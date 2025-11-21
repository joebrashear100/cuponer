//
//  PlaidManager.swift
//  Furg
//
//  Manages Plaid bank connections
//  Note: Requires LinkKit framework from Plaid
//

import Foundation
// import LinkKit // Uncomment when LinkKit is added via SPM

@MainActor
class PlaidManager: ObservableObject {
    @Published var linkedBanks: [LinkedBank] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let apiClient = APIClient()

    struct LinkedBank: Identifiable {
        let id: String
        let name: String
        var lastSynced: Date
    }

    func presentPlaidLink() async {
        isLoading = true

        do {
            let response = try await apiClient.getPlaidLinkToken()
            let linkToken = response.linkToken

            // Note: Plaid LinkKit integration
            // Once LinkKit is added via Swift Package Manager:
            // 1. Import LinkKit
            // 2. Create LinkTokenConfiguration
            // 3. Present Handler
            // 4. Handle success callback with public token
            // 5. Exchange token via exchangePublicToken()

            print("Link token received: \(linkToken)")
            // For now, store link token for manual testing
            UserDefaults.standard.set(linkToken, forKey: "plaid_link_token")

            errorMessage = "Plaid Link ready. Add LinkKit framework to complete integration."

        } catch {
            errorMessage = "Failed to create link token: \(error.localizedDescription)"
        }

        isLoading = false
    }

    func exchangePublicToken(_ publicToken: String) async {
        isLoading = true

        do {
            let response = try await apiClient.exchangePlaidToken(publicToken)

            let bank = LinkedBank(
                id: response.itemId,
                name: response.institutionName,
                lastSynced: Date()
            )

            linkedBanks.append(bank)

            // Trigger initial sync
            await syncBanks()

        } catch {
            errorMessage = "Failed to exchange token: \(error.localizedDescription)"
        }

        isLoading = false
    }

    func syncBanks() async {
        isLoading = true

        do {
            try await apiClient.syncAllBanks()

            // Update last synced time for all banks
            linkedBanks = linkedBanks.map { bank in
                var updated = bank
                updated.lastSynced = Date()
                return updated
            }

        } catch {
            errorMessage = "Failed to sync banks: \(error.localizedDescription)"
        }

        isLoading = false
    }
}
