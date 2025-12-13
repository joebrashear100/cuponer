//
//  QuickTransactionView.swift
//  Furg
//
//  Quick-add transactions using templates
//

import SwiftUI

struct QuickTransactionView: View {
    @StateObject private var templateManager = RecurringTransactionManager.shared
    @State private var showCustomAmount = false
    @State private var customAmount = ""
    @State private var selectedTemplate: TransactionTemplate?
    @State private var searchText = ""
    @State private var showAddTemplate = false
    @State private var animate = false

    var filteredTemplates: [TransactionTemplate] {
        if searchText.isEmpty {
            return templateManager.templates
        }
        return templateManager.templates.filter {
            $0.name.localizedCaseInsensitiveContains(searchText) ||
            $0.merchant.localizedCaseInsensitiveContains(searchText) ||
            $0.category.localizedCaseInsensitiveContains(searchText)
        }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.furgCharcoal.ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 24) {
                        // Search
                        searchBar
                            .opacity(animate ? 1 : 0)
                            .offset(y: animate ? 0 : 20)

                        // Contextual Suggestions
                        if searchText.isEmpty {
                            contextualSuggestions
                                .opacity(animate ? 1 : 0)
                                .offset(y: animate ? 0 : 20)
                                .animation(.spring(response: 0.6).delay(0.1), value: animate)
                        }

                        // Favorites
                        if !templateManager.favorites.isEmpty && searchText.isEmpty {
                            favoritesSection
                                .opacity(animate ? 1 : 0)
                                .offset(y: animate ? 0 : 20)
                                .animation(.spring(response: 0.6).delay(0.15), value: animate)
                        }

                        // Frequently Used
                        if !templateManager.frequentlyUsed.isEmpty && searchText.isEmpty {
                            frequentlyUsedSection
                                .opacity(animate ? 1 : 0)
                                .offset(y: animate ? 0 : 20)
                                .animation(.spring(response: 0.6).delay(0.2), value: animate)
                        }

                        // All Templates by Category
                        allTemplatesSection
                            .opacity(animate ? 1 : 0)
                            .offset(y: animate ? 0 : 20)
                            .animation(.spring(response: 0.6).delay(0.25), value: animate)

                        Spacer(minLength: 100)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                }
            }
            .navigationTitle("Quick Add")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showAddTemplate = true
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .foregroundColor(.furgMint)
                    }
                }
            }
            .onAppear {
                withAnimation(.spring(response: 0.6)) {
                    animate = true
                }
            }
            .sheet(isPresented: $showAddTemplate) {
                AddTemplateView()
            }
            .sheet(item: $selectedTemplate) { template in
                QuickAddConfirmView(template: template)
            }
        }
    }

    // MARK: - Search Bar

    private var searchBar: some View {
        HStack(spacing: 12) {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.white.opacity(0.5))

            TextField("Search templates...", text: $searchText)
                .font(.system(size: 15))
                .foregroundColor(.white)
                .autocorrectionDisabled()

            if !searchText.isEmpty {
                Button {
                    searchText = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.white.opacity(0.5))
                }
            }
        }
        .padding(14)
        .background(Color.white.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }

    // MARK: - Contextual Suggestions

    private var contextualSuggestions: some View {
        let suggestions = templateManager.getContextualSuggestions()
        guard !suggestions.isEmpty else { return AnyView(EmptyView()) }

        return AnyView(
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: "sparkles")
                        .foregroundColor(.furgMint)
                    Text("Suggested Right Now")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.white.opacity(0.6))
                }

                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                    ForEach(suggestions.prefix(6)) { template in
                        QuickTemplateButton(template: template) {
                            selectedTemplate = template
                        }
                    }
                }
            }
        )
    }

    // MARK: - Favorites

    private var favoritesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "star.fill")
                    .foregroundColor(.yellow)
                Text("Favorites")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white.opacity(0.6))
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(templateManager.favorites) { template in
                        FavoriteTemplateCard(template: template) {
                            selectedTemplate = template
                        }
                    }
                }
            }
        }
    }

    // MARK: - Frequently Used

    private var frequentlyUsedSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "clock.arrow.circlepath")
                    .foregroundColor(.furgMint)
                Text("Frequently Used")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white.opacity(0.6))
            }

            ForEach(templateManager.frequentlyUsed.prefix(4)) { template in
                TemplateRow(template: template) {
                    selectedTemplate = template
                } onFavorite: {
                    templateManager.toggleFavorite(template.id)
                }
            }
        }
    }

    // MARK: - All Templates

    private var allTemplatesSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(searchText.isEmpty ? "All Templates" : "Results")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.white.opacity(0.6))

            if searchText.isEmpty {
                ForEach(templateManager.templatesByCategory) { category in
                    VStack(alignment: .leading, spacing: 10) {
                        HStack {
                            Image(systemName: category.icon)
                                .font(.system(size: 12))
                            Text(category.name)
                                .font(.system(size: 13, weight: .medium))
                        }
                        .foregroundColor(.white.opacity(0.5))

                        ForEach(category.templates.prefix(3)) { template in
                            TemplateRow(template: template) {
                                selectedTemplate = template
                            } onFavorite: {
                                templateManager.toggleFavorite(template.id)
                            }
                        }
                    }
                }
            } else {
                ForEach(filteredTemplates) { template in
                    TemplateRow(template: template) {
                        selectedTemplate = template
                    } onFavorite: {
                        templateManager.toggleFavorite(template.id)
                    }
                }

                if filteredTemplates.isEmpty {
                    Text("No templates found")
                        .font(.system(size: 14))
                        .foregroundColor(.white.opacity(0.5))
                        .padding()
                }
            }
        }
    }
}

// MARK: - Supporting Views

struct QuickTemplateButton: View {
    let template: TransactionTemplate
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: template.icon)
                    .font(.system(size: 20))
                    .foregroundColor(colorFromString(template.color))

                Text(template.name)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.white)
                    .lineLimit(2)
                    .multilineTextAlignment(.center)

                if let amount = template.defaultAmount {
                    Text("$\(Int(amount))")
                        .font(.system(size: 10))
                        .foregroundColor(.white.opacity(0.5))
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(Color.white.opacity(0.05))
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }

    private func colorFromString(_ colorName: String) -> Color {
        switch colorName.lowercased() {
        case "red": return .red
        case "blue": return .blue
        case "green": return .green
        case "purple": return .purple
        case "orange": return .orange
        case "brown": return .brown
        case "yellow": return .yellow
        case "pink": return .pink
        case "mint": return .mint
        case "black": return .gray
        default: return .gray
        }
    }
}

struct FavoriteTemplateCard: View {
    let template: TransactionTemplate
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                Image(systemName: template.icon)
                    .font(.system(size: 16))
                    .foregroundColor(colorFromString(template.color))

                VStack(alignment: .leading, spacing: 2) {
                    Text(template.name)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.white)

                    Text(template.displayAmount)
                        .font(.system(size: 11))
                        .foregroundColor(.white.opacity(0.5))
                }
            }
            .padding(12)
            .background(Color.white.opacity(0.08))
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }

    private func colorFromString(_ colorName: String) -> Color {
        switch colorName.lowercased() {
        case "red": return .red
        case "blue": return .blue
        case "green": return .green
        case "purple": return .purple
        case "orange": return .orange
        case "brown": return .brown
        case "yellow": return .yellow
        default: return .gray
        }
    }
}

struct TemplateRow: View {
    let template: TransactionTemplate
    let action: () -> Void
    let onFavorite: () -> Void

    @StateObject private var templateManager = RecurringTransactionManager.shared

    var isFavorite: Bool {
        templateManager.favoriteTemplates.contains(template.id)
    }

    var body: some View {
        HStack(spacing: 14) {
            Button(action: action) {
                HStack(spacing: 14) {
                    Image(systemName: template.icon)
                        .font(.system(size: 18))
                        .foregroundColor(colorFromString(template.color))
                        .frame(width: 44, height: 44)
                        .background(colorFromString(template.color).opacity(0.2))
                        .clipShape(RoundedRectangle(cornerRadius: 12))

                    VStack(alignment: .leading, spacing: 4) {
                        Text(template.name)
                            .font(.system(size: 15, weight: .medium))
                            .foregroundColor(.white)

                        Text(template.merchant)
                            .font(.system(size: 12))
                            .foregroundColor(.white.opacity(0.5))
                    }

                    Spacer()

                    VStack(alignment: .trailing, spacing: 4) {
                        Text(template.displayAmount)
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(.white)

                        if template.usageCount > 0 {
                            Text("\(template.usageCount) uses")
                                .font(.system(size: 10))
                                .foregroundColor(.white.opacity(0.4))
                        }
                    }
                }
            }

            Button(action: onFavorite) {
                Image(systemName: isFavorite ? "star.fill" : "star")
                    .font(.system(size: 16))
                    .foregroundColor(isFavorite ? .yellow : .white.opacity(0.3))
            }
        }
        .padding(12)
        .background(Color.white.opacity(0.05))
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }

    private func colorFromString(_ colorName: String) -> Color {
        switch colorName.lowercased() {
        case "red": return .red
        case "blue": return .blue
        case "green": return .green
        case "purple": return .purple
        case "orange": return .orange
        case "brown": return .brown
        case "yellow": return .yellow
        case "pink": return .pink
        case "mint": return .mint
        case "black": return .gray
        default: return .gray
        }
    }
}

// MARK: - Quick Add Confirm View

struct QuickAddConfirmView: View {
    let template: TransactionTemplate
    @Environment(\.dismiss) var dismiss
    @StateObject private var templateManager = RecurringTransactionManager.shared

    @State private var amount: String = ""
    @State private var notes = ""
    @State private var isAdding = false

    var body: some View {
        NavigationStack {
            ZStack {
                Color.furgCharcoal.ignoresSafeArea()

                VStack(spacing: 24) {
                    // Template Info
                    VStack(spacing: 12) {
                        Image(systemName: template.icon)
                            .font(.system(size: 40))
                            .foregroundColor(colorFromString(template.color))

                        Text(template.name)
                            .font(.system(size: 22, weight: .bold))
                            .foregroundColor(.white)

                        Text(template.merchant)
                            .font(.system(size: 14))
                            .foregroundColor(.white.opacity(0.6))
                    }
                    .padding(.top, 20)

                    // Amount Input
                    VStack(spacing: 8) {
                        Text("Amount")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.white.opacity(0.6))

                        HStack {
                            Text("$")
                                .font(.system(size: 32, weight: .bold))
                                .foregroundColor(.white.opacity(0.5))

                            TextField(template.defaultAmount != nil ? String(format: "%.2f", template.defaultAmount!) : "0.00", text: $amount)
                                .font(.system(size: 40, weight: .bold, design: .rounded))
                                .foregroundColor(.white)
                                .keyboardType(.decimalPad)
                                .multilineTextAlignment(.center)
                        }
                    }
                    .padding()
                    .background(Color.white.opacity(0.05))
                    .clipShape(RoundedRectangle(cornerRadius: 16))

                    // Notes (optional)
                    FurgTextField("Notes (optional)", text: $notes, icon: "note.text")

                    Spacer()

                    // Add Button
                    Button {
                        addTransaction()
                    } label: {
                        HStack {
                            if isAdding {
                                ProgressView()
                                    .tint(.furgCharcoal)
                            } else {
                                Image(systemName: "plus.circle.fill")
                                Text("Add Transaction")
                            }
                        }
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(.furgCharcoal)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Color.furgMint)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                    }
                    .disabled(isAdding)
                }
                .padding(20)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                        .foregroundColor(.white.opacity(0.7))
                }
            }
            .onAppear {
                if let defaultAmount = template.defaultAmount {
                    amount = String(format: "%.2f", defaultAmount)
                }
            }
        }
    }

    private func addTransaction() {
        isAdding = true
        let finalAmount = Double(amount) ?? template.defaultAmount ?? 0

        _ = templateManager.quickAdd(
            templateId: template.id,
            amount: finalAmount,
            notes: notes.isEmpty ? nil : notes
        )

        // Haptic feedback
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            dismiss()
        }
    }

    private func colorFromString(_ colorName: String) -> Color {
        switch colorName.lowercased() {
        case "red": return .red
        case "blue": return .blue
        case "green": return .green
        case "purple": return .purple
        case "orange": return .orange
        case "brown": return .brown
        case "yellow": return .yellow
        case "pink": return .pink
        case "mint": return .mint
        case "black": return .gray
        default: return .gray
        }
    }
}

// MARK: - Add Template View

struct AddTemplateView: View {
    @Environment(\.dismiss) var dismiss
    @StateObject private var templateManager = RecurringTransactionManager.shared

    @State private var name = ""
    @State private var merchant = ""
    @State private var category = "Food & Dining"
    @State private var defaultAmount = ""
    @State private var selectedIcon = "dollarsign.circle.fill"
    @State private var selectedColor = "blue"

    let categories = ["Food & Dining", "Groceries", "Transportation", "Shopping", "Entertainment", "Health & Medical", "Personal Care", "Utilities", "Subscriptions"]
    let icons = ["fork.knife", "cart.fill", "car.fill", "bag.fill", "film.fill", "heart.fill", "sparkles", "bolt.fill", "cup.and.saucer.fill", "fuelpump.fill", "dumbbell.fill", "scissors"]
    let colors = ["red", "blue", "green", "purple", "orange", "brown", "yellow", "pink", "mint"]

    var body: some View {
        NavigationStack {
            ZStack {
                Color.furgCharcoal.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 20) {
                        FurgTextField("Template Name", text: $name, icon: "textformat")
                        FurgTextField("Merchant Name", text: $merchant, icon: "building.2")
                        FurgTextField("Default Amount (optional)", text: $defaultAmount, icon: "dollarsign")

                        // Category
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Category")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(.white.opacity(0.6))

                            Picker("Category", selection: $category) {
                                ForEach(categories, id: \.self) { cat in
                                    Text(cat).tag(cat)
                                }
                            }
                            .pickerStyle(.menu)
                            .tint(.furgMint)
                        }

                        // Icon Selection
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Icon")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(.white.opacity(0.6))

                            LazyVGrid(columns: [GridItem(.adaptive(minimum: 50))], spacing: 10) {
                                ForEach(icons, id: \.self) { icon in
                                    Button {
                                        selectedIcon = icon
                                    } label: {
                                        Image(systemName: icon)
                                            .font(.system(size: 20))
                                            .foregroundColor(selectedIcon == icon ? .furgCharcoal : .white.opacity(0.7))
                                            .frame(width: 44, height: 44)
                                            .background(selectedIcon == icon ? Color.furgMint : Color.white.opacity(0.08))
                                            .clipShape(RoundedRectangle(cornerRadius: 10))
                                    }
                                }
                            }
                        }

                        // Color Selection
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Color")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(.white.opacity(0.6))

                            HStack(spacing: 10) {
                                ForEach(colors, id: \.self) { color in
                                    Button {
                                        selectedColor = color
                                    } label: {
                                        Circle()
                                            .fill(colorFromString(color))
                                            .frame(width: 30, height: 30)
                                            .overlay(
                                                Circle()
                                                    .stroke(Color.white, lineWidth: selectedColor == color ? 2 : 0)
                                            )
                                    }
                                }
                            }
                        }

                        Spacer(minLength: 40)
                    }
                    .padding(20)
                }
            }
            .navigationTitle("New Template")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                        .foregroundColor(.white.opacity(0.7))
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveTemplate()
                    }
                    .foregroundColor(.furgMint)
                    .disabled(name.isEmpty || merchant.isEmpty)
                }
            }
        }
    }

    private func saveTemplate() {
        let template = TransactionTemplate(
            id: UUID(),
            name: name,
            merchant: merchant,
            category: category,
            defaultAmount: Double(defaultAmount),
            icon: selectedIcon,
            color: selectedColor,
            usageCount: 0,
            lastUsed: nil,
            isSystemTemplate: false,
            tags: [],
            notes: nil
        )

        templateManager.addTemplate(template)
        dismiss()
    }

    private func colorFromString(_ colorName: String) -> Color {
        switch colorName.lowercased() {
        case "red": return .red
        case "blue": return .blue
        case "green": return .green
        case "purple": return .purple
        case "orange": return .orange
        case "brown": return .brown
        case "yellow": return .yellow
        case "pink": return .pink
        case "mint": return .mint
        default: return .gray
        }
    }
}

#Preview {
    QuickTransactionView()
}
