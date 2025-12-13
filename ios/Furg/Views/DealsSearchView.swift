//
//  DealsSearchView.swift
//  Furg
//
//  Deals Search - Find products and deals on Amazon
//

import SwiftUI

struct DealsSearchView: View {
    @ObservedObject var dealsManager: DealsManager
    @Environment(\.dismiss) private var dismiss

    @State private var searchText = ""
    @State private var selectedCategory: DealsCategory = .all
    @State private var selectedSort: DealsSortOption = .relevance
    @State private var primeOnly = false
    @State private var maxPrice: Double?
    @State private var showFilters = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Search bar
                searchBar

                // Filter pills
                filterPills

                // Results
                if dealsManager.isLoading {
                    loadingView
                } else if dealsManager.searchResults.isEmpty && !searchText.isEmpty {
                    emptyResultsView
                } else if dealsManager.searchResults.isEmpty {
                    searchPromptView
                } else {
                    resultsList
                }
            }
            .navigationTitle("Search with Deals")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showFilters = true
                    } label: {
                        Image(systemName: "slider.horizontal.3")
                    }
                }
            }
            .sheet(isPresented: $showFilters) {
                filterSheet
            }
        }
    }

    // MARK: - Search Bar

    private var searchBar: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(.secondary)

            TextField("Search Amazon products...", text: $searchText)
                .textFieldStyle(.plain)
                .submitLabel(.search)
                .onSubmit {
                    performSearch()
                }

            if !searchText.isEmpty {
                Button {
                    searchText = ""
                    dealsManager.clearSearch()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding()
        .background(Color.secondary.opacity(0.1))
        .cornerRadius(12)
        .padding()
    }

    // MARK: - Filter Pills

    private var filterPills: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                // Category pill
                Menu {
                    ForEach(DealsCategory.allCases, id: \.self) { category in
                        Button {
                            selectedCategory = category
                        } label: {
                            if selectedCategory == category {
                                Label(category.label, systemImage: "checkmark")
                            } else {
                                Text(category.label)
                            }
                        }
                    }
                } label: {
                    FilterPill(
                        icon: selectedCategory.icon,
                        text: selectedCategory.label,
                        isActive: selectedCategory != .all
                    )
                }

                // Sort pill
                Menu {
                    ForEach(DealsSortOption.allCases, id: \.self) { option in
                        Button {
                            selectedSort = option
                        } label: {
                            if selectedSort == option {
                                Label(option.label, systemImage: "checkmark")
                            } else {
                                Text(option.label)
                            }
                        }
                    }
                } label: {
                    FilterPill(
                        icon: "arrow.up.arrow.down",
                        text: selectedSort.label,
                        isActive: selectedSort != .relevance
                    )
                }

                // Prime only toggle
                Button {
                    primeOnly.toggle()
                } label: {
                    FilterPill(
                        icon: "star.fill",
                        text: "Prime Only",
                        isActive: primeOnly
                    )
                }

                // Price filter
                if let price = maxPrice {
                    Button {
                        maxPrice = nil
                    } label: {
                        FilterPill(
                            icon: "xmark",
                            text: "Max $\(Int(price))",
                            isActive: true
                        )
                    }
                }
            }
            .padding(.horizontal)
        }
        .padding(.bottom, 8)
    }

    // MARK: - Results List

    private var resultsList: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                // Results count
                HStack {
                    Text("\(dealsManager.searchResults.count) results")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    Spacer()

                    if !dealsManager.tip.isEmpty {
                        Text(dealsManager.tip)
                            .font(.caption2)
                            .foregroundStyle(.orange)
                    }
                }
                .padding(.horizontal)

                ForEach(dealsManager.searchResults) { product in
                    ProductSearchCard(product: product) {
                        // Track action
                        Task {
                            await dealsManager.trackProduct(asin: product.asin)
                        }
                    } onSave: {
                        // Save action
                        Task {
                            await dealsManager.saveDeal(product)
                        }
                    }
                }
            }
            .padding()
        }
    }

    // MARK: - Loading View

    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.5)

            Text("Deals is searching...")
                .font(.headline)

            Text("Finding the best deals for you")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Empty Results

    private var emptyResultsView: some View {
        VStack(spacing: 16) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 48))
                .foregroundStyle(.secondary)

            Text("No results found")
                .font(.headline)

            Text("Try different keywords or adjust your filters")
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            Button("Clear Filters") {
                selectedCategory = .all
                selectedSort = .relevance
                primeOnly = false
                maxPrice = nil
            }
            .buttonStyle(.bordered)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }

    // MARK: - Search Prompt

    private var searchPromptView: some View {
        VStack(spacing: 20) {
            Image(systemName: "dog.fill")
                .font(.system(size: 64))
                .foregroundStyle(.orange)

            Text("What are you looking for?")
                .font(.headline)

            Text("Search for products and I'll help you find the best deals!")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            // Quick search suggestions
            VStack(alignment: .leading, spacing: 12) {
                Text("Popular searches:")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                FlowLayout(spacing: 8) {
                    QuickSearchPill("headphones") { searchText = "headphones"; performSearch() }
                    QuickSearchPill("laptop") { searchText = "laptop"; performSearch() }
                    QuickSearchPill("coffee maker") { searchText = "coffee maker"; performSearch() }
                    QuickSearchPill("smart watch") { searchText = "smart watch"; performSearch() }
                    QuickSearchPill("air fryer") { searchText = "air fryer"; performSearch() }
                    QuickSearchPill("kindle") { searchText = "kindle"; performSearch() }
                }
            }
            .padding()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }

    // MARK: - Filter Sheet

    private var filterSheet: some View {
        NavigationStack {
            List {
                Section("Category") {
                    ForEach(DealsCategory.allCases, id: \.self) { category in
                        Button {
                            selectedCategory = category
                        } label: {
                            HStack {
                                Image(systemName: category.icon)
                                Text(category.label)
                                Spacer()
                                if selectedCategory == category {
                                    Image(systemName: "checkmark")
                                        .foregroundStyle(.blue)
                                }
                            }
                        }
                        .foregroundStyle(.primary)
                    }
                }

                Section("Sort By") {
                    ForEach(DealsSortOption.allCases, id: \.self) { option in
                        Button {
                            selectedSort = option
                        } label: {
                            HStack {
                                Text(option.label)
                                Spacer()
                                if selectedSort == option {
                                    Image(systemName: "checkmark")
                                        .foregroundStyle(.blue)
                                }
                            }
                        }
                        .foregroundStyle(.primary)
                    }
                }

                Section("Price") {
                    HStack {
                        Text("Max Price")
                        Spacer()
                        TextField("Any", value: $maxPrice, format: .currency(code: "USD"))
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 100)
                    }
                }

                Section("Options") {
                    Toggle("Prime Only", isOn: $primeOnly)
                }
            }
            .navigationTitle("Filters")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Reset") {
                        selectedCategory = .all
                        selectedSort = .relevance
                        primeOnly = false
                        maxPrice = nil
                    }
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        showFilters = false
                        if !searchText.isEmpty {
                            performSearch()
                        }
                    }
                    .fontWeight(.semibold)
                }
            }
        }
        .presentationDetents([.medium, .large])
    }

    // MARK: - Actions

    private func performSearch() {
        Task {
            await dealsManager.search(
                keywords: searchText,
                category: selectedCategory == .all ? nil : selectedCategory,
                maxPrice: maxPrice,
                primeOnly: primeOnly,
                sortBy: selectedSort
            )
        }
    }
}

// MARK: - Supporting Views

struct FilterPill: View {
    let icon: String
    let text: String
    let isActive: Bool

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.caption)
            Text(text)
                .font(.caption)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(isActive ? Color.orange.opacity(0.2) : Color.secondary.opacity(0.1))
        .foregroundStyle(isActive ? .orange : .primary)
        .cornerRadius(16)
    }
}

struct QuickSearchPill: View {
    let text: String
    let action: () -> Void

    init(_ text: String, action: @escaping () -> Void) {
        self.text = text
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            Text(text)
                .font(.caption)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color.orange.opacity(0.1))
                .foregroundStyle(.orange)
                .cornerRadius(16)
        }
    }
}

struct ProductSearchCard: View {
    let product: DealsProduct
    let onTrack: () -> Void
    let onSave: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .top) {
                // Product image
                AsyncImage(url: URL(string: product.imageUrl ?? "")) { image in
                    image.resizable().aspectRatio(contentMode: .fit)
                } placeholder: {
                    Color.gray.opacity(0.2)
                }
                .frame(width: 80, height: 80)
                .cornerRadius(8)

                VStack(alignment: .leading, spacing: 4) {
                    Text(product.title)
                        .font(.subheadline)
                        .lineLimit(2)

                    // Rating
                    if let rating = product.rating {
                        HStack(spacing: 2) {
                            ForEach(0..<5, id: \.self) { index in
                                Image(systemName: index < Int(rating) ? "star.fill" : "star")
                                    .font(.caption2)
                                    .foregroundStyle(.yellow)
                            }
                            if let count = product.reviewCount {
                                Text("(\(count))")
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }

                    // Price
                    HStack(alignment: .bottom, spacing: 4) {
                        Text(product.formattedPrice)
                            .font(.headline)
                            .foregroundStyle(product.savingsPercent != nil ? .green : .primary)

                        if let original = product.formattedOriginalPrice {
                            Text(original)
                                .font(.caption)
                                .strikethrough()
                                .foregroundStyle(.secondary)
                        }

                        if let savings = product.formattedSavings {
                            Text(savings)
                                .font(.caption2)
                                .fontWeight(.medium)
                                .padding(.horizontal, 4)
                                .padding(.vertical, 2)
                                .background(Color.green.opacity(0.2))
                                .cornerRadius(4)
                                .foregroundStyle(.green)
                        }
                    }

                    // Prime & deal badge
                    HStack(spacing: 8) {
                        if product.isPrime {
                            HStack(spacing: 2) {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.caption2)
                                Text("Prime")
                                    .font(.caption2)
                            }
                            .foregroundStyle(.blue)
                        }

                        if let badge = product.dealBadge {
                            Text(badge)
                                .font(.caption2)
                                .fontWeight(.medium)
                                .foregroundStyle(.orange)
                        }
                    }
                }

                Spacer()
            }

            // Action buttons
            HStack {
                Button(action: onTrack) {
                    Label("Track Price", systemImage: "eye")
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

                Link(destination: URL(string: product.url)!) {
                    Label("Buy", systemImage: "cart")
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

#Preview {
    DealsSearchView(dealsManager: DealsManager(apiClient: APIClient()))
}
