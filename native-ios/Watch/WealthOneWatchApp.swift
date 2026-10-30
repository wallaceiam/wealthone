import SwiftUI

@main
struct WealthOneWatchApp: App {
  @StateObject private var model = WatchModel()
  var body: some Scene {
    WindowGroup {
      NavigationStack { WatchHomeView() }.environmentObject(model).tint(.blue)
    }
  }
}
