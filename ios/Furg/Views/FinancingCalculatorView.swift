//
//  FinancingCalculatorView.swift
//  Furg
//
//  Financing options calculator and comparison view
//

import SwiftUI

struct FinancingCalculatorView: View {
    @EnvironmentObject var wishlistManager: WishlistManager
    @Environment(\.dismiss) var dismiss
    @State private var purchasePrice: String = "1000"
    @State private var selectedOptionId: String?
    @State private var showCustomCalculator = false
    @State private var animate = false

    // Custom financing inputs
    @State private var customApr: String = "15"
    @State private var customTermMonths: String = "12"

    var priceValue: Double {
        Double(purchasePrice) ?? 0
    }

    var applicableOptions: [FinancingOption] {
        wishlistManager.getApplicableOptions(forAmount: priceValue)
    }

    var selectedOption: FinancingOption? {
        applicableOptions.first { $0.id == selectedOptionId }
    }

    var calculation: FinancingCalculation? {
        if showCustomCalculator {
            let customOption = FinancingOption(
                name: "Custom",
                type: .personalLoan,
                apr: Double(customApr) ?? 15,
                termMonths: Int(customTermMonths) ?? 12
            )
            return wishlistManager.calculateFinancing(amount: priceValue, option: customOption)
        } else if let option = selectedOption {
            return wishlistManager.calculateFinancing(amount: priceValue, option: option)
        }
        return nil
    }

    var body: some View {
        ZStack {
            CopilotBackground()

            ScrollView {
                VStack(spacing: 20) {
                    // Header
                    HStack {
                        Button(action: { dismiss() }) {
                            Image(systemName: "xmark")
                                .font(.body.bold())
                                .foregroundColor(.furgCharcoal.opacity(0.6))
                                .padding(10)
                                .background(Circle().fill(Color.white.opacity(0.3)))
                        }

                        Spacer()

                        Text("Financing Calculator")
                            .font(.headline)
                            .foregroundColor(.furgCharcoal)

                        Spacer()

                        // Invisible spacer for centering
                        Circle()
                            .fill(Color.clear)
                            .frame(width: 36, height: 36)
                    }
                    .padding(.horizontal)
                    .padding(.top)
                    .offset(y: animate ? 0 : -20)
                    .opacity(animate ? 1 : 0)
                    .animation(.easeOut(duration: 0.5), value: animate)

                    // Price Input
                    GlassPriceInputSection(purchasePrice: $purchasePrice)
                        .offset(y: animate ? 0 : 20)
                        .opacity(animate ? 1 : 0)
                        .animation(.easeOut(duration: 0.5).delay(0.1), value: animate)

                    // Toggle between preset and custom
                    GlassModeToggle(showCustomCalculator: $showCustomCalculator)
                        .offset(y: animate ? 0 : 20)
                        .opacity(animate ? 1 : 0)
                        .animation(.easeOut(duration: 0.5).delay(0.15), value: animate)

                    if showCustomCalculator {
                        GlassCustomFinancingSection(
                            customApr: $customApr,
                            customTermMonths: $customTermMonths
                        )
                        .offset(y: animate ? 0 : 20)
                        .opacity(animate ? 1 : 0)
                        .animation(.easeOut(duration: 0.5).delay(0.2), value: animate)
                    } else {
                        GlassFinancingOptionsSection(
                            options: applicableOptions,
                            selectedOptionId: $selectedOptionId,
                            priceValue: priceValue,
                            wishlistManager: wishlistManager
                        )
                        .offset(y: animate ? 0 : 20)
                        .opacity(animate ? 1 : 0)
                        .animation(.easeOut(duration: 0.5).delay(0.2), value: animate)
                    }

                    // Calculation Result
                    if let calc = calculation {
                        GlassCalculationResultSection(
                            calculation: calc,
                            purchasePrice: priceValue,
                            option: showCustomCalculator ? nil : selectedOption
                        )
                        .offset(y: animate ? 0 : 20)
                        .opacity(animate ? 1 : 0)
                        .animation(.easeOut(duration: 0.5).delay(0.3), value: animate)
                    }

                    // Comparison Table
                    if priceValue > 0 && !showCustomCalculator && !applicableOptions.isEmpty {
                        GlassComparisonTableSection(
                            options: applicableOptions,
                            purchasePrice: priceValue,
                            wishlistManager: wishlistManager,
                            selectedOptionId: selectedOptionId
                        )
                        .offset(y: animate ? 0 : 20)
                        .opacity(animate ? 1 : 0)
                        .animation(.easeOut(duration: 0.5).delay(0.4), value: animate)
                    }

                    Spacer(minLength: 40)
                }
                .padding(.vertical)
            }
        }
        .onAppear { animate = true }
    }
}

// MARK: - Glass Price Input Section

struct GlassPriceInputSection: View {
    @Binding var purchasePrice: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Purchase Price")
                .font(.headline)
                .foregroundColor(.furgCharcoal)

            HStack {
                Text("$")
                    .font(.title)
                    .foregroundColor(.furgMint)

                TextField("1000", text: $purchasePrice)
                    .font(.system(size: 36, weight: .bold))
                    .keyboardType(.decimalPad)
                    .foregroundColor(.furgCharcoal)
            }
            .padding()
            .copilotCard()
        }
        .padding(.horizontal)
    }
}

// MARK: - Glass Mode Toggle

struct GlassModeToggle: View {
    @Binding var showCustomCalculator: Bool

    var body: some View {
        HStack(spacing: 0) {
            Button(action: { showCustomCalculator = false }) {
                Text("Preset Options")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(showCustomCalculator ? .furgCharcoal.opacity(0.6) : .white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(
                        LinearGradient(
                            colors: showCustomCalculator
                                ? [Color.clear, Color.clear]
                                : [.furgMint, .furgSeafoam],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
            }

            Button(action: { showCustomCalculator = true }) {
                Text("Custom Terms")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(showCustomCalculator ? .white : .furgCharcoal.opacity(0.6))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(
                        LinearGradient(
                            colors: showCustomCalculator
                                ? [.furgMint, .furgSeafoam]
                                : [Color.clear, Color.clear],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
            }
        }
        .background(Color.white.opacity(0.3))
        .cornerRadius(12)
        .padding(.horizontal)
    }
}

// MARK: - Glass Custom Financing Section

struct GlassCustomFinancingSection: View {
    @Binding var customApr: String
    @Binding var customTermMonths: String

    var body: some View {
        VStack(spacing: 16) {
            HStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("APR (%)")
                        .font(.caption)
                        .foregroundColor(.furgCharcoal.opacity(0.6))

                    TextField("15", text: $customApr)
                        .keyboardType(.decimalPad)
                        .font(.title3.bold())
                        .foregroundColor(.furgCharcoal)
                        .padding()
                        .background(Color.white.opacity(0.3))
                        .cornerRadius(12)
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text("Term (months)")
                        .font(.caption)
                        .foregroundColor(.furgCharcoal.opacity(0.6))

                    TextField("12", text: $customTermMonths)
                        .keyboardType(.numberPad)
                        .font(.title3.bold())
                        .foregroundColor(.furgCharcoal)
                        .padding()
                        .background(Color.white.opacity(0.3))
                        .cornerRadius(12)
                }
            }
        }
        .padding()
        .copilotCard()
        .padding(.horizontal)
    }
}

// MARK: - Glass Financing Options Section

struct GlassFinancingOptionsSection: View {
    let options: [FinancingOption]
    @Binding var selectedOptionId: String?
    let priceValue: Double
    let wishlistManager: WishlistManager

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Financing Options")
                .font(.headline)
                .foregroundColor(.furgCharcoal)
                .padding(.horizontal)

            if options.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "creditcard.trianglebadge.exclamationmark")
                        .font(.system(size: 32))
                        .foregroundColor(.furgMint.opacity(0.6))

                    Text("No financing options available for this price.\nTry a different amount or use custom terms.")
                        .font(.subheadline)
                        .foregroundColor(.furgCharcoal.opacity(0.6))
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(24)
                .copilotCard()
                .padding(.horizontal)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(options) { option in
                            GlassFinancingOptionCard(
                                option: option,
                                isSelected: selectedOptionId == option.id,
                                calculation: wishlistManager.calculateFinancing(amount: priceValue, option: option)
                            ) {
                                selectedOptionId = option.id
                            }
                        }
                    }
                    .padding(.horizontal)
                }
            }
        }
    }
}

struct GlassFinancingOptionCard: View {
    let option: FinancingOption
    let isSelected: Bool
    let calculation: FinancingCalculation
    let onSelect: () -> Void

    var body: some View {
        Button(action: onSelect) {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    ZStack {
                        Circle()
                            .fill(LinearGradient(
                                colors: [.furgSeafoam, .furgMint],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ))
                            .frame(width: 28, height: 28)

                        Image(systemName: option.type.icon)
                            .font(.caption)
                            .foregroundColor(.white)
                    }

                    Spacer()

                    if isSelected {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.furgMint)
                    }
                }

                Text(option.name)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.furgCharcoal)
                    .lineLimit(1)

                Text("\(String(format: "%.1f", option.apr))% APR")
                    .font(.caption)
                    .foregroundColor(.furgCharcoal.opacity(0.6))

                Text("\(option.termMonths) months")
                    .font(.caption)
                    .foregroundColor(.furgCharcoal.opacity(0.6))

                Rectangle()
                    .fill(Color.furgMint.opacity(0.3))
                    .frame(height: 1)

                Text(calculation.formattedMonthlyPayment)
                    .font(.headline)
                    .foregroundColor(.furgMint)

                Text("/month")
                    .font(.caption2)
                    .foregroundColor(.furgCharcoal.opacity(0.5))
            }
            .padding()
            .frame(width: 150)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.white.opacity(isSelected ? 0.8 : 0.5))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(
                        isSelected
                            ? LinearGradient(colors: [.furgMint, .furgSeafoam], startPoint: .topLeading, endPoint: .bottomTrailing)
                            : LinearGradient(colors: [.clear], startPoint: .topLeading, endPoint: .bottomTrailing),
                        lineWidth: 2
                    )
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Glass Calculation Result Section

struct GlassCalculationResultSection: View {
    let calculation: FinancingCalculation
    let purchasePrice: Double
    let option: FinancingOption?

    var interestPercentage: Double {
        guard purchasePrice > 0 else { return 0 }
        return (calculation.totalInterest / purchasePrice) * 100
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Payment Details")
                    .font(.headline)
                    .foregroundColor(.furgCharcoal)

                Spacer()

                if let option = option {
                    Text(option.name)
                        .font(.caption)
                        .foregroundColor(.furgMint)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(Color.furgMint.opacity(0.15))
                        .cornerRadius(8)
                }
            }

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                GlassResultCard(
                    title: "Monthly Payment",
                    value: calculation.formattedMonthlyPayment,
                    gradient: [.furgMint, .furgSeafoam],
                    isLarge: true
                )

                GlassResultCard(
                    title: "Total Payment",
                    value: calculation.formattedTotalPayment,
                    gradient: [.furgSeafoam, .furgSage]
                )

                GlassResultCard(
                    title: "Total Interest",
                    value: calculation.formattedTotalInterest,
                    gradient: calculation.totalInterest > 0 ? [.furgWarning, .orange] : [.furgSuccess, .furgMint]
                )

                GlassResultCard(
                    title: "Payoff Date",
                    value: calculation.payoffDate.formatted(.dateTime.month(.abbreviated).year()),
                    gradient: [.furgSage, .furgPistachio]
                )
            }

            // Interest Warning/Success
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(calculation.totalInterest > 0
                            ? Color.furgWarning.opacity(0.2)
                            : Color.furgSuccess.opacity(0.2))
                        .frame(width: 36, height: 36)

                    Image(systemName: calculation.totalInterest > 0
                        ? "exclamationmark.triangle.fill"
                        : "checkmark.circle.fill")
                        .foregroundColor(calculation.totalInterest > 0 ? .furgWarning : .furgSuccess)
                }

                Text(calculation.totalInterest > 0
                    ? "You'll pay \(calculation.formattedTotalInterest) in interest (\(String(format: "%.1f", interestPercentage))% more)"
                    : "No interest! You only pay the purchase price.")
                    .font(.caption)
                    .foregroundColor(.furgCharcoal.opacity(0.8))
            }
            .padding()
            .background(
                (calculation.totalInterest > 0 ? Color.furgWarning : Color.furgSuccess).opacity(0.1)
            )
            .cornerRadius(12)
        }
        .padding()
        .copilotCard()
        .padding(.horizontal)
    }
}

struct GlassResultCard: View {
    let title: String
    let value: String
    let gradient: [Color]
    var isLarge: Bool = false

    var body: some View {
        VStack(alignment: .center, spacing: 6) {
            Text(title)
                .font(.caption)
                .foregroundColor(.furgCharcoal.opacity(0.6))

            Text(value)
                .font(isLarge ? .title2 : .headline)
                .fontWeight(.bold)
                .foregroundStyle(LinearGradient(
                    colors: gradient,
                    startPoint: .leading,
                    endPoint: .trailing
                ))
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color.white.opacity(0.3))
        .cornerRadius(12)
    }
}

// MARK: - Glass Comparison Table Section

struct GlassComparisonTableSection: View {
    let options: [FinancingOption]
    let purchasePrice: Double
    let wishlistManager: WishlistManager
    let selectedOptionId: String?

    var sortedOptions: [(option: FinancingOption, calculation: FinancingCalculation)] {
        options.map { option in
            (option, wishlistManager.calculateFinancing(amount: purchasePrice, option: option))
        }.sorted { $0.calculation.totalPayment < $1.calculation.totalPayment }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Compare All Options")
                .font(.headline)
                .foregroundColor(.furgCharcoal)

            VStack(spacing: 0) {
                // Header
                HStack {
                    Text("Option")
                        .frame(maxWidth: .infinity, alignment: .leading)
                    Text("Monthly")
                        .frame(width: 65, alignment: .trailing)
                    Text("Total")
                        .frame(width: 65, alignment: .trailing)
                    Text("Interest")
                        .frame(width: 60, alignment: .trailing)
                }
                .font(.caption)
                .foregroundColor(.furgCharcoal.opacity(0.6))
                .padding(.horizontal)
                .padding(.vertical, 10)

                Rectangle()
                    .fill(Color.furgMint.opacity(0.3))
                    .frame(height: 1)

                // Cash option (best)
                HStack {
                    HStack(spacing: 6) {
                        ZStack {
                            Circle()
                                .fill(LinearGradient(
                                    colors: [.furgSuccess, .furgMint],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ))
                                .frame(width: 20, height: 20)

                            Image(systemName: "banknote")
                                .font(.caption2)
                                .foregroundColor(.white)
                        }
                        Text("Pay Cash")
                            .font(.subheadline)
                            .foregroundColor(.furgCharcoal)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)

                    Text("—")
                        .frame(width: 65, alignment: .trailing)
                        .foregroundColor(.furgCharcoal.opacity(0.5))

                    Text(String(format: "$%.0f", purchasePrice))
                        .font(.subheadline)
                        .frame(width: 65, alignment: .trailing)
                        .foregroundColor(.furgCharcoal)

                    Text("$0")
                        .font(.subheadline)
                        .foregroundColor(.furgSuccess)
                        .frame(width: 60, alignment: .trailing)
                }
                .padding(.horizontal)
                .padding(.vertical, 12)
                .background(Color.furgSuccess.opacity(0.1))

                Rectangle()
                    .fill(Color.white.opacity(0.3))
                    .frame(height: 1)

                // Financing options
                ForEach(sortedOptions, id: \.option.id) { item in
                    HStack {
                        HStack(spacing: 6) {
                            ZStack {
                                Circle()
                                    .fill(LinearGradient(
                                        colors: [.furgSeafoam, .furgMint],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ))
                                    .frame(width: 20, height: 20)

                                Image(systemName: item.option.type.icon)
                                    .font(.caption2)
                                    .foregroundColor(.white)
                            }
                            Text(item.option.name)
                                .font(.subheadline)
                                .foregroundColor(.furgCharcoal)
                                .lineLimit(1)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)

                        Text(String(format: "$%.0f", item.calculation.monthlyPayment))
                            .font(.subheadline)
                            .frame(width: 65, alignment: .trailing)
                            .foregroundColor(.furgCharcoal)

                        Text(String(format: "$%.0f", item.calculation.totalPayment))
                            .font(.subheadline)
                            .frame(width: 65, alignment: .trailing)
                            .foregroundColor(.furgCharcoal)

                        Text(String(format: "$%.0f", item.calculation.totalInterest))
                            .font(.subheadline)
                            .foregroundColor(item.calculation.totalInterest > 0 ? .furgWarning : .furgSuccess)
                            .frame(width: 60, alignment: .trailing)
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 12)
                    .background(selectedOptionId == item.option.id ? Color.furgMint.opacity(0.1) : Color.clear)

                    if item.option.id != sortedOptions.last?.option.id {
                        Rectangle()
                            .fill(Color.white.opacity(0.3))
                            .frame(height: 1)
                            .padding(.horizontal)
                    }
                }
            }
            .background(Color.white.opacity(0.2))
            .cornerRadius(12)
        }
        .padding()
        .copilotCard()
        .padding(.horizontal)
    }
}

// Keep old names for backward compatibility
typealias PriceInputSection = GlassPriceInputSection
typealias CustomFinancingSection = GlassCustomFinancingSection
typealias FinancingOptionsSection = GlassFinancingOptionsSection
typealias FinancingOptionCard = GlassFinancingOptionCard
typealias CalculationResultSection = GlassCalculationResultSection
typealias ResultCard = GlassResultCard
typealias ComparisonTableSection = GlassComparisonTableSection

#Preview {
    FinancingCalculatorView()
        .environmentObject(WishlistManager())
}
