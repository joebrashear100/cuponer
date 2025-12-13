//
//  ChatView.swift
//  Furg
//
//  Premium Apple-style chat interface with glassmorphism
//  Inspired by Apple Wallet, Robinhood, and iOS 18 design language
//

import SwiftUI
import Combine

struct ChatView: View {
    @EnvironmentObject var chatManager: ChatManager
    @State private var messageText = ""
    @State private var scrollProxy: ScrollViewProxy?
    @State private var animate = false
    @FocusState private var isInputFocused: Bool

    var body: some View {
        ZStack {
            // Animated gradient background
            AnimatedMeshBackground()

            VStack(spacing: 0) {
                // Premium header
                chatHeader
                    .offset(y: animate ? 0 : -30)
                    .opacity(animate ? 1 : 0)

                // Messages area
                ScrollViewReader { proxy in
                    ScrollView(showsIndicators: false) {
                        LazyVStack(spacing: 16) {
                            if chatManager.messages.isEmpty {
                                ChatEmptyStateView(onSuggestionTap: { suggestion in
                                    messageText = suggestion
                                    sendMessage()
                                })
                                .transition(.opacity.combined(with: .scale(scale: 0.95)))
                            } else {
                                ForEach(Array(chatManager.messages.enumerated()), id: \.element.id) { index, message in
                                    MessageRow(message: message)
                                        .id(message.id)
                                        .transition(.asymmetric(
                                            insertion: .opacity.combined(with: .move(edge: .bottom)),
                                            removal: .opacity
                                        ))
                                }
                            }

                            if chatManager.isLoading {
                                TypingIndicator()
                                    .transition(.opacity.combined(with: .scale(scale: 0.8)))
                            }

                            // Bottom spacer for input
                            Color.clear.frame(height: 100)
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 16)
                    }
                    .onAppear {
                        scrollProxy = proxy
                        Task { await chatManager.loadHistory() }
                    }
                    .onChange(of: chatManager.messages.count) {
                        scrollToBottom()
                    }
                }

                Spacer(minLength: 0)
            }

            // Floating input bar at bottom
            VStack {
                Spacer()
                floatingInputBar
                    .offset(y: animate ? 0 : 100)
                    .opacity(animate ? 1 : 0)
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                animate = true
            }
        }
        .onTapGesture {
            isInputFocused = false
        }
    }

    // MARK: - Header

    private var chatHeader: some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: 2) {
                Text("FURG")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundColor(.white)

                Text("Your financial assistant")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.white.opacity(0.5))
            }

            Spacer()

            // Menu button
            Menu {
                Button(action: { chatManager.clearHistory() }) {
                    Label("Clear Chat", systemImage: "trash")
                }
            } label: {
                ZStack {
                    Circle()
                        .fill(.ultraThinMaterial)
                        .frame(width: 36, height: 36)

                    Image(systemName: "ellipsis")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.white.opacity(0.8))
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 16)
        .padding(.bottom, 8)
    }

    // MARK: - Floating Input Bar (No Background)

    private var floatingInputBar: some View {
        HStack(spacing: 12) {
            // Text field with glass effect
            HStack(spacing: 8) {
                TextField("Message FURG...", text: $messageText, axis: .vertical)
                    .font(.system(size: 16))
                    .foregroundColor(.white)
                    .lineLimit(1...4)
                    .focused($isInputFocused)
                    .tint(.furgMint)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 24)
                    .fill(.ultraThinMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: 24)
                            .stroke(Color.white.opacity(0.1), lineWidth: 0.5)
                    )
            )

            // Send button
            Button(action: sendMessage) {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                                    ? [Color.white.opacity(0.1), Color.white.opacity(0.1)]
                                    : [.furgMint, .furgSeafoam],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 44, height: 44)

                    Image(systemName: "arrow.up")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(
                            messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                            ? .white.opacity(0.3)
                            : .white
                        )
                }
            }
            .disabled(messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || chatManager.isLoading)
            .scaleEffect(messageText.isEmpty ? 1 : 1.05)
            .animation(.spring(response: 0.3), value: messageText.isEmpty)
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 100) // Tab bar space
    }

    // MARK: - Actions

    private func sendMessage() {
        let text = messageText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }

        withAnimation(.spring(response: 0.4)) {
            messageText = ""
        }

        Task {
            await chatManager.sendMessage(text)
        }
    }

    private func scrollToBottom() {
        guard let lastMessage = chatManager.messages.last else { return }
        withAnimation(.spring(response: 0.4)) {
            scrollProxy?.scrollTo(lastMessage.id, anchor: .bottom)
        }
    }
}

// MARK: - Empty State View

private struct ChatEmptyStateView: View {
    var onSuggestionTap: (String) -> Void

    let suggestions = [
        ("How am I doing?", "chart.line.uptrend.xyaxis"),
        ("Spending tips", "lightbulb.fill"),
        ("Can I afford $500?", "dollarsign.circle"),
        ("Bill summary", "doc.text.fill")
    ]

    var body: some View {
        VStack(spacing: 32) {
            // Animated icon
            ZStack {
                // Outer glow
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [.furgMint.opacity(0.3), .clear],
                            center: .center,
                            startRadius: 30,
                            endRadius: 80
                        )
                    )
                    .frame(width: 160, height: 160)

                // Glass circle
                Circle()
                    .fill(.ultraThinMaterial)
                    .frame(width: 88, height: 88)
                    .overlay(
                        Circle()
                            .stroke(
                                LinearGradient(
                                    colors: [.white.opacity(0.3), .white.opacity(0.05)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1
                            )
                    )

                // Icon
                Image(systemName: "bubble.left.and.bubble.right.fill")
                    .font(.system(size: 32))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.furgMint, .furgSeafoam],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }

            // Text
            VStack(spacing: 8) {
                Text("Chat with FURG")
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundColor(.white)

                Text("Your brutally honest financial AI")
                    .font(.system(size: 15))
                    .foregroundColor(.white.opacity(0.5))
            }

            // Suggestion chips
            VStack(spacing: 12) {
                Text("Try asking")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.white.opacity(0.4))
                    .textCase(.uppercase)
                    .tracking(1)

                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                    ForEach(suggestions, id: \.0) { suggestion, icon in
                        SuggestionChip(text: suggestion, icon: icon) {
                            onSuggestionTap(suggestion)
                        }
                    }
                }
            }
        }
        .padding(.vertical, 40)
    }
}

// MARK: - Suggestion Chip

private struct SuggestionChip: View {
    let text: String
    let icon: String
    var onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 12, weight: .medium))

                Text(text)
                    .font(.system(size: 13, weight: .medium))
                    .lineLimit(1)
            }
            .foregroundColor(.furgMint)
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(.ultraThinMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.furgMint.opacity(0.2), lineWidth: 0.5)
                    )
            )
        }
        .buttonStyle(ScaleButtonStyle())
    }
}

// MARK: - Message Row

private struct MessageRow: View {
    let message: ChatMessage

    var body: some View {
        HStack(alignment: .bottom, spacing: 8) {
            if message.role == .user {
                Spacer(minLength: 50)
            }

            if message.role == .assistant {
                // FURG avatar
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [.furgMint, .furgSeafoam],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 28, height: 28)

                    Text("F")
                        .font(.system(size: 12, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                }
            }

            VStack(alignment: message.role == .user ? .trailing : .leading, spacing: 4) {
                // Message bubble
                Text(message.content)
                    .font(.system(size: 15))
                    .foregroundColor(message.role == .user ? .white : .white.opacity(0.95))
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(
                        Group {
                            if message.role == .user {
                                LinearGradient(
                                    colors: [.furgMint, .furgSeafoam],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            } else {
                                Color.white.opacity(0.08)
                            }
                        }
                    )
                    .clipShape(MessageBubbleShape(isFromUser: message.role == .user))
                    .overlay(
                        MessageBubbleShape(isFromUser: message.role == .user)
                            .stroke(
                                message.role == .user
                                ? Color.clear
                                : Color.white.opacity(0.1),
                                lineWidth: 0.5
                            )
                    )

                // Timestamp
                Text(message.timestamp, style: .time)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(.white.opacity(0.3))
            }

            if message.role == .assistant {
                Spacer(minLength: 50)
            }
        }
    }
}

// MARK: - Message Bubble Shape

private struct MessageBubbleShape: Shape {
    let isFromUser: Bool

    func path(in rect: CGRect) -> Path {
        let radius: CGFloat = 18
        let tailSize: CGFloat = 6

        var path = Path()

        if isFromUser {
            // User message - rounded with tail on right
            path.move(to: CGPoint(x: rect.minX + radius, y: rect.minY))
            path.addLine(to: CGPoint(x: rect.maxX - radius, y: rect.minY))
            path.addQuadCurve(
                to: CGPoint(x: rect.maxX, y: rect.minY + radius),
                control: CGPoint(x: rect.maxX, y: rect.minY)
            )
            path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY - radius))
            path.addQuadCurve(
                to: CGPoint(x: rect.maxX - tailSize, y: rect.maxY),
                control: CGPoint(x: rect.maxX, y: rect.maxY)
            )
            path.addLine(to: CGPoint(x: rect.minX + radius, y: rect.maxY))
            path.addQuadCurve(
                to: CGPoint(x: rect.minX, y: rect.maxY - radius),
                control: CGPoint(x: rect.minX, y: rect.maxY)
            )
            path.addLine(to: CGPoint(x: rect.minX, y: rect.minY + radius))
            path.addQuadCurve(
                to: CGPoint(x: rect.minX + radius, y: rect.minY),
                control: CGPoint(x: rect.minX, y: rect.minY)
            )
        } else {
            // Assistant message - rounded with tail on left
            path.move(to: CGPoint(x: rect.minX + radius, y: rect.minY))
            path.addLine(to: CGPoint(x: rect.maxX - radius, y: rect.minY))
            path.addQuadCurve(
                to: CGPoint(x: rect.maxX, y: rect.minY + radius),
                control: CGPoint(x: rect.maxX, y: rect.minY)
            )
            path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY - radius))
            path.addQuadCurve(
                to: CGPoint(x: rect.maxX - radius, y: rect.maxY),
                control: CGPoint(x: rect.maxX, y: rect.maxY)
            )
            path.addLine(to: CGPoint(x: rect.minX + tailSize, y: rect.maxY))
            path.addQuadCurve(
                to: CGPoint(x: rect.minX, y: rect.maxY - radius),
                control: CGPoint(x: rect.minX, y: rect.maxY)
            )
            path.addLine(to: CGPoint(x: rect.minX, y: rect.minY + radius))
            path.addQuadCurve(
                to: CGPoint(x: rect.minX + radius, y: rect.minY),
                control: CGPoint(x: rect.minX, y: rect.minY)
            )
        }

        path.closeSubpath()
        return path
    }
}

// MARK: - Typing Indicator

private struct TypingIndicator: View {
    @State private var phase = 0
    @State private var timerCancellable: AnyCancellable?

    var body: some View {
        HStack(alignment: .bottom, spacing: 8) {
            // FURG avatar
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [.furgMint, .furgSeafoam],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 28, height: 28)

                Text("F")
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
            }

            // Dots
            HStack(spacing: 4) {
                ForEach(0..<3, id: \.self) { index in
                    Circle()
                        .fill(Color.furgMint)
                        .frame(width: 6, height: 6)
                        .scaleEffect(phase == index ? 1.3 : 0.8)
                        .opacity(phase == index ? 1 : 0.4)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: 18)
                    .fill(Color.white.opacity(0.08))
                    .overlay(
                        RoundedRectangle(cornerRadius: 18)
                            .stroke(Color.white.opacity(0.1), lineWidth: 0.5)
                    )
            )

            Spacer()
        }
        .onAppear {
            // Start timer only when view appears
            timerCancellable = Timer.publish(every: 0.4, on: .main, in: .common)
                .autoconnect()
                .sink { _ in
                    withAnimation(.easeInOut(duration: 0.3)) {
                        phase = (phase + 1) % 3
                    }
                }
        }
        .onDisappear {
            // CRITICAL: Cancel timer when view disappears to prevent memory leak
            timerCancellable?.cancel()
            timerCancellable = nil
        }
        .accessibilityLabel("FURG is typing")
        .accessibilityAddTraits(.updatesFrequently)
    }
}

// MARK: - Scale Button Style

private struct ScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.95 : 1)
            .opacity(configuration.isPressed ? 0.8 : 1)
            .animation(.spring(response: 0.3), value: configuration.isPressed)
    }
}

// MARK: - Preview

#Preview {
    ChatView()
        .environmentObject(ChatManager())
}
