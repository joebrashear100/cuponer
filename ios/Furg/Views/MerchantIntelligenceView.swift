//
//  MerchantIntelligenceView.swift
//  Furg
//
//  Created for radical life integration - merchant intelligence display
//

import SwiftUI

struct MerchantIntelligenceView: View {
    @StateObject private var merchantManager = MerchantIntelligenceManager.shared
    @State private var searchText = ""
    @State private var selectedCategory: MerchantCategory?
    @State private var selectedMerchant: MerchantProfile?
    @State private var showingMerchantDetail = false

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Search bar
                    SearchBarView(text: $searchText, placeholder: "Search stores...")

                    // Category filter
                    CategoryFilterView(selectedCategory: $selectedCategory)

                    // Active insights
                    if !merchantManager.activeInsights.isEmpty && searchText.isEmpty {
                        InsightsSection(insights: merchantManager.activeInsights)
                    }

                    // Favorite merchants
                    if !merchantManager.favoriteMerchants.isEmpty && searchText.isEmpty && selectedCategory == nil {
                        FavoriteMerchantsSection(
                            merchants: merchantManager.favoriteMerchants,
                            onSelect: { merchant in
                                selectedMerchant = merchant
                                showingMerchantDetail = true
                            }
                        )
                    }

                    // Recent merchants
                    if !merchantManager.recentMerchants.isEmpty && searchText.isEmpty && selectedCategory == nil {
                        RecentMerchantsSection(
                            merchants: merchantManager.recentMerchants,
                            onSelect: { merchant in
                                selectedMerchant = merchant
                                showingMerchantDetail = true
                            }
                        )
                    }

                    // All merchants or filtered
                    MerchantsListSection(
                        merchants: filteredMerchants,
                        onSelect: { merchant in
                            selectedMerchant = merchant
                            showingMerchantDetail = true
                        }
                    )
                }
                .padding()
            }
            .navigationTitle("Store Intelligence")
            .onAppear {
                merchantManager.generateAllInsights()
            }
            .sheet(isPresented: $showingMerchantDetail) {
                if let merchant = selectedMerchant {
                    MerchantDetailView(merchant: merchant)
                }
            }
        }
    }

    private var filteredMerchants: [MerchantProfile] {
        var merchants = Array(merchantManager.merchantProfiles.values)

        if let category = selectedCategory {
            merchants = merchants.filter { $0.category == category }
        }

        if !searchText.isEmpty {
            merchants = merchants.filter {
                $0.name.localizedCaseInsensitiveContains(searchText) ||
                $0.category.rawValue.localizedCaseInsensitiveContains(searchText)
            }
        }

        return merchants.sorted { $0.name < $1.name }
    }
}

// MARK: - Search Bar

struct SearchBarView: View {
    @Binding var text: String
    let placeholder: String

    var body: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.secondary)

            TextField(placeholder, text: $text)
                .textFieldStyle(.plain)

            if !text.isEmpty {
                Button(action: { text = "" }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(12)
        .background(Color(.systemGray6))
        .cornerRadius(10)
    }
}

// MARK: - Category Filter

struct CategoryFilterView: View {
    @Binding var selectedCategory: MerchantCategory?

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                MerchantCategoryChip(
                    title: "All",
                    isSelected: selectedCategory == nil,
                    action: { selectedCategory = nil }
                )

                ForEach([MerchantCategory.grocery, .electronics, .department, .pharmacy, .homeGoods, .clothing], id: \.self) { category in
                    MerchantCategoryChip(
                        title: category.rawValue,
                        isSelected: selectedCategory == category,
                        action: { selectedCategory = category }
                    )
                }
            }
        }
    }
}

struct MerchantCategoryChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline)
                .fontWeight(isSelected ? .semibold : .regular)
                .foregroundColor(isSelected ? .white : .primary)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(isSelected ? Color.blue : Color(.systemGray6))
                .cornerRadius(20)
        }
    }
}

// MARK: - Insights Section

struct InsightsSection: View {
    let insights: [MerchantInsight]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "lightbulb.fill")
                    .foregroundColor(.yellow)
                Text("Smart Insights")
                    .font(.headline)
                Spacer()
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(insights.prefix(5)) { insight in
                        MerchantInsightCard(insight: insight)
                    }
                }
            }
        }
    }
}

struct MerchantInsightCard: View {
    let insight: MerchantInsight

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: insightIcon(for: insight.type))
                    .foregroundColor(insightColor(for: insight.type))
                Text(insight.merchantName)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Text(insight.title)
                .font(.subheadline)
                .fontWeight(.semibold)
                .lineLimit(1)

            Text(insight.description)
                .font(.caption)
                .foregroundColor(.secondary)
                .lineLimit(2)

            if let savings = insight.savings {
                Text("Avg. \(Int(savings))% savings")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.green)
            }
        }
        .padding(12)
        .frame(width: 200)
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }

    private func insightIcon(for type: InsightType) -> String {
        switch type {
        case .priceDrop: return "arrow.down.circle.fill"
        case .saleAlert: return "tag.fill"
        case .returnDeadline: return "clock.fill"
        case .priceMatchOpportunity: return "arrow.left.arrow.right.circle.fill"
        case .bestTimeToBuy: return "calendar"
        case .loyaltyReward: return "star.fill"
        case .crowdAlert: return "person.3.fill"
        case .newCoupon: return "ticket.fill"
        case .seasonalDeal: return "leaf.fill"
        case .spendingPattern: return "chart.bar.fill"
        }
    }

    private func insightColor(for type: InsightType) -> Color {
        switch type {
        case .priceDrop, .saleAlert, .newCoupon, .seasonalDeal: return .green
        case .returnDeadline: return .red
        case .priceMatchOpportunity: return .blue
        case .bestTimeToBuy, .crowdAlert: return .orange
        case .loyaltyReward: return .yellow
        case .spendingPattern: return .purple
        }
    }
}

// MARK: - Favorite Merchants

struct FavoriteMerchantsSection: View {
    let merchants: [MerchantProfile]
    let onSelect: (MerchantProfile) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "heart.fill")
                    .foregroundColor(.red)
                Text("Favorites")
                    .font(.headline)
                Spacer()
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(merchants) { merchant in
                        MerchantMiniCard(merchant: merchant)
                            .onTapGesture { onSelect(merchant) }
                    }
                }
            }
        }
    }
}

struct MerchantMiniCard: View {
    let merchant: MerchantProfile

    var body: some View {
        VStack(spacing: 8) {
            Circle()
                .fill(Color.blue.opacity(0.2))
                .frame(width: 50, height: 50)
                .overlay(
                    Text(String(merchant.name.prefix(1)))
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.blue)
                )

            Text(merchant.name)
                .font(.caption)
                .lineLimit(1)
        }
        .frame(width: 70)
    }
}

// MARK: - Recent Merchants

struct RecentMerchantsSection: View {
    let merchants: [MerchantProfile]
    let onSelect: (MerchantProfile) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "clock")
                    .foregroundColor(.secondary)
                Text("Recent")
                    .font(.headline)
                Spacer()
            }

            ForEach(merchants.prefix(3)) { merchant in
                MerchantRowCard(merchant: merchant)
                    .onTapGesture { onSelect(merchant) }
            }
        }
    }
}

struct MerchantRowCard: View {
    let merchant: MerchantProfile

    var body: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(MerchantCategoryColors.color(for: merchant.category.rawValue).opacity(0.2))
                .frame(width: 44, height: 44)
                .overlay(
                    Text(String(merchant.name.prefix(1)))
                        .font(.headline)
                        .foregroundColor(MerchantCategoryColors.color(for: merchant.category.rawValue))
                )

            VStack(alignment: .leading, spacing: 4) {
                Text(merchant.name)
                    .font(.subheadline)
                    .fontWeight(.medium)
                Text(merchant.category.rawValue)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            // Price level indicator
            HStack(spacing: 2) {
                ForEach(0..<4) { index in
                    Text("$")
                        .font(.caption)
                        .foregroundColor(index < merchant.priceLevel ? .primary : .secondary.opacity(0.3))
                }
            }

            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(12)
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

// MARK: - Merchants List

struct MerchantsListSection: View {
    let merchants: [MerchantProfile]
    let onSelect: (MerchantProfile) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("All Stores")
                .font(.headline)

            ForEach(merchants) { merchant in
                MerchantListRow(merchant: merchant)
                    .onTapGesture { onSelect(merchant) }
            }
        }
    }
}

struct MerchantListRow: View {
    let merchant: MerchantProfile
    @StateObject private var manager = MerchantIntelligenceManager.shared

    var body: some View {
        HStack(spacing: 12) {
            // Logo placeholder
            Circle()
                .fill(MerchantCategoryColors.color(for: merchant.category.rawValue).opacity(0.2))
                .frame(width: 50, height: 50)
                .overlay(
                    Text(String(merchant.name.prefix(1)))
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(MerchantCategoryColors.color(for: merchant.category.rawValue))
                )

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(merchant.name)
                        .font(.headline)

                    if manager.isFavorite(merchantId: merchant.id) {
                        Image(systemName: "heart.fill")
                            .font(.caption)
                            .foregroundColor(.red)
                    }
                }

                Text(merchant.category.rawValue)
                    .font(.caption)
                    .foregroundColor(.secondary)

                // Key features
                HStack(spacing: 8) {
                    if merchant.policies.returnPolicy.standardDays > 30 {
                        FeatureBadge(text: "\(merchant.policies.returnPolicy.standardDays)d returns", color: .green)
                    }
                    if merchant.policies.priceMatch?.enabled == true {
                        FeatureBadge(text: "Price Match", color: .blue)
                    }
                    if merchant.loyaltyInfo != nil {
                        FeatureBadge(text: "Rewards", color: .purple)
                    }
                }
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                // Rating
                HStack(spacing: 2) {
                    Image(systemName: "star.fill")
                        .font(.caption)
                        .foregroundColor(.yellow)
                    Text(String(format: "%.1f", merchant.rating))
                        .font(.caption)
                        .fontWeight(.medium)
                }

                // Price level
                HStack(spacing: 1) {
                    ForEach(0..<4) { index in
                        Text("$")
                            .font(.caption2)
                            .foregroundColor(index < merchant.priceLevel ? .primary : .secondary.opacity(0.3))
                    }
                }
            }

            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(12)
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

struct FeatureBadge: View {
    let text: String
    let color: Color

    var body: some View {
        Text(text)
            .font(.caption2)
            .foregroundColor(color)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(color.opacity(0.15))
            .cornerRadius(4)
    }
}

// MARK: - Merchant Detail View

struct MerchantDetailView: View {
    let merchant: MerchantProfile
    @StateObject private var manager = MerchantIntelligenceManager.shared
    @Environment(\.dismiss) private var dismiss
    @State private var selectedTab = 0

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 0) {
                    // Header
                    MerchantHeaderView(merchant: merchant)

                    // Tab picker
                    Picker("", selection: $selectedTab) {
                        Text("Policies").tag(0)
                        Text("Pricing").tag(1)
                        Text("Tips").tag(2)
                    }
                    .pickerStyle(.segmented)
                    .padding()

                    // Tab content
                    switch selectedTab {
                    case 0:
                        PoliciesTabView(merchant: merchant)
                    case 1:
                        PricingTabView(merchant: merchant)
                    case 2:
                        TipsTabView(merchant: merchant)
                    default:
                        EmptyView()
                    }
                }
            }
            .navigationTitle(merchant.name)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done") { dismiss() }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        manager.toggleFavorite(merchantId: merchant.id)
                    }) {
                        Image(systemName: manager.isFavorite(merchantId: merchant.id) ? "heart.fill" : "heart")
                            .foregroundColor(.red)
                    }
                }
            }
        }
    }
}

struct MerchantHeaderView: View {
    let merchant: MerchantProfile

    var body: some View {
        VStack(spacing: 16) {
            // Logo
            Circle()
                .fill(Color.blue.opacity(0.1))
                .frame(width: 80, height: 80)
                .overlay(
                    Text(String(merchant.name.prefix(1)))
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.blue)
                )

            // Name and category
            VStack(spacing: 4) {
                Text(merchant.name)
                    .font(.title2)
                    .fontWeight(.bold)

                Text(merchant.category.rawValue)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }

            // Quick stats
            HStack(spacing: 24) {
                VStack {
                    HStack(spacing: 2) {
                        Image(systemName: "star.fill")
                            .foregroundColor(.yellow)
                        Text(String(format: "%.1f", merchant.rating))
                            .fontWeight(.bold)
                    }
                    Text("\(merchant.reviewCount / 1000)k reviews")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                VStack {
                    HStack(spacing: 1) {
                        ForEach(0..<4) { index in
                            Text("$")
                                .fontWeight(index < merchant.priceLevel ? .bold : .regular)
                                .foregroundColor(index < merchant.priceLevel ? .primary : .secondary.opacity(0.3))
                        }
                    }
                    Text("Price Level")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                if let hours = merchant.operatingHours {
                    VStack {
                        Image(systemName: hours.isOpen24Hours ? "clock.badge.checkmark" : "clock")
                            .foregroundColor(.green)
                        Text(hours.isOpen24Hours ? "24 Hours" : "See Hours")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }

            // User stats if available
            if let stats = merchant.userStats {
                HStack(spacing: 20) {
                    UserStatItem(title: "Total Spent", value: CurrencyFormatter.formatCompact(stats.totalSpent))
                    UserStatItem(title: "Visits", value: "\(stats.visitCount)")
                    UserStatItem(title: "Avg. Trip", value: CurrencyFormatter.formatCompact(stats.averageTransaction))
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)
                .padding(.horizontal)
            }
        }
        .padding()
    }
}

struct UserStatItem: View {
    let title: String
    let value: String

    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.headline)
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
}

// MARK: - Policies Tab

struct PoliciesTabView: View {
    let merchant: MerchantProfile

    var body: some View {
        VStack(spacing: 16) {
            // Return Policy
            PolicyCard(
                icon: "arrow.uturn.backward.circle.fill",
                iconColor: .blue,
                title: "Return Policy",
                content: {
                    VStack(alignment: .leading, spacing: 8) {
                        PolicyRow(label: "Window", value: merchant.policies.returnPolicy.standardDays == -1 ? "Unlimited" : "\(merchant.policies.returnPolicy.standardDays) days")

                        if let extended = merchant.policies.returnPolicy.extendedHolidayDays {
                            PolicyRow(label: "Holiday Extended", value: "\(extended) days")
                        }

                        PolicyRow(label: "Receipt Required", value: merchant.policies.returnPolicy.receiptRequired ? "Yes" : "No")
                        PolicyRow(label: "Original Package", value: merchant.policies.returnPolicy.originalPackagingRequired ? "Required" : "Not Required")

                        if let fee = merchant.policies.returnPolicy.restockingFee {
                            PolicyRow(label: "Restocking Fee", value: "\(Int(fee))%")
                        }

                        if !merchant.policies.returnPolicy.exceptions.isEmpty {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Exceptions:")
                                    .font(.caption)
                                    .fontWeight(.medium)
                                ForEach(merchant.policies.returnPolicy.exceptions, id: \.self) { exception in
                                    Text("• \(exception)")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                            .padding(.top, 4)
                        }

                        HStack(spacing: 8) {
                            ForEach(merchant.policies.returnPolicy.returnMethods, id: \.rawValue) { method in
                                Text(method.rawValue)
                                    .font(.caption2)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(Color.blue.opacity(0.1))
                                    .cornerRadius(4)
                            }
                        }
                        .padding(.top, 4)
                    }
                }
            )

            // Price Match Policy
            if let priceMatch = merchant.policies.priceMatch {
                PolicyCard(
                    icon: "arrow.left.arrow.right.circle.fill",
                    iconColor: .green,
                    title: "Price Match",
                    content: {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Image(systemName: priceMatch.enabled ? "checkmark.circle.fill" : "xmark.circle.fill")
                                    .foregroundColor(priceMatch.enabled ? .green : .red)
                                Text(priceMatch.enabled ? "Price matching available" : "No price matching")
                                    .fontWeight(.medium)
                            }

                            if priceMatch.enabled {
                                if !priceMatch.competitorsMatched.isEmpty {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text("Matched retailers:")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                        Text(priceMatch.competitorsMatched.joined(separator: ", "))
                                            .font(.caption)
                                    }
                                }

                                if let timeLimit = priceMatch.timeLimit, timeLimit > 0 {
                                    PolicyRow(label: "Time Limit", value: "\(timeLimit) days after purchase")
                                }

                                if let beat = priceMatch.beatByPercent {
                                    HStack {
                                        Image(systemName: "star.fill")
                                            .foregroundColor(.yellow)
                                            .font(.caption)
                                        Text("Beats competitor price by \(Int(beat))%!")
                                            .font(.caption)
                                            .fontWeight(.medium)
                                    }
                                }
                            }
                        }
                    }
                )
            }

            // Special Policies
            if !merchant.policies.specialPolicies.isEmpty {
                PolicyCard(
                    icon: "star.circle.fill",
                    iconColor: .yellow,
                    title: "Special Policies",
                    content: {
                        VStack(alignment: .leading, spacing: 6) {
                            ForEach(merchant.policies.specialPolicies, id: \.self) { policy in
                                HStack(alignment: .top) {
                                    Image(systemName: "checkmark")
                                        .font(.caption)
                                        .foregroundColor(.green)
                                    Text(policy)
                                        .font(.caption)
                                }
                            }
                        }
                    }
                )
            }
        }
        .padding()
    }
}

struct PolicyCard<Content: View>: View {
    let icon: String
    let iconColor: Color
    let title: String
    @ViewBuilder let content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(iconColor)
                Text(title)
                    .font(.headline)
            }

            content()
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

struct PolicyRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack {
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .font(.caption)
                .fontWeight(.medium)
        }
    }
}

// MARK: - Pricing Tab

struct PricingTabView: View {
    let merchant: MerchantProfile

    var body: some View {
        VStack(spacing: 16) {
            // Best Time to Buy
            if let bestTime = merchant.priceIntelligence.bestTimeToBuy.dayOfWeek.first {
                PricingCard(
                    icon: "calendar",
                    iconColor: .blue,
                    title: "Best Day to Shop",
                    content: {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text(bestTime.day)
                                    .font(.title2)
                                    .fontWeight(.bold)
                                Spacer()
                                Text("\(Int(bestTime.savings))% more savings")
                                    .font(.caption)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(Color.green.opacity(0.2))
                                    .foregroundColor(.green)
                                    .cornerRadius(4)
                            }
                            Text(bestTime.reason)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                )
            }

            // Upcoming Sales
            if !merchant.priceIntelligence.saleFrequency.majorSaleEvents.isEmpty {
                PricingCard(
                    icon: "tag.fill",
                    iconColor: .red,
                    title: "Major Sales Events",
                    content: {
                        VStack(spacing: 10) {
                            ForEach(merchant.priceIntelligence.saleFrequency.majorSaleEvents, id: \.name) { sale in
                                HStack {
                                    VStack(alignment: .leading) {
                                        Text(sale.name)
                                            .font(.subheadline)
                                            .fontWeight(.medium)
                                        Text(sale.popularCategories.joined(separator: ", "))
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                    Spacer()
                                    Text("\(Int(sale.averageDiscount))% off")
                                        .font(.caption)
                                        .fontWeight(.bold)
                                        .foregroundColor(.green)
                                }
                            }
                        }
                    }
                )
            }

            // Coupon Info
            let couponInfo = merchant.priceIntelligence.couponAvailability
            PricingCard(
                icon: "ticket.fill",
                iconColor: .purple,
                title: "Coupons & Savings",
                content: {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Avg. Coupon Savings")
                            Spacer()
                            Text("\(Int(couponInfo.averageSavings))%")
                                .fontWeight(.bold)
                                .foregroundColor(.green)
                        }

                        HStack(spacing: 8) {
                            if couponInfo.digitalCoupons {
                                CouponBadge(text: "Digital", icon: "iphone")
                            }
                            if couponInfo.paperCoupons {
                                CouponBadge(text: "Paper", icon: "doc.text")
                            }
                            if couponInfo.stackable {
                                CouponBadge(text: "Stackable", icon: "square.stack.3d.up")
                            }
                        }

                        if !couponInfo.couponSources.isEmpty {
                            Text("Find coupons: \(couponInfo.couponSources.joined(separator: ", "))")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            )

            // Loyalty Program
            if let loyalty = merchant.loyaltyInfo {
                PricingCard(
                    icon: "star.fill",
                    iconColor: .yellow,
                    title: loyalty.programName,
                    content: {
                        VStack(alignment: .leading, spacing: 8) {
                            if loyalty.pointsPerDollar > 0 {
                                HStack {
                                    Text("Earn")
                                    Text("\(Int(loyalty.pointsPerDollar)) pts/$1")
                                        .fontWeight(.bold)
                                }
                            }

                            if let gasDiscount = loyalty.gasDiscount {
                                HStack {
                                    Image(systemName: "fuelpump.fill")
                                        .foregroundColor(.orange)
                                    Text("\(Int(gasDiscount))¢/gal fuel discount")
                                        .font(.caption)
                                }
                            }

                            if !loyalty.specialPerks.isEmpty {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Perks:")
                                        .font(.caption)
                                        .fontWeight(.medium)
                                    ForEach(loyalty.specialPerks.prefix(4), id: \.self) { perk in
                                        HStack {
                                            Image(systemName: "checkmark")
                                                .font(.caption2)
                                                .foregroundColor(.green)
                                            Text(perk)
                                                .font(.caption)
                                        }
                                    }
                                }
                            }
                        }
                    }
                )
            }
        }
        .padding()
    }
}

struct PricingCard<Content: View>: View {
    let icon: String
    let iconColor: Color
    let title: String
    @ViewBuilder let content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(iconColor)
                Text(title)
                    .font(.headline)
            }

            content()
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

struct CouponBadge: View {
    let text: String
    let icon: String

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.caption2)
            Text(text)
                .font(.caption2)
        }
        .foregroundColor(.purple)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(Color.purple.opacity(0.1))
        .cornerRadius(4)
    }
}

// MARK: - Tips Tab

struct TipsTabView: View {
    let merchant: MerchantProfile
    @StateObject private var manager = MerchantIntelligenceManager.shared

    var body: some View {
        VStack(spacing: 16) {
            // Smart insights for this merchant
            let insights = manager.generateInsights(for: merchant.id)

            ForEach(insights) { insight in
                TipCard(insight: insight)
            }

            // Payment tips
            if !merchant.paymentOptions.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Image(systemName: "creditcard.fill")
                            .foregroundColor(.blue)
                        Text("Payment Tips")
                            .font(.headline)
                    }

                    ForEach(merchant.paymentOptions.filter { $0.bonusRewards != nil || $0.financing != nil }, id: \.type) { option in
                        HStack {
                            Text(option.type.rawValue)
                                .font(.subheadline)
                            Spacer()
                            if let bonus = option.bonusRewards {
                                Text("\(Int(bonus))% bonus")
                                    .font(.caption)
                                    .foregroundColor(.green)
                            }
                            if let financing = option.financing, financing.interestFree {
                                Text("\(financing.months)mo 0% APR")
                                    .font(.caption)
                                    .foregroundColor(.blue)
                            }
                        }
                    }
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)
            }

            // Crowd tips
            if let crowd = merchant.crowdData {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Image(systemName: "person.3.fill")
                            .foregroundColor(.orange)
                        Text("Avoid the Crowds")
                            .font(.headline)
                    }

                    HStack {
                        Text("Best time to visit:")
                        Spacer()
                        Text(crowd.bestTimeToVisit)
                            .fontWeight(.medium)
                            .foregroundColor(.green)
                    }

                    HStack {
                        Text("Avg. checkout wait:")
                        Spacer()
                        Text("\(crowd.averageWaitTime) min")
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Quiet hours: \(crowd.quietHours.joined(separator: ", "))")
                            .font(.caption)
                            .foregroundColor(.green)
                        Text("Busy hours: \(crowd.peakHours.joined(separator: ", "))")
                            .font(.caption)
                            .foregroundColor(.red)
                    }
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)
            }

            // Related merchants for price comparison
            let related = manager.getRelatedMerchants(merchantId: merchant.id)
            if !related.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Image(systemName: "chart.bar.fill")
                            .foregroundColor(.purple)
                        Text("Price Comparisons")
                            .font(.headline)
                    }

                    ForEach(related.filter { $0.relationship == "competitor" }, id: \.merchantId) { related in
                        HStack {
                            Text(related.name)
                                .font(.subheadline)
                            Spacer()
                            Text(related.priceComparison == "cheaper" ? "Cheaper" : related.priceComparison == "more_expensive" ? "More Expensive" : "Similar")
                                .font(.caption)
                                .foregroundColor(related.priceComparison == "cheaper" ? .green : related.priceComparison == "more_expensive" ? .red : .secondary)

                            if related.averagePriceDiff > 0 {
                                Text("(\(Int(related.averagePriceDiff))%)")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)
            }
        }
        .padding()
    }
}

struct TipCard: View {
    let insight: MerchantInsight

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: tipIcon(for: insight.type))
                .foregroundColor(tipColor(for: insight.type))
                .font(.title2)

            VStack(alignment: .leading, spacing: 4) {
                Text(insight.title)
                    .font(.subheadline)
                    .fontWeight(.semibold)

                Text(insight.description)
                    .font(.caption)
                    .foregroundColor(.secondary)

                if let savings = insight.savings {
                    Text("Potential: \(Int(savings))% savings")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.green)
                }
            }

            Spacer()
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }

    private func tipIcon(for type: InsightType) -> String {
        switch type {
        case .priceDrop: return "arrow.down.circle.fill"
        case .saleAlert: return "tag.fill"
        case .returnDeadline: return "clock.fill"
        case .priceMatchOpportunity: return "arrow.left.arrow.right.circle.fill"
        case .bestTimeToBuy: return "calendar"
        case .loyaltyReward: return "star.fill"
        case .crowdAlert: return "person.3.fill"
        case .newCoupon: return "ticket.fill"
        case .seasonalDeal: return "leaf.fill"
        case .spendingPattern: return "chart.bar.fill"
        }
    }

    private func tipColor(for type: InsightType) -> Color {
        switch type {
        case .priceDrop, .saleAlert, .newCoupon, .seasonalDeal: return .green
        case .returnDeadline: return .red
        case .priceMatchOpportunity: return .blue
        case .bestTimeToBuy, .crowdAlert: return .orange
        case .loyaltyReward: return .yellow
        case .spendingPattern: return .purple
        }
    }
}

#Preview {
    MerchantIntelligenceView()
}
