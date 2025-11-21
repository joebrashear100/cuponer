//
//  ChatManager.swift
//  Furg
//
//  Manages chat conversation with FURG personality
//

import Foundation

@MainActor
class ChatManager: ObservableObject {
    @Published var messages: [ChatMessage] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let apiClient = APIClient()

    func loadHistory() async {
        do {
            let response = try await apiClient.getChatHistory()

            messages = response.messages.map { msg in
                ChatMessage(
                    id: UUID().uuidString,
                    role: msg.role == "user" ? .user : .assistant,
                    content: msg.content,
                    timestamp: ISO8601DateFormatter().date(from: msg.timestamp) ?? Date()
                )
            }
        } catch {
            errorMessage = "Failed to load history: \(error.localizedDescription)"
        }
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
            let response = try await apiClient.sendChatMessage(text)

            let aiMessage = ChatMessage(
                id: UUID().uuidString,
                role: .assistant,
                content: response.message,
                timestamp: Date()
            )

            messages.append(aiMessage)
        } catch {
            errorMessage = "Failed to send message: \(error.localizedDescription)"

            // Add error message to chat
            let errorMsg = ChatMessage(
                id: UUID().uuidString,
                role: .assistant,
                content: "Whoa, my roasting circuits are overloaded. Try again in a sec.",
                timestamp: Date()
            )
            messages.append(errorMsg)
        }

        isLoading = false
    }

    func clearHistory() {
        messages.removeAll()
    }
}
