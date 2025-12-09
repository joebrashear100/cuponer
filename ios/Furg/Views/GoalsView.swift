//
//  GoalsView.swift
//  Furg
//
//  Savings goals tracking and management view
//

import SwiftUI

struct GoalsView: View {
    @StateObject private var goalsManager = GoalsManager()
    @State private var showAddSheet = false
    @State private var selectedGoal: FurgSavingsGoal?
    @State private var showContributeSheet = false
    @State private var animate = false

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 24) {
                // Header
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Your")
                            .font(.furgBody)
                            .foregroundColor(.white.opacity(0.6))
                        Text("Goals")
                            .font(.furgLargeTitle)
                            .foregroundColor(.white)
                    }
                    Spacer()
                    Button {
                        showAddSheet = true
                    } label: {
                        Image(systemName: "plus")
                            .font(.title3.weight(.semibold))
                            .foregroundColor(.furgCharcoal)
                            .padding(12)
                            .background(Color.furgMint)
                            .clipShape(Circle())
                    }
                }
                .padding(.top, 60)
                .offset(y: animate ? 0 : -20)
                .opacity(animate ? 1 : 0)
                .animation(.easeOut(duration: 0.5), value: animate)

                // Overall Progress
                OverallProgressCard(
                    totalSaved: goalsManager.totalSaved,
                    totalTarget: goalsManager.totalTarget,
                    progress: goalsManager.overallProgress,
                    goalCount: goalsManager.activeGoals.count
                )
                .offset(y: animate ? 0 : 20)
                .opacity(animate ? 1 : 0)
                .animation(.easeOut(duration: 0.5).delay(0.1), value: animate)

                // Primary Goal Highlight
                if let primaryGoal = goalsManager.primaryGoal {
                    PrimaryGoalCard(
                        goal: primaryGoal,
                        onContribute: {
                            selectedGoal = primaryGoal
                            showContributeSheet = true
                        }
                    )
                    .offset(y: animate ? 0 : 20)
                    .opacity(animate ? 1 : 0)
                    .animation(.easeOut(duration: 0.5).delay(0.15), value: animate)
                }

                // Goals List
                if goalsManager.isLoading {
                    ProgressView()
                        .tint(.furgMint)
                        .padding(40)
                } else if goalsManager.activeGoals.isEmpty {
                    EmptyGoalsState()
                        .offset(y: animate ? 0 : 20)
                        .opacity(animate ? 1 : 0)
                        .animation(.easeOut(duration: 0.5).delay(0.2), value: animate)
                } else {
                    VStack(alignment: .leading, spacing: 16) {
                        if goalsManager.activeGoals.count > 1 {
                            Text("ALL GOALS")
                                .font(.furgCaption)
                                .foregroundColor(.white.opacity(0.5))
                                .tracking(2)
                                .padding(.top, 8)
                        }

                        ForEach(Array(goalsManager.activeGoals.enumerated()), id: \.element.id) { index, goal in
                            GoalCard(
                                goal: goal,
                                progress: nil, // Will be calculated
                                onTap: { selectedGoal = goal },
                                onContribute: {
                                    selectedGoal = goal
                                    showContributeSheet = true
                                }
                            )
                            .offset(y: animate ? 0 : 20)
                            .opacity(animate ? 1 : 0)
                            .animation(.easeOut(duration: 0.4).delay(0.2 + Double(index) * 0.05), value: animate)
                        }
                    }
                }

                // Achieved Goals
                if !goalsManager.achievedGoals.isEmpty {
                    VStack(alignment: .leading, spacing: 16) {
                        Text("ACHIEVED")
                            .font(.furgCaption)
                            .foregroundColor(.white.opacity(0.5))
                            .tracking(2)
                            .padding(.top, 8)

                        ForEach(goalsManager.achievedGoals) { goal in
                            AchievedGoalCard(goal: goal)
                        }
                    }
                }

                Spacer(minLength: 120)
            }
            .padding(.horizontal, 20)
        }
        .refreshable {
            await goalsManager.loadGoals()
        }
        .task {
            await goalsManager.loadGoals()
        }
        .onAppear {
            withAnimation { animate = true }
        }
        .sheet(isPresented: $showAddSheet) {
            CreateGoalSheet(goalsManager: goalsManager)
        }
        .sheet(isPresented: $showContributeSheet) {
            if let goal = selectedGoal {
                ContributeSheet(goal: goal, goalsManager: goalsManager)
            }
        }
        .sheet(item: $selectedGoal) { goal in
            GoalDetailSheet(goal: goal, goalsManager: goalsManager)
        }
    }
}

// MARK: - Overall Progress Card

struct OverallProgressCard: View {
    let totalSaved: Decimal
    let totalTarget: Decimal
    let progress: Float
    let goalCount: Int

    var body: some View {
        VStack(spacing: 20) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("TOTAL SAVED")
                        .font(.furgCaption)
                        .foregroundColor(.white.opacity(0.5))
                        .tracking(2)

                    Text(formatCurrency(totalSaved))
                        .font(.system(size: 36, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                }

                Spacer()

                ZStack {
                    Circle()
                        .stroke(Color.white.opacity(0.1), lineWidth: 8)
                        .frame(width: 80, height: 80)

                    Circle()
                        .trim(from: 0, to: CGFloat(progress / 100))
                        .stroke(
                            LinearGradient(colors: [.furgMint, .furgSeafoam], startPoint: .topLeading, endPoint: .bottomTrailing),
                            style: StrokeStyle(lineWidth: 8, lineCap: .round)
                        )
                        .frame(width: 80, height: 80)
                        .rotationEffect(.degrees(-90))

                    Text("\(Int(progress))%")
                        .font(.furgHeadline)
                        .foregroundColor(.furgMint)
                }
            }

            HStack {
                Label("\(goalCount) active goal\(goalCount == 1 ? "" : "s")", systemImage: "target")
                    .font(.furgCaption)
                    .foregroundColor(.white.opacity(0.5))

                Spacer()

                Text("of \(formatCurrency(totalTarget))")
                    .font(.furgCaption)
                    .foregroundColor(.white.opacity(0.5))
            }
        }
        .padding(24)
        .copilotCard()
    }

    private func formatCurrency(_ value: Decimal) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.maximumFractionDigits = 0
        return formatter.string(from: value as NSNumber) ?? "$\(value)"
    }
}

// MARK: - Primary Goal Card

struct PrimaryGoalCard: View {
    let goal: FurgSavingsGoal
    let onContribute: () -> Void

    var body: some View {
        VStack(spacing: 20) {
            // Header
            HStack {
                ZStack {
                    Circle()
                        .fill(goal.displayColor.opacity(0.2))
                        .frame(width: 56, height: 56)

                    Image(systemName: goal.icon)
                        .font(.title2)
                        .foregroundColor(goal.displayColor)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text("PRIMARY GOAL")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(.furgMint)
                        .tracking(1)

                    Text(goal.name)
                        .font(.furgTitle2)
                        .foregroundColor(.white)
                }

                Spacer()
            }

            // Progress
            VStack(spacing: 12) {
                HStack {
                    Text(goal.formattedCurrent)
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundColor(.white)

                    Text("of \(goal.formattedTarget)")
                        .font(.furgBody)
                        .foregroundColor(.white.opacity(0.5))

                    Spacer()

                    Text("\(Int(goal.percentComplete))%")
                        .font(.furgHeadline)
                        .foregroundColor(.furgMint)
                }

                // Progress Bar
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 6)
                            .fill(Color.white.opacity(0.1))
                            .frame(height: 12)

                        RoundedRectangle(cornerRadius: 6)
                            .fill(
                                LinearGradient(colors: [.furgMint, .furgSeafoam], startPoint: .leading, endPoint: .trailing)
                            )
                            .frame(width: geometry.size.width * CGFloat(goal.percentComplete / 100), height: 12)
                    }
                }
                .frame(height: 12)
            }

            // Deadline & Action
            HStack {
                if let deadline = goal.deadline {
                    HStack(spacing: 6) {
                        Image(systemName: "calendar")
                            .font(.caption)
                        Text("Due \(deadline, style: .date)")
                            .font(.furgCaption)
                    }
                    .foregroundColor(.white.opacity(0.5))
                }

                Spacer()

                Button(action: onContribute) {
                    HStack(spacing: 6) {
                        Image(systemName: "plus.circle")
                        Text("Add Funds")
                    }
                    .font(.furgCaption.weight(.semibold))
                    .foregroundColor(.furgCharcoal)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(Color.furgMint)
                    .clipShape(Capsule())
                }
            }
        }
        .padding(24)
        .copilotCard()
        .overlay(
            RoundedRectangle(cornerRadius: 24)
                .stroke(
                    LinearGradient(colors: [.furgMint.opacity(0.5), .furgMint.opacity(0.1)], startPoint: .topLeading, endPoint: .bottomTrailing),
                    lineWidth: 1
                )
        )
    }
}

// MARK: - Goal Card

struct GoalCard: View {
    let goal: FurgSavingsGoal
    let progress: GoalProgress?
    let onTap: () -> Void
    let onContribute: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 16) {
                // Icon
                ZStack {
                    Circle()
                        .fill(goal.displayColor.opacity(0.2))
                        .frame(width: 48, height: 48)

                    Image(systemName: goal.icon)
                        .font(.title3)
                        .foregroundColor(goal.displayColor)
                }

                // Info
                VStack(alignment: .leading, spacing: 6) {
                    Text(goal.name)
                        .font(.furgHeadline)
                        .foregroundColor(.white)

                    // Progress bar
                    GeometryReader { geometry in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 3)
                                .fill(Color.white.opacity(0.1))
                                .frame(height: 6)

                            RoundedRectangle(cornerRadius: 3)
                                .fill(goal.displayColor)
                                .frame(width: geometry.size.width * CGFloat(goal.percentComplete / 100), height: 6)
                        }
                    }
                    .frame(height: 6)

                    Text("\(goal.formattedCurrent) of \(goal.formattedTarget)")
                        .font(.furgCaption)
                        .foregroundColor(.white.opacity(0.5))
                }

                Spacer()

                // Percentage
                VStack(alignment: .trailing, spacing: 4) {
                    Text("\(Int(goal.percentComplete))%")
                        .font(.furgTitle2)
                        .foregroundColor(goal.displayColor)

                    if let deadline = goal.deadline {
                        let days = Calendar.current.dateComponents([.day], from: Date(), to: deadline).day ?? 0
                        Text("\(days)d left")
                            .font(.furgCaption)
                            .foregroundColor(.white.opacity(0.4))
                    }
                }
            }
            .padding(20)
            .copilotCard(cornerRadius: 20, opacity: 0.08)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Achieved Goal Card

struct AchievedGoalCard: View {
    let goal: FurgSavingsGoal

    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(Color.furgSuccess.opacity(0.2))
                    .frame(width: 48, height: 48)

                Image(systemName: "checkmark")
                    .font(.title3.weight(.semibold))
                    .foregroundColor(.furgSuccess)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(goal.name)
                    .font(.furgHeadline)
                    .foregroundColor(.white.opacity(0.7))
                    .strikethrough(color: .white.opacity(0.3))

                Text("Achieved \(goal.achievedAt ?? Date(), style: .date)")
                    .font(.furgCaption)
                    .foregroundColor(.furgSuccess)
            }

            Spacer()

            Text(goal.formattedTarget)
                .font(.furgHeadline)
                .foregroundColor(.furgSuccess)
        }
        .padding(16)
        .copilotCard(cornerRadius: 16, opacity: 0.05)
    }
}

// MARK: - Empty State

struct EmptyGoalsState: View {
    var body: some View {
        VStack(spacing: 20) {
            ZStack {
                Circle()
                    .fill(Color.furgMint.opacity(0.1))
                    .frame(width: 100, height: 100)

                Image(systemName: "target")
                    .font(.system(size: 40))
                    .foregroundColor(.furgMint.opacity(0.5))
            }

            VStack(spacing: 8) {
                Text("No Goals Yet")
                    .font(.furgHeadline)
                    .foregroundColor(.white.opacity(0.8))

                Text("Create your first savings goal\nand start tracking your progress")
                    .font(.furgBody)
                    .foregroundColor(.white.opacity(0.4))
                    .multilineTextAlignment(.center)
            }
        }
        .padding(40)
        .frame(maxWidth: .infinity)
        .copilotCard()
    }
}

// MARK: - Create Goal Sheet

struct CreateGoalSheet: View {
    @Environment(\.dismiss) var dismiss
    let goalsManager: GoalsManager

    @State private var name = ""
    @State private var targetAmount = ""
    @State private var hasDeadline = false
    @State private var deadline = Date().addingTimeInterval(86400 * 180) // 6 months
    @State private var category: GoalCategory = .custom
    @State private var autoContribute = false
    @State private var contributeAmount = ""
    @State private var contributeFrequency: RecurringFrequency = .monthly
    @State private var isCreating = false

    var body: some View {
        ZStack {
            CopilotBackground()

            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    HStack {
                        Button { dismiss() } label: {
                            Image(systemName: "xmark")
                                .font(.title3)
                                .foregroundColor(.white.opacity(0.7))
                                .padding(12)
                                .copilotCard(cornerRadius: 12, opacity: 0.1)
                        }
                        Spacer()
                        Text("New Goal")
                            .font(.furgTitle2)
                            .foregroundColor(.white)
                        Spacer()
                        Color.clear.frame(width: 44)
                    }
                    .padding(.top, 20)

                    // Category Selection
                    VStack(alignment: .leading, spacing: 12) {
                        Text("CATEGORY")
                            .font(.furgCaption)
                            .foregroundColor(.white.opacity(0.5))
                            .tracking(2)

                        LazyVGrid(columns: [GridItem(.adaptive(minimum: 100))], spacing: 10) {
                            ForEach(GoalCategory.allCases, id: \.self) { cat in
                                GoalCategoryChip(category: cat, isSelected: category == cat) {
                                    category = cat
                                    if name.isEmpty {
                                        name = cat.label
                                    }
                                }
                            }
                        }
                    }

                    // Name
                    VStack(alignment: .leading, spacing: 8) {
                        Text("NAME")
                            .font(.furgCaption)
                            .foregroundColor(.white.opacity(0.5))
                            .tracking(2)

                        TextField("What are you saving for?", text: $name)
                            .font(.furgBody)
                            .foregroundColor(.white)
                            .padding(16)
                            .copilotCard(cornerRadius: 14, opacity: 0.1)
                    }

                    // Amount
                    VStack(alignment: .leading, spacing: 8) {
                        Text("TARGET AMOUNT")
                            .font(.furgCaption)
                            .foregroundColor(.white.opacity(0.5))
                            .tracking(2)

                        HStack {
                            Text("$")
                                .font(.furgTitle2)
                                .foregroundColor(.furgMint)

                            TextField("0", text: $targetAmount)
                                .font(.furgTitle2)
                                .foregroundColor(.white)
                                .keyboardType(.decimalPad)
                        }
                        .padding(16)
                        .copilotCard(cornerRadius: 14, opacity: 0.1)
                    }

                    // Deadline Toggle
                    VStack(alignment: .leading, spacing: 12) {
                        Toggle(isOn: $hasDeadline) {
                            Text("Set a deadline")
                                .font(.furgBody)
                                .foregroundColor(.white)
                        }
                        .tint(.furgMint)

                        if hasDeadline {
                            DatePicker("Deadline", selection: $deadline, in: Date()..., displayedComponents: .date)
                                .datePickerStyle(.graphical)
                                .tint(.furgMint)
                                .colorScheme(.dark)
                                .padding(16)
                                .copilotCard(cornerRadius: 14, opacity: 0.1)
                        }
                    }
                    .padding(16)
                    .copilotCard(cornerRadius: 14, opacity: 0.1)

                    // Auto-contribute Toggle
                    VStack(alignment: .leading, spacing: 12) {
                        Toggle(isOn: $autoContribute) {
                            Text("Auto-contribute")
                                .font(.furgBody)
                                .foregroundColor(.white)
                        }
                        .tint(.furgMint)

                        if autoContribute {
                            HStack {
                                Text("$")
                                    .font(.furgHeadline)
                                    .foregroundColor(.furgMint)

                                TextField("0", text: $contributeAmount)
                                    .font(.furgHeadline)
                                    .foregroundColor(.white)
                                    .keyboardType(.decimalPad)
                                    .frame(width: 80)

                                Picker("", selection: $contributeFrequency) {
                                    ForEach(RecurringFrequency.allCases, id: \.self) { freq in
                                        Text(freq.label).tag(freq)
                                    }
                                }
                                .pickerStyle(.menu)
                                .tint(.furgMint)
                            }
                            .padding(12)
                            .copilotCard(cornerRadius: 12, opacity: 0.08)
                        }
                    }
                    .padding(16)
                    .copilotCard(cornerRadius: 14, opacity: 0.1)

                    Spacer(minLength: 20)

                    // Create Button
                    Button {
                        createGoal()
                    } label: {
                        HStack {
                            if isCreating {
                                ProgressView().tint(.furgCharcoal)
                            } else {
                                Image(systemName: "plus.circle.fill")
                                Text("Create Goal")
                            }
                        }
                        .font(.furgHeadline)
                        .foregroundColor(.furgCharcoal)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 18)
                        .background(
                            Group {
                                if name.isEmpty || targetAmount.isEmpty {
                                    Color.white.opacity(0.2)
                                } else {
                                    FurgGradients.mintGradient
                                }
                            }
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                    }
                    .disabled(name.isEmpty || targetAmount.isEmpty || isCreating)
                    .padding(.bottom, 20)
                }
                .padding(.horizontal, 20)
            }
        }
    }

    private func createGoal() {
        guard let amount = Decimal(string: targetAmount), amount > 0 else { return }

        isCreating = true

        let goal = FurgSavingsGoal(
            id: UUID().uuidString,
            name: name,
            targetAmount: amount,
            currentAmount: 0,
            deadline: hasDeadline ? deadline : nil,
            priority: goalsManager.goals.count + 1,
            category: category,
            icon: category.icon,
            color: category.suggestedColor,
            linkedAccountIds: [],
            autoContribute: autoContribute,
            autoContributeAmount: autoContribute ? Decimal(string: contributeAmount) : nil,
            autoContributeFrequency: autoContribute ? contributeFrequency : nil,
            createdAt: Date(),
            achievedAt: nil
        )

        Task {
            let success = await goalsManager.createGoal(goal)
            isCreating = false
            if success {
                dismiss()
            }
        }
    }
}

// MARK: - Goal Category Chip

struct GoalCategoryChip: View {
    let category: GoalCategory
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: category.icon)
                    .font(.caption)
                Text(category.label)
                    .font(.furgCaption)
            }
            .foregroundColor(isSelected ? .furgCharcoal : .white.opacity(0.6))
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(isSelected ? Color.furgMint : Color.white.opacity(0.08))
            .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Contribute Sheet

struct ContributeSheet: View {
    @Environment(\.dismiss) var dismiss
    let goal: FurgSavingsGoal
    let goalsManager: GoalsManager

    @State private var amount = ""
    @State private var note = ""
    @State private var isContributing = false

    var body: some View {
        ZStack {
            CopilotBackground()

            VStack(spacing: 24) {
                // Header
                HStack {
                    Button { dismiss() } label: {
                        Image(systemName: "xmark")
                            .font(.title3)
                            .foregroundColor(.white.opacity(0.7))
                            .padding(12)
                            .copilotCard(cornerRadius: 12, opacity: 0.1)
                    }
                    Spacer()
                    Text("Add Funds")
                        .font(.furgTitle2)
                        .foregroundColor(.white)
                    Spacer()
                    Color.clear.frame(width: 44)
                }
                .padding(.top, 20)

                Spacer()

                // Goal Info
                VStack(spacing: 8) {
                    Image(systemName: goal.icon)
                        .font(.system(size: 40))
                        .foregroundColor(goal.displayColor)

                    Text(goal.name)
                        .font(.furgTitle2)
                        .foregroundColor(.white)

                    Text("\(goal.formattedRemaining) remaining")
                        .font(.furgBody)
                        .foregroundColor(.white.opacity(0.5))
                }

                // Amount Input
                VStack(spacing: 12) {
                    Text("AMOUNT")
                        .font(.furgCaption)
                        .foregroundColor(.white.opacity(0.5))
                        .tracking(2)

                    HStack(alignment: .center, spacing: 4) {
                        Text("$")
                            .font(.system(size: 40, weight: .medium, design: .rounded))
                            .foregroundColor(.furgMint)

                        TextField("0", text: $amount)
                            .font(.system(size: 56, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.center)
                            .frame(maxWidth: 200)
                    }
                }
                .padding(32)
                .copilotCard()

                // Note
                TextField("Add a note (optional)", text: $note)
                    .font(.furgBody)
                    .foregroundColor(.white)
                    .padding(16)
                    .copilotCard(cornerRadius: 14, opacity: 0.1)

                Spacer()

                // Contribute Button
                Button {
                    contribute()
                } label: {
                    HStack {
                        if isContributing {
                            ProgressView().tint(.furgCharcoal)
                        } else {
                            Image(systemName: "plus.circle.fill")
                            Text("Add to Goal")
                        }
                    }
                    .font(.furgHeadline)
                    .foregroundColor(.furgCharcoal)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 18)
                    .background(
                        Group {
                            if amount.isEmpty {
                                Color.white.opacity(0.2)
                            } else {
                                FurgGradients.mintGradient
                            }
                        }
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                }
                .disabled(amount.isEmpty || isContributing)
                .padding(.bottom, 20)
            }
            .padding(.horizontal, 20)
        }
    }

    private func contribute() {
        guard let amountValue = Decimal(string: amount), amountValue > 0 else { return }

        isContributing = true

        Task {
            let success = await goalsManager.contributeToGoal(goal.id, amount: amountValue, note: note.isEmpty ? nil : note)
            isContributing = false
            if success {
                dismiss()
            }
        }
    }
}

// MARK: - Goal Detail Sheet

struct GoalDetailSheet: View {
    @Environment(\.dismiss) var dismiss
    let goal: FurgSavingsGoal
    let goalsManager: GoalsManager

    @State private var progress: GoalProgress?
    @State private var milestones: [GoalMilestone] = []
    @State private var showDeleteConfirm = false

    var body: some View {
        ZStack {
            CopilotBackground()

            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    HStack {
                        Button { dismiss() } label: {
                            Image(systemName: "xmark")
                                .font(.title3)
                                .foregroundColor(.white.opacity(0.7))
                                .padding(12)
                                .copilotCard(cornerRadius: 12, opacity: 0.1)
                        }
                        Spacer()
                        Text(goal.name)
                            .font(.furgTitle2)
                            .foregroundColor(.white)
                        Spacer()
                        Button { showDeleteConfirm = true } label: {
                            Image(systemName: "trash")
                                .font(.title3)
                                .foregroundColor(.furgDanger)
                                .padding(12)
                                .copilotCard(cornerRadius: 12, opacity: 0.1)
                        }
                    }
                    .padding(.top, 20)

                    // Progress Ring
                    VStack(spacing: 16) {
                        ZStack {
                            Circle()
                                .stroke(Color.white.opacity(0.1), lineWidth: 16)
                                .frame(width: 180, height: 180)

                            Circle()
                                .trim(from: 0, to: CGFloat(goal.percentComplete / 100))
                                .stroke(
                                    LinearGradient(colors: [goal.displayColor, goal.displayColor.opacity(0.5)], startPoint: .topLeading, endPoint: .bottomTrailing),
                                    style: StrokeStyle(lineWidth: 16, lineCap: .round)
                                )
                                .frame(width: 180, height: 180)
                                .rotationEffect(.degrees(-90))

                            VStack(spacing: 4) {
                                Text("\(Int(goal.percentComplete))%")
                                    .font(.system(size: 44, weight: .bold, design: .rounded))
                                    .foregroundColor(.white)

                                Text("complete")
                                    .font(.furgCaption)
                                    .foregroundColor(.white.opacity(0.5))
                            }
                        }

                        Text("\(goal.formattedCurrent) of \(goal.formattedTarget)")
                            .font(.furgHeadline)
                            .foregroundColor(.furgMint)
                    }
                    .padding(32)
                    .copilotCard()

                    // Progress Details
                    if let progress = progress {
                        VStack(spacing: 16) {
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Remaining")
                                        .font(.furgCaption)
                                        .foregroundColor(.white.opacity(0.5))
                                    Text(goal.formattedRemaining)
                                        .font(.furgTitle2)
                                        .foregroundColor(.white)
                                }

                                Spacer()

                                VStack(alignment: .trailing, spacing: 4) {
                                    Text("Status")
                                        .font(.furgCaption)
                                        .foregroundColor(.white.opacity(0.5))
                                    HStack(spacing: 6) {
                                        Circle()
                                            .fill(statusColor(progress.status))
                                            .frame(width: 8, height: 8)
                                        Text(statusLabel(progress.status))
                                            .font(.furgHeadline)
                                            .foregroundColor(statusColor(progress.status))
                                    }
                                }
                            }

                            Divider().background(Color.white.opacity(0.1))

                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Required/mo")
                                        .font(.furgCaption)
                                        .foregroundColor(.white.opacity(0.5))
                                    Text(progress.formattedRequired)
                                        .font(.furgHeadline)
                                        .foregroundColor(.white)
                                }

                                Spacer()

                                VStack(alignment: .trailing, spacing: 4) {
                                    Text("Current/mo")
                                        .font(.furgCaption)
                                        .foregroundColor(.white.opacity(0.5))
                                    Text(progress.formattedCurrent)
                                        .font(.furgHeadline)
                                        .foregroundColor(progress.onTrack ? .furgSuccess : .furgWarning)
                                }
                            }
                        }
                        .padding(20)
                        .copilotCard()
                    }

                    // Milestones
                    if !milestones.isEmpty {
                        VStack(alignment: .leading, spacing: 16) {
                            Text("MILESTONES")
                                .font(.furgCaption)
                                .foregroundColor(.white.opacity(0.5))
                                .tracking(2)

                            ForEach(milestones) { milestone in
                                HStack(spacing: 12) {
                                    ZStack {
                                        Circle()
                                            .fill(milestone.isReached ? Color.furgSuccess : Color.white.opacity(0.1))
                                            .frame(width: 32, height: 32)

                                        if milestone.isReached {
                                            Image(systemName: "checkmark")
                                                .font(.caption.weight(.bold))
                                                .foregroundColor(.white)
                                        } else {
                                            Text("\(milestone.percentage)%")
                                                .font(.system(size: 10, weight: .bold))
                                                .foregroundColor(.white.opacity(0.5))
                                        }
                                    }

                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(milestone.message)
                                            .font(.furgCaption)
                                            .foregroundColor(milestone.isReached ? .white : .white.opacity(0.5))

                                        if milestone.isReached, let date = milestone.reachedAt {
                                            Text(date, style: .date)
                                                .font(.system(size: 10))
                                                .foregroundColor(.furgSuccess)
                                        }
                                    }

                                    Spacer()
                                }
                            }
                        }
                        .padding(20)
                        .copilotCard()
                    }

                    Spacer(minLength: 40)
                }
                .padding(.horizontal, 20)
            }
        }
        .task {
            progress = await goalsManager.getProgress(for: goal.id)
            milestones = goalsManager.getMilestones(for: goal.id)
        }
        .alert("Delete Goal", isPresented: $showDeleteConfirm) {
            Button("Delete", role: .destructive) {
                Task {
                    _ = await goalsManager.deleteGoal(goal.id)
                    dismiss()
                }
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("Are you sure you want to delete \"\(goal.name)\"? This cannot be undone.")
        }
    }

    private func statusColor(_ status: GoalStatus) -> Color {
        switch status {
        case .onTrack, .ahead: return .furgSuccess
        case .behind: return .furgWarning
        case .atRisk: return .furgDanger
        case .achieved: return .furgMint
        }
    }

    private func statusLabel(_ status: GoalStatus) -> String {
        switch status {
        case .onTrack: return "On Track"
        case .ahead: return "Ahead"
        case .behind: return "Behind"
        case .atRisk: return "At Risk"
        case .achieved: return "Achieved"
        }
    }
}

#Preview {
    ZStack {
        CopilotBackground()
        GoalsView()
    }
}
