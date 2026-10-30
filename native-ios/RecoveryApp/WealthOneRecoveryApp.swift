import SwiftUI

/// Original app identity, but only read-only legacy discovery and file export.
@main
struct WealthOneRecoveryApp: App {
  @StateObject private var recovery = LegacyRecoveryModel()
  var body: some Scene {
    WindowGroup {
      NavigationStack { LegacyRecoveryBrowser(recovery: recovery) }.tint(.blue)
    }
  }
}
