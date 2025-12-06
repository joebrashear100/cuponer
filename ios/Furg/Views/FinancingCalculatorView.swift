//
//  FinancingCalculatorView.swift
//  Furg
//
//  Financing options calculator and comparison view
//

import SwiftUI

struct FinancingCalculatorView: View {
    @EnvironmentObject var wishlistManager: WishlistManager
    @State private var purchasePrice: String = "1000"
    @State private var selectedOptionId: String?
    @State private var showCustomCalculator = false

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
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Price Input
                    PriceInputSection(purchasePrice: $purchasePrice)

                    // Toggle between preset and custom
                    Picker("Mode", selection: $showCustomCalculator) {
                        Text("Preset Options").tag(false)
                        Text("Custom Terms").tag(true)
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal)

                    if showCustomCalculator {
                        CustomFinancingSection(
                            customApr: $customApr,
                            customTermMonths: $customTermMonths
                        )
                    } else {
                        FinancingOptionsSection(
                            options: applicableOptions,
                            selectedOptionId: $selectedOptionId,
                            priceValue: priceValue,
                            wishlistManager: wishlistManager
                        )
                    }

                    // Calculation Result
                    if let calc = calculation {
                        CalculationResultSection(
                            calculation: calc,
                            purchasePrice: priceValue,
                            option: showCustomCalculator ? nil : selectedOption
                        )
                    }

                    // Comparison Table
                    if priceValue > 0 && !showCustomCalculator && !applicableOptions.isEmpty {
                        ComparisonTableSection(
                            options: applicableOptions,
                            purchasePrice: priceValue,
                            wishlistManager: wishlistManager,
                            selectedOptionId: selectedOptionId
                        )
                    }
                }
                .padding(.vertical)
            }
            .navigationTitle("Financing Calculator")
        }
    }
}

// MARK: - Price Input Section

struct PriceInputSection: View {
    @Binding var purchasePrice: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Purchase Price")
                .font(.headline)

            HStack {
                Text("$")
                    .font(.title2)
                    .foregroundColor(.gray)

                TextField("1000", text: $purchasePrice)
                    .font(.title)
                    .fontWeight(.bold)
                    .keyboardType(.decimalPad)
            }
            .padding()
            .background(Color(uiColor: .secondarySystemBackground))
            .cornerRadius(12)
        }
        .padding(.horizontal)
    }
}

// MARK: - Custom Financing Section

struct CustomFinancingSection: View {
    @Binding var customApr: String
    @Binding var customTermMonths: String

    var body: some View {
        VStack(spacing: 16) {
            HStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("APR (%)")
                        .font(.caption)
                        .foregroundColor(.gray)

                    TextField("15", text: $customApr)
                        .keyboardType(.decimalPad)
                        .padding()
                        .background(Color(uiColor: .tertiarySystemBackground))
                        .cornerRadius(8)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text("Term (months)")
                        .font(.caption)
                        .foregroundColor(.gray)

                    TextField("12", text: $customTermMonths)
                        .keyboardType(.numberPad)
                        .padding()
                        .background(Color(uiColor: .tertiarySystemBackground))
                        .cornerRadius(8)
                }
            }
        }
        .padding()
        .background(Color(uiColor: .secondarySystemBackground))
        .cornerRadius(12)
        .padding(.horizontal)
    }
}

// MARK: - Financing Options Section

struct FinancingOptionsSection: View {
    let options: [FinancingOption]
    @Binding var selectedOptionId: String?
    let priceValue: Double
    let wishlistManager: WishlistManager

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Financing Options")
                .font(.headline)
                .padding(.horizontal)

            if options.isEmpty {
                Text("No financing options available for this price.\nTry a different amount or use custom terms.")
                    .font(.subheadline)
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color(uiColor: .secondarySystemBackground))
                    .cornerRadius(12)
                    .padding(.horizontal)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(options) { option in
                            FinancingOptionCard(
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

struct FinancingOptionCard: View {
    let option: FinancingOption
    let isSelected: Bool
    let calculation: FinancingCalculation
    let onSelect: () -> Void

    var body: some View {
        Button(action: onSelect) {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: option.type.icon)
                        .foregroundColor(.blue)

                    Text(option.name)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .lineLimit(1)
                }

                Text("\(String(format: "%.1f", option.apr))% APR")
                    .font(.caption)
                    .foregroundColor(.gray)

                Text("\(option.termMonths) months")
                    .font(.caption)
                    .foregroundColor(.gray)

                Divider()

                Text(calculation.formattedMonthlyPayment)
                    .font(.headline)
                    .foregroundColor(.orange)

                Text("/month")
                    .font(.caption2)
                    .foregroundColor(.gray)
            }
            .padding()
            .frame(width: 140)
            .background(Color(uiColor: .secondarySystemBackground))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color.blue : Color.clear, lineWidth: 2)
            )
            .cornerRadius(12)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Calculation Result Section

struct CalculationResultSection: View {
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

                Spacer()

                if let option = option {
                    Text(option.name)
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.blue.opacity(0.2))
                        .cornerRadius(8)
                }
            }

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                ResultCard(
                    title: "Monthly Payment",
                    value: calculation.formattedMonthlyPayment,
                    color: .orange,
                    isLarge: true
                )

                ResultCard(
                    title: "Total Payment",
                    value: calculation.formattedTotalPayment,
                    color: .primary
                )

                ResultCard(
                    title: "Total Interest",
                    value: calculation.formattedTotalInterest,
                    color: calculation.totalInterest > 0 ? .red : .green
                )

                ResultCard(
                    title: "Payoff Date",
                    value: calculation.payoffDate.formatted(.dateTime.month(.abbreviated).year()),
                    color: .primary
                )
            }

            // Interest Warning
            if calculation.totalInterest > 0 {
                HStack {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.orange)

                    Text("You'll pay \(calculation.formattedTotalInterest) in interest (\(String(format: "%.1f", interestPercentage))% more than the purchase price)")
                        .font(.caption)
                        .foregroundColor(.orange)
                }
                .padding()
                .background(Color.orange.opacity(0.1))
                .cornerRadius(8)
            } else {
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)

                    Text("No interest! You only pay the purchase price.")
                        .font(.caption)
                        .foregroundColor(.green)
                }
                .padding()
                .background(Color.green.opacity(0.1))
                .cornerRadius(8)
            }
        }
        .padding()
        .background(Color(uiColor: .secondarySystemBackground))
        .cornerRadius(12)
        .padding(.horizontal)
    }
}

struct ResultCard: View {
    let title: String
    let value: String
    let color: Color
    var isLarge: Bool = false

    var body: some View {
        VStack(alignment: .center, spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundColor(.gray)

            Text(value)
                .font(isLarge ? .title2 : .headline)
                .fontWeight(.bold)
                .foregroundColor(color)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(uiColor: .tertiarySystemBackground))
        .cornerRadius(8)
    }
}

// MARK: - Comparison Table Section

struct ComparisonTableSection: View {
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
                .padding(.horizontal)

            VStack(spacing: 0) {
                // Header
                HStack {
                    Text("Option")
                        .frame(maxWidth: .infinity, alignment: .leading)
                    Text("Monthly")
                        .frame(width: 70, alignment: .trailing)
                    Text("Total")
                        .frame(width: 70, alignment: .trailing)
                    Text("Interest")
                        .frame(width: 70, alignment: .trailing)
                }
                .font(.caption)
                .foregroundColor(.gray)
                .padding(.horizontal)
                .padding(.vertical, 8)

                Divider()

                // Cash option
                HStack {
                    HStack(spacing: 4) {
                        Image(systemName: "banknote")
                            .foregroundColor(.green)
                        Text("Pay Cash")
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)

                    Text("—")
                        .frame(width: 70, alignment: .trailing)

                    Text(String(format: "$%.0f", purchasePrice))
                        .frame(width: 70, alignment: .trailing)

                    Text("$0")
                        .foregroundColor(.green)
                        .frame(width: 70, alignment: .trailing)
                }
                .font(.subheadline)
                .padding(.horizontal)
                .padding(.vertical, 10)
                .background(Color.green.opacity(0.1))

                Divider()

                // Financing options
                ForEach(sortedOptions, id: \.option.id) { item in
                    HStack {
                        HStack(spacing: 4) {
                            Image(systemName: item.option.type.icon)
                                .foregroundColor(.blue)
                            Text(item.option.name)
                                .lineLimit(1)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)

                        Text(String(format: "$%.0f", item.calculation.monthlyPayment))
                            .frame(width: 70, alignment: .trailing)

                        Text(String(format: "$%.0f", item.calculation.totalPayment))
                            .frame(width: 70, alignment: .trailing)

                        Text(String(format: "$%.0f", item.calculation.totalInterest))
                            .foregroundColor(item.calculation.totalInterest > 0 ? .red : .green)
                            .frame(width: 70, alignment: .trailing)
                    }
                    .font(.subheadline)
                    .padding(.horizontal)
                    .padding(.vertical, 10)
                    .background(selectedOptionId == item.option.id ? Color.blue.opacity(0.1) : Color.clear)

                    if item.option.id != sortedOptions.last?.option.id {
                        Divider()
                    }
                }
            }
            .background(Color(uiColor: .secondarySystemBackground))
            .cornerRadius(12)
            .padding(.horizontal)
        }
    }
}

#Preview {
    FinancingCalculatorView()
        .environmentObject(WishlistManager())
}
