import SwiftUI

@main
struct WealthOneApp: App {
  @StateObject private var model = AppModel()
  @Environment(\.scenePhase) private var scenePhase
  var body: some Scene {
    WindowGroup {
      RootTabView().environmentObject(model)
        .task {
          await model.start()
          while !Task.isCancelled {
            do { try await Task.sleep(for: .seconds(60)) } catch { break }
            if scenePhase == .active { await model.synchronize() }
          }
        }
        .onChange(of: scenePhase) { _, phase in
          if phase == .active { Task { await model.synchronize() } }
        }
        .alert(
          "WealthOne",
          isPresented: Binding(get: { model.error != nil }, set: { if !$0 { model.error = nil } })
        ) {
          Button("OK") { model.error = nil }
        } message: {
          Text(model.error ?? "")
        }
    }
  }
}
