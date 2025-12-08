//
//  RecommendationsView.swift
//  Furg
//
//  Comprehensive recommendations hub for accounts, cards, insurance, and more
//

import SwiftUI

struct RecommendationsView: View {
    @StateObject private var recommendationEngine = RecommendationEngine.shared
    @StateObject private var cardOptimizer = CardOptimizer.shared
    @State private var selectedCategory: RecommendationCategory?
    @State private var selectedRecommendation: Recommendation?
    @State private var showCardOptimizer = false
    @State private var animate = false

    var body: some View {
        NavigationStack {
            ZStack {
                Color.furgCharcoal.ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 24) {
                        // Savings Summary Header
                        savingsSummaryCard
                            .opacity(animate ? 1 : 0)
                            .offset(y: animate ? 0 : 20)

                        // Quick Actions
                        quickActionsSection
                            .opacity(animate ? 1 : 0)
                            .offset(y: animate ? 0 : 20)
                            .animation(.spring(response: 0.6).delay(0.1), value: animate)

                        // Card Optimizer Quick Access
                        cardOptimizerCard
                            .opacity(animate ? 1 : 0)
                            .offset(y: animate ? 0 : 20)
                            .animation(.spring(response: 0.6).delay(0.15), value: animate)

                        // Featured Recommendations
                        if !recommendationEngine.featuredRecommendations.isEmpty {
                            featuredSection
                                .opacity(animate ? 1 : 0)
                                .offset(y: animate ? 0 : 20)
                                .animation(.spring(response: 0.6).delay(0.2), value: animate)
                        }

                        // Category Selector
                        categorySelector
                            .opacity(animate ? 1 : 0)
                            .offset(y: animate ? 0 : 20)
                            .animation(.spring(response: 0.6).delay(0.25), value: animate)

                        // Recommendations List
                        recommendationsList
                            .opacity(animate ? 1 : 0)
                            .offset(y: animate ? 0 : 20)
                            .animation(.spring(response: 0.6).delay(0.3), value: animate)

                        Spacer(minLength: 100)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                }
            }
            .navigationTitle("For You")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        recommendationEngine.analyzeAndGenerateRecommendations()
                    } label: {
                        Image(systemName: "arrow.clockwise")
                            .foregroundColor(.furgMint)
                    }
                }
            }
            .onAppear {
                withAnimation(.spring(response: 0.6)) {
                    animate = true
                }
                if recommendationEngine.recommendations.isEmpty {
                    recommendationEngine.analyzeAndGenerateRecommendations()
                }
                cardOptimizer.generateCategoryRecommendations()
            }
            .sheet(item: $selectedRecommendation) { recommendation in
                RecommendationDetailView(recommendation: recommendation)
            }
            .sheet(isPresented: $showCardOptimizer) {
                CardOptimizerView()
            }
        }
    }

    // MARK: - Savings Summary

    private var savingsSummaryCard: some View {
        VStack(spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Potential Annual Value")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.white.opacity(0.6))

                    Text("$\(Int(recommendationEngine.totalPotentialSavings + recommendationEngine.totalPotentialEarnings))")
                        .font(.system(size: 36, weight: .bold, design: .rounded))
                        .foregroundColor(.furgMint)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 8) {
                    HStack(spacing: 4) {
                        Image(systemName: "arrow.down.circle.fill")
                            .foregroundColor(.furgSuccess)
                        Text("$\(Int(recommendationEngine.totalPotentialSavings))")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.furgSuccess)
                    }

                    HStack(spacing: 4) {
                        Image(systemName: "arrow.up.circle.fill")
                            .foregroundColor(.furgMint)
                        Text("$\(Int(recommendationEngine.totalPotentialEarnings))")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.furgMint)
                    }
                }
            }

            HStack {
                Text("\(recommendationEngine.recommendations.count) personalized recommendations")
                    .font(.system(size: 12))
                    .foregroundColor(.white.opacity(0.5))

                Spacer()

                if let lastAnalyzed = recommendationEngine.lastAnalyzed {
                    Text("Updated \(timeAgo(lastAnalyzed))")
                        .font(.system(size: 11))
                        .foregroundColor(.white.opacity(0.4))
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(LinearGradient(colors: [.furgMint.opacity(0.2), .furgCharcoal], startPoint: .topLeading, endPoint: .bottomTrailing))
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color.furgMint.opacity(0.3), lineWidth: 1)
                )
        )
    }

    // MARK: - Quick Actions

    private var quickActionsSection: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                RecommendationActionButton(
                    icon: "creditcard.fill",
                    title: "Which Card?",
                    subtitle: "Maximize rewards",
                    color: .purple
                ) {
                    showCardOptimizer = true
                }

                RecommendationActionButton(
                    icon: "banknote",
                    title: "Best Rates",
                    subtitle: "Savings accounts",
                    color: .green
                ) {
                    selectedCategory = .accounts
                }

                RecommendationActionButton(
                    icon: "shield.fill",
                    title: "Insurance",
                    subtitle: "Compare quotes",
                    color: .blue
                ) {
                    selectedCategory = .insurance
                }

                RecommendationActionButton(
                    icon: "percent",
                    title: "Refinance",
                    subtitle: "Lower rates",
                    color: .red
                ) {
                    selectedCategory = .loans
                }
            }
        }
    }

    // MARK: - Card Optimizer Card

    private var cardOptimizerCard: some View {
        Button {
            showCardOptimizer = true
        } label: {
            HStack(spacing: 16) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.purple.opacity(0.2))
                        .frame(width: 50, height: 50)

                    Image(systemName: "creditcard.and.123")
                        .font(.system(size: 22))
                        .foregroundColor(.purple)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text("Card Optimizer")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)

                    Text("Which card to use for each purchase")
                        .font(.system(size: 12))
                        .foregroundColor(.white.opacity(0.6))
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 4) {
                    Text("+$\(Int(cardOptimizer.totalOptimizedValue))")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.furgMint)

                    Text("per year")
                        .font(.system(size: 10))
                        .foregroundColor(.white.opacity(0.5))
                }

                Image(systemName: "chevron.right")
                    .font(.system(size: 14))
                    .foregroundColor(.white.opacity(0.3))
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.white.opacity(0.05))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color.purple.opacity(0.3), lineWidth: 1)
                    )
            )
        }
    }

    // MARK: - Featured Section

    private var featuredSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "star.fill")
                    .foregroundColor(.yellow)
                Text("Top Opportunities")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white.opacity(0.6))
            }

            ForEach(recommendationEngine.featuredRecommendations.prefix(3)) { recommendation in
                FeaturedRecommendationCard(recommendation: recommendation)
                    .onTapGesture {
                        selectedRecommendation = recommendation
                    }
            }
        }
    }

    // MARK: - Category Selector

    private var categorySelector: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                CategoryPill(
                    title: "All",
                    icon: "square.grid.2x2.fill",
                    isSelected: selectedCategory == nil,
                    color: .furgMint
                ) {
                    selectedCategory = nil
                }

                ForEach(RecommendationCategory.allCases, id: \.self) { category in
                    CategoryPill(
                        title: category.rawValue,
                        icon: category.icon,
                        isSelected: selectedCategory == category,
                        color: category.color
                    ) {
                        selectedCategory = category
                    }
                }
            }
        }
    }

    // MARK: - Recommendations List

    private var recommendationsList: some View {
        let filteredRecommendations = selectedCategory == nil
            ? recommendationEngine.recommendations
            : recommendationEngine.getRecommendations(for: selectedCategory!)

        return VStack(alignment: .leading, spacing: 12) {
            if selectedCategory != nil {
                Text("\(selectedCategory!.rawValue) Recommendations")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white.opacity(0.6))
            }

            if filteredRecommendations.isEmpty {
                EmptyRecommendationsView()
            } else {
                ForEach(filteredRecommendations) { recommendation in
                    RecommendationRow(recommendation: recommendation)
                        .onTapGesture {
                            selectedRecommendation = recommendation
                        }
                }
            }
        }
    }

    // MARK: - Helpers

    private func timeAgo(_ date: Date) -> String {
        let interval = Date().timeIntervalSince(date)
        if interval < 60 {
            return "just now"
        } else if interval < 3600 {
            return "\(Int(interval / 60))m ago"
        } else if interval < 86400 {
            return "\(Int(interval / 3600))h ago"
        } else {
            return "\(Int(interval / 86400))d ago"
        }
    }
}

// MARK: - Supporting Views

struct RecommendationActionButton: View {
    let icon: String
    let title: String
    let subtitle: String
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 10) {
                Image(systemName: icon)
                    .font(.system(size: 22))
                    .foregroundColor(color)

                VStack(spacing: 2) {
                    Text(title)
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.white)

                    Text(subtitle)
                        .font(.system(size: 10))
                        .foregroundColor(.white.opacity(0.5))
                }
            }
            .frame(width: 90)
            .padding(.vertical, 14)
            .background(color.opacity(0.15))
            .clipShape(RoundedRectangle(cornerRadius: 14))
        }
    }
}

struct CategoryPill: View {
    let title: String
    let icon: String
    let isSelected: Bool
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 12))

                Text(title)
                    .font(.system(size: 12, weight: .medium))
            }
            .foregroundColor(isSelected ? .furgCharcoal : .white.opacity(0.7))
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(isSelected ? color : Color.white.opacity(0.08))
            .clipShape(Capsule())
        }
    }
}

struct FeaturedRecommendationCard: View {
    let recommendation: Recommendation

    var body: some View {
        HStack(spacing: 14) {
            // Icon
            Image(systemName: recommendation.icon)
                .font(.system(size: 22))
                .foregroundColor(recommendation.color)
                .frame(width: 50, height: 50)
                .background(recommendation.color.opacity(0.2))
                .clipShape(RoundedRectangle(cornerRadius: 12))

            VStack(alignment: .leading, spacing: 4) {
                Text(recommendation.title)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.white)
                    .lineLimit(1)

                Text(recommendation.subtitle)
                    .font(.system(size: 12))
                    .foregroundColor(.white.opacity(0.6))
                    .lineLimit(1)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                if let savings = recommendation.potentialSavings {
                    Text("-$\(Int(savings))")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.furgSuccess)
                } else if let earnings = recommendation.potentialEarnings {
                    Text("+$\(Int(earnings))")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.furgMint)
                }

                Text(recommendation.urgency.rawValue)
                    .font(.system(size: 9, weight: .medium))
                    .foregroundColor(recommendation.urgency.color)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(recommendation.urgency.color.opacity(0.2))
                    .clipShape(Capsule())
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color.white.opacity(0.05))
        )
    }
}

struct RecommendationRow: View {
    let recommendation: Recommendation

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: recommendation.icon)
                .font(.system(size: 16))
                .foregroundColor(recommendation.color)
                .frame(width: 36, height: 36)
                .background(recommendation.color.opacity(0.2))
                .clipShape(RoundedRectangle(cornerRadius: 10))

            VStack(alignment: .leading, spacing: 2) {
                Text(recommendation.title)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white)
                    .lineLimit(1)

                Text(recommendation.category.rawValue)
                    .font(.system(size: 11))
                    .foregroundColor(.white.opacity(0.5))
            }

            Spacer()

            if let savings = recommendation.potentialSavings, savings > 0 {
                Text("-$\(Int(savings))")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.furgSuccess)
            } else if let earnings = recommendation.potentialEarnings, earnings > 0 {
                Text("+$\(Int(earnings))")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.furgMint)
            }

            Image(systemName: "chevron.right")
                .font(.system(size: 12))
                .foregroundColor(.white.opacity(0.3))
        }
        .padding(12)
        .background(Color.white.opacity(0.03))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

struct EmptyRecommendationsView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "sparkles")
                .font(.system(size: 40))
                .foregroundColor(.furgMint.opacity(0.5))

            Text("No recommendations yet")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.white.opacity(0.6))

            Text("Add more financial data to get personalized recommendations")
                .font(.system(size: 13))
                .foregroundColor(.white.opacity(0.4))
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(40)
    }
}

// MARK: - Recommendation Detail View

struct RecommendationDetailView: View {
    let recommendation: Recommendation
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                Color.furgCharcoal.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 24) {
                        // Header
                        VStack(spacing: 12) {
                            Image(systemName: recommendation.icon)
                                .font(.system(size: 50))
                                .foregroundColor(recommendation.color)

                            Text(recommendation.title)
                                .font(.system(size: 24, weight: .bold))
                                .foregroundColor(.white)
                                .multilineTextAlignment(.center)

                            Text(recommendation.subtitle)
                                .font(.system(size: 14))
                                .foregroundColor(.white.opacity(0.6))

                            // Value badge
                            if let savings = recommendation.potentialSavings {
                                HStack {
                                    Image(systemName: "arrow.down.circle.fill")
                                    Text("Save $\(Int(savings))/year")
                                }
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(.furgSuccess)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                                .background(Color.furgSuccess.opacity(0.2))
                                .clipShape(Capsule())
                            } else if let earnings = recommendation.potentialEarnings {
                                HStack {
                                    Image(systemName: "arrow.up.circle.fill")
                                    Text("Earn $\(Int(earnings))/year")
                                }
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(.furgMint)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                                .background(Color.furgMint.opacity(0.2))
                                .clipShape(Capsule())
                            }
                        }
                        .padding(.top, 20)

                        // Description
                        Text(recommendation.description)
                            .font(.system(size: 15))
                            .foregroundColor(.white.opacity(0.8))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)

                        // Pros & Cons
                        HStack(alignment: .top, spacing: 16) {
                            // Pros
                            VStack(alignment: .leading, spacing: 10) {
                                HStack {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(.furgSuccess)
                                    Text("Pros")
                                        .font(.system(size: 14, weight: .semibold))
                                        .foregroundColor(.white.opacity(0.6))
                                }

                                ForEach(recommendation.pros, id: \.self) { pro in
                                    HStack(alignment: .top, spacing: 6) {
                                        Text("•")
                                            .foregroundColor(.furgSuccess)
                                        Text(pro)
                                            .font(.system(size: 13))
                                            .foregroundColor(.white.opacity(0.8))
                                    }
                                }
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)

                            // Cons
                            VStack(alignment: .leading, spacing: 10) {
                                HStack {
                                    Image(systemName: "xmark.circle.fill")
                                        .foregroundColor(.furgWarning)
                                    Text("Cons")
                                        .font(.system(size: 14, weight: .semibold))
                                        .foregroundColor(.white.opacity(0.6))
                                }

                                ForEach(recommendation.cons, id: \.self) { con in
                                    HStack(alignment: .top, spacing: 6) {
                                        Text("•")
                                            .foregroundColor(.furgWarning)
                                        Text(con)
                                            .font(.system(size: 13))
                                            .foregroundColor(.white.opacity(0.8))
                                    }
                                }
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        .padding()
                        .background(Color.white.opacity(0.05))
                        .clipShape(RoundedRectangle(cornerRadius: 14))

                        // Action Items
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Next Steps")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(.white.opacity(0.6))

                            ForEach(recommendation.actionItems) { action in
                                ActionItemRow(action: action)
                            }
                        }

                        // Confidence
                        HStack {
                            Text("Confidence: \(Int(recommendation.confidence * 100))%")
                                .font(.system(size: 12))
                                .foregroundColor(.white.opacity(0.5))

                            Spacer()

                            if let expires = recommendation.expiresAt {
                                Text("Expires: \(formatDate(expires))")
                                    .font(.system(size: 12))
                                    .foregroundColor(.furgWarning)
                            }
                        }

                        Spacer(minLength: 40)
                    }
                    .padding(.horizontal, 20)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                        .foregroundColor(.furgMint)
                }
            }
        }
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, yyyy"
        return formatter.string(from: date)
    }
}

struct ActionItemRow: View {
    let action: ActionItem

    var body: some View {
        Button {
            // Handle action
        } label: {
            HStack(spacing: 12) {
                Image(systemName: iconForAction(action.actionType))
                    .font(.system(size: 14))
                    .foregroundColor(.furgMint)
                    .frame(width: 32, height: 32)
                    .background(Color.furgMint.opacity(0.2))
                    .clipShape(Circle())

                VStack(alignment: .leading, spacing: 2) {
                    Text(action.title)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white)

                    if let description = action.description {
                        Text(description)
                            .font(.system(size: 11))
                            .foregroundColor(.white.opacity(0.5))
                    }
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 12))
                    .foregroundColor(.white.opacity(0.3))
            }
            .padding(12)
            .background(Color.white.opacity(0.05))
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }

    private func iconForAction(_ type: ActionItem.ActionType) -> String {
        switch type {
        case .apply: return "checkmark.circle"
        case .compare: return "arrow.left.arrow.right"
        case .learn: return "book"
        case .call: return "phone"
        case .negotiate: return "text.bubble"
        case .cancel: return "xmark.circle"
        case .switch_: return "arrow.triangle.swap"
        }
    }
}

// MARK: - Card Optimizer View

struct CardOptimizerView: View {
    @StateObject private var cardOptimizer = CardOptimizer.shared
    @Environment(\.dismiss) var dismiss
    @State private var animate = false

    var body: some View {
        NavigationStack {
            ZStack {
                Color.furgCharcoal.ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 24) {
                        // Summary
                        optimizerSummary
                            .opacity(animate ? 1 : 0)
                            .offset(y: animate ? 0 : 20)

                        // Reminders
                        if !cardOptimizer.getRotatingCategoryReminders().isEmpty {
                            remindersSection
                                .opacity(animate ? 1 : 0)
                                .offset(y: animate ? 0 : 20)
                                .animation(.spring(response: 0.6).delay(0.1), value: animate)
                        }

                        // Your Cards
                        yourCardsSection
                            .opacity(animate ? 1 : 0)
                            .offset(y: animate ? 0 : 20)
                            .animation(.spring(response: 0.6).delay(0.15), value: animate)

                        // Category Guide
                        categoryGuideSection
                            .opacity(animate ? 1 : 0)
                            .offset(y: animate ? 0 : 20)
                            .animation(.spring(response: 0.6).delay(0.2), value: animate)

                        Spacer(minLength: 100)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                }
            }
            .navigationTitle("Card Optimizer")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                        .foregroundColor(.furgMint)
                }
            }
            .onAppear {
                withAnimation(.spring(response: 0.6)) {
                    animate = true
                }
            }
        }
    }

    private var optimizerSummary: some View {
        VStack(spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Optimized Value")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.white.opacity(0.6))

                    Text("$\(Int(cardOptimizer.totalOptimizedValue))")
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .foregroundColor(.furgMint)

                    Text("per year using optimal cards")
                        .font(.system(size: 11))
                        .foregroundColor(.white.opacity(0.5))
                }

                Spacer()

                Image(systemName: "creditcard.and.123")
                    .font(.system(size: 40))
                    .foregroundColor(.furgMint.opacity(0.3))
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(LinearGradient(colors: [.purple.opacity(0.2), .furgCharcoal], startPoint: .topLeading, endPoint: .bottomTrailing))
        )
    }

    private var remindersSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "bell.fill")
                    .foregroundColor(.furgWarning)
                Text("Reminders")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white.opacity(0.6))
            }

            ForEach(cardOptimizer.getRotatingCategoryReminders(), id: \.self) { reminder in
                Text(reminder)
                    .font(.system(size: 13))
                    .foregroundColor(.white.opacity(0.8))
                    .padding(12)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.furgWarning.opacity(0.15))
                    .clipShape(RoundedRectangle(cornerRadius: 10))
            }
        }
    }

    private var yourCardsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Your Cards")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white.opacity(0.6))

                Spacer()

                Button {
                    // Add card
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .foregroundColor(.furgMint)
                }
            }

            ForEach(cardOptimizer.userCards) { card in
                CardSummaryRow(card: card)
            }
        }
    }

    private var categoryGuideSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Which Card to Use")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.white.opacity(0.6))

            ForEach(Array(cardOptimizer.categoryRecommendations.values).sorted { $0.estimatedValue > $1.estimatedValue }) { rec in
                CategoryCardGuideRow(recommendation: rec)
            }
        }
    }
}

struct CardSummaryRow: View {
    let card: UserCard

    var body: some View {
        HStack(spacing: 12) {
            RoundedRectangle(cornerRadius: 6)
                .fill(colorFromString(card.cardColor))
                .frame(width: 50, height: 34)
                .overlay(
                    Text("•••• \(card.last4)")
                        .font(.system(size: 8, weight: .bold))
                        .foregroundColor(.white)
                )

            VStack(alignment: .leading, spacing: 2) {
                Text(card.nickname)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white)

                Text(card.issuer)
                    .font(.system(size: 11))
                    .foregroundColor(.white.opacity(0.5))
            }

            Spacer()

            if let primary = card.primaryCategory {
                Text("Best for \(primary)")
                    .font(.system(size: 10))
                    .foregroundColor(.furgMint)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.furgMint.opacity(0.2))
                    .clipShape(Capsule())
            }
        }
        .padding(12)
        .background(Color.white.opacity(0.05))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private func colorFromString(_ colorName: String) -> Color {
        switch colorName.lowercased() {
        case "blue": return .blue
        case "purple": return .purple
        case "cyan": return .cyan
        case "orange": return .orange
        case "green": return .green
        case "red": return .red
        case "gray", "grey": return .gray
        default: return .gray
        }
    }
}

struct CategoryCardGuideRow: View {
    let recommendation: CardUsageRecommendation

    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text(recommendation.category)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white)

                Text("~$\(Int(recommendation.estimatedValue))/mo value")
                    .font(.system(size: 11))
                    .foregroundColor(.white.opacity(0.5))
            }

            Spacer()

            HStack(spacing: 8) {
                Text(recommendation.card.nickname)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.furgMint)

                Text("\(Int(recommendation.reward.multiplier))x")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(.furgCharcoal)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.furgMint)
                    .clipShape(Capsule())
            }
        }
        .padding(12)
        .background(Color.white.opacity(0.05))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

#Preview {
    RecommendationsView()
}
