// Deterministic vector artwork based on WealthOne's original rising-chart identity.
// Run from the repository root: swift native-ios/Tools/generate-icons.swift
import AppKit
import Foundation

let root = URL(fileURLWithPath: FileManager.default.currentDirectoryPath).appendingPathComponent(
  "native-ios")
let size = 1024
let points: [CGPoint] = [
  .init(x: 0, y: 0.55), .init(x: 0.06, y: 0.56), .init(x: 0.12, y: 0.60),
  .init(x: 0.18, y: 0.63), .init(x: 0.24, y: 0.59), .init(x: 0.30, y: 0.53),
  .init(x: 0.36, y: 0.59), .init(x: 0.42, y: 0.43), .init(x: 0.48, y: 0.61),
  .init(x: 0.53, y: 0.65), .init(x: 0.59, y: 0.52), .init(x: 0.65, y: 0.50),
  .init(x: 0.71, y: 0.29), .init(x: 0.77, y: 0.47), .init(x: 0.83, y: 0.43),
  .init(x: 0.88, y: 0.59), .init(x: 0.93, y: 0.45), .init(x: 1, y: 0.35),
]
func rgb(_ r: CGFloat, _ g: CGFloat, _ b: CGFloat) -> NSColor {
  NSColor(srgbRed: r, green: g, blue: b, alpha: 1)
}
func render(
  _ name: String, folder: String, top: NSColor, bottom: NSColor, stroke: NSColor,
  watch: Bool = false
) throws {
  let drawing = CGContext(
    data: nil, width: size, height: size, bitsPerComponent: 8,
    bytesPerRow: size * 4, space: CGColorSpace(name: CGColorSpace.sRGB)!,
    bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue)!
  let context = NSGraphicsContext(cgContext: drawing, flipped: false)
  NSGraphicsContext.saveGraphicsState()
  NSGraphicsContext.current = context
  let rect = NSRect(x: 0, y: 0, width: size, height: size)
  NSGradient(starting: bottom, ending: top)!.draw(in: rect, angle: 90)
  let line = NSBezierPath()
  for (index, point) in points.enumerated() {
    // Inset the Watch motif to preserve it under the circular system mask.
    let x = watch ? 0.11 + point.x * 0.78 : point.x
    let y = watch ? 0.08 + point.y * 0.82 : point.y
    let position = CGPoint(x: x * CGFloat(size), y: (1 - y) * CGFloat(size))
    if index == 0 { line.move(to: position) } else { line.line(to: position) }
  }
  line.lineWidth = watch ? 29 : 27
  line.lineCapStyle = .round
  line.lineJoinStyle = .round
  stroke.setStroke()
  line.stroke()
  NSGraphicsContext.restoreGraphicsState()
  let directory = root.appendingPathComponent(folder + "/Assets.xcassets/AppIcon.appiconset")
  try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
  let bitmap = NSBitmapImageRep(cgImage: drawing.makeImage()!)
  try bitmap.representation(using: .png, properties: [:])!.write(
    to: directory.appendingPathComponent(name))
}
try render(
  "WealthOne-Light.png", folder: "App", top: .white, bottom: rgb(0.89, 0.95, 1),
  stroke: rgb(0.04, 0.31, 0.66))
try render(
  "WealthOne-Dark.png", folder: "App", top: rgb(0.11, 0.22, 0.36), bottom: rgb(0.035, 0.08, 0.15),
  stroke: rgb(0.77, 0.89, 1))
try render(
  "WealthOne-Watch.png", folder: "Watch", top: rgb(0.12, 0.57, 1), bottom: rgb(0, 0.31, 0.83),
  stroke: .white, watch: true)

let info: [String: Any] = ["author": "xcode", "version": 1]
let appImages: [[String: Any]] = [
  [
    "filename": "WealthOne-Light.png", "idiom": "universal", "platform": "ios", "size": "1024x1024",
  ],
  [
    "filename": "WealthOne-Dark.png", "idiom": "universal", "platform": "ios", "size": "1024x1024",
    "appearances": [["appearance": "luminosity", "value": "dark"]],
  ],
]
let watchImages: [[String: Any]] = [
  [
    "filename": "WealthOne-Watch.png", "idiom": "universal", "platform": "watchos",
    "size": "1024x1024",
  ]
]
for (folder, images) in [("App", appImages), ("Watch", watchImages)] {
  let catalog = root.appendingPathComponent(folder + "/Assets.xcassets")
  try JSONSerialization.data(
    withJSONObject: ["images": images, "info": info], options: [.prettyPrinted, .sortedKeys]
  )
  .write(to: catalog.appendingPathComponent("AppIcon.appiconset/Contents.json"))
  if folder == "Watch" {
    try JSONSerialization.data(
      withJSONObject: ["info": info], options: [.prettyPrinted, .sortedKeys]
    )
    .write(to: catalog.appendingPathComponent("Contents.json"))
  }
}
print("Generated iPhone light/dark and Watch icon catalogs.")
