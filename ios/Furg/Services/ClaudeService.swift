//
//  ClaudeService.swift
//  Furg
//
//  Direct integration with Claude API for AI chat
//

import Foundation

// MARK: - Claude API Models

struct ClaudeMessage: Codable {
    let role: String
    let content: String
}

struct ClaudeRequest: Codable {
    let model: String
    let max_tokens: Int
    let system: String
    let messages: [ClaudeMessage]
}

struct ClaudeResponse: Codable {
    let id: String
    let type: String
    let role: String
    let content: [ClaudeContent]
    let model: String
    let stop_reason: String?
    let usage: ClaudeUsage
}

struct ClaudeContent: Codable {
    let type: String
    let text: String
}

struct ClaudeUsage: Codable {
    let input_tokens: Int
    let output_tokens: Int
}

struct ClaudeErrorResponse: Codable {
    let type: String
    let error: ClaudeError
}

struct ClaudeError: Codable {
    let type: String
    let message: String
}

// MARK: - Claude Service

@MainActor
class ClaudeService: ObservableObject {
    static let shared = ClaudeService()

    @Published var isLoading = false
    @Published var errorMessage: String?

    private var conversationHistory: [ClaudeMessage] = []

    // FURG's personality system prompt
    private let systemPrompt = """
    You are FURG, a brutally honest AI financial assistant with a sharp wit and no filter. Your personality:

    - You're like that friend who tells you the truth even when it hurts
    - You use humor to deliver tough financial advice
    - You're encouraging but also call out bad spending habits
    - You speak casually, like texting a friend (use contractions, casual language)
    - You keep responses concise - usually 2-3 sentences max
    - You celebrate wins genuinely but roast unnecessary spending
    - You use occasional emoji but don't overdo it 🔥

    Your role is to help users:
    - Track and understand their spending
    - Stay motivated on savings goals
    - Make smarter financial decisions
    - Feel accountable but not judged

    Example responses:
    - "Bro you spent $47 at Starbucks this week. That's someone's grocery budget. I'm not mad, just disappointed. 😤"
    - "Look at you! $500 saved this month. Keep this up and you'll hit your goal early. Actually proud rn."
    - "Can you afford $500? Technically yes. Should you? Let's look at your goals first..."

    Be helpful, be real, be FURG.
    """

    func sendMessage(_ userMessage: String) async throws -> String {
        isLoading = true
        errorMessage = nil

        defer { isLoading = false }

        // Add user message to history
        conversationHistory.append(ClaudeMessage(role: "user", content: userMessage))

        // Keep only last 20 messages for context
        if conversationHistory.count > 20 {
            conversationHistory = Array(conversationHistory.suffix(20))
        }

        let request = ClaudeRequest(
            model: Config.Claude.model,
            max_tokens: Config.Claude.maxTokens,
            system: systemPrompt,
            messages: conversationHistory
        )

        guard let url = URL(string: Config.Claude.baseURL) else {
            throw URLError(.badURL)
        }

        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.setValue(Config.Claude.apiKey, forHTTPHeaderField: "x-api-key")
        urlRequest.setValue("2023-06-01", forHTTPHeaderField: "anthropic-version")
        urlRequest.timeoutInterval = 60

        let encoder = JSONEncoder()
        urlRequest.httpBody = try encoder.encode(request)

        let (data, response) = try await URLSession.shared.data(for: urlRequest)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw URLError(.badServerResponse)
        }

        if httpResponse.statusCode != 200 {
            if let errorResponse = try? JSONDecoder().decode(ClaudeErrorResponse.self, from: data) {
                throw NSError(
                    domain: "ClaudeAPI",
                    code: httpResponse.statusCode,
                    userInfo: [NSLocalizedDescriptionKey: errorResponse.error.message]
                )
            }
            throw URLError(.badServerResponse)
        }

        let claudeResponse = try JSONDecoder().decode(ClaudeResponse.self, from: data)

        guard let textContent = claudeResponse.content.first(where: { $0.type == "text" }) else {
            throw NSError(domain: "ClaudeAPI", code: -1, userInfo: [NSLocalizedDescriptionKey: "No text response"])
        }

        // Add assistant response to history
        conversationHistory.append(ClaudeMessage(role: "assistant", content: textContent.text))

        return textContent.text
    }

    func clearHistory() {
        conversationHistory.removeAll()
    }
}
