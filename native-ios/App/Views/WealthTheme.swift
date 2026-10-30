import SwiftUI

// Semantic surfaces follow system appearance and accessibility settings.
enum WealthTheme {
  static let background = Color(uiColor: .systemBackground)
  static let ink = Color.primary
  static let blue = Color.blue
  static let paleBlue = Color.blue.opacity(0.12)
  static let chartColors: [Color] = [.blue, .blue.opacity(0.65), .blue.opacity(0.32)]
}
extension View {
  func wealthScreen() -> some View {
    self.frame(maxWidth: 960).frame(maxWidth: .infinity)
      .tint(WealthTheme.blue)
  }
  func wealthNavigationTitle(
    _ title: String,
    displayMode: NavigationBarItem.TitleDisplayMode = .inline
  ) -> some View {
    self.navigationTitle(title).navigationBarTitleDisplayMode(displayMode)
  }
  func wealthCard() -> some View {
    self.padding(.vertical, 16).frame(maxWidth: .infinity, alignment: .leading)
  }
  func protectDraft(_ dirty: Bool, discard: @escaping () -> Void) -> some View {
    modifier(DraftProtection(dirty: dirty, discard: discard))
  }
}
struct DraftProtection: ViewModifier {
  let dirty: Bool
  let discard: () -> Void
  @State private var confirming = false
  func body(content: Content) -> some View {
    content.interactiveDismissDisabled(dirty).navigationBarBackButtonHidden(dirty)
      .toolbar {
        if dirty {
          ToolbarItem(placement: .navigationBarLeading) {
            Button("Cancel") { confirming = true }
          }
        }
      }
      .alert("Discard unsaved changes?", isPresented: $confirming) {
        Button("Discard Changes", role: .destructive, action: discard)
        Button("Keep Editing", role: .cancel) {}
      }
  }
}
