//
//  TransactionClarificationView.swift
//  Furg
//
//  Handle unclear transactions that need user categorization
//

import SwiftUI

struct TransactionClarificationView: View {
    @StateObject private var categorizationManager = SmartCategorizationManager.shared
    @State private var animate = false

    var body: some View {
        NavigationStack {
            ZStack {
                Color.furgCharcoal.ignoresSafeArea()

                if categorizationManager.pendingClarifications.isEmpty {
                    emptyState
                } else {
                    ScrollView(showsIndicators: false) {
                        VStack(spacing: 20) {
                            // Header Stats
                            headerStats
                                .opacity(animate ? 1 : 0)
                                .offset(y: animate ? 0 : 20)

                            // Pending Clarifications
                            pendingSection
                                .opacity(animate ? 1 : 0)
                                .offset(y: animate ? 0 : 20)
                                .animation(.spring(response: 0.6).delay(0.1), value: animate)

                            // Learning Stats
                            learningStatsSection
                                .opacity(animate ? 1 : 0)
                                .offset(y: animate ? 0 : 20)
                                .animation(.spring(response: 0.6).delay(0.15), value: animate)

                            Spacer(minLength: 100)
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 20)
                    }
                }
            }
            .navigationTitle("Categorize")
            .navigationBarTitleDisplayMode(.large)
            .onAppear {
                withAnimation(.spring(response: 0.6)) {
                    animate = true
                }
            }
        }
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 20) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 60))
                .foregroundColor(.furgSuccess)

            Text("All Caught Up!")
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(.white)

            Text("No transactions need your attention right now.\nWe'll notify you when something needs categorizing.")
                .font(.system(size: 14))
                .foregroundColor(.white.opacity(0.6))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)

            // Learning stats even when empty
            VStack(spacing: 12) {
                HStack(spacing: 20) {
                    MiniStatBox(
                        value: "\(Int(categorizationManager.getCategorizationAccuracy() * 100))%",
                        label: "Accuracy",
                        icon: "target",
                        color: .furgSuccess
                    )

                    MiniStatBox(
                        value: "\(categorizationManager.learningStats.merchantsLearned)",
                        label: "Merchants Learned",
                        icon: "brain.head.profile",
                        color: .furgMint
                    )
                }
            }
            .padding(.top, 30)
        }
    }

    // MARK: - Header Stats

    private var headerStats: some View {
        HStack(spacing: 12) {
            StatBox(
                value: "\(categorizationManager.pendingClarifications.count)",
                label: "Needs Review",
                color: .furgWarning
            )

            StatBox(
                value: "\(Int(categorizationManager.getCategorizationAccuracy() * 100))%",
                label: "AI Accuracy",
                color: .furgSuccess
            )
        }
    }

    // MARK: - Pending Section

    private var pendingSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "questionmark.circle.fill")
                    .foregroundColor(.furgWarning)
                Text("Needs Your Input")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white.opacity(0.6))
            }

            ForEach(categorizationManager.pendingClarifications) { clarification in
                ClarificationCard(clarification: clarification)
            }
        }
    }

    // MARK: - Learning Stats

    private var learningStatsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "brain.head.profile")
                    .foregroundColor(.furgMint)
                Text("AI Learning")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white.opacity(0.6))
            }

            VStack(spacing: 10) {
                LearningStatRow(
                    label: "Transactions Processed",
                    value: "\(categorizationManager.learningStats.totalTransactionsProcessed)",
                    icon: "arrow.triangle.2.circlepath"
                )

                LearningStatRow(
                    label: "Merchants Learned",
                    value: "\(categorizationManager.learningStats.merchantsLearned)",
                    icon: "building.2"
                )

                LearningStatRow(
                    label: "Auto-Categorization Rate",
                    value: "\(Int(categorizationManager.learningStats.autoCategorizationRate * 100))%",
                    icon: "bolt.fill"
                )
            }
            .padding(16)
            .background(Color.white.opacity(0.05))
            .clipShape(RoundedRectangle(cornerRadius: 14))

            // Most confident categories
            if !categorizationManager.getMostConfidentCategories().isEmpty {
                VStack(alignment: .leading, spacing: 10) {
                    Text("Most Accurate Categories")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.white.opacity(0.5))

                    ForEach(categorizationManager.getMostConfidentCategories().prefix(5), id: \.0) { category, confidence in
                        HStack {
                            Text(category)
                                .font(.system(size: 13))
                                .foregroundColor(.white.opacity(0.8))

                            Spacer()

                            Text("\(Int(confidence * 100))%")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(.furgMint)
                        }
                    }
                }
                .padding(16)
                .background(Color.white.opacity(0.05))
                .clipShape(RoundedRectangle(cornerRadius: 14))
            }
        }
    }
}

// MARK: - Supporting Views

struct StatBox: View {
    let value: String
    let label: String
    let color: Color

    var body: some View {
        VStack(spacing: 6) {
            Text(value)
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundColor(color)

            Text(label)
                .font(.system(size: 11))
                .foregroundColor(.white.opacity(0.5))
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(color.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }
}

struct MiniStatBox: View {
    let value: String
    let label: String
    let icon: String
    let color: Color

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundColor(color)

            VStack(alignment: .leading, spacing: 2) {
                Text(value)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.white)

                Text(label)
                    .font(.system(size: 11))
                    .foregroundColor(.white.opacity(0.5))
            }
        }
        .padding(14)
        .background(Color.white.opacity(0.05))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

struct ClarificationCard: View {
    let clarification: TransactionClarification
    @StateObject private var categorizationManager = SmartCategorizationManager.shared
    @State private var selectedCategory: String?
    @State private var isExpanded = false

    var body: some View {
        VStack(spacing: 0) {
            // Main Card Content
            Button {
                withAnimation(.spring(response: 0.3)) {
                    isExpanded.toggle()
                }
            } label: {
                HStack(spacing: 14) {
                    // Question mark icon
                    Image(systemName: "questionmark.circle.fill")
                        .font(.system(size: 24))
                        .foregroundColor(.furgWarning)

                    VStack(alignment: .leading, spacing: 4) {
                        Text(clarification.merchantName)
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white)

                        Text(formatDate(clarification.date))
                            .font(.system(size: 12))
                            .foregroundColor(.white.opacity(0.5))
                    }

                    Spacer()

                    VStack(alignment: .trailing, spacing: 4) {
                        Text("$\(String(format: "%.2f", abs(clarification.amount)))")
                            .font(.system(size: 18, weight: .bold, design: .rounded))
                            .foregroundColor(.white)

                        Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                            .font(.system(size: 12))
                            .foregroundColor(.white.opacity(0.4))
                    }
                }
                .padding(16)
            }

            // Expanded Category Selection
            if isExpanded {
                Divider()
                    .background(Color.white.opacity(0.1))

                VStack(alignment: .leading, spacing: 12) {
                    Text("What was this purchase?")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.white.opacity(0.6))

                    // Suggested categories
                    FlowLayout(spacing: 8) {
                        ForEach(clarification.suggestedCategories) { suggestion in
                            CategoryChip(
                                category: suggestion.category,
                                confidence: suggestion.confidence,
                                isSelected: selectedCategory == suggestion.category
                            ) {
                                selectedCategory = suggestion.category
                            }
                        }

                        // Other category option
                        CategoryChip(
                            category: "Other...",
                            confidence: 0,
                            isSelected: false
                        ) {
                            // Show category picker
                        }
                    }

                    // Apply button
                    if let category = selectedCategory {
                        Button {
                            categorizationManager.resolveClarification(
                                id: clarification.id,
                                selectedCategory: category
                            )
                        } label: {
                            HStack {
                                Image(systemName: "checkmark.circle.fill")
                                Text("Apply \"\(category)\"")
                            }
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.furgCharcoal)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(Color.furgMint)
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                        }
                    }
                }
                .padding(16)
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color.white.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(Color.furgWarning.opacity(0.3), lineWidth: 1)
                )
        )
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, h:mm a"
        return formatter.string(from: date)
    }
}

struct CategoryChip: View {
    let category: String
    let confidence: Double
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Text(category)
                    .font(.system(size: 13, weight: .medium))

                if confidence > 0 {
                    Text("\(Int(confidence * 100))%")
                        .font(.system(size: 10))
                        .foregroundColor(isSelected ? .furgCharcoal.opacity(0.6) : .white.opacity(0.4))
                }
            }
            .foregroundColor(isSelected ? .furgCharcoal : .white.opacity(0.8))
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(isSelected ? Color.furgMint : Color.white.opacity(0.1))
            .clipShape(Capsule())
        }
    }
}

struct LearningStatRow: View {
    let label: String
    let value: String
    let icon: String

    var body: some View {
        HStack {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundColor(.furgMint)
                .frame(width: 24)

            Text(label)
                .font(.system(size: 13))
                .foregroundColor(.white.opacity(0.7))

            Spacer()

            Text(value)
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(.white)
        }
    }
}

// MARK: - Flow Layout for Category Chips

struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let sizes = subviews.map { $0.sizeThatFits(.unspecified) }
        return layout(sizes: sizes, containerWidth: proposal.width ?? .infinity).size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let sizes = subviews.map { $0.sizeThatFits(.unspecified) }
        let offsets = layout(sizes: sizes, containerWidth: bounds.width).offsets

        for (offset, subview) in zip(offsets, subviews) {
            subview.place(at: CGPoint(x: bounds.minX + offset.x, y: bounds.minY + offset.y), proposal: .unspecified)
        }
    }

    private func layout(sizes: [CGSize], containerWidth: CGFloat) -> (offsets: [CGPoint], size: CGSize) {
        var offsets: [CGPoint] = []
        var currentX: CGFloat = 0
        var currentY: CGFloat = 0
        var maxY: CGFloat = 0
        var rowHeight: CGFloat = 0

        for size in sizes {
            if currentX + size.width > containerWidth && currentX > 0 {
                currentX = 0
                currentY += rowHeight + spacing
                rowHeight = 0
            }

            offsets.append(CGPoint(x: currentX, y: currentY))
            currentX += size.width + spacing
            rowHeight = max(rowHeight, size.height)
            maxY = max(maxY, currentY + size.height)
        }

        return (offsets, CGSize(width: containerWidth, height: maxY))
    }
}

#Preview {
    TransactionClarificationView()
}
