// Copyright (c) 2026 guoxianzhe. SPDX-License-Identifier: MIT
import Cocoa
import UniformTypeIdentifiers

let paths = [
  "Library/Application Support/Codex/Crashpad/pending", ".cache/uv",
  "Library/Caches/vscode-cpptools", ".gradle/caches", ".gradle/.tmp", ".gradle/daemon",
  ".npm/_cacache", ".npm/_npx", "Library/Caches/CocoaPods", "Library/Caches/Yarn",
  "Library/Caches/electron", "Library/Caches/ms-playwright", "Library/Caches/typescript",
]
let home = FileManager.default.homeDirectoryForCurrentUser
let targets = paths.map { home.appendingPathComponent($0) }
func run(_ executable: String, _ args: [String]) throws -> (Int32, String) {
  let p = Process()
  let pipe = Pipe()
  p.executableURL = URL(fileURLWithPath: executable)
  p.arguments = args
  p.standardOutput = pipe
  p.standardError = pipe
  try p.run()
  let data = pipe.fileHandleForReading.readDataToEndOfFile()
  p.waitUntilExit()
  return (p.terminationStatus, String(decoding: data, as: UTF8.self))
}
func validated(_ url: URL, under root: URL) -> Bool {
  url.standardizedFileURL.path.hasPrefix(root.standardizedFileURL.path + "/")
    && url.resolvingSymlinksInPath().path == url.standardizedFileURL.path
}
func size(_ url: URL) throws -> Int64 {
  guard FileManager.default.fileExists(atPath: url.path) else { return 0 }
  guard validated(url, under: home) else {
    throw NSError(
      domain: "Cleaner", code: 1,
      userInfo: [NSLocalizedDescriptionKey: "Skipped linked directory: \(url.path)"])
  }
  let (code, output) = try run("/usr/bin/du", ["-sk", url.path])
  guard code == 0, let first = output.split(whereSeparator: { $0.isWhitespace }).first,
    let kb = Int64(first)
  else {
    throw NSError(
      domain: "Cleaner", code: 2,
      userInfo: [NSLocalizedDescriptionKey: "Cannot measure: \(url.path)\n\(output)"])
  }
  return kb * 1024
}
func human(_ bytes: Int64) -> String {
  abs(bytes) >= 1_073_741_824
    ? String(format: "%.2f GiB", Double(bytes) / 1_073_741_824)
    : String(format: "%.1f MiB", Double(bytes) / 1_048_576)
}
func freeSpace() -> Int64 {
  ((try? FileManager.default.attributesOfFileSystem(forPath: home.path)[.systemFreeSize])
    as? NSNumber)?.int64Value ?? 0
}
final class FloatingPanel: NSPanel { override var canBecomeKey: Bool { true } }
func clampOrigin(_ origin: NSPoint, size: NSSize, to frame: NSRect) -> NSPoint {
  NSPoint(
    x: min(max(origin.x, frame.minX), max(frame.minX, frame.maxX - size.width)),
    y: min(max(origin.y, frame.minY), max(frame.minY, frame.maxY - size.height)))
}
final class App: NSObject, NSApplicationDelegate {
  enum BubbleState { case idle, scanning, ready, cleaning, done }
  var bubbleState: BubbleState = .idle
  let bubble = NSPopover()
  let bubbleTitle = NSTextField(labelWithString: "Let's make room.")
  let bubbleMessage = NSTextField(wrappingLabelWithString: "Click your companion to scan.")
  let bubbleClean = NSButton(title: "Clean", target: nil, action: nil)
  let bubbleLater = NSButton(title: "Later", target: nil, action: nil)
  let bubbleDetails = NSButton(title: "Details", target: nil, action: nil)
  let spinner = NSProgressIndicator()
  var buddy: FloatingPanel!, panel: FloatingPanel!, statusItem: NSStatusItem!
  let avatar = AvatarView(frame: NSRect(x: 0, y: 0, width: 152, height: 240))
  let capacity = NSTextField(labelWithString: "Let's make room.")
  let subtitle = NSTextField(labelWithString: "Click Scan to check your caches.")
  let detail = NSTextView()
  let scanButton = NSButton(title: "Scan again", target: nil, action: nil)
  let cleanButton = NSButton(title: "Clean caches…", target: nil, action: nil)
  var measured: [(URL, Int64)] = [], busy = false
  let defaults = UserDefaults.standard
  var avatarURL: URL {
    home.appendingPathComponent("Library/Application Support/Cache-Chan/companion.png")
  }
  func menu() -> NSMenu {
    let m = NSMenu()
    for (title, action) in [
      ("Show companion", #selector(show)), ("Open cleaner", #selector(openCleaner)),
      ("Change avatar…", #selector(changeAvatar)), ("Reset avatar", #selector(resetAvatar)),
      ("About Cache-Chan", #selector(about)),
    ] {
      let item = NSMenuItem(title: title, action: action, keyEquivalent: "")
      item.target = self
      m.addItem(item)
    }
    m.addItem(.separator())
    m.addItem(
      NSMenuItem(
        title: "Quit Cache-Chan", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q"
      ))
    return m
  }
  func applicationDidFinishLaunching(_ notification: Notification) {
    NSApp.appearance = NSAppearance(named: .darkAqua)
    buddy = FloatingPanel(
      contentRect: avatar.frame, styleMask: [.borderless], backing: .buffered, defer: false)
    buddy.title = "Cache-Chan companion"
    buddy.backgroundColor = .clear
    buddy.isOpaque = false
    buddy.hasShadow = false
    buddy.contentView = avatar
    makeCleaner()
    makeBubble()
    for w in [buddy!, panel!] {
      w.level = .floating
      w.hidesOnDeactivate = false
      w.isReleasedWhenClosed = false
      w.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
    }
    avatar.setAccessibilityElement(true)
    avatar.setAccessibilityRole(.button)
    avatar.setAccessibilityLabel(
      "Cache-Chan avatar. Click to scan caches. Drag to move. Right-click for settings.")
    avatar.toolTip = "Click to scan · drag to move · right-click to customize"
    avatar.onClick = { [weak self] in self?.scanFromAvatar() }
    avatar.onMove = { [weak self] in
      guard let s = self else { return }
      s.keepOnScreen()
      s.defaults.set(NSStringFromPoint(s.buddy.frame.origin), forKey: "companionPosition")
      s.positionCleaner()
      if s.bubble.isShown {
        s.bubble.close()
        s.showBubble()
      }
    }
    avatar.contextMenu = menu()
    if let image = NSImage(contentsOf: avatarURL) {
      avatar.image = image
      avatar.usesDefault = false
    }
    let frame = NSScreen.main?.visibleFrame ?? NSRect(x: 0, y: 0, width: 1440, height: 900)
    let position =
      defaults.string(forKey: "companionPosition").map(NSPointFromString)
      ?? NSPoint(x: frame.maxX - 182, y: frame.minY + 80)
    buddy.setFrameOrigin(position)
    keepOnScreen()
    statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
    statusItem.button?.image = NSImage(
      systemSymbolName: "sparkles", accessibilityDescription: "Cache-Chan")
    statusItem.menu = menu()
    show()
    if let i = CommandLine.arguments.firstIndex(of: "--preview"),
      CommandLine.arguments.count > i + 1
    {
      capacity.stringValue = "Your space. Reclaimed."
      updateBubble(
        .done, title: "Scan. Review. Clean.",
        message:
          "Click my avatar to scan your development caches. I'll ask before deleting anything.")
      subtitle.stringValue = "Scan, review, confirm. You're in control."
      detail.string =
        "A desktop companion with a smaller footprint.\n\n13 fixed cache locations\nCustom avatars · Drag anywhere\nNo admin access · No telemetry\n\nClick Scan to see your real cache sizes."
      exportPreview(to: CommandLine.arguments[i + 1])
      NSApp.terminate(nil)
    }
  }
  func makeBubble() {
    let controller = NSViewController()
    controller.view = NSView(frame: NSRect(x: 0, y: 0, width: 292, height: 190))
    bubbleTitle.font = .systemFont(ofSize: 19, weight: .bold)
    bubbleMessage.font = .systemFont(ofSize: 12)
    bubbleMessage.textColor = .secondaryLabelColor
    bubbleClean.target = self
    bubbleClean.action = #selector(clean)
    bubbleLater.target = self
    bubbleLater.action = #selector(dismissBubble)
    bubbleDetails.target = self
    bubbleDetails.action = #selector(openCleaner)
    for button in [bubbleClean, bubbleLater, bubbleDetails] { button.bezelStyle = .rounded }
    bubbleClean.contentTintColor = rose
    spinner.style = .spinning
    spinner.controlSize = .small
    spinner.isDisplayedWhenStopped = false
    let header = NSStackView(views: [spinner, bubbleTitle])
    header.spacing = 8
    let actions = NSStackView(views: [bubbleClean, bubbleLater, bubbleDetails])
    actions.spacing = 8
    let stack = NSStackView(views: [header, bubbleMessage, actions])
    stack.orientation = .vertical
    stack.alignment = .leading
    stack.spacing = 14
    stack.translatesAutoresizingMaskIntoConstraints = false
    controller.view.addSubview(stack)
    NSLayoutConstraint.activate([
      stack.leadingAnchor.constraint(equalTo: controller.view.leadingAnchor, constant: 18),
      stack.trailingAnchor.constraint(equalTo: controller.view.trailingAnchor, constant: -18),
      stack.topAnchor.constraint(equalTo: controller.view.topAnchor, constant: 18),
      bubbleMessage.widthAnchor.constraint(equalTo: stack.widthAnchor),
    ])
    bubble.contentViewController = controller
    bubble.contentSize = controller.view.frame.size
    bubble.behavior = .applicationDefined
    bubble.animates = !NSWorkspace.shared.accessibilityDisplayShouldReduceMotion
    updateBubble(.idle, title: "Let's make room.", message: "Click your companion to scan.")
  }
  func showBubble() {
    if !bubble.isShown {
      bubble.show(
        relativeTo: NSRect(x: 8, y: 28, width: 136, height: 204), of: avatar, preferredEdge: .minX)
    }
  }
  func scanFromAvatar() {
    show()
    showBubble()
    if !busy { scan() }
  }
  @objc func dismissBubble() { bubble.close() }
  func updateBubble(_ state: BubbleState, title: String, message: String) {
    bubbleState = state
    bubbleTitle.stringValue = title
    bubbleMessage.stringValue = message
    bubbleClean.isHidden = state != .ready
    bubbleClean.isEnabled = state == .ready && measured.contains { $0.1 > 0 }
    bubbleLater.title = (state == .ready) ? "Later" : "Close"
    bubbleDetails.isEnabled = state != .cleaning
    if state == .scanning || state == .cleaning {
      spinner.startAnimation(nil)
    } else {
      spinner.stopAnimation(nil)
    }
  }
  func makeCleaner() {
    panel = FloatingPanel(
      contentRect: NSRect(x: 0, y: 0, width: 410, height: 510),
      styleMask: [.titled, .closable, .utilityWindow], backing: .buffered, defer: false)
    panel.title = "Cache-Chan"
    let root = panel.contentView!
    root.wantsLayer = true
    root.layer?.backgroundColor =
      NSColor(calibratedRed: 0.10, green: 0.09, blue: 0.13, alpha: 1).cgColor
    let brand = NSTextField(labelWithString: "CACHE-CHAN  /  DESKTOP COMPANION")
    brand.font = .monospacedSystemFont(ofSize: 10, weight: .semibold)
    brand.textColor = rose
    capacity.font = .systemFont(ofSize: 27, weight: .bold)
    capacity.textColor = .white
    subtitle.font = .systemFont(ofSize: 11)
    subtitle.textColor = NSColor(calibratedWhite: 0.76, alpha: 1)
    let scroll = NSScrollView()
    scroll.hasVerticalScroller = true
    scroll.drawsBackground = false
    detail.isEditable = false
    detail.drawsBackground = false
    detail.textColor = NSColor(calibratedWhite: 0.88, alpha: 1)
    detail.font = .monospacedSystemFont(ofSize: 11, weight: .regular)
    detail.textContainerInset = NSSize(width: 0, height: 8)
    detail.isVerticallyResizable = true
    detail.isHorizontallyResizable = false
    detail.autoresizingMask = [.width]
    detail.frame = NSRect(x: 0, y: 0, width: 362, height: 200)
    detail.minSize = NSSize(width: 0, height: 200)
    detail.maxSize = NSSize(
      width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude)
    detail.textContainer?.containerSize = NSSize(
      width: 362, height: CGFloat.greatestFiniteMagnitude)
    detail.textContainer?.widthTracksTextView = true
    detail.textContainer?.lineBreakMode = .byCharWrapping
    let paragraph = NSMutableParagraphStyle()
    paragraph.lineBreakMode = .byCharWrapping
    detail.defaultParagraphStyle = paragraph
    detail.string = "Your caches stay untouched until you confirm."
    scroll.documentView = detail
    scanButton.target = self
    scanButton.action = #selector(scan)
    cleanButton.target = self
    cleanButton.action = #selector(clean)
    cleanButton.isEnabled = false
    for b in [scanButton, cleanButton] {
      b.bezelStyle = .rounded
      b.controlSize = .large
    }
    cleanButton.contentTintColor = rose
    let actions = NSStackView(views: [scanButton, cleanButton])
    actions.spacing = 12
    let custom = NSButton(title: "Change avatar…", target: self, action: #selector(changeAvatar))
    custom.bezelStyle = .rounded
    custom.contentTintColor = rose
    let footer = NSTextField(labelWithString: "© 2026 guoxianzhe · MIT License · v0.4.0")
    footer.font = .systemFont(ofSize: 10)
    footer.textColor = NSColor(calibratedWhite: 0.65, alpha: 1)
    let note = NSTextField(
      wrappingLabelWithString:
        "Quit active builds first. These caches will be rebuilt or downloaded when needed.")
    note.font = .systemFont(ofSize: 11)
    note.textColor = NSColor(calibratedWhite: 0.72, alpha: 1)
    let stack = NSStackView(views: [
      brand, capacity, subtitle, scroll, actions, note, custom, footer,
    ])
    stack.orientation = .vertical
    stack.alignment = .leading
    stack.spacing = 16
    stack.translatesAutoresizingMaskIntoConstraints = false
    root.addSubview(stack)
    NSLayoutConstraint.activate([
      stack.leadingAnchor.constraint(equalTo: root.leadingAnchor, constant: 24),
      stack.trailingAnchor.constraint(equalTo: root.trailingAnchor, constant: -24),
      stack.topAnchor.constraint(equalTo: root.topAnchor, constant: 24),
      stack.bottomAnchor.constraint(equalTo: root.bottomAnchor, constant: -24),
      scroll.widthAnchor.constraint(equalTo: stack.widthAnchor),
      scroll.heightAnchor.constraint(greaterThanOrEqualToConstant: 165),
      capacity.widthAnchor.constraint(equalTo: stack.widthAnchor),
    ])
  }
  func keepOnScreen() {
    guard
      let f = (NSScreen.screens.first { $0.visibleFrame.intersects(buddy.frame) } ?? NSScreen.main)?
        .visibleFrame
    else { return }
    buddy.setFrameOrigin(clampOrigin(buddy.frame.origin, size: buddy.frame.size, to: f))
  }
  func positionCleaner() {
    guard
      let f = (NSScreen.screens.first { $0.visibleFrame.intersects(buddy.frame) } ?? NSScreen.main)?
        .visibleFrame
    else { return }
    let left = buddy.frame.minX - panel.frame.width - 12
    let x = buddy.frame.minX - panel.frame.width - 12 >= f.minX ? left : buddy.frame.maxX + 12
    panel.setFrameOrigin(
      clampOrigin(
        NSPoint(x: x, y: buddy.frame.midY - panel.frame.height / 2), size: panel.frame.size, to: f))
  }
  @objc func show() { buddy.orderFrontRegardless() }
  @objc func openCleaner() {
    bubble.close()
    show()
    positionCleaner()
    panel.makeKeyAndOrderFront(nil)
    NSApp.activate(ignoringOtherApps: true)
    if measured.isEmpty && !busy { scan() }
  }
  func toggleCleaner() { if panel.isVisible { panel.orderOut(nil) } else { openCleaner() } }
  @objc func changeAvatar() {
    let picker = NSOpenPanel()
    picker.title = "Choose your companion avatar"
    picker.allowedContentTypes = [.image]
    picker.canChooseDirectories = false
    picker.allowsMultipleSelection = false
    guard picker.runModal() == .OK, let url = picker.url else { return }
    do {
      guard let image = NSImage(contentsOf: url), image.size.width > 0, image.size.height > 0 else {
        throw NSError(
          domain: "Avatar", code: 1,
          userInfo: [NSLocalizedDescriptionKey: "Please choose a readable image."])
      }
      let scale = min(512 / max(image.size.width, image.size.height), 1)
      let normalized = NSImage(
        size: NSSize(width: image.size.width * scale, height: image.size.height * scale))
      normalized.lockFocus()
      image.draw(
        in: NSRect(origin: .zero, size: normalized.size),
        from: .zero, operation: .sourceOver, fraction: 1)
      normalized.unlockFocus()
      guard let data = pngData(normalized) else { throw NSError(domain: "Avatar", code: 2) }
      try FileManager.default.createDirectory(
        at: avatarURL.deletingLastPathComponent(), withIntermediateDirectories: true)
      try data.write(to: avatarURL, options: .atomic)
      avatar.image = normalized
      avatar.usesDefault = false
      avatar.needsDisplay = true
    } catch { errorAlert("Could not change avatar", error) }
  }
  @objc func resetAvatar() {
    do {
      if FileManager.default.fileExists(atPath: avatarURL.path) {
        try FileManager.default.removeItem(at: avatarURL)
      }
      avatar.image = mascotImage()
      avatar.usesDefault = true
      avatar.needsDisplay = true
    } catch { errorAlert("Could not reset avatar", error) }
  }
  func errorAlert(_ title: String, _ error: Error) {
    let a = NSAlert()
    a.messageText = title
    a.informativeText = error.localizedDescription
    a.runModal()
  }
  @objc func about() {
    let a = NSAlert()
    a.messageText = "Cache-Chan 0.4.0"
    a.icon = mascotImage()
    a.informativeText =
      "A little companion. A little more space.\n\nCopyright © 2026 guoxianzhe\nCode and original mascot: MIT License\n\ngithub.com/guoxianzhe/cache-cleaner\nNo telemetry. No automatic cleaning."
    a.runModal()
  }
  func setBusy(_ value: Bool) {
    busy = value
    avatar.setActivity(value)
    scanButton.isEnabled = !value
    cleanButton.isEnabled = !value && measured.contains { $0.1 > 0 }
  }
  @objc func scan() {
    guard !busy else { return }
    setBusy(true)
    updateBubble(
      .scanning, title: "Checking your caches…",
      message: "Scanning 13 cache locations. Nothing is being deleted.")
    capacity.stringValue = "Checking your caches…"
    subtitle.stringValue = "Scanning 13 locations. No files are being removed."
    DispatchQueue.global(qos: .utility).async {
      var found: [(URL, Int64)] = []
      var lines: [String] = []
      for t in targets {
        do {
          let b = try size(t)
          found.append((t, b))
          lines.append("\(human(b))  ·  \(t.path.replacingOccurrences(of: home.path,with: "~"))")
        } catch { lines.append(error.localizedDescription) }
      }
      let result = found
      let text = lines.joined(separator: "\n\n")
      DispatchQueue.main.async {
        self.measured = result
        let total = result.reduce(0) { $0 + $1.1 }
        self.capacity.stringValue = total > 0 ? "\(human(total)) to reclaim" : "All clear!"
        self.subtitle.stringValue =
          "Disk available: \(human(freeSpace())) · Review before cleaning."
        self.detail.string = text
        self.setBusy(false)
        self.updateBubble(
          total > 0 ? .ready : .done,
          title: total > 0 ? "Clean \(human(total))?" : "All clear!",
          message: total > 0
            ? "Permanently delete these development caches? Quit active builds first. Details shows the exact paths."
            : "No eligible caches to clean. Click the avatar whenever you want to scan again.")
      }
    }
  }
  @objc func clean() {
    guard !busy else { return }
    let selected = measured.filter { $0.1 > 0 }
    guard !selected.isEmpty else { return }
    // The bubble's explicit Clean button is the confirmation; no second modal.
    guard bubble.isShown && bubbleState == .ready else {
      showBubble()
      updateBubble(
        .ready, title: "Clean \(human(selected.reduce(0) { $0+$1.1 }))?",
        message:
          "Permanently delete these development caches? Quit active builds first. Details shows the exact paths."
      )
      return
    }
    setBusy(true)
    updateBubble(
      .cleaning, title: "Making room…",
      message: "Removing only the scanned cache locations. Keep Cache-Chan running.")
    capacity.stringValue = "Making room…"
    subtitle.stringValue = "Keep Cache-Chan open until cleaning finishes."
    DispatchQueue.global(qos: .utility).async {
      let beforeFree = freeSpace()
      var removed: Int64 = 0
      var errors: [String] = []
      for (t, _) in selected {
        do {
          let before = try size(t)
          guard before > 0 else { continue }
          let (code, output) = try run("/usr/bin/find", [t.path, "-depth", "-delete"])
          if code != 0 { errors.append("\(t.lastPathComponent): \(output)") }
          removed += max(0, before - (try size(t)))
        } catch { errors.append(error.localizedDescription) }
      }
      let deleted = removed
      let afterFree = freeSpace()
      let failures = errors
      DispatchQueue.main.async {
        self.measured = []
        self.setBusy(false)
        self.capacity.stringValue = "\(human(deleted)) cleared"
        self.subtitle.stringValue =
          failures.isEmpty ? "A little more breathing room." : "Some locations need attention."
        self.updateBubble(
          .done, title: "\(human(deleted)) cleared",
          message: failures.isEmpty
            ? "Disk available: \(human(afterFree)). Your caches will rebuild when needed."
            : "Some locations could not be cleaned. Open Details for the errors.")
        self.avatar.celebrate()
        self.detail.string =
          "Disk available: \(human(afterFree))\nAvailable space change: \(human(afterFree-beforeFree))\n\n"
          + (failures.isEmpty
            ? "Done! Shared APFS blocks and other app activity can affect the disk space change. Your caches will rebuild when needed."
            : failures.joined(separator: "\n"))
      }
    }
  }
  func exportPreview(to path: String) {
    let previewView = bubble.contentViewController!.view
    previewView.wantsLayer = true
    previewView.layer?.backgroundColor =
      NSColor(calibratedRed: 0.10, green: 0.09, blue: 0.13, alpha: 1).cgColor
    previewView.layer?.cornerRadius = 16
    previewView.layoutSubtreeIfNeeded()
    let image = NSImage(size: NSSize(width: 1000, height: 640))
    image.lockFocus()
    NSColor(calibratedRed: 0.97, green: 0.92, blue: 0.93, alpha: 1).setFill()
    NSBezierPath(rect: NSRect(x: 0, y: 0, width: 1000, height: 640)).fill()
    "Cache-Chan".draw(
      at: NSPoint(x: 56, y: 527),
      withAttributes: [.font: NSFont.systemFont(ofSize: 42, weight: .bold), .foregroundColor: ink])
    "A little companion.\nA little more space.".draw(
      in: NSRect(x: 56, y: 402, width: 410, height: 100),
      withAttributes: [
        .font: NSFont.systemFont(ofSize: 26, weight: .medium), .foregroundColor: ink,
      ])
    let character = mascotImage()
    character.draw(
      in: fittedRect(character.size, in: NSRect(x: 116, y: 114, width: 228, height: 310)))
    "NATIVE macOS  /  CUSTOM AVATARS  /  MIT".draw(
      at: NSPoint(x: 56, y: 58),
      withAttributes: [
        .font: NSFont.monospacedSystemFont(ofSize: 11, weight: .semibold), .foregroundColor: ink,
      ])
    if let bitmap = previewView.bitmapImageRepForCachingDisplay(
      in: previewView.bounds)
    {
      previewView.cacheDisplay(in: previewView.bounds, to: bitmap)
      let ui = NSImage(size: previewView.bounds.size)
      ui.addRepresentation(bitmap)
      ui.draw(in: NSRect(x: 532, y: 245, width: 365, height: 237.5))
    }
    image.unlockFocus()
    try? pngData(image)?.write(to: URL(fileURLWithPath: path))
  }
}
@main struct Main {
  static func main() throws {
    let app = NSApplication.shared
    if CommandLine.arguments.contains("--self-test") {
      let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
      try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
      let file = root.appendingPathComponent("cache")
      try Data(repeating: 1, count: 8192).write(to: file)
      assert(validated(file, under: root))
      assert(!validated(root, under: root))
      let link = root.appendingPathComponent("link")
      try FileManager.default.createSymbolicLink(at: link, withDestinationURL: home)
      assert(!validated(link, under: root))
      assert(human(1_073_741_824) == "1.00 GiB")
      assert(human(-1_073_741_824) == "-1.00 GiB")
      assert(NSImage(data: pngData(mascotImage())!) != nil)
      let pose = mascotImage()
      let fit = fittedRect(pose.size, in: NSRect(x: 0, y: 0, width: 136, height: 204))
      assert(abs(fit.width / fit.height - pose.size.width / pose.size.height) < 0.001)
      assert(fit.width <= 136 && fit.height <= 204)
      assert(pngData(pose) != pngData(mascotImage(blink: true)))
      assert(NSBitmapImageRep(data: pngData(pose)!)!.colorAt(x: 0, y: 0)!.alphaComponent == 0)
      let animationView = AvatarView(frame: NSRect(x: 0, y: 0, width: 104, height: 120))
      animationView.setActivity(true)
      if !NSWorkspace.shared.accessibilityDisplayShouldReduceMotion {
        assert(animationView.layer?.animation(forKey: "activity") != nil)
      }
      animationView.setActivity(false)
      assert(animationView.layer?.animation(forKey: "activity") == nil)
      let controller = App()
      controller.makeBubble()
      controller.updateBubble(.ready, title: "Test", message: "No caches")
      assert(!controller.bubbleClean.isEnabled)
      controller.measured = [(file, 8192)]
      controller.updateBubble(.ready, title: "Test", message: "Has caches")
      assert(controller.bubbleClean.isEnabled && !controller.bubbleClean.isHidden)
      controller.updateBubble(.cleaning, title: "Test", message: "Working")
      assert(!controller.bubbleClean.isEnabled && controller.bubbleClean.isHidden)
      let screen = NSRect(x: 0, y: 0, width: 1000, height: 800)
      assert(
        clampOrigin(NSPoint(x: -20, y: 900), size: NSSize(width: 104, height: 120), to: screen)
          == NSPoint(x: 0, y: 680))
      let negativeScreen = NSRect(x: -1000, y: 0, width: 1000, height: 800)
      assert(
        clampOrigin(
          NSPoint(x: 20, y: -30), size: NSSize(width: 104, height: 120), to: negativeScreen)
          == NSPoint(x: -104, y: 0))
      let (code, _) = try run("/usr/bin/find", [root.path, "-depth", "-delete"])
      assert(code == 0 && !FileManager.default.fileExists(atPath: root.path))
      print(
        "Self-test passed: scope validation, symlink rejection, signed capacity formatting, avatar rendering, temporary cleanup."
      )
    } else if let i = CommandLine.arguments.firstIndex(of: "--export-icon"),
      CommandLine.arguments.count > i + 1
    {
      try pngData(portraitImage(1024))!.write(
        to: URL(fileURLWithPath: CommandLine.arguments[i + 1]))
    } else if let i = CommandLine.arguments.firstIndex(of: "--export-avatar"),
      CommandLine.arguments.count > i + 1
    {
      try pngData(mascotImage(1024))!.write(to: URL(fileURLWithPath: CommandLine.arguments[i + 1]))
    } else {
      let delegate = App()
      app.setActivationPolicy(.accessory)
      app.delegate = delegate
      app.run()
    }
  }
}
