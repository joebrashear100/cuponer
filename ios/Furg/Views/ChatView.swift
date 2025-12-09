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
            CopilotBackground()

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
                                EmptyStateView(onSuggestionTap: { suggestion in
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
        VStack(spacing: 12) {
            HStack(alignment: .center) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("FURG")
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundColor(.white)

                    HStack(spacing: 6) {
                        Circle()
                            .fill(Color.furgSuccess)
                            .frame(width: 6, height: 6)
                        Text("Online • Ready to help")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.white.opacity(0.5))
                    }
                }

                Spacer()

                // Quick actions
                HStack(spacing: 10) {
                    Button {
                        // Voice input (placeholder)
                    } label: {
                        ZStack {
                            Circle()
                                .fill(Color.white.opacity(0.08))
                                .frame(width: 36, height: 36)

                            Image(systemName: "mic.fill")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.white.opacity(0.6))
                        }
                    }

                    // Menu button
                    Menu {
                        Button(action: { chatManager.clearHistory() }) {
                            Label("Clear Chat", systemImage: "trash")
                        }
                        Button(action: {}) {
                            Label("Export Chat", systemImage: "square.and.arrow.up")
                        }
                        Button(action: {}) {
                            Label("Voice Mode", systemImage: "waveform")
                        }
                    } label: {
                        ZStack {
                            Circle()
                                .fill(Color.white.opacity(0.08))
                                .frame(width: 36, height: 36)

                            Image(systemName: "ellipsis")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(.white.opacity(0.8))
                        }
                    }
                }
            }

            // Quick action pills (when no messages)
            if chatManager.messages.isEmpty {
                quickActionPills
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 16)
        .padding(.bottom, 8)
    }

    private var quickActionPills: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                QuickActionPill(icon: "chart.bar.fill", text: "Spending Report", color: .purple) {
                    messageText = "Give me a spending report"
                    sendMessage()
                }
                QuickActionPill(icon: "bell.fill", text: "Bill Alerts", color: .furgWarning) {
                    messageText = "What bills are due soon?"
                    sendMessage()
                }
                QuickActionPill(icon: "target", text: "Goal Check", color: .furgMint) {
                    messageText = "How are my savings goals?"
                    sendMessage()
                }
                QuickActionPill(icon: "sparkles", text: "Daily Tip", color: .yellow) {
                    messageText = "Give me a financial tip"
                    sendMessage()
                }
            }
        }
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
                    .fill(Color.white.opacity(0.08))
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

private struct EmptyStateView: View {
    var onSuggestionTap: (String) -> Void
    @State private var selectedCategory = 0

    let categories = ["Quick", "Budget", "Goals", "Analytics"]

    let suggestionsByCategory: [[SuggestionItem]] = [
        // Quick
        [
            SuggestionItem(text: "How am I doing?", icon: "chart.line.uptrend.xyaxis", color: .furgMint),
            SuggestionItem(text: "Can I afford $500?", icon: "dollarsign.circle", color: .furgSuccess),
            SuggestionItem(text: "What's my spending power?", icon: "creditcard.fill", color: .blue),
            SuggestionItem(text: "Surprise me with a tip", icon: "lightbulb.fill", color: .yellow)
        ],
        // Budget
        [
            SuggestionItem(text: "Create a budget for me", icon: "chart.pie.fill", color: .purple),
            SuggestionItem(text: "Where am I overspending?", icon: "exclamationmark.triangle.fill", color: .furgWarning),
            SuggestionItem(text: "How to save $500/month?", icon: "banknote.fill", color: .furgMint),
            SuggestionItem(text: "Review my subscriptions", icon: "repeat", color: .indigo)
        ],
        // Goals
        [
            SuggestionItem(text: "Help me save for vacation", icon: "airplane", color: .cyan),
            SuggestionItem(text: "Emergency fund advice", icon: "shield.fill", color: .furgSuccess),
            SuggestionItem(text: "Debt payoff strategy", icon: "creditcard.trianglebadge.exclamationmark.fill", color: .furgDanger),
            SuggestionItem(text: "Investment suggestions", icon: "chart.bar.fill", color: .purple)
        ],
        // Analytics
        [
            SuggestionItem(text: "Analyze my spending habits", icon: "magnifyingglass", color: .blue),
            SuggestionItem(text: "Compare to last month", icon: "calendar", color: .orange),
            SuggestionItem(text: "My financial health score", icon: "heart.fill", color: .red),
            SuggestionItem(text: "Predict next month's spending", icon: "wand.and.stars", color: .furgMint)
        ]
    ]

    var body: some View {
        VStack(spacing: 28) {
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
                    .frame(width: 140, height: 140)

                // Glass circle
                Circle()
                    .fill(Color.white.opacity(0.08))
                    .frame(width: 80, height: 80)
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
                Image(systemName: "brain.head.profile")
                    .font(.system(size: 28))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.furgMint, .furgSeafoam],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }

            // Text
            VStack(spacing: 6) {
                Text("Chat with FURG")
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                    .foregroundColor(.white)

                Text("Your brutally honest financial AI")
                    .font(.system(size: 14))
                    .foregroundColor(.white.opacity(0.5))
            }

            // Category tabs
            HStack(spacing: 6) {
                ForEach(Array(categories.enumerated()), id: \.offset) { index, category in
                    Button {
                        withAnimation(.spring(response: 0.3)) {
                            selectedCategory = index
                        }
                    } label: {
                        Text(category)
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(selectedCategory == index ? .furgCharcoal : .white.opacity(0.6))
                            .padding(.horizontal, 14)
                            .padding(.vertical, 8)
                            .background(
                                Capsule()
                                    .fill(selectedCategory == index ? Color.furgMint : Color.white.opacity(0.08))
                            )
                    }
                }
            }

            // Suggestion chips based on category
            VStack(spacing: 10) {
                ForEach(suggestionsByCategory[selectedCategory], id: \.text) { suggestion in
                    RichSuggestionChip(item: suggestion) {
                        onSuggestionTap(suggestion.text)
                    }
                }
            }

            // Quick stats footer
            HStack(spacing: 24) {
                QuickStatBadge(icon: "checkmark.circle.fill", value: "24/7", label: "Available", color: .furgSuccess)
                QuickStatBadge(icon: "bolt.fill", value: "< 1s", label: "Response", color: .furgWarning)
                QuickStatBadge(icon: "lock.fill", value: "100%", label: "Private", color: .furgMint)
            }
            .padding(.top, 8)
        }
        .padding(.vertical, 32)
    }
}

// MARK: - Suggestion Item

private struct SuggestionItem {
    let text: String
    let icon: String
    let color: Color
}

// MARK: - Rich Suggestion Chip

private struct RichSuggestionChip: View {
    let item: SuggestionItem
    var onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(item.color.opacity(0.2))
                        .frame(width: 36, height: 36)

                    Image(systemName: item.icon)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(item.color)
                }

                Text(item.text)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white)
                    .lineLimit(1)

                Spacer()

                Image(systemName: "arrow.up.right")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(.white.opacity(0.3))
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(Color.white.opacity(0.06))
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(Color.white.opacity(0.1), lineWidth: 0.5)
                    )
            )
        }
        .buttonStyle(ScaleButtonStyle())
    }
}

// MARK: - Quick Stat Badge

private struct QuickStatBadge: View {
    let icon: String
    let value: String
    let label: String
    let color: Color

    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundColor(color)

            Text(value)
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(.white)

            Text(label)
                .font(.system(size: 9))
                .foregroundColor(.white.opacity(0.4))
        }
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
                    .fill(Color.white.opacity(0.08))
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

// MARK: - Quick Action Pill

private struct QuickActionPill: View {
    let icon: String
    let text: String
    let color: Color
    var onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(color)

                Text(text)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.white.opacity(0.8))
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                Capsule()
                    .fill(color.opacity(0.15))
                    .overlay(
                        Capsule()
                            .stroke(color.opacity(0.3), lineWidth: 0.5)
                    )
            )
        }
        .buttonStyle(ScaleButtonStyle())
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
