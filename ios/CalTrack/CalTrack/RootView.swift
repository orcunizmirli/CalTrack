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
        .animation(.easeInOut, value: appState.isAuthenticated)
        .animation(.easeInOut, value: appState.isOnboardingComplete)
    }
}

struct MainTabView: View {
    @State private var selectedTab = 0
    @State private var showAIScan = false

    var body: some View {
        ZStack(alignment: .bottom) {
            TabView(selection: $selectedTab) {
                DashboardView()
                    .tabItem {
                        Image(systemName: "house.fill")
                        Text("Ana Sayfa")
                    }
                    .tag(0)

                FoodSearchView()
                    .tabItem {
                        Image(systemName: "magnifyingglass")
                        Text("Ara")
                    }
                    .tag(1)

                Color.clear
                    .tabItem {
                        Image(systemName: "camera.fill")
                        Text("Tara")
                    }
                    .tag(2)

                AnalyticsView()
                    .tabItem {
                        Image(systemName: "chart.bar.fill")
                        Text("Analiz")
                    }
                    .tag(3)

                SettingsView()
                    .tabItem {
                        Image(systemName: "person.fill")
                        Text("Profil")
                    }
                    .tag(4)
            }
            .onChange(of: selectedTab) { _, newValue in
                if newValue == 2 {
                    showAIScan = true
                    selectedTab = 0
                }
            }

            // Floating AI Scan Button
            Button(action: { showAIScan = true }) {
                ZStack {
                    Circle()
                        .fill(Color.accentColor)
                        .frame(width: 64, height: 64)
                        .shadow(color: Color.accentColor.opacity(0.4), radius: 8, y: 4)

                    Image(systemName: "camera.fill")
                        .font(.system(size: 24, weight: .semibold))
                        .foregroundColor(.white)
                }
            }
            .offset(y: -8)
        }
        .fullScreenCover(isPresented: $showAIScan) {
            AIFoodScanView()
        }
    }
}
