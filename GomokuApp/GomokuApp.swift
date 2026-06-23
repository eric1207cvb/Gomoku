import SwiftUI

@main
struct GomokuApp: App {
    @StateObject private var monetization = MonetizationStore()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(monetization)
                .preferredColorScheme(.light)
                .task {
                    monetization.configure()
                }
        }
    }
}
