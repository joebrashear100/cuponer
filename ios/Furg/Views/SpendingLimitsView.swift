//
//  SpendingLimitsView.swift
//  Furg
//
//  Manage spending limits by category with alerts
//

import SwiftUI

struct SpendingLimitsView: View {
    @EnvironmentObject var limitsManager: SpendingLimitsManager

    @State private var showAddLimit = false
    @State private var showAlerts = false
    @State private var editingLimit: SpendingLimit?

    var body: some View {
        ZStack {
            AnimatedMeshBackground()

            ScrollView {
                VStack(spacing: 24) {
                    // Header with alerts badge
                    headerSection

                    // Alerts preview
                    if limitsManager.unreadAlertCount > 0 {
                        alertsPreview
                    }

                    // Over limit warning
                    if !limitsManager.overLimitCategories.isEmpty {
                        overLimitSection
                    }

                    // Active limits
                    limitsSection

                    // Add limit button
                    addLimitButton
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
                .padding(.bottom, 100)
            }
        }
        .navigationTitle("Spending Limits")
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    showAlerts = true
                } label: {
                    ZStack(alignment: .topTrailing) {
                        Image(systemName: "bell.fill")
                            .font(.system(size: 18))
                            .foregroundColor(.white)

                        if limitsManager.unreadAlertCount > 0 {
                            Circle()
                                .fill(Color.furgDanger)
                                .frame(width: 10, height: 10)
                                .offset(x: 2, y: -2)
                        }
                    }
                }
            }
        }
        .sheet(isPresented: $showAddLimit) {
            AddSpendingLimitSheet()
                .environmentObject(limitsManager)
        }
        .sheet(isPresented: $showAlerts) {
            AlertsListSheet()
                .environmentObject(limitsManager)
        }
        .sheet(item: $editingLimit) { limit in
            EditSpendingLimitSheet(limit: limit)
                .environmentObject(limitsManager)
        }
    }

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Budget Limits")
                .font(.furgTitle2)
                .foregroundColor(.white)

            Text("Set spending caps and get roasted when you exceed them")
                .font(.furgBody)
                .foregroundColor(.white.opacity(0.6))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var alertsPreview: some View {
        Button {
            showAlerts = true
        } label: {
            GlassCard {
                HStack(spacing: 16) {
                    ZStack {
                        Circle()
                            .fill(Color.furgDanger.opacity(0.2))
                            .frame(width: 50, height: 50)

                        Image(systemName: "bell.badge.fill")
                            .font(.system(size: 22))
                            .foregroundColor(.furgDanger)
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        Text("\(limitsManager.unreadAlertCount) New Alerts")
                            .font(.furgHeadline)
                            .foregroundColor(.white)

                        Text("Tap to view all alerts")
                            .font(.furgCaption)
                            .foregroundColor(.white.opacity(0.5))
                    }

                    Spacer()

                    Image(systemName: "chevron.right")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.white.opacity(0.5))
                }
            }
        }
    }

    private var overLimitSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundColor(.furgDanger)
                Text("Over Budget")
                    .font(.furgHeadline)
                    .foregroundColor(.furgDanger)
            }

            ForEach(limitsManager.overLimitCategories) { limit in
                overLimitCard(limit)
            }
        }
    }

    private func overLimitCard(_ limit: SpendingLimit) -> some View {
        GlassCard {
            HStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(SpendingLimitsManager.colorForCategory(limit.category).opacity(0.2))
                        .frame(width: 44, height: 44)

                    Image(systemName: SpendingLimitsManager.iconForCategory(limit.category))
                        .font(.system(size: 18))
                        .foregroundColor(SpendingLimitsManager.colorForCategory(limit.category))
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(limit.category)
                        .font(.furgHeadline)
                        .foregroundColor(.white)

                    Text("$\(limit.currentSpent as NSDecimalNumber, specifier: "%.0f") of $\(limit.limitAmount as NSDecimalNumber, specifier: "%.0f")")
                        .font(.furgCaption)
                        .foregroundColor(.furgDanger)
                }

                Spacer()

                Text("+$\(abs(limit.remaining) as NSDecimalNumber, specifier: "%.0f")")
                    .font(.furgHeadline)
                    .foregroundColor(.furgDanger)
            }
        }
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.furgDanger.opacity(0.5), lineWidth: 1)
        )
    }

    private var limitsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Active Limits")
                .font(.furgHeadline)
                .foregroundColor(.white)

            ForEach(limitsManager.limits.filter { $0.isActive && !$0.isOverLimit }) { limit in
                limitCard(limit)
            }
        }
    }

    private func limitCard(_ limit: SpendingLimit) -> some View {
        Button {
            editingLimit = limit
        } label: {
            GlassCard {
                VStack(spacing: 16) {
                    HStack(spacing: 16) {
                        ZStack {
                            Circle()
                                .fill(SpendingLimitsManager.colorForCategory(limit.category).opacity(0.2))
                                .frame(width: 44, height: 44)

                            Image(systemName: SpendingLimitsManager.iconForCategory(limit.category))
                                .font(.system(size: 18))
                                .foregroundColor(SpendingLimitsManager.colorForCategory(limit.category))
                        }

                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Text(limit.category)
                                    .font(.furgHeadline)
                                    .foregroundColor(.white)

                                Spacer()

                                Text("$\(limit.remaining as NSDecimalNumber, specifier: "%.0f") left")
                                    .font(.furgCaption)
                                    .foregroundColor(limit.isNearLimit ? .furgWarning : .white.opacity(0.6))
                            }

                            HStack {
                                Text(limit.period.displayName)
                                    .font(.furgCaption)
                                    .foregroundColor(.white.opacity(0.5))

                                Spacer()

                                Text("$\(limit.currentSpent as NSDecimalNumber, specifier: "%.0f") / $\(limit.limitAmount as NSDecimalNumber, specifier: "%.0f")")
                                    .font(.furgCaption)
                                    .foregroundColor(.white.opacity(0.5))
                            }
                        }
                    }

                    // Progress bar
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color.white.opacity(0.1))
                                .frame(height: 8)

                            RoundedRectangle(cornerRadius: 4)
                                .fill(progressColor(for: limit))
                                .frame(width: geo.size.width * min(limit.percentageUsed, 1.0), height: 8)
                        }
                    }
                    .frame(height: 8)
                }
            }
        }
    }

    private func progressColor(for limit: SpendingLimit) -> Color {
        if limit.isOverLimit {
            return .furgDanger
        } else if limit.isNearLimit {
            return .furgWarning
        } else {
            return SpendingLimitsManager.colorForCategory(limit.category)
        }
    }

    private var addLimitButton: some View {
        Button {
            showAddLimit = true
        } label: {
            GlassCard {
                HStack {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 22))
                        .foregroundColor(.furgMint)

                    Text("Add Spending Limit")
                        .font(.furgHeadline)
                        .foregroundColor(.white)

                    Spacer()
                }
            }
        }
    }
}

// MARK: - Add Spending Limit Sheet

struct AddSpendingLimitSheet: View {
    @EnvironmentObject var limitsManager: SpendingLimitsManager
    @Environment(\.dismiss) var dismiss

    @State private var selectedCategory = ""
    @State private var amount = ""
    @State private var period: LimitPeriod = .monthly
    @State private var warningThreshold = 0.8

    var body: some View {
        NavigationStack {
            ZStack {
                Color.furgDarkBg.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 24) {
                        // Category selector
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Category")
                                .font(.furgHeadline)
                                .foregroundColor(.white)

                            LazyVGrid(columns: [
                                GridItem(.flexible()),
                                GridItem(.flexible()),
                                GridItem(.flexible())
                            ], spacing: 12) {
                                ForEach(SpendingLimitsManager.availableCategories, id: \.self) { category in
                                    CategoryButton(
                                        category: category,
                                        isSelected: selectedCategory == category
                                    ) {
                                        selectedCategory = category
                                    }
                                }
                            }
                        }

                        // Amount input
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Limit Amount")
                                .font(.furgHeadline)
                                .foregroundColor(.white)

                            HStack {
                                Text("$")
                                    .font(.furgTitle2)
                                    .foregroundColor(.white.opacity(0.5))

                                TextField("0", text: $amount)
                                    .font(.furgTitle2)
                                    .foregroundColor(.white)
                                    .keyboardType(.decimalPad)
                            }
                            .padding()
                            .background(Color.white.opacity(0.1))
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                        }

                        // Period selector
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Period")
                                .font(.furgHeadline)
                                .foregroundColor(.white)

                            HStack(spacing: 12) {
                                ForEach(LimitPeriod.allCases, id: \.self) { periodOption in
                                    Button {
                                        period = periodOption
                                    } label: {
                                        VStack(spacing: 8) {
                                            Image(systemName: periodOption.icon)
                                                .font(.system(size: 20))
                                            Text(periodOption.displayName)
                                                .font(.furgCaption)
                                        }
                                        .foregroundColor(period == periodOption ? .furgDarkBg : .white)
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 16)
                                        .background(period == periodOption ? Color.furgMint : Color.white.opacity(0.1))
                                        .clipShape(RoundedRectangle(cornerRadius: 12))
                                    }
                                }
                            }
                        }

                        // Warning threshold
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Text("Warning at")
                                    .font(.furgHeadline)
                                    .foregroundColor(.white)

                                Spacer()

                                Text("\(Int(warningThreshold * 100))%")
                                    .font(.furgHeadline)
                                    .foregroundColor(.furgWarning)
                            }

                            Slider(value: $warningThreshold, in: 0.5...0.95, step: 0.05)
                                .tint(.furgWarning)
                        }
                    }
                    .padding(24)
                }
            }
            .navigationTitle("Add Limit")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(.white.opacity(0.7))
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveLimit()
                    }
                    .foregroundColor(.furgMint)
                    .disabled(selectedCategory.isEmpty || amount.isEmpty)
                }
            }
        }
        .presentationDetents([.large])
    }

    private func saveLimit() {
        guard let amountValue = Decimal(string: amount) else { return }

        Task {
            await limitsManager.createLimit(
                category: selectedCategory,
                amount: amountValue,
                period: period,
                warningThreshold: warningThreshold
            )
            dismiss()
        }
    }
}

struct CategoryButton: View {
    let category: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: SpendingLimitsManager.iconForCategory(category))
                    .font(.system(size: 20))
                    .foregroundColor(isSelected ? .white : SpendingLimitsManager.colorForCategory(category))

                Text(category)
                    .font(.furgCaption)
                    .foregroundColor(isSelected ? .white : .white.opacity(0.7))
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(
                isSelected ?
                SpendingLimitsManager.colorForCategory(category) :
                Color.white.opacity(0.1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(
                        isSelected ?
                        Color.clear :
                        SpendingLimitsManager.colorForCategory(category).opacity(0.3),
                        lineWidth: 1
                    )
            )
        }
    }
}

// MARK: - Edit Spending Limit Sheet

struct EditSpendingLimitSheet: View {
    @EnvironmentObject var limitsManager: SpendingLimitsManager
    @Environment(\.dismiss) var dismiss

    let limit: SpendingLimit

    @State private var amount: String
    @State private var showDeleteConfirm = false

    init(limit: SpendingLimit) {
        self.limit = limit
        _amount = State(initialValue: "\(limit.limitAmount)")
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.furgDarkBg.ignoresSafeArea()

                VStack(spacing: 24) {
                    // Category header
                    HStack(spacing: 16) {
                        ZStack {
                            Circle()
                                .fill(SpendingLimitsManager.colorForCategory(limit.category).opacity(0.2))
                                .frame(width: 60, height: 60)

                            Image(systemName: SpendingLimitsManager.iconForCategory(limit.category))
                                .font(.system(size: 26))
                                .foregroundColor(SpendingLimitsManager.colorForCategory(limit.category))
                        }

                        VStack(alignment: .leading, spacing: 4) {
                            Text(limit.category)
                                .font(.furgTitle2)
                                .foregroundColor(.white)

                            Text(limit.period.displayName + " limit")
                                .font(.furgBody)
                                .foregroundColor(.white.opacity(0.5))
                        }

                        Spacer()
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 24)

                    // Current spending
                    GlassCard {
                        VStack(spacing: 8) {
                            Text("Current Spending")
                                .font(.furgCaption)
                                .foregroundColor(.white.opacity(0.5))

                            Text("$\(limit.currentSpent as NSDecimalNumber, specifier: "%.2f")")
                                .font(.furgLargeTitle)
                                .foregroundColor(limit.isOverLimit ? .furgDanger : .white)
                        }
                    }
                    .padding(.horizontal, 24)

                    // Amount input
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Limit Amount")
                            .font(.furgHeadline)
                            .foregroundColor(.white)

                        HStack {
                            Text("$")
                                .font(.furgTitle2)
                                .foregroundColor(.white.opacity(0.5))

                            TextField("0", text: $amount)
                                .font(.furgTitle2)
                                .foregroundColor(.white)
                                .keyboardType(.decimalPad)
                        }
                        .padding()
                        .background(Color.white.opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    .padding(.horizontal, 24)

                    Spacer()

                    // Delete button
                    Button {
                        showDeleteConfirm = true
                    } label: {
                        HStack {
                            Image(systemName: "trash.fill")
                            Text("Delete Limit")
                        }
                        .font(.furgHeadline)
                        .foregroundColor(.furgDanger)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Color.furgDanger.opacity(0.15))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 40)
                }
            }
            .navigationTitle("Edit Limit")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(.white.opacity(0.7))
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveChanges()
                    }
                    .foregroundColor(.furgMint)
                }
            }
            .alert("Delete Limit?", isPresented: $showDeleteConfirm) {
                Button("Cancel", role: .cancel) {}
                Button("Delete", role: .destructive) {
                    deleteLimit()
                }
            } message: {
                Text("This will remove the spending limit for \(limit.category).")
            }
        }
        .presentationDetents([.medium])
    }

    private func saveChanges() {
        guard let amountValue = Decimal(string: amount) else { return }

        Task {
            await limitsManager.updateLimit(limit, newAmount: amountValue)
            dismiss()
        }
    }

    private func deleteLimit() {
        Task {
            await limitsManager.deleteLimit(limit)
            dismiss()
        }
    }
}

// MARK: - Alerts List Sheet

struct AlertsListSheet: View {
    @EnvironmentObject var limitsManager: SpendingLimitsManager
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                Color.furgDarkBg.ignoresSafeArea()

                if limitsManager.alerts.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "bell.slash.fill")
                            .font(.system(size: 50))
                            .foregroundColor(.white.opacity(0.3))

                        Text("No Alerts")
                            .font(.furgTitle2)
                            .foregroundColor(.white)

                        Text("You're all caught up!")
                            .font(.furgBody)
                            .foregroundColor(.white.opacity(0.5))
                    }
                } else {
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(limitsManager.alerts) { alert in
                                AlertRow(alert: alert) {
                                    Task {
                                        await limitsManager.markAlertRead(alert)
                                    }
                                }
                            }
                        }
                        .padding(24)
                    }
                }
            }
            .navigationTitle("Alerts")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(.white.opacity(0.7))
                }

                if limitsManager.unreadAlertCount > 0 {
                    ToolbarItem(placement: .primaryAction) {
                        Button("Mark All Read") {
                            Task {
                                await limitsManager.markAllAlertsRead()
                            }
                        }
                        .font(.furgCaption)
                        .foregroundColor(.furgMint)
                    }
                }
            }
        }
        .presentationDetents([.large])
    }
}

struct AlertRow: View {
    let alert: SpendingAlert
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(alert.iconColor.opacity(0.2))
                        .frame(width: 44, height: 44)

                    Image(systemName: alert.icon)
                        .font(.system(size: 18))
                        .foregroundColor(alert.iconColor)
                }

                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(alert.title)
                            .font(.furgHeadline)
                            .foregroundColor(.white)

                        if !alert.isRead {
                            Circle()
                                .fill(Color.furgMint)
                                .frame(width: 8, height: 8)
                        }
                    }

                    Text(alert.message)
                        .font(.furgCaption)
                        .foregroundColor(.white.opacity(0.6))
                        .lineLimit(2)

                    Text(alert.createdAt.formatted(date: .abbreviated, time: .shortened))
                        .font(.furgCaption)
                        .foregroundColor(.white.opacity(0.4))
                }

                Spacer()
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.white.opacity(alert.isRead ? 0.03 : 0.08))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.white.opacity(0.1), lineWidth: 1)
            )
        }
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        SpendingLimitsView()
            .environmentObject(SpendingLimitsManager())
    }
}
