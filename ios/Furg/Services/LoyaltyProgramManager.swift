import Foundation
import Combine

// MARK: - Loyalty Program Models

struct LoyaltyProgram: Identifiable, Codable {
    let id: String
    let name: String
    let type: ProgramType
    let provider: String
    var membershipId: String?
    var tierLevel: String?
    var pointsBalance: Double
    var pointsName: String
    var pointValue: Double // Value per point in cents
    var expirationDate: Date?
    var lastUpdated: Date
    var isConnected: Bool

    enum ProgramType: String, Codable, CaseIterable {
        case airline
        case hotel
        case creditCard
        case retail
        case dining
        case gas
        case grocery
        case entertainment
        case travel
        case cashback

        var icon: String {
            switch self {
            case .airline: return "airplane"
            case .hotel: return "building.fill"
            case .creditCard: return "creditcard.fill"
            case .retail: return "bag.fill"
            case .dining: return "fork.knife"
            case .gas: return "fuelpump.fill"
            case .grocery: return "cart.fill"
            case .entertainment: return "ticket.fill"
            case .travel: return "globe"
            case .cashback: return "dollarsign.circle.fill"
            }
        }
    }

    var estimatedValue: Double {
        return (pointsBalance * pointValue) / 100.0
    }

    var isExpiringSoon: Bool {
        guard let expiration = expirationDate else { return false }
        return expiration < Calendar.current.date(byAdding: .month, value: 3, to: Date())!
    }
}

struct PointsTransaction: Identifiable, Codable {
    let id: String
    let programId: String
    let date: Date
    let description: String
    let pointsEarned: Double
    let pointsRedeemed: Double
    let balance: Double
    let source: String?
}

struct RedemptionOption: Identifiable, Codable {
    let id: String
    let programId: String
    let name: String
    let description: String
    let pointsRequired: Double
    let estimatedValue: Double
    let category: RedemptionCategory
    let expirationDate: Date?
    let url: String?

    enum RedemptionCategory: String, Codable {
        case travel
        case cashback
        case giftCard
        case merchandise
        case experiences
        case transfer
        case statement
    }

    var centsPerPoint: Double {
        guard pointsRequired > 0 else { return 0 }
        return (estimatedValue / pointsRequired) * 100
    }
}

struct PointsOptimization: Identifiable, Codable {
    let id: String
    let title: String
    let description: String
    let potentialValue: Double
    let programIds: [String]
    let type: OptimizationType
    let actionRequired: String
    let deadline: Date?

    enum OptimizationType: String, Codable {
        case transfer // Transfer points to partner
        case redeem // Best redemption opportunity
        case earn // Bonus earning opportunity
        case prevent // Prevent expiration
        case stack // Stack multiple programs
    }
}

struct LoyaltyInsight: Identifiable, Codable {
    let id: String
    let type: InsightType
    let title: String
    let message: String
    let programs: [String]
    let value: Double?
    let createdAt: Date

    enum InsightType: String, Codable {
        case expiringPoints
        case redemptionOpportunity
        case earningOpportunity
        case tierStatus
        case programComparison
        case unusedProgram
    }
}

// MARK: - Known Programs Database

struct KnownProgram {
    let name: String
    let type: LoyaltyProgram.ProgramType
    let provider: String
    let pointsName: String
    let basePointValue: Double
    let tiers: [String]
}

// MARK: - Loyalty Program Manager

class LoyaltyProgramManager: ObservableObject {
    static let shared = LoyaltyProgramManager()

    // MARK: - Published Properties
    @Published var programs: [LoyaltyProgram] = []
    @Published var transactions: [PointsTransaction] = []
    @Published var redemptionOptions: [RedemptionOption] = []
    @Published var optimizations: [PointsOptimization] = []
    @Published var insights: [LoyaltyInsight] = []

    // Summary stats
    @Published var totalPointsValue: Double = 0
    @Published var totalPointsBalance: Double = 0
    @Published var expiringPointsValue: Double = 0
    @Published var programCount: Int = 0

    // MARK: - Private Properties
    private let userDefaults = UserDefaults.standard
    private let programsKey = "loyalty_programs"
    private let transactionsKey = "loyalty_transactions"

    // Known loyalty programs database
    private let knownPrograms: [String: KnownProgram] = [
        // Airlines
        "united": KnownProgram(name: "United MileagePlus", type: .airline, provider: "United Airlines", pointsName: "Miles", basePointValue: 1.2, tiers: ["Member", "Silver", "Gold", "Platinum", "1K"]),
        "delta": KnownProgram(name: "Delta SkyMiles", type: .airline, provider: "Delta Air Lines", pointsName: "Miles", basePointValue: 1.1, tiers: ["Member", "Silver", "Gold", "Platinum", "Diamond"]),
        "american": KnownProgram(name: "AAdvantage", type: .airline, provider: "American Airlines", pointsName: "Miles", basePointValue: 1.4, tiers: ["Member", "Gold", "Platinum", "Platinum Pro", "Executive Platinum"]),
        "southwest": KnownProgram(name: "Rapid Rewards", type: .airline, provider: "Southwest Airlines", pointsName: "Points", basePointValue: 1.4, tiers: ["Member", "A-List", "A-List Preferred"]),

        // Hotels
        "marriott": KnownProgram(name: "Marriott Bonvoy", type: .hotel, provider: "Marriott", pointsName: "Points", basePointValue: 0.7, tiers: ["Member", "Silver", "Gold", "Platinum", "Titanium", "Ambassador"]),
        "hilton": KnownProgram(name: "Hilton Honors", type: .hotel, provider: "Hilton", pointsName: "Points", basePointValue: 0.5, tiers: ["Member", "Silver", "Gold", "Diamond"]),
        "hyatt": KnownProgram(name: "World of Hyatt", type: .hotel, provider: "Hyatt", pointsName: "Points", basePointValue: 1.7, tiers: ["Member", "Discoverist", "Explorist", "Globalist"]),
        "ihg": KnownProgram(name: "IHG One Rewards", type: .hotel, provider: "IHG", pointsName: "Points", basePointValue: 0.5, tiers: ["Club", "Silver", "Gold", "Platinum", "Diamond"]),

        // Credit Cards
        "chase_ur": KnownProgram(name: "Chase Ultimate Rewards", type: .creditCard, provider: "Chase", pointsName: "Points", basePointValue: 1.5, tiers: []),
        "amex_mr": KnownProgram(name: "Amex Membership Rewards", type: .creditCard, provider: "American Express", pointsName: "Points", basePointValue: 1.0, tiers: []),
        "citi_typ": KnownProgram(name: "Citi ThankYou Points", type: .creditCard, provider: "Citi", pointsName: "Points", basePointValue: 1.0, tiers: []),
        "capital_one": KnownProgram(name: "Capital One Miles", type: .creditCard, provider: "Capital One", pointsName: "Miles", basePointValue: 1.0, tiers: []),

        // Retail
        "target_circle": KnownProgram(name: "Target Circle", type: .retail, provider: "Target", pointsName: "Votes", basePointValue: 1.0, tiers: []),
        "walmart_plus": KnownProgram(name: "Walmart+", type: .retail, provider: "Walmart", pointsName: "Rewards", basePointValue: 1.0, tiers: []),
        "amazon_prime": KnownProgram(name: "Amazon Prime", type: .retail, provider: "Amazon", pointsName: "Points", basePointValue: 1.0, tiers: []),
        "costco": KnownProgram(name: "Costco Executive", type: .retail, provider: "Costco", pointsName: "Rewards", basePointValue: 2.0, tiers: ["Gold Star", "Executive"]),

        // Dining
        "starbucks": KnownProgram(name: "Starbucks Rewards", type: .dining, provider: "Starbucks", pointsName: "Stars", basePointValue: 4.0, tiers: ["Green", "Gold"]),

        // Gas
        "shell": KnownProgram(name: "Shell Fuel Rewards", type: .gas, provider: "Shell", pointsName: "Rewards", basePointValue: 1.0, tiers: []),
        "exxon": KnownProgram(name: "Exxon Mobil Rewards+", type: .gas, provider: "Exxon Mobil", pointsName: "Points", basePointValue: 0.5, tiers: []),

        // Grocery
        "kroger": KnownProgram(name: "Kroger Plus", type: .grocery, provider: "Kroger", pointsName: "Fuel Points", basePointValue: 0.1, tiers: []),
        "safeway": KnownProgram(name: "Safeway for U", type: .grocery, provider: "Safeway", pointsName: "Points", basePointValue: 1.0, tiers: [])
    ]

    // Transfer partners (simplified)
    private let transferPartners: [String: [(partner: String, ratio: Double)]] = [
        "chase_ur": [
            ("united", 1.0),
            ("southwest", 1.0),
            ("marriott", 1.0),
            ("hyatt", 1.0)
        ],
        "amex_mr": [
            ("delta", 1.0),
            ("hilton", 1.0),
            ("marriott", 1.0)
        ]
    ]

    // MARK: - Initialization

    init() {
        loadData()
        calculateStats()
        generateOptimizations()
        generateInsights()
    }

    // MARK: - Program Management

    func addProgram(knownProgramKey: String, membershipId: String? = nil, pointsBalance: Double = 0, tierLevel: String? = nil) {
        guard let known = knownPrograms[knownProgramKey] else { return }

        let program = LoyaltyProgram(
            id: UUID().uuidString,
            name: known.name,
            type: known.type,
            provider: known.provider,
            membershipId: membershipId,
            tierLevel: tierLevel ?? known.tiers.first,
            pointsBalance: pointsBalance,
            pointsName: known.pointsName,
            pointValue: known.basePointValue,
            expirationDate: nil,
            lastUpdated: Date(),
            isConnected: false
        )

        programs.append(program)
        savePrograms()
        calculateStats()
        generateOptimizations()
        generateInsights()
    }

    func addCustomProgram(_ program: LoyaltyProgram) {
        programs.append(program)
        savePrograms()
        calculateStats()
    }

    func updateBalance(programId: String, newBalance: Double) {
        guard let index = programs.firstIndex(where: { $0.id == programId }) else { return }

        let oldBalance = programs[index].pointsBalance

        // Record transaction
        let transaction = PointsTransaction(
            id: UUID().uuidString,
            programId: programId,
            date: Date(),
            description: newBalance > oldBalance ? "Points Earned" : "Points Redeemed",
            pointsEarned: max(0, newBalance - oldBalance),
            pointsRedeemed: max(0, oldBalance - newBalance),
            balance: newBalance,
            source: "Manual Update"
        )
        transactions.insert(transaction, at: 0)

        // Update program
        programs[index].pointsBalance = newBalance
        programs[index].lastUpdated = Date()

        savePrograms()
        saveTransactions()
        calculateStats()
        generateOptimizations()
    }

    func removeProgram(_ programId: String) {
        programs.removeAll { $0.id == programId }
        transactions.removeAll { $0.programId == programId }
        savePrograms()
        saveTransactions()
        calculateStats()
    }

    // MARK: - Optimization Generation

    private func generateOptimizations() {
        var newOptimizations: [PointsOptimization] = []

        // Check for expiring points
        for program in programs {
            if program.isExpiringSoon, let expiration = program.expirationDate {
                newOptimizations.append(PointsOptimization(
                    id: UUID().uuidString,
                    title: "\(program.pointsName) Expiring Soon",
                    description: "\(Int(program.pointsBalance)) \(program.pointsName) worth $\(String(format: "%.2f", program.estimatedValue)) expiring",
                    potentialValue: program.estimatedValue,
                    programIds: [program.id],
                    type: .prevent,
                    actionRequired: "Redeem or use before expiration",
                    deadline: expiration
                ))
            }
        }

        // Check for transfer opportunities
        for (sourceKey, partners) in transferPartners {
            guard let sourceProgram = programs.first(where: { $0.name == knownPrograms[sourceKey]?.name }) else { continue }

            for (partnerKey, ratio) in partners {
                guard let partnerProgram = programs.first(where: { $0.name == knownPrograms[partnerKey]?.name }),
                      let partnerInfo = knownPrograms[partnerKey] else { continue }

                let transferredValue = (sourceProgram.pointsBalance * ratio * partnerInfo.basePointValue) / 100
                let currentValue = sourceProgram.estimatedValue

                if transferredValue > currentValue * 1.2 { // 20% better value
                    newOptimizations.append(PointsOptimization(
                        id: UUID().uuidString,
                        title: "Transfer to \(partnerProgram.name)",
                        description: "Get $\(String(format: "%.2f", transferredValue)) value instead of $\(String(format: "%.2f", currentValue))",
                        potentialValue: transferredValue - currentValue,
                        programIds: [sourceProgram.id, partnerProgram.id],
                        type: .transfer,
                        actionRequired: "Transfer \(Int(sourceProgram.pointsBalance)) points at \(ratio):1 ratio",
                        deadline: nil
                    ))
                }
            }
        }

        // Check for best redemption opportunities
        for program in programs where program.pointsBalance > 0 {
            if let bestRedemption = findBestRedemption(for: program) {
                newOptimizations.append(PointsOptimization(
                    id: UUID().uuidString,
                    title: "Best Redemption: \(bestRedemption.name)",
                    description: "Get \(String(format: "%.1f", bestRedemption.centsPerPoint)) cents per \(program.pointsName.dropLast())",
                    potentialValue: bestRedemption.estimatedValue,
                    programIds: [program.id],
                    type: .redeem,
                    actionRequired: "Redeem \(Int(bestRedemption.pointsRequired)) \(program.pointsName)",
                    deadline: bestRedemption.expirationDate
                ))
            }
        }

        optimizations = newOptimizations.sorted { ($0.potentialValue) > ($1.potentialValue) }
    }

    private func findBestRedemption(for program: LoyaltyProgram) -> RedemptionOption? {
        // Generate sample redemption options based on program type
        var options: [RedemptionOption] = []

        switch program.type {
        case .airline:
            options = [
                RedemptionOption(id: UUID().uuidString, programId: program.id, name: "Domestic Flight", description: "Round-trip economy", pointsRequired: 25000, estimatedValue: 350, category: .travel, expirationDate: nil, url: nil),
                RedemptionOption(id: UUID().uuidString, programId: program.id, name: "International Flight", description: "Round-trip economy to Europe", pointsRequired: 60000, estimatedValue: 900, category: .travel, expirationDate: nil, url: nil),
                RedemptionOption(id: UUID().uuidString, programId: program.id, name: "Gift Card", description: "$100 gift card", pointsRequired: 10000, estimatedValue: 100, category: .giftCard, expirationDate: nil, url: nil)
            ]
        case .hotel:
            options = [
                RedemptionOption(id: UUID().uuidString, programId: program.id, name: "Free Night (Cat 1-4)", description: "One night stay", pointsRequired: 15000, estimatedValue: 150, category: .travel, expirationDate: nil, url: nil),
                RedemptionOption(id: UUID().uuidString, programId: program.id, name: "Free Night (Cat 5-7)", description: "One night stay", pointsRequired: 40000, estimatedValue: 350, category: .travel, expirationDate: nil, url: nil)
            ]
        case .creditCard:
            options = [
                RedemptionOption(id: UUID().uuidString, programId: program.id, name: "Cash Back", description: "Statement credit", pointsRequired: 10000, estimatedValue: 100, category: .cashback, expirationDate: nil, url: nil),
                RedemptionOption(id: UUID().uuidString, programId: program.id, name: "Travel Portal", description: "Book travel at 1.25-1.5x", pointsRequired: 10000, estimatedValue: 150, category: .travel, expirationDate: nil, url: nil)
            ]
        default:
            options = [
                RedemptionOption(id: UUID().uuidString, programId: program.id, name: "Reward", description: "Standard redemption", pointsRequired: program.pointsBalance, estimatedValue: program.estimatedValue, category: .merchandise, expirationDate: nil, url: nil)
            ]
        }

        // Filter to affordable options and find best value
        let affordableOptions = options.filter { $0.pointsRequired <= program.pointsBalance }
        return affordableOptions.max { $0.centsPerPoint < $1.centsPerPoint }
    }

    // MARK: - Insights Generation

    private func generateInsights() {
        var newInsights: [LoyaltyInsight] = []

        // Expiring points insight
        let expiringPrograms = programs.filter { $0.isExpiringSoon }
        if !expiringPrograms.isEmpty {
            let totalExpiring = expiringPrograms.reduce(0) { $0 + $1.estimatedValue }
            newInsights.append(LoyaltyInsight(
                id: UUID().uuidString,
                type: .expiringPoints,
                title: "Points Expiring Soon",
                message: "$\(String(format: "%.2f", totalExpiring)) worth of points across \(expiringPrograms.count) program(s) expiring in the next 3 months",
                programs: expiringPrograms.map { $0.id },
                value: totalExpiring,
                createdAt: Date()
            ))
        }

        // Unused programs insight
        let unusedPrograms = programs.filter {
            $0.lastUpdated < Calendar.current.date(byAdding: .month, value: -6, to: Date())!
        }
        if !unusedPrograms.isEmpty {
            newInsights.append(LoyaltyInsight(
                id: UUID().uuidString,
                type: .unusedProgram,
                title: "Unused Loyalty Programs",
                message: "\(unusedPrograms.count) program(s) haven't been updated in 6+ months. You might be missing earning opportunities.",
                programs: unusedPrograms.map { $0.id },
                value: nil,
                createdAt: Date()
            ))
        }

        // High value programs
        let highValuePrograms = programs.filter { $0.estimatedValue > 100 }.sorted { $0.estimatedValue > $1.estimatedValue }
        if !highValuePrograms.isEmpty {
            newInsights.append(LoyaltyInsight(
                id: UUID().uuidString,
                type: .redemptionOpportunity,
                title: "High-Value Points Available",
                message: "You have $\(String(format: "%.2f", highValuePrograms.reduce(0) { $0 + $1.estimatedValue })) in high-value programs ready to use",
                programs: highValuePrograms.prefix(3).map { $0.id },
                value: highValuePrograms.reduce(0) { $0 + $1.estimatedValue },
                createdAt: Date()
            ))
        }

        insights = newInsights
    }

    // MARK: - Stats Calculation

    private func calculateStats() {
        totalPointsBalance = programs.reduce(0) { $0 + $1.pointsBalance }
        totalPointsValue = programs.reduce(0) { $0 + $1.estimatedValue }
        expiringPointsValue = programs.filter { $0.isExpiringSoon }.reduce(0) { $0 + $1.estimatedValue }
        programCount = programs.count
    }

    // MARK: - Search & Query

    func getPrograms(ofType type: LoyaltyProgram.ProgramType) -> [LoyaltyProgram] {
        return programs.filter { $0.type == type }
    }

    func getTransactions(for programId: String) -> [PointsTransaction] {
        return transactions.filter { $0.programId == programId }
    }

    func searchKnownPrograms(query: String) -> [KnownProgram] {
        let lowercaseQuery = query.lowercased()
        return knownPrograms.values.filter {
            $0.name.lowercased().contains(lowercaseQuery) ||
            $0.provider.lowercased().contains(lowercaseQuery)
        }
    }

    func getAvailablePrograms() -> [(key: String, program: KnownProgram)] {
        let existingNames = Set(programs.map { $0.name })
        return knownPrograms.filter { !existingNames.contains($0.value.name) }
            .map { ($0.key, $0.value) }
            .sorted { $0.1.name < $1.1.name }
    }

    // MARK: - Persistence

    private func loadData() {
        if let data = userDefaults.data(forKey: programsKey),
           let saved = try? JSONDecoder().decode([LoyaltyProgram].self, from: data) {
            programs = saved
        }

        if let data = userDefaults.data(forKey: transactionsKey),
           let saved = try? JSONDecoder().decode([PointsTransaction].self, from: data) {
            transactions = saved
        }
    }

    private func savePrograms() {
        if let data = try? JSONEncoder().encode(programs) {
            userDefaults.set(data, forKey: programsKey)
        }
    }

    private func saveTransactions() {
        if let data = try? JSONEncoder().encode(transactions) {
            userDefaults.set(data, forKey: transactionsKey)
        }
    }
}
