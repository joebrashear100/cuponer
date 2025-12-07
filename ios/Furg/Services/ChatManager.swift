//
//  ChatManager.swift
//  Furg
//
//  Manages chat conversation with FURG personality using Claude AI
//

import Foundation

@MainActor
class ChatManager: ObservableObject {
    @Published var messages: [ChatMessage] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let claudeService = ClaudeService.shared

    func loadHistory() async {
        // For now, we keep history in memory via ClaudeService
        // Messages persist during app session
        errorMessage = nil
    }

    func sendMessage(_ text: String) async {
        let userMessage = ChatMessage(
            id: UUID().uuidString,
            role: .user,
            content: text,
            timestamp: Date()
        )

        messages.append(userMessage)
        isLoading = true
        errorMessage = nil

        do {
            let response = try await claudeService.sendMessage(text)

            let aiMessage = ChatMessage(
                id: UUID().uuidString,
                role: .assistant,
                content: response,
                timestamp: Date()
            )

            messages.append(aiMessage)
        } catch {
            // Check if it's an API key issue
            if error.localizedDescription.contains("invalid") || error.localizedDescription.contains("key") {
                errorMessage = "API key not configured. Add your Claude API key in Config.swift"
            } else {
                errorMessage = nil // Don't show error banner, just show in chat
            }

            // Add friendly error message to chat
            let errorMsg = ChatMessage(
                id: UUID().uuidString,
                role: .assistant,
                content: "My brain's having a moment. 🧠 Check your API key in Config.swift or try again!",
                timestamp: Date()
            )
            messages.append(errorMsg)
        }

        isLoading = false
    }

    func clearHistory() {
        messages.removeAll()
        claudeService.clearHistory()
    }
}
