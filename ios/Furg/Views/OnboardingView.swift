//
//  OnboardingView.swift
//  Furg
//
//  Multi-step onboarding flow for new users
//

import SwiftUI

struct OnboardingView: View {
    @EnvironmentObject var authManager: AuthManager
    @EnvironmentObject var financeManager: FinanceManager
    @EnvironmentObject var goalsManager: GoalsManager

    @State private var currentStep = 0
    @State private var name = ""
    @State private var salary: String = ""
    @State private var goalAmount: String = ""
    @State private var goalPurpose = ""
    @State private var goalDeadline = Date().addingTimeInterval(365 * 24 * 60 * 60) // 1 year from now
    @State private var intensityMode = "moderate"
    @State private var isCompleting = false

    let totalSteps = 5

    var body: some View {
        ZStack {
            CopilotBackground()

            VStack(spacing: 0) {
                // Progress bar
                ProgressBar(current: currentStep, total: totalSteps)
                    .padding(.horizontal, 24)
                    .padding(.top, 20)
                    .padding(.bottom, 16)

                // Content - with maximum height to keep nav visible
                TabView(selection: $currentStep) {
                    WelcomeStep(name: $name)
                        .tag(0)

                    IncomeStep(salary: $salary)
                        .tag(1)

                    GoalStep(
                        goalAmount: $goalAmount,
                        goalPurpose: $goalPurpose,
                        goalDeadline: $goalDeadline
                    )
                        .tag(2)

                    IntensityStep(intensityMode: $intensityMode)
                        .tag(3)

                    ConnectBankStep()
                        .tag(4)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .animation(.easeInOut, value: currentStep)

                Spacer(minLength: 20)

                // Navigation buttons - always visible
                VStack(spacing: 16) {
                    HStack(spacing: 16) {
                        if currentStep > 0 {
                            Button {
                                withAnimation {
                                    currentStep -= 1
                                }
                            } label: {
                                HStack {
                                    Image(systemName: "chevron.left")
                                    Text("Back")
                                }
                                .font(.furgHeadline)
                                .foregroundColor(.white.opacity(0.7))
                            }
                            .copilotSecondaryButton()
                        }

                        Spacer()

                        if currentStep < totalSteps - 1 {
                            Button {
                                withAnimation {
                                    currentStep += 1
                                }
                            } label: {
                                HStack {
                                    Text(currentStep == 0 && name.isEmpty ? "Skip" : "Continue")
                                    Image(systemName: "chevron.right")
                                }
                                .font(.furgHeadline)
                                .foregroundColor(.furgDarkBg)
                            }
                            .copilotPrimaryButton()
                        } else {
                            Button {
                                completeOnboarding()
                            } label: {
                                if isCompleting {
                                    ProgressView()
                                        .tint(.furgDarkBg)
                                } else {
                                    HStack {
                                        Text("Get Started")
                                        Image(systemName: "sparkles")
                                    }
                                    .font(.furgHeadline)
                                    .foregroundColor(.furgDarkBg)
                                }
                            }
                            .copilotPrimaryButton()
                            .disabled(isCompleting)
                        }
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 40)
            }
        }
    }

    private func completeOnboarding() {
        isCompleting = true

        Task {
            // Save user profile
            var profile: [String: Any] = [
                "intensity_mode": intensityMode
            ]

            if !name.isEmpty {
                profile["name"] = name
            }

            if let salaryValue = Double(salary.replacingOccurrences(of: ",", with: "")) {
                profile["salary"] = salaryValue
            }

            if let goalValue = Double(goalAmount.replacingOccurrences(of: ",", with: "")), !goalPurpose.isEmpty {
                profile["savings_goal"] = [
                    "amount": goalValue,
                    "purpose": goalPurpose,
                    "deadline": ISO8601DateFormatter().string(from: goalDeadline)
                ]

                // Create the goal in goals manager
                let newGoal = FurgSavingsGoal(
                    id: UUID().uuidString,
                    name: goalPurpose,
                    targetAmount: Decimal(goalValue),
                    currentAmount: 0,
                    deadline: goalDeadline,
                    priority: 1,
                    category: .custom,
                    icon: "flag.fill",
                    color: "mint",
                    linkedAccountIds: [],
                    autoContribute: false,
                    autoContributeAmount: nil,
                    autoContributeFrequency: nil,
                    createdAt: Date(),
                    achievedAt: nil
                )
                _ = await goalsManager.createGoal(newGoal)
            }

            // Mark onboarding complete
            authManager.completeOnboarding()

            isCompleting = false
        }
    }
}

// MARK: - Progress Bar

struct ProgressBar: View {
    let current: Int
    let total: Int

    var body: some View {
        HStack(spacing: 8) {
            ForEach(0..<total, id: \.self) { index in
                Capsule()
                    .fill(index <= current ? Color.furgMint : Color.white.opacity(0.2))
                    .frame(height: 4)
            }
        }
    }
}

// MARK: - Step 1: Welcome

struct WelcomeStep: View {
    @Binding var name: String

    var body: some View {
        VStack(spacing: 32) {
            Spacer()

            VStack(spacing: 16) {
                Image(systemName: "hand.wave.fill")
                    .font(.system(size: 60))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.furgMint, .furgSeafoam],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )

                Text("Welcome to FURG")
                    .font(.furgLargeTitle)
                    .foregroundColor(.white)

                Text("Your brutally honest financial AI.\nLet's get to know you.")
                    .font(.furgBody)
                    .foregroundColor(.white.opacity(0.6))
                    .multilineTextAlignment(.center)
            }

            CopilotCard(padding: 24) {
                VStack(alignment: .leading, spacing: 12) {
                    Text("What should I call you?")
                        .font(.furgHeadline)
                        .foregroundColor(.white)

                    TextField("Your name", text: $name)
                        .font(.furgBody)
                        .foregroundColor(.white)
                        .padding()
                        .background(Color.white.opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.white.opacity(0.2), lineWidth: 1)
                        )
                }
            }
            .padding(.horizontal, 24)

            Spacer()
            Spacer()
        }
    }
}

// MARK: - Step 2: Income

struct IncomeStep: View {
    @Binding var salary: String

    var body: some View {
        VStack(spacing: 32) {
            Spacer()

            VStack(spacing: 16) {
                Image(systemName: "dollarsign.circle.fill")
                    .font(.system(size: 60))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.furgMint, .furgSeafoam],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )

                Text("Your Income")
                    .font(.furgLargeTitle)
                    .foregroundColor(.white)

                Text("This helps me give you\nrealistic advice.")
                    .font(.furgBody)
                    .foregroundColor(.white.opacity(0.6))
                    .multilineTextAlignment(.center)
            }

            CopilotCard(padding: 24) {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Annual salary (before taxes)")
                        .font(.furgHeadline)
                        .foregroundColor(.white)

                    HStack {
                        Text("$")
                            .font(.furgTitle2)
                            .foregroundColor(.white.opacity(0.5))

                        TextField("120,000", text: $salary)
                            .font(.furgTitle2)
                            .foregroundColor(.white)
                            .keyboardType(.numberPad)
                    }
                    .padding()
                    .background(Color.white.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.white.opacity(0.2), lineWidth: 1)
                    )

                    Text("Optional - skip if you prefer")
                        .font(.furgCaption)
                        .foregroundColor(.white.opacity(0.4))
                }
            }
            .padding(.horizontal, 24)

            Spacer()
            Spacer()
        }
    }
}

// MARK: - Step 3: Goal

struct GoalStep: View {
    @Binding var goalAmount: String
    @Binding var goalPurpose: String
    @Binding var goalDeadline: Date

    let purposes = [
        "House down payment",
        "Emergency fund",
        "New car",
        "Wedding",
        "Vacation",
        "Debt payoff",
        "Investment",
        "Other"
    ]

    var body: some View {
        ScrollView {
            VStack(spacing: 32) {
                VStack(spacing: 16) {
                    Image(systemName: "flag.fill")
                        .font(.system(size: 60))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.furgMint, .furgSeafoam],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )

                    Text("Your Main Goal")
                        .font(.furgLargeTitle)
                        .foregroundColor(.white)

                    Text("What are you saving for?\nI'll roast you if you slack.")
                        .font(.furgBody)
                        .foregroundColor(.white.opacity(0.6))
                        .multilineTextAlignment(.center)
                }
                .padding(.top, 40)

                CopilotCard(padding: 24) {
                    VStack(spacing: 20) {
                        // Goal purpose
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Saving for")
                                .font(.furgHeadline)
                                .foregroundColor(.white)

                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 8) {
                                    ForEach(purposes, id: \.self) { purpose in
                                        Button {
                                            goalPurpose = purpose
                                        } label: {
                                            Text(purpose)
                                                .font(.furgCaption)
                                                .foregroundColor(goalPurpose == purpose ? .furgDarkBg : .white)
                                                .padding(.horizontal, 16)
                                                .padding(.vertical, 10)
                                                .background(
                                                    goalPurpose == purpose ?
                                                    Color.furgMint :
                                                    Color.white.opacity(0.1)
                                                )
                                                .clipShape(Capsule())
                                        }
                                    }
                                }
                            }
                        }

                        // Goal amount
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Target amount")
                                .font(.furgHeadline)
                                .foregroundColor(.white)

                            HStack {
                                Text("$")
                                    .font(.furgTitle2)
                                    .foregroundColor(.white.opacity(0.5))

                                TextField("30,000", text: $goalAmount)
                                    .font(.furgTitle2)
                                    .foregroundColor(.white)
                                    .keyboardType(.numberPad)
                            }
                            .padding()
                            .background(Color.white.opacity(0.1))
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.white.opacity(0.2), lineWidth: 1)
                            )
                        }

                        // Deadline
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Target date")
                                .font(.furgHeadline)
                                .foregroundColor(.white)

                            DatePicker(
                                "",
                                selection: $goalDeadline,
                                in: Date()...,
                                displayedComponents: .date
                            )
                            .datePickerStyle(.compact)
                            .labelsHidden()
                            .tint(.furgMint)
                            .colorScheme(.dark)
                        }
                    }
                }
                .padding(.horizontal, 24)
            }
            .padding(.bottom, 100)
        }
    }
}

// MARK: - Step 4: Intensity

struct IntensityStep: View {
    @Binding var intensityMode: String

    var body: some View {
        VStack(spacing: 32) {
            Spacer()

            VStack(spacing: 16) {
                Image(systemName: "flame.fill")
                    .font(.system(size: 60))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.furgMint, .furgSeafoam],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )

                Text("Roast Level")
                    .font(.furgLargeTitle)
                    .foregroundColor(.white)

                Text("How hard should I be on you?")
                    .font(.furgBody)
                    .foregroundColor(.white.opacity(0.6))
            }

            VStack(spacing: 16) {
                IntensityOption(
                    title: "Mild",
                    description: "Gentle nudges, minimal roasting",
                    icon: "leaf.fill",
                    isSelected: intensityMode == "mild"
                ) {
                    intensityMode = "mild"
                }

                IntensityOption(
                    title: "Moderate",
                    description: "Balanced tough love",
                    icon: "flame",
                    isSelected: intensityMode == "moderate"
                ) {
                    intensityMode = "moderate"
                }

                IntensityOption(
                    title: "Insanity",
                    description: "Maximum roasting, no mercy",
                    icon: "flame.fill",
                    isSelected: intensityMode == "insanity"
                ) {
                    intensityMode = "insanity"
                }
            }
            .padding(.horizontal, 24)

            Spacer()
            Spacer()
        }
    }
}

struct IntensityOption: View {
    let title: String
    let description: String
    let icon: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(isSelected ? Color.furgMint.opacity(0.3) : Color.white.opacity(0.1))
                        .frame(width: 50, height: 50)

                    Image(systemName: icon)
                        .font(.system(size: 22))
                        .foregroundColor(isSelected ? .furgMint : .white.opacity(0.6))
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.furgHeadline)
                        .foregroundColor(.white)

                    Text(description)
                        .font(.furgCaption)
                        .foregroundColor(.white.opacity(0.5))
                }

                Spacer()

                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 24))
                        .foregroundColor(.furgMint)
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.white.opacity(0.05))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(
                                isSelected ? Color.furgMint.opacity(0.5) : Color.white.opacity(0.1),
                                lineWidth: isSelected ? 2 : 1
                            )
                    )
            )
        }
    }
}

// MARK: - Step 5: Connect Bank

struct ConnectBankStep: View {
    @EnvironmentObject var plaidManager: PlaidManager

    var body: some View {
        VStack(spacing: 32) {
            Spacer()

            VStack(spacing: 16) {
                Image(systemName: "building.columns.fill")
                    .font(.system(size: 60))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.furgMint, .furgSeafoam],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )

                Text("Connect Your Bank")
                    .font(.furgLargeTitle)
                    .foregroundColor(.white)

                Text("Automatic transaction tracking.\nNo manual entry needed.")
                    .font(.furgBody)
                    .foregroundColor(.white.opacity(0.6))
                    .multilineTextAlignment(.center)
            }

            CopilotCard(padding: 24) {
                VStack(spacing: 20) {
                    HStack(spacing: 12) {
                        Image(systemName: "lock.shield.fill")
                            .font(.system(size: 20))
                            .foregroundColor(.furgMint)

                        Text("Bank-level security with Plaid")
                            .font(.furgCaption)
                            .foregroundColor(.white.opacity(0.7))
                    }

                    Divider()
                        .background(Color.white.opacity(0.1))

                    VStack(spacing: 12) {
                        BankBenefitRow(icon: "creditcard.fill", text: "Auto-track transactions")
                        BankBenefitRow(icon: "chart.line.uptrend.xyaxis", text: "Spending insights")
                        BankBenefitRow(icon: "bell.fill", text: "Bill detection")
                        BankBenefitRow(icon: "eye.slash.fill", text: "Shadow banking setup")
                    }

                    Button {
                        Task {
                            await plaidManager.presentPlaidLink()
                        }
                    } label: {
                        HStack {
                            Image(systemName: "plus.circle.fill")
                            Text("Connect Bank Account")
                        }
                        .font(.furgHeadline)
                        .foregroundColor(.furgDarkBg)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Color.furgMint)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }

                    Text("You can also connect later in Settings")
                        .font(.furgCaption)
                        .foregroundColor(.white.opacity(0.4))
                }
            }
            .padding(.horizontal, 24)

            Spacer()
            Spacer()
        }
    }
}

struct BankBenefitRow: View {
    let icon: String
    let text: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundColor(.furgMint)
                .frame(width: 24)

            Text(text)
                .font(.furgBody)
                .foregroundColor(.white.opacity(0.8))

            Spacer()
        }
    }
}

// MARK: - Preview

#Preview {
    OnboardingView()
        .environmentObject(AuthManager())
        .environmentObject(FinanceManager())
        .environmentObject(GoalsManager())
        .environmentObject(PlaidManager())
}
