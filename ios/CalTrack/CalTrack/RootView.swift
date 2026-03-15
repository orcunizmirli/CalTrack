import SwiftUI

struct RootView: View {
    @EnvironmentObject var appState: AppState

    var body: some View {
        Group {
            if !appState.isAuthenticated {
                WelcomeView()
            } else if !appState.isOnboardingComplete {
                OnboardingFlowView()
            } else {
                MainTabView()
            }
        }
        .animation(.ctSpring, value: appState.isAuthenticated)
        .animation(.ctSpring, value: appState.isOnboardingComplete)
    }
}

struct MainTabView: View {
    @State private var selectedTab = AppTab.home
    @State private var showAIScan = false

    enum AppTab: String, CaseIterable {
        case home, search, scan, analytics, profile
    }

    var body: some View {
        TabView(selection: $selectedTab) {
            Tab("Ana Sayfa", systemImage: "house.fill", value: .home) {
                DashboardView()
            }

            Tab("Ara", systemImage: "magnifyingglass", value: .search) {
                FoodSearchView()
            }

            Tab("Tara", systemImage: "camera.fill", value: .scan) {
                Color.clear
            }

            Tab("Analiz", systemImage: "chart.bar.fill", value: .analytics) {
                AnalyticsView()
            }

            Tab("Profil", systemImage: "person.fill", value: .profile) {
                SettingsView()
            }
        }
        .tabViewStyle(.tabBarOnly)
        .tabBarMinimizeBehavior(.onScrollDown)
        .onChange(of: selectedTab) { _, newValue in
            if newValue == .scan {
                HapticManager.medium()
                showAIScan = true
                selectedTab = .home
            }
        }
        .fullScreenCover(isPresented: $showAIScan) {
            AIFoodScanView()
        }
    }
}
