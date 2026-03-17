import SwiftUI
import AuthenticationServices

struct WelcomeView: View {
    @EnvironmentObject var appState: AppState
    @State private var showEmailLogin = false

    var body: some View {
        ZStack {
            // Floating food particles background
            FloatingFoodParticlesView()

            VStack(spacing: 32) {
                Spacer()

                // Animated Logo & Title
                VStack(spacing: 16) {
                    AppLogoView(size: 120)

                    Text("Forkcast")
                        .font(.ctLargeTitle)

                    Text("Smart Meal Tracking, Powered by AI")
                        .font(.ctBody)
                        .foregroundStyle(.ctTextSecondary)
                }

                Spacer()

                // Animated Features
                VStack(alignment: .leading, spacing: 16) {
                    AnimatedFeatureRow(icon: "camera.fill", title: "Fotoğraf ile Tarama",
                              description: "Yemeğini çek, AI anında kaloriyi hesaplasın", index: 0)
                    AnimatedFeatureRow(icon: "chart.bar.fill", title: "Detaylı Takip",
                              description: "Kalori, makro ve mikro besin takibi", index: 1)
                    AnimatedFeatureRow(icon: "heart.fill", title: "Apple Health",
                              description: "Sağlık verilerinle otomatik senkronize", index: 2)
                    AnimatedFeatureRow(icon: "book.fill", title: "Akıllı Tarifler",
                              description: "Hedefine uygun AI destekli yemek tarifleri", index: 3)
                }
                .padding(.horizontal)

                Spacer()

                // Sign In Buttons
                VStack(spacing: 12) {
                SignInWithAppleButton(.signIn) { request in
                    request.requestedScopes = [.fullName, .email]
                } onCompletion: { result in
                    handleAppleSignIn(result)
                }
                .signInWithAppleButtonStyle(.black)
                .frame(height: 52)
                .cornerRadius(14)

                Button(action: { showEmailLogin = true }) {
                    HStack {
                        Image(systemName: "envelope.fill")
                        Text("Email ile Devam Et")
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(Color.ctAccent)
                    .foregroundStyle(.black)
                    .cornerRadius(14)
                    .fontWeight(.semibold)
                }

                Button("Hesabım var, Giriş Yap") {
                    showEmailLogin = true
                }
                .font(.ctSubheadline)
                .foregroundStyle(.ctAccent)
                .padding(.top, 4)
            }
                .padding(.horizontal)
                .padding(.bottom, 32)
            } // end VStack(spacing: 32)
        } // end ZStack
        .background(AnimatedGradientBackground())
        .background(Color.ctBackground)
        .sheet(isPresented: $showEmailLogin) {
            EmailLoginView()
        }
    }

    private func handleAppleSignIn(_ result: Result<ASAuthorization, Error>) {
        switch result {
        case .success(let auth):
            if let credential = auth.credential as? ASAuthorizationAppleIDCredential {
                // TODO: Send credential to backend
                let _ = credential.identityToken
                appState.signIn()
            }
        case .failure(let error):
            print("Apple Sign-In failed: \(error)")
        }
    }
}

struct FeatureRow: View {
    let icon: String
    let title: String
    let description: String

    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(.ctAccent)
                .frame(width: 44, height: 44)
                .background(Color.ctAccent.opacity(0.1))
                .cornerRadius(12)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.ctHeadline)
                Text(description)
                    .font(.ctFootnote)
                    .foregroundStyle(.ctTextSecondary)
            }
        }
    }
}

struct EmailLoginView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var appState: AppState
    @State private var email = ""
    @State private var password = ""
    @State private var isRegistering = false
    @State private var name = ""
    @State private var isLoading = false
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    Text(isRegistering ? "Hesap Oluştur" : "Giriş Yap")
                        .font(.ctTitle)
                        .padding(.top, 20)

                    if isRegistering {
                        TextField("Ad Soyad", text: $name)
                            .textFieldStyle(.roundedBorder)
                            .textContentType(.name)
                    }

                    TextField("Email", text: $email)
                        .textFieldStyle(.roundedBorder)
                        .textContentType(.emailAddress)
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)

                    SecureField("Şifre", text: $password)
                        .textFieldStyle(.roundedBorder)
                        .textContentType(isRegistering ? .newPassword : .password)

                    if let error = errorMessage {
                        Text(error)
                            .font(.ctFootnote)
                            .foregroundStyle(.ctError)
                    }

                    Button(action: handleAuth) {
                        if isLoading {
                            ProgressView()
                                .tint(.white)
                        } else {
                            Text(isRegistering ? "Kayıt Ol" : "Giriş Yap")
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(Color.ctAccent)
                    .foregroundStyle(.black)
                    .cornerRadius(14)
                    .fontWeight(.semibold)
                    .disabled(isLoading)

                    Button(isRegistering ? "Zaten hesabım var" : "Hesap oluştur") {
                        withAnimation { isRegistering.toggle() }
                    }
                    .font(.ctSubheadline)
                    .foregroundStyle(.ctAccent)
                }
                .padding()
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("İptal") { dismiss() }
                }
            }
        }
    }

    private func handleAuth() {
        isLoading = true
        errorMessage = nil

        // TODO: Implement actual API call
        Task {
            try? await Task.sleep(nanoseconds: 1_000_000_000)
            isLoading = false
            appState.signIn()
            dismiss()
        }
    }
}
