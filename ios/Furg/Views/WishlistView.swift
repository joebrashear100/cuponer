//
//  WishlistView.swift
//  Furg
//
//  Modern glassmorphism wishlist view
//

import SwiftUI

struct WishlistView: View {
    @EnvironmentObject var wishlistManager: WishlistManager
    @State private var showAddSheet = false
    @State private var editingItem: WishlistItem?
    @State private var selectedFilter = 0
    @State private var animate = false

    let filters = ["Active", "Purchased", "All"]

    var filteredItems: [WishlistItem] {
        switch selectedFilter {
        case 0: return wishlistManager.activeItems
        case 1: return wishlistManager.purchasedItems
        default: return wishlistManager.wishlist
        }
    }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 24) {
                // Header
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Your")
                            .font(.furgBody)
                            .foregroundColor(.white.opacity(0.6))
                        Text("Wishlist")
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

                // Stats row
                HStack(spacing: 12) {
                    WishlistStatCard(
                        value: "\(wishlistManager.activeItems.count)",
                        label: "Items",
                        icon: "heart.fill",
                        color: .furgMint
                    )

                    WishlistStatCard(
                        value: "$\(Int(wishlistManager.totalWishlistValue))",
                        label: "Total",
                        icon: "dollarsign.circle.fill",
                        color: .furgSeafoam
                    )

                    WishlistStatCard(
                        value: wishlistManager.totalMonthsToComplete == Int.max ? "—" : "\(wishlistManager.totalMonthsToComplete)mo",
                        label: "Timeline",
                        icon: "clock.fill",
                        color: .furgPistachio
                    )
                }
                .offset(y: animate ? 0 : 20)
                .opacity(animate ? 1 : 0)
                .animation(.easeOut(duration: 0.5), value: animate)

                // Filter tabs
                Picker("Filter", selection: $selectedFilter) {
                    ForEach(0..<filters.count, id: \.self) { index in
                        Text(filters[index]).tag(index)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)
                .offset(y: animate ? 0 : 20)
                .opacity(animate ? 1 : 0)
                .animation(.easeOut(duration: 0.5), value: animate)

                // Items list
                if filteredItems.isEmpty {
                    EmptyWishlistState(filter: selectedFilter)
                        .offset(y: animate ? 0 : 20)
                        .opacity(animate ? 1 : 0)
                        .animation(.easeOut(duration: 0.5), value: animate)
                } else {
                    LazyVStack(spacing: 16) {
                        ForEach(Array(filteredItems.enumerated()), id: \.element.id) { index, item in
                            ModernWishlistCard(
                                item: item,
                                plan: wishlistManager.purchasePlans.first { $0.id == item.id },
                                onEdit: { editingItem = item },
                                onDelete: { wishlistManager.deleteItem(id: item.id) },
                                onMarkPurchased: { wishlistManager.markAsPurchased(id: item.id) }
                            )
                            .offset(y: animate ? 0 : 20)
                            .opacity(animate ? 1 : 0)
                            .animation(.easeOut(duration: 0.4), value: animate)
                        }
                    }
                }

                Spacer(minLength: 120)
            }
            .padding(.horizontal, 20)
        }
        .onAppear {
            withAnimation { animate = true }
        }
        .sheet(isPresented: $showAddSheet) {
            ModernAddItemSheet(wishlistManager: wishlistManager)
        }
        .sheet(item: $editingItem) { item in
            ModernEditItemSheet(item: item, wishlistManager: wishlistManager)
        }
    }
}

// MARK: - Stat Card

struct WishlistStatCard: View {
    let value: String
    let label: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(color)

            Text(value)
                .font(.furgTitle2)
                .foregroundColor(.white)

            Text(label)
                .font(.furgCaption)
                .foregroundColor(.white.opacity(0.5))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .copilotCard(cornerRadius: 20, opacity: 0.08)
    }
}

// MARK: - Empty State

struct EmptyWishlistState: View {
    let filter: Int

    var message: String {
        switch filter {
        case 0: return "Start adding items you want to save for"
        case 1: return "Items you've purchased will appear here"
        default: return "Your wishlist is empty"
        }
    }

    var body: some View {
        VStack(spacing: 20) {
            ZStack {
                Circle()
                    .fill(Color.furgMint.opacity(0.1))
                    .frame(width: 100, height: 100)

                Image(systemName: "heart")
                    .font(.system(size: 40))
                    .foregroundColor(.furgMint.opacity(0.5))
            }

            VStack(spacing: 8) {
                Text("Nothing here yet")
                    .font(.furgHeadline)
                    .foregroundColor(.white.opacity(0.8))

                Text(message)
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

// MARK: - Modern Wishlist Card

struct ModernWishlistCard: View {
    let item: WishlistItem
    let plan: PurchasePlan?
    let onEdit: () -> Void
    let onDelete: () -> Void
    let onMarkPurchased: () -> Void

    @State private var showDeleteConfirm = false

    var priorityColor: Color {
        switch item.priority {
        case .low: return .white.opacity(0.4)
        case .medium: return .furgInfo
        case .high: return .furgWarning
        case .urgent: return .furgDanger
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header row
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 6) {
                    HStack(spacing: 10) {
                        Text(item.name)
                            .font(.furgHeadline)
                            .foregroundColor(.white)
                            .strikethrough(item.isPurchased, color: .white.opacity(0.5))

                        Text(item.priority.label.uppercased())
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(item.priority == .low ? Color.white.opacity(0.6) : Color.furgCharcoal)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(priorityColor)
                            .clipShape(Capsule())
                    }

                    HStack(spacing: 6) {
                        Image(systemName: item.category.icon)
                            .font(.caption)
                        Text(item.category.label)
                            .font(.furgCaption)
                    }
                    .foregroundColor(.white.opacity(0.4))
                }

                Spacer()

                Text(item.formattedPrice)
                    .font(.furgTitle2)
                    .foregroundColor(.furgMint)
            }

            // Notes
            if let notes = item.notes, !notes.isEmpty {
                Text(notes)
                    .font(.furgCaption)
                    .foregroundColor(.white.opacity(0.5))
                    .padding(12)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.white.opacity(0.05))
                    .clipShape(RoundedRectangle(cornerRadius: 10))
            }

            // Purchase plan info
            if !item.isPurchased, let plan = plan {
                HStack(spacing: 20) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Target Date")
                            .font(.furgCaption)
                            .foregroundColor(.white.opacity(0.4))
                        Text(plan.estimatedPurchaseDate, style: .date)
                            .font(.furgBody)
                            .foregroundColor(.white)
                    }

                    Spacer()

                    VStack(alignment: .trailing, spacing: 4) {
                        Text("Monthly")
                            .font(.furgCaption)
                            .foregroundColor(.white.opacity(0.4))
                        Text(plan.formattedMonthlySavings)
                            .font(.furgBody)
                            .foregroundColor(.furgMint)
                    }
                }
                .padding(14)
                .background(Color.furgMint.opacity(0.08))
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }

            // Purchased badge
            if item.isPurchased, let purchasedDate = item.purchasedDate {
                HStack(spacing: 8) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.furgSuccess)
                    Text("Purchased \(purchasedDate, style: .date)")
                        .font(.furgCaption)
                        .foregroundColor(.furgSuccess)
                }
                .padding(12)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.furgSuccess.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 10))
            }

            // Actions
            HStack(spacing: 12) {
                if !item.isPurchased {
                    Button(action: onMarkPurchased) {
                        HStack(spacing: 6) {
                            Image(systemName: "checkmark")
                            Text("Purchased")
                        }
                        .font(.furgCaption)
                        .foregroundColor(.furgCharcoal)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(Color.furgSuccess)
                        .clipShape(Capsule())
                    }

                    Button(action: onEdit) {
                        HStack(spacing: 6) {
                            Image(systemName: "pencil")
                            Text("Edit")
                        }
                        .font(.furgCaption)
                        .foregroundColor(.white.opacity(0.7))
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(Color.white.opacity(0.1))
                        .clipShape(Capsule())
                    }
                }

                Spacer()

                Button(action: { showDeleteConfirm = true }) {
                    Image(systemName: "trash")
                        .font(.callout)
                        .foregroundColor(.furgDanger.opacity(0.8))
                        .padding(10)
                        .background(Color.furgDanger.opacity(0.1))
                        .clipShape(Circle())
                }
            }
        }
        .padding(20)
        .copilotCard(cornerRadius: 24, opacity: 0.1)
        .confirmationDialog("Delete Item", isPresented: $showDeleteConfirm) {
            Button("Delete", role: .destructive, action: onDelete)
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("Are you sure you want to delete \"\(item.name)\"?")
        }
    }
}

// MARK: - Modern Add Item Sheet

struct ModernAddItemSheet: View {
    @Environment(\.dismiss) var dismiss
    let wishlistManager: WishlistManager

    @State private var name = ""
    @State private var price = ""
    @State private var priority: Priority = .medium
    @State private var category: ItemCategory = .other
    @State private var notes = ""

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
                        Text("Add Item")
                            .font(.furgTitle2)
                            .foregroundColor(.white)
                        Spacer()
                        Color.clear.frame(width: 44)
                    }
                    .padding(.top, 20)

                    // Name input
                    VStack(alignment: .leading, spacing: 8) {
                        Text("NAME")
                            .font(.furgCaption)
                            .foregroundColor(.white.opacity(0.5))
                            .tracking(1)

                        TextField("What do you want?", text: $name)
                            .font(.furgBody)
                            .foregroundColor(.white)
                            .padding(16)
                            .copilotCard(cornerRadius: 14, opacity: 0.1)
                    }

                    // Price input
                    VStack(alignment: .leading, spacing: 8) {
                        Text("PRICE")
                            .font(.furgCaption)
                            .foregroundColor(.white.opacity(0.5))
                            .tracking(1)

                        HStack {
                            Text("$")
                                .font(.furgTitle2)
                                .foregroundColor(.furgMint)

                            TextField("0", text: $price)
                                .font(.furgTitle2)
                                .foregroundColor(.white)
                                .keyboardType(.decimalPad)
                        }
                        .padding(16)
                        .copilotCard(cornerRadius: 14, opacity: 0.1)
                    }

                    // Priority
                    VStack(alignment: .leading, spacing: 12) {
                        Text("PRIORITY")
                            .font(.furgCaption)
                            .foregroundColor(.white.opacity(0.5))
                            .tracking(1)

                        HStack(spacing: 10) {
                            ForEach(Priority.allCases, id: \.self) { p in
                                PriorityChip(priority: p, isSelected: priority == p) {
                                    priority = p
                                }
                            }
                        }
                    }

                    // Category
                    VStack(alignment: .leading, spacing: 12) {
                        Text("CATEGORY")
                            .font(.furgCaption)
                            .foregroundColor(.white.opacity(0.5))
                            .tracking(1)

                        LazyVGrid(columns: [GridItem(.adaptive(minimum: 100))], spacing: 10) {
                            ForEach(ItemCategory.allCases, id: \.self) { c in
                                CategoryChip(category: c, isSelected: category == c) {
                                    category = c
                                }
                            }
                        }
                    }

                    // Notes
                    VStack(alignment: .leading, spacing: 8) {
                        Text("NOTES")
                            .font(.furgCaption)
                            .foregroundColor(.white.opacity(0.5))
                            .tracking(1)

                        TextField("Optional notes...", text: $notes, axis: .vertical)
                            .font(.furgBody)
                            .foregroundColor(.white)
                            .lineLimit(3...6)
                            .padding(16)
                            .copilotCard(cornerRadius: 14, opacity: 0.1)
                    }

                    Spacer(minLength: 20)

                    // Add button
                    Button {
                        addItem()
                    } label: {
                        HStack {
                            Image(systemName: "plus.circle.fill")
                            Text("Add to Wishlist")
                        }
                        .font(.furgHeadline)
                        .foregroundColor(.furgCharcoal)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 18)
                        .background(
                            Group {
                                if name.isEmpty || price.isEmpty {
                                    Color.white.opacity(0.2)
                                } else {
                                    FurgGradients.mintGradient
                                }
                            }
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                    }
                    .disabled(name.isEmpty || price.isEmpty)
                    .padding(.bottom, 20)
                }
                .padding(.horizontal, 20)
            }
        }
    }

    private func addItem() {
        guard let priceValue = Double(price), priceValue > 0 else { return }

        let item = WishlistItem(
            name: name,
            price: priceValue,
            priority: priority,
            category: category,
            notes: notes.isEmpty ? nil : notes
        )

        wishlistManager.addItem(item)
        dismiss()
    }
}

// MARK: - Modern Edit Item Sheet

struct ModernEditItemSheet: View {
    @Environment(\.dismiss) var dismiss
    let item: WishlistItem
    let wishlistManager: WishlistManager

    @State private var name: String
    @State private var price: String
    @State private var priority: Priority
    @State private var category: ItemCategory
    @State private var notes: String

    init(item: WishlistItem, wishlistManager: WishlistManager) {
        self.item = item
        self.wishlistManager = wishlistManager
        _name = State(initialValue: item.name)
        _price = State(initialValue: String(format: "%.2f", item.price))
        _priority = State(initialValue: item.priority)
        _category = State(initialValue: item.category)
        _notes = State(initialValue: item.notes ?? "")
    }

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
                        Text("Edit Item")
                            .font(.furgTitle2)
                            .foregroundColor(.white)
                        Spacer()
                        Color.clear.frame(width: 44)
                    }
                    .padding(.top, 20)

                    // Name input
                    VStack(alignment: .leading, spacing: 8) {
                        Text("NAME")
                            .font(.furgCaption)
                            .foregroundColor(.white.opacity(0.5))
                            .tracking(1)

                        TextField("What do you want?", text: $name)
                            .font(.furgBody)
                            .foregroundColor(.white)
                            .padding(16)
                            .copilotCard(cornerRadius: 14, opacity: 0.1)
                    }

                    // Price input
                    VStack(alignment: .leading, spacing: 8) {
                        Text("PRICE")
                            .font(.furgCaption)
                            .foregroundColor(.white.opacity(0.5))
                            .tracking(1)

                        HStack {
                            Text("$")
                                .font(.furgTitle2)
                                .foregroundColor(.furgMint)

                            TextField("0", text: $price)
                                .font(.furgTitle2)
                                .foregroundColor(.white)
                                .keyboardType(.decimalPad)
                        }
                        .padding(16)
                        .copilotCard(cornerRadius: 14, opacity: 0.1)
                    }

                    // Priority
                    VStack(alignment: .leading, spacing: 12) {
                        Text("PRIORITY")
                            .font(.furgCaption)
                            .foregroundColor(.white.opacity(0.5))
                            .tracking(1)

                        HStack(spacing: 10) {
                            ForEach(Priority.allCases, id: \.self) { p in
                                PriorityChip(priority: p, isSelected: priority == p) {
                                    priority = p
                                }
                            }
                        }
                    }

                    // Category
                    VStack(alignment: .leading, spacing: 12) {
                        Text("CATEGORY")
                            .font(.furgCaption)
                            .foregroundColor(.white.opacity(0.5))
                            .tracking(1)

                        LazyVGrid(columns: [GridItem(.adaptive(minimum: 100))], spacing: 10) {
                            ForEach(ItemCategory.allCases, id: \.self) { c in
                                CategoryChip(category: c, isSelected: category == c) {
                                    category = c
                                }
                            }
                        }
                    }

                    // Notes
                    VStack(alignment: .leading, spacing: 8) {
                        Text("NOTES")
                            .font(.furgCaption)
                            .foregroundColor(.white.opacity(0.5))
                            .tracking(1)

                        TextField("Optional notes...", text: $notes, axis: .vertical)
                            .font(.furgBody)
                            .foregroundColor(.white)
                            .lineLimit(3...6)
                            .padding(16)
                            .copilotCard(cornerRadius: 14, opacity: 0.1)
                    }

                    Spacer(minLength: 20)

                    // Save button
                    Button {
                        saveChanges()
                    } label: {
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                            Text("Save Changes")
                        }
                        .font(.furgHeadline)
                        .foregroundColor(.furgCharcoal)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 18)
                        .background(FurgGradients.mintGradient)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                    }
                    .padding(.bottom, 20)
                }
                .padding(.horizontal, 20)
            }
        }
    }

    private func saveChanges() {
        guard let priceValue = Double(price), priceValue > 0 else { return }

        var updatedItem = item
        updatedItem.name = name
        updatedItem.price = priceValue
        updatedItem.priority = priority
        updatedItem.category = category
        updatedItem.notes = notes.isEmpty ? nil : notes

        wishlistManager.updateItem(updatedItem)
        dismiss()
    }
}

// MARK: - Priority Chip

struct PriorityChip: View {
    let priority: Priority
    let isSelected: Bool
    let action: () -> Void

    var color: Color {
        switch priority {
        case .low: return .white.opacity(0.3)
        case .medium: return .furgInfo
        case .high: return .furgWarning
        case .urgent: return .furgDanger
        }
    }

    var body: some View {
        Button(action: action) {
            Text(priority.label)
                .font(.furgCaption)
                .foregroundColor(isSelected ? .furgCharcoal : .white.opacity(0.6))
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(isSelected ? color : Color.white.opacity(0.08))
                .clipShape(Capsule())
                .overlay(
                    Capsule()
                        .stroke(isSelected ? Color.clear : Color.white.opacity(0.1), lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Category Chip

struct CategoryChip: View {
    let category: ItemCategory
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

#Preview {
    ZStack {
        CopilotBackground()
        WishlistView()
    }
    .environmentObject(WishlistManager())
}
