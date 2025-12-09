//
//  ChatManager.swift
//  Furg
//
//  Manages chat conversation with FURG personality using Claude AI
//

import Foundation
import os.log

private let logger = Logger(subsystem: "com.furg.app", category: "ChatManager")

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
            logger.debug("Received AI response for message")
        } catch {
            logger.error("Chat error: \(error.localizedDescription)")

            // Determine error type and provide appropriate feedback
            let chatErrorMessage: String
            let nsError = error as NSError

            if nsError.domain == "ClaudeAPI" {
                switch nsError.code {
                case 401:
                    errorMessage = "API key is invalid or missing. Configure it in settings."
                    chatErrorMessage = "Looks like my API key isn't working. Check your settings! 🔑"
                case 429:
                    errorMessage = nil
                    chatErrorMessage = "Whoa, too many requests! Give me a sec to catch my breath. 😮‍💨"
                case 500...599:
                    errorMessage = nil
                    chatErrorMessage = "Claude's servers are having a moment. Try again in a bit! 🔧"
                default:
                    errorMessage = nil
                    chatErrorMessage = "Something went wrong on my end. Mind trying again? 🤔"
                }
            } else if nsError.domain == NSURLErrorDomain {
                errorMessage = nil
                chatErrorMessage = "Can't reach the servers. Check your internet connection! 📶"
            } else {
                errorMessage = nil
                chatErrorMessage = "My brain's having a moment. 🧠 Try again!"
            }

            let errorMsg = ChatMessage(
                id: UUID().uuidString,
                role: .assistant,
                content: chatErrorMessage,
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
