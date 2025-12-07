//
//  PlaidManager.swift
//  Furg
//
//  Manages Plaid bank connections
//  Note: Add LinkKit via SPM: https://github.com/plaid/plaid-link-ios
//

import Foundation
import SwiftUI
import os.log

// Uncomment when LinkKit is added via SPM
// import LinkKit

private let logger = Logger(subsystem: "com.furg.app", category: "PlaidManager")

@MainActor
class PlaidManager: ObservableObject {
    @Published var linkedBanks: [LinkedBank] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var showLinkFlow = false
    @Published var linkToken: String?

    private let apiClient = APIClient()
    private let keychain = KeychainService.shared

    // MARK: - Models

    struct LinkedBank: Identifiable, Codable {
        let id: String
        let name: String
        let institutionId: String?
        var lastSynced: Date
        var accounts: [LinkedAccount]

        struct LinkedAccount: Identifiable, Codable {
            let id: String
            let name: String
            let mask: String?
            let type: String
            let subtype: String?
            var currentBalance: Double?
            var availableBalance: Double?
        }
    }

    // MARK: - Initialization

    init() {
        loadLinkedBanks()
    }

    // MARK: - Link Flow

    func presentPlaidLink() async {
        isLoading = true
        errorMessage = nil

        do {
            // Get link token from backend
            let response = try await apiClient.getPlaidLinkToken()
            self.linkToken = response.linkToken
            self.showLinkFlow = true
            self.isLoading = false

            // With LinkKit installed, you would:
            // createLinkHandler(with: response.linkToken)

        } catch {
            errorMessage = "Failed to initialize bank connection: \(error.localizedDescription)"
            isLoading = false
        }
    }

    // MARK: - Token Exchange (called after Plaid Link success)

    func exchangePublicToken(_ publicToken: String, institutionName: String, institutionId: String, accountIds: [String]) async {
        isLoading = true

        do {
            let response = try await apiClient.exchangePlaidToken(publicToken)

            // Create linked bank record
            let linkedAccounts = accountIds.map { accountId in
                LinkedBank.LinkedAccount(
                    id: accountId,
                    name: "Account",
                    mask: nil,
                    type: "depository",
                    subtype: nil,
                    currentBalance: nil,
                    availableBalance: nil
                )
            }

            let bank = LinkedBank(
                id: response.itemId,
                name: institutionName,
                institutionId: institutionId,
                lastSynced: Date(),
                accounts: linkedAccounts
            )

            linkedBanks.append(bank)
            saveLinkedBanks()

            // Store item ID securely
            try? keychain.save(response.itemId, for: .plaidItemId)

            // Trigger initial sync
            await syncBanks()

            showLinkFlow = false

        } catch {
            errorMessage = "Failed to connect bank: \(error.localizedDescription)"
        }

        isLoading = false
    }

    // MARK: - Bank Sync

    func syncBanks() async {
        guard !linkedBanks.isEmpty else { return }

        isLoading = true

        do {
            try await apiClient.syncAllBanks()

            // Update last synced time
            linkedBanks = linkedBanks.map { bank in
                var updated = bank
                updated.lastSynced = Date()
                return updated
            }

            saveLinkedBanks()

            // Refresh account balances
            await refreshAccountBalances()

        } catch {
            errorMessage = "Failed to sync: \(error.localizedDescription)"
        }

        isLoading = false
    }

    private func refreshAccountBalances() async {
        do {
            let accounts: PlaidAccountsResponse = try await apiClient.get("/plaid/accounts")

            // Update linked banks with fresh balance data
            for i in 0..<linkedBanks.count {
                for j in 0..<linkedBanks[i].accounts.count {
                    if let accountData = accounts.accounts.first(where: { $0.accountId == linkedBanks[i].accounts[j].id }) {
                        linkedBanks[i].accounts[j].currentBalance = accountData.balances.current
                        linkedBanks[i].accounts[j].availableBalance = accountData.balances.available
                    }
                }
            }

            saveLinkedBanks()
        } catch {
            logger.error("Failed to refresh balances: \(error.localizedDescription)")
        }
    }

    // MARK: - Remove Bank

    func removeBank(_ bank: LinkedBank) async {
        isLoading = true

        do {
            try await apiClient.postVoid("/plaid/remove", body: ["item_id": bank.id])

            linkedBanks.removeAll { $0.id == bank.id }
            saveLinkedBanks()

        } catch {
            errorMessage = "Failed to remove bank: \(error.localizedDescription)"
        }

        isLoading = false
    }

    // MARK: - Persistence

    private func saveLinkedBanks() {
        if let data = try? JSONEncoder().encode(linkedBanks) {
            UserDefaults.standard.set(data, forKey: "linked_banks")
        }
    }

    private func loadLinkedBanks() {
        if let data = UserDefaults.standard.data(forKey: "linked_banks"),
           let banks = try? JSONDecoder().decode([LinkedBank].self, from: data) {
            linkedBanks = banks
        }
    }

    // MARK: - Computed Properties

    var hasLinkedBanks: Bool {
        !linkedBanks.isEmpty
    }

    var totalAccounts: Int {
        linkedBanks.reduce(0) { $0 + $1.accounts.count }
    }

    var lastSyncDate: Date? {
        linkedBanks.map(\.lastSynced).max()
    }
}

// MARK: - Additional Response Models

struct PlaidAccountsResponse: Codable {
    let accounts: [PlaidAccount]

    struct PlaidAccount: Codable {
        let accountId: String
        let name: String
        let mask: String?
        let type: String
        let subtype: String?
        let balances: Balances

        enum CodingKeys: String, CodingKey {
            case accountId = "account_id"
            case name, mask, type, subtype, balances
        }

        struct Balances: Codable {
            let available: Double?
            let current: Double?
            let limit: Double?
        }
    }
}
