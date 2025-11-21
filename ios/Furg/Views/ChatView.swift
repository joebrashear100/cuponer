//
//  ChatView.swift
//  Furg
//
//  Main chat interface with FURG
//

import SwiftUI

struct ChatView: View {
    @EnvironmentObject var chatManager: ChatManager
    @State private var messageText = ""
    @State private var scrollProxy: ScrollViewProxy?

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Messages
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(spacing: 16) {
                            ForEach(chatManager.messages) { message in
                                MessageBubble(message: message)
                                    .id(message.id)
                            }

                            if chatManager.isLoading {
                                HStack {
                                    ProgressView()
                                        .padding()
                                    Text("FURG is thinking...")
                                        .foregroundColor(.gray)
                                }
                            }
                        }
                        .padding()
                    }
                    .onAppear {
                        scrollProxy = proxy
                        Task {
                            await chatManager.loadHistory()
                            scrollToBottom()
                        }
                    }
                    .onChange(of: chatManager.messages.count) { _ in
                        scrollToBottom()
                    }
                }

                // Input bar
                HStack(spacing: 12) {
                    TextField("Message FURG...", text: $messageText, axis: .vertical)
                        .textFieldStyle(.roundedBorder)
                        .lineLimit(1...5)

                    Button(action: sendMessage) {
                        Image(systemName: "arrow.up.circle.fill")
                            .font(.title2)
                            .foregroundColor(messageText.isEmpty ? .gray : .orange)
                    }
                    .disabled(messageText.isEmpty || chatManager.isLoading)
                }
                .padding()
                .background(Color(uiColor: .systemBackground))
            }
            .navigationTitle("FURG")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button(action: { Task { await chatManager.loadHistory() } }) {
                            Label("Refresh", systemImage: "arrow.clockwise")
                        }
                        Button(role: .destructive, action: { chatManager.clearHistory() }) {
                            Label("Clear Chat", systemImage: "trash")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
            }
        }
    }

    private func sendMessage() {
        let text = messageText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }

        messageText = ""

        Task {
            await chatManager.sendMessage(text)
        }
    }

    private func scrollToBottom() {
        guard let lastMessage = chatManager.messages.last else { return }
        withAnimation {
            scrollProxy?.scrollTo(lastMessage.id, anchor: .bottom)
        }
    }
}

struct MessageBubble: View {
    let message: ChatMessage

    var body: some View {
        HStack {
            if message.role == .user {
                Spacer()
            }

            VStack(alignment: message.role == .user ? .trailing : .leading, spacing: 4) {
                Text(message.content)
                    .padding(12)
                    .background(message.role == .user ? Color.orange : Color(uiColor: .secondarySystemBackground))
                    .foregroundColor(message.role == .user ? .white : .primary)
                    .cornerRadius(16)

                Text(message.timestamp, style: .time)
                    .font(.caption2)
                    .foregroundColor(.gray)
            }

            if message.role == .assistant {
                Spacer()
            }
        }
    }
}

#Preview {
    ChatView()
        .environmentObject(ChatManager())
}
