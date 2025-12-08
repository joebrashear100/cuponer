import Foundation
import Combine

// MARK: - Life Event Models

struct DetectedLifeEvent: Identifiable, Codable {
    let id: String
    let type: LifeEventType
    let detectedAt: Date
    let confidence: Double
    let evidence: [Evidence]
    var confirmed: Bool?
    var financialImpact: FinancialImpact
    var recommendations: [EventRecommendation]
    var isAddressed: Bool

    enum LifeEventType: String, Codable, CaseIterable {
        case gettingEngaged = "Getting Engaged"
        case gettingMarried = "Getting Married"
        case havingBaby = "Having a Baby"
        case buyingHome = "Buying a Home"
        case movingResidence = "Moving"
        case startingNewJob = "Starting New Job"
        case losingJob = "Job Loss"
        case retiring = "Retiring"
        case gettingDivorced = "Getting Divorced"
        case deathInFamily = "Death in Family"
        case startingBusiness = "Starting a Business"
        case goingToCollege = "Going to College"
        case graduatingCollege = "Graduating College"
        case gettingPet = "Getting a Pet"
        case majorIllness = "Major Illness"
        case receivingInheritance = "Receiving Inheritance"
        case gettingPromotion = "Getting a Promotion"
        case childGoingToCollege = "Child Going to College"

        var icon: String {
            switch self {
            case .gettingEngaged, .gettingMarried: return "heart.fill"
            case .havingBaby: return "figure.and.child.holdinghands"
            case .buyingHome: return "house.fill"
            case .movingResidence: return "box.truck.fill"
            case .startingNewJob, .gettingPromotion: return "briefcase.fill"
            case .losingJob: return "xmark.circle.fill"
            case .retiring: return "beach.umbrella.fill"
            case .gettingDivorced: return "heart.slash.fill"
            case .deathInFamily: return "heart.fill"
            case .startingBusiness: return "building.2.fill"
            case .goingToCollege, .graduatingCollege, .childGoingToCollege: return "graduationcap.fill"
            case .gettingPet: return "pawprint.fill"
            case .majorIllness: return "cross.case.fill"
            case .receivingInheritance: return "gift.fill"
            }
        }

        var color: String {
            switch self {
            case .gettingEngaged, .gettingMarried: return "pink"
            case .havingBaby: return "blue"
            case .buyingHome: return "green"
            case .movingResidence: return "orange"
            case .startingNewJob, .gettingPromotion: return "green"
            case .losingJob: return "red"
            case .retiring: return "yellow"
            case .gettingDivorced, .deathInFamily, .majorIllness: return "gray"
            case .startingBusiness: return "purple"
            case .goingToCollege, .graduatingCollege, .childGoingToCollege: return "blue"
            case .gettingPet: return "orange"
            case .receivingInheritance: return "gold"
            }
        }

        var averageFinancialImpact: Double {
            switch self {
            case .gettingEngaged: return -10000
            case .gettingMarried: return -30000
            case .havingBaby: return -15000
            case .buyingHome: return -50000
            case .movingResidence: return -5000
            case .startingNewJob: return 10000
            case .losingJob: return -30000
            case .retiring: return -20000
            case .gettingDivorced: return -15000
            case .deathInFamily: return -10000
            case .startingBusiness: return -20000
            case .goingToCollege: return -40000
            case .graduatingCollege: return 30000
            case .gettingPet: return -2000
            case .majorIllness: return -10000
            case .receivingInheritance: return 50000
            case .gettingPromotion: return 15000
            case .childGoingToCollege: return -50000
            }
        }
    }

    struct Evidence: Codable {
        let type: EvidenceType
        let description: String
        let weight: Double
        let date: Date

        enum EvidenceType: String, Codable {
            case spendingPattern
            case merchantCategory
            case incomeChange
            case locationChange
            case calendarEvent
            case emailParsed
            case userConfirmed
        }
    }

    struct FinancialImpact: Codable {
        var estimatedOneTimeCost: Double
        var estimatedMonthlyCostChange: Double
        var estimatedIncomeChange: Double
        var budgetAdjustments: [BudgetAdjustment]
        var savingsGoalRecommendation: Double?

        struct BudgetAdjustment: Codable {
            let category: String
            let currentAmount: Double
            let recommendedAmount: Double
            let reason: String
        }
    }

    struct EventRecommendation: Identifiable, Codable {
        let id: String
        let title: String
        let description: String
        let priority: Priority
        let category: Category
        var isCompleted: Bool

        enum Priority: String, Codable {
            case urgent, high, medium, low
        }

        enum Category: String, Codable {
            case financial, insurance, legal, tax, savings, investment
        }
    }
}

struct SpendingPattern: Codable {
    let merchant: String
    let category: String
    let amount: Double
    let frequency: Int
    let dateRange: DateRange

    struct DateRange: Codable {
        let start: Date
        let end: Date
    }
}

// MARK: - Life Event Detector

class LifeEventDetector: ObservableObject {
    static let shared = LifeEventDetector()

    // MARK: - Published Properties
    @Published var detectedEvents: [DetectedLifeEvent] = []
    @Published var pendingConfirmation: [DetectedLifeEvent] = []
    @Published var recentTransactionPatterns: [SpendingPattern] = []

    @Published var isAnalyzing = false
    @Published var lastAnalysisDate: Date?

    // MARK: - Private Properties
    private let userDefaults = UserDefaults.standard
    private let eventsKey = "lifeEvents_detected"
    private let patternsKey = "lifeEvents_patterns"

    // Detection thresholds
    private let confidenceThreshold: Double = 0.6

    // Event detection patterns
    private let eventPatterns: [DetectedLifeEvent.LifeEventType: EventPattern] = [
        .gettingEngaged: EventPattern(
            merchantKeywords: ["jewelry", "tiffany", "ring", "zales", "kay jewelers", "blue nile"],
            categoryKeywords: ["jewelry"],
            priceRange: 2000...50000,
            frequencyThreshold: 1
        ),
        .gettingMarried: EventPattern(
            merchantKeywords: ["wedding", "bridal", "catering", "venue", "florist", "photographer", "dj", "band"],
            categoryKeywords: ["wedding", "event planning"],
            priceRange: 500...100000,
            frequencyThreshold: 3
        ),
        .havingBaby: EventPattern(
            merchantKeywords: ["baby", "babies r us", "buy buy baby", "nursery", "maternity", "obgyn", "pediatric"],
            categoryKeywords: ["baby", "children", "medical"],
            priceRange: 50...5000,
            frequencyThreshold: 5
        ),
        .buyingHome: EventPattern(
            merchantKeywords: ["home depot", "lowes", "furniture", "moving", "u-haul", "storage", "escrow", "title company"],
            categoryKeywords: ["home improvement", "furniture", "moving"],
            priceRange: 500...50000,
            frequencyThreshold: 5
        ),
        .movingResidence: EventPattern(
            merchantKeywords: ["u-haul", "penske", "moving", "storage", "boxes", "pod"],
            categoryKeywords: ["moving", "storage"],
            priceRange: 100...5000,
            frequencyThreshold: 3
        ),
        .gettingPet: EventPattern(
            merchantKeywords: ["petco", "petsmart", "pet supplies", "vet", "veterinary", "chewy", "animal hospital"],
            categoryKeywords: ["pet", "veterinary"],
            priceRange: 50...2000,
            frequencyThreshold: 3
        ),
        .startingBusiness: EventPattern(
            merchantKeywords: ["llc", "incorporate", "business license", "office depot", "staples", "coworking", "wework"],
            categoryKeywords: ["office supplies", "business services"],
            priceRange: 100...10000,
            frequencyThreshold: 5
        )
    ]

    private struct EventPattern {
        let merchantKeywords: [String]
        let categoryKeywords: [String]
        let priceRange: ClosedRange<Double>
        let frequencyThreshold: Int
    }

    // MARK: - Initialization

    init() {
        loadData()
    }

    // MARK: - Event Detection

    func analyzeTransactions(_ transactions: [(merchant: String, category: String, amount: Double, date: Date)]) {
        isAnalyzing = true
        defer {
            isAnalyzing = false
            lastAnalysisDate = Date()
        }

        // Group transactions by time period and analyze patterns
        let recentTransactions = transactions.filter {
            $0.date > Calendar.current.date(byAdding: .month, value: -3, to: Date())!
        }

        for (eventType, pattern) in eventPatterns {
            let evidence = findEvidence(for: eventType, pattern: pattern, in: recentTransactions)

            if !evidence.isEmpty {
                let confidence = calculateConfidence(evidence: evidence, pattern: pattern)

                if confidence >= confidenceThreshold {
                    // Check if we already detected this event recently
                    let existingEvent = detectedEvents.first {
                        $0.type == eventType &&
                        $0.detectedAt > Calendar.current.date(byAdding: .month, value: -6, to: Date())!
                    }

                    if existingEvent == nil {
                        let event = createEvent(type: eventType, evidence: evidence, confidence: confidence)
                        detectedEvents.insert(event, at: 0)
                        pendingConfirmation.insert(event, at: 0)
                    }
                }
            }
        }

        saveEvents()
    }

    private func findEvidence(for eventType: DetectedLifeEvent.LifeEventType, pattern: EventPattern, in transactions: [(merchant: String, category: String, amount: Double, date: Date)]) -> [DetectedLifeEvent.Evidence] {
        var evidence: [DetectedLifeEvent.Evidence] = []

        // Check merchant keywords
        for transaction in transactions {
            let merchantLower = transaction.merchant.lowercased()
            let categoryLower = transaction.category.lowercased()

            for keyword in pattern.merchantKeywords {
                if merchantLower.contains(keyword) && pattern.priceRange.contains(transaction.amount) {
                    evidence.append(DetectedLifeEvent.Evidence(
                        type: .spendingPattern,
                        description: "Purchase at \(transaction.merchant) for $\(String(format: "%.2f", transaction.amount))",
                        weight: 0.3,
                        date: transaction.date
                    ))
                }
            }

            for keyword in pattern.categoryKeywords {
                if categoryLower.contains(keyword) {
                    evidence.append(DetectedLifeEvent.Evidence(
                        type: .merchantCategory,
                        description: "\(transaction.category) spending at \(transaction.merchant)",
                        weight: 0.2,
                        date: transaction.date
                    ))
                }
            }
        }

        return evidence
    }

    private func calculateConfidence(evidence: [DetectedLifeEvent.Evidence], pattern: EventPattern) -> Double {
        guard !evidence.isEmpty else { return 0 }

        let totalWeight = evidence.reduce(0) { $0 + $1.weight }
        let frequencyScore = min(Double(evidence.count) / Double(pattern.frequencyThreshold), 1.0)

        // Combine weights and frequency
        let confidence = min(totalWeight * 0.6 + frequencyScore * 0.4, 1.0)

        return confidence
    }

    private func createEvent(type: DetectedLifeEvent.LifeEventType, evidence: [DetectedLifeEvent.Evidence], confidence: Double) -> DetectedLifeEvent {
        let impact = calculateFinancialImpact(for: type)
        let recommendations = generateRecommendations(for: type)

        return DetectedLifeEvent(
            id: UUID().uuidString,
            type: type,
            detectedAt: Date(),
            confidence: confidence,
            evidence: evidence,
            confirmed: nil,
            financialImpact: impact,
            recommendations: recommendations,
            isAddressed: false
        )
    }

    private func calculateFinancialImpact(for eventType: DetectedLifeEvent.LifeEventType) -> DetectedLifeEvent.FinancialImpact {
        var impact = DetectedLifeEvent.FinancialImpact(
            estimatedOneTimeCost: 0,
            estimatedMonthlyCostChange: 0,
            estimatedIncomeChange: 0,
            budgetAdjustments: [],
            savingsGoalRecommendation: nil
        )

        switch eventType {
        case .gettingEngaged:
            impact.estimatedOneTimeCost = 10000
            impact.savingsGoalRecommendation = 30000 // For wedding
            impact.budgetAdjustments = [
                DetectedLifeEvent.FinancialImpact.BudgetAdjustment(
                    category: "Entertainment",
                    currentAmount: 500,
                    recommendedAmount: 300,
                    reason: "Save for wedding"
                )
            ]

        case .gettingMarried:
            impact.estimatedOneTimeCost = 30000
            impact.estimatedMonthlyCostChange = -200 // Shared expenses
            impact.budgetAdjustments = [
                DetectedLifeEvent.FinancialImpact.BudgetAdjustment(
                    category: "Housing",
                    currentAmount: 1500,
                    recommendedAmount: 1200,
                    reason: "Shared housing costs"
                )
            ]

        case .havingBaby:
            impact.estimatedOneTimeCost = 10000
            impact.estimatedMonthlyCostChange = 1500
            impact.savingsGoalRecommendation = 20000
            impact.budgetAdjustments = [
                DetectedLifeEvent.FinancialImpact.BudgetAdjustment(
                    category: "Childcare",
                    currentAmount: 0,
                    recommendedAmount: 1500,
                    reason: "Daycare/childcare expenses"
                ),
                DetectedLifeEvent.FinancialImpact.BudgetAdjustment(
                    category: "Medical",
                    currentAmount: 100,
                    recommendedAmount: 300,
                    reason: "Pediatric care"
                )
            ]

        case .buyingHome:
            impact.estimatedOneTimeCost = 30000 // Down payment, closing costs
            impact.estimatedMonthlyCostChange = 500 // Mortgage vs rent difference
            impact.savingsGoalRecommendation = 50000

        case .movingResidence:
            impact.estimatedOneTimeCost = 3000
            impact.estimatedMonthlyCostChange = 200

        case .startingNewJob:
            impact.estimatedIncomeChange = 10000
            impact.budgetAdjustments = [
                DetectedLifeEvent.FinancialImpact.BudgetAdjustment(
                    category: "Savings",
                    currentAmount: 500,
                    recommendedAmount: 750,
                    reason: "Increase savings with new income"
                )
            ]

        case .losingJob:
            impact.estimatedIncomeChange = -50000
            impact.savingsGoalRecommendation = 20000 // Emergency fund
            impact.budgetAdjustments = [
                DetectedLifeEvent.FinancialImpact.BudgetAdjustment(
                    category: "Discretionary",
                    currentAmount: 800,
                    recommendedAmount: 200,
                    reason: "Reduce spending during job search"
                )
            ]

        case .gettingPet:
            impact.estimatedOneTimeCost = 1000
            impact.estimatedMonthlyCostChange = 150
            impact.budgetAdjustments = [
                DetectedLifeEvent.FinancialImpact.BudgetAdjustment(
                    category: "Pet Care",
                    currentAmount: 0,
                    recommendedAmount: 150,
                    reason: "Food, vet, supplies"
                )
            ]

        default:
            impact.estimatedOneTimeCost = abs(eventType.averageFinancialImpact)
        }

        return impact
    }

    private func generateRecommendations(for eventType: DetectedLifeEvent.LifeEventType) -> [DetectedLifeEvent.EventRecommendation] {
        var recommendations: [DetectedLifeEvent.EventRecommendation] = []

        switch eventType {
        case .gettingEngaged, .gettingMarried:
            recommendations = [
                DetectedLifeEvent.EventRecommendation(
                    id: UUID().uuidString,
                    title: "Discuss Finances with Partner",
                    description: "Have an open conversation about debts, spending habits, and financial goals",
                    priority: .urgent,
                    category: .financial,
                    isCompleted: false
                ),
                DetectedLifeEvent.EventRecommendation(
                    id: UUID().uuidString,
                    title: "Update Beneficiaries",
                    description: "Update life insurance and retirement account beneficiaries",
                    priority: .high,
                    category: .legal,
                    isCompleted: false
                ),
                DetectedLifeEvent.EventRecommendation(
                    id: UUID().uuidString,
                    title: "Review Insurance Needs",
                    description: "Consider joint policies for auto, renters/home, and life insurance",
                    priority: .high,
                    category: .insurance,
                    isCompleted: false
                )
            ]

        case .havingBaby:
            recommendations = [
                DetectedLifeEvent.EventRecommendation(
                    id: UUID().uuidString,
                    title: "Start 529 College Savings",
                    description: "Open a tax-advantaged education savings account",
                    priority: .high,
                    category: .savings,
                    isCompleted: false
                ),
                DetectedLifeEvent.EventRecommendation(
                    id: UUID().uuidString,
                    title: "Increase Life Insurance",
                    description: "Review and increase life insurance coverage",
                    priority: .urgent,
                    category: .insurance,
                    isCompleted: false
                ),
                DetectedLifeEvent.EventRecommendation(
                    id: UUID().uuidString,
                    title: "Create/Update Will",
                    description: "Designate guardianship and create estate plan",
                    priority: .urgent,
                    category: .legal,
                    isCompleted: false
                ),
                DetectedLifeEvent.EventRecommendation(
                    id: UUID().uuidString,
                    title: "Budget for Childcare",
                    description: "Research and budget for daycare or childcare costs",
                    priority: .high,
                    category: .financial,
                    isCompleted: false
                )
            ]

        case .buyingHome:
            recommendations = [
                DetectedLifeEvent.EventRecommendation(
                    id: UUID().uuidString,
                    title: "Get Homeowners Insurance",
                    description: "Shop for comprehensive homeowners insurance",
                    priority: .urgent,
                    category: .insurance,
                    isCompleted: false
                ),
                DetectedLifeEvent.EventRecommendation(
                    id: UUID().uuidString,
                    title: "Start Home Maintenance Fund",
                    description: "Set aside 1-2% of home value annually for repairs",
                    priority: .high,
                    category: .savings,
                    isCompleted: false
                ),
                DetectedLifeEvent.EventRecommendation(
                    id: UUID().uuidString,
                    title: "Review Property Tax Deductions",
                    description: "Understand new tax deductions available to homeowners",
                    priority: .medium,
                    category: .tax,
                    isCompleted: false
                )
            ]

        case .losingJob:
            recommendations = [
                DetectedLifeEvent.EventRecommendation(
                    id: UUID().uuidString,
                    title: "File for Unemployment",
                    description: "Apply for unemployment benefits immediately",
                    priority: .urgent,
                    category: .financial,
                    isCompleted: false
                ),
                DetectedLifeEvent.EventRecommendation(
                    id: UUID().uuidString,
                    title: "Review COBRA Options",
                    description: "Evaluate health insurance continuation or marketplace options",
                    priority: .urgent,
                    category: .insurance,
                    isCompleted: false
                ),
                DetectedLifeEvent.EventRecommendation(
                    id: UUID().uuidString,
                    title: "Reduce Discretionary Spending",
                    description: "Cut non-essential expenses while job searching",
                    priority: .urgent,
                    category: .financial,
                    isCompleted: false
                ),
                DetectedLifeEvent.EventRecommendation(
                    id: UUID().uuidString,
                    title: "Don't Touch Retirement",
                    description: "Avoid early withdrawals from 401k/IRA",
                    priority: .high,
                    category: .investment,
                    isCompleted: false
                )
            ]

        default:
            recommendations = [
                DetectedLifeEvent.EventRecommendation(
                    id: UUID().uuidString,
                    title: "Review Budget",
                    description: "Update your budget to reflect life changes",
                    priority: .high,
                    category: .financial,
                    isCompleted: false
                ),
                DetectedLifeEvent.EventRecommendation(
                    id: UUID().uuidString,
                    title: "Update Emergency Fund",
                    description: "Ensure emergency fund matches new situation",
                    priority: .medium,
                    category: .savings,
                    isCompleted: false
                )
            ]
        }

        return recommendations
    }

    // MARK: - User Interaction

    func confirmEvent(_ eventId: String, confirmed: Bool) {
        if let index = detectedEvents.firstIndex(where: { $0.id == eventId }) {
            detectedEvents[index].confirmed = confirmed
            pendingConfirmation.removeAll { $0.id == eventId }
            saveEvents()

            // Remember this for future detection tuning
            if confirmed {
                ConversationMemoryManager.shared.rememberFact(
                    "User confirmed \(detectedEvents[index].type.rawValue)",
                    category: "Life Events"
                )
            }
        }
    }

    func markRecommendationComplete(_ eventId: String, recommendationId: String) {
        if let eventIndex = detectedEvents.firstIndex(where: { $0.id == eventId }),
           let recIndex = detectedEvents[eventIndex].recommendations.firstIndex(where: { $0.id == recommendationId }) {
            detectedEvents[eventIndex].recommendations[recIndex].isCompleted = true
            saveEvents()
        }
    }

    func dismissEvent(_ eventId: String) {
        detectedEvents.removeAll { $0.id == eventId }
        pendingConfirmation.removeAll { $0.id == eventId }
        saveEvents()
    }

    // MARK: - Manual Event Creation

    func reportLifeEvent(_ type: DetectedLifeEvent.LifeEventType, notes: String? = nil) {
        let event = createEvent(
            type: type,
            evidence: [
                DetectedLifeEvent.Evidence(
                    type: .userConfirmed,
                    description: notes ?? "User reported",
                    weight: 1.0,
                    date: Date()
                )
            ],
            confidence: 1.0
        )

        var confirmedEvent = event
        confirmedEvent.confirmed = true

        detectedEvents.insert(confirmedEvent, at: 0)
        saveEvents()

        // Remember in conversation memory
        ConversationMemoryManager.shared.rememberFact(
            "User is experiencing: \(type.rawValue)",
            category: "Life Events"
        )
    }

    // MARK: - Persistence

    private func loadData() {
        if let data = userDefaults.data(forKey: eventsKey),
           let events = try? JSONDecoder().decode([DetectedLifeEvent].self, from: data) {
            detectedEvents = events
            pendingConfirmation = events.filter { $0.confirmed == nil }
        }
    }

    private func saveEvents() {
        if let data = try? JSONEncoder().encode(detectedEvents) {
            userDefaults.set(data, forKey: eventsKey)
        }
    }
}
