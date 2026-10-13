// Copyright (c) 2026 guoxianzhe. SPDX-License-Identifier: MIT
import Cocoa

let ink = NSColor(calibratedRed: 0.18, green: 0.15, blue: 0.24, alpha: 1)
let rose = NSColor(calibratedRed: 1, green: 0.67, blue: 0.74, alpha: 1)

// Original character artwork, drawn locally with native vector primitives.
func mascotImage(_ dimension: CGFloat = 512) -> NSImage {
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
func pngData(_ image: NSImage) -> Data? {
  guard let tiff = image.tiffRepresentation, let bitmap = NSBitmapImageRep(data: tiff) else {
    return nil
  }
  return bitmap.representation(using: .png, properties: [:])
}
final class AvatarView: NSView {
  var image = mascotImage()
  var onClick: (() -> Void)?, onMove: (() -> Void)?
  var contextMenu: NSMenu?
  private var origin = NSPoint.zero, mouseOrigin = NSPoint.zero
  private var dragged = false
  override func draw(_ dirtyRect: NSRect) {
    let circle = NSRect(x: 8, y: 25, width: 88, height: 88)
    NSGraphicsContext.saveGraphicsState()
    NSBezierPath(ovalIn: circle).addClip()
    let side = min(image.size.width, image.size.height)
    image.draw(
      in: circle,
      from: NSRect(
        x: (image.size.width - side) / 2, y: (image.size.height - side) / 2, width: side,
        height: side), operation: .sourceOver, fraction: 1)
    NSGraphicsContext.restoreGraphicsState()
    rose.setStroke()
    let ring = NSBezierPath(ovalIn: circle)
    ring.lineWidth = 2
    ring.stroke()
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
