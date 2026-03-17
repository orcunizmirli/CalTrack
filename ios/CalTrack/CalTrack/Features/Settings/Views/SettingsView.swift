import SwiftUI
import UserNotifications

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
    @State private var breakfastTime = dateFrom(hour: 8, minute: 0)
    @State private var lunchReminder = true
    @State private var lunchTime = dateFrom(hour: 12, minute: 30)
    @State private var dinnerReminder = true
    @State private var dinnerTime = dateFrom(hour: 19, minute: 0)
    @State private var waterReminder = false
    @State private var notificationsAuthorized = false
    @State private var showPermissionAlert = false

    var body: some View {
        List {
            if !notificationsAuthorized {
                Section {
                    Button(action: { requestPermission() }) {
                        HStack {
                            Image(systemName: "bell.badge")
                                .foregroundStyle(.ctAccent)
                            Text("Bildirimleri Etkinleştir")
                        }
                    }
                }
            }

            Section("Öğün Hatırlatmaları") {
                Toggle("Kahvaltı", isOn: $breakfastReminder)
                if breakfastReminder {
                    DatePicker("Saat", selection: $breakfastTime, displayedComponents: .hourAndMinute)
                }

                Toggle("Öğle Yemeği", isOn: $lunchReminder)
                if lunchReminder {
                    DatePicker("Saat", selection: $lunchTime, displayedComponents: .hourAndMinute)
                }

                Toggle("Akşam Yemeği", isOn: $dinnerReminder)
                if dinnerReminder {
                    DatePicker("Saat", selection: $dinnerTime, displayedComponents: .hourAndMinute)
                }
            }

            Section("Diğer") {
                Toggle("Su İçme Hatırlatması", isOn: $waterReminder)
            }
        }
        .scrollContentBackground(.hidden)
        .background(Color.ctBackground)
        .navigationTitle("Bildirimler")
        .onAppear { checkPermission() }
        .onChange(of: breakfastReminder) { _, _ in scheduleAll() }
        .onChange(of: lunchReminder) { _, _ in scheduleAll() }
        .onChange(of: dinnerReminder) { _, _ in scheduleAll() }
        .onChange(of: waterReminder) { _, _ in scheduleAll() }
        .onChange(of: breakfastTime) { _, _ in scheduleAll() }
        .onChange(of: lunchTime) { _, _ in scheduleAll() }
        .onChange(of: dinnerTime) { _, _ in scheduleAll() }
        .alert("Bildirim İzni", isPresented: $showPermissionAlert) {
            Button("Ayarlar") {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            }
            Button("İptal", role: .cancel) {}
        } message: {
            Text("Hatırlatıcılar için bildirim iznini Ayarlar'dan etkinleştirin.")
        }
    }

    private func checkPermission() {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            DispatchQueue.main.async {
                notificationsAuthorized = settings.authorizationStatus == .authorized
            }
        }
    }

    private func requestPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, _ in
            DispatchQueue.main.async {
                notificationsAuthorized = granted
                if !granted { showPermissionAlert = true }
                if granted { scheduleAll() }
            }
        }
    }

    private func scheduleAll() {
        let center = UNUserNotificationCenter.current()
        center.removeAllPendingNotificationRequests()

        if breakfastReminder {
            scheduleMealReminder(id: "breakfast", title: "Kahvaltı Zamanı", body: "Kahvaltını kaydetmeyi unutma!", time: breakfastTime)
        }
        if lunchReminder {
            scheduleMealReminder(id: "lunch", title: "Öğle Yemeği", body: "Öğle yemeğini kaydetmeyi unutma!", time: lunchTime)
        }
        if dinnerReminder {
            scheduleMealReminder(id: "dinner", title: "Akşam Yemeği", body: "Akşam yemeğini kaydetmeyi unutma!", time: dinnerTime)
        }
        if waterReminder {
            scheduleWaterReminders()
        }

        savePreferencesToBackend()
    }

    private func scheduleMealReminder(id: String, title: String, body: String, time: Date) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default

        let calendar = Calendar.current
        var dateComponents = DateComponents()
        dateComponents.hour = calendar.component(.hour, from: time)
        dateComponents.minute = calendar.component(.minute, from: time)

        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        let request = UNNotificationRequest(identifier: "meal_\(id)", content: content, trigger: trigger)

        UNUserNotificationCenter.current().add(request)
    }

    private func scheduleWaterReminders() {
        let content = UNMutableNotificationContent()
        content.title = "Su İç"
        content.body = "Bir bardak su içmeyi unutma!"
        content.sound = .default

        // Schedule every 60 min from 9:00 to 21:00
        for hour in stride(from: 9, through: 21, by: 1) {
            var dateComponents = DateComponents()
            dateComponents.hour = hour
            dateComponents.minute = 0

            let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
            let request = UNNotificationRequest(identifier: "water_\(hour)", content: content, trigger: trigger)

            UNUserNotificationCenter.current().add(request)
        }
    }

    private struct NotificationPrefs: Codable {
        let breakfastReminder: Bool
        let breakfastTime: String
        let lunchReminder: Bool
        let lunchTime: String
        let dinnerReminder: Bool
        let dinnerTime: String
        let waterReminder: Bool
    }

    private func savePreferencesToBackend() {
        let calendar = Calendar.current
        let prefs = NotificationPrefs(
            breakfastReminder: breakfastReminder,
            breakfastTime: String(format: "%02d:%02d", calendar.component(.hour, from: breakfastTime), calendar.component(.minute, from: breakfastTime)),
            lunchReminder: lunchReminder,
            lunchTime: String(format: "%02d:%02d", calendar.component(.hour, from: lunchTime), calendar.component(.minute, from: lunchTime)),
            dinnerReminder: dinnerReminder,
            dinnerTime: String(format: "%02d:%02d", calendar.component(.hour, from: dinnerTime), calendar.component(.minute, from: dinnerTime)),
            waterReminder: waterReminder
        )

        Task {
            do {
                struct Ack: Decodable {}
                let _: Ack = try await APIClient.shared.request(
                    endpoint: "/api/v1/notifications/preferences",
                    method: .PUT,
                    body: prefs
                )
            } catch {
                print("Bildirim tercihleri kaydedilemedi: \(error)")
            }
        }
    }

    private static func dateFrom(hour: Int, minute: Int) -> Date {
        var components = DateComponents()
        components.hour = hour
        components.minute = minute
        return Calendar.current.date(from: components) ?? Date()
    }
}

private func dateFrom(hour: Int, minute: Int) -> Date {
    var components = DateComponents()
    components.hour = hour
    components.minute = minute
    return Calendar.current.date(from: components) ?? Date()
}
