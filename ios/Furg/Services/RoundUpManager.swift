//
//  RoundUpManager.swift
//  Furg
//
//  Manages round-up investing automation
//

import Foundation

@MainActor
class RoundUpManager: ObservableObject {
    @Published var config: RoundUpConfig = .default
    @Published var summary: RoundUpSummary?
    @Published var pendingRoundUps: [RoundUpTransaction] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let apiClient = APIClient()

    // MARK: - Demo Data

    var demoSummary: RoundUpSummary {
        RoundUpSummary(
            totalRoundedUp: 234.56,
            totalTransferred: 200.00,
            pendingAmount: 34.56,
            transactionCount: 87,
            lastTransferDate: Calendar.current.date(byAdding: .day, value: -3, to: Date())
        )
    }

    var demoPendingRoundUps: [RoundUpTransaction] {
        [
            RoundUpTransaction(
                id: "1",
                sourceTransactionId: "txn1",
                originalAmount: 4.73,
                roundedAmount: 5.00,
                roundUpAmount: 0.27,
                multipliedAmount: 0.27,
                status: .pending,
                transferId: nil,
                createdAt: Date()
            ),
            RoundUpTransaction(
                id: "2",
                sourceTransactionId: "txn2",
                originalAmount: 12.45,
                roundedAmount: 13.00,
                roundUpAmount: 0.55,
                multipliedAmount: 0.55,
                status: .pending,
                transferId: nil,
                createdAt: Calendar.current.date(byAdding: .hour, value: -2, to: Date()) ?? Date()
            ),
            RoundUpTransaction(
                id: "3",
                sourceTransactionId: "txn3",
                originalAmount: 7.89,
                roundedAmount: 8.00,
                roundUpAmount: 0.11,
                multipliedAmount: 0.11,
                status: .pending,
                transferId: nil,
                createdAt: Calendar.current.date(byAdding: .hour, value: -5, to: Date()) ?? Date()
            )
        ]
    }

    // MARK: - Load Data

    func loadConfig() async {
        isLoading = true
        defer { isLoading = false }

        do {
            config = try await apiClient.getRoundUpConfig()
        } catch {
            // Use default config if API fails
            config = .default
        }
    }

    func loadSummary() async {
        do {
            summary = try await apiClient.getRoundUpSummary()
        } catch {
            summary = demoSummary
        }
    }

    func loadPendingRoundUps() async {
        do {
            pendingRoundUps = try await apiClient.getPendingRoundUps()
        } catch {
            pendingRoundUps = demoPendingRoundUps
        }
    }

    // MARK: - Configuration

    func updateConfig(_ newConfig: RoundUpConfig) async -> Bool {
        isLoading = true
        defer { isLoading = false }

        do {
            try await apiClient.updateRoundUpConfig(newConfig)
            config = newConfig
            return true
        } catch {
            errorMessage = "Failed to update round-up settings"
            return false
        }
    }

    func enableRoundUps(goalId: String? = nil) async -> Bool {
        var newConfig = config
        newConfig.enabled = true
        newConfig.goalId = goalId
        return await updateConfig(newConfig)
    }

    func disableRoundUps() async -> Bool {
        var newConfig = config
        newConfig.enabled = false
        return await updateConfig(newConfig)
    }

    func setMultiplier(_ multiplier: Int) async -> Bool {
        var newConfig = config
        newConfig.multiplier = max(1, min(10, multiplier))
        return await updateConfig(newConfig)
    }

    func setRoundUpAmount(_ amount: RoundUpAmount) async -> Bool {
        var newConfig = config
        newConfig.roundUpTo = amount
        return await updateConfig(newConfig)
    }

    func setDailyCap(_ cap: Decimal?) async -> Bool {
        var newConfig = config
        newConfig.dailyCap = cap
        return await updateConfig(newConfig)
    }

    func setWeeklyCap(_ cap: Decimal?) async -> Bool {
        var newConfig = config
        newConfig.weeklyCap = cap
        return await updateConfig(newConfig)
    }

    func linkGoal(_ goalId: String) async -> Bool {
        var newConfig = config
        newConfig.goalId = goalId
        return await updateConfig(newConfig)
    }

    // MARK: - Transfer

    func transferPendingRoundUps() async -> Bool {
        isLoading = true
        defer { isLoading = false }

        do {
            try await apiClient.transferRoundUps()
            await loadSummary()
            await loadPendingRoundUps()
            return true
        } catch {
            errorMessage = "Failed to transfer round-ups"
            return false
        }
    }

    // MARK: - Calculations

    func calculateRoundUp(for amount: Decimal) -> Decimal {
        let baseRoundUp = config.roundUpTo.calculate(from: amount)
        return baseRoundUp * Decimal(config.multiplier)
    }

    func estimateMonthlyRoundUp(averageTransactionsPerDay: Int = 5) -> Decimal {
        // Assume average round-up is about $0.50 per transaction
        let avgRoundUp: Decimal = 0.50
        let dailyRoundUp = avgRoundUp * Decimal(averageTransactionsPerDay) * Decimal(config.multiplier)
        return dailyRoundUp * 30
    }
}

// MARK: - API Client Extensions

extension APIClient {
    func getRoundUpConfig() async throws -> RoundUpConfig {
        return try await get("/roundups/config")
    }

    func updateRoundUpConfig(_ config: RoundUpConfig) async throws {
        let _: EmptyResponse = try await post("/roundups/config", body: config)
    }

    func getRoundUpSummary() async throws -> RoundUpSummary {
        return try await get("/roundups/summary")
    }

    func getPendingRoundUps() async throws -> [RoundUpTransaction] {
        let response: RoundUpsResponse = try await get("/roundups/pending")
        return response.roundUps
    }

    func transferRoundUps() async throws {
        let _: EmptyResponse = try await post("/roundups/transfer", body: EmptyBody())
    }
}

struct RoundUpsResponse: Codable {
    let roundUps: [RoundUpTransaction]

    enum CodingKeys: String, CodingKey {
        case roundUps = "round_ups"
    }
}

struct EmptyBody: Codable {}
struct EmptyResponse: Codable {}
