//
//  WelcomeView.swift
//  Furg
//
//  Modern glassmorphism welcome screen
//

import SwiftUI
import AuthenticationServices

struct WelcomeView: View {
    @EnvironmentObject var authManager: AuthManager
    @State private var animate = false

    var body: some View {
        ZStack {
            // Animated background
            AnimatedMeshBackground()

            // Content
            VStack(spacing: 0) {
                Spacer()

                // Logo and branding
                VStack(spacing: 24) {
                    // Glowing logo
                    ZStack {
                        // Glow effect
                        Circle()
                            .fill(Color.furgMint.opacity(0.3))
                            .frame(width: 140, height: 140)
                            .blur(radius: 30)

                        // Glass circle
                        Circle()
                            .fill(Color.white.opacity(0.1))
                            .frame(width: 120, height: 120)
                            .overlay(
                                Circle()
                                    .stroke(
                                        LinearGradient(
                                            colors: [Color.furgMint.opacity(0.6), Color.furgMint.opacity(0.1)],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        ),
                                        lineWidth: 2
                                    )
                            )

                        Image(systemName: "flame.fill")
                            .font(.system(size: 50))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [Color.furgMint, Color.furgSeafoam],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                    }
                    .scaleEffect(animate ? 1.0 : 0.9)
                    .animation(.easeOut(duration: 0.8), value: animate)

                    VStack(spacing: 12) {
                        Text("FURG")
                            .font(.system(size: 52, weight: .black, design: .rounded))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [.white, .white.opacity(0.8)],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )

                        Text(Config.tagline)
                            .font(.furgBody)
                            .foregroundColor(.white.opacity(0.6))
                    }
                }
                .padding(.bottom, 50)

                Spacer()

                // Features card
                FloatingCard(padding: 24) {
                    VStack(spacing: 20) {
                        FeatureRow(icon: "message.fill", title: "Chat-First", subtitle: "Control everything through conversation")
                        FeatureRow(icon: "shield.lefthalf.filled", title: "Bill Shield", subtitle: "Never miss a payment again")
                        FeatureRow(icon: "eye.slash.fill", title: "Shadow Banking", subtitle: "Hide money from yourself")
                        FeatureRow(icon: "sparkles", title: "AI Insights", subtitle: "Smart spending analysis")
                    }
                }
                .padding(.horizontal, 24)
                .offset(y: animate ? 0 : 30)
                .opacity(animate ? 1 : 0)
                .animation(.easeOut(duration: 0.6).delay(0.3), value: animate)

                Spacer()

                // Sign in section
                VStack(spacing: 16) {
                    // Apple Sign In
                    SignInWithAppleButton(.signIn) { request in
                        request.requestedScopes = [.fullName, .email]
                    } onCompletion: { result in
                        switch result {
                        case .success(let authorization):
                            if let credential = authorization.credential as? ASAuthorizationAppleIDCredential {
                                Task {
                                    await authManager.handleAppleSignIn(credential: credential)
                                }
                            }
                        case .failure(let error):
                            authManager.errorMessage = error.localizedDescription
                        }
                    }
                    .signInWithAppleButtonStyle(.white)
                    .frame(height: 54)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color.white.opacity(0.2), lineWidth: 1)
                    )

                    #if DEBUG
                    Button {
                        authManager.debugBypassLogin()
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "arrow.right.circle.fill")
                            Text("Skip Sign In")
                        }
                        .font(.furgHeadline)
                        .foregroundColor(.white.opacity(0.7))
                    }
                    .glassButton()
                    #endif

                    if authManager.isLoading {
                        ProgressView()
                            .tint(.furgMint)
                            .scaleEffect(1.2)
                    }

                    if let error = authManager.errorMessage {
                        Text(error)
                            .font(.furgCaption)
                            .foregroundColor(.furgDanger)
                            .multilineTextAlignment(.center)
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 40)
                .offset(y: animate ? 0 : 40)
                .opacity(animate ? 1 : 0)
                .animation(.easeOut(duration: 0.6).delay(0.5), value: animate)
            }
        }
        .onAppear {
            animate = true
        }
    }
}

struct FeatureRow: View {
    let icon: String
    let title: String
    let subtitle: String

    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(Color.furgMint.opacity(0.15))
                    .frame(width: 44, height: 44)

                Image(systemName: icon)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.furgMint)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.furgHeadline)
                    .foregroundColor(.white)

                Text(subtitle)
                    .font(.furgCaption)
                    .foregroundColor(.white.opacity(0.5))
            }

            Spacer()
        }
    }
}

#Preview {
    WelcomeView()
        .environmentObject(AuthManager())
}
