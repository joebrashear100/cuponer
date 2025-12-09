//
//  AuthManager.swift
//  Furg
//
//  Handles Sign in with Apple and JWT token management
//  SECURITY: Tokens stored in Keychain, not UserDefaults
//

import SwiftUI
import AuthenticationServices
import os.log

private let logger = Logger(subsystem: "com.furg.app", category: "AuthManager")

@MainActor
class AuthManager: NSObject, ObservableObject {
    @Published var isAuthenticated = false
    @Published var hasCompletedOnboarding = false
    @Published var userID: String?
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let onboardingKey = "hasCompletedOnboarding"
    private let keychain = KeychainService.shared

    /// JWT token stored securely in Keychain
    private var token: String? {
        get {
            keychain.getStringOptional(for: .jwtToken)
        }
        set {
            if let newValue = newValue {
                do {
                    try keychain.save(newValue, for: .jwtToken)
                } catch {
                    logger.error("Failed to save JWT token to Keychain: \(error.localizedDescription)")
                }
            } else {
                try? keychain.delete(.jwtToken)
            }
        }
    }

    /// User ID stored securely in Keychain
    private var storedUserId: String? {
        get {
            keychain.getStringOptional(for: .userId)
        }
        set {
            if let newValue = newValue {
                try? keychain.save(newValue, for: .userId)
            } else {
                try? keychain.delete(.userId)
            }
        }
    }

    override init() {
        super.init()
        migrateFromUserDefaults()
        checkAuthenticationStatus()
    }

    /// Migrate credentials from UserDefaults to Keychain (one-time migration)
    private func migrateFromUserDefaults() {
        // Migrate JWT token if exists in UserDefaults
        if let oldToken = UserDefaults.standard.string(forKey: Config.Keys.jwtToken) {
            token = oldToken
            UserDefaults.standard.removeObject(forKey: Config.Keys.jwtToken)
            logger.info("Migrated JWT token from UserDefaults to Keychain")
        }

        // Migrate user ID if exists in UserDefaults
        if let oldUserId = UserDefaults.standard.string(forKey: Config.Keys.userId) {
            storedUserId = oldUserId
            UserDefaults.standard.removeObject(forKey: Config.Keys.userId)
            logger.info("Migrated user ID from UserDefaults to Keychain")
        }
    }

    func checkAuthenticationStatus() {
        if token != nil, let userId = storedUserId {
            self.isAuthenticated = true
            self.userID = userId
            self.hasCompletedOnboarding = UserDefaults.standard.bool(forKey: onboardingKey)
            logger.debug("User authenticated: \(userId.prefix(8))...")
        }
    }

    func completeOnboarding() {
        UserDefaults.standard.set(true, forKey: onboardingKey)
        hasCompletedOnboarding = true
    }

    func resetOnboarding() {
        UserDefaults.standard.set(false, forKey: onboardingKey)
        hasCompletedOnboarding = false
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
        storedUserId = nil
        isAuthenticated = false
        userID = nil
        logger.info("User signed out")
    }

    #if DEBUG
    /// Debug login for testing - requires DEBUG_USER_ID and DEBUG_JWT_TOKEN environment variables
    /// Set these in your Xcode scheme to enable debug login
    /// SECURITY: Never commit actual tokens to source code
    func debugBypassLogin(skipOnboarding: Bool = true) {
        guard let debugUserId = ProcessInfo.processInfo.environment["DEBUG_USER_ID"],
              let debugToken = ProcessInfo.processInfo.environment["DEBUG_JWT_TOKEN"] else {
            logger.warning("Debug login requires DEBUG_USER_ID and DEBUG_JWT_TOKEN environment variables")
            errorMessage = "Debug login not configured. Set environment variables in Xcode scheme."
            return
        }

        token = debugToken
        storedUserId = debugUserId

        self.userID = debugUserId
        self.isAuthenticated = true
        self.errorMessage = nil

        // Skip onboarding for debug users by default
        if skipOnboarding {
            UserDefaults.standard.set(true, forKey: onboardingKey)
            self.hasCompletedOnboarding = true
        }

        logger.info("Debug login successful for user: \(debugUserId.prefix(8))...")
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
                self.storedUserId = response.userId
                self.isAuthenticated = true
                self.isLoading = false
                self.errorMessage = nil
                logger.info("Apple Sign In successful for user: \(response.userId.prefix(8))...")
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
            // Try to get window from connected scenes
            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
               let window = windowScene.windows.first {
                return window
            }

            // Fallback: create a temporary window if none exists
            logger.warning("No window available for presentation anchor, creating fallback")
            let fallbackWindow = UIWindow(frame: UIScreen.main.bounds)
            fallbackWindow.makeKeyAndVisible()
            return fallbackWindow
        }
    }
}
