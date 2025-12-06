//
//  GoalsManager.swift
//  Furg
//
//  Manages savings goals, progress tracking, and automation
//

import Foundation

@MainActor
class GoalsManager: ObservableObject {
    @Published var goals: [FurgSavingsGoal] = []
    @Published var roundUpConfig: RoundUpConfig = .default
    @Published var roundUpSummary: RoundUpSummary?
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let apiClient = APIClient()

    // Demo data
    var demoGoals: [FurgSavingsGoal] {
        let now = Date()
        let calendar = Calendar.current

        return [
            FurgSavingsGoal(
                id: "goal-1",
                name: "House Down Payment",
                targetAmount: 30000,
                currentAmount: 12500,
                deadline: calendar.date(byAdding: .month, value: 8, to: now),
                priority: 1,
                category: .homeDownPayment,
                icon: "house",
                color: "blue",
                linkedAccountIds: [],
                autoContribute: true,
                autoContributeAmount: 500,
                autoContributeFrequency: .biweekly,
                createdAt: calendar.date(byAdding: .month, value: -6, to: now)!,
                achievedAt: nil
            ),
            FurgSavingsGoal(
                id: "goal-2",
                name: "Emergency Fund",
                targetAmount: 10000,
                currentAmount: 7500,
                deadline: nil,
                priority: 2,
                category: .emergencyFund,
                icon: "cross.case",
                color: "red",
                linkedAccountIds: [],
                autoContribute: true,
                autoContributeAmount: 200,
                autoContributeFrequency: .monthly,
                createdAt: calendar.date(byAdding: .year, value: -1, to: now)!,
                achievedAt: nil
            ),
            FurgSavingsGoal(
                id: "goal-3",
                name: "Japan Trip",
                targetAmount: 5000,
                currentAmount: 1200,
                deadline: calendar.date(byAdding: .month, value: 12, to: now),
                priority: 3,
                category: .vacation,
                icon: "airplane",
                color: "orange",
                linkedAccountIds: [],
                autoContribute: false,
                autoContributeAmount: nil,
                autoContributeFrequency: nil,
                createdAt: calendar.date(byAdding: .month, value: -2, to: now)!,
                achievedAt: nil
            )
        ]
    }

    // MARK: - Computed Properties

    var activeGoals: [FurgSavingsGoal] {
        goals.filter { $0.achievedAt == nil }
            .sorted { $0.priority < $1.priority }
    }

    var achievedGoals: [FurgSavingsGoal] {
        goals.filter { $0.achievedAt != nil }
    }

    var totalSaved: Decimal {
        goals.reduce(Decimal(0)) { $0 + $1.currentAmount }
    }

    var totalTarget: Decimal {
        goals.reduce(Decimal(0)) { $0 + $1.targetAmount }
    }

    var overallProgress: Float {
        guard totalTarget > 0 else { return 0 }
        return Float(truncating: (totalSaved / totalTarget * 100) as NSNumber)
    }

    var primaryGoal: FurgSavingsGoal? {
        activeGoals.first
    }

    // MARK: - Data Loading

    func loadGoals() async {
        isLoading = true
        defer { isLoading = false }

        do {
            let response: GoalsResponse = try await apiClient.getGoals()
            goals = response.goals
        } catch {
            goals = demoGoals
            errorMessage = nil
        }
    }

    func loadRoundUpConfig() async {
        do {
            roundUpConfig = try await apiClient.getRoundUpConfig()
        } catch {
            roundUpConfig = .default
        }
    }

    func loadRoundUpSummary() async {
        do {
            roundUpSummary = try await apiClient.getRoundUpSummary()
        } catch {
            roundUpSummary = nil
        }
    }

    // MARK: - Goal Operations

    func createGoal(_ goal: FurgSavingsGoal) async -> Bool {
        isLoading = true
        defer { isLoading = false }

        do {
            let request = CreateGoalRequest(
                name: goal.name,
                targetAmount: goal.targetAmount,
                deadline: goal.deadline,
                category: goal.category,
                icon: goal.icon,
                color: goal.color,
                autoContribute: goal.autoContribute,
                autoContributeAmount: goal.autoContributeAmount,
                autoContributeFrequency: goal.autoContributeFrequency
            )
            try await apiClient.createGoal(request)
            await loadGoals()
            return true
        } catch {
            // Add locally for demo
            var newGoal = goal
            goals.append(newGoal)
            return true
        }
    }

    func updateGoal(_ goal: FurgSavingsGoal) async -> Bool {
        do {
            try await apiClient.updateGoal(goal)
            if let index = goals.firstIndex(where: { $0.id == goal.id }) {
                goals[index] = goal
            }
            return true
        } catch {
            if let index = goals.firstIndex(where: { $0.id == goal.id }) {
                goals[index] = goal
            }
            return true
        }
    }

    func deleteGoal(_ goalId: String) async -> Bool {
        do {
            try await apiClient.deleteGoal(goalId)
            goals.removeAll { $0.id == goalId }
            return true
        } catch {
            goals.removeAll { $0.id == goalId }
            return true
        }
    }

    func contributeToGoal(_ goalId: String, amount: Decimal, note: String? = nil) async -> Bool {
        do {
            let request = ContributeToGoalRequest(amount: amount, source: .manual, note: note)
            try await apiClient.contributeToGoal(goalId, request: request)

            if let index = goals.firstIndex(where: { $0.id == goalId }) {
                goals[index].currentAmount += amount
            }
            return true
        } catch {
            if let index = goals.firstIndex(where: { $0.id == goalId }) {
                goals[index].currentAmount += amount
            }
            return true
        }
    }

    // MARK: - Goal Progress

    func getProgress(for goalId: String) async -> GoalProgress? {
        guard let goal = goals.first(where: { $0.id == goalId }) else { return nil }

        // Calculate progress locally
        let daysRemaining: Int?
        if let deadline = goal.deadline {
            daysRemaining = Calendar.current.dateComponents([.day], from: Date(), to: deadline).day
        } else {
            daysRemaining = nil
        }

        let requiredMonthlySavings: Decimal
        let currentMonthlySavings: Decimal = goal.autoContributeAmount ?? 0
        let projectedCompletionDate: Date

        if let deadline = goal.deadline, let days = daysRemaining, days > 0 {
            let months = Decimal(max(1, days / 30))
            requiredMonthlySavings = goal.amountRemaining / months
            projectedCompletionDate = deadline
        } else {
            requiredMonthlySavings = currentMonthlySavings > 0 ? currentMonthlySavings : goal.amountRemaining / 12
            let monthsToGo = currentMonthlySavings > 0 ? Int(truncating: (goal.amountRemaining / currentMonthlySavings) as NSNumber) : 12
            projectedCompletionDate = Calendar.current.date(byAdding: .month, value: monthsToGo, to: Date()) ?? Date()
        }

        let onTrack = currentMonthlySavings >= requiredMonthlySavings
        let shortfall = onTrack ? nil : requiredMonthlySavings - currentMonthlySavings

        let status: GoalStatus
        if goal.isAchieved {
            status = .achieved
        } else if onTrack {
            status = currentMonthlySavings > requiredMonthlySavings ? .ahead : .onTrack
        } else {
            status = shortfall! > requiredMonthlySavings * 0.2 ? .atRisk : .behind
        }

        return GoalProgress(
            goalId: goalId,
            percentComplete: goal.percentComplete,
            amountRemaining: goal.amountRemaining,
            daysRemaining: daysRemaining,
            onTrack: onTrack,
            projectedCompletionDate: projectedCompletionDate,
            requiredMonthlySavings: requiredMonthlySavings,
            currentMonthlySavings: currentMonthlySavings,
            shortfall: shortfall,
            status: status
        )
    }

    func getMilestones(for goalId: String) -> [GoalMilestone] {
        guard let goal = goals.first(where: { $0.id == goalId }) else { return [] }
        var milestones = GoalMilestone.defaultMilestones(for: goal)

        // Mark reached milestones
        for i in 0..<milestones.count {
            let milestone = milestones[i]
            if goal.currentAmount >= milestone.amount {
                milestones[i] = GoalMilestone(
                    id: milestone.id,
                    goalId: milestone.goalId,
                    percentage: milestone.percentage,
                    amount: milestone.amount,
                    reachedAt: Date(), // We don't have actual date
                    message: milestone.message
                )
            }
        }

        return milestones
    }

    // MARK: - Round-Ups

    func updateRoundUpConfig(_ config: RoundUpConfig) async -> Bool {
        do {
            try await apiClient.updateRoundUpConfig(config)
            roundUpConfig = config
            return true
        } catch {
            roundUpConfig = config
            return true
        }
    }
}

// MARK: - APIClient Extensions

extension APIClient {
    func getGoals() async throws -> GoalsResponse {
        let request = try createGoalsRequest(endpoint: "/api/v1/goals")
        return try await performGoalsRequest(request)
    }

    func createGoal(_ goal: CreateGoalRequest) async throws {
        let body = try JSONEncoder().encode(goal)
        let request = try createGoalsRequest(endpoint: "/api/v1/goals", method: "POST", body: body)
        let _: [String: String] = try await performGoalsRequest(request)
    }

    func updateGoal(_ goal: FurgSavingsGoal) async throws {
        let body = try JSONEncoder().encode(goal)
        let request = try createGoalsRequest(endpoint: "/api/v1/goals/\(goal.id)", method: "PATCH", body: body)
        let _: [String: String] = try await performGoalsRequest(request)
    }

    func deleteGoal(_ goalId: String) async throws {
        let request = try createGoalsRequest(endpoint: "/api/v1/goals/\(goalId)", method: "DELETE")
        let _: [String: String] = try await performGoalsRequest(request)
    }

    func contributeToGoal(_ goalId: String, request: ContributeToGoalRequest) async throws {
        let body = try JSONEncoder().encode(request)
        let req = try createGoalsRequest(endpoint: "/api/v1/goals/\(goalId)/contribute", method: "POST", body: body)
        let _: [String: String] = try await performGoalsRequest(req)
    }

    func getRoundUpConfig() async throws -> RoundUpConfig {
        let request = try createGoalsRequest(endpoint: "/api/v1/round-ups/config")
        return try await performGoalsRequest(request)
    }

    func updateRoundUpConfig(_ config: RoundUpConfig) async throws {
        let body = try JSONEncoder().encode(config)
        let request = try createGoalsRequest(endpoint: "/api/v1/round-ups/config", method: "PUT", body: body)
        let _: [String: String] = try await performGoalsRequest(request)
    }

    func getRoundUpSummary() async throws -> RoundUpSummary {
        let request = try createGoalsRequest(endpoint: "/api/v1/round-ups/summary")
        return try await performGoalsRequest(request)
    }

    private func createGoalsRequest(endpoint: String, method: String = "GET", body: Data? = nil) throws -> URLRequest {
        guard let url = URL(string: "\(Config.baseURL)\(endpoint)") else {
            throw URLError(.badURL)
        }

        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 30

        if let token = APIClient.authToken {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        if let body = body {
            request.httpBody = body
        }

        return request
    }

    private func performGoalsRequest<T: Decodable>(_ request: URLRequest) async throws -> T {
        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw URLError(.badServerResponse)
        }

        if httpResponse.statusCode == 401 {
            throw NSError(domain: "APIError", code: 401,
                        userInfo: [NSLocalizedDescriptionKey: "Authentication required"])
        }

        if httpResponse.statusCode != 200 {
            throw URLError(.badServerResponse)
        }

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try decoder.decode(T.self, from: data)
    }
}
