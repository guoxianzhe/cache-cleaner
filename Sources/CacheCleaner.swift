import Cocoa

let paths = [
    "Library/Application Support/Codex/Crashpad/pending", ".cache/uv",
    "Library/Caches/vscode-cpptools", ".gradle/caches", ".gradle/.tmp",
    ".gradle/daemon", ".npm/_cacache", ".npm/_npx", "Library/Caches/CocoaPods",
    "Library/Caches/Yarn", "Library/Caches/electron", "Library/Caches/ms-playwright",
    "Library/Caches/typescript"
]
let home = FileManager.default.homeDirectoryForCurrentUser
let targets = paths.map { home.appendingPathComponent($0) }

func run(_ executable: String, _ args: [String]) throws -> (Int32, String) {
    let process = Process(), pipe = Pipe()
    process.executableURL = URL(fileURLWithPath: executable)
    process.arguments = args
    process.standardOutput = pipe
    process.standardError = pipe
    try process.run()
    let data = pipe.fileHandleForReading.readDataToEndOfFile()
    process.waitUntilExit()
    return (process.terminationStatus, String(decoding: data, as: UTF8.self))
}

// Reject redirected paths, including symlinks in any parent directory.
func validated(_ url: URL, under root: URL) -> Bool {
    let rootPath = root.standardizedFileURL.path + "/"
    return url.standardizedFileURL.path.hasPrefix(rootPath)
        && url.resolvingSymlinksInPath().path == url.standardizedFileURL.path
}

func size(_ url: URL) throws -> Int64 {
    guard FileManager.default.fileExists(atPath: url.path) else { return 0 }
    guard validated(url, under: home) else {
        throw NSError(domain: "Cleaner", code: 1, userInfo: [NSLocalizedDescriptionKey: "跳过链接目录：\(url.path)"])
    }
    let (status, output) = try run("/usr/bin/du", ["-sk", url.path])
    guard status == 0, let first = output.split(whereSeparator: { $0.isWhitespace }).first,
          let kb = Int64(first) else {
        throw NSError(domain: "Cleaner", code: 2, userInfo: [NSLocalizedDescriptionKey: "无法统计：\(url.path)\n\(output)"])
    }
    return kb * 1024
}

func human(_ bytes: Int64) -> String {
    if bytes >= 1_073_741_824 { return String(format: "%.2f GiB", Double(bytes) / 1_073_741_824) }
    return String(format: "%.1f MiB", Double(bytes) / 1_048_576)
}

func freeSpace() -> Int64 {
    let attrs = try? FileManager.default.attributesOfFileSystem(forPath: home.path)
    return (attrs?[.systemFreeSize] as? NSNumber)?.int64Value ?? 0
}

final class App: NSObject, NSApplicationDelegate {
    var panel: NSPanel!
    var statusItem: NSStatusItem!
    let headline = NSTextField(labelWithString: "开发缓存清理")
    let capacity = NSTextField(labelWithString: "点击扫描，计算可清理容量")
    let detail = NSTextView()
    let scanButton = NSButton(title: "扫描", target: nil, action: nil)
    let cleanButton = NSButton(title: "清理…", target: nil, action: nil)
    var measured: [(URL, Int64)] = []
    var busy = false

    func applicationDidFinishLaunching(_ notification: Notification) {
        panel = NSPanel(contentRect: NSRect(x: 0, y: 0, width: 400, height: 370),
                        styleMask: [.titled, .closable, .utilityWindow], backing: .buffered, defer: false)
        panel.title = "缓存小扫帚"
        panel.level = .floating
        panel.hidesOnDeactivate = false
        panel.isReleasedWhenClosed = false
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        headline.font = .systemFont(ofSize: 20, weight: .semibold)
        capacity.font = .monospacedDigitSystemFont(ofSize: 16, weight: .medium)
        let note = NSTextField(wrappingLabelWithString: "固定清理开发缓存。建议先退出正在构建的开发工具。")
        note.textColor = .secondaryLabelColor
        let scroll = NSScrollView()
        scroll.hasVerticalScroller = true
        scroll.borderType = .bezelBorder
        detail.isEditable = false
        detail.font = .systemFont(ofSize: 11)
        detail.isVerticallyResizable = true
        detail.textContainer?.widthTracksTextView = true
        scroll.documentView = detail
        scanButton.target = self; scanButton.action = #selector(scan)
        cleanButton.target = self; cleanButton.action = #selector(clean)
        cleanButton.isEnabled = false
        let buttons = NSStackView(views: [scanButton, cleanButton])
        buttons.spacing = 12
        let stack = NSStackView(views: [headline, capacity, note, scroll, buttons])
        stack.orientation = .vertical; stack.alignment = .leading; stack.spacing = 14
        stack.translatesAutoresizingMaskIntoConstraints = false
        panel.contentView!.addSubview(stack)
        NSLayoutConstraint.activate([
            stack.leadingAnchor.constraint(equalTo: panel.contentView!.leadingAnchor, constant: 20),
            stack.trailingAnchor.constraint(equalTo: panel.contentView!.trailingAnchor, constant: -20),
            stack.topAnchor.constraint(equalTo: panel.contentView!.topAnchor, constant: 20),
            stack.bottomAnchor.constraint(equalTo: panel.contentView!.bottomAnchor, constant: -20),
            scroll.widthAnchor.constraint(equalTo: stack.widthAnchor),
            scroll.heightAnchor.constraint(greaterThanOrEqualToConstant: 150)
        ])
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        statusItem.button?.image = NSImage(systemSymbolName: "sparkles", accessibilityDescription: "缓存小扫帚")
        let menu = NSMenu()
        let showItem = NSMenuItem(title: "显示悬浮窗", action: #selector(show), keyEquivalent: "")
        showItem.target = self; menu.addItem(showItem)
        menu.addItem(.separator())
        menu.addItem(NSMenuItem(title: "退出", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q"))
        statusItem.menu = menu
        panel.center(); show(); scan()
    }

    @objc func show() { panel.makeKeyAndOrderFront(nil); NSApp.activate(ignoringOtherApps: true) }

    func setBusy(_ value: Bool) {
        busy = value; scanButton.isEnabled = !value
        cleanButton.isEnabled = !value && measured.contains { $0.1 > 0 }
    }

    @objc func scan() {
        guard !busy else { return }
        setBusy(true); capacity.stringValue = "正在扫描…"
        DispatchQueue.global(qos: .utility).async {
            var found: [(URL, Int64)] = [], lines: [String] = []
            for target in targets {
                do {
                    let bytes = try size(target); found.append((target, bytes))
                    lines.append("\(human(bytes))  ·  \(target.path.replacingOccurrences(of: home.path, with: "~"))")
                } catch { lines.append(error.localizedDescription) }
            }
            let result = found, text = lines.joined(separator: "\n\n")
            DispatchQueue.main.async {
                self.measured = result
                self.capacity.stringValue = "可清理 \(human(result.reduce(0) { $0 + $1.1 }))"
                self.detail.string = text; self.setBusy(false)
            }
        }
    }

    @objc func clean() {
        guard !busy else { return }
        let selected = measured.filter { $0.1 > 0 }
        let alert = NSAlert()
        alert.messageText = "清理 \(human(selected.reduce(0) { $0 + $1.1 })) 的开发缓存？"
        alert.informativeText = "这些缓存会永久删除，之后使用时可重新生成或下载。清理范围见窗口列表。"
        alert.addButton(withTitle: "清理"); alert.addButton(withTitle: "取消")
        guard alert.runModal() == .alertFirstButtonReturn else { return }
        setBusy(true); capacity.stringValue = "正在清理…"
        DispatchQueue.global(qos: .utility).async {
            let beforeFree = freeSpace()
            var removed: Int64 = 0, errors: [String] = []
            for (target, _) in selected {
                do {
                    let before = try size(target)
                    guard before > 0 else { continue }
                    let (code, output) = try run("/usr/bin/find", [target.path, "-depth", "-delete"])
                    if code != 0 { errors.append("\(target.lastPathComponent)：\(output)") }
                    removed += max(0, before - (try size(target)))
                } catch { errors.append(error.localizedDescription) }
            }
            let deleted = removed, afterFree = freeSpace(), failures = errors
            DispatchQueue.main.async {
                self.measured = []; self.setBusy(false)
                self.capacity.stringValue = "已清理 \(human(deleted))"
                self.detail.string = "磁盘剩余：\(human(afterFree))\n可用空间变化：\(human(afterFree - beforeFree))\n\n" +
                    (failures.isEmpty ? "清理完成。缓存统计量与磁盘变化可能因共享文件或其他应用活动而不同。" : "部分项目未清理成功：\n" + failures.joined(separator: "\n"))
            }
        }
    }
}

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
    let (code, _) = try run("/usr/bin/find", [root.path, "-depth", "-delete"])
    assert(code == 0 && !FileManager.default.fileExists(atPath: root.path))
    print("Self-test passed: fixed paths, symlink rejection, size formatting, temporary-cache deletion.")
} else {
    let app = NSApplication.shared
    let delegate = App()
    app.setActivationPolicy(.accessory)
    app.delegate = delegate
    app.run()
}
