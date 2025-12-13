//
//  EnhancedOnboardingView.swift
//  Furg
//
//  Premium onboarding experience with animations and engaging content
//

import SwiftUI

struct EnhancedOnboardingView: View {
    @EnvironmentObject var authManager: AuthManager
    @EnvironmentObject var financeManager: FinanceManager
    @EnvironmentObject var goalsManager: GoalsManager
    @EnvironmentObject var plaidManager: PlaidManager

    @State private var currentPage = 0
    @State private var name = ""
    @State private var monthlyIncome = ""
    @State private var savingsGoal = ""
    @State private var goalPurpose = "Emergency Fund"
    @State private var roastLevel = "moderate"
    @State private var isLoading = false
    @State private var showConfetti = false

    private let totalPages = 6

    var body: some View {
        ZStack {
            AnimatedMeshBackground()

            VStack(spacing: 0) {
                // Progress indicator
                progressIndicator
                    .padding(.top, 16)

                // Page content
                TabView(selection: $currentPage) {
                    SplashPage()
                        .tag(0)

                    NameInputPage(name: $name)
                        .tag(1)

                    IncomePage(monthlyIncome: $monthlyIncome)
                        .tag(2)

                    GoalSetupPage(savingsGoal: $savingsGoal, goalPurpose: $goalPurpose)
                        .tag(3)

                    RoastLevelPage(roastLevel: $roastLevel)
                        .tag(4)

                    PermissionsPage()
                        .tag(5)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .animation(.spring(response: 0.5, dampingFraction: 0.8), value: currentPage)

                // Navigation
                navigationButtons
                    .padding(.horizontal, 24)
                    .padding(.bottom, 40)
            }

            if showConfetti {
                ConfettiView()
                    .allowsHitTesting(false)
            }
        }
    }

    // MARK: - Progress Indicator

    private var progressIndicator: some View {
        HStack(spacing: 8) {
            ForEach(0..<totalPages, id: \.self) { index in
                Capsule()
                    .fill(index <= currentPage ? Color.furgMint : Color.white.opacity(0.2))
                    .frame(width: index == currentPage ? 24 : 8, height: 8)
                    .animation(.spring(response: 0.3), value: currentPage)
            }
        }
        .padding(.horizontal, 24)
    }

    // MARK: - Navigation Buttons

    private var navigationButtons: some View {
        HStack(spacing: 16) {
            if currentPage > 0 {
                Button {
                    withAnimation(.spring(response: 0.4)) {
                        currentPage -= 1
                    }
                    ThemeManager.shared.triggerHaptic(.light)
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "chevron.left")
                        Text("Back")
                    }
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.white.opacity(0.7))
                    .padding(.horizontal, 20)
                    .padding(.vertical, 14)
                    .background(Color.white.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
            }

            Spacer()

            if currentPage < totalPages - 1 {
                Button {
                    withAnimation(.spring(response: 0.4)) {
                        currentPage += 1
                    }
                    ThemeManager.shared.triggerHaptic(.medium)
                } label: {
                    HStack(spacing: 6) {
                        Text(currentPage == 0 ? "Get Started" : "Continue")
                        Image(systemName: "chevron.right")
                    }
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.furgCharcoal)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 14)
                    .background(
                        LinearGradient(
                            colors: [.furgMint, .furgSeafoam],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
            } else {
                Button {
                    completeOnboarding()
                } label: {
                    HStack(spacing: 8) {
                        if isLoading {
                            ProgressView()
                                .tint(.furgCharcoal)
                        } else {
                            Image(systemName: "sparkles")
                            Text("Let's Go!")
                        }
                    }
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.furgCharcoal)
                    .padding(.horizontal, 28)
                    .padding(.vertical, 14)
                    .background(
                        LinearGradient(
                            colors: [.furgMint, .furgSeafoam],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .disabled(isLoading)
            }
        }
    }

    // MARK: - Complete Onboarding

    private func completeOnboarding() {
        isLoading = true
        ThemeManager.shared.triggerNotificationHaptic(.success)
        showConfetti = true

        Task {
            // Save user data
            // Note: Monthly budget will be set via budget manager later
            _ = Double(monthlyIncome.replacingOccurrences(of: ",", with: ""))

            if let goalAmount = Double(savingsGoal.replacingOccurrences(of: ",", with: "")), !goalPurpose.isEmpty {
                let goal = FurgSavingsGoal(
                    id: UUID().uuidString,
                    name: goalPurpose,
                    targetAmount: Decimal(goalAmount),
                    currentAmount: 0,
                    deadline: Calendar.current.date(byAdding: .year, value: 1, to: Date()),
                    priority: 1,
                    category: goalCategory(for: goalPurpose),
                    icon: goalIcon(for: goalPurpose),
                    color: "mint",
                    linkedAccountIds: [],
                    autoContribute: false,
                    autoContributeAmount: nil,
                    autoContributeFrequency: nil,
                    createdAt: Date(),
                    achievedAt: nil
                )
                _ = await goalsManager.createGoal(goal)
            }

            // Wait for confetti
            try? await Task.sleep(nanoseconds: 1_500_000_000)

            authManager.completeOnboarding()
            isLoading = false
        }
    }

    private func goalCategory(for purpose: String) -> GoalCategory {
        switch purpose {
        case "Emergency Fund": return .emergencyFund
        case "House Down Payment": return .homeDownPayment
        case "Vacation": return .vacation
        case "New Car": return .car
        case "Retirement": return .retirement
        case "Wedding": return .wedding
        case "Debt Payoff": return .debtPayoff
        default: return .custom
        }
    }

    private func goalIcon(for purpose: String) -> String {
        switch purpose {
        case "Emergency Fund": return "cross.case.fill"
        case "House Down Payment": return "house.fill"
        case "Vacation": return "airplane"
        case "New Car": return "car.fill"
        case "Retirement": return "sun.horizon.fill"
        case "Wedding": return "heart.fill"
        case "Debt Payoff": return "arrow.down.circle.fill"
        default: return "star.fill"
        }
    }
}

// MARK: - Splash Page

struct SplashPage: View {
    @State private var logoScale: CGFloat = 0.8
    @State private var logoOpacity: Double = 0
    @State private var textOpacity: Double = 0
    @State private var featuresOpacity: Double = 0

    var body: some View {
        VStack(spacing: 32) {
            Spacer()

            // Animated logo
            ZStack {
                // Glow effect
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [.furgMint.opacity(0.4), .clear],
                            center: .center,
                            startRadius: 0,
                            endRadius: 80
                        )
                    )
                    .frame(width: 160, height: 160)
                    .blur(radius: 20)

                // Logo icon
                Image(systemName: "flame.fill")
                    .font(.system(size: 80))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.furgMint, .furgSeafoam],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }
            .scaleEffect(logoScale)
            .opacity(logoOpacity)

            VStack(spacing: 16) {
                Text("Welcome to FURG")
                    .font(.system(size: 34, weight: .bold, design: .rounded))
                    .foregroundColor(.white)

                Text("Your brutally honest\nfinancial AI companion")
                    .font(.system(size: 18))
                    .foregroundColor(.white.opacity(0.6))
                    .multilineTextAlignment(.center)
            }
            .opacity(textOpacity)

            Spacer()

            // Feature highlights
            VStack(spacing: 16) {
                FeatureHighlight(icon: "brain.head.profile", text: "AI-powered insights", color: .furgMint)
                FeatureHighlight(icon: "chart.line.uptrend.xyaxis", text: "Smart spending tracking", color: .furgSeafoam)
                FeatureHighlight(icon: "flame", text: "Motivational roasting", color: .furgWarning)
            }
            .opacity(featuresOpacity)
            .padding(.horizontal, 40)

            Spacer()
        }
        .onAppear {
            withAnimation(.spring(response: 0.8, dampingFraction: 0.6).delay(0.2)) {
                logoScale = 1.0
                logoOpacity = 1.0
            }
            withAnimation(.easeOut(duration: 0.6).delay(0.5)) {
                textOpacity = 1.0
            }
            withAnimation(.easeOut(duration: 0.6).delay(0.8)) {
                featuresOpacity = 1.0
            }
        }
    }
}

struct FeatureHighlight: View {
    let icon: String
    let text: String
    let color: Color

    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundColor(color)
                .frame(width: 44, height: 44)
                .background(color.opacity(0.2))
                .clipShape(RoundedRectangle(cornerRadius: 12))

            Text(text)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.white)

            Spacer()

            Image(systemName: "checkmark.circle.fill")
                .foregroundColor(color)
        }
        .padding(16)
        .background(Color.white.opacity(0.05))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

// MARK: - Name Input Page

struct NameInputPage: View {
    @Binding var name: String
    @State private var animate = false
    @FocusState private var isFocused: Bool

    var body: some View {
        VStack(spacing: 32) {
            Spacer()

            VStack(spacing: 16) {
                Image(systemName: "person.circle.fill")
                    .font(.system(size: 60))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.furgMint, .furgSeafoam],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .scaleEffect(animate ? 1 : 0.8)
                    .opacity(animate ? 1 : 0)

                Text("What's your name?")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                    .opacity(animate ? 1 : 0)

                Text("I promise to only roast you\na reasonable amount")
                    .font(.system(size: 16))
                    .foregroundColor(.white.opacity(0.6))
                    .multilineTextAlignment(.center)
                    .opacity(animate ? 1 : 0)
            }

            VStack(spacing: 12) {
                TextField("", text: $name, prompt: Text("Your name").foregroundColor(.white.opacity(0.3)))
                    .font(.system(size: 24, weight: .medium, design: .rounded))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .padding(.vertical, 20)
                    .background(Color.white.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(isFocused ? Color.furgMint : Color.white.opacity(0.2), lineWidth: 2)
                    )
                    .focused($isFocused)

                Text("You can skip this if you prefer to stay anonymous")
                    .font(.system(size: 12))
                    .foregroundColor(.white.opacity(0.4))
            }
            .padding(.horizontal, 32)
            .offset(y: animate ? 0 : 30)
            .opacity(animate ? 1 : 0)

            Spacer()
            Spacer()
        }
        .onAppear {
            withAnimation(.spring(response: 0.6).delay(0.2)) {
                animate = true
            }
        }
    }
}

// MARK: - Income Page

struct IncomePage: View {
    @Binding var monthlyIncome: String
    @State private var animate = false

    let presets = ["3,000", "5,000", "7,500", "10,000"]

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

                Text("Monthly Income")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundColor(.white)

                Text("After taxes - this helps me give\nyou realistic advice")
                    .font(.system(size: 16))
                    .foregroundColor(.white.opacity(0.6))
                    .multilineTextAlignment(.center)
            }
            .offset(y: animate ? 0 : 20)
            .opacity(animate ? 1 : 0)

            VStack(spacing: 20) {
                // Main input
                HStack {
                    Text("$")
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .foregroundColor(.furgMint)

                    TextField("0", text: $monthlyIncome)
                        .font(.system(size: 42, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                        .keyboardType(.numberPad)
                        .multilineTextAlignment(.center)
                }
                .padding(.vertical, 20)
                .padding(.horizontal, 24)
                .background(Color.white.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 20))
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color.furgMint.opacity(0.3), lineWidth: 2)
                )

                // Quick presets
                HStack(spacing: 10) {
                    ForEach(presets, id: \.self) { preset in
                        Button {
                            monthlyIncome = preset
                            ThemeManager.shared.triggerHaptic(.light)
                        } label: {
                            Text("$\(preset)")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(monthlyIncome == preset ? .furgCharcoal : .white.opacity(0.7))
                                .padding(.horizontal, 14)
                                .padding(.vertical, 10)
                                .background(monthlyIncome == preset ? Color.furgMint : Color.white.opacity(0.1))
                                .clipShape(Capsule())
                        }
                    }
                }
            }
            .padding(.horizontal, 32)
            .offset(y: animate ? 0 : 30)
            .opacity(animate ? 1 : 0)
            .animation(.spring(response: 0.6).delay(0.1), value: animate)

            Spacer()
            Spacer()
        }
        .onAppear {
            withAnimation(.spring(response: 0.6)) {
                animate = true
            }
        }
    }
}

// MARK: - Goal Setup Page

struct GoalSetupPage: View {
    @Binding var savingsGoal: String
    @Binding var goalPurpose: String
    @State private var animate = false

    let purposes = [
        ("Emergency Fund", "cross.case.fill", Color.red),
        ("House Down Payment", "house.fill", Color.blue),
        ("Vacation", "airplane", Color.orange),
        ("New Car", "car.fill", Color.purple),
        ("Retirement", "sun.horizon.fill", Color.green),
        ("Debt Payoff", "arrow.down.circle.fill", Color.furgMint)
    ]

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 32) {
                VStack(spacing: 16) {
                    Image(systemName: "target")
                        .font(.system(size: 60))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.furgMint, .furgSeafoam],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )

                    Text("Your Main Goal")
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundColor(.white)

                    Text("What are you saving for?\nI'll help you get there")
                        .font(.system(size: 16))
                        .foregroundColor(.white.opacity(0.6))
                        .multilineTextAlignment(.center)
                }
                .padding(.top, 40)
                .offset(y: animate ? 0 : 20)
                .opacity(animate ? 1 : 0)

                // Goal purpose selection
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                    ForEach(purposes, id: \.0) { purpose, icon, color in
                        Button {
                            goalPurpose = purpose
                            ThemeManager.shared.triggerHaptic(.light)
                        } label: {
                            VStack(spacing: 10) {
                                Image(systemName: icon)
                                    .font(.system(size: 24))
                                    .foregroundColor(goalPurpose == purpose ? .white : color)

                                Text(purpose)
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundColor(goalPurpose == purpose ? .white : .white.opacity(0.8))
                                    .multilineTextAlignment(.center)
                                    .lineLimit(2)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 20)
                            .background(goalPurpose == purpose ? color : color.opacity(0.2))
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(goalPurpose == purpose ? color : Color.clear, lineWidth: 2)
                            )
                        }
                    }
                }
                .padding(.horizontal, 24)
                .offset(y: animate ? 0 : 30)
                .opacity(animate ? 1 : 0)
                .animation(.spring(response: 0.6).delay(0.1), value: animate)

                // Goal amount
                VStack(alignment: .leading, spacing: 12) {
                    Text("Target Amount")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white.opacity(0.6))

                    HStack {
                        Text("$")
                            .font(.system(size: 28, weight: .bold, design: .rounded))
                            .foregroundColor(.furgMint)

                        TextField("10,000", text: $savingsGoal)
                            .font(.system(size: 32, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                            .keyboardType(.numberPad)
                    }
                    .padding(20)
                    .background(Color.white.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                }
                .padding(.horizontal, 24)
                .offset(y: animate ? 0 : 30)
                .opacity(animate ? 1 : 0)
                .animation(.spring(response: 0.6).delay(0.2), value: animate)

                Spacer(minLength: 100)
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.6)) {
                animate = true
            }
        }
    }
}

// MARK: - Roast Level Page

struct RoastLevelPage: View {
    @Binding var roastLevel: String
    @State private var animate = false

    let levels = [
        ("mild", "Gentle Nudges", "Soft encouragement, minimal criticism", "leaf.fill", Color.green),
        ("moderate", "Balanced Burn", "Honest feedback with tough love", "flame", Color.orange),
        ("insanity", "Maximum Roast", "No mercy, maximum accountability", "flame.fill", Color.red)
    ]

    var body: some View {
        VStack(spacing: 32) {
            Spacer()

            VStack(spacing: 16) {
                Image(systemName: "flame.fill")
                    .font(.system(size: 60))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.furgWarning, .furgDanger],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )

                Text("Roast Level")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundColor(.white)

                Text("How hard should I be on you?")
                    .font(.system(size: 16))
                    .foregroundColor(.white.opacity(0.6))
            }
            .offset(y: animate ? 0 : 20)
            .opacity(animate ? 1 : 0)

            VStack(spacing: 12) {
                ForEach(Array(levels.enumerated()), id: \.element.0) { index, level in
                    Button {
                        roastLevel = level.0
                        ThemeManager.shared.triggerHaptic(.medium)
                    } label: {
                        HStack(spacing: 16) {
                            ZStack {
                                Circle()
                                    .fill(roastLevel == level.0 ? level.4 : level.4.opacity(0.3))
                                    .frame(width: 50, height: 50)

                                Image(systemName: level.3)
                                    .font(.system(size: 22))
                                    .foregroundColor(roastLevel == level.0 ? .white : level.4)
                            }

                            VStack(alignment: .leading, spacing: 4) {
                                Text(level.1)
                                    .font(.system(size: 17, weight: .semibold))
                                    .foregroundColor(.white)

                                Text(level.2)
                                    .font(.system(size: 13))
                                    .foregroundColor(.white.opacity(0.5))
                            }

                            Spacer()

                            if roastLevel == level.0 {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.system(size: 24))
                                    .foregroundColor(level.4)
                            }
                        }
                        .padding(16)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color.white.opacity(roastLevel == level.0 ? 0.1 : 0.05))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 16)
                                        .stroke(roastLevel == level.0 ? level.4.opacity(0.5) : Color.clear, lineWidth: 2)
                                )
                        )
                    }
                    .offset(y: animate ? 0 : 30)
                    .opacity(animate ? 1 : 0)
                    .animation(.spring(response: 0.6).delay(Double(index) * 0.1), value: animate)
                }
            }
            .padding(.horizontal, 24)

            Spacer()
            Spacer()
        }
        .onAppear {
            withAnimation(.spring(response: 0.6)) {
                animate = true
            }
        }
    }
}

// MARK: - Permissions Page

struct PermissionsPage: View {
    @State private var animate = false
    @State private var notificationsGranted = false
    @State private var locationGranted = false

    var body: some View {
        VStack(spacing: 32) {
            Spacer()

            VStack(spacing: 16) {
                Image(systemName: "hand.raised.fill")
                    .font(.system(size: 60))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.furgMint, .furgSeafoam],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )

                Text("Almost There!")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundColor(.white)

                Text("Enable these for the best experience")
                    .font(.system(size: 16))
                    .foregroundColor(.white.opacity(0.6))
            }
            .offset(y: animate ? 0 : 20)
            .opacity(animate ? 1 : 0)

            VStack(spacing: 16) {
                PermissionCard(
                    icon: "bell.badge.fill",
                    title: "Notifications",
                    description: "Spending alerts, goal updates, and motivational roasts",
                    color: .furgWarning,
                    isGranted: notificationsGranted,
                    action: {
                        Task {
                            notificationsGranted = await NotificationManager.shared.requestAuthorization()
                        }
                    }
                )

                PermissionCard(
                    icon: "location.fill",
                    title: "Location",
                    description: "Location-based spending insights and nearby deals",
                    color: .furgInfo,
                    isGranted: locationGranted,
                    action: {
                        LocationManager.shared.requestAuthorization()
                        locationGranted = true
                    }
                )
            }
            .padding(.horizontal, 24)
            .offset(y: animate ? 0 : 30)
            .opacity(animate ? 1 : 0)
            .animation(.spring(response: 0.6).delay(0.1), value: animate)

            Text("You can change these anytime in Settings")
                .font(.system(size: 12))
                .foregroundColor(.white.opacity(0.4))
                .offset(y: animate ? 0 : 30)
                .opacity(animate ? 1 : 0)
                .animation(.spring(response: 0.6).delay(0.2), value: animate)

            Spacer()
            Spacer()
        }
        .onAppear {
            withAnimation(.spring(response: 0.6)) {
                animate = true
            }
        }
    }
}

struct PermissionCard: View {
    let icon: String
    let title: String
    let description: String
    let color: Color
    let isGranted: Bool
    let action: () -> Void

    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 24))
                .foregroundColor(color)
                .frame(width: 50, height: 50)
                .background(color.opacity(0.2))
                .clipShape(RoundedRectangle(cornerRadius: 12))

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)

                Text(description)
                    .font(.system(size: 12))
                    .foregroundColor(.white.opacity(0.5))
                    .lineLimit(2)
            }

            Spacer()

            Button(action: action) {
                Text(isGranted ? "Enabled" : "Enable")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(isGranted ? .white : .furgCharcoal)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(isGranted ? Color.furgSuccess : Color.furgMint)
                    .clipShape(Capsule())
            }
            .disabled(isGranted)
        }
        .padding(16)
        .background(Color.white.opacity(0.05))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

// MARK: - Confetti View

struct ConfettiView: View {
    @State private var particles: [ConfettiParticle] = []

    var body: some View {
        GeometryReader { geometry in
            ForEach(particles) { particle in
                Circle()
                    .fill(particle.color)
                    .frame(width: particle.size, height: particle.size)
                    .position(particle.position)
                    .opacity(particle.opacity)
            }
        }
        .onAppear {
            createParticles()
        }
    }

    private func createParticles() {
        let colors: [Color] = [.furgMint, .furgSeafoam, .furgWarning, .furgSuccess, .pink, .purple]
        let screenWidth = UIScreen.main.bounds.width
        let screenHeight = UIScreen.main.bounds.height

        for i in 0..<50 {
            let particle = ConfettiParticle(
                id: i,
                color: colors.randomElement()!,
                size: CGFloat.random(in: 6...12),
                position: CGPoint(x: CGFloat.random(in: 0...screenWidth), y: -20),
                opacity: 1.0
            )
            particles.append(particle)
        }

        // Animate particles falling
        for (index, _) in particles.enumerated() {
            let delay = Double.random(in: 0...0.5)
            let duration = Double.random(in: 1.5...3.0)

            DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                withAnimation(.easeIn(duration: duration)) {
                    particles[index].position.y = screenHeight + 50
                    particles[index].position.x += CGFloat.random(in: -100...100)
                    particles[index].opacity = 0
                }
            }
        }
    }
}

struct ConfettiParticle: Identifiable {
    let id: Int
    let color: Color
    let size: CGFloat
    var position: CGPoint
    var opacity: Double
}

// MARK: - Preview

#Preview {
    EnhancedOnboardingView()
        .environmentObject(AuthManager())
        .environmentObject(FinanceManager())
        .environmentObject(GoalsManager())
        .environmentObject(PlaidManager())
}
