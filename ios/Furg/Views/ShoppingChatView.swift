//
//  ShoppingChatView.swift
//  Furg
//
//  ChatGPT-style shopping assistant interface.
//  Provides conversational product search, deals, and recommendations.
//

import SwiftUI

struct ShoppingChatView: View {
    @StateObject private var assistant = ShoppingAssistantManager.shared
    @State private var inputText = ""
    @State private var showingShoppingQuickActions = false
    @FocusState private var isInputFocused: Bool

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Chat messages
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(spacing: 16) {
                            ForEach(assistant.messages) { message in
                                MessageBubble(message: message)
                                    .id(message.id)
                            }

                            if assistant.isLoading {
                                LoadingBubble()
                            }
                        }
                        .padding()
                    }
                    .onChange(of: assistant.messages.count) { _, _ in
                        withAnimation {
                            if let lastMessage = assistant.messages.last {
                                proxy.scrollTo(lastMessage.id, anchor: .bottom)
                            }
                        }
                    }
                }

                // Quick action chips
                if showingShoppingQuickActions {
                    ShoppingQuickActionsBar(onAction: { action in
                        handleShoppingQuickAction(action)
                    })
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }

                // Input bar
                InputBar(
                    text: $inputText,
                    isLoading: assistant.isLoading,
                    showingShoppingQuickActions: $showingShoppingQuickActions,
                    onSend: sendMessage
                )
                .focused($isInputFocused)
            }
            .navigationTitle("Shopping Assistant")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        Button(action: { assistant.clearHistory() }) {
                            Label("Clear Chat", systemImage: "trash")
                        }

                        Button(action: { showingShoppingQuickActions.toggle() }) {
                            Label(showingShoppingQuickActions ? "Hide Quick Actions" : "Show Quick Actions",
                                  systemImage: "bolt.fill")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
            }
        }
    }

    private func sendMessage() {
        guard !inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }

        let message = inputText
        inputText = ""
        isInputFocused = false

        Task {
            await assistant.sendMessage(message)
        }
    }

    private func handleShoppingQuickAction(_ action: ShoppingQuickAction) {
        Task {
            switch action {
            case .searchProducts:
                inputText = "Find "
                isInputFocused = true
            case .findDeals:
                await assistant.sendMessage("What deals are available today?")
            case .comparePrices:
                inputText = "Compare prices for "
                isInputFocused = true
            case .bestCard:
                inputText = "What card should I use at "
                isInputFocused = true
            case .loyaltyPoints:
                await assistant.sendMessage("Check my loyalty points")
            case .reorderSuggestions:
                await assistant.sendMessage("What items might I need to reorder?")
            }
        }
    }
}

// MARK: - Message Bubble

struct MessageBubble: View {
    let message: ShoppingChatMessage

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            if message.role == .assistant {
                // Assistant avatar
                Circle()
                    .fill(Color.purple.opacity(0.2))
                    .frame(width: 32, height: 32)
                    .overlay {
                        Image(systemName: "cart.fill")
                            .font(.system(size: 14))
                            .foregroundStyle(.purple)
                    }
            }

            VStack(alignment: message.role == .user ? .trailing : .leading, spacing: 8) {
                // Message content
                Text(message.content)
                    .padding(12)
                    .background(message.role == .user ? Color.blue : Color(.systemGray6))
                    .foregroundStyle(message.role == .user ? .white : .primary)
                    .clipShape(RoundedRectangle(cornerRadius: 16))

                // Product results
                if let products = message.productResults, !products.isEmpty {
                    ProductResultsCard(products: products)
                }

                // Deal results
                if let deals = message.dealResults, !deals.isEmpty {
                    DealResultsCard(deals: deals)
                }

                // Price comparison
                if let comparison = message.priceComparison {
                    PriceComparisonCard(comparison: comparison)
                }

                // Timestamp
                Text(message.timestamp, style: .time)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: message.role == .user ? .trailing : .leading)

            if message.role == .user {
                // User avatar
                Circle()
                    .fill(Color.blue.opacity(0.2))
                    .frame(width: 32, height: 32)
                    .overlay {
                        Image(systemName: "person.fill")
                            .font(.system(size: 14))
                            .foregroundStyle(.blue)
                    }
            }
        }
    }
}

// MARK: - Product Results Card

struct ProductResultsCard: View {
    let products: [ProductResult]

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Products Found")
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundStyle(.secondary)

            ForEach(products.prefix(5)) { product in
                ProductRow(product: product)
            }

            if products.count > 5 {
                Text("+ \(products.count - 5) more results")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.05), radius: 5, y: 2)
    }
}

struct ProductRow: View {
    let product: ProductResult

    var body: some View {
        HStack(spacing: 12) {
            // Product image placeholder
            RoundedRectangle(cornerRadius: 8)
                .fill(Color(.systemGray5))
                .frame(width: 50, height: 50)
                .overlay {
                    Image(systemName: "photo")
                        .foregroundStyle(.secondary)
                }

            VStack(alignment: .leading, spacing: 4) {
                Text(product.name)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .lineLimit(1)

                HStack(spacing: 4) {
                    Text(product.formattedPrice)
                        .font(.subheadline)
                        .fontWeight(.bold)
                        .foregroundStyle(.primary)

                    if product.hasDiscount {
                        Text(product.formattedOriginalPrice ?? "")
                            .font(.caption)
                            .strikethrough()
                            .foregroundStyle(.secondary)

                        Text("-\(product.discountPercent!)%")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundStyle(.green)
                    }
                }

                HStack(spacing: 8) {
                    HStack(spacing: 2) {
                        Image(systemName: "star.fill")
                            .font(.caption2)
                            .foregroundStyle(.yellow)
                        Text(String(format: "%.1f", product.rating))
                            .font(.caption)
                    }

                    Text("at \(product.retailer)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()

            if product.inStock {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(.green)
            } else {
                Text("Out of stock")
                    .font(.caption2)
                    .foregroundStyle(.red)
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Deal Results Card

struct DealResultsCard: View {
    let deals: [DealResult]

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Deals Found")
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundStyle(.secondary)

            ForEach(deals.prefix(5)) { deal in
                DealRow(deal: deal)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.05), radius: 5, y: 2)
    }
}

struct DealRow: View {
    let deal: DealResult

    var body: some View {
        HStack(spacing: 12) {
            // Deal badge
            Text(deal.formattedDiscount)
                .font(.caption)
                .fontWeight(.bold)
                .foregroundStyle(.white)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.green)
                .clipShape(RoundedRectangle(cornerRadius: 4))

            VStack(alignment: .leading, spacing: 2) {
                Text(deal.title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .lineLimit(1)

                Text(deal.retailer)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            if let code = deal.code {
                Text(code)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color(.systemGray5))
                    .clipShape(RoundedRectangle(cornerRadius: 4))
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Price Comparison Card

struct PriceComparisonCard: View {
    let comparison: PriceComparisonResult

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Price Comparison")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundStyle(.secondary)

                Spacer()

                if comparison.potentialSavings > 0 {
                    Text("Save \(String(format: "$%.2f", comparison.potentialSavings))")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundStyle(.green)
                }
            }

            Text(comparison.product)
                .font(.subheadline)
                .fontWeight(.medium)

            ForEach(comparison.comparisons.prefix(5)) { retailerPrice in
                HStack {
                    if retailerPrice.retailer == comparison.bestDeal?.retailer {
                        Image(systemName: "star.fill")
                            .font(.caption)
                            .foregroundStyle(.yellow)
                    }

                    Text(retailerPrice.retailer)
                        .font(.caption)

                    Spacer()

                    Text(retailerPrice.formattedPrice)
                        .font(.subheadline)
                        .fontWeight(retailerPrice.retailer == comparison.bestDeal?.retailer ? .bold : .regular)

                    if retailerPrice.inStock {
                        Image(systemName: "checkmark")
                            .font(.caption2)
                            .foregroundStyle(.green)
                    } else {
                        Image(systemName: "xmark")
                            .font(.caption2)
                            .foregroundStyle(.red)
                    }
                }
            }

            Divider()

            HStack {
                Text("Average: \(String(format: "$%.2f", comparison.averagePrice))")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Spacer()

                if let bestDeal = comparison.bestDeal {
                    Text("Best: \(bestDeal.retailer) at \(bestDeal.formattedPrice)")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundStyle(.green)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.05), radius: 5, y: 2)
    }
}

// MARK: - Loading Bubble

struct LoadingBubble: View {
    @State private var animating = false

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Circle()
                .fill(Color.purple.opacity(0.2))
                .frame(width: 32, height: 32)
                .overlay {
                    Image(systemName: "cart.fill")
                        .font(.system(size: 14))
                        .foregroundStyle(.purple)
                }

            HStack(spacing: 4) {
                ForEach(0..<3) { index in
                    Circle()
                        .fill(Color.secondary)
                        .frame(width: 8, height: 8)
                        .scaleEffect(animating ? 1 : 0.5)
                        .animation(
                            .easeInOut(duration: 0.6)
                            .repeatForever()
                            .delay(Double(index) * 0.2),
                            value: animating
                        )
                }
            }
            .padding(12)
            .background(Color(.systemGray6))
            .clipShape(RoundedRectangle(cornerRadius: 16))

            Spacer()
        }
        .onAppear { animating = true }
    }
}

// MARK: - Quick Actions Bar

enum ShoppingQuickAction: CaseIterable {
    case searchProducts
    case findDeals
    case comparePrices
    case bestCard
    case loyaltyPoints
    case reorderSuggestions

    var title: String {
        switch self {
        case .searchProducts: return "Search"
        case .findDeals: return "Deals"
        case .comparePrices: return "Compare"
        case .bestCard: return "Best Card"
        case .loyaltyPoints: return "Points"
        case .reorderSuggestions: return "Reorder"
        }
    }

    var icon: String {
        switch self {
        case .searchProducts: return "magnifyingglass"
        case .findDeals: return "tag.fill"
        case .comparePrices: return "chart.bar.fill"
        case .bestCard: return "creditcard.fill"
        case .loyaltyPoints: return "star.fill"
        case .reorderSuggestions: return "repeat"
        }
    }

    var color: Color {
        switch self {
        case .searchProducts: return .blue
        case .findDeals: return .green
        case .comparePrices: return .orange
        case .bestCard: return .purple
        case .loyaltyPoints: return .yellow
        case .reorderSuggestions: return .teal
        }
    }
}

struct ShoppingQuickActionsBar: View {
    let onAction: (ShoppingQuickAction) -> Void

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(ShoppingQuickAction.allCases, id: \.self) { action in
                    Button(action: { onAction(action) }) {
                        HStack(spacing: 6) {
                            Image(systemName: action.icon)
                                .font(.caption)
                            Text(action.title)
                                .font(.caption)
                                .fontWeight(.medium)
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(action.color.opacity(0.15))
                        .foregroundStyle(action.color)
                        .clipShape(Capsule())
                    }
                }
            }
            .padding(.horizontal)
        }
        .padding(.vertical, 8)
        .background(Color(.systemBackground))
    }
}

// MARK: - Input Bar

struct InputBar: View {
    @Binding var text: String
    let isLoading: Bool
    @Binding var showingShoppingQuickActions: Bool
    let onSend: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            Divider()

            HStack(spacing: 12) {
                // Quick actions toggle
                Button(action: {
                    withAnimation(.spring(response: 0.3)) {
                        showingShoppingQuickActions.toggle()
                    }
                }) {
                    Image(systemName: showingShoppingQuickActions ? "xmark.circle.fill" : "bolt.circle.fill")
                        .font(.title2)
                        .foregroundStyle(showingShoppingQuickActions ? Color.secondary : Color.blue)
                }

                // Text input
                TextField("Ask about products, deals...", text: $text)
                    .textFieldStyle(.plain)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Color(.systemGray6))
                    .clipShape(RoundedRectangle(cornerRadius: 20))
                    .onSubmit(onSend)

                // Send button
                Button(action: onSend) {
                    Image(systemName: "arrow.up.circle.fill")
                        .font(.title)
                        .foregroundStyle(text.isEmpty || isLoading ? Color.secondary : Color.blue)
                }
                .disabled(text.isEmpty || isLoading)
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
            .background(Color(.systemBackground))
        }
    }
}

// MARK: - Preview

#Preview {
    ShoppingChatView()
}
