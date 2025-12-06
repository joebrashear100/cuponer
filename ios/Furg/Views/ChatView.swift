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
        VStack(spacing: 0) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("FURG")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.furgCharcoal)

                    Text("Your financial assistant")
                        .font(.subheadline)
                        .foregroundColor(.furgCharcoal.opacity(0.6))
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
                        .background(Circle().fill(Color.white.opacity(0.3)))
                }
            }
            .padding(.horizontal)
            .padding(.top)
            .offset(y: animate ? 0 : -20)
            .opacity(animate ? 1 : 0)
            .animation(.easeOut(duration: 0.5), value: animate)

            // Messages
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(spacing: 16) {
                        if chatManager.messages.isEmpty {
                            GlassEmptyChatView()
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
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.furgCharcoal)

                Text("Ask me anything about your finances,\nspending habits, or savings goals")
                    .font(.subheadline)
                    .foregroundColor(.furgCharcoal.opacity(0.6))
                    .multilineTextAlignment(.center)
            }

            // Suggestion chips
            VStack(spacing: 12) {
                Text("Try asking:")
                    .font(.caption)
                    .foregroundColor(.furgCharcoal.opacity(0.5))

                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                    SuggestionChip(text: "How am I doing?")
                    SuggestionChip(text: "Spending tips")
                    SuggestionChip(text: "Can I afford...?")
                    SuggestionChip(text: "Bill summary")
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

    var body: some View {
        Text(text)
            .font(.caption)
            .foregroundColor(.furgMint)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Color.furgMint.opacity(0.15))
            .cornerRadius(16)
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
                            .foregroundColor(.furgCharcoal.opacity(0.6))
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
                                Color.white.opacity(0.6)
                            }
                        }
                    )
                    .foregroundColor(message.role == .user ? .white : .furgCharcoal)
                    .cornerRadius(20)
                    .cornerRadius(message.role == .user ? 20 : 20, corners: message.role == .user ? [.topLeft, .topRight, .bottomLeft] : [.topLeft, .topRight, .bottomRight])

                Text(message.timestamp, style: .time)
                    .font(.caption2)
                    .foregroundColor(.furgCharcoal.opacity(0.4))
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
                    ForEach(0..<3) { index in
                        Circle()
                            .fill(Color.furgMint)
                            .frame(width: 8, height: 8)
                            .scaleEffect(animationPhase == index ? 1.2 : 0.8)
                            .opacity(animationPhase == index ? 1 : 0.5)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(Color.white.opacity(0.6))
                .cornerRadius(20)
            }

            Spacer()
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 0.4).repeatForever()) {
                animationPhase = (animationPhase + 1) % 3
            }
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
                .background(Color.white.opacity(0.6))
                .cornerRadius(20)
                .foregroundColor(.furgCharcoal)

            Button(action: onSend) {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: messageText.isEmpty
                                    ? [Color.gray.opacity(0.3), Color.gray.opacity(0.3)]
                                    : [.furgMint, .furgSeafoam],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 44, height: 44)

                    Image(systemName: "arrow.up")
                        .font(.body.bold())
                        .foregroundColor(messageText.isEmpty ? .gray : .white)
                }
            }
            .disabled(messageText.isEmpty || isLoading)
        }
        .padding()
        .background(
            Rectangle()
                .fill(.ultraThinMaterial)
                .ignoresSafeArea()
        )
    }
}

// MARK: - Corner Radius Extension

extension View {
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(RoundedCorner(radius: radius, corners: corners))
    }
}

struct RoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners

    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: corners,
            cornerRadii: CGSize(width: radius, height: radius)
        )
        return Path(path.cgPath)
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
