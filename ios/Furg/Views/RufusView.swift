//
//  RufusView.swift
//  Furg
//
//  Rufus - Your Amazon Shopping AI Sidekick
//  Find deals, track prices, save money
//

import SwiftUI

struct RufusView: View {
    @StateObject private var rufusManager = RufusManager()
    @State private var selectedTab = 0
    @State private var showSearch = false
    @State private var searchText = ""

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Rufus Header
                    rufusHeader

                    // Quick Stats
                    if let stats = rufusManager.stats {
                        statsCards(stats)
                    }

                    // Tab Selection
                    tabPicker

                    // Content based on selected tab
                    switch selectedTab {
                    case 0:
                        dealsSection
                    case 1:
                        trackedSection
                    case 2:
                        savedSection
                    default:
                        dealsSection
                    }
                }
                .padding()
            }
            .navigationTitle("Rufus")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showSearch = true
                    } label: {
                        Image(systemName: "magnifyingglass")
                    }
                }
            }
            .sheet(isPresented: $showSearch) {
                RufusSearchView(rufusManager: rufusManager)
            }
            .refreshable {
                await rufusManager.loadHome()
            }
            .task {
                await rufusManager.loadHome()
                await rufusManager.loadTrackedProducts()
                await rufusManager.loadDeals()
            }
        }
    }

    // MARK: - Header

    private var rufusHeader: some View {
        VStack(spacing: 12) {
            // Rufus mascot/icon
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color.orange, Color.orange.opacity(0.7)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 80, height: 80)

                Image(systemName: "dog.fill")
                    .font(.system(size: 40))
                    .foregroundStyle(.white)
            }

            Text(rufusManager.greeting)
                .font(.headline)
                .multilineTextAlignment(.center)

            if !rufusManager.tip.isEmpty {
                Text(rufusManager.tip)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
        }
        .padding(.vertical)
    }

    // MARK: - Stats Cards

    private func statsCards(_ stats: RufusStats) -> some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                StatCard(
                    icon: "eye",
                    value: "\(stats.productsTracked)",
                    label: "Tracking",
                    color: .blue
                )

                StatCard(
                    icon: "arrow.down.circle.fill",
                    value: "\(stats.priceDropsFound)",
                    label: "Price Drops",
                    color: .green
                )

                StatCard(
                    icon: "dollarsign.circle.fill",
                    value: stats.formattedPotentialSavings,
                    label: "Potential Savings",
                    color: .orange
                )

                StatCard(
                    icon: "bookmark.fill",
                    value: "\(stats.savedDeals)",
                    label: "Saved Deals",
                    color: .purple
                )
            }
        }
    }

    // MARK: - Tab Picker

    private var tabPicker: some View {
        Picker("Section", selection: $selectedTab) {
            Text("Deals").tag(0)
            Text("Tracking").tag(1)
            Text("Saved").tag(2)
        }
        .pickerStyle(.segmented)
    }

    // MARK: - Deals Section

    private var dealsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Price drops alert
            if rufusManager.hasPriceDrops {
                priceDropsAlert
            }

            // Suggested deals
            if !rufusManager.suggestedDeals.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Hot Deals")
                        .font(.headline)

                    ForEach(rufusManager.suggestedDeals) { deal in
                        RufusDealCard(deal: deal, onTrack: {
                            Task {
                                await rufusManager.trackProduct(asin: deal.product.asin)
                            }
                        }, onSave: {
                            Task {
                                await rufusManager.saveDeal(deal.product, dealType: deal.dealType)
                            }
                        })
                    }
                }
            }

            // Browse by category
            VStack(alignment: .leading, spacing: 12) {
                Text("Browse Categories")
                    .font(.headline)

                LazyVGrid(columns: [GridItem(.adaptive(minimum: 100))], spacing: 12) {
                    ForEach(RufusCategory.allCases.filter { $0 != .all }, id: \.self) { category in
                        CategoryButton(category: category) {
                            Task {
                                await rufusManager.loadDeals(categories: [category])
                            }
                        }
                    }
                }
            }

            // Current deals
            if rufusManager.hasDeals {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Current Deals (\(rufusManager.currentDeals.count))")
                        .font(.headline)

                    ForEach(rufusManager.currentDeals) { deal in
                        RufusDealCard(deal: deal, onTrack: {
                            Task {
                                await rufusManager.trackProduct(asin: deal.product.asin)
                            }
                        }, onSave: {
                            Task {
                                await rufusManager.saveDeal(deal.product, dealType: deal.dealType)
                            }
                        })
                    }
                }
            }

            // Empty state
            if rufusManager.suggestedDeals.isEmpty && rufusManager.currentDeals.isEmpty && !rufusManager.isLoading {
                emptyDealsState
            }
        }
    }

    // MARK: - Price Drops Alert

    private var priceDropsAlert: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "bell.badge.fill")
                    .foregroundStyle(.green)
                Text("Price Drops Detected!")
                    .font(.headline)
                Spacer()
            }

            ForEach(rufusManager.priceDrops) { drop in
                HStack {
                    AsyncImage(url: URL(string: drop.imageUrl ?? "")) { image in
                        image.resizable().aspectRatio(contentMode: .fit)
                    } placeholder: {
                        Color.gray.opacity(0.2)
                    }
                    .frame(width: 50, height: 50)
                    .cornerRadius(8)

                    VStack(alignment: .leading) {
                        Text(drop.title)
                            .font(.subheadline)
                            .lineLimit(1)

                        HStack {
                            Text(String(format: "$%.2f", drop.currentPrice))
                                .font(.headline)
                                .foregroundStyle(.green)

                            Text("-$\(String(format: "%.2f", drop.savings))")
                                .font(.caption)
                                .foregroundStyle(.green)
                        }
                    }

                    Spacer()
                }
                .padding(.vertical, 4)
            }
        }
        .padding()
        .background(Color.green.opacity(0.1))
        .cornerRadius(12)
    }

    // MARK: - Tracked Section

    private var trackedSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            if rufusManager.totalPotentialSavings > 0 {
                HStack {
                    Image(systemName: "chart.line.downtrend.xyaxis")
                        .foregroundStyle(.green)
                    Text("Potential Savings: ")
                    Text(String(format: "$%.2f", rufusManager.totalPotentialSavings))
                        .fontWeight(.bold)
                        .foregroundStyle(.green)
                }
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color.green.opacity(0.1))
                .cornerRadius(12)
            }

            if rufusManager.trackedProducts.isEmpty {
                emptyTrackingState
            } else {
                ForEach(rufusManager.trackedProducts) { product in
                    TrackedProductCard(product: product) {
                        Task {
                            await rufusManager.untrackProduct(asin: product.asin)
                        }
                    }
                }
            }
        }
    }

    // MARK: - Saved Section

    private var savedSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            if rufusManager.totalSavingsAvailable > 0 {
                HStack {
                    Image(systemName: "bookmark.fill")
                        .foregroundStyle(.purple)
                    Text("Total Savings Available: ")
                    Text(String(format: "$%.2f", rufusManager.totalSavingsAvailable))
                        .fontWeight(.bold)
                        .foregroundStyle(.purple)
                }
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color.purple.opacity(0.1))
                .cornerRadius(12)
            }

            if rufusManager.savedDeals.isEmpty {
                emptySavedState
            } else {
                ForEach(rufusManager.savedDeals) { deal in
                    SavedDealCard(deal: deal) {
                        Task {
                            await rufusManager.removeSavedDeal(asin: deal.asin)
                        }
                    }
                }
            }
        }
    }

    // MARK: - Empty States

    private var emptyDealsState: some View {
        VStack(spacing: 12) {
            Image(systemName: "tag.slash")
                .font(.system(size: 48))
                .foregroundStyle(.secondary)
            Text("No deals right now")
                .font(.headline)
            Text("Try searching for specific products or check back later!")
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }

    private var emptyTrackingState: some View {
        VStack(spacing: 12) {
            Image(systemName: "eye.slash")
                .font(.system(size: 48))
                .foregroundStyle(.secondary)
            Text("Not tracking any products")
                .font(.headline)
            Text("Search for products and tap 'Track' to monitor prices!")
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            Button("Find Products to Track") {
                showSearch = true
            }
            .buttonStyle(.borderedProminent)
            .tint(.orange)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }

    private var emptySavedState: some View {
        VStack(spacing: 12) {
            Image(systemName: "bookmark.slash")
                .font(.system(size: 48))
                .foregroundStyle(.secondary)
            Text("No saved deals")
                .font(.headline)
            Text("Save deals to purchase later!")
                .font(.caption)
                .foregroundStyle(.secondary)

            Button("Browse Deals") {
                selectedTab = 0
            }
            .buttonStyle(.borderedProminent)
            .tint(.purple)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }
}

// MARK: - Supporting Views

struct StatCard: View {
    let icon: String
    let value: String
    let label: String
    let color: Color

    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(color)
            Text(value)
                .font(.headline)
            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .frame(width: 90, height: 80)
        .background(color.opacity(0.1))
        .cornerRadius(12)
    }
}

struct CategoryButton: View {
    let category: RufusCategory
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: category.icon)
                    .font(.title3)
                Text(category.label)
                    .font(.caption)
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(Color.secondary.opacity(0.1))
            .cornerRadius(8)
        }
        .buttonStyle(.plain)
    }
}

struct RufusDealCard: View {
    let deal: RufusDeal
    let onTrack: () -> Void
    let onSave: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .top) {
                // Product image
                AsyncImage(url: URL(string: deal.product.imageUrl ?? "")) { image in
                    image.resizable().aspectRatio(contentMode: .fit)
                } placeholder: {
                    Color.gray.opacity(0.2)
                }
                .frame(width: 80, height: 80)
                .cornerRadius(8)

                VStack(alignment: .leading, spacing: 4) {
                    // Deal badge
                    HStack {
                        Image(systemName: deal.dealType.icon)
                            .font(.caption)
                        Text(deal.dealType.label)
                            .font(.caption)
                            .fontWeight(.medium)
                    }
                    .foregroundStyle(Color(hex: deal.dealType.color) ?? .orange)

                    // Title
                    Text(deal.product.title)
                        .font(.subheadline)
                        .lineLimit(2)

                    // Price
                    HStack(alignment: .bottom, spacing: 4) {
                        Text(deal.product.formattedPrice)
                            .font(.headline)
                            .foregroundStyle(.green)

                        if let original = deal.product.formattedOriginalPrice {
                            Text(original)
                                .font(.caption)
                                .strikethrough()
                                .foregroundStyle(.secondary)
                        }

                        if let savings = deal.product.formattedSavings {
                            Text(savings)
                                .font(.caption)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.green.opacity(0.2))
                                .cornerRadius(4)
                                .foregroundStyle(.green)
                        }
                    }

                    // Prime badge
                    if deal.product.isPrime {
                        HStack(spacing: 2) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.caption2)
                            Text("Prime")
                                .font(.caption2)
                        }
                        .foregroundStyle(.blue)
                    }
                }

                Spacer()
            }

            // Action buttons
            HStack {
                Button(action: onTrack) {
                    Label("Track", systemImage: "eye")
                        .font(.caption)
                }
                .buttonStyle(.bordered)
                .tint(.blue)

                Button(action: onSave) {
                    Label("Save", systemImage: "bookmark")
                        .font(.caption)
                }
                .buttonStyle(.bordered)
                .tint(.purple)

                Spacer()

                Link(destination: URL(string: deal.product.url)!) {
                    Label("View", systemImage: "arrow.up.right.square")
                        .font(.caption)
                }
                .buttonStyle(.borderedProminent)
                .tint(.orange)
            }
        }
        .padding()
        .background(Color.secondary.opacity(0.05))
        .cornerRadius(12)
    }
}

struct TrackedProductCard: View {
    let product: RufusTrackedProduct
    let onUntrack: () -> Void

    var body: some View {
        HStack {
            AsyncImage(url: URL(string: product.imageUrl ?? "")) { image in
                image.resizable().aspectRatio(contentMode: .fit)
            } placeholder: {
                Color.gray.opacity(0.2)
            }
            .frame(width: 60, height: 60)
            .cornerRadius(8)

            VStack(alignment: .leading, spacing: 4) {
                Text(product.title)
                    .font(.subheadline)
                    .lineLimit(2)

                HStack {
                    Text(product.formattedCurrentPrice)
                        .font(.headline)
                        .foregroundStyle(product.priceDropped ? .green : .primary)

                    if product.priceDropped {
                        Image(systemName: "arrow.down.circle.fill")
                            .foregroundStyle(.green)
                    }

                    Spacer()

                    Text("Target: \(product.formattedTargetPrice)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                // Progress bar
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        Rectangle()
                            .fill(Color.secondary.opacity(0.2))
                            .frame(height: 4)

                        Rectangle()
                            .fill(Color.green)
                            .frame(width: geometry.size.width * product.progressToTarget, height: 4)
                    }
                    .cornerRadius(2)
                }
                .frame(height: 4)
            }

            Button(action: onUntrack) {
                Image(systemName: "xmark.circle.fill")
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
        .background(product.priceDropped ? Color.green.opacity(0.1) : Color.secondary.opacity(0.05))
        .cornerRadius(12)
    }
}

struct SavedDealCard: View {
    let deal: RufusSavedDeal
    let onRemove: () -> Void

    var body: some View {
        HStack {
            AsyncImage(url: URL(string: deal.imageUrl ?? "")) { image in
                image.resizable().aspectRatio(contentMode: .fit)
            } placeholder: {
                Color.gray.opacity(0.2)
            }
            .frame(width: 60, height: 60)
            .cornerRadius(8)

            VStack(alignment: .leading, spacing: 4) {
                Text(deal.title)
                    .font(.subheadline)
                    .lineLimit(2)

                HStack {
                    Text(deal.formattedPrice)
                        .font(.headline)
                        .foregroundStyle(.green)

                    if let savings = deal.formattedSavings {
                        Text(savings)
                            .font(.caption)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.green.opacity(0.2))
                            .cornerRadius(4)
                            .foregroundStyle(.green)
                    }
                }

                Text("Saved \(deal.savedAt.formatted(date: .abbreviated, time: .omitted))")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            VStack {
                if let url = deal.url, let dealUrl = URL(string: url) {
                    Link(destination: dealUrl) {
                        Image(systemName: "cart.badge.plus")
                            .foregroundStyle(.orange)
                    }
                }

                Button(action: onRemove) {
                    Image(systemName: "trash")
                        .foregroundStyle(.red.opacity(0.7))
                }
            }
        }
        .padding()
        .background(Color.secondary.opacity(0.05))
        .cornerRadius(12)
    }
}

// MARK: - Color Extension

extension Color {
    init?(hex: String) {
        var hexSanitized = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        hexSanitized = hexSanitized.replacingOccurrences(of: "#", with: "")

        var rgb: UInt64 = 0

        guard Scanner(string: hexSanitized).scanHexInt64(&rgb) else { return nil }

        self.init(
            red: Double((rgb & 0xFF0000) >> 16) / 255.0,
            green: Double((rgb & 0x00FF00) >> 8) / 255.0,
            blue: Double(rgb & 0x0000FF) / 255.0
        )
    }
}

#Preview {
    RufusView()
}
