// Copyright (c) 2026 guoxianzhe. SPDX-License-Identifier: MIT
import Cocoa
import QuartzCore

let ink = NSColor(calibratedRed: 0.18, green: 0.15, blue: 0.24, alpha: 1)
let rose = NSColor(calibratedRed: 1, green: 0.67, blue: 0.74, alpha: 1)

// Original character artwork, drawn locally with native vector primitives.
func portraitImage(_ dimension: CGFloat = 512) -> NSImage {
  let image = NSImage(size: NSSize(width: dimension, height: dimension))
  image.lockFocus()
  let transform = NSAffineTransform()
  transform.scale(by: dimension / 100)
  transform.concat()
  func oval(_ r: NSRect, _ color: NSColor, outline: Bool = false) {
    let p = NSBezierPath(ovalIn: r)
    color.setFill()
    p.fill()
    if outline {
      ink.setStroke()
      p.lineWidth = 1.4
      p.stroke()
    }
  }
  func shape(_ points: [NSPoint], _ color: NSColor) {
    let p = NSBezierPath()
    p.move(to: points[0])
    points.dropFirst().forEach { p.line(to: $0) }
    p.close()
    color.setFill()
    p.fill()
    ink.setStroke()
    p.lineWidth = 1.1
    p.stroke()
  }
  func line(_ points: [NSPoint], _ color: NSColor = ink, _ width: CGFloat = 1.4) {
    let p = NSBezierPath()
    p.move(to: points[0])
    points.dropFirst().forEach { p.line(to: $0) }
    color.setStroke()
    p.lineWidth = width
    p.lineCapStyle = .round
    p.stroke()
  }
  oval(
    NSRect(x: 3, y: 3, width: 94, height: 94),
    NSColor(calibratedRed: 1, green: 0.91, blue: 0.92, alpha: 1))
  oval(NSRect(x: 9, y: 10, width: 82, height: 81), .white)
  let hair = NSColor(calibratedRed: 0.94, green: 0.54, blue: 0.65, alpha: 1)
  oval(NSRect(x: 8, y: 22, width: 25, height: 49), hair, outline: true)
  oval(NSRect(x: 67, y: 22, width: 25, height: 49), hair, outline: true)
  oval(NSRect(x: 21, y: 20, width: 58, height: 64), hair, outline: true)
  ink.setFill()
  NSBezierPath(roundedRect: NSRect(x: 27, y: 10, width: 46, height: 25), xRadius: 12, yRadius: 12)
    .fill()
  shape(
    [
      NSPoint(x: 39, y: 30), NSPoint(x: 50, y: 21), NSPoint(x: 61, y: 30), NSPoint(x: 58, y: 15),
      NSPoint(x: 42, y: 15),
    ], .white)
  oval(
    NSRect(x: 26, y: 29, width: 48, height: 46),
    NSColor(calibratedRed: 1, green: 0.89, blue: 0.82, alpha: 1), outline: true)
  oval(NSRect(x: 22, y: 59, width: 57, height: 26), rose, outline: true)
  shape(
    [
      NSPoint(x: 25, y: 72), NSPoint(x: 33, y: 79), NSPoint(x: 49, y: 76), NSPoint(x: 40, y: 59),
      NSPoint(x: 39, y: 70), NSPoint(x: 30, y: 58),
    ], rose)
  shape(
    [
      NSPoint(x: 48, y: 77), NSPoint(x: 67, y: 77), NSPoint(x: 76, y: 67), NSPoint(x: 70, y: 55),
      NSPoint(x: 61, y: 69), NSPoint(x: 58, y: 59),
    ], rose)
  for x: CGFloat in [36, 57] {
    oval(NSRect(x: x - 2, y: 43, width: 11, height: 17), .white)
    oval(
      NSRect(x: x, y: 43, width: 8, height: 15),
      NSColor(calibratedRed: 0.24, green: 0.53, blue: 0.56, alpha: 1))
    oval(NSRect(x: x + 2, y: 46, width: 4, height: 10), ink)
    oval(NSRect(x: x + 1, y: 52, width: 4, height: 5), .white)
    line([NSPoint(x: x - 3, y: 57), NSPoint(x: x + 1, y: 60), NSPoint(x: x + 8, y: 58)], ink, 2.2)
  }
  oval(NSRect(x: 29, y: 37, width: 12, height: 5), rose.withAlphaComponent(0.55))
  oval(NSRect(x: 60, y: 37, width: 12, height: 5), rose.withAlphaComponent(0.55))
  line([NSPoint(x: 46, y: 37), NSPoint(x: 50, y: 35), NSPoint(x: 54, y: 37)])
  shape(
    [
      NSPoint(x: 68, y: 74), NSPoint(x: 63, y: 88), NSPoint(x: 77, y: 83), NSPoint(x: 85, y: 91),
      NSPoint(x: 87, y: 76), NSPoint(x: 77, y: 78),
    ], ink)
  oval(NSRect(x: 73, y: 77, width: 7, height: 7), .white)
  line([NSPoint(x: 21, y: 86), NSPoint(x: 21, y: 94)], hair, 2)
  line([NSPoint(x: 17, y: 90), NSPoint(x: 25, y: 90)], hair, 2)
  line([NSPoint(x: 86, y: 15), NSPoint(x: 86, y: 24)], hair, 2)
  line([NSPoint(x: 82, y: 19), NSPoint(x: 90, y: 19)], hair, 2)
  image.unlockFocus()
  return image
}
// Full-body companion. The portrait remains the square application icon.
func mascotImage(
  _ height: CGFloat = 512, blink: Bool = false, working: Bool = false, happy: Bool = false
) -> NSImage {
  let image = NSImage(size: NSSize(width: height * 2 / 3, height: height))
  image.lockFocus()
  let transform = NSAffineTransform()
  transform.scale(by: height / 150)
  transform.concat()
  let skin = NSColor(calibratedRed: 1, green: 0.89, blue: 0.82, alpha: 1)
  let hair = NSColor(calibratedRed: 0.94, green: 0.54, blue: 0.65, alpha: 1)
  func oval(_ r: NSRect, _ color: NSColor, outline: Bool = false) {
    let p = NSBezierPath(ovalIn: r)
    color.setFill()
    p.fill()
    if outline {
      ink.setStroke()
      p.lineWidth = 1.1
      p.stroke()
    }
  }
  func shape(_ points: [NSPoint], _ color: NSColor) {
    let p = NSBezierPath()
    p.move(to: points[0])
    points.dropFirst().forEach { p.line(to: $0) }
    p.close()
    color.setFill()
    p.fill()
    ink.setStroke()
    p.lineWidth = 1.1
    p.lineJoinStyle = .round
    p.stroke()
  }
  func line(_ points: [NSPoint], _ color: NSColor = ink, width: CGFloat = 1.4) {
    let p = NSBezierPath()
    p.move(to: points[0])
    points.dropFirst().forEach { p.line(to: $0) }
    color.setStroke()
    p.lineWidth = width
    p.lineCapStyle = .round
    p.stroke()
  }
  oval(NSRect(x: 27, y: 6, width: 57, height: 8), ink.withAlphaComponent(0.12))
  // Broom, with a wooden handle and rose bristle tie.
  line(
    [NSPoint(x: 13, y: 24), NSPoint(x: 24, y: 104)],
    NSColor(calibratedRed: 0.62, green: 0.39, blue: 0.27, alpha: 1), width: 3)
  shape(
    [NSPoint(x: 9, y: 31), NSPoint(x: 20, y: 30), NSPoint(x: 29, y: 11), NSPoint(x: 3, y: 13)],
    NSColor(calibratedRed: 0.98, green: 0.76, blue: 0.47, alpha: 1))
  line([NSPoint(x: 12, y: 28), NSPoint(x: 9, y: 15)], ink.withAlphaComponent(0.4), width: 0.7)
  line([NSPoint(x: 16, y: 28), NSPoint(x: 18, y: 14)], ink.withAlphaComponent(0.4), width: 0.7)
  line([NSPoint(x: 8, y: 29), NSPoint(x: 22, y: 28)], hair, width: 3)
  // Twin tails sit behind the shoulders, rather than inside a portrait badge.
  oval(NSRect(x: 19, y: 76, width: 24, height: 59), hair, outline: true)
  oval(NSRect(x: 71, y: 76, width: 23, height: 59), hair, outline: true)
  oval(NSRect(x: 29, y: 93, width: 53, height: 50), hair, outline: true)
  // Stockings and boots, drawn before the skirt.
  shape(
    [NSPoint(x: 41, y: 53), NSPoint(x: 52, y: 53), NSPoint(x: 51, y: 19), NSPoint(x: 42, y: 19)],
    .white)
  shape(
    [NSPoint(x: 60, y: 53), NSPoint(x: 71, y: 53), NSPoint(x: 70, y: 19), NSPoint(x: 61, y: 19)],
    .white)
  shape(
    [NSPoint(x: 40, y: 24), NSPoint(x: 52, y: 24), NSPoint(x: 54, y: 12), NSPoint(x: 36, y: 12)],
    ink)
  shape(
    [NSPoint(x: 60, y: 24), NSPoint(x: 72, y: 24), NSPoint(x: 77, y: 12), NSPoint(x: 58, y: 12)],
    ink)
  line([NSPoint(x: 41, y: 19), NSPoint(x: 48, y: 19)], rose, width: 2)
  line([NSPoint(x: 63, y: 19), NSPoint(x: 69, y: 19)], rose, width: 2)
  oval(NSRect(x: 47, y: 87, width: 18, height: 13), skin, outline: true)
  // Left hand holds the broom. Right hand changes pose while working.
  shape(
    [
      NSPoint(x: 43, y: 91), NSPoint(x: 35, y: 86), NSPoint(x: 24, y: 74), NSPoint(x: 29, y: 68),
      NSPoint(x: 45, y: 81),
    ], ink)
  oval(NSRect(x: 21, y: 67, width: 11, height: 11), skin, outline: true)
  if working || happy {
    shape(
      [
        NSPoint(x: 67, y: 89), NSPoint(x: 76, y: 81), NSPoint(x: 88, y: 100),
        NSPoint(x: 83, y: 105), NSPoint(x: 71, y: 92),
      ], ink)
    oval(NSRect(x: 81, y: 102, width: 11, height: 12), skin, outline: true)
    line([NSPoint(x: 86, y: 113), NSPoint(x: 84, y: 117)], ink, width: 1)
  } else {
    shape(
      [
        NSPoint(x: 68, y: 91), NSPoint(x: 76, y: 85), NSPoint(x: 86, y: 65), NSPoint(x: 79, y: 62),
        NSPoint(x: 65, y: 81),
      ], ink)
    oval(NSRect(x: 78, y: 57, width: 10, height: 12), skin, outline: true)
  }
  shape(
    [NSPoint(x: 42, y: 94), NSPoint(x: 68, y: 94), NSPoint(x: 74, y: 64), NSPoint(x: 36, y: 64)],
    ink)
  shape(
    [NSPoint(x: 40, y: 67), NSPoint(x: 70, y: 67), NSPoint(x: 82, y: 47), NSPoint(x: 29, y: 47)],
    ink)
  shape(
    [NSPoint(x: 43, y: 65), NSPoint(x: 67, y: 65), NSPoint(x: 73, y: 49), NSPoint(x: 38, y: 49)],
    .white)
  line([NSPoint(x: 31, y: 46), NSPoint(x: 80, y: 46)], rose, width: 2)
  shape(
    [
      NSPoint(x: 43, y: 92), NSPoint(x: 55, y: 81), NSPoint(x: 67, y: 92), NSPoint(x: 64, y: 69),
      NSPoint(x: 47, y: 69),
    ], .white)
  shape(
    [
      NSPoint(x: 55, y: 83), NSPoint(x: 47, y: 88), NSPoint(x: 47, y: 79), NSPoint(x: 55, y: 83),
      NSPoint(x: 64, y: 88), NSPoint(x: 64, y: 79),
    ], rose)
  oval(NSRect(x: 52, y: 80, width: 6, height: 6), hair)
  oval(NSRect(x: 33, y: 95, width: 45, height: 40), skin, outline: true)
  oval(NSRect(x: 29, y: 122, width: 53, height: 20), rose, outline: true)
  shape(
    [
      NSPoint(x: 31, y: 132), NSPoint(x: 42, y: 140), NSPoint(x: 54, y: 133),
      NSPoint(x: 44, y: 118), NSPoint(x: 43, y: 130), NSPoint(x: 34, y: 116),
    ], rose)
  shape(
    [
      NSPoint(x: 51, y: 135), NSPoint(x: 70, y: 135), NSPoint(x: 80, y: 125),
      NSPoint(x: 74, y: 114), NSPoint(x: 65, y: 126), NSPoint(x: 62, y: 117),
    ], rose)
  for x: CGFloat in [42, 61] {
    if blink || happy {
      line(
        [
          NSPoint(x: x - 2, y: 111), NSPoint(x: x + 3, y: happy ? 114 : 111),
          NSPoint(x: x + 8, y: 111),
        ], ink, width: 1.8)
    } else {
      oval(NSRect(x: x - 1, y: 105, width: 10, height: 15), .white)
      oval(
        NSRect(x: x, y: 105, width: 8, height: 14),
        NSColor(calibratedRed: 0.24, green: 0.53, blue: 0.56, alpha: 1))
      oval(NSRect(x: x + 2, y: 107, width: 4, height: 10), ink)
      oval(NSRect(x: x + 1, y: 114, width: 4, height: 4), .white)
      line(
        [NSPoint(x: x - 2, y: 119), NSPoint(x: x + 2, y: 121), NSPoint(x: x + 8, y: 119)], ink,
        width: 1.8)
    }
  }
  oval(NSRect(x: 34, y: 101, width: 10, height: 4), rose.withAlphaComponent(0.6))
  oval(NSRect(x: 67, y: 101, width: 10, height: 4), rose.withAlphaComponent(0.6))
  line([NSPoint(x: 51, y: 100), NSPoint(x: 55, y: happy ? 96 : 98), NSPoint(x: 59, y: 100)])
  shape(
    [
      NSPoint(x: 71, y: 130), NSPoint(x: 68, y: 145), NSPoint(x: 79, y: 140),
      NSPoint(x: 88, y: 147), NSPoint(x: 89, y: 133), NSPoint(x: 79, y: 135),
    ], ink)
  oval(NSRect(x: 76, y: 134, width: 6, height: 6), .white)
  if working || happy {
    line([NSPoint(x: 9, y: 114), NSPoint(x: 9, y: 124)], hair, width: 2)
    line([NSPoint(x: 4, y: 119), NSPoint(x: 14, y: 119)], hair, width: 2)
    line([NSPoint(x: 92, y: 57), NSPoint(x: 92, y: 67)], hair, width: 2)
    line([NSPoint(x: 87, y: 62), NSPoint(x: 97, y: 62)], hair, width: 2)
  }
  image.unlockFocus()
  return image
}
func fittedRect(_ image: NSSize, in box: NSRect) -> NSRect {
  guard image.width > 0, image.height > 0 else { return .zero }
  let scale = min(box.width / image.width, box.height / image.height)
  let size = NSSize(width: image.width * scale, height: image.height * scale)
  return NSRect(
    x: box.midX - size.width / 2, y: box.midY - size.height / 2, width: size.width,
    height: size.height)
}
func pngData(_ image: NSImage) -> Data? {
  guard let tiff = image.tiffRepresentation, let bitmap = NSBitmapImageRep(data: tiff) else {
    return nil
  }
  return bitmap.representation(using: .png, properties: [:])
}
final class AvatarView: NSView {
  var usesDefault = true
  private var active = false, blinking = false, cheering = false
  private var blinkTimer: Timer?
  private let idleImage = mascotImage()
  private let closedEyesImage = mascotImage(blink: true)
  private let workingImage = mascotImage(working: true)
  private let happyImage = mascotImage(happy: true)
  override func viewDidMoveToWindow() {
    super.viewDidMoveToWindow()
    blinkTimer?.invalidate()
    guard window != nil else { return }
    blinkTimer = Timer.scheduledTimer(withTimeInterval: 4.8, repeats: true) { [weak self] _ in
      guard let self = self, self.usesDefault, !self.active, !self.cheering,
        !NSWorkspace.shared.accessibilityDisplayShouldReduceMotion
      else { return }
      self.blinking = true
      self.needsDisplay = true
      DispatchQueue.main.asyncAfter(deadline: .now() + 0.14) { [weak self] in
        self?.blinking = false
        self?.needsDisplay = true
      }
    }
  }
  deinit { blinkTimer?.invalidate() }
  func setActivity(_ active: Bool) {
    self.active = active
    needsDisplay = true
    wantsLayer = true
    layer?.removeAnimation(forKey: "activity")
    guard active, !NSWorkspace.shared.accessibilityDisplayShouldReduceMotion else { return }
    let pulse = CABasicAnimation(keyPath: "transform.rotation.z")
    pulse.fromValue = -0.025
    pulse.toValue = 0.025
    pulse.duration = 0.65
    pulse.autoreverses = true
    pulse.repeatCount = .infinity
    layer?.add(pulse, forKey: "activity")
  }
  func celebrate() {
    cheering = true
    needsDisplay = true
    DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { [weak self] in
      self?.cheering = false
      self?.needsDisplay = true
    }
    guard !NSWorkspace.shared.accessibilityDisplayShouldReduceMotion else { return }
    let hop = CAKeyframeAnimation(keyPath: "transform.translation.y")
    hop.values = [0, 7, -3, 2, 0]
    hop.duration = 0.55
    layer?.add(hop, forKey: "celebrate")
  }
  var image = mascotImage()
  var onClick: (() -> Void)?, onMove: (() -> Void)?
  var contextMenu: NSMenu?
  private var origin = NSPoint.zero, mouseOrigin = NSPoint.zero
  private var dragged = false
  override func draw(_ dirtyRect: NSRect) {
    let artwork =
      usesDefault
      ? (cheering ? happyImage : active ? workingImage : blinking ? closedEyesImage : idleImage)
      : image
    artwork.draw(
      in: fittedRect(
        artwork.size, in: NSRect(x: 8, y: 28, width: bounds.width - 16, height: bounds.height - 36)),
      from: .zero, operation: .sourceOver, fraction: 1)
    let attrs: [NSAttributedString.Key: Any] = [
      .font: NSFont.monospacedSystemFont(ofSize: 9, weight: .bold), .foregroundColor: ink,
    ]
    let text = "CACHE-CHAN"
    let size = "CACHE-CHAN".size(withAttributes: attrs)
    let pill = NSRect(
      x: (bounds.width - size.width) / 2 - 7, y: 5, width: size.width + 14, height: 17)
    NSColor.white.setFill()
    NSBezierPath(roundedRect: pill, xRadius: 8, yRadius: 8).fill()
    text.draw(at: NSPoint(x: pill.minX + 7, y: 8), withAttributes: attrs)
  }
  override func mouseDown(with event: NSEvent) {
    origin = window?.frame.origin ?? .zero
    mouseOrigin = NSEvent.mouseLocation
    dragged = false
  }
  override func mouseDragged(with event: NSEvent) {
    let p = NSEvent.mouseLocation
    if hypot(p.x - mouseOrigin.x, p.y - mouseOrigin.y) > 4 { dragged = true }
    if dragged {
      window?.setFrameOrigin(
        NSPoint(x: origin.x + p.x - mouseOrigin.x, y: origin.y + p.y - mouseOrigin.y))
    }
  }
  override func mouseUp(with event: NSEvent) { if dragged { onMove?() } else { onClick?() } }
  override func rightMouseDown(with event: NSEvent) {
    if let m = contextMenu { NSMenu.popUpContextMenu(m, with: event, for: self) }
  }
  override var acceptsFirstResponder: Bool { true }
  override func keyDown(with event: NSEvent) {
    if event.keyCode == 36 || event.keyCode == 49 { onClick?() } else { super.keyDown(with: event) }
  }
  override func accessibilityPerformPress() -> Bool {
    onClick?()
    return true
  }
}
