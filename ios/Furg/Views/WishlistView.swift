//
//  WishlistView.swift
//  Furg
//
//  Wishlist management view for purchase planning
//

import SwiftUI

struct WishlistView: View {
    @EnvironmentObject var wishlistManager: WishlistManager
    @State private var showAddSheet = false
    @State private var editingItem: WishlistItem?
    @State private var selectedFilter: WishlistFilter = .active

    enum WishlistFilter: String, CaseIterable {
        case active = "Active"
        case purchased = "Purchased"
        case all = "All"
    }

    var filteredItems: [WishlistItem] {
        switch selectedFilter {
        case .active:
            return wishlistManager.activeItems
        case .purchased:
            return wishlistManager.purchasedItems
        case .all:
            return wishlistManager.wishlist
        }
    }

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 16) {
                    // Quick Stats
                    HStack(spacing: 12) {
                        QuickStatCard(
                            title: "Items",
                            value: "\(wishlistManager.activeItems.count)",
                            icon: "heart.fill",
                            color: .pink
                        )

                        QuickStatCard(
                            title: "Total Value",
                            value: formatCurrency(wishlistManager.totalWishlistValue),
                            icon: "dollarsign.circle.fill",
                            color: .green
                        )

                        QuickStatCard(
                            title: "Time to Complete",
                            value: wishlistManager.totalMonthsToComplete == Int.max
                                ? "—"
                                : "\(wishlistManager.totalMonthsToComplete)mo",
                            icon: "calendar",
                            color: .blue
                        )
                    }
                    .padding(.horizontal)

                    // Filter Picker
                    Picker("Filter", selection: $selectedFilter) {
                        ForEach(WishlistFilter.allCases, id: \.self) { filter in
                            Text(filter.rawValue).tag(filter)
                        }
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal)

                    // Items List
                    if filteredItems.isEmpty {
                        VStack(spacing: 12) {
                            Image(systemName: "heart.slash")
                                .font(.system(size: 48))
                                .foregroundColor(.gray)

                            Text(emptyStateMessage)
                                .foregroundColor(.gray)
                                .multilineTextAlignment(.center)
                        }
                        .frame(maxWidth: .infinity, minHeight: 200)
                        .padding()
                    } else {
                        LazyVStack(spacing: 12) {
                            ForEach(filteredItems) { item in
                                WishlistItemCard(
                                    item: item,
                                    plan: wishlistManager.purchasePlans.first { $0.id == item.id },
                                    onEdit: { editingItem = item },
                                    onDelete: { wishlistManager.deleteItem(id: item.id) },
                                    onMarkPurchased: { wishlistManager.markAsPurchased(id: item.id) }
                                )
                            }
                        }
                        .padding(.horizontal)
                    }
                }
                .padding(.vertical)
            }
            .navigationTitle("Wishlist")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showAddSheet = true }) {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showAddSheet) {
                AddWishlistItemSheet(wishlistManager: wishlistManager)
            }
            .sheet(item: $editingItem) { item in
                EditWishlistItemSheet(item: item, wishlistManager: wishlistManager)
            }
        }
    }

    private var emptyStateMessage: String {
        switch selectedFilter {
        case .active:
            return "No items in your wishlist.\nTap + to add something you want!"
        case .purchased:
            return "No purchased items yet.\nKeep saving toward your goals!"
        case .all:
            return "Your wishlist is empty.\nTap + to get started!"
        }
    }

    private func formatCurrency(_ amount: Double) -> String {
        String(format: "$%.0f", amount)
    }
}

// MARK: - Quick Stat Card

struct QuickStatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .foregroundColor(color)
                .font(.title3)

            Text(value)
                .font(.headline)
                .fontWeight(.bold)

            Text(title)
                .font(.caption2)
                .foregroundColor(.gray)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(Color(uiColor: .secondarySystemBackground))
        .cornerRadius(12)
    }
}

// MARK: - Wishlist Item Card

struct WishlistItemCard: View {
    let item: WishlistItem
    let plan: PurchasePlan?
    let onEdit: () -> Void
    let onDelete: () -> Void
    let onMarkPurchased: () -> Void

    @State private var showDeleteConfirm = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 8) {
                        Text(item.name)
                            .font(.headline)
                            .strikethrough(item.isPurchased)

                        PriorityBadge(priority: item.priority)
                    }

                    HStack(spacing: 8) {
                        Label(item.category.label, systemImage: item.category.icon)
                            .font(.caption)
                            .foregroundColor(.gray)

                        Text("•")
                            .foregroundColor(.gray)

                        Text(item.dateAdded, style: .date)
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                }

                Spacer()

                Text(item.formattedPrice)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.orange)
            }

            // Notes
            if let notes = item.notes, !notes.isEmpty {
                Text(notes)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(8)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color(uiColor: .tertiarySystemBackground))
                    .cornerRadius(8)
            }

            // Purchase Plan (for active items)
            if !item.isPurchased, let plan = plan {
                VStack(alignment: .leading, spacing: 8) {
                    Divider()

                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Est. Purchase Date")
                                .font(.caption2)
                                .foregroundColor(.gray)
                            Text(plan.estimatedPurchaseDate, style: .date)
                                .font(.subheadline)
                                .fontWeight(.medium)
                        }

                        Spacer()

                        VStack(alignment: .trailing, spacing: 2) {
                            Text("Monthly Savings")
                                .font(.caption2)
                                .foregroundColor(.gray)
                            Text(plan.formattedMonthlySavings)
                                .font(.subheadline)
                                .fontWeight(.medium)
                        }
                    }

                    // Financing option
                    if let financing = plan.financingOption,
                       let calc = plan.financingCalculation {
                        HStack {
                            Image(systemName: financing.type.icon)
                                .foregroundColor(.blue)

                            VStack(alignment: .leading, spacing: 2) {
                                Text(financing.name)
                                    .font(.caption)
                                    .fontWeight(.medium)

                                Text("\(calc.formattedMonthlyPayment)/mo • \(calc.formattedTotalInterest) interest")
                                    .font(.caption2)
                                    .foregroundColor(calc.totalInterest > 0 ? .orange : .green)
                            }

                            Spacer()
                        }
                        .padding(8)
                        .background(Color.blue.opacity(0.1))
                        .cornerRadius(8)
                    }
                }
            }

            // Purchased badge
            if item.isPurchased, let purchasedDate = item.purchasedDate {
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                    Text("Purchased on \(purchasedDate, style: .date)")
                        .font(.caption)
                        .foregroundColor(.green)
                }
                .padding(8)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.green.opacity(0.1))
                .cornerRadius(8)
            }

            // Actions
            HStack(spacing: 12) {
                if !item.isPurchased {
                    Button(action: onMarkPurchased) {
                        Label("Purchased", systemImage: "checkmark")
                            .font(.caption)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.green)

                    Button(action: onEdit) {
                        Label("Edit", systemImage: "pencil")
                            .font(.caption)
                    }
                    .buttonStyle(.bordered)
                }

                Spacer()

                Button(action: { showDeleteConfirm = true }) {
                    Image(systemName: "trash")
                        .foregroundColor(.red)
                }
            }
        }
        .padding()
        .background(Color(uiColor: .secondarySystemBackground))
        .cornerRadius(16)
        .confirmationDialog("Delete Item", isPresented: $showDeleteConfirm) {
            Button("Delete", role: .destructive, action: onDelete)
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("Are you sure you want to delete \"\(item.name)\"?")
        }
    }
}

// MARK: - Priority Badge

struct PriorityBadge: View {
    let priority: Priority

    var color: Color {
        switch priority {
        case .low: return .gray
        case .medium: return .blue
        case .high: return .orange
        case .urgent: return .red
        }
    }

    var body: some View {
        Text(priority.label)
            .font(.caption2)
            .fontWeight(.semibold)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(color)
            .foregroundColor(.white)
            .cornerRadius(8)
    }
}

// MARK: - Add Item Sheet

struct AddWishlistItemSheet: View {
    @Environment(\.dismiss) var dismiss
    let wishlistManager: WishlistManager

    @State private var name = ""
    @State private var price = ""
    @State private var priority: Priority = .medium
    @State private var category: ItemCategory = .other
    @State private var url = ""
    @State private var notes = ""
    @State private var targetDate: Date?
    @State private var hasTargetDate = false

    var body: some View {
        NavigationView {
            Form {
                Section("Item Details") {
                    TextField("Name", text: $name)

                    HStack {
                        Text("$")
                        TextField("Price", text: $price)
                            .keyboardType(.decimalPad)
                    }
                }

                Section("Classification") {
                    Picker("Priority", selection: $priority) {
                        ForEach(Priority.allCases, id: \.self) { p in
                            Text(p.label).tag(p)
                        }
                    }

                    Picker("Category", selection: $category) {
                        ForEach(ItemCategory.allCases, id: \.self) { c in
                            Label(c.label, systemImage: c.icon).tag(c)
                        }
                    }
                }

                Section("Optional") {
                    TextField("Product URL", text: $url)
                        .keyboardType(.URL)
                        .autocapitalization(.none)

                    Toggle("Target Date", isOn: $hasTargetDate)

                    if hasTargetDate {
                        DatePicker(
                            "Target Date",
                            selection: Binding(
                                get: { targetDate ?? Date() },
                                set: { targetDate = $0 }
                            ),
                            displayedComponents: .date
                        )
                    }

                    TextField("Notes", text: $notes, axis: .vertical)
                        .lineLimit(3...6)
                }

                Section {
                    Button("Add to Wishlist") {
                        addItem()
                    }
                    .frame(maxWidth: .infinity, alignment: .center)
                    .disabled(name.isEmpty || price.isEmpty)
                }
            }
            .navigationTitle("Add Item")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
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
            url: url.isEmpty ? nil : url,
            notes: notes.isEmpty ? nil : notes,
            targetDate: hasTargetDate ? targetDate : nil
        )

        wishlistManager.addItem(item)
        dismiss()
    }
}

// MARK: - Edit Item Sheet

struct EditWishlistItemSheet: View {
    @Environment(\.dismiss) var dismiss
    let item: WishlistItem
    let wishlistManager: WishlistManager

    @State private var name: String
    @State private var price: String
    @State private var priority: Priority
    @State private var category: ItemCategory
    @State private var url: String
    @State private var notes: String
    @State private var targetDate: Date?
    @State private var hasTargetDate: Bool

    init(item: WishlistItem, wishlistManager: WishlistManager) {
        self.item = item
        self.wishlistManager = wishlistManager
        _name = State(initialValue: item.name)
        _price = State(initialValue: String(format: "%.2f", item.price))
        _priority = State(initialValue: item.priority)
        _category = State(initialValue: item.category)
        _url = State(initialValue: item.url ?? "")
        _notes = State(initialValue: item.notes ?? "")
        _targetDate = State(initialValue: item.targetDate)
        _hasTargetDate = State(initialValue: item.targetDate != nil)
    }

    var body: some View {
        NavigationView {
            Form {
                Section("Item Details") {
                    TextField("Name", text: $name)

                    HStack {
                        Text("$")
                        TextField("Price", text: $price)
                            .keyboardType(.decimalPad)
                    }
                }

                Section("Classification") {
                    Picker("Priority", selection: $priority) {
                        ForEach(Priority.allCases, id: \.self) { p in
                            Text(p.label).tag(p)
                        }
                    }

                    Picker("Category", selection: $category) {
                        ForEach(ItemCategory.allCases, id: \.self) { c in
                            Label(c.label, systemImage: c.icon).tag(c)
                        }
                    }
                }

                Section("Optional") {
                    TextField("Product URL", text: $url)
                        .keyboardType(.URL)
                        .autocapitalization(.none)

                    Toggle("Target Date", isOn: $hasTargetDate)

                    if hasTargetDate {
                        DatePicker(
                            "Target Date",
                            selection: Binding(
                                get: { targetDate ?? Date() },
                                set: { targetDate = $0 }
                            ),
                            displayedComponents: .date
                        )
                    }

                    TextField("Notes", text: $notes, axis: .vertical)
                        .lineLimit(3...6)
                }

                Section {
                    Button("Save Changes") {
                        saveChanges()
                    }
                    .frame(maxWidth: .infinity, alignment: .center)
                    .disabled(name.isEmpty || price.isEmpty)
                }
            }
            .navigationTitle("Edit Item")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
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
        updatedItem.url = url.isEmpty ? nil : url
        updatedItem.notes = notes.isEmpty ? nil : notes
        updatedItem.targetDate = hasTargetDate ? targetDate : nil

        wishlistManager.updateItem(updatedItem)
        dismiss()
    }
}

#Preview {
    WishlistView()
        .environmentObject(WishlistManager())
}
