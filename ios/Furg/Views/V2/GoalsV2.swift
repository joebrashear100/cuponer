//
//  GoalsV2.swift
//  Furg
//
//  Savings goals with progress tracking and projections
//

import SwiftUI
import Charts

// MARK: - Goals Dashboard

struct GoalsV2: View {
    @Environment(\.dismiss) var dismiss
    @State private var showAddGoal = false
    @State private var selectedGoal: GoalV2?

    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 24) {
                    // Summary card
                    goalsSummaryCard

                    // Active goals
                    activeGoalsSection

                    // Completed goals
                    if !completedGoals.isEmpty {
                        completedGoalsSection
                    }
                }
                .padding(20)
            }
            .background(Color.v2Background)
            .navigationTitle("Goals")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button { dismiss() } label: {
                        Image(systemName: "xmark")
                            .foregroundColor(.v2TextSecondary)
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button { showAddGoal = true } label: {
                        Image(systemName: "plus")
                            .foregroundColor(.v2Mint)
                    }
                }
            }
            .sheet(isPresented: $showAddGoal) {
                AddGoalSheetV2()
                    .presentationBackground(Color.v2Background)
            }
            .sheet(item: $selectedGoal) { goal in
                GoalDetailV2(goal: goal)
                    .presentationBackground(Color.v2Background)
            }
        }
    }

    // MARK: - Summary Card

    var goalsSummaryCard: some View {
        V2Card(padding: 20) {
            VStack(spacing: 16) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Total Saved")
                            .font(.v2Caption)
                            .foregroundColor(.v2TextSecondary)

                        HStack(alignment: .firstTextBaseline, spacing: 4) {
                            Text("$")
                                .font(.system(size: 24, weight: .medium, design: .rounded))
                                .foregroundColor(.v2Mint)
                            Text(formatNumber(totalSaved))
                                .font(.v2DisplayMedium)
                                .foregroundColor(.v2TextPrimary)
                        }
                    }

                    Spacer()

                    VStack(alignment: .trailing, spacing: 4) {
                        Text("Target")
                            .font(.v2Caption)
                            .foregroundColor(.v2TextSecondary)

                        Text("$\(formatNumber(totalTarget))")
                            .font(.v2MetricMedium)
                            .foregroundColor(.v2TextTertiary)
                    }
                }

                // Overall progress
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 6)
                            .fill(Color.white.opacity(0.1))

                        RoundedRectangle(cornerRadius: 6)
                            .fill(V2Gradients.budgetLine)
                            .frame(width: geo.size.width * min(totalSaved / totalTarget, 1))
                    }
                }
                .frame(height: 10)

                HStack {
                    Text("\(Int(totalSaved / totalTarget * 100))% of goal")
                        .font(.v2CaptionSmall)
                        .foregroundColor(.v2TextTertiary)

                    Spacer()

                    Text("$\(formatNumber(totalTarget - totalSaved)) to go")
                        .font(.v2CaptionSmall)
                        .foregroundColor(.v2Mint)
                }
            }
        }
    }

    var totalSaved: Double {
        sampleGoals.reduce(0) { $0 + $1.currentAmount }
    }

    var totalTarget: Double {
        sampleGoals.reduce(0) { $0 + $1.targetAmount }
    }

    // MARK: - Active Goals

    var activeGoalsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            V2SectionHeader(title: "Active Goals")

            ForEach(activeGoals) { goal in
                Button {
                    selectedGoal = goal
                } label: {
                    GoalCardV2(goal: goal)
                }
            }
        }
    }

    var activeGoals: [GoalV2] {
        sampleGoals.filter { $0.currentAmount < $0.targetAmount }
    }

    // MARK: - Completed Goals

    var completedGoalsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            V2SectionHeader(title: "Completed")

            ForEach(completedGoals) { goal in
                GoalCardV2(goal: goal, isCompleted: true)
            }
        }
    }

    var completedGoals: [GoalV2] {
        sampleGoals.filter { $0.currentAmount >= $0.targetAmount }
    }

    // MARK: - Sample Data

    var sampleGoals: [GoalV2] {
        [
            GoalV2(
                name: "Emergency Fund",
                icon: "shield.fill",
                color: .v2Blue,
                targetAmount: 10000,
                currentAmount: 6500,
                monthlyContribution: 400,
                targetDate: Calendar.current.date(byAdding: .month, value: 9, to: Date())
            ),
            GoalV2(
                name: "Vacation",
                icon: "airplane",
                color: .v2CategoryTravel,
                targetAmount: 3000,
                currentAmount: 1200,
                monthlyContribution: 300,
                targetDate: Calendar.current.date(byAdding: .month, value: 6, to: Date())
            ),
            GoalV2(
                name: "New Laptop",
                icon: "laptopcomputer",
                color: .v2Purple,
                targetAmount: 2000,
                currentAmount: 850,
                monthlyContribution: 200,
                targetDate: Calendar.current.date(byAdding: .month, value: 6, to: Date())
            ),
            GoalV2(
                name: "Concert Tickets",
                icon: "music.note",
                color: .v2CategoryEntertainment,
                targetAmount: 500,
                currentAmount: 500,
                monthlyContribution: 100,
                targetDate: nil
            )
        ]
    }

    func formatNumber(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: value)) ?? "0"
    }
}

// MARK: - Goal Card

struct GoalCardV2: View {
    let goal: GoalV2
    var isCompleted: Bool = false

    var progress: Double { min(goal.currentAmount / goal.targetAmount, 1) }

    var body: some View {
        V2Card(padding: 16) {
            VStack(spacing: 14) {
                HStack(spacing: 14) {
                    // Icon
                    ZStack {
                        Circle()
                            .fill(goal.color.opacity(0.15))
                            .frame(width: 48, height: 48)

                        Image(systemName: goal.icon)
                            .font(.system(size: 20))
                            .foregroundColor(goal.color)
                    }

                    // Name and progress text
                    VStack(alignment: .leading, spacing: 4) {
                        Text(goal.name)
                            .font(.v2BodyBold)
                            .foregroundColor(.v2TextPrimary)

                        if isCompleted {
                            HStack(spacing: 4) {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.system(size: 12))
                                    .foregroundColor(.v2Lime)
                                Text("Completed!")
                                    .font(.v2CaptionSmall)
                                    .foregroundColor(.v2Lime)
                            }
                        } else {
                            Text("\(Int(progress * 100))% complete")
                                .font(.v2CaptionSmall)
                                .foregroundColor(.v2TextTertiary)
                        }
                    }

                    Spacer()

                    // Amount
                    VStack(alignment: .trailing, spacing: 4) {
                        Text("$\(Int(goal.currentAmount))")
                            .font(.v2BodyBold)
                            .foregroundColor(isCompleted ? .v2Lime : .v2TextPrimary)

                        Text("of $\(Int(goal.targetAmount))")
                            .font(.v2CaptionSmall)
                            .foregroundColor(.v2TextTertiary)
                    }
                }

                if !isCompleted {
                    // Progress bar
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color.white.opacity(0.1))

                            RoundedRectangle(cornerRadius: 4)
                                .fill(goal.color)
                                .frame(width: geo.size.width * progress)
                        }
                    }
                    .frame(height: 6)

                    // Footer
                    HStack {
                        if let targetDate = goal.targetDate {
                            let months = Calendar.current.dateComponents([.month], from: Date(), to: targetDate).month ?? 0
                            Text("\(months) months left")
                                .font(.v2CaptionSmall)
                                .foregroundColor(.v2TextTertiary)
                        }

                        Spacer()

                        Text("$\(Int(goal.monthlyContribution))/mo")
                            .font(.v2CaptionSmall)
                            .foregroundColor(.v2Mint)
                    }
                }
            }
        }
        .opacity(isCompleted ? 0.7 : 1)
    }
}

// MARK: - Goal Model

struct GoalV2: Identifiable {
    let id = UUID()
    let name: String
    let icon: String
    let color: Color
    let targetAmount: Double
    let currentAmount: Double
    let monthlyContribution: Double
    let targetDate: Date?
}

// MARK: - Goal Detail

struct GoalDetailV2: View {
    let goal: GoalV2
    @Environment(\.dismiss) var dismiss
    @State private var showAddMoney = false

    var progress: Double { min(goal.currentAmount / goal.targetAmount, 1) }
    var remaining: Double { goal.targetAmount - goal.currentAmount }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    VStack(spacing: 16) {
                        ZStack {
                            Circle()
                                .fill(goal.color.opacity(0.15))
                                .frame(width: 80, height: 80)

                            Image(systemName: goal.icon)
                                .font(.system(size: 36))
                                .foregroundColor(goal.color)
                        }

                        Text(goal.name)
                            .font(.v2Title)
                            .foregroundColor(.v2TextPrimary)
                    }
                    .padding(.top, 20)

                    // Progress ring
                    progressRingView

                    // Stats
                    statsCards

                    // Projection chart
                    projectionChart

                    // Actions
                    VStack(spacing: 12) {
                        Button {
                            showAddMoney = true
                        } label: {
                            HStack {
                                Image(systemName: "plus.circle.fill")
                                Text("Add Money")
                            }
                            .font(.v2BodyBold)
                            .foregroundColor(.v2Background)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(goal.color)
                            .cornerRadius(14)
                        }

                        Button {
                            // Edit goal
                        } label: {
                            Text("Edit Goal")
                                .font(.v2Body)
                                .foregroundColor(.v2TextSecondary)
                        }
                    }
                }
                .padding(20)
            }
            .background(Color.v2Background)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                        .foregroundColor(.v2Mint)
                }
            }
        }
    }

    var progressRingView: some View {
        ZStack {
            // Background ring
            Circle()
                .stroke(Color.white.opacity(0.1), lineWidth: 12)
                .frame(width: 160, height: 160)

            // Progress ring
            Circle()
                .trim(from: 0, to: progress)
                .stroke(goal.color, style: StrokeStyle(lineWidth: 12, lineCap: .round))
                .frame(width: 160, height: 160)
                .rotationEffect(.degrees(-90))

            // Center content
            VStack(spacing: 4) {
                Text("$\(Int(goal.currentAmount))")
                    .font(.v2DisplaySmall)
                    .foregroundColor(.v2TextPrimary)

                Text("of $\(Int(goal.targetAmount))")
                    .font(.v2Caption)
                    .foregroundColor(.v2TextSecondary)
            }
        }
    }

    var statsCards: some View {
        HStack(spacing: 12) {
            StatCardV2(
                label: "Remaining",
                value: "$\(Int(remaining))",
                color: .v2TextPrimary
            )

            StatCardV2(
                label: "Monthly",
                value: "$\(Int(goal.monthlyContribution))",
                color: .v2Mint
            )

            if let targetDate = goal.targetDate {
                let months = Calendar.current.dateComponents([.month], from: Date(), to: targetDate).month ?? 0
                StatCardV2(
                    label: "Months Left",
                    value: "\(months)",
                    color: .v2Blue
                )
            }
        }
    }

    var projectionChart: some View {
        V2Card {
            VStack(alignment: .leading, spacing: 12) {
                Text("Savings Projection")
                    .font(.v2Headline)
                    .foregroundColor(.v2TextPrimary)

                Chart {
                    // Projected line
                    ForEach(projectionData, id: \.month) { data in
                        LineMark(
                            x: .value("Month", data.month),
                            y: .value("Amount", data.projected)
                        )
                        .foregroundStyle(goal.color.opacity(0.5))
                        .lineStyle(StrokeStyle(lineWidth: 2, dash: [5, 5]))
                    }

                    // Actual line
                    ForEach(projectionData.filter { $0.actual != nil }, id: \.month) { data in
                        LineMark(
                            x: .value("Month", data.month),
                            y: .value("Amount", data.actual!)
                        )
                        .foregroundStyle(goal.color)
                        .lineStyle(StrokeStyle(lineWidth: 3))
                    }

                    // Target line
                    RuleMark(y: .value("Target", goal.targetAmount))
                        .foregroundStyle(Color.v2Lime.opacity(0.5))
                        .lineStyle(StrokeStyle(lineWidth: 1, dash: [4, 4]))
                }
                .chartYAxis {
                    AxisMarks(position: .leading) { value in
                        AxisValueLabel {
                            if let amount = value.as(Double.self) {
                                Text("$\(Int(amount / 1000))k")
                                    .font(.v2CaptionSmall)
                                    .foregroundColor(.v2TextTertiary)
                            }
                        }
                    }
                }
                .frame(height: 160)
            }
        }
    }

    var projectionData: [ProjectionPoint] {
        let months = ["Sep", "Oct", "Nov", "Dec", "Jan", "Feb", "Mar", "Apr", "May"]
        var current = goal.currentAmount - (goal.monthlyContribution * 3) // Start 3 months ago
        var projected = current

        return months.enumerated().map { index, month in
            let actual: Double? = index < 4 ? current : nil
            current += goal.monthlyContribution
            projected += goal.monthlyContribution
            return ProjectionPoint(month: month, actual: actual, projected: min(projected, goal.targetAmount))
        }
    }
}

struct ProjectionPoint {
    let month: String
    let actual: Double?
    let projected: Double
}

struct StatCardV2: View {
    let label: String
    let value: String
    let color: Color

    var body: some View {
        V2Card(padding: 12, cornerRadius: 12) {
            VStack(spacing: 4) {
                Text(value)
                    .font(.v2MetricMedium)
                    .foregroundColor(color)

                Text(label)
                    .font(.v2CaptionSmall)
                    .foregroundColor(.v2TextTertiary)
            }
            .frame(maxWidth: .infinity)
        }
    }
}

// MARK: - Add Goal Sheet

struct AddGoalSheetV2: View {
    @Environment(\.dismiss) var dismiss
    @State private var goalName = ""
    @State private var targetAmount = ""
    @State private var monthlyContribution = ""
    @State private var selectedIcon = "star.fill"
    @State private var selectedColor: Color = .v2Mint

    let iconOptions = ["star.fill", "house.fill", "car.fill", "airplane", "laptopcomputer", "gift.fill", "heart.fill", "graduationcap.fill"]
    let colorOptions: [Color] = [.v2Mint, .v2Blue, .v2Purple, .v2CategoryTravel, .v2Gold, .v2Coral]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Icon selector
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Choose an Icon")
                            .font(.v2Caption)
                            .foregroundColor(.v2TextSecondary)

                        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 4), spacing: 12) {
                            ForEach(iconOptions, id: \.self) { icon in
                                Button {
                                    selectedIcon = icon
                                } label: {
                                    ZStack {
                                        Circle()
                                            .fill(selectedIcon == icon ? selectedColor.opacity(0.2) : Color.v2CardBackground)
                                            .frame(width: 56, height: 56)

                                        Image(systemName: icon)
                                            .font(.system(size: 22))
                                            .foregroundColor(selectedIcon == icon ? selectedColor : .v2TextTertiary)
                                    }
                                }
                            }
                        }
                    }

                    // Color selector
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Choose a Color")
                            .font(.v2Caption)
                            .foregroundColor(.v2TextSecondary)

                        HStack(spacing: 12) {
                            ForEach(colorOptions, id: \.self) { color in
                                Button {
                                    selectedColor = color
                                } label: {
                                    Circle()
                                        .fill(color)
                                        .frame(width: 40, height: 40)
                                        .overlay(
                                            Circle()
                                                .stroke(Color.white, lineWidth: selectedColor == color ? 3 : 0)
                                        )
                                }
                            }
                        }
                    }

                    // Form fields
                    VStack(spacing: 16) {
                        FormFieldV2(label: "Goal Name", placeholder: "e.g., Emergency Fund", text: $goalName)
                        FormFieldV2(label: "Target Amount", placeholder: "$10,000", text: $targetAmount, keyboardType: .decimalPad)
                        FormFieldV2(label: "Monthly Contribution", placeholder: "$200", text: $monthlyContribution, keyboardType: .decimalPad)
                    }

                    Spacer(minLength: 40)

                    // Create button
                    Button {
                        dismiss()
                    } label: {
                        Text("Create Goal")
                            .font(.v2BodyBold)
                            .foregroundColor(.v2Background)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(goalName.isEmpty ? Color.v2TextTertiary : selectedColor)
                            .cornerRadius(14)
                    }
                    .disabled(goalName.isEmpty)
                }
                .padding(20)
            }
            .background(Color.v2Background)
            .navigationTitle("New Goal")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                        .foregroundColor(.v2TextSecondary)
                }
            }
        }
    }
}

struct FormFieldV2: View {
    let label: String
    let placeholder: String
    @Binding var text: String
    var keyboardType: UIKeyboardType = .default

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(label)
                .font(.v2Caption)
                .foregroundColor(.v2TextSecondary)

            TextField(placeholder, text: $text)
                .font(.v2Body)
                .foregroundColor(.v2TextPrimary)
                .keyboardType(keyboardType)
                .padding(14)
                .background(Color.v2CardBackground)
                .cornerRadius(12)
        }
    }
}

// MARK: - Preview

#Preview {
    GoalsV2()
}
