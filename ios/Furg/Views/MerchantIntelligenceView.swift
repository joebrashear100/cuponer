import SwiftUI

struct MerchantIntelligenceView: View {
    @StateObject private var merchantManager = MerchantIntelligenceManager.shared
    @EnvironmentObject var financeManager: FinanceManager
    @State private var searchText = ""
    @State private var selectedMerchant: MerchantProfile?
    @State private var selectedCategory: String?

    var filteredMerchants: [MerchantProfile] {
        let allMerchants = merchantManager.recentMerchants
        var filtered = allMerchants

        if !searchText.isEmpty {
            filtered = filtered.filter { merchant in
                merchant.name.lowercased().contains(searchText.lowercased()) ||
                merchant.category.rawValue.lowercased().contains(searchText.lowercased())
            }
        }

        if let category = selectedCategory {
            filtered = filtered.filter { $0.category.rawValue == category }
        }

        return filtered.sorted { ($0.userStats?.visitCount ?? 0) > ($1.userStats?.visitCount ?? 0) }
    }

    var categories: [String] {
        Array(Set(merchantManager.recentMerchants.map { $0.category.rawValue })).sorted()
    }

    var topInsights: [MerchantInsight] {
        merchantManager.activeInsights.sorted { $0.priority > $1.priority }.prefix(3).map { $0 }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.furgCharcoal.ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 20) {
                        // Header
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Merchant Intelligence")
                                .font(.system(size: 28, weight: .bold))
                                .foregroundColor(.white)

                            Text("Insights about where you spend")
                                .font(.system(size: 14))
                                .foregroundColor(.white.opacity(0.6))
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 20)
                        .padding(.top, 16)

                        // Search bar
                        HStack(spacing: 10) {
                            Image(systemName: "magnifyingglass")
                                .foregroundColor(.white.opacity(0.5))

                            TextField("Search merchants...", text: $searchText)
                                .foregroundColor(.white)
                        }
                        .padding(12)
                        .background(Color.white.opacity(0.1))
                        .cornerRadius(10)
                        .padding(.horizontal, 20)

                        // Category filter
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 10) {
                                MerchantFilterChip(
                                    label: "All",
                                    isSelected: selectedCategory == nil,
                                    action: { selectedCategory = nil }
                                )

                                ForEach(categories, id: \.self) { category in
                                    MerchantFilterChip(
                                        label: category,
                                        isSelected: selectedCategory == category,
                                        action: { selectedCategory = category }
                                    )
                                }
                            }
                            .padding(.horizontal, 20)
                        }

                        // Top insights section
                        if !topInsights.isEmpty {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Top Insights")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 20)

                                ForEach(topInsights) { insight in
                                    MerchantInsightCard(insight: insight)
                                        .padding(.horizontal, 20)
                                }
                            }
                        }

                        // Merchants list
                        if filteredMerchants.isEmpty {
                            VStack(spacing: 12) {
                                Image(systemName: "magnifyingglass")
                                    .font(.system(size: 32))
                                    .foregroundColor(.white.opacity(0.3))

                                Text("No merchants found")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(.white)

                                Text("Try adjusting your search")
                                    .font(.system(size: 13))
                                    .foregroundColor(.white.opacity(0.5))
                            }
                            .padding(40)
                        } else {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Your Merchants")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 20)

                                ForEach(filteredMerchants) { merchant in
                                    NavigationLink(destination: MerchantDetailView(merchant: merchant)) {
                                        MerchantDetailRow(merchant: merchant)
                                    }
                                    .padding(.horizontal, 20)
                                }
                            }
                        }

                        Spacer(minLength: 40)
                    }
                }
            }
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

// MARK: - Supporting Views

struct MerchantFilterChip: View {
    let label: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(label)
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(isSelected ? .furgCharcoal : .white)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(isSelected ? Color.furgMint : Color.white.opacity(0.1))
                .cornerRadius(20)
        }
    }
}

struct MerchantInsightCard: View {
    let insight: MerchantInsight

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 8) {
                    Text(insight.title)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.white)

                    Text(insight.description)
                        .font(.system(size: 12))
                        .foregroundColor(.white.opacity(0.6))
                }

                Spacer()

                Image(systemName: "lightbulb.fill")
                    .foregroundColor(.furgWarning)
            }

            if insight.actionable, let action = insight.action {
                HStack {
                    Image(systemName: "arrowtriangle.up.fill")
                        .font(.system(size: 10))
                        .foregroundColor(.furgSuccess)

                    Text(action)
                        .font(.system(size: 12))
                        .foregroundColor(.furgSuccess)

                    Spacer()
                }
            }
        }
        .padding(14)
        .background(Color.white.opacity(0.05))
        .cornerRadius(12)
    }
}

struct MerchantDetailRow: View {
    let merchant: MerchantProfile

    var body: some View {
        HStack(spacing: 14) {
            // Merchant icon/initial
            Circle()
                .fill(Color.furgMint.opacity(0.2))
                .frame(width: 44, height: 44)
                .overlay(
                    Text(String(merchant.name.prefix(1)))
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.furgMint)
                )

            VStack(alignment: .leading, spacing: 4) {
                Text(merchant.name)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(.white)

                HStack(spacing: 8) {
                    Text(merchant.category.rawValue)
                        .font(.system(size: 12))
                        .foregroundColor(.white.opacity(0.5))

                    Circle()
                        .fill(Color.white.opacity(0.2))
                        .frame(width: 3, height: 3)

                    Text("\(merchant.userStats?.visitCount ?? 0) visits")
                        .font(.system(size: 12))
                        .foregroundColor(.white.opacity(0.5))
                }
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                Text("$\(Int(merchant.userStats?.totalSpent ?? 0))")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.furgMint)

                Text("avg $\(Int(merchant.userStats?.averageTransaction ?? 0))")
                    .font(.system(size: 11))
                    .foregroundColor(.white.opacity(0.5))
            }
        }
        .padding(14)
        .background(Color.white.opacity(0.05))
        .cornerRadius(12)
    }
}

#Preview {
    MerchantIntelligenceView()
        .environmentObject(FinanceManager())
}
