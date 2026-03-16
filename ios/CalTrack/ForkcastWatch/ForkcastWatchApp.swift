import SwiftUI

@main
struct ForkcastWatchApp: App {
    @StateObject private var connectivity = WatchConnectivityManager()

    var body: some Scene {
        WindowGroup {
            WatchHomeView()
                .environmentObject(connectivity)
        }
    }
}
