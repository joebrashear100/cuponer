//
//  AuthManager.swift
//  Furg
//
//  Handles Sign in with Apple and JWT token management
//

import SwiftUI
import AuthenticationServices

@MainActor
class AuthManager: NSObject, ObservableObject {
    @Published var isAuthenticated = false
    @Published var userID: String?
    @Published var isLoading = false
    @Published var errorMessage: String?

    private var token: String? {
        get { UserDefaults.standard.string(forKey: Config.Keys.jwtToken) }
        set {
            if let newValue = newValue {
                UserDefaults.standard.set(newValue, forKey: Config.Keys.jwtToken)
            } else {
                UserDefaults.standard.removeObject(forKey: Config.Keys.jwtToken)
            }
        }
    }

    override init() {
        super.init()
        checkAuthenticationStatus()
    }

    func checkAuthenticationStatus() {
        if token != nil, let userId = UserDefaults.standard.string(forKey: Config.Keys.userId) {
            self.isAuthenticated = true
            self.userID = userId
        }
    }

    func signInWithApple() {
        let provider = ASAuthorizationAppleIDProvider()
        let request = provider.createRequest()
        request.requestedScopes = [.fullName, .email]

        let controller = ASAuthorizationController(authorizationRequests: [request])
        controller.delegate = self
        controller.presentationContextProvider = self
        controller.performRequests()
    }

    func signOut() {
        token = nil
        UserDefaults.standard.removeObject(forKey: Config.Keys.userId)
        isAuthenticated = false
        userID = nil
    }

    #if DEBUG
    func debugBypassLogin() {
        // Debug-only function to bypass authentication for testing
        let debugUserId = "debug-user-\(UUID().uuidString.prefix(8))"
        let debugToken = "debug-token-\(UUID().uuidString)"

        UserDefaults.standard.set(debugToken, forKey: Config.Keys.jwtToken)
        UserDefaults.standard.set(debugUserId, forKey: Config.Keys.userId)

        self.userID = debugUserId
        self.isAuthenticated = true
        self.errorMessage = nil
    }
    #endif

    func handleAppleSignIn(credential: ASAuthorizationAppleIDCredential) async {
        await MainActor.run { isLoading = true }
        await handleAppleIDCredential(credential)
    }

    private func handleAppleIDCredential(_ credential: ASAuthorizationAppleIDCredential) async {
        guard let identityToken = credential.identityToken,
              let tokenString = String(data: identityToken, encoding: .utf8) else {
            await MainActor.run {
                self.errorMessage = "Failed to get Apple ID token"
                self.isLoading = false
            }
            return
        }

        // Exchange with backend
        do {
            let response = try await authenticateWithBackend(appleToken: tokenString, userIdentifier: credential.user)

            await MainActor.run {
                self.token = response.jwt
                self.userID = response.userId
                UserDefaults.standard.set(response.userId, forKey: Config.Keys.userId)
                self.isAuthenticated = true
                self.isLoading = false
                self.errorMessage = nil
            }
        } catch {
            await MainActor.run {
                self.errorMessage = "Authentication failed: \(error.localizedDescription)"
                self.isLoading = false
            }
        }
    }

    private func authenticateWithBackend(appleToken: String, userIdentifier: String) async throws -> AuthResponse {
        let url = URL(string: "\(Config.baseURL)\(Config.API.auth)")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let requestBody = AppleAuthRequest(appleToken: appleToken, userIdentifier: userIdentifier)
        request.httpBody = try JSONEncoder().encode(requestBody)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw URLError(.badServerResponse)
        }

        if httpResponse.statusCode != 200 {
            if let apiError = try? JSONDecoder().decode(APIError.self, from: data) {
                throw NSError(domain: "AuthError", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: apiError.detail])
            }
            throw URLError(.badServerResponse)
        }

        let authResponse = try JSONDecoder().decode(AuthResponse.self, from: data)
        return authResponse
    }

    func getToken() -> String? {
        return token
    }
}

// MARK: - ASAuthorizationControllerDelegate

extension AuthManager: ASAuthorizationControllerDelegate {
    nonisolated func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
        Task { @MainActor in
            isLoading = true

            if let credential = authorization.credential as? ASAuthorizationAppleIDCredential {
                await handleAppleIDCredential(credential)
            }
        }
    }

    nonisolated func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
        Task { @MainActor in
            errorMessage = "Sign in failed: \(error.localizedDescription)"
            isLoading = false
        }
    }
}

// MARK: - ASAuthorizationControllerPresentationContextProviding

extension AuthManager: ASAuthorizationControllerPresentationContextProviding {
    nonisolated func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        return MainActor.assumeIsolated {
            guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                  let window = windowScene.windows.first else {
                fatalError("No window available")
            }
            return window
        }
    }
}
