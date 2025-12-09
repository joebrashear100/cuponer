//
//  WelcomeView.swift
//  Furg
//
//  Ultra-minimal welcome screen for debugging touch issues
//

import SwiftUI
import AuthenticationServices

struct WelcomeView: View {
    @EnvironmentObject var authManager: AuthManager

    var body: some View {
        VStack(spacing: 30) {
            Spacer()

            // Logo
            Image(systemName: "flame.fill")
                .font(.system(size: 80))
                .foregroundColor(.green)

            Text("FURG")
                .font(.system(size: 48, weight: .black))
                .foregroundColor(.white)

            Text("Your brutally honest money app")
                .font(.system(size: 16))
                .foregroundColor(.gray)

            Spacer()

            // Buttons section
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
                .cornerRadius(12)

                #if DEBUG
                // Debug: Skip to Onboarding
                Button(action: {
                    authManager.debugBypassLogin(skipOnboarding: false)
                }) {
                    Text("DEBUG: Skip to Onboarding")
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(Color.blue)
                        .cornerRadius(12)
                }
                .buttonStyle(PlainButtonStyle())

                // Debug: Skip to Main App
                Button(action: {
                    authManager.debugBypassLogin(skipOnboarding: true)
                }) {
                    Text("DEBUG: Skip to Main App")
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(Color.green)
                        .cornerRadius(12)
                }
                .buttonStyle(PlainButtonStyle())
                #endif

                // Show loading state
                if authManager.isLoading {
                    ProgressView()
                        .tint(.white)
                }

                // Show error if any
                if let error = authManager.errorMessage {
                    Text(error)
                        .font(.caption)
                        .foregroundColor(.red)
                        .multilineTextAlignment(.center)
                }
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 50)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(red: 0.05, green: 0.05, blue: 0.08))
        .ignoresSafeArea()
    }
}

#Preview {
    WelcomeView()
        .environmentObject(AuthManager())
}
