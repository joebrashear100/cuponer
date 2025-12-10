import SwiftUI

// MARK: - Life Integration Hub View

struct LifeIntegrationView: View {
    @StateObject private var lifeContext = LifeContextManager.shared

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
                LifeQuickActionButton(icon: "doc.text.viewfinder", title: "Scan Receipt", color: .blue) {
                    showingCamera = true
                }

                LifeQuickActionButton(icon: "cart.badge.plus", title: "Add to List", color: .green) {
                    // Add to shopping list
                }

                LifeQuickActionButton(icon: "face.smiling", title: "Log Mood", color: .pink) {
                    // Log mood
                }

                LifeQuickActionButton(icon: "dollarsign.circle", title: "Quick Entry", color: .orange) {
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

struct LifeQuickActionButton: View {
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
