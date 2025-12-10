//
//  QuickDebtPaymentSheet.swift
//  Furg
//
//  Quick payment interface for recording debt payments without opening full Debt Payoff view
//

import SwiftUI

struct QuickDebtPaymentSheet: View {
    @Environment(\.dismiss) var dismiss
    @State private var selectedDebtIndex = 0
    @State private var paymentAmount = ""
    @State private var paymentMethod = "Balance Transfer"

    let sampleDebts = [
        ("Credit Card - Chase", "$4,250", "High Interest"),
        ("Student Loan - Federal", "$18,500", "Low Interest"),
        ("Auto Loan - Honda", "$12,000", "Medium Interest"),
        ("Personal Loan - SoFi", "$3,750", "Variable"),
    ]

    var body: some View {
        ZStack {
            Color.furgCharcoal.ignoresSafeArea()

            VStack(spacing: 0) {
                // Header
                HStack {
                    Text("Quick Debt Payment")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.white)

                    Spacer()

                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(.furgMint)
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
                .background(Color(red: 0.08, green: 0.08, blue: 0.12).opacity(0.95))
                .overlay(
                    VStack(spacing: 0) {
                        Spacer()
                        Divider()
                            .background(Color.white.opacity(0.1))
                    }
                )

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 20) {
                        // Select Debt Section
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Select Debt")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(.white.opacity(0.7))
                                .padding(.horizontal, 20)

                            VStack(spacing: 8) {
                                ForEach(0..<sampleDebts.count, id: \.self) { index in
                                    DebtSelectionRow(
                                        isSelected: selectedDebtIndex == index,
                                        debtName: sampleDebts[index].0,
                                        debtBalance: sampleDebts[index].1,
                                        interestType: sampleDebts[index].2
                                    ) {
                                        selectedDebtIndex = index
                                    }
                                }
                            }
                            .padding(.horizontal, 20)
                        }

                        // Payment Amount Section
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Payment Amount")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(.white.opacity(0.7))
                                .padding(.horizontal, 20)

                            HStack(spacing: 12) {
                                Text("$")
                                    .font(.system(size: 28, weight: .semibold))
                                    .foregroundColor(.furgMint)

                                TextField("0.00", text: $paymentAmount)
                                    .font(.system(size: 28, weight: .semibold))
                                    .foregroundColor(.white)
                                    .keyboardType(.decimalPad)

                                Spacer()
                            }
                            .padding(16)
                            .background(Color.white.opacity(0.03))
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .padding(.horizontal, 20)
                        }

                        // Payment Method Section
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Payment Method")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(.white.opacity(0.7))
                                .padding(.horizontal, 20)

                            HStack(spacing: 8) {
                                ForEach(["Balance Transfer", "Check", "ACH"], id: \.self) { method in
                                    Button {
                                        paymentMethod = method
                                    } label: {
                                        Text(method)
                                            .font(.system(size: 12, weight: .medium))
                                            .foregroundColor(paymentMethod == method ? .white : .white.opacity(0.6))
                                            .frame(maxWidth: .infinity)
                                            .padding(.vertical, 10)
                                            .background(
                                                paymentMethod == method
                                                    ? Color.furgMint.opacity(0.2)
                                                    : Color.white.opacity(0.03)
                                            )
                                            .clipShape(RoundedRectangle(cornerRadius: 10))
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 10)
                                                    .stroke(
                                                        paymentMethod == method ? Color.furgMint.opacity(0.4) : Color.white.opacity(0.1),
                                                        lineWidth: 1
                                                    )
                                            )
                                    }
                                }
                            }
                            .padding(.horizontal, 20)
                        }

                        // Payment Summary
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Summary")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(.white.opacity(0.7))
                                .padding(.horizontal, 20)

                            VStack(spacing: 10) {
                                HStack {
                                    Text("Debt:")
                                        .foregroundColor(.white.opacity(0.6))
                                    Spacer()
                                    Text(sampleDebts[selectedDebtIndex].0)
                                        .foregroundColor(.white)
                                        .font(.system(size: 13, weight: .medium))
                                }

                                Divider()
                                    .background(Color.white.opacity(0.1))

                                HStack {
                                    Text("Amount:")
                                        .foregroundColor(.white.opacity(0.6))
                                    Spacer()
                                    Text("$\(paymentAmount.isEmpty ? "0.00" : paymentAmount)")
                                        .foregroundColor(.furgMint)
                                        .font(.system(size: 13, weight: .semibold))
                                }

                                HStack {
                                    Text("Method:")
                                        .foregroundColor(.white.opacity(0.6))
                                    Spacer()
                                    Text(paymentMethod)
                                        .foregroundColor(.white)
                                        .font(.system(size: 13, weight: .medium))
                                }
                            }
                            .padding(16)
                            .background(Color.white.opacity(0.03))
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .padding(.horizontal, 20)
                        }

                        // Submit Button
                        VStack(spacing: 12) {
                            Button {
                                // TODO: Submit payment via DebtPayoffManager
                                dismiss()
                            } label: {
                                HStack {
                                    Image(systemName: "checkmark.circle.fill")
                                        .font(.system(size: 16, weight: .semibold))

                                    Text("Record Payment")
                                        .font(.system(size: 16, weight: .semibold))

                                    Spacer()
                                }
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(
                                    LinearGradient(
                                        colors: [.furgMint, Color(red: 0.3, green: 0.85, blue: 0.6)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                                .shadow(color: Color.furgMint.opacity(0.3), radius: 8, y: 4)
                            }
                            .disabled(paymentAmount.isEmpty || Double(paymentAmount) ?? 0 <= 0)
                            .opacity(paymentAmount.isEmpty || Double(paymentAmount) ?? 0 <= 0 ? 0.5 : 1)
                        }
                        .padding(.horizontal, 20)
                        .padding(.bottom, 20)
                    }
                    .padding(.vertical, 20)
                }
            }
        }
    }
}

// MARK: - Debt Selection Row
struct DebtSelectionRow: View {
    let isSelected: Bool
    let debtName: String
    let debtBalance: String
    let interestType: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                // Selection indicator
                ZStack {
                    Circle()
                        .fill(isSelected ? Color.furgMint : Color.white.opacity(0.1))
                        .frame(width: 20, height: 20)

                    if isSelected {
                        Image(systemName: "checkmark")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(.furgCharcoal)
                    }
                }

                // Debt info
                VStack(alignment: .leading, spacing: 4) {
                    Text(debtName)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.white)

                    HStack(spacing: 8) {
                        Text(debtBalance)
                            .font(.system(size: 12))
                            .foregroundColor(.white.opacity(0.6))

                        Text("•")
                            .foregroundColor(.white.opacity(0.3))

                        Text(interestType)
                            .font(.system(size: 12))
                            .foregroundColor(.white.opacity(0.5))
                    }
                }

                Spacer()
            }
            .padding(12)
            .background(isSelected ? Color.furgMint.opacity(0.15) : Color.white.opacity(0.03))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(
                        isSelected ? Color.furgMint.opacity(0.4) : Color.white.opacity(0.1),
                        lineWidth: 1
                    )
            )
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    QuickDebtPaymentSheet()
        .environmentObject(FinanceManager())
}
