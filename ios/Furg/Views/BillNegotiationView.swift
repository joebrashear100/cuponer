//
//  BillNegotiationView.swift
//  Furg
//
//  AI-powered bill negotiation assistant and savings tracker
//

import SwiftUI

struct BillNegotiationView: View {
    @Environment(\.dismiss) var dismiss
    @State private var animate = false
    @State private var selectedBill: NegotiableBill?
    @State private var showNegotiationScript = false
    @State private var selectedScript: NegotiationScript?

    // Demo negotiable bills
    let bills: [NegotiableBill] = [
        NegotiableBill(
            name: "Xfinity Internet",
            category: .internet,
            currentAmount: 89.99,
            marketAverage: 65.00,
            potentialSavings: 24.99,
            lastNegotiated: nil,
            negotiationDifficulty: .easy,
            successRate: 85,
            tips: ["Mention competitor pricing", "Ask about promotional rates", "Threaten to cancel"],
            phoneNumber: "1-800-934-6489"
        ),
        NegotiableBill(
            name: "AT&T Wireless",
            category: .phone,
            currentAmount: 125.00,
            marketAverage: 95.00,
            potentialSavings: 30.00,
            lastNegotiated: Calendar.current.date(byAdding: .month, value: -8, to: Date()),
            negotiationDifficulty: .medium,
            successRate: 70,
            tips: ["Ask about loyalty discounts", "Check for military/veteran discounts", "Bundle services"],
            phoneNumber: "1-800-331-0500"
        ),
        NegotiableBill(
            name: "State Farm Insurance",
            category: .insurance,
            currentAmount: 156.00,
            marketAverage: 120.00,
            potentialSavings: 36.00,
            lastNegotiated: nil,
            negotiationDifficulty: .medium,
            successRate: 65,
            tips: ["Bundle home and auto", "Ask about safe driver discounts", "Increase deductible"],
            phoneNumber: "1-800-782-8332"
        ),
        NegotiableBill(
            name: "Planet Fitness",
            category: .subscription,
            currentAmount: 24.99,
            marketAverage: 10.00,
            potentialSavings: 14.99,
            lastNegotiated: nil,
            negotiationDifficulty: .hard,
            successRate: 40,
            tips: ["Negotiate at end of month", "Ask for annual rate", "Mention competitor offers"],
            phoneNumber: "1-844-880-7180"
        ),
        NegotiableBill(
            name: "ADT Security",
            category: .subscription,
            currentAmount: 45.99,
            marketAverage: 28.00,
            potentialSavings: 17.99,
            lastNegotiated: nil,
            negotiationDifficulty: .easy,
            successRate: 80,
            tips: ["High churn industry - they want to keep you", "Ask for loyalty rate", "Mention DIY alternatives"],
            phoneNumber: "1-800-280-6946"
        )
    ]

    var totalPotentialSavings: Double {
        bills.reduce(0) { $0 + $1.potentialSavings }
    }

    var totalAnnualSavings: Double {
        totalPotentialSavings * 12
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.furgCharcoal.ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 24) {
                        // Savings potential header
                        savingsPotentialCard
                            .offset(y: animate ? 0 : 20)
                            .opacity(animate ? 1 : 0)

                        // Quick tips
                        negotiationTips
                            .offset(y: animate ? 0 : 20)
                            .opacity(animate ? 1 : 0)
                            .animation(.spring(response: 0.6).delay(0.1), value: animate)

                        // Bills to negotiate
                        billsSection
                            .offset(y: animate ? 0 : 20)
                            .opacity(animate ? 1 : 0)
                            .animation(.spring(response: 0.6).delay(0.2), value: animate)

                        // Success stories
                        successStories
                            .offset(y: animate ? 0 : 20)
                            .opacity(animate ? 1 : 0)
                            .animation(.spring(response: 0.6).delay(0.3), value: animate)

                        Spacer(minLength: 40)
                    }
                    .padding(.horizontal, 20)
                }
            }
            .navigationTitle("Bill Negotiation")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                        .foregroundColor(.furgMint)
                }
            }
            .onAppear {
                withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                    animate = true
                }
            }
            .sheet(item: $selectedBill) { bill in
                BillNegotiationDetailSheet(bill: bill)
            }
            .sheet(item: $selectedScript) { script in
                NegotiationScriptSheet(script: script)
            }
        }
    }

    // MARK: - Savings Potential Card

    private var savingsPotentialCard: some View {
        VStack(spacing: 20) {
            HStack {
                Image(systemName: "banknote.fill")
                    .font(.title2)
                    .foregroundColor(.furgMint)

                VStack(alignment: .leading, spacing: 2) {
                    Text("Potential Savings")
                        .font(.system(size: 14))
                        .foregroundColor(.white.opacity(0.6))

                    Text("$\(Int(totalAnnualSavings))/year")
                        .font(.system(size: 32, weight: .bold))
                        .foregroundColor(.white)
                }

                Spacer()
            }

            HStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Monthly")
                        .font(.system(size: 11))
                        .foregroundColor(.white.opacity(0.4))
                    Text("$\(Int(totalPotentialSavings))")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.furgSuccess)
                }

                Spacer()

                VStack(alignment: .center, spacing: 4) {
                    Text("Bills Found")
                        .font(.system(size: 11))
                        .foregroundColor(.white.opacity(0.4))
                    Text("\(bills.count)")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.white)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 4) {
                    Text("Avg. Success")
                        .font(.system(size: 11))
                        .foregroundColor(.white.opacity(0.4))
                    Text("68%")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.furgMint)
                }
            }

            Button {
                if let firstBill = bills.first {
                    selectedBill = firstBill
                }
            } label: {
                HStack {
                    Image(systemName: "phone.fill")
                    Text("Start Negotiating")
                }
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.furgCharcoal)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(
                    LinearGradient(
                        colors: [.furgMint, .furgSeafoam],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
        }
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(
                    LinearGradient(
                        colors: [Color.furgMint.opacity(0.2), Color.furgMint.opacity(0.05)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 24)
                        .stroke(Color.furgMint.opacity(0.3), lineWidth: 1)
                )
        )
    }

    // MARK: - Negotiation Tips

    private var negotiationTips: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "lightbulb.fill")
                    .foregroundColor(.furgWarning)
                Text("Pro Tips")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    TipCard(
                        icon: "clock.fill",
                        title: "Best Time",
                        tip: "Call at month-end when reps have quotas to meet"
                    )

                    TipCard(
                        icon: "person.wave.2.fill",
                        title: "Be Nice",
                        tip: "Reps help friendly customers more"
                    )

                    TipCard(
                        icon: "arrow.left.arrow.right",
                        title: "Competitors",
                        tip: "Research competitor prices before calling"
                    )

                    TipCard(
                        icon: "xmark.circle.fill",
                        title: "Cancel Card",
                        tip: "Asking to cancel often gets you to retention dept"
                    )
                }
            }
        }
    }

    // MARK: - Bills Section

    private var billsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Bills to Negotiate")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)

                Spacer()

                Text("Sorted by savings")
                    .font(.system(size: 12))
                    .foregroundColor(.white.opacity(0.4))
            }

            ForEach(bills.sorted(by: { $0.potentialSavings > $1.potentialSavings })) { bill in
                Button {
                    selectedBill = bill
                } label: {
                    NegotiableBillRow(bill: bill)
                }
                .buttonStyle(.plain)
            }
        }
    }

    // MARK: - Success Stories

    private var successStories: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Success Stories")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.white)

            VStack(spacing: 10) {
                SuccessStoryRow(
                    name: "Sarah M.",
                    bill: "Comcast",
                    saved: 35,
                    quote: "Used the cancellation script and got $35/mo off instantly!"
                )

                SuccessStoryRow(
                    name: "Mike T.",
                    bill: "AT&T",
                    saved: 25,
                    quote: "Mentioned competitor pricing and they matched it right away."
                )

                SuccessStoryRow(
                    name: "Lisa K.",
                    bill: "State Farm",
                    saved: 40,
                    quote: "Bundled home & auto, saved $40/mo. Should've done this years ago!"
                )
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.05))
        )
    }
}

// MARK: - Supporting Types

struct NegotiableBill: Identifiable {
    let id = UUID()
    let name: String
    let category: BillCategory
    let currentAmount: Double
    let marketAverage: Double
    let potentialSavings: Double
    let lastNegotiated: Date?
    let negotiationDifficulty: Difficulty
    let successRate: Int
    let tips: [String]
    let phoneNumber: String

    enum BillCategory: String {
        case internet = "Internet"
        case phone = "Phone"
        case insurance = "Insurance"
        case subscription = "Subscription"
        case utility = "Utility"

        var icon: String {
            switch self {
            case .internet: return "wifi"
            case .phone: return "iphone"
            case .insurance: return "shield.fill"
            case .subscription: return "repeat"
            case .utility: return "bolt.fill"
            }
        }

        var color: Color {
            switch self {
            case .internet: return .blue
            case .phone: return .green
            case .insurance: return .orange
            case .subscription: return .purple
            case .utility: return .yellow
            }
        }
    }

    enum Difficulty: String {
        case easy = "Easy"
        case medium = "Medium"
        case hard = "Hard"

        var color: Color {
            switch self {
            case .easy: return .furgSuccess
            case .medium: return .furgWarning
            case .hard: return .furgDanger
            }
        }
    }
}

struct NegotiationScript: Identifiable {
    let id = UUID()
    let title: String
    let steps: [String]
}

// MARK: - Supporting Views

private struct TipCard: View {
    let icon: String
    let title: String
    let tip: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(.furgMint)
                Text(title)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.white)
            }

            Text(tip)
                .font(.system(size: 12))
                .foregroundColor(.white.opacity(0.6))
                .lineLimit(2)
        }
        .padding(12)
        .frame(width: 160)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.05))
        )
    }
}

private struct NegotiableBillRow: View {
    let bill: NegotiableBill

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(bill.category.color.opacity(0.2))
                    .frame(width: 44, height: 44)

                Image(systemName: bill.category.icon)
                    .font(.system(size: 18))
                    .foregroundColor(bill.category.color)
            }

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(bill.name)
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(.white)

                    Text(bill.negotiationDifficulty.rawValue)
                        .font(.system(size: 9, weight: .semibold))
                        .foregroundColor(bill.negotiationDifficulty.color)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Capsule().fill(bill.negotiationDifficulty.color.opacity(0.2)))
                }

                HStack(spacing: 8) {
                    Text("$\(String(format: "%.2f", bill.currentAmount))/mo")
                        .font(.system(size: 12))
                        .foregroundColor(.white.opacity(0.5))

                    Text("\(bill.successRate)% success")
                        .font(.system(size: 11))
                        .foregroundColor(.furgMint)
                }
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                Text("-$\(Int(bill.potentialSavings))")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.furgSuccess)

                Text("potential")
                    .font(.system(size: 10))
                    .foregroundColor(.white.opacity(0.4))
            }

            Image(systemName: "chevron.right")
                .font(.system(size: 12))
                .foregroundColor(.white.opacity(0.3))
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.05))
        )
    }
}

private struct SuccessStoryRow: View {
    let name: String
    let bill: String
    let saved: Int
    let quote: String

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            ZStack {
                Circle()
                    .fill(Color.furgMint.opacity(0.2))
                    .frame(width: 36, height: 36)

                Text(name.prefix(1))
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.furgMint)
            }

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(name)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.white)

                    Text("saved $\(saved)/mo on \(bill)")
                        .font(.system(size: 12))
                        .foregroundColor(.furgSuccess)
                }

                Text("\"\(quote)\"")
                    .font(.system(size: 12))
                    .foregroundColor(.white.opacity(0.6))
                    .italic()
            }
        }
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.white.opacity(0.03))
        )
    }
}

private struct BillNegotiationDetailSheet: View {
    let bill: NegotiableBill
    @Environment(\.dismiss) var dismiss
    @State private var showScript = false

    var body: some View {
        NavigationStack {
            ZStack {
                Color.furgCharcoal.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 24) {
                        // Bill header
                        VStack(spacing: 16) {
                            ZStack {
                                Circle()
                                    .fill(bill.category.color.opacity(0.2))
                                    .frame(width: 80, height: 80)

                                Image(systemName: bill.category.icon)
                                    .font(.system(size: 32))
                                    .foregroundColor(bill.category.color)
                            }

                            Text(bill.name)
                                .font(.system(size: 24, weight: .bold))
                                .foregroundColor(.white)

                            HStack(spacing: 16) {
                                VStack(spacing: 2) {
                                    Text("Current")
                                        .font(.system(size: 11))
                                        .foregroundColor(.white.opacity(0.4))
                                    Text("$\(String(format: "%.2f", bill.currentAmount))")
                                        .font(.system(size: 18, weight: .bold))
                                        .foregroundColor(.white)
                                }

                                Image(systemName: "arrow.right")
                                    .foregroundColor(.furgMint)

                                VStack(spacing: 2) {
                                    Text("Target")
                                        .font(.system(size: 11))
                                        .foregroundColor(.white.opacity(0.4))
                                    Text("$\(String(format: "%.2f", bill.marketAverage))")
                                        .font(.system(size: 18, weight: .bold))
                                        .foregroundColor(.furgSuccess)
                                }
                            }
                        }
                        .padding(.top, 20)

                        // Savings breakdown
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Potential Savings")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.white)

                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Monthly")
                                        .font(.system(size: 12))
                                        .foregroundColor(.white.opacity(0.5))
                                    Text("$\(Int(bill.potentialSavings))")
                                        .font(.system(size: 24, weight: .bold))
                                        .foregroundColor(.furgSuccess)
                                }

                                Spacer()

                                VStack(alignment: .trailing, spacing: 4) {
                                    Text("Yearly")
                                        .font(.system(size: 12))
                                        .foregroundColor(.white.opacity(0.5))
                                    Text("$\(Int(bill.potentialSavings * 12))")
                                        .font(.system(size: 24, weight: .bold))
                                        .foregroundColor(.furgMint)
                                }
                            }
                        }
                        .padding(16)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color.furgSuccess.opacity(0.1))
                        )
                        .padding(.horizontal, 20)

                        // Tips
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Negotiation Tips")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.white)

                            ForEach(bill.tips, id: \.self) { tip in
                                HStack(alignment: .top, spacing: 10) {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(.furgMint)

                                    Text(tip)
                                        .font(.system(size: 14))
                                        .foregroundColor(.white.opacity(0.7))
                                }
                            }
                        }
                        .padding(16)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color.white.opacity(0.05))
                        )
                        .padding(.horizontal, 20)

                        // Script button
                        Button {
                            showScript = true
                        } label: {
                            HStack {
                                Image(systemName: "doc.text.fill")
                                Text("View Negotiation Script")
                            }
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.furgMint)
                            .padding(.vertical, 12)
                            .frame(maxWidth: .infinity)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.furgMint, lineWidth: 1)
                            )
                        }
                        .padding(.horizontal, 20)

                        Spacer(minLength: 100)
                    }
                }
            }
            .navigationTitle(bill.name)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                        .foregroundColor(.furgMint)
                }
            }
            .overlay(alignment: .bottom) {
                Button {
                    if let url = URL(string: "tel://\(bill.phoneNumber.replacingOccurrences(of: "-", with: ""))") {
                        UIApplication.shared.open(url)
                    }
                } label: {
                    HStack {
                        Image(systemName: "phone.fill")
                        Text("Call \(bill.phoneNumber)")
                    }
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.furgCharcoal)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        LinearGradient(
                            colors: [.furgMint, .furgSeafoam],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 20)
            }
            .sheet(isPresented: $showScript) {
                NegotiationScriptSheet(script: NegotiationScript(
                    title: "\(bill.name) Script",
                    steps: [
                        "\"Hi, I've been a loyal customer for [X years] and I'm calling about my bill.\"",
                        "\"I noticed my bill is $\(String(format: "%.2f", bill.currentAmount))/month, which seems high compared to what I'm seeing from competitors.\"",
                        "\"[Competitor] is offering similar service for around $\(String(format: "%.2f", bill.marketAverage))/month. Is there anything you can do to match or beat that?\"",
                        "If they say no: \"I really want to stay with \(bill.name), but I may need to switch if we can't find a better rate. Can I speak with the retention department?\"",
                        "If still no: \"I understand. I'd like to cancel my service effective [date].\" (This often triggers better offers)",
                        "If they offer a deal: \"Thank you! Can I get that in writing/email confirmation?\""
                    ]
                ))
            }
        }
    }
}

private struct NegotiationScriptSheet: View {
    let script: NegotiationScript
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                Color.furgCharcoal.ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        Text("Follow this script for best results:")
                            .font(.system(size: 14))
                            .foregroundColor(.white.opacity(0.6))
                            .padding(.top, 20)

                        ForEach(Array(script.steps.enumerated()), id: \.offset) { index, step in
                            HStack(alignment: .top, spacing: 14) {
                                ZStack {
                                    Circle()
                                        .fill(Color.furgMint.opacity(0.2))
                                        .frame(width: 32, height: 32)

                                    Text("\(index + 1)")
                                        .font(.system(size: 14, weight: .bold))
                                        .foregroundColor(.furgMint)
                                }

                                Text(step)
                                    .font(.system(size: 14))
                                    .foregroundColor(.white.opacity(0.8))
                                    .lineSpacing(4)
                            }
                            .padding(14)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color.white.opacity(0.05))
                            )
                        }

                        // Copy button
                        Button {
                            UIPasteboard.general.string = script.steps.enumerated().map { "\($0 + 1). \($1)" }.joined(separator: "\n\n")
                        } label: {
                            HStack {
                                Image(systemName: "doc.on.doc")
                                Text("Copy Script")
                            }
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.furgMint)
                            .padding(.vertical, 12)
                            .frame(maxWidth: .infinity)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.furgMint, lineWidth: 1)
                            )
                        }
                        .padding(.top, 8)

                        Spacer(minLength: 40)
                    }
                    .padding(.horizontal, 20)
                }
            }
            .navigationTitle("Negotiation Script")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                        .foregroundColor(.furgMint)
                }
            }
        }
    }
}

#Preview {
    BillNegotiationView()
}
