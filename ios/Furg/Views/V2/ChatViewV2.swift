//
//  ChatViewV2.swift
//  Furg
//
//  Full AI Assistant chat interface with personality
//

import SwiftUI

struct ChatViewV2: View {
    @Environment(\.dismiss) var dismiss
    @State private var messageText = ""
    @State private var messages: [ChatMessageV2] = []
    @State private var isTyping = false
    @State private var showSuggestions = true
    @FocusState private var isInputFocused: Bool

    let suggestions = [
        "How am I doing this month?",
        "Where can I cut spending?",
        "Show my subscriptions",
        "Predict next month's expenses"
    ]

    var body: some View {
        NavigationStack {
            ZStack {
                Color.v2Background.ignoresSafeArea()

                VStack(spacing: 0) {
                    // Messages
                    ScrollViewReader { proxy in
                        ScrollView {
                            LazyVStack(spacing: 16) {
                                // Welcome message
                                if messages.isEmpty {
                                    welcomeSection
                                }

                                ForEach(messages) { message in
                                    ChatBubbleV2(message: message)
                                        .id(message.id)
                                }

                                if isTyping {
                                    TypingIndicatorV2()
                                        .id("typing")
                                }
                            }
                            .padding()
                        }
                        .onChange(of: messages.count) { _, _ in
                            withAnimation {
                                if let lastMessage = messages.last {
                                    proxy.scrollTo(lastMessage.id, anchor: .bottom)
                                }
                            }
                        }
                    }

                    // Suggestions
                    if showSuggestions && messages.isEmpty {
                        suggestionsSection
                    }

                    // Input bar
                    inputBar
                }
            }
            .navigationTitle("AI Assistant")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button { dismiss() } label: {
                        Image(systemName: "xmark")
                            .foregroundColor(.v2TextSecondary)
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button("Clear conversation", role: .destructive) {
                            messages.removeAll()
                            showSuggestions = true
                        }
                        Button("Export chat") { }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                            .foregroundColor(.v2TextSecondary)
                    }
                }
            }
        }
    }

    // MARK: - Welcome Section

    var welcomeSection: some View {
        VStack(spacing: 20) {
            Spacer().frame(height: 40)

            // AI Avatar
            ZStack {
                Circle()
                    .fill(V2Gradients.primary)
                    .frame(width: 80, height: 80)

                Image(systemName: "sparkles")
                    .font(.system(size: 36))
                    .foregroundColor(.v2TextInverse)
            }

            VStack(spacing: 8) {
                Text("Hey! I'm your AI assistant")
                    .font(.v2Title)
                    .foregroundColor(.v2TextPrimary)

                Text("Ask me anything about your finances.\nI can analyze spending, find savings,\nand help you reach your goals.")
                    .font(.v2Body)
                    .foregroundColor(.v2TextSecondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
            }

            Spacer().frame(height: 20)
        }
    }

    // MARK: - Suggestions

    var suggestionsSection: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(suggestions, id: \.self) { suggestion in
                    Button {
                        sendMessage(suggestion)
                    } label: {
                        Text(suggestion)
                            .font(.v2Caption)
                            .foregroundColor(.v2Primary)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 10)
                            .background(Color.v2Primary.opacity(0.12))
                            .cornerRadius(18)
                    }
                }
            }
            .padding(.horizontal)
            .padding(.bottom, 12)
        }
    }

    // MARK: - Input Bar

    var inputBar: some View {
        HStack(spacing: 12) {
            // Text field
            HStack {
                TextField("Ask anything...", text: $messageText, axis: .vertical)
                    .font(.v2Body)
                    .foregroundColor(.v2TextPrimary)
                    .lineLimit(1...4)
                    .focused($isInputFocused)

                if !messageText.isEmpty {
                    Button {
                        messageText = ""
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.v2TextTertiary)
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Color.v2CardBackground)
            .cornerRadius(24)

            // Send button
            Button {
                sendMessage(messageText)
            } label: {
                Image(systemName: "arrow.up.circle.fill")
                    .font(.system(size: 40))
                    .foregroundColor(messageText.isEmpty ? .v2TextTertiary : .v2Primary)
            }
            .disabled(messageText.isEmpty)
        }
        .padding(.horizontal)
        .padding(.vertical, 12)
        .background(Color.v2BackgroundSecondary)
    }

    // MARK: - Actions

    func sendMessage(_ text: String) {
        guard !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }

        let userMessage = ChatMessageV2(content: text, isUser: true)
        messages.append(userMessage)
        messageText = ""
        showSuggestions = false
        isInputFocused = false

        // Simulate AI response
        isTyping = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            isTyping = false
            let response = generateMockResponse(for: text)
            messages.append(response)
        }
    }

    func generateMockResponse(for query: String) -> ChatMessageV2 {
        let lowercased = query.lowercased()

        if lowercased.contains("doing") || lowercased.contains("month") {
            return ChatMessageV2(
                content: "You're doing great this month! 🎉\n\nYou've spent $1,350 of your $2,000 budget, leaving $650 for the next 15 days. That's about $43/day.\n\nYour biggest expense was Food & Dining at $387. You're actually 12% under your usual spending pace!",
                isUser: false,
                hasChart: true
            )
        } else if lowercased.contains("cut") || lowercased.contains("save") {
            return ChatMessageV2(
                content: "I found 3 ways to save money:\n\n1. **Subscriptions** - You have 2 overlapping streaming services ($25/mo)\n\n2. **Food delivery** - You've spent $180 on DoorDash. Cooking could save ~$120/mo\n\n3. **Unused gym** - No check-ins in 3 weeks. Consider pausing? ($45/mo)",
                isUser: false
            )
        } else if lowercased.contains("subscription") {
            return ChatMessageV2(
                content: "You have 8 active subscriptions totaling $127/month:\n\n• Netflix - $15.99\n• Spotify - $10.99\n• iCloud - $2.99\n• Gym - $45.00\n• HBO Max - $15.99\n• NYT - $17.00\n• Hulu - $7.99\n• YouTube Premium - $11.99\n\nWant me to analyze which ones you use most?",
                isUser: false
            )
        } else if lowercased.contains("predict") || lowercased.contains("next") {
            return ChatMessageV2(
                content: "Based on your patterns, here's my prediction for next month:\n\n📊 **Projected spending:** $2,180\n📈 **Trend:** +9% vs this month\n\n**Why the increase?**\n• Holiday season spending (+$150)\n• Annual insurance payment due (+$80)\n\nWant me to create a budget plan?",
                isUser: false,
                hasChart: true
            )
        } else {
            return ChatMessageV2(
                content: "I can help you with that! Let me analyze your financial data.\n\nYour current financial health score is 78/100, which is good. Your spending is on track and you're building your emergency fund steadily.\n\nIs there something specific you'd like to dive deeper into?",
                isUser: false
            )
        }
    }
}

// MARK: - Chat Message Model

struct ChatMessageV2: Identifiable {
    let id = UUID()
    let content: String
    let isUser: Bool
    var hasChart: Bool = false
    let timestamp = Date()
}

// MARK: - Chat Bubble

struct ChatBubbleV2: View {
    let message: ChatMessageV2

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            if !message.isUser {
                // AI Avatar
                ZStack {
                    Circle()
                        .fill(V2Gradients.primary)
                        .frame(width: 32, height: 32)

                    Image(systemName: "sparkles")
                        .font(.system(size: 14))
                        .foregroundColor(.v2TextInverse)
                }
            }

            VStack(alignment: message.isUser ? .trailing : .leading, spacing: 8) {
                // Message bubble
                Text(LocalizedStringKey(message.content))
                    .font(.v2Body)
                    .foregroundColor(message.isUser ? .v2TextInverse : .v2TextPrimary)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(
                        message.isUser
                        ? AnyShapeStyle(V2Gradients.primary)
                        : AnyShapeStyle(Color.v2CardBackground)
                    )
                    .cornerRadius(20)
                    .cornerRadius(message.isUser ? 20 : 4, corners: message.isUser ? [.bottomRight] : [.bottomLeft])

                // Mock chart for demo
                if message.hasChart {
                    MockChartView()
                        .frame(height: 120)
                        .padding(.horizontal, 4)
                }

                // Timestamp
                Text(message.timestamp, style: .time)
                    .font(.v2CaptionSmall)
                    .foregroundColor(.v2TextTertiary)
            }
            .frame(maxWidth: 280, alignment: message.isUser ? .trailing : .leading)

            if message.isUser {
                Spacer().frame(width: 32)
            }
        }
        .frame(maxWidth: .infinity, alignment: message.isUser ? .trailing : .leading)
    }
}

// MARK: - Typing Indicator

struct TypingIndicatorV2: View {
    @State private var dotScale: [CGFloat] = [1, 1, 1]

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            ZStack {
                Circle()
                    .fill(V2Gradients.primary)
                    .frame(width: 32, height: 32)

                Image(systemName: "sparkles")
                    .font(.system(size: 14))
                    .foregroundColor(.v2TextInverse)
            }

            HStack(spacing: 6) {
                ForEach(0..<3, id: \.self) { index in
                    Circle()
                        .fill(Color.v2TextTertiary)
                        .frame(width: 8, height: 8)
                        .scaleEffect(dotScale[index])
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 16)
            .background(Color.v2CardBackground)
            .cornerRadius(20)
            .cornerRadius(4, corners: [.bottomLeft])
            .onAppear {
                animateDots()
            }

            Spacer()
        }
    }

    func animateDots() {
        for i in 0..<3 {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(i) * 0.15) {
                withAnimation(Animation.easeInOut(duration: 0.4).repeatForever(autoreverses: true)) {
                    dotScale[i] = 1.4
                }
            }
        }
    }
}

// MARK: - Mock Chart

struct MockChartView: View {
    var body: some View {
        V2Card(padding: 12, cornerRadius: 12) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Monthly Spending")
                    .font(.v2CaptionSmall)
                    .foregroundColor(.v2TextTertiary)

                HStack(alignment: .bottom, spacing: 8) {
                    ForEach(0..<7, id: \.self) { i in
                        VStack {
                            RoundedRectangle(cornerRadius: 4)
                                .fill(i == 6 ? Color.v2Primary : Color.v2Primary.opacity(0.4))
                                .frame(width: 28, height: CGFloat.random(in: 30...70))
                        }
                    }
                }
            }
        }
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

// MARK: - Preview

#Preview {
    ChatViewV2()
}
