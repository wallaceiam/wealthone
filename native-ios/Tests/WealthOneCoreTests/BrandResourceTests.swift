#if canImport(CoreText)
  import CoreText
  import Foundation
  import XCTest

  final class BrandResourceTests: XCTestCase {
    func testBundledLegacyFontNamesAndFeatherGlyphs() throws {
      let root = URL(fileURLWithPath: #filePath).deletingLastPathComponent()
        .deletingLastPathComponent().deletingLastPathComponent()
      let names = [
        "Karla-Regular", "Karla-Bold", "Montserrat-Regular", "Montserrat-Medium",
        "Montserrat-SemiBold", "Montserrat-Bold", "Feather",
      ]
      for name in names {
        let url = root.appendingPathComponent("App/Resources/Fonts/" + name + ".ttf")
        XCTAssertTrue(FileManager.default.fileExists(atPath: url.path), "Missing font: " + name)
        let descriptors = try XCTUnwrap(
          CTFontManagerCreateFontDescriptorsFromURL(url as CFURL) as? [CTFontDescriptor])
        XCTAssertTrue(
          descriptors.contains {
            CTFontDescriptorCopyAttribute($0, kCTFontNameAttribute) as? String == name
          }, "Incorrect PostScript name: " + name)
        if name == "Feather" {
          let font = CTFontCreateWithFontDescriptor(try XCTUnwrap(descriptors.first), 24, nil)
          var character: UniChar = 61828  // Existing Feather home glyph
          var glyph: CGGlyph = 0
          XCTAssertTrue(CTFontGetGlyphsForCharacters(font, &character, &glyph, 1))
          XCTAssertNotEqual(glyph, 0)
        }
      }
    }
  }
#endif
