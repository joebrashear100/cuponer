//
//  CardRecommendationsView.swift
//  Furg
//
//  Smart credit/debit card recommendations based on spending patterns
//

import SwiftUI

struct CardRecommendationsView: View {
    @Environment(\.dismiss) var dismiss
    @StateObject private var cardOptimizer = CardOptimizer.shared
    @State private var animate = false
    @State private var selectedCard: CardRecommendation?
    @State private var showingApplySheet = false

    // Compute spending data from CardOptimizer
    var monthlySpending: [String: Double] {
        var spending: [String: Double] = [:]
        for transaction in cardOptimizer.transactions {
            let category = transaction.category?.rawValue ?? "Other"
            spending[category, default: 0] += abs(transaction.amount)
        }
        return spending
    }

    var totalMonthlySpend: Double {
        monthlySpending.values.reduce(0, +)
    }

    // Card recommendations based on spending
    var recommendations: [CardRecommendation] {
        let optimizedCards = cardOptimizer.recommendCards()
        if optimizedCards.isEmpty {
            return demoRecommendations
        }
        return optimizedCards.map { card in
            convertToUIModel(card)
        }
    }

    // Convert CardOptimizer model to UI model
    private func convertToUIModel(_ card: CreditCard) -> CardRecommendation {
        let matchScore = calculateMatchScore(for: card)
        let estimatedAnnualValue = calculateAnnualValue(for: card)

        return CardRecommendation(
            name: card.name,
            issuer: card.issuer,
            type: card.cardType == "Credit" ? .credit : .debit,
            annualFee: Int(card.annualFee),
            signupBonus: "\(Int(card.signupBonus)) \(card.bonusType)",
            signupBonusValue: Int(card.signupBonus),
            signupRequirement: "Minimum spend requirements apply",
            topCategories: convertCategories(from: card),
            estimatedAnnualValue: estimatedAnnualValue,
            matchScore: matchScore,
            matchReason: generateMatchReason(for: card, score: matchScore),
            pros: generatePros(for: card),
            cons: generateCons(for: card),
            creditScoreNeeded: card.minCreditScore > 750 ? "Excellent (750+)" : card.minCreditScore > 700 ? "Good (700+)" : "Fair (620+)",
            color: getColorForIssuer(card.issuer)
        )
    }

    private func calculateMatchScore(for card: CreditCard) -> Int {
        var score = 50

        // Bonus for matching top spending categories
        let topCategories = monthlySpending.sorted { $0.value > $1.value }.prefix(3)
        for (category, _) in topCategories {
            if card.rewards.contains(where: { $0.category.lowercased() == category.lowercased() }) {
                score += 10
            }
        }

        // Bonus for no annual fee
        if card.annualFee == 0 {
            score += 5
        }

        return min(score, 100)
    }

    private func calculateAnnualValue(for card: CreditCard) -> Double {
        var value = card.signupBonus

        // Estimate annual rewards value
        let topCategory = monthlySpending.max(by: { $0.value < $1.value })
        if let (category, amount) = topCategory,
           let reward = card.rewards.first(where: { $0.category.lowercased() == category.lowercased() }) {
            let monthlyReward = (amount * reward.rate) / 100
            value += monthlyReward * 12
        }

        return value - card.annualFee
    }

    private func convertCategories(from card: CreditCard) -> [CardCategory] {
        return card.rewards.map { reward in
            CardCategory(
                name: reward.category,
                multiplier: reward.rate,
                type: "% cash back"
            )
        }
    }

    private func generateMatchReason(for card: CreditCard, score: Int) -> String {
        let topSpending = monthlySpending.max(by: { $0.value < $1.value })
        if let (category, amount) = topSpending {
            return "Great match for your spending, especially \(category) ($\(Int(amount))/mo)"
        }
        return "Well-suited for your spending patterns"
    }

    private func generatePros(for card: CreditCard) -> [String] {
        var pros: [String] = []

        if card.annualFee == 0 {
            pros.append("No annual fee")
        }

        if card.signupBonus > 0 {
            pros.append("Generous signup bonus")
        }

        if !card.rewards.isEmpty {
            pros.append("Competitive rewards in key categories")
        }

        return pros.isEmpty ? ["Strong rewards program"] : pros
    }

    private func generateCons(for card: CreditCard) -> [String] {
        var cons: [String] = []

        if card.annualFee > 0 {
            cons.append("$\(Int(card.annualFee)) annual fee")
        }

        if card.minCreditScore > 700 {
            cons.append("Requires good to excellent credit")
        }

        return cons.isEmpty ? ["May have spending requirements"] : cons
    }

    private func getColorForIssuer(_ issuer: String) -> Color {
        switch issuer.lowercased() {
        case "chase": return .blue
        case "amex", "american express": return .yellow
        case "citi": return .cyan
        case "discover": return .orange
        case "capital one": return .red
        default: return .purple
        }
    }

    private var demoRecommendations: [CardRecommendation] {
        [
            CardRecommendation(
                name: "Chase Sapphire Preferred",
                issuer: "Chase",
                type: .credit,
                annualFee: 95,
                signupBonus: "60,000 points",
                signupBonusValue: 750,
                signupRequirement: "Spend $4,000 in first 3 months",
                topCategories: [
                    CardCategory(name: "Travel", multiplier: 5, type: "points"),
                    CardCategory(name: "Dining", multiplier: 3, type: "points"),
                    CardCategory(name: "Streaming", multiplier: 3, type: "points"),
                    CardCategory(name: "Everything Else", multiplier: 1, type: "points")
                ],
                estimatedAnnualValue: 890,
                matchScore: 95,
                matchReason: "Perfect for your high dining ($687/mo) and travel spending",
                pros: ["Excellent travel rewards", "Trip protection", "No foreign transaction fees", "Points transfer to airlines/hotels"],
                cons: ["$95 annual fee", "Requires good credit"],
                creditScoreNeeded: "Good to Excellent (700+)",
                color: .blue
            ),
            CardRecommendation(
                name: "American Express Gold",
                issuer: "American Express",
                type: .credit,
                annualFee: 250,
                signupBonus: "60,000 points",
                signupBonusValue: 720,
                signupRequirement: "Spend $6,000 in first 6 months",
                topCategories: [
                    CardCategory(name: "Dining", multiplier: 4, type: "points"),
                    CardCategory(name: "Groceries", multiplier: 4, type: "points"),
                    CardCategory(name: "Everything Else", multiplier: 1, type: "points")
                ],
                estimatedAnnualValue: 1240,
                matchScore: 92,
                matchReason: "Maximizes your dining & grocery spend ($1,229/mo combined)",
                pros: ["4x on dining & groceries", "$120 dining credit", "$120 Uber credit", "Great travel partners"],
                cons: ["$250 annual fee (offset by credits)", "Not accepted everywhere"],
                creditScoreNeeded: "Good to Excellent (700+)",
                color: .yellow
            ),
            CardRecommendation(
                name: "Citi Double Cash",
                issuer: "Citi",
                type: .credit,
                annualFee: 0,
                signupBonus: "$200 cash back",
                signupBonusValue: 200,
                signupRequirement: "Spend $1,500 in first 6 months",
                topCategories: [
                    CardCategory(name: "Everything", multiplier: 2, type: "% cash back")
                ],
                estimatedAnnualValue: 538,
                matchScore: 85,
                matchReason: "Simple 2% on everything - great no-fee option",
                pros: ["No annual fee", "Simple flat rate", "No category tracking"],
                cons: ["No signup bonus", "No travel perks", "Foreign transaction fees"],
                creditScoreNeeded: "Good (670+)",
                color: .cyan
            ),
            CardRecommendation(
                name: "Discover it Cash Back",
                issuer: "Discover",
                type: .credit,
                annualFee: 0,
                signupBonus: "Cashback Match",
                signupBonusValue: 300,
                signupRequirement: "All cash back matched in first year",
                topCategories: [
                    CardCategory(name: "Rotating Categories", multiplier: 5, type: "% cash back"),
                    CardCategory(name: "Everything Else", multiplier: 1, type: "% cash back")
                ],
                estimatedAnnualValue: 420,
                matchScore: 80,
                matchReason: "Great for building credit with rotating 5% categories",
                pros: ["No annual fee", "First year cashback matched", "Good for building credit"],
                cons: ["Rotating categories require activation", "Less accepted than Visa/MC"],
                creditScoreNeeded: "Fair to Good (630+)",
                color: .orange
            ),
            CardRecommendation(
                name: "SoFi Checking & Savings",
                issuer: "SoFi",
                type: .debit,
                annualFee: 0,
                signupBonus: "$300 bonus",
                signupBonusValue: 300,
                signupRequirement: "Set up direct deposit",
                topCategories: [
                    CardCategory(name: "APY", multiplier: 4.5, type: "% interest")
                ],
                estimatedAnnualValue: 360,
                matchScore: 78,
                matchReason: "High-yield checking with no fees - great for your savings",
                pros: ["4.5% APY", "No account fees", "Early direct deposit", "ATM fee reimbursement"],
                cons: ["Need direct deposit for best rate", "No physical branches"],
                creditScoreNeeded: "N/A - Debit",
                color: .purple
            )
        ]
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.furgCharcoal.ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 24) {
                        // Spending summary
                        spendingSummary
                            .offset(y: animate ? 0 : 20)
                            .opacity(animate ? 1 : 0)

                        // Best match card
                        if let bestMatch = recommendations.first {
                            bestMatchCard(bestMatch)
                                .offset(y: animate ? 0 : 20)
                                .opacity(animate ? 1 : 0)
                                .animation(.spring(response: 0.6).delay(0.1), value: animate)
                        }

                        // All recommendations
                        allRecommendations
                            .offset(y: animate ? 0 : 20)
                            .opacity(animate ? 1 : 0)
                            .animation(.spring(response: 0.6).delay(0.2), value: animate)

                        // Disclaimer
                        disclaimer
                            .offset(y: animate ? 0 : 20)
                            .opacity(animate ? 1 : 0)
                            .animation(.spring(response: 0.6).delay(0.3), value: animate)

                        Spacer(minLength: 40)
                    }
                    .padding(.horizontal, 20)
                }
            }
            .navigationTitle("Card Recommendations")
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
            .sheet(item: $selectedCard) { card in
                CardDetailSheet(card: card)
            }
        }
    }

    // MARK: - Spending Summary

    private var spendingSummary: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "chart.pie.fill")
                    .foregroundColor(.furgMint)
                Text("Your Spending Profile")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
            }

            Text("Based on $\(Int(totalMonthlySpend))/month in spending:")
                .font(.system(size: 13))
                .foregroundColor(.white.opacity(0.6))

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                ForEach(monthlySpending.sorted(by: { $0.value > $1.value }), id: \.key) { category, amount in
                    VStack(spacing: 4) {
                        Text("$\(Int(amount))")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.white)
                        Text(category)
                            .font(.system(size: 11))
                            .foregroundColor(.white.opacity(0.5))
                    }
                    .padding(.vertical, 10)
                    .frame(maxWidth: .infinity)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color.white.opacity(0.05))
                    )
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.white.opacity(0.03))
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color.white.opacity(0.1), lineWidth: 0.5)
                )
        )
    }

    // MARK: - Best Match Card

    private func bestMatchCard(_ card: CardRecommendation) -> some View {
        Button {
            selectedCard = card
        } label: {
            VStack(spacing: 16) {
                HStack {
                    Text("BEST MATCH")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(.furgCharcoal)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.furgMint)
                        .clipShape(Capsule())

                    Spacer()

                    Text("\(card.matchScore)% Match")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.furgMint)
                }

                HStack(spacing: 16) {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(card.color.gradient)
                        .frame(width: 60, height: 40)
                        .overlay(
                            Text(card.issuer.prefix(1))
                                .font(.system(size: 18, weight: .bold))
                                .foregroundColor(.white)
                        )

                    VStack(alignment: .leading, spacing: 4) {
                        Text(card.name)
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.white)

                        Text(card.issuer)
                            .font(.system(size: 13))
                            .foregroundColor(.white.opacity(0.5))
                    }

                    Spacer()
                }

                Text(card.matchReason)
                    .font(.system(size: 14))
                    .foregroundColor(.white.opacity(0.7))
                    .frame(maxWidth: .infinity, alignment: .leading)

                HStack(spacing: 20) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Annual Value")
                            .font(.system(size: 10))
                            .foregroundColor(.white.opacity(0.4))
                        Text("$\(Int(card.estimatedAnnualValue))")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.furgSuccess)
                    }

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Signup Bonus")
                            .font(.system(size: 10))
                            .foregroundColor(.white.opacity(0.4))
                        Text(card.signupBonus)
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.white)
                    }

                    Spacer()

                    Image(systemName: "chevron.right")
                        .foregroundColor(.white.opacity(0.3))
                }
            }
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(
                        LinearGradient(
                            colors: [card.color.opacity(0.3), card.color.opacity(0.1)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(card.color.opacity(0.3), lineWidth: 1)
                    )
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - All Recommendations

    private var allRecommendations: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Other Recommendations")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.white)

            ForEach(Array(recommendations.dropFirst())) { card in
                Button {
                    selectedCard = card
                } label: {
                    CardRecommendationRow(card: card)
                }
                .buttonStyle(.plain)
            }
        }
    }

    // MARK: - Disclaimer

    private var disclaimer: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "info.circle")
                .foregroundColor(.furgInfo)

            Text("Card recommendations are based on your spending patterns. Annual values are estimates. Always read terms and conditions before applying.")
                .font(.system(size: 11))
                .foregroundColor(.white.opacity(0.5))
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.furgInfo.opacity(0.1))
        )
    }
}

// MARK: - Supporting Types

struct CardRecommendation: Identifiable {
    let id = UUID()
    let name: String
    let issuer: String
    let type: CardType
    let annualFee: Int
    let signupBonus: String
    let signupBonusValue: Int
    let signupRequirement: String
    let topCategories: [CardCategory]
    let estimatedAnnualValue: Double
    let matchScore: Int
    let matchReason: String
    let pros: [String]
    let cons: [String]
    let creditScoreNeeded: String
    let color: Color

    enum CardType: String {
        case credit = "Credit Card"
        case debit = "Debit Card"
    }
}

struct CardCategory: Identifiable {
    let id = UUID()
    let name: String
    let multiplier: Double
    let type: String
}

// MARK: - Supporting Views

private struct CardRecommendationRow: View {
    let card: CardRecommendation

    var body: some View {
        HStack(spacing: 14) {
            RoundedRectangle(cornerRadius: 8)
                .fill(card.color.gradient)
                .frame(width: 50, height: 32)
                .overlay(
                    Text(card.issuer.prefix(1))
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.white)
                )

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(card.name)
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(.white)

                    if card.annualFee == 0 {
                        Text("NO FEE")
                            .font(.system(size: 8, weight: .bold))
                            .foregroundColor(.furgSuccess)
                            .padding(.horizontal, 4)
                            .padding(.vertical, 2)
                            .background(Capsule().fill(Color.furgSuccess.opacity(0.2)))
                    }
                }

                HStack(spacing: 12) {
                    Text("\(card.matchScore)% match")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.furgMint)

                    Text("$\(Int(card.estimatedAnnualValue))/yr value")
                        .font(.system(size: 12))
                        .foregroundColor(.white.opacity(0.5))
                }
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(.white.opacity(0.3))
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color.white.opacity(0.05))
        )
    }
}

private struct CardDetailSheet: View {
    let card: CardRecommendation
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                Color.furgCharcoal.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 24) {
                        // Card visual
                        RoundedRectangle(cornerRadius: 16)
                            .fill(card.color.gradient)
                            .frame(height: 200)
                            .overlay(
                                VStack(alignment: .leading) {
                                    HStack {
                                        Text(card.issuer)
                                            .font(.system(size: 14, weight: .medium))
                                        Spacer()
                                        Text(card.type.rawValue)
                                            .font(.system(size: 12))
                                    }

                                    Spacer()

                                    Text(card.name)
                                        .font(.system(size: 22, weight: .bold))

                                    HStack {
                                        Text("**** **** **** 1234")
                                            .font(.system(size: 14, design: .monospaced))
                                        Spacer()
                                    }
                                }
                                .foregroundColor(.white)
                                .padding(24)
                            )
                            .shadow(color: card.color.opacity(0.4), radius: 20, y: 10)
                            .padding(.horizontal, 20)

                        // Key details
                        VStack(spacing: 16) {
                            HStack(spacing: 20) {
                                DetailBox(title: "Annual Fee", value: card.annualFee == 0 ? "$0" : "$\(card.annualFee)")
                                DetailBox(title: "Match Score", value: "\(card.matchScore)%", highlight: true)
                                DetailBox(title: "Est. Value", value: "$\(Int(card.estimatedAnnualValue))/yr")
                            }
                        }
                        .padding(.horizontal, 20)

                        // Signup bonus
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Signup Bonus")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.white)

                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(card.signupBonus)
                                        .font(.system(size: 20, weight: .bold))
                                        .foregroundColor(.furgMint)

                                    Text(card.signupRequirement)
                                        .font(.system(size: 13))
                                        .foregroundColor(.white.opacity(0.6))
                                }

                                Spacer()

                                Text("≈ $\(card.signupBonusValue)")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(.white)
                            }
                        }
                        .padding(16)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color.white.opacity(0.05))
                        )
                        .padding(.horizontal, 20)

                        // Rewards
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Rewards")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.white)

                            ForEach(card.topCategories) { category in
                                HStack {
                                    Text(category.name)
                                        .font(.system(size: 14))
                                        .foregroundColor(.white.opacity(0.7))

                                    Spacer()

                                    Text("\(String(format: "%.0f", category.multiplier))x \(category.type)")
                                        .font(.system(size: 14, weight: .semibold))
                                        .foregroundColor(.furgMint)
                                }
                                .padding(.vertical, 8)

                                if category.id != card.topCategories.last?.id {
                                    Divider().background(Color.white.opacity(0.1))
                                }
                            }
                        }
                        .padding(16)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color.white.opacity(0.05))
                        )
                        .padding(.horizontal, 20)

                        // Pros & Cons
                        HStack(alignment: .top, spacing: 12) {
                            // Pros
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Pros")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(.furgSuccess)

                                ForEach(card.pros, id: \.self) { pro in
                                    HStack(alignment: .top, spacing: 6) {
                                        Image(systemName: "checkmark")
                                            .font(.system(size: 10, weight: .bold))
                                            .foregroundColor(.furgSuccess)
                                        Text(pro)
                                            .font(.system(size: 12))
                                            .foregroundColor(.white.opacity(0.7))
                                    }
                                }
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)

                            // Cons
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Cons")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(.furgDanger)

                                ForEach(card.cons, id: \.self) { con in
                                    HStack(alignment: .top, spacing: 6) {
                                        Image(systemName: "xmark")
                                            .font(.system(size: 10, weight: .bold))
                                            .foregroundColor(.furgDanger)
                                        Text(con)
                                            .font(.system(size: 12))
                                            .foregroundColor(.white.opacity(0.7))
                                    }
                                }
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        .padding(16)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color.white.opacity(0.05))
                        )
                        .padding(.horizontal, 20)

                        // Credit score needed
                        HStack {
                            Image(systemName: "creditcard.fill")
                                .foregroundColor(.furgInfo)
                            Text("Credit Score Needed:")
                                .font(.system(size: 13))
                                .foregroundColor(.white.opacity(0.6))
                            Text(card.creditScoreNeeded)
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundColor(.white)
                        }
                        .padding(.horizontal, 20)

                        Spacer(minLength: 100)
                    }
                    .padding(.top, 20)
                }
            }
            .navigationTitle(card.name)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                        .foregroundColor(.furgMint)
                }
            }
            .overlay(alignment: .bottom) {
                Button {
                    // Open application URL
                } label: {
                    Text("Learn More & Apply")
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
                .background(
                    LinearGradient(
                        colors: [.clear, Color.furgCharcoal],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .frame(height: 100)
                )
            }
        }
    }
}

private struct DetailBox: View {
    let title: String
    let value: String
    var highlight: Bool = false

    var body: some View {
        VStack(spacing: 4) {
            Text(title)
                .font(.system(size: 10))
                .foregroundColor(.white.opacity(0.5))

            Text(value)
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(highlight ? .furgMint : .white)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.white.opacity(0.05))
        )
    }
}

#Preview {
    CardRecommendationsView()
}
