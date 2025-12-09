//
//  SubscriptionManager.swift
//  Furg
//
//  Manages subscription detection, tracking, and cancellation
//

import Foundation
import os.log

private let logger = Logger(subsystem: "com.furg.app", category: "SubscriptionManager")

@MainActor
class SubscriptionManager: ObservableObject {
    @Published var subscriptions: [Subscription] = []
    @Published var summary: SubscriptionSummary?
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let apiClient = APIClient()

    // Demo data when no bank is connected
    var demoSubscriptions: [Subscription] {
        [
            Subscription(
                id: "demo-1",
                merchantName: "Netflix",
                merchantLogo: nil,
                category: .streaming,
                amount: 15.99,
                frequency: .monthly,
                nextBillingDate: Calendar.current.date(byAdding: .day, value: 5, to: Date())!,
                startDate: Calendar.current.date(byAdding: .month, value: -18, to: Date()),
                freeTrialEnds: nil,
                status: .active,
                cancellationUrl: "https://netflix.com/cancelplan",
                cancellationDifficulty: .easy,
                usageMetrics: SubscriptionUsage(lastUsedDate: Calendar.current.date(byAdding: .day, value: -2, to: Date()), usageFrequency: "12 times/month", valueScore: 0.8),
                lastUsedDate: Calendar.current.date(byAdding: .day, value: -2, to: Date())
            ),
            Subscription(
                id: "demo-2",
                merchantName: "Spotify",
                merchantLogo: nil,
                category: .music,
                amount: 10.99,
                frequency: .monthly,
                nextBillingDate: Calendar.current.date(byAdding: .day, value: 12, to: Date())!,
                startDate: Calendar.current.date(byAdding: .year, value: -2, to: Date()),
                freeTrialEnds: nil,
                status: .active,
                cancellationUrl: "https://spotify.com/account",
                cancellationDifficulty: .easy,
                usageMetrics: SubscriptionUsage(lastUsedDate: Date(), usageFrequency: "Daily", valueScore: 0.95),
                lastUsedDate: Date()
            ),
            Subscription(
                id: "demo-3",
                merchantName: "Adobe Creative Cloud",
                merchantLogo: nil,
                category: .software,
                amount: 54.99,
                frequency: .monthly,
                nextBillingDate: Calendar.current.date(byAdding: .day, value: 8, to: Date())!,
                startDate: Calendar.current.date(byAdding: .month, value: -6, to: Date()),
                freeTrialEnds: nil,
                status: .active,
                cancellationUrl: nil,
                cancellationDifficulty: .hard,
                usageMetrics: SubscriptionUsage(lastUsedDate: Calendar.current.date(byAdding: .month, value: -2, to: Date()), usageFrequency: "2 times/month", valueScore: 0.15),
                lastUsedDate: Calendar.current.date(byAdding: .month, value: -2, to: Date())
            ),
            Subscription(
                id: "demo-4",
                merchantName: "Planet Fitness",
                merchantLogo: nil,
                category: .fitness,
                amount: 24.99,
                frequency: .monthly,
                nextBillingDate: Calendar.current.date(byAdding: .day, value: 1, to: Date())!,
                startDate: Calendar.current.date(byAdding: .month, value: -8, to: Date()),
                freeTrialEnds: nil,
                status: .active,
                cancellationUrl: nil,
                cancellationDifficulty: .veryHard,
                usageMetrics: SubscriptionUsage(lastUsedDate: Calendar.current.date(byAdding: .month, value: -3, to: Date()), usageFrequency: "0 times/month", valueScore: 0.0),
                lastUsedDate: Calendar.current.date(byAdding: .month, value: -3, to: Date())
            ),
            Subscription(
                id: "demo-5",
                merchantName: "iCloud+",
                merchantLogo: nil,
                category: .storage,
                amount: 2.99,
                frequency: .monthly,
                nextBillingDate: Calendar.current.date(byAdding: .day, value: 15, to: Date())!,
                startDate: Calendar.current.date(byAdding: .year, value: -3, to: Date()),
                freeTrialEnds: nil,
                status: .active,
                cancellationUrl: nil,
                cancellationDifficulty: .easy,
                usageMetrics: SubscriptionUsage(lastUsedDate: Date(), usageFrequency: "Always on", valueScore: 0.9),
                lastUsedDate: Date()
            ),
            Subscription(
                id: "demo-6",
                merchantName: "HBO Max",
                merchantLogo: nil,
                category: .streaming,
                amount: 15.99,
                frequency: .monthly,
                nextBillingDate: Calendar.current.date(byAdding: .day, value: 20, to: Date())!,
                startDate: Calendar.current.date(byAdding: .month, value: -4, to: Date()),
                freeTrialEnds: nil,
                status: .active,
                cancellationUrl: "https://max.com/account",
                cancellationDifficulty: .moderate,
                usageMetrics: SubscriptionUsage(lastUsedDate: Calendar.current.date(byAdding: .day, value: -45, to: Date()), usageFrequency: "1 time last month", valueScore: 0.1),
                lastUsedDate: Calendar.current.date(byAdding: .day, value: -45, to: Date())
            )
        ]
    }

    var demoSummary: SubscriptionSummary {
        let subs = demoSubscriptions
        let totalMonthly = subs.reduce(Decimal(0)) { $0 + $1.monthlyEquivalent }
        let unusedCount = subs.filter { $0.isUnused }.count
        let potentialSavings = subs.filter { $0.isUnused }.reduce(Decimal(0)) { $0 + $1.monthlyEquivalent }

        var byCategory: [String: Decimal] = [:]
        for sub in subs {
            byCategory[sub.category.label, default: 0] += sub.monthlyEquivalent
        }

        return SubscriptionSummary(
            totalMonthly: totalMonthly,
            totalAnnual: totalMonthly * 12,
            subscriptionCount: subs.count,
            unusedCount: unusedCount,
            potentialSavings: potentialSavings,
            byCategory: byCategory
        )
    }

    // MARK: - Computed Properties

    var activeSubscriptions: [Subscription] {
        subscriptions.filter { $0.status == .active || $0.status == .trialEnding }
    }

    var unusedSubscriptions: [Subscription] {
        subscriptions.filter { $0.isUnused }
    }

    var totalMonthly: Decimal {
        activeSubscriptions.reduce(Decimal(0)) { $0 + $1.monthlyEquivalent }
    }

    var totalAnnual: Decimal {
        totalMonthly * 12
    }

    var potentialSavings: Decimal {
        unusedSubscriptions.reduce(Decimal(0)) { $0 + $1.monthlyEquivalent }
    }

    // MARK: - Data Loading

    func loadSubscriptions() async {
        isLoading = true
        defer { isLoading = false }

        do {
            let response: SubscriptionsResponse = try await apiClient.getSubscriptions()
            subscriptions = response.subscriptions
            summary = response.summary
            logger.debug("Loaded \(response.subscriptions.count) subscriptions from API")
        } catch {
            logger.warning("Failed to load subscriptions, using demo data: \(error.localizedDescription)")
            subscriptions = demoSubscriptions
            summary = demoSummary
            errorMessage = nil
        }
    }

    func detectSubscriptions() async {
        isLoading = true
        defer { isLoading = false }

        do {
            let response: SubscriptionsResponse = try await apiClient.detectSubscriptions()
            subscriptions = response.subscriptions
            summary = response.summary
            logger.info("Detected \(response.subscriptions.count) subscriptions")
        } catch {
            logger.warning("Failed to detect subscriptions: \(error.localizedDescription)")
            errorMessage = "Connect a bank to detect subscriptions automatically"
        }
    }

    // MARK: - Cancellation

    func getCancellationGuide(for subscriptionId: String) async -> CancellationGuide? {
        do {
            let response: CancellationGuideResponse = try await apiClient.getCancellationGuide(subscriptionId: subscriptionId)
            logger.debug("Loaded cancellation guide for subscription '\(subscriptionId)'")
            return response.guide
        } catch {
            logger.warning("Failed to get cancellation guide, using demo: \(error.localizedDescription)")
            if let sub = subscriptions.first(where: { $0.id == subscriptionId }) {
                return demoCancellationGuide(for: sub)
            }
            return nil
        }
    }

    func markAsCancelled(subscriptionId: String) async -> Bool {
        do {
            try await apiClient.cancelSubscription(subscriptionId: subscriptionId)
            if let index = subscriptions.firstIndex(where: { $0.id == subscriptionId }) {
                subscriptions.remove(at: index)
            }
            await loadSubscriptions()
            logger.info("Marked subscription '\(subscriptionId)' as cancelled")
            return true
        } catch {
            logger.error("Failed to cancel subscription: \(error.localizedDescription)")
            errorMessage = "Failed to mark subscription as cancelled"
            return false
        }
    }

    // MARK: - Negotiation

    func getNegotiationScript(for billId: String) async -> NegotiationScript? {
        do {
            let response: NegotiationScriptResponse = try await apiClient.getNegotiationScript(billId: billId)
            logger.debug("Loaded negotiation script for bill '\(billId)'")
            return response.script
        } catch {
            logger.warning("Failed to get negotiation script: \(error.localizedDescription)")
            return nil
        }
    }

    func getNegotiationPotential(for billId: String) async -> NegotiationPotential? {
        do {
            let response: NegotiationScriptResponse = try await apiClient.getNegotiationScript(billId: billId)
            logger.debug("Loaded negotiation potential for bill '\(billId)'")
            return response.potential
        } catch {
            logger.warning("Failed to get negotiation potential: \(error.localizedDescription)")
            return nil
        }
    }

    // MARK: - Demo Helpers

    private func demoCancellationGuide(for subscription: Subscription) -> CancellationGuide {
        let steps: [String]
        let script: String?
        let method: CancellationMethod

        switch subscription.cancellationDifficulty {
        case .easy:
            method = .onlineOneClick
            steps = [
                "Log into your \(subscription.merchantName) account",
                "Go to Settings > Account",
                "Click 'Cancel Subscription'",
                "Confirm cancellation"
            ]
            script = nil

        case .moderate:
            method = .onlineMultiStep
            steps = [
                "Log into your \(subscription.merchantName) account",
                "Navigate to Account Settings",
                "Look for 'Manage Subscription' or 'Billing'",
                "Find the cancel option (often buried)",
                "Complete the cancellation survey",
                "Confirm via email"
            ]
            script = nil

        case .hard:
            method = .phoneCancellation
            steps = [
                "Call customer service",
                "Navigate through phone menu to 'Cancel subscription'",
                "Speak with retention specialist",
                "Decline any offers to stay",
                "Request confirmation email"
            ]
            script = """
            "Hi, I'd like to cancel my \(subscription.merchantName) subscription effective immediately."

            If they ask why: "I'm consolidating my expenses and no longer need this service."

            If they offer a discount: "I appreciate the offer, but I've made my decision. Please proceed with the cancellation."

            At the end: "Can you please send me a confirmation email that the subscription has been cancelled?"
            """

        case .veryHard:
            method = .inPersonRequired
            steps = [
                "Some gyms require in-person cancellation",
                "Bring a valid ID",
                "Ask for the membership manager",
                "Request written confirmation of cancellation",
                "Keep all documentation"
            ]
            script = """
            "I need to cancel my membership effective today."

            If they mention a contract: "I understand there may be fees, but I'd like to proceed with cancellation."

            If they offer to freeze: "No thank you, I want to cancel completely."

            Important: Get everything in writing before you leave.
            """
        }

        return CancellationGuide(
            id: "guide-\(subscription.id)",
            merchantName: subscription.merchantName,
            method: method,
            url: subscription.cancellationUrl,
            phoneNumber: nil,
            steps: steps,
            script: script,
            averageTimeMinutes: subscription.cancellationDifficulty == .easy ? 2 : 15,
            successRate: 0.95,
            tips: [
                "Take screenshots of your cancellation confirmation",
                "Check your next billing date - you have until then to cancel",
                "Monitor your bank statement to ensure no further charges"
            ],
            warnings: subscription.cancellationDifficulty == .hard || subscription.cancellationDifficulty == .veryHard
                ? ["Retention specialists may offer discounts - stay firm if you want to cancel", "Some companies charge early termination fees"]
                : []
        )
    }
}

// MARK: - APIClient Extensions for Subscriptions

extension APIClient {
    func getSubscriptions() async throws -> SubscriptionsResponse {
        return try await get("/subscriptions")
    }

    func detectSubscriptions() async throws -> SubscriptionsResponse {
        return try await post("/subscriptions/detect", body: EmptyBody())
    }

    func getCancellationGuide(subscriptionId: String) async throws -> CancellationGuideResponse {
        return try await get("/subscriptions/\(subscriptionId)/cancellation-guide")
    }

    func cancelSubscription(subscriptionId: String) async throws {
        try await postVoid("/subscriptions/\(subscriptionId)/mark-cancelled", body: EmptyBody())
    }

    func getNegotiationScript(billId: String) async throws -> NegotiationScriptResponse {
        return try await get("/subscriptions/\(billId)/negotiation-script")
    }
}
