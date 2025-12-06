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
    @State private var animate = false

    var body: some View {
        ZStack {
            AnimatedMeshBackground()

            VStack(spacing: 0) {
                // Header
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("FURG")
                            .font(.furgLargeTitle)
                            .foregroundColor(.furgMint)

                        Text("Your financial assistant")
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.6))
                    }

                    Spacer()

                    Menu {
                        Button(action: { Task { await chatManager.loadHistory() } }) {
                            Label("Refresh", systemImage: "arrow.clockwise")
                        }
                        Button(role: .destructive, action: { chatManager.clearHistory() }) {
                            Label("Clear Chat", systemImage: "trash")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle.fill")
                            .font(.title2)
                            .foregroundColor(.furgMint)
                            .padding(8)
                            .background(Circle().fill(Color.white.opacity(0.1)))
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top)
                .offset(y: animate ? 0 : -20)
                .opacity(animate ? 1 : 0)
                .animation(.easeOut(duration: 0.5), value: animate)

            // Messages
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(spacing: 16) {
                        if chatManager.messages.isEmpty {
                            GlassEmptyChatView(onSuggestionTap: { suggestion in
                                messageText = suggestion
                                sendMessage()
                            })
                                .padding(.top, 60)
                                .offset(y: animate ? 0 : 20)
                                .opacity(animate ? 1 : 0)
                                .animation(.easeOut(duration: 0.5).delay(0.2), value: animate)
                        } else {
                            ForEach(Array(chatManager.messages.enumerated()), id: \.element.id) { index, message in
                                GlassMessageBubble(message: message)
                                    .id(message.id)
                                    .offset(y: animate ? 0 : 20)
                                    .opacity(animate ? 1 : 0)
                                    .animation(.easeOut(duration: 0.4).delay(0.1 + Double(index) * 0.05), value: animate)
                            }
                        }

                        if chatManager.isLoading {
                            GlassTypingIndicator()
                        }

                        // Error message
                        if let error = chatManager.errorMessage {
                            HStack {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .foregroundColor(.furgWarning)
                                Text(error)
                                    .font(.caption)
                                    .foregroundColor(.white.opacity(0.8))
                            }
                            .padding()
                            .background(Color.furgWarning.opacity(0.2))
                            .cornerRadius(12)
                            .padding(.horizontal)
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
                .onChange(of: chatManager.messages.count) {
                    scrollToBottom()
                }
            }

                // Input bar
                GlassChatInputBar(
                    messageText: $messageText,
                    isLoading: chatManager.isLoading,
                    onSend: sendMessage
                )
                .padding(.bottom, 80) // Space for custom tab bar
            }
        }
        .onAppear { animate = true }
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

// MARK: - Glass Empty Chat View

struct GlassEmptyChatView: View {
    var onSuggestionTap: (String) -> Void

    let suggestions = [
        "How am I doing?",
        "Give me spending tips",
        "Can I afford $500?",
        "Show my bill summary"
    ]

    var body: some View {
        VStack(spacing: 24) {
            // Animated FURG icon
            ZStack {
                Circle()
                    .fill(LinearGradient(
                        colors: [.furgMint.opacity(0.3), .furgSeafoam.opacity(0.2)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ))
                    .frame(width: 100, height: 100)

                Circle()
                    .fill(LinearGradient(
                        colors: [.furgMint, .furgSeafoam],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ))
                    .frame(width: 70, height: 70)

                Image(systemName: "bubble.left.and.bubble.right.fill")
                    .font(.system(size: 28))
                    .foregroundColor(.white)
            }

            VStack(spacing: 8) {
                Text("Chat with FURG")
                    .font(.furgTitle2)
                    .foregroundColor(.white)

                Text("Ask me anything about your finances,\nspending habits, or savings goals")
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.6))
                    .multilineTextAlignment(.center)
            }

            // Suggestion chips
            VStack(spacing: 12) {
                Text("Try asking:")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.5))

                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                    ForEach(suggestions, id: \.self) { suggestion in
                        SuggestionChip(text: suggestion) {
                            onSuggestionTap(suggestion)
                        }
                    }
                }
            }
        }
        .padding(32)
        .glassCard()
        .padding(.horizontal)
    }
}

struct SuggestionChip: View {
    let text: String
    var onTap: () -> Void = {}

    var body: some View {
        Button(action: onTap) {
            Text(text)
                .font(.caption)
                .foregroundColor(.furgMint)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .frame(maxWidth: .infinity)
                .background(Color.furgMint.opacity(0.15))
                .cornerRadius(16)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Glass Message Bubble

struct GlassMessageBubble: View {
    let message: ChatMessage

    var body: some View {
        HStack {
            if message.role == .user {
                Spacer(minLength: 60)
            }

            VStack(alignment: message.role == .user ? .trailing : .leading, spacing: 6) {
                if message.role == .assistant {
                    HStack(spacing: 8) {
                        ZStack {
                            Circle()
                                .fill(LinearGradient(
                                    colors: [.furgMint, .furgSeafoam],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ))
                                .frame(width: 24, height: 24)

                            Text("F")
                                .font(.caption2.bold())
                                .foregroundColor(.white)
                        }

                        Text("FURG")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(.white.opacity(0.6))
                    }
                }

                Text(message.content)
                    .padding(14)
                    .background(
                        Group {
                            if message.role == .user {
                                LinearGradient(
                                    colors: [.furgMint, .furgSeafoam],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            } else {
                                Color.white.opacity(0.15)
                            }
                        }
                    )
                    .foregroundColor(message.role == .user ? .furgCharcoal : .white)
                    .cornerRadius(20)

                Text(message.timestamp, style: .time)
                    .font(.caption2)
                    .foregroundColor(.white.opacity(0.4))
            }

            if message.role == .assistant {
                Spacer(minLength: 60)
            }
        }
    }
}

// MARK: - Glass Typing Indicator

struct GlassTypingIndicator: View {
    @State private var animationPhase = 0

    let timer = Timer.publish(every: 0.4, on: .main, in: .common).autoconnect()

    var body: some View {
        HStack {
            HStack(spacing: 8) {
                ZStack {
                    Circle()
                        .fill(LinearGradient(
                            colors: [.furgMint, .furgSeafoam],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ))
                        .frame(width: 24, height: 24)

                    Text("F")
                        .font(.caption2.bold())
                        .foregroundColor(.white)
                }

                HStack(spacing: 6) {
                    ForEach(0..<3, id: \.self) { index in
                        Circle()
                            .fill(Color.furgMint)
                            .frame(width: 8, height: 8)
                            .scaleEffect(animationPhase == index ? 1.2 : 0.8)
                            .opacity(animationPhase == index ? 1 : 0.5)
                            .animation(.easeInOut(duration: 0.3), value: animationPhase)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(Color.white.opacity(0.6))
                .cornerRadius(20)
            }

            Spacer()
        }
        .onReceive(timer) { _ in
            animationPhase = (animationPhase + 1) % 3
        }
    }
}

// MARK: - Glass Chat Input Bar

struct GlassChatInputBar: View {
    @Binding var messageText: String
    let isLoading: Bool
    let onSend: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            TextField("Message FURG...", text: $messageText, axis: .vertical)
                .lineLimit(1...5)
                .padding(12)
                .background(Color.white.opacity(0.1))
                .cornerRadius(20)
                .foregroundColor(.white)

            Button(action: onSend) {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: messageText.isEmpty
                                    ? [Color.white.opacity(0.1), Color.white.opacity(0.1)]
                                    : [.furgMint, .furgSeafoam],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 44, height: 44)

                    Image(systemName: "arrow.up")
                        .font(.body.bold())
                        .foregroundColor(messageText.isEmpty ? .white.opacity(0.3) : .furgCharcoal)
                }
            }
            .disabled(messageText.isEmpty || isLoading)
        }
        .padding()
        .background(
            Rectangle()
                .fill(Color.black.opacity(0.3))
                .background(.ultraThinMaterial)
                .ignoresSafeArea()
        )
    }
}

// Keep old name for backward compatibility
typealias MessageBubble = GlassMessageBubble

#Preview {
    ZStack {
        AnimatedMeshBackground()
        ChatView()
            .environmentObject(ChatManager())
    }
}
