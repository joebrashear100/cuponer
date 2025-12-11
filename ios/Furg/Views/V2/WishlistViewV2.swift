//
//  WishlistViewV2.swift
//  Furg
//
//  Purchase planning and wishlist management
//

import SwiftUI

struct WishlistViewV2: View {
    @Environment(\.dismiss) var dismiss
    @State private var showAddItem = false
    @State private var selectedItem: WishlistItemV2?

    var totalWishlist: Double {
        sampleWishlist.reduce(0) { $0 + $1.price }
    }

    var priorityItems: [WishlistItemV2] {
        sampleWishlist.filter { $0.priority == .high }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Summary
                    summaryCard

                    // Priority items
                    if !priorityItems.isEmpty {
                        prioritySection
                    }

                    // All items
                    allItemsSection
                }
                .padding(20)
            }
            .background(Color.v2Background)
            .navigationTitle("Wishlist")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button { dismiss() } label: {
                        Image(systemName: "xmark")
                            .foregroundColor(.v2TextSecondary)
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button { showAddItem = true } label: {
                        Image(systemName: "plus")
                            .foregroundColor(.v2Primary)
                    }
                }
            }
            .sheet(isPresented: $showAddItem) {
                AddWishlistItemV2()
                    .presentationBackground(Color.v2Background)
            }
            .sheet(item: $selectedItem) { item in
                WishlistItemDetailV2(item: item)
                    .presentationBackground(Color.v2Background)
            }
        }
    }

    // MARK: - Summary Card

    var summaryCard: some View {
        V2Card(padding: 24) {
            VStack(spacing: 16) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Total Wishlist")
                            .font(.v2Caption)
                            .foregroundColor(.v2TextSecondary)

                        HStack(alignment: .firstTextBaseline, spacing: 4) {
                            Text("$")
                                .font(.system(size: 24, weight: .medium, design: .rounded))
                                .foregroundColor(.v2Primary)
                            Text(String(format: "%.0f", totalWishlist))
                                .font(.v2DisplayMedium)
                                .foregroundColor(.v2TextPrimary)
                        }
                    }

                    Spacer()

                    VStack(alignment: .trailing, spacing: 4) {
                        Text("\(sampleWishlist.count) items")
                            .font(.v2Caption)
                            .foregroundColor(.v2TextSecondary)

                        Text("\(priorityItems.count) priority")
                            .font(.v2CaptionSmall)
                            .foregroundColor(.v2Accent)
                    }
                }

                // Affordability indicator
                HStack(spacing: 10) {
                    Image(systemName: "lightbulb.fill")
                        .foregroundColor(.v2Warning)

                    Text("At your current savings rate, you can afford this in ~3 months")
                        .font(.v2CaptionSmall)
                        .foregroundColor(.v2TextSecondary)
                }
                .padding(12)
                .background(Color.v2Warning.opacity(0.1))
                .cornerRadius(10)
            }
        }
    }

    // MARK: - Priority Section

    var prioritySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            V2SectionHeader(title: "Priority Items")

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(priorityItems) { item in
                        Button {
                            selectedItem = item
                        } label: {
                            PriorityItemCard(item: item)
                        }
                    }
                }
            }
        }
    }

    // MARK: - All Items Section

    var allItemsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            V2SectionHeader(title: "All Items")

            V2Card(padding: 0) {
                VStack(spacing: 0) {
                    ForEach(sampleWishlist) { item in
                        Button {
                            selectedItem = item
                        } label: {
                            WishlistRowV2(item: item)
                        }

                        if item.id != sampleWishlist.last?.id {
                            Divider().background(Color.white.opacity(0.06))
                        }
                    }
                }
            }
        }
    }

    // MARK: - Sample Data

    var sampleWishlist: [WishlistItemV2] {
        [
            WishlistItemV2(name: "MacBook Pro 14\"", price: 1999, category: "Electronics", priority: .high, imageURL: nil, notes: "For work and development"),
            WishlistItemV2(name: "AirPods Pro", price: 249, category: "Electronics", priority: .high, imageURL: nil, notes: nil),
            WishlistItemV2(name: "Standing Desk", price: 599, category: "Home Office", priority: .medium, imageURL: nil, notes: "Ergonomic setup"),
            WishlistItemV2(name: "Winter Jacket", price: 350, category: "Clothing", priority: .medium, imageURL: nil, notes: nil),
            WishlistItemV2(name: "Running Shoes", price: 150, category: "Fitness", priority: .low, imageURL: nil, notes: "Nike Air Zoom"),
            WishlistItemV2(name: "Kindle Paperwhite", price: 139, category: "Electronics", priority: .low, imageURL: nil, notes: nil)
        ]
    }
}

// MARK: - Wishlist Item Model

struct WishlistItemV2: Identifiable {
    let id = UUID()
    let name: String
    let price: Double
    let category: String
    let priority: Priority
    let imageURL: URL?
    let notes: String?

    enum Priority: String {
        case high = "High"
        case medium = "Medium"
        case low = "Low"

        var color: Color {
            switch self {
            case .high: return .v2Accent
            case .medium: return .v2Warning
            case .low: return .v2TextTertiary
            }
        }
    }
}

// MARK: - Priority Item Card

struct PriorityItemCard: View {
    let item: WishlistItemV2

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Image placeholder
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.v2CardBackgroundElevated)
                    .frame(width: 140, height: 100)

                Image(systemName: iconForCategory(item.category))
                    .font(.system(size: 32))
                    .foregroundColor(.v2TextTertiary)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(item.name)
                    .font(.v2BodyBold)
                    .foregroundColor(.v2TextPrimary)
                    .lineLimit(1)

                Text("$\(Int(item.price))")
                    .font(.v2Caption)
                    .foregroundColor(.v2Primary)
            }
        }
        .frame(width: 140)
        .padding(12)
        .background(Color.v2CardBackground)
        .cornerRadius(16)
    }

    func iconForCategory(_ category: String) -> String {
        switch category {
        case "Electronics": return "laptopcomputer"
        case "Clothing": return "tshirt.fill"
        case "Home Office": return "desktopcomputer"
        case "Fitness": return "figure.run"
        default: return "bag.fill"
        }
    }
}

// MARK: - Wishlist Row

struct WishlistRowV2: View {
    let item: WishlistItemV2

    var body: some View {
        HStack(spacing: 14) {
            // Icon
            ZStack {
                Circle()
                    .fill(item.priority.color.opacity(0.15))
                    .frame(width: 44, height: 44)

                Image(systemName: iconForCategory(item.category))
                    .font(.system(size: 18))
                    .foregroundColor(item.priority.color)
            }

            // Details
            VStack(alignment: .leading, spacing: 4) {
                Text(item.name)
                    .font(.v2BodyBold)
                    .foregroundColor(.v2TextPrimary)

                HStack(spacing: 8) {
                    Text(item.category)
                        .font(.v2CaptionSmall)
                        .foregroundColor(.v2TextTertiary)

                    Text("•")
                        .foregroundColor(.v2TextTertiary)

                    Text(item.priority.rawValue)
                        .font(.v2CaptionSmall)
                        .foregroundColor(item.priority.color)
                }
            }

            Spacer()

            Text("$\(Int(item.price))")
                .font(.v2BodyBold)
                .foregroundColor(.v2TextPrimary)

            Image(systemName: "chevron.right")
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(.v2TextTertiary)
        }
        .padding(16)
    }

    func iconForCategory(_ category: String) -> String {
        switch category {
        case "Electronics": return "laptopcomputer"
        case "Clothing": return "tshirt.fill"
        case "Home Office": return "desktopcomputer"
        case "Fitness": return "figure.run"
        default: return "bag.fill"
        }
    }
}

// MARK: - Item Detail

struct WishlistItemDetailV2: View {
    let item: WishlistItemV2
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Image
                    ZStack {
                        RoundedRectangle(cornerRadius: 20)
                            .fill(Color.v2CardBackground)
                            .frame(height: 200)

                        Image(systemName: "bag.fill")
                            .font(.system(size: 60))
                            .foregroundColor(.v2TextTertiary)
                    }
                    .padding(.horizontal, 40)

                    // Details
                    VStack(spacing: 8) {
                        Text(item.name)
                            .font(.v2Title)
                            .foregroundColor(.v2TextPrimary)

                        HStack(alignment: .firstTextBaseline, spacing: 4) {
                            Text("$")
                                .font(.system(size: 20, weight: .medium, design: .rounded))
                                .foregroundColor(.v2Primary)
                            Text(String(format: "%.0f", item.price))
                                .font(.v2DisplaySmall)
                                .foregroundColor(.v2TextPrimary)
                        }
                    }

                    // Info
                    V2Card(padding: 16) {
                        VStack(spacing: 0) {
                            DetailRowV2(label: "Category", value: item.category)
                            Divider().background(Color.white.opacity(0.06))
                            DetailRowV2(label: "Priority", value: item.priority.rawValue)
                            if let notes = item.notes {
                                Divider().background(Color.white.opacity(0.06))
                                DetailRowV2(label: "Notes", value: notes)
                            }
                        }
                    }

                    // Savings calculator
                    V2Card {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Savings Plan")
                                .font(.v2Headline)
                                .foregroundColor(.v2TextPrimary)

                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Save $100/month")
                                        .font(.v2Body)
                                        .foregroundColor(.v2TextSecondary)
                                    Text("Ready in ~\(Int(item.price / 100)) months")
                                        .font(.v2Caption)
                                        .foregroundColor(.v2Primary)
                                }

                                Spacer()

                                Button {
                                    // Create savings goal
                                } label: {
                                    Text("Create Goal")
                                        .font(.v2Caption)
                                        .foregroundColor(.v2Primary)
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 8)
                                        .background(Color.v2Primary.opacity(0.15))
                                        .cornerRadius(8)
                                }
                            }
                        }
                    }

                    // Actions
                    VStack(spacing: 12) {
                        Button {
                            // Mark as purchased
                        } label: {
                            Text("Mark as Purchased")
                                .font(.v2BodyBold)
                                .foregroundColor(.v2TextInverse)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(Color.v2Primary)
                                .cornerRadius(14)
                        }

                        Button {
                            // Remove
                        } label: {
                            Text("Remove from Wishlist")
                                .font(.v2Body)
                                .foregroundColor(.v2Danger)
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
                        .foregroundColor(.v2Primary)
                }
            }
        }
    }
}

// MARK: - Add Item Sheet

struct AddWishlistItemV2: View {
    @Environment(\.dismiss) var dismiss
    @State private var name = ""
    @State private var price = ""
    @State private var category = "Electronics"
    @State private var priority = WishlistItemV2.Priority.medium
    @State private var notes = ""

    let categories = ["Electronics", "Clothing", "Home Office", "Fitness", "Travel", "Other"]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    FormFieldV2(label: "Item Name", placeholder: "What do you want?", text: $name)

                    FormFieldV2(label: "Price", placeholder: "$0", text: $price, keyboardType: .decimalPad)

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Category")
                            .font(.v2Caption)
                            .foregroundColor(.v2TextSecondary)

                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                ForEach(categories, id: \.self) { cat in
                                    Button {
                                        category = cat
                                    } label: {
                                        Text(cat)
                                            .font(.v2Caption)
                                            .foregroundColor(category == cat ? .v2TextInverse : .v2TextSecondary)
                                            .padding(.horizontal, 14)
                                            .padding(.vertical, 10)
                                            .background(category == cat ? Color.v2Primary : Color.v2CardBackground)
                                            .cornerRadius(18)
                                    }
                                }
                            }
                        }
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Priority")
                            .font(.v2Caption)
                            .foregroundColor(.v2TextSecondary)

                        HStack(spacing: 12) {
                            ForEach([WishlistItemV2.Priority.high, .medium, .low], id: \.rawValue) { p in
                                Button {
                                    priority = p
                                } label: {
                                    Text(p.rawValue)
                                        .font(.v2Caption)
                                        .foregroundColor(priority == p ? .v2TextInverse : p.color)
                                        .padding(.horizontal, 16)
                                        .padding(.vertical, 10)
                                        .background(priority == p ? p.color : p.color.opacity(0.15))
                                        .cornerRadius(18)
                                }
                            }
                        }
                    }

                    FormFieldV2(label: "Notes (optional)", placeholder: "Any details...", text: $notes)

                    Spacer(minLength: 40)

                    Button {
                        dismiss()
                    } label: {
                        Text("Add to Wishlist")
                            .font(.v2BodyBold)
                            .foregroundColor(.v2TextInverse)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(name.isEmpty || price.isEmpty ? Color.v2TextTertiary : Color.v2Primary)
                            .cornerRadius(14)
                    }
                    .disabled(name.isEmpty || price.isEmpty)
                }
                .padding(20)
            }
            .background(Color.v2Background)
            .navigationTitle("Add Item")
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

// MARK: - Preview

#Preview {
    WishlistViewV2()
}
