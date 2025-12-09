//
//  MoneyMindfulnessView.swift
//  Furg
//
//  Daily spending reflection and mindfulness features
//

import SwiftUI

struct MoneyMindfulnessView: View {
    @Environment(\.dismiss) var dismiss
    @State private var animate = false
    @State private var todayMood: SpendingMood?
    @State private var reflectionText = ""
    @State private var showReflectionSheet = false

    var body: some View {
        NavigationStack {
            ZStack {
                Color.furgCharcoal.ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 28) {
                        // Daily check-in card
                        dailyCheckInCard
                            .offset(y: animate ? 0 : 20)
                            .opacity(animate ? 1 : 0)

                        // Today's spending summary
                        todaysSummary
                            .offset(y: animate ? 0 : 20)
                            .opacity(animate ? 1 : 0)
                            .animation(.spring(response: 0.6).delay(0.1), value: animate)

                        // Spending intention
                        spendingIntention
                            .offset(y: animate ? 0 : 20)
                            .opacity(animate ? 1 : 0)
                            .animation(.spring(response: 0.6).delay(0.15), value: animate)

                        // Mindful moments
                        mindfulMoments
                            .offset(y: animate ? 0 : 20)
                            .opacity(animate ? 1 : 0)
                            .animation(.spring(response: 0.6).delay(0.2), value: animate)

                        // Weekly mood trend
                        weeklyMoodTrend
                            .offset(y: animate ? 0 : 20)
                            .opacity(animate ? 1 : 0)
                            .animation(.spring(response: 0.6).delay(0.25), value: animate)

                        // Reflection history
                        reflectionHistory
                            .offset(y: animate ? 0 : 20)
                            .opacity(animate ? 1 : 0)
                            .animation(.spring(response: 0.6).delay(0.3), value: animate)

                        Spacer(minLength: 40)
                    }
                    .padding(.horizontal, 20)
                }
            }
            .navigationTitle("Money Mindfulness")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                        .foregroundColor(.furgMint)
                }
            }
            .sheet(isPresented: $showReflectionSheet) {
                ReflectionSheet(mood: todayMood ?? .neutral, text: $reflectionText)
            }
            .onAppear {
                withAnimation(.spring(response: 0.6)) {
                    animate = true
                }
            }
        }
    }

    // MARK: - Daily Check-In

    private var dailyCheckInCard: some View {
        VStack(spacing: 20) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Daily Check-In")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.white)

                    Text("How do you feel about your spending today?")
                        .font(.system(size: 13))
                        .foregroundColor(.white.opacity(0.6))
                }

                Spacer()

                if todayMood != nil {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 24))
                        .foregroundColor(.furgSuccess)
                }
            }

            // Mood selector
            HStack(spacing: 12) {
                ForEach(SpendingMood.allCases, id: \.self) { mood in
                    MoodButton(mood: mood, isSelected: todayMood == mood) {
                        withAnimation(.spring(response: 0.3)) {
                            todayMood = mood
                        }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                            showReflectionSheet = true
                        }
                    }
                }
            }

            if todayMood == nil {
                Text("Tap to reflect on today's spending")
                    .font(.system(size: 11))
                    .foregroundColor(.white.opacity(0.4))
            }
        }
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 24)
                        .stroke(
                            LinearGradient(
                                colors: [.furgMint.opacity(0.3), .furgSeafoam.opacity(0.1)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                )
        )
    }

    // MARK: - Today's Summary

    private var todaysSummary: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Today's Spending")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.white.opacity(0.6))

            HStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("$127.45")
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .foregroundColor(.white)

                    HStack(spacing: 4) {
                        Image(systemName: "arrow.down")
                            .font(.system(size: 10, weight: .bold))
                        Text("23% below average")
                            .font(.system(size: 12, weight: .medium))
                    }
                    .foregroundColor(.furgSuccess)
                }

                Spacer()

                // Circular progress
                ZStack {
                    Circle()
                        .stroke(Color.white.opacity(0.1), lineWidth: 8)
                        .frame(width: 70, height: 70)

                    Circle()
                        .trim(from: 0, to: 0.65)
                        .stroke(Color.furgMint, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                        .frame(width: 70, height: 70)
                        .rotationEffect(.degrees(-90))

                    VStack(spacing: 0) {
                        Text("65%")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.white)
                        Text("of limit")
                            .font(.system(size: 8))
                            .foregroundColor(.white.opacity(0.5))
                    }
                }
            }

            // Transaction count
            HStack {
                Image(systemName: "creditcard.fill")
                    .font(.system(size: 12))
                    .foregroundColor(.white.opacity(0.4))

                Text("4 transactions today")
                    .font(.system(size: 12))
                    .foregroundColor(.white.opacity(0.5))

                Spacer()

                Text("View All")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.furgMint)
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color.white.opacity(0.1), lineWidth: 0.5)
                )
        )
    }

    // MARK: - Spending Intention

    private var spendingIntention: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "sparkles")
                    .foregroundColor(.furgMint)

                Text("Today's Intention")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white.opacity(0.6))
            }

            Text("\"I will only spend on necessities and skip impulse purchases.\"")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.white)
                .italic()
                .padding(16)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.furgMint.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 12))

            Button {
                // Edit intention
            } label: {
                HStack {
                    Image(systemName: "pencil")
                    Text("Set New Intention")
                }
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(.furgMint)
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color.white.opacity(0.1), lineWidth: 0.5)
                )
        )
    }

    // MARK: - Mindful Moments

    private var mindfulMoments: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Mindful Moments")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.white.opacity(0.6))

            VStack(spacing: 10) {
                MindfulPromptCard(
                    icon: "brain.head.profile",
                    title: "Pause Before Purchase",
                    description: "Take 3 deep breaths before any purchase over $50",
                    color: .purple
                )

                MindfulPromptCard(
                    icon: "clock.fill",
                    title: "24-Hour Rule",
                    description: "Wait 24 hours before non-essential purchases",
                    color: .blue
                )

                MindfulPromptCard(
                    icon: "questionmark.circle.fill",
                    title: "Ask Yourself",
                    description: "\"Will this bring lasting value to my life?\"",
                    color: .orange
                )
            }
        }
    }

    // MARK: - Weekly Mood Trend

    private var weeklyMoodTrend: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("This Week's Mood")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.white.opacity(0.6))

            HStack(spacing: 12) {
                ForEach(weekMoods, id: \.day) { dayMood in
                    VStack(spacing: 8) {
                        Text(dayMood.emoji)
                            .font(.system(size: 24))
                            .opacity(dayMood.mood != nil ? 1 : 0.3)

                        Text(dayMood.day)
                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(.white.opacity(0.5))
                    }
                    .frame(maxWidth: .infinity)
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.white.opacity(0.05))
            )

            // Stats
            HStack(spacing: 20) {
                MoodStatItem(label: "Average", value: "Good", color: .furgSuccess)
                MoodStatItem(label: "Best Day", value: "Monday", color: .furgMint)
                MoodStatItem(label: "Needs Work", value: "Thursday", color: .furgWarning)
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color.white.opacity(0.1), lineWidth: 0.5)
                )
        )
    }

    private var weekMoods: [DayMood] {
        [
            DayMood(day: "Mon", mood: .great, emoji: "😊"),
            DayMood(day: "Tue", mood: .good, emoji: "🙂"),
            DayMood(day: "Wed", mood: .good, emoji: "🙂"),
            DayMood(day: "Thu", mood: .poor, emoji: "😟"),
            DayMood(day: "Fri", mood: .neutral, emoji: "😐"),
            DayMood(day: "Sat", mood: nil, emoji: "⚪️"),
            DayMood(day: "Sun", mood: nil, emoji: "⚪️")
        ]
    }

    // MARK: - Reflection History

    private var reflectionHistory: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Recent Reflections")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white.opacity(0.6))

                Spacer()

                Button("See All") {}
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.furgMint)
            }

            VStack(spacing: 12) {
                ReflectionRow(
                    date: "Today",
                    mood: .good,
                    excerpt: "Stayed within budget today. Resisted the urge to order takeout..."
                )

                ReflectionRow(
                    date: "Yesterday",
                    mood: .neutral,
                    excerpt: "Spent more than planned on groceries but it was all necessary items..."
                )

                ReflectionRow(
                    date: "Dec 5",
                    mood: .great,
                    excerpt: "No-spend day! Felt really empowered to see my savings grow..."
                )
            }
        }
    }
}

// MARK: - Supporting Views

enum SpendingMood: String, CaseIterable {
    case great, good, neutral, poor, terrible

    var emoji: String {
        switch self {
        case .great: return "😊"
        case .good: return "🙂"
        case .neutral: return "😐"
        case .poor: return "😟"
        case .terrible: return "😢"
        }
    }

    var label: String {
        switch self {
        case .great: return "Great"
        case .good: return "Good"
        case .neutral: return "Okay"
        case .poor: return "Poor"
        case .terrible: return "Bad"
        }
    }

    var color: Color {
        switch self {
        case .great: return .furgSuccess
        case .good: return .furgMint
        case .neutral: return .furgInfo
        case .poor: return .furgWarning
        case .terrible: return .furgDanger
        }
    }
}

struct DayMood {
    let day: String
    let mood: SpendingMood?
    let emoji: String
}

struct MoodButton: View {
    let mood: SpendingMood
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                Text(mood.emoji)
                    .font(.system(size: 28))

                Text(mood.label)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(isSelected ? mood.color : .white.opacity(0.5))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(isSelected ? mood.color.opacity(0.2) : Color.clear)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? mood.color : Color.clear, lineWidth: 2)
            )
        }
    }
}

struct MindfulPromptCard: View {
    let icon: String
    let title: String
    let description: String
    let color: Color

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundColor(color)
                .frame(width: 44, height: 44)
                .background(color.opacity(0.2))
                .clipShape(RoundedRectangle(cornerRadius: 12))

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white)

                Text(description)
                    .font(.system(size: 12))
                    .foregroundColor(.white.opacity(0.6))
                    .lineLimit(2)
            }

            Spacer()
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color.white.opacity(0.05))
        )
    }
}

struct MoodStatItem: View {
    let label: String
    let value: String
    let color: Color

    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(color)

            Text(label)
                .font(.system(size: 10))
                .foregroundColor(.white.opacity(0.4))
        }
        .frame(maxWidth: .infinity)
    }
}

struct ReflectionRow: View {
    let date: String
    let mood: SpendingMood
    let excerpt: String

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Text(mood.emoji)
                .font(.system(size: 20))

            VStack(alignment: .leading, spacing: 4) {
                Text(date)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.white.opacity(0.5))

                Text(excerpt)
                    .font(.system(size: 13))
                    .foregroundColor(.white.opacity(0.8))
                    .lineLimit(2)
            }

            Spacer()
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color.white.opacity(0.05))
        )
    }
}

struct ReflectionSheet: View {
    @Environment(\.dismiss) var dismiss
    let mood: SpendingMood
    @Binding var text: String

    var body: some View {
        NavigationStack {
            ZStack {
                Color.furgCharcoal.ignoresSafeArea()

                VStack(spacing: 24) {
                    VStack(spacing: 12) {
                        Text(mood.emoji)
                            .font(.system(size: 60))

                        Text("You're feeling \(mood.label.lowercased())")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.white)

                        Text("Take a moment to reflect on your spending today")
                            .font(.system(size: 14))
                            .foregroundColor(.white.opacity(0.6))
                    }
                    .padding(.top, 20)

                    VStack(alignment: .leading, spacing: 8) {
                        Text("What influenced your spending today?")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.white.opacity(0.7))

                        TextEditor(text: $text)
                            .font(.system(size: 16))
                            .foregroundColor(.white)
                            .scrollContentBackground(.hidden)
                            .frame(minHeight: 150)
                            .padding(12)
                            .background(Color.white.opacity(0.08))
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    .padding(.horizontal, 20)

                    // Prompt suggestions
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Reflection prompts:")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.white.opacity(0.5))

                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                PromptChip(text: "What could I do differently?")
                                PromptChip(text: "Was this spending aligned with my goals?")
                                PromptChip(text: "How did I feel after each purchase?")
                            }
                        }
                    }
                    .padding(.horizontal, 20)

                    Spacer()

                    Button {
                        dismiss()
                    } label: {
                        Text("Save Reflection")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.furgCharcoal)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(
                                LinearGradient(
                                    colors: [.furgMint, .furgSeafoam],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 20)
                }
            }
            .navigationTitle("Daily Reflection")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                        .foregroundColor(.white.opacity(0.7))
                }
            }
        }
    }
}

struct PromptChip: View {
    let text: String

    var body: some View {
        Text(text)
            .font(.system(size: 12))
            .foregroundColor(.white.opacity(0.7))
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Color.white.opacity(0.1))
            .clipShape(Capsule())
    }
}

// MARK: - Preview

#Preview {
    MoneyMindfulnessView()
}
