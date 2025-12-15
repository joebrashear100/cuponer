//
//  SankeyDiagramView.swift
//  Furg
//
//  Sankey diagram showing money flow through spending categories
//

import SwiftUI

struct SankeyDiagramView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Money Flow")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                Text("Where your money goes")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.white.opacity(0.5))
            }

            // Simplified Sankey visualization
            VStack(spacing: 20) {
                // Source: Income
                HStack(spacing: 12) {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.chartIncome)
                        .frame(width: 80, height: 40)
                        .overlay(
                            Text("Income\n$6,500")
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundColor(.white)
                                .multilineTextAlignment(.center)
                        )

                    VStack(spacing: 8) {
                        // Flow lines
                        HStack(spacing: 0) {
                            ForEach(0..<3, id: \.self) { _ in
                                Divider()
                                    .frame(height: 2)
                                    .background(
                                        LinearGradient(
                                            gradient: Gradient(colors: [
                                                Color.furgMint.opacity(0.6),
                                                Color.furgMint.opacity(0.2)
                                            ]),
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                            }
                        }
                        .frame(height: 2)

                        HStack(spacing: 0) {
                            ForEach(0..<3, id: \.self) { _ in
                                Divider()
                                    .frame(height: 2)
                                    .background(
                                        LinearGradient(
                                            gradient: Gradient(colors: [
                                                Color.furgMint.opacity(0.6),
                                                Color.furgMint.opacity(0.2)
                                            ]),
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                            }
                        }
                        .frame(height: 2)

                        HStack(spacing: 0) {
                            ForEach(0..<3, id: \.self) { _ in
                                Divider()
                                    .frame(height: 2)
                                    .background(
                                        LinearGradient(
                                            gradient: Gradient(colors: [
                                                Color.furgMint.opacity(0.6),
                                                Color.furgMint.opacity(0.2)
                                            ]),
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                            }
                        }
                        .frame(height: 2)
                    }

                    VStack(spacing: 6) {
                        // Categories
                        categoryFlow(category: "Food", amount: "$650", color: .v2CategoryFood)
                        categoryFlow(category: "Shopping", amount: "$420", color: .v2CategoryShopping)
                        categoryFlow(category: "Transport", amount: "$280", color: .v2CategoryTransport)
                    }
                }

                // Summary row
                HStack(spacing: 16) {
                    Spacer()
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Total Spent: $2,450")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.white)
                        Text("Remaining: $4,050")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.chartIncome)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Color.white.opacity(0.05))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                }
            }
            .padding(16)
            .background(Color.white.opacity(0.03))
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .padding(.horizontal, 20)
    }

    private func categoryFlow(category: String, amount: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack(spacing: 6) {
                Circle()
                    .fill(color)
                    .frame(width: 6, height: 6)
                Text(category)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.white)
            }
            Text(amount)
                .font(.system(size: 10, weight: .medium))
                .foregroundColor(color)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(color.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 6))
    }
}

#Preview {
    ZStack {
        Color.furgCharcoal
            .ignoresSafeArea()
        SankeyDiagramView()
    }
}
