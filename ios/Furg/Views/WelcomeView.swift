//
//  WelcomeView.swift
//  Furg
//
//  Welcome screen with Sign in with Apple
//

import SwiftUI
import AuthenticationServices

struct WelcomeView: View {
    @EnvironmentObject var authManager: AuthManager

    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                colors: [Color.orange, Color.red],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 40) {
                Spacer()

                // App icon and title
                VStack(spacing: 20) {
                    Image(systemName: "flame.fill")
                        .resizable()
                        .frame(width: 100, height: 100)
                        .foregroundColor(.white)

                    Text("FURG")
                        .font(.system(size: 60, weight: .black))
                        .foregroundColor(.white)

                    Text(Config.tagline)
                        .font(.title3)
                        .foregroundColor(.white.opacity(0.9))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }

                Spacer()

                // Features
                VStack(alignment: .leading, spacing: 20) {
                    FeatureRow(icon: "message.fill", text: "Chat-first control")
                    FeatureRow(icon: "shield.fill", text: "Bill protection")
                    FeatureRow(icon: "eye.slash.fill", text: "Hide money from yourself")
                    FeatureRow(icon: "flame.fill", text: "Roasting personality")
                }
                .padding(.horizontal, 40)

                Spacer()

                // Sign in button
                VStack(spacing: 20) {
                    SignInWithAppleButton(.signIn) { request in
                        request.requestedScopes = [.fullName, .email]
                    } onCompletion: { _ in
                        // Handled by AuthManager
                    }
                    .signInWithAppleButtonStyle(.white)
                    .frame(height: 50)
                    .padding(.horizontal, 40)

                    if authManager.isLoading {
                        ProgressView()
                            .tint(.white)
                    }

                    if let error = authManager.errorMessage {
                        Text(error)
                            .font(.caption)
                            .foregroundColor(.white)
                            .padding(.horizontal)
                    }
                }
                .padding(.bottom, 40)
            }
        }
        .onAppear {
            authManager.signInWithApple()
        }
    }
}

struct FeatureRow: View {
    let icon: String
    let text: String

    var body: some View {
        HStack(spacing: 15) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.white)
                .frame(width: 30)

            Text(text)
                .font(.body)
                .foregroundColor(.white)
        }
    }
}

#Preview {
    WelcomeView()
        .environmentObject(AuthManager())
}
