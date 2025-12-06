//
//  APIClient.swift
//  Furg
//
//  Central API client for all backend communication
//

import Foundation

// Empty response for void POST calls
struct EmptyAPIResponse: Decodable {}

@MainActor
class APIClient: ObservableObject {
    @Published var isLoading = false
    @Published var errorMessage: String?

    // Shared token storage - set by AuthManager
    static var authToken: String? {
        get { UserDefaults.standard.string(forKey: Config.Keys.jwtToken) }
    }

    // MARK: - Helper Methods

    private func createRequest(endpoint: String, method: String = "GET", body: Data? = nil) throws -> URLRequest {
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

    private func performRequest<T: Decodable>(_ request: URLRequest) async throws -> T {
        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw URLError(.badServerResponse)
        }

        if httpResponse.statusCode == 401 {
            throw NSError(domain: "APIError", code: 401,
                        userInfo: [NSLocalizedDescriptionKey: "Authentication required. Please sign in again."])
        }

        if httpResponse.statusCode != 200 {
            if let apiError = try? JSONDecoder().decode(APIError.self, from: data) {
                throw NSError(domain: "APIError", code: httpResponse.statusCode,
                            userInfo: [NSLocalizedDescriptionKey: apiError.detail])
            }
            throw URLError(.badServerResponse)
        }

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try decoder.decode(T.self, from: data)
    }

    // MARK: - Generic Request Methods

    func get<T: Decodable>(_ endpoint: String) async throws -> T {
        let fullEndpoint = endpoint.hasPrefix("/api") ? endpoint : "/api/v1\(endpoint)"
        let request = try createRequest(endpoint: fullEndpoint)
        return try await performRequest(request)
    }

    func post<T: Decodable, B: Encodable>(_ endpoint: String, body: B) async throws -> T {
        let fullEndpoint = endpoint.hasPrefix("/api") ? endpoint : "/api/v1\(endpoint)"
        let bodyData = try JSONEncoder().encode(body)
        let request = try createRequest(endpoint: fullEndpoint, method: "POST", body: bodyData)
        return try await performRequest(request)
    }

    func postVoid<B: Encodable>(_ endpoint: String, body: B) async throws {
        let fullEndpoint = endpoint.hasPrefix("/api") ? endpoint : "/api/v1\(endpoint)"
        let bodyData = try JSONEncoder().encode(body)
        let request = try createRequest(endpoint: fullEndpoint, method: "POST", body: bodyData)
        let _: EmptyAPIResponse = try await performRequest(request)
    }

    // MARK: - Chat API

    func sendChatMessage(_ message: String) async throws -> ChatResponse {
        let requestBody = ChatRequest(message: message, includeContext: true)
        let body = try JSONEncoder().encode(requestBody)
        let request = try createRequest(endpoint: Config.API.chat, method: "POST", body: body)
        return try await performRequest(request)
    }

    func getChatHistory(limit: Int = 50) async throws -> ChatHistoryResponse {
        let request = try createRequest(endpoint: "\(Config.API.chatHistory)?limit=\(limit)")
        return try await performRequest(request)
    }

    // MARK: - Balance API

    func getBalance() async throws -> BalanceSummary {
        let request = try createRequest(endpoint: Config.API.balance)
        return try await performRequest(request)
    }

    func hideMoney(amount: Double, purpose: String = "forced_savings") async throws -> HideMoneyResponse {
        let requestBody = HideMoneyRequest(amount: amount, purpose: purpose)
        let body = try JSONEncoder().encode(requestBody)
        let request = try createRequest(endpoint: Config.API.hideMoney, method: "POST", body: body)
        return try await performRequest(request)
    }

    func revealMoney(amount: Double? = nil) async throws -> HideMoneyResponse {
        var requestBody: [String: Any] = [:]
        if let amount = amount {
            requestBody["amount"] = amount
        }
        let body = try JSONSerialization.data(withJSONObject: requestBody)
        let request = try createRequest(endpoint: Config.API.revealMoney, method: "POST", body: body)
        return try await performRequest(request)
    }

    // MARK: - Transaction API

    func getTransactions(days: Int = 30) async throws -> TransactionsResponse {
        let request = try createRequest(endpoint: "\(Config.API.transactions)?days=\(days)")
        return try await performRequest(request)
    }

    func getSpendingSummary(days: Int = 30) async throws -> SpendingSummaryResponse {
        let request = try createRequest(endpoint: "\(Config.API.transactions)/spending?days=\(days)")
        return try await performRequest(request)
    }

    // MARK: - Bills API

    func getBills() async throws -> BillsResponse {
        let request = try createRequest(endpoint: Config.API.bills)
        return try await performRequest(request)
    }

    func detectBills() async throws -> BillsResponse {
        let request = try createRequest(endpoint: Config.API.billsDetect, method: "POST")
        return try await performRequest(request)
    }

    func getUpcomingBills(days: Int = 30) async throws -> UpcomingBillsResponse {
        let request = try createRequest(endpoint: "\(Config.API.bills)/upcoming?days=\(days)")
        return try await performRequest(request)
    }

    // MARK: - Plaid API

    func getPlaidLinkToken() async throws -> PlaidLinkTokenResponse {
        let request = try createRequest(endpoint: Config.API.plaidLinkToken, method: "POST")
        return try await performRequest(request)
    }

    func exchangePlaidToken(_ publicToken: String) async throws -> PlaidExchangeResponse {
        let requestBody = PlaidExchangeRequest(publicToken: publicToken)
        let body = try JSONEncoder().encode(requestBody)
        let request = try createRequest(endpoint: Config.API.plaidExchange, method: "POST", body: body)
        return try await performRequest(request)
    }

    func syncAllBanks() async throws {
        let request = try createRequest(endpoint: Config.API.plaidSync, method: "POST")
        let _: [String: String] = try await performRequest(request)
    }

    // MARK: - Profile API

    func getProfile() async throws -> UserProfile {
        let request = try createRequest(endpoint: Config.API.profile)
        return try await performRequest(request)
    }

    func updateProfile(_ updates: [String: Any]) async throws {
        let body = try JSONSerialization.data(withJSONObject: updates)
        let request = try createRequest(endpoint: Config.API.profile, method: "PATCH", body: body)
        let _: [String: String] = try await performRequest(request)
    }

    func setSavingsGoal(amount: Double, deadline: String, purpose: String, frequency: String = "weekly") async throws {
        let requestBody = SavingsGoalRequest(goalAmount: amount, deadline: deadline, purpose: purpose, frequency: frequency)
        let body = try JSONEncoder().encode(requestBody)
        let request = try createRequest(endpoint: Config.API.savingsGoal, method: "POST", body: body)
        let _: [String: String] = try await performRequest(request)
    }
}
