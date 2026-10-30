import Foundation
import ImageIO
import XCTest

final class AppIconTests: XCTestCase {
  func testNativeIconCatalogsContainValidPlatformArtwork() throws {
    let root = URL(fileURLWithPath: #filePath).deletingLastPathComponent()
      .deletingLastPathComponent().deletingLastPathComponent()
    for platform in ["App", "Watch"] {
      let catalog = root.appendingPathComponent(platform + "/Assets.xcassets/AppIcon.appiconset")
      let data = try Data(contentsOf: catalog.appendingPathComponent("Contents.json"))
      let json = try XCTUnwrap(JSONSerialization.jsonObject(with: data) as? [String: Any])
      let images = try XCTUnwrap(json["images"] as? [[String: Any]])
      if platform == "App" {
        XCTAssertTrue(
          images.contains {
            ($0["appearances"] as? [[String: String]])?.contains {
              $0["appearance"] == "luminosity" && $0["value"] == "dark"
            } == true
          }, "A dark iPhone icon must be supplied")
      }
      XCTAssertFalse(images.isEmpty)
      for item in images {
        let filename = try XCTUnwrap(item["filename"] as? String)
        let source = try XCTUnwrap(
          CGImageSourceCreateWithURL(catalog.appendingPathComponent(filename) as CFURL, nil))
        let image = try XCTUnwrap(CGImageSourceCreateImageAtIndex(source, 0, nil))
        XCTAssertEqual(image.width, 1024)
        XCTAssertEqual(image.height, 1024)
      }
    }
  }
}
