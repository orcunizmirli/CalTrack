import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var appState: AppState

    var body: some View {
        NavigationStack {
            List {
                // Profile Section
                Section {
                    NavigationLink(destination: ProfileEditView()) {
                        HStack(spacing: 14) {
                            Image(systemName: "person.circle.fill")
                                .font(.system(size: 44))
                                .foregroundStyle(.ctAccent)

                            VStack(alignment: .leading, spacing: 2) {
                                Text("Kullanıcı")
                                    .font(.ctHeadline)
                                Text("Profil bilgilerini düzenle")
                                    .font(.ctCaption)
                                    .foregroundStyle(.ctTextSecondary)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }

                // Goals
                Section("Hedefler") {
                    NavigationLink(destination: GoalsOverviewView()) {
                        Label("Kalori & Makro Hedefleri", systemImage: "target")
                    }
                    NavigationLink(destination: MicroNutrientView()) {
                        Label("Mikro Besin Takibi", systemImage: "leaf.fill")
                    }
                }

                // Recipes
                Section("Tarifler") {
                    NavigationLink(destination: RecipeRequestView()) {
                        Label("AI Tarif Önerisi", systemImage: "sparkles")
                    }
                    NavigationLink(destination: SavedRecipesView()) {
                        Label("Kayıtlı Tarifler", systemImage: "bookmark.fill")
                    }
                }

                // Integrations
                Section("Entegrasyonlar") {
                    NavigationLink(destination: HealthKitSettingsView()) {
                        Label("Apple Health", systemImage: "heart.fill")
                    }
                }

                // Preferences
                Section("Tercihler") {
                    NavigationLink(destination: NotificationSettingsView()) {
                        Label("Bildirimler", systemImage: "bell.fill")
                    }

                    HStack {
                        Label("Birim Sistemi", systemImage: "ruler")
                        Spacer()
                        Text("Metrik")
                            .foregroundStyle(.ctTextSecondary)
                    }

                    HStack {
                        Label("Dil", systemImage: "globe")
                        Spacer()
                        Text("Türkçe")
                            .foregroundStyle(.ctTextSecondary)
                    }
                }

                // About
                Section("Hakkında") {
                    HStack {
                        Text("Versiyon")
                        Spacer()
                        Text("1.0.0")
                            .foregroundStyle(.ctTextSecondary)
                    }

                    Link(destination: URL(string: "https://caltrack.app/privacy")!) {
                        Label("Gizlilik Politikası", systemImage: "lock.shield")
                    }

                    Link(destination: URL(string: "https://caltrack.app/terms")!) {
                        Label("Kullanım Koşulları", systemImage: "doc.text")
                    }
                }

                // Danger Zone
                Section {
                    Button(action: {
                        appState.signOut()
                    }) {
                        Label("Çıkış Yap", systemImage: "rectangle.portrait.and.arrow.right")
                            .foregroundStyle(.ctError)
                    }

                    Button(role: .destructive, action: {}) {
                        Label("Hesabı Sil", systemImage: "trash")
                    }
                }
            }
            .scrollContentBackground(.hidden)
            .background(Color.ctBackground)
            .navigationTitle("Profil")
        }
    }
}

struct ProfileEditView: View {
    @State private var name = ""
    @State private var height: Double = 170
    @State private var weight: Double = 70

    var body: some View {
        Form {
            Section("Kişisel Bilgiler") {
                TextField("İsim", text: $name)

                HStack {
                    Text("Boy")
                    Spacer()
                    Text("\(Int(height)) cm")
                        .foregroundStyle(.ctTextSecondary)
                }

                HStack {
                    Text("Kilo")
                    Spacer()
                    Text(String(format: "%.1f kg", weight))
                        .foregroundStyle(.ctTextSecondary)
                }
            }
        }
        .scrollContentBackground(.hidden)
        .background(Color.ctBackground)
        .navigationTitle("Profil Düzenle")
    }
}

struct SavedRecipesView: View {
    var body: some View {
        Text("Kayıtlı tarifler burada gösterilecek")
            .foregroundStyle(.ctTextSecondary)
            .navigationTitle("Kayıtlı Tarifler")
    }
}

struct HealthKitSettingsView: View {
    @StateObject private var healthKit = HealthKitManager.shared

    var body: some View {
        List {
            Section {
                HStack {
                    Image(systemName: "heart.fill")
                        .foregroundStyle(.red)
                    Text("Apple Health Bağlantısı")
                    Spacer()
                    Text(healthKit.isAuthorized ? "Bağlı" : "Bağlı Değil")
                        .foregroundStyle(healthKit.isAuthorized ? .ctSuccess : .ctTextSecondary)
                }

                if !healthKit.isAuthorized {
                    Button("Bağlantı Kur") {
                        Task { try? await healthKit.requestAuthorization() }
                    }
                }
            }

            Section("Okunan Veriler") {
                Label("Boy, Kilo, Yaş", systemImage: "figure.stand")
                Label("Adım Sayısı", systemImage: "figure.walk")
                Label("Aktif Kalori", systemImage: "flame")
                Label("Antrenmanlar", systemImage: "dumbbell")
            }

            Section("Yazılan Veriler") {
                Label("Kalori Alımı", systemImage: "fork.knife")
                Label("Su Tüketimi", systemImage: "drop")
                Label("Kilo Kaydı", systemImage: "scalemass")
            }
        }
        .scrollContentBackground(.hidden)
        .background(Color.ctBackground)
        .navigationTitle("Apple Health")
    }
}

struct NotificationSettingsView: View {
    @State private var breakfastReminder = true
    @State private var lunchReminder = true
    @State private var dinnerReminder = true
    @State private var waterReminder = false

    var body: some View {
        List {
            Section("Öğün Hatırlatmaları") {
                Toggle("Kahvaltı", isOn: $breakfastReminder)
                Toggle("Öğle Yemeği", isOn: $lunchReminder)
                Toggle("Akşam Yemeği", isOn: $dinnerReminder)
            }

            Section("Diğer") {
                Toggle("Su İçme Hatırlatması", isOn: $waterReminder)
            }
        }
        .scrollContentBackground(.hidden)
        .background(Color.ctBackground)
        .navigationTitle("Bildirimler")
    }
}
