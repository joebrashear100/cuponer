import SwiftUI

// MARK: - Life Integration Hub View

struct LifeIntegrationView: View {
    @StateObject private var lifeContext = LifeContextManager.shared
    @StateObject private var timeWealth = TimeWealthManager.shared
    @StateObject private var emotionalSpending = EmotionalSpendingManager.shared
    @StateObject private var emailIntelligence = EmailIntelligenceManager.shared
    @StateObject private var receiptScanner = ReceiptScannerManager.shared
    @StateObject private var photoIntelligence = PhotoIntelligenceManager.shared
    @StateObject private var retailerConnection = RetailerConnectionManager.shared
    @StateObject private var conversationMemory = ConversationMemoryManager.shared
    @StateObject private var lifeEventDetector = LifeEventDetector.shared
    @StateObject private var lifeSimulator = LifeSimulator.shared
    @StateObject private var loyaltyPrograms = LoyaltyProgramManager.shared
    @StateObject private var shoppingIntelligence = ShoppingIntelligenceManager.shared

    @State private var selectedTab: LifeTab = .context
    @State private var showingSettings = false
    @State private var showingCamera = false

    enum LifeTab: String, CaseIterable {
        case context = "Context"
        case time = "Time"
        case mood = "Mood"
        case shopping = "Shop"
        case simulate = "Simulate"

        var icon: String {
            switch self {
            case .context: return "brain.head.profile"
            case .time: return "clock.fill"
            case .mood: return "heart.fill"
            case .shopping: return "cart.fill"
            case .simulate: return "wand.and.stars"
            }
        }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Life Context Summary Card
                    lifeContextSummaryCard

                    // Tab Selection
                    tabSelector

                    // Tab Content
                    tabContent

                    // Quick Actions
                    quickActionsSection

                    // Insights Feed
                    insightsFeedSection
                }
                .padding()
            }
            .navigationTitle("Life Hub")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    HStack {
                        Button {
                            showingCamera = true
                        } label: {
                            Image(systemName: "camera.fill")
                        }

                        Button {
                            showingSettings = true
                        } label: {
                            Image(systemName: "gear")
                        }
                    }
                }
            }
            .sheet(isPresented: $showingSettings) {
                LifeIntegrationSettingsView()
            }
            .sheet(isPresented: $showingCamera) {
                PhotoScanView()
            }
        }
    }

    // MARK: - Life Context Summary

    private var lifeContextSummaryCard: some View {
        VStack(spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Your Life Context")
                        .font(.headline)
                    Text(contextSummaryText)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                spendingRiskIndicator
            }

            // Key Metrics Row
            HStack(spacing: 12) {
                ContextMetricView(
                    icon: "clock.fill",
                    value: String(format: "%.1fh", timeWealth.todayHoursSpent),
                    label: "Hours Today",
                    color: .blue
                )

                ContextMetricView(
                    icon: "heart.fill",
                    value: emotionalSpending.currentMood?.mood.emoji ?? "😐",
                    label: "Mood",
                    color: .pink
                )

                ContextMetricView(
                    icon: "location.fill",
                    value: lifeContext.locationContext.currentMode.rawValue.prefix(4).capitalized,
                    label: "Mode",
                    color: .green
                )

                ContextMetricView(
                    icon: "bed.double.fill",
                    value: String(format: "%.1fh", lifeContext.healthContext.lastNightSleep ?? 0),
                    label: "Sleep",
                    color: .purple
                )
            }

            // Active Alerts
            if !lifeContext.contextualAlerts.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(lifeContext.contextualAlerts.prefix(2), id: \.id) { alert in
                        HStack {
                            Circle()
                                .fill(alertColor(alert.priority))
                                .frame(width: 8, height: 8)
                            Text(alert.title)
                                .font(.caption)
                                .fontWeight(.medium)
                            Spacer()
                            if alert.actionable {
                                Text(alert.action ?? "")
                                    .font(.caption2)
                                    .foregroundStyle(.blue)
                            }
                        }
                    }
                }
                .padding(.top, 8)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.05), radius: 10, y: 5)
    }

    private var spendingRiskIndicator: some View {
        VStack(spacing: 4) {
            ZStack {
                Circle()
                    .stroke(Color.gray.opacity(0.2), lineWidth: 6)
                Circle()
                    .trim(from: 0, to: lifeContext.spendingRiskScore / 100)
                    .stroke(spendingRiskColor, style: StrokeStyle(lineWidth: 6, lineCap: .round))
                    .rotationEffect(.degrees(-90))

                Text("\(Int(lifeContext.spendingRiskScore))")
                    .font(.caption)
                    .fontWeight(.bold)
            }
            .frame(width: 50, height: 50)

            Text("Risk")
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
    }

    private var spendingRiskColor: Color {
        if lifeContext.spendingRiskScore < 30 { return .green }
        if lifeContext.spendingRiskScore < 60 { return .yellow }
        if lifeContext.spendingRiskScore < 80 { return .orange }
        return .red
    }

    private var contextSummaryText: String {
        var parts: [String] = []

        if let sleep = lifeContext.healthContext.lastNightSleep {
            parts.append(sleep < 6 ? "Low sleep" : "Well rested")
        }

        parts.append(lifeContext.healthContext.stressLevel.rawValue + " stress")

        if !lifeContext.locationContext.isInHomeCity {
            parts.append("Traveling")
        }

        return parts.joined(separator: " • ")
    }

    // MARK: - Tab Selector

    private var tabSelector: some View {
        HStack(spacing: 8) {
            ForEach(LifeTab.allCases, id: \.self) { tab in
                Button {
                    withAnimation(.spring(response: 0.3)) {
                        selectedTab = tab
                    }
                } label: {
                    VStack(spacing: 4) {
                        Image(systemName: tab.icon)
                            .font(.system(size: 18))
                        Text(tab.rawValue)
                            .font(.caption2)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(selectedTab == tab ? Color.blue.opacity(0.1) : Color.clear)
                    .foregroundStyle(selectedTab == tab ? .blue : .secondary)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                }
            }
        }
        .padding(4)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    // MARK: - Tab Content

    @ViewBuilder
    private var tabContent: some View {
        switch selectedTab {
        case .context:
            ContextTabView(lifeContext: lifeContext, conversationMemory: conversationMemory, lifeEventDetector: lifeEventDetector)
        case .time:
            TimeWealthTabView(timeWealth: timeWealth)
        case .mood:
            MoodTabView(emotionalSpending: emotionalSpending)
        case .shopping:
            ShoppingTabView(
                shoppingIntelligence: shoppingIntelligence,
                retailerConnection: retailerConnection,
                loyaltyPrograms: loyaltyPrograms
            )
        case .simulate:
            SimulateTabView(lifeSimulator: lifeSimulator)
        }
    }

    // MARK: - Quick Actions

    private var quickActionsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Quick Actions")
                .font(.headline)

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                QuickActionButton(icon: "doc.text.viewfinder", title: "Scan Receipt", color: .blue) {
                    showingCamera = true
                }

                QuickActionButton(icon: "cart.badge.plus", title: "Add to List", color: .green) {
                    // Add to shopping list
                }

                QuickActionButton(icon: "face.smiling", title: "Log Mood", color: .pink) {
                    // Log mood
                }

                QuickActionButton(icon: "dollarsign.circle", title: "Quick Entry", color: .orange) {
                    // Quick transaction entry
                }
            }
        }
    }

    // MARK: - Insights Feed

    private var insightsFeedSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Insights")
                    .font(.headline)
                Spacer()
                Text("\(totalInsightsCount) new")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            VStack(spacing: 8) {
                // Life Events
                ForEach(lifeEventDetector.pendingConfirmation.prefix(2)) { event in
                    LifeEventInsightCard(event: event)
                }

                // Emotional Insights
                ForEach(emotionalSpending.insights.prefix(2)) { insight in
                    EmotionalInsightCard(insight: insight)
                }

                // Shopping Recommendations
                ForEach(shoppingIntelligence.recommendations.prefix(2)) { rec in
                    ShoppingRecommendationCard(recommendation: rec)
                }

                // Time Wealth Insights
                if let summary = timeWealth.weeklySummary {
                    ForEach(summary.insights.prefix(1)) { insight in
                        TimeWealthInsightCard(insight: insight)
                    }
                }
            }
        }
    }

    private var totalInsightsCount: Int {
        lifeEventDetector.pendingConfirmation.count +
        emotionalSpending.insights.count +
        shoppingIntelligence.recommendations.count +
        (timeWealth.weeklySummary?.insights.count ?? 0)
    }

    private func alertColor(_ priority: LifeContextSnapshot.ContextualRecommendation.Priority) -> Color {
        switch priority {
        case .low: return .gray
        case .medium: return .yellow
        case .high: return .orange
        case .urgent: return .red
        }
    }
}

// MARK: - Supporting Views

struct ContextMetricView: View {
    let icon: String
    let value: String
    let label: String
    let color: Color

    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundStyle(color)
            Text(value)
                .font(.caption)
                .fontWeight(.semibold)
            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

struct QuickActionButton: View {
    let icon: String
    let title: String
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 24))
                    .foregroundStyle(color)
                Text(title)
                    .font(.caption)
                    .foregroundStyle(.primary)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(color.opacity(0.1))
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }
}

// MARK: - Tab Content Views

struct ContextTabView: View {
    @ObservedObject var lifeContext: LifeContextManager
    @ObservedObject var conversationMemory: ConversationMemoryManager
    @ObservedObject var lifeEventDetector: LifeEventDetector

    var body: some View {
        VStack(spacing: 16) {
            // Calendar Events
            if !lifeContext.calendarEvents.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Upcoming Events")
                        .font(.subheadline)
                        .fontWeight(.semibold)

                    ForEach(lifeContext.calendarEvents.prefix(3)) { event in
                        HStack {
                            Image(systemName: event.eventType.icon)
                                .foregroundStyle(.blue)
                            VStack(alignment: .leading) {
                                Text(event.title)
                                    .font(.caption)
                                Text(event.startDate, style: .date)
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            if let cost = event.estimatedCost {
                                Text("~$\(Int(cost))")
                                    .font(.caption)
                                    .foregroundStyle(.orange)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }
                .padding()
                .background(Color(.secondarySystemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }

            // Active Goals
            if !conversationMemory.goals.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Active Goals")
                        .font(.subheadline)
                        .fontWeight(.semibold)

                    ForEach(conversationMemory.goals.filter { $0.status == .active }.prefix(3)) { goal in
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Image(systemName: goal.category.icon)
                                    .foregroundStyle(.green)
                                Text(goal.name)
                                    .font(.caption)
                                Spacer()
                                Text("\(Int(goal.progress * 100))%")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            ProgressView(value: goal.progress)
                                .tint(.green)
                        }
                        .padding(.vertical, 4)
                    }
                }
                .padding()
                .background(Color(.secondarySystemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }

            // Detected Life Events
            if !lifeEventDetector.pendingConfirmation.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Detected Life Events")
                        .font(.subheadline)
                        .fontWeight(.semibold)

                    ForEach(lifeEventDetector.pendingConfirmation) { event in
                        HStack {
                            Image(systemName: event.type.icon)
                                .foregroundStyle(Color(event.type.color))
                            VStack(alignment: .leading) {
                                Text(event.type.rawValue)
                                    .font(.caption)
                                    .fontWeight(.medium)
                                Text("\(Int(event.confidence * 100))% confidence")
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            Button("Confirm") {
                                lifeEventDetector.confirmEvent(event.id, confirmed: true)
                            }
                            .font(.caption)
                            .buttonStyle(.bordered)
                        }
                        .padding(.vertical, 4)
                    }
                }
                .padding()
                .background(Color(.secondarySystemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
        }
    }
}

struct TimeWealthTabView: View {
    @ObservedObject var timeWealth: TimeWealthManager

    var body: some View {
        VStack(spacing: 16) {
            // Today's Time Spent
            VStack(spacing: 8) {
                Text("Today's Spending")
                    .font(.subheadline)
                    .fontWeight(.semibold)

                HStack(alignment: .bottom, spacing: 4) {
                    Text(String(format: "%.1f", timeWealth.todayHoursSpent))
                        .font(.system(size: 48, weight: .bold, design: .rounded))
                    Text("hours of life")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .padding(.bottom, 10)
                }

                Text("at $\(String(format: "%.2f", timeWealth.profile.trueHourlyRate))/hour true rate")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.blue.opacity(0.1))
            .clipShape(RoundedRectangle(cornerRadius: 12))

            // Weekly Summary
            if let summary = timeWealth.weeklySummary {
                VStack(alignment: .leading, spacing: 8) {
                    Text("This Week")
                        .font(.subheadline)
                        .fontWeight(.semibold)

                    HStack {
                        VStack {
                            Text("\(String(format: "%.1f", summary.essentialHours))h")
                                .font(.headline)
                            Text("Essential")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                        .frame(maxWidth: .infinity)

                        VStack {
                            Text("\(String(format: "%.1f", summary.discretionaryHours))h")
                                .font(.headline)
                            Text("Discretionary")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                        .frame(maxWidth: .infinity)

                        VStack {
                            Text("$\(Int(summary.totalSpent))")
                                .font(.headline)
                            Text("Total")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                        .frame(maxWidth: .infinity)
                    }

                    // Top categories
                    if !summary.topTimeConsumers.isEmpty {
                        Divider()
                        Text("Top Time Consumers")
                            .font(.caption)
                            .foregroundStyle(.secondary)

                        ForEach(summary.topTimeConsumers.prefix(3)) { category in
                            HStack {
                                Text(category.category)
                                    .font(.caption)
                                Spacer()
                                Text("\(String(format: "%.1f", category.hoursOfLife))h")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }
                .padding()
                .background(Color(.secondarySystemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
        }
    }
}

struct MoodTabView: View {
    @ObservedObject var emotionalSpending: EmotionalSpendingManager
    @State private var selectedMood: MoodEntry.Mood = .neutral
    @State private var selectedEnergy: MoodEntry.EnergyLevel = .moderate
    @State private var stressLevel: Double = 5

    var body: some View {
        VStack(spacing: 16) {
            // Current Risk Level
            VStack(spacing: 8) {
                let (level, color, advice) = emotionalSpending.getRiskAssessment()

                Text("Spending Risk: \(level)")
                    .font(.headline)
                    .foregroundStyle(Color(color))

                Text(advice)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color(.secondarySystemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 12))

            // Quick Mood Log
            VStack(alignment: .leading, spacing: 12) {
                Text("Log Your Mood")
                    .font(.subheadline)
                    .fontWeight(.semibold)

                // Mood Selection
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(MoodEntry.Mood.allCases, id: \.self) { mood in
                            Button {
                                selectedMood = mood
                            } label: {
                                VStack {
                                    Text(mood.emoji)
                                        .font(.title2)
                                    Text(mood.rawValue)
                                        .font(.caption2)
                                }
                                .padding(8)
                                .background(selectedMood == mood ? Color.blue.opacity(0.2) : Color.clear)
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }

                // Stress Slider
                VStack(alignment: .leading, spacing: 4) {
                    Text("Stress Level: \(Int(stressLevel))")
                        .font(.caption)
                    Slider(value: $stressLevel, in: 1...10, step: 1)
                        .tint(.orange)
                }

                Button {
                    emotionalSpending.logMood(
                        selectedMood,
                        energy: selectedEnergy,
                        stress: Int(stressLevel)
                    )
                } label: {
                    Text("Log Mood")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(Color.blue)
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                }
            }
            .padding()
            .background(Color(.secondarySystemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 12))

            // Patterns
            if !emotionalSpending.patterns.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Detected Patterns")
                        .font(.subheadline)
                        .fontWeight(.semibold)

                    ForEach(emotionalSpending.patterns.prefix(3)) { pattern in
                        HStack {
                            VStack(alignment: .leading) {
                                Text(pattern.pattern.rawValue)
                                    .font(.caption)
                                    .fontWeight(.medium)
                                Text(pattern.description)
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            Text("$\(Int(pattern.totalAmount))")
                                .font(.caption)
                                .foregroundStyle(.orange)
                        }
                        .padding(.vertical, 4)
                    }
                }
                .padding()
                .background(Color(.secondarySystemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
        }
    }
}

struct ShoppingTabView: View {
    @ObservedObject var shoppingIntelligence: ShoppingIntelligenceManager
    @ObservedObject var retailerConnection: RetailerConnectionManager
    @ObservedObject var loyaltyPrograms: LoyaltyProgramManager

    var body: some View {
        VStack(spacing: 16) {
            // Shopping Stats
            HStack(spacing: 16) {
                LifeStatCard(value: "\(shoppingIntelligence.listItemCount)", label: "List Items", color: .blue)
                LifeStatCard(value: "\(shoppingIntelligence.activeDealsCount)", label: "Active Deals", color: .green)
                LifeStatCard(value: "$\(Int(loyaltyPrograms.totalPointsValue))", label: "Points Value", color: .orange)
            }

            // Shopping List Preview
            if !shoppingIntelligence.shoppingList.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Shopping List")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                        Spacer()
                        Text("\(shoppingIntelligence.shoppingList.filter { !$0.isPurchased }.count) items")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    ForEach(shoppingIntelligence.shoppingList.filter { !$0.isPurchased }.prefix(5)) { item in
                        HStack {
                            Image(systemName: "circle")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Text(item.name)
                                .font(.caption)
                            if item.quantity > 1 {
                                Text("x\(item.quantity)")
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            if let price = item.estimatedPrice {
                                Text("~$\(String(format: "%.2f", price))")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }
                .padding()
                .background(Color(.secondarySystemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }

            // Connected Retailers
            VStack(alignment: .leading, spacing: 8) {
                Text("Connected Retailers")
                    .font(.subheadline)
                    .fontWeight(.semibold)

                if retailerConnection.connectedAccounts.isEmpty {
                    Text("Connect retailers to track purchase history")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity)
                        .padding()
                } else {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach(retailerConnection.connectedAccounts) { account in
                                VStack {
                                    Image(systemName: account.retailer.icon)
                                        .font(.title2)
                                        .foregroundStyle(Color(account.retailer.color))
                                    Text(account.retailer.displayName)
                                        .font(.caption2)
                                }
                                .padding(8)
                                .background(Color(.tertiarySystemBackground))
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                            }
                        }
                    }
                }
            }
            .padding()
            .background(Color(.secondarySystemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 12))

            // Loyalty Programs
            if !loyaltyPrograms.programs.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Loyalty Programs")
                        .font(.subheadline)
                        .fontWeight(.semibold)

                    ForEach(loyaltyPrograms.programs.sorted { $0.estimatedValue > $1.estimatedValue }.prefix(3)) { program in
                        HStack {
                            Image(systemName: program.type.icon)
                                .foregroundStyle(.blue)
                            VStack(alignment: .leading) {
                                Text(program.name)
                                    .font(.caption)
                                Text("\(Int(program.pointsBalance)) \(program.pointsName)")
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            Text("$\(String(format: "%.2f", program.estimatedValue))")
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundStyle(.green)
                        }
                        .padding(.vertical, 4)
                    }
                }
                .padding()
                .background(Color(.secondarySystemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
        }
    }
}

struct SimulateTabView: View {
    @ObservedObject var lifeSimulator: LifeSimulator
    @State private var selectedScenarioType: LifeScenario.ScenarioType = .moveToCity
    @State private var selectedCity = "Austin"
    @State private var newSalary: Double = 80000

    var body: some View {
        VStack(spacing: 16) {
            // Quick Scenario Selector
            VStack(alignment: .leading, spacing: 8) {
                Text("What If...")
                    .font(.headline)

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach([LifeScenario.ScenarioType.moveToCity, .careerChange, .havingChild, .buyingHome, .earlyRetirement], id: \.self) { type in
                            Button {
                                selectedScenarioType = type
                            } label: {
                                VStack {
                                    Image(systemName: type.icon)
                                        .font(.title3)
                                    Text(type.rawValue.split(separator: " ").first ?? "")
                                        .font(.caption2)
                                }
                                .padding(12)
                                .background(selectedScenarioType == type ? Color.blue.opacity(0.2) : Color(.tertiarySystemBackground))
                                .clipShape(RoundedRectangle(cornerRadius: 10))
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }

            // Scenario Configuration
            VStack(alignment: .leading, spacing: 12) {
                switch selectedScenarioType {
                case .moveToCity:
                    Text("Select City")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    Picker("City", selection: $selectedCity) {
                        ForEach(lifeSimulator.getAvailableCities(), id: \.self) { city in
                            Text(city).tag(city)
                        }
                    }
                    .pickerStyle(.menu)

                case .careerChange:
                    Text("New Annual Salary")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    TextField("Salary", value: $newSalary, format: .currency(code: "USD"))
                        .textFieldStyle(.roundedBorder)

                default:
                    Text("Configure your scenario")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Button {
                    runSimulation()
                } label: {
                    Text("Run Simulation")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(Color.blue)
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                }
            }
            .padding()
            .background(Color(.secondarySystemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 12))

            // Recent Scenarios
            if !lifeSimulator.savedScenarios.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Recent Simulations")
                        .font(.subheadline)
                        .fontWeight(.semibold)

                    ForEach(lifeSimulator.savedScenarios.prefix(3)) { scenario in
                        HStack {
                            Image(systemName: scenario.type.icon)
                                .foregroundStyle(.blue)
                            VStack(alignment: .leading) {
                                Text(scenario.title)
                                    .font(.caption)
                                    .fontWeight(.medium)
                                Text(scenario.comparison.recommendation.prefix(50) + "...")
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            VStack(alignment: .trailing) {
                                Text(scenario.comparison.netWorthDifference >= 0 ? "+" : "")
                                Text("$\(Int(scenario.comparison.netWorthDifference))")
                                    .font(.caption)
                                    .foregroundStyle(scenario.comparison.netWorthDifference >= 0 ? .green : .red)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }
                .padding()
                .background(Color(.secondarySystemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
        }
    }

    private func runSimulation() {
        switch selectedScenarioType {
        case .moveToCity:
            _ = lifeSimulator.simulateMoveToCity(selectedCity)
        case .careerChange:
            _ = lifeSimulator.simulateCareerChange(newSalary: newSalary)
        case .havingChild:
            _ = lifeSimulator.simulateHavingChild()
        case .buyingHome:
            _ = lifeSimulator.simulateBuyingHome(homePrice: 400000)
        case .earlyRetirement:
            _ = lifeSimulator.simulateEarlyRetirement(targetAge: 55)
        default:
            break
        }
    }
}

struct LifeStatCard: View {
    let value: String
    let label: String
    let color: Color

    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.headline)
                .foregroundStyle(color)
            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(color.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }
}

// MARK: - Insight Cards

struct LifeEventInsightCard: View {
    let event: DetectedLifeEvent

    var body: some View {
        HStack {
            Image(systemName: event.type.icon)
                .foregroundStyle(Color(event.type.color))
            VStack(alignment: .leading) {
                Text("Life Event Detected")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                Text(event.type.rawValue)
                    .font(.caption)
                    .fontWeight(.medium)
            }
            Spacer()
            Text("Review")
                .font(.caption)
                .foregroundStyle(.blue)
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }
}

struct EmotionalInsightCard: View {
    let insight: EmotionalInsight

    var body: some View {
        HStack {
            Image(systemName: "heart.fill")
                .foregroundStyle(.pink)
            VStack(alignment: .leading) {
                Text(insight.title)
                    .font(.caption)
                    .fontWeight(.medium)
                Text(insight.message.prefix(50) + "...")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            Spacer()
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }
}

struct ShoppingRecommendationCard: View {
    let recommendation: SmartRecommendation

    var body: some View {
        HStack {
            Image(systemName: "lightbulb.fill")
                .foregroundStyle(.yellow)
            VStack(alignment: .leading) {
                Text(recommendation.title)
                    .font(.caption)
                    .fontWeight(.medium)
                if let savings = recommendation.potentialSavings {
                    Text("Save $\(String(format: "%.2f", savings))")
                        .font(.caption2)
                        .foregroundStyle(.green)
                }
            }
            Spacer()
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }
}

struct TimeWealthInsightCard: View {
    let insight: TimeWealthSummary.TimeWealthInsight

    var body: some View {
        HStack {
            Image(systemName: "clock.fill")
                .foregroundStyle(.blue)
            VStack(alignment: .leading) {
                Text(insight.title)
                    .font(.caption)
                    .fontWeight(.medium)
                Text(insight.message.prefix(50) + "...")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            Spacer()
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }
}

// MARK: - Settings View

struct LifeIntegrationSettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var lifeContext = LifeContextManager.shared

    var body: some View {
        NavigationStack {
            List {
                Section("Permissions") {
                    Toggle("Calendar Access", isOn: .constant(lifeContext.calendarAccessGranted))
                        .disabled(true)
                    Toggle("Health Access", isOn: .constant(lifeContext.healthAccessGranted))
                        .disabled(true)
                    Toggle("Location Access", isOn: .constant(lifeContext.locationAccessGranted))
                        .disabled(true)

                    Button("Request All Permissions") {
                        lifeContext.requestAllPermissions()
                    }
                }

                Section("Data Sources") {
                    NavigationLink("Email Intelligence") {
                        Text("Email Settings")
                    }
                    NavigationLink("Connected Retailers") {
                        Text("Retailer Settings")
                    }
                    NavigationLink("Loyalty Programs") {
                        Text("Loyalty Settings")
                    }
                }

                Section("Preferences") {
                    NavigationLink("Time Wealth Profile") {
                        Text("Time Wealth Settings")
                    }
                    NavigationLink("Emotional Spending") {
                        Text("Emotional Settings")
                    }
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Photo Scan View

struct PhotoScanView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            VStack {
                Text("Camera View")
                    .font(.headline)
                Text("Scan receipts or products")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .navigationTitle("Scan")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    LifeIntegrationView()
}
