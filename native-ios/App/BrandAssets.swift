import SwiftUI

/// Compatibility helpers for existing screens, now using native Dynamic Type styles.
enum BrandFont {
  enum Weight { case regular, medium, semibold, bold }
  static func heading(_ size: CGFloat = 28, relativeTo style: Font.TextStyle = .title) -> Font {
    let semantic: Font.TextStyle =
      style == .title ? (size <= 22 ? .title2 : size >= 32 ? .largeTitle : .title) : style
    return .system(semantic, design: .default, weight: .bold)
  }
  static func body(
    _ size: CGFloat = 16, relativeTo style: Font.TextStyle = .body,
    weight: Weight = .regular
  ) -> Font {
    let semantic: Font.TextStyle =
      style == .body
      ? (size <= 11
        ? .caption2
        : size <= 12 ? .caption : size <= 14 ? .subheadline : size <= 16 ? .callout : .body) : style
    let nativeWeight: Font.Weight =
      switch weight {
      case .regular: .regular
      case .medium: .medium
      case .semibold: .semibold
      case .bold: .bold
      }
    return .system(semantic, design: .default, weight: nativeWeight)
  }
}

/// Existing call-site names map to SF Symbols; no legacy glyph font is used.
struct FeatherIcon: View {
  let name: String
  var size: CGFloat = 22
  @ScaledMetric private var scale: CGFloat = 1
  var body: some View {
    Image(systemName: Self.symbol(name)).font(.system(size: size * scale))
      .accessibilityHidden(true)
  }
  static func image(_ name: String, size: CGFloat = 24) -> Image {
    Image(systemName: symbol(name))
  }
  static func symbol(_ name: String) -> String {
    symbols[name] ?? "info.circle"
  }
  private static let symbols: [String: String] = [
    "home": "house.fill", "bar-chart": "chart.pie.fill", "target": "target",
    "list": "clock.arrow.circlepath", "settings": "gearshape.fill", "plus": "plus",
    "save": "checkmark", "trash": "trash", "chevron-left": "chevron.left",
    "chevron-right": "chevron.right", "chevron-down": "chevron.down",
    "sliders": "slider.horizontal.3", "arrow-up-right": "arrow.up.right",
    "arrow-down-right": "arrow.down.right", "trending-up": "chart.line.uptrend.xyaxis",
    "trending-down": "chart.line.downtrend.xyaxis", "credit-card": "creditcard",
    "dollar-sign": "sterlingsign.circle", "briefcase": "chart.bar.fill",
    "pie-chart": "chart.pie", "download": "square.and.arrow.down",
    "upload": "square.and.arrow.up", "cloud": "icloud", "check": "checkmark",
    "check-circle": "checkmark.circle", "alert-circle": "exclamationmark.circle",
    "clock": "clock", "calendar": "calendar", "eye": "eye", "info": "info.circle",
    "x": "xmark", "search": "magnifyingglass", "refresh-cw": "arrow.clockwise",
    "shield": "checkmark.shield", "file-text": "doc.text", "edit-2": "pencil",
    "arrow-right": "arrow.right", "more-horizontal": "ellipsis",
  ]
}
