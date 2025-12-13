import Foundation
import Combine
import HealthKit

// MARK: - Emotional Spending Models

struct MoodEntry: Identifiable, Codable {
    let id: String
    let timestamp: Date
    let mood: Mood
    let energy: EnergyLevel
    let stressLevel: Int // 1-10
    let triggers: [EmotionalTrigger]
    let notes: String?
    let source: MoodSource

    enum Mood: String, Codable, CaseIterable {
        case veryHappy = "Very Happy"
        case happy = "Happy"
        case neutral = "Neutral"
        case sad = "Sad"
        case verySad = "Very Sad"
        case anxious = "Anxious"
        case stressed = "Stressed"
        case angry = "Angry"
        case bored = "Bored"
        case excited = "Excited"

        var emoji: String {
            switch self {
            case .veryHappy: return "😄"
            case .happy: return "🙂"
            case .neutral: return "😐"
            case .sad: return "😢"
            case .verySad: return "😭"
            case .anxious: return "😰"
            case .stressed: return "😫"
            case .angry: return "😠"
            case .bored: return "😑"
            case .excited: return "🤩"
            }
        }

        var spendingRiskMultiplier: Double {
            switch self {
            case .veryHappy: return 1.2 // Celebratory spending
            case .happy: return 1.0
            case .neutral: return 1.0
            case .sad: return 1.4 // Retail therapy
            case .verySad: return 1.6
            case .anxious: return 1.3
            case .stressed: return 1.5
            case .angry: return 1.3
            case .bored: return 1.35
            case .excited: return 1.25
            }
        }

        var color: String {
            switch self {
            case .veryHappy, .happy, .excited: return "green"
            case .neutral: return "gray"
            case .sad, .verySad: return "blue"
            case .anxious, .stressed: return "orange"
            case .angry: return "red"
            case .bored: return "purple"
            }
        }
    }

    enum EnergyLevel: String, Codable, CaseIterable {
        case veryLow = "Very Low"
        case low = "Low"
        case moderate = "Moderate"
        case high = "High"
        case veryHigh = "Very High"

        var spendingImpact: Double {
            switch self {
            case .veryLow: return 1.2 // Low energy = convenience spending
            case .low: return 1.1
            case .moderate: return 1.0
            case .high: return 0.95
            case .veryHigh: return 1.1 // High energy = impulsive
            }
        }
    }

    enum MoodSource: String, Codable {
        case manual
        case inferred // From health data, time patterns
        case prompt // Asked during purchase
    }
}

enum EmotionalTrigger: String, Codable, CaseIterable {
    case work = "Work Stress"
    case relationship = "Relationship"
    case health = "Health Concerns"
    case financial = "Financial Worry"
    case family = "Family Issues"
    case social = "Social Pressure"
    case fomo = "FOMO"
    case boredom = "Boredom"
    case celebration = "Celebration"
    case reward = "Self-Reward"
    case habit = "Habit"
    case advertising = "Saw an Ad"
    case socialMedia = "Social Media"
    case sale = "Sale/Deal"
    case convenience = "Convenience"

    var icon: String {
        switch self {
        case .work: return "briefcase.fill"
        case .relationship: return "heart.fill"
        case .health: return "heart.text.square.fill"
        case .financial: return "dollarsign.circle.fill"
        case .family: return "house.fill"
        case .social: return "person.3.fill"
        case .fomo: return "exclamationmark.triangle.fill"
        case .boredom: return "moon.zzz.fill"
        case .celebration: return "party.popper.fill"
        case .reward: return "gift.fill"
        case .habit: return "arrow.clockwise"
        case .advertising: return "megaphone.fill"
        case .socialMedia: return "iphone"
        case .sale: return "tag.fill"
        case .convenience: return "clock.fill"
        }
    }
}

struct EmotionalTransaction: Identifiable, Codable {
    let id: String
    let transactionId: String
    let amount: Double
    let merchantName: String
    let category: String
    let timestamp: Date
    var moodAtPurchase: MoodEntry.Mood?
    var energyAtPurchase: MoodEntry.EnergyLevel?
    var triggers: [EmotionalTrigger]
    var wasImpulse: Bool
    var regretLevel: Int? // 1-5, logged after purchase
    var satisfaction: Int? // 1-5
    var coolingOffTriggered: Bool
    var coolingOffResult: CoolingOffResult?

    enum CoolingOffResult: String, Codable {
        case purchased
        case canceled
        case reduced
        case pending
    }
}

struct EmotionalSpendingPattern: Identifiable, Codable {
    let id: String
    let pattern: PatternType
    let description: String
    let frequency: Int
    let totalAmount: Double
    let averageAmount: Double
    let commonMoods: [MoodEntry.Mood]
    let commonTriggers: [EmotionalTrigger]
    let recommendations: [String]

    enum PatternType: String, Codable {
        case retailTherapy = "Retail Therapy"
        case stressShopping = "Stress Shopping"
        case boredomBuying = "Boredom Buying"
        case celebrationSpending = "Celebration Spending"
        case lateNightShopping = "Late Night Shopping"
        case weekendSplurge = "Weekend Splurge"
        case paydaySurge = "Payday Surge"
        case socialSpending = "Social Spending"
        case impulseBuying = "Impulse Buying"
        case revengeSpending = "Revenge Spending"
    }
}

struct CoolingOffPeriod: Identifiable, Codable {
    let id: String
    let transactionDetails: PendingPurchase
    let startTime: Date
    let endTime: Date
    let reason: CoolingOffReason
    var status: Status
    var reminderSent: Bool

    struct PendingPurchase: Codable {
        let merchantName: String
        let amount: Double
        let category: String
        let itemDescription: String?
    }

    enum CoolingOffReason: String, Codable {
        case highStress = "High Stress Detected"
        case lowSleep = "Low Sleep"
        case largeAmount = "Large Purchase"
        case impulsePattern = "Impulse Pattern Detected"
        case lateNight = "Late Night Purchase"
        case userRequested = "User Requested"
    }

    enum Status: String, Codable {
        case active
        case expired
        case purchased
        case canceled
    }

    var timeRemaining: TimeInterval {
        return endTime.timeIntervalSince(Date())
    }

    var isExpired: Bool {
        return Date() >= endTime
    }
}

struct EmotionalInsight: Identifiable, Codable {
    let id: String
    let type: InsightType
    let title: String
    let message: String
    let data: InsightData
    let actionable: Bool
    let action: String?
    let createdAt: Date

    enum InsightType: String, Codable {
        case pattern
        case warning
        case achievement
        case suggestion
        case correlation
    }

    struct InsightData: Codable {
        let mood: MoodEntry.Mood?
        let trigger: EmotionalTrigger?
        let amount: Double?
        let timeOfDay: String?
        let dayOfWeek: String?
        let comparisonPercentage: Double?
    }
}

// MARK: - Emotional Spending Manager

class EmotionalSpendingManager: ObservableObject {
    static let shared = EmotionalSpendingManager()

    // MARK: - Published Properties
    @Published var moodHistory: [MoodEntry] = []
    @Published var currentMood: MoodEntry?
    @Published var emotionalTransactions: [EmotionalTransaction] = []
    @Published var patterns: [EmotionalSpendingPattern] = []
    @Published var activeCoolingOffPeriods: [CoolingOffPeriod] = []
    @Published var insights: [EmotionalInsight] = []

    @Published var spendingRiskLevel: Double = 50 // 0-100
    @Published var coolingOffEnabled: Bool = true
    @Published var coolingOffDuration: TimeInterval = 24 * 60 * 60 // 24 hours default
    @Published var largeAmountThreshold: Double = 100

    // Correlations
    @Published var moodSpendingCorrelation: [MoodEntry.Mood: Double] = [:]
    @Published var triggerSpendingCorrelation: [EmotionalTrigger: Double] = [:]
    @Published var timeOfDayCorrelation: [Int: Double] = [:]
    @Published var dayOfWeekCorrelation: [Int: Double] = [:]

    // MARK: - Private Properties
    private let userDefaults = UserDefaults.standard
    private let moodHistoryKey = "emotional_moodHistory"
    private let transactionsKey = "emotional_transactions"
    private let patternsKey = "emotional_patterns"
    private let coolingOffKey = "emotional_coolingOff"
    private let settingsKey = "emotional_settings"

    private var cancellables = Set<AnyCancellable>()
    private let healthStore = HKHealthStore()

    // MARK: - Initialization

    init() {
        loadData()
        analyzePatterns()
        calculateCorrelations()
        checkCoolingOffPeriods()
    }

    // MARK: - Mood Logging

    func logMood(_ mood: MoodEntry.Mood, energy: MoodEntry.EnergyLevel, stress: Int, triggers: [EmotionalTrigger] = [], notes: String? = nil) {
        let entry = MoodEntry(
            id: UUID().uuidString,
            timestamp: Date(),
            mood: mood,
            energy: energy,
            stressLevel: stress,
            triggers: triggers,
            notes: notes,
            source: .manual
        )

        moodHistory.insert(entry, at: 0)
        currentMood = entry

        // Keep last 365 days
        let cutoff = Calendar.current.date(byAdding: .day, value: -365, to: Date())!
        moodHistory = moodHistory.filter { $0.timestamp >= cutoff }

        updateSpendingRiskLevel()
        saveMoodHistory()
        analyzePatterns()
    }

    func inferMoodFromContext() {
        // Infer mood from available data
        var inferredMood: MoodEntry.Mood = .neutral
        var inferredEnergy: MoodEntry.EnergyLevel = .moderate
        var inferredStress: Int = 5
        var triggers: [EmotionalTrigger] = []

        // Time of day inference
        let hour = Calendar.current.component(.hour, from: Date())
        if hour >= 22 || hour < 6 {
            inferredEnergy = .low
            inferredStress += 1
        }

        // Day of week inference
        let weekday = Calendar.current.component(.weekday, from: Date())
        if weekday == 1 { // Sunday
            triggers.append(.boredom)
        } else if weekday == 6 { // Friday
            inferredMood = .happy
            triggers.append(.celebration)
        }

        // Use health data if available
        if let lifeContext = LifeContextManager.shared.healthContext.lastNightSleep {
            if lifeContext < 6 {
                inferredEnergy = .low
                inferredStress += 2
                inferredMood = .stressed
            }
        }

        if LifeContextManager.shared.healthContext.stressLevel == .high {
            inferredMood = .stressed
            inferredStress = 8
            triggers.append(.work)
        }

        let entry = MoodEntry(
            id: UUID().uuidString,
            timestamp: Date(),
            mood: inferredMood,
            energy: inferredEnergy,
            stressLevel: inferredStress,
            triggers: triggers,
            notes: nil,
            source: .inferred
        )

        currentMood = entry
        updateSpendingRiskLevel()
    }

    // MARK: - Transaction Emotional Tagging

    func tagTransaction(transactionId: String, amount: Double, merchant: String, category: String, mood: MoodEntry.Mood? = nil, triggers: [EmotionalTrigger] = [], wasImpulse: Bool = false) {
        let effectiveMood = mood ?? currentMood?.mood

        let emotionalTransaction = EmotionalTransaction(
            id: UUID().uuidString,
            transactionId: transactionId,
            amount: amount,
            merchantName: merchant,
            category: category,
            timestamp: Date(),
            moodAtPurchase: effectiveMood,
            energyAtPurchase: currentMood?.energy,
            triggers: triggers,
            wasImpulse: wasImpulse,
            regretLevel: nil,
            satisfaction: nil,
            coolingOffTriggered: false,
            coolingOffResult: nil
        )

        emotionalTransactions.insert(emotionalTransaction, at: 0)
        saveTransactions()
        calculateCorrelations()
    }

    func logPostPurchaseFeeling(transactionId: String, regret: Int, satisfaction: Int) {
        if let index = emotionalTransactions.firstIndex(where: { $0.transactionId == transactionId }) {
            emotionalTransactions[index].regretLevel = regret
            emotionalTransactions[index].satisfaction = satisfaction
            saveTransactions()
            analyzePatterns()
        }
    }

    // MARK: - Cooling Off Period

    func shouldTriggerCoolingOff(amount: Double, category: String) -> (shouldTrigger: Bool, reason: CoolingOffPeriod.CoolingOffReason?) {
        guard coolingOffEnabled else { return (false, nil) }

        // Check high stress
        if let mood = currentMood, mood.stressLevel >= 7 {
            return (true, .highStress)
        }

        // Check low sleep
        if let sleep = LifeContextManager.shared.healthContext.lastNightSleep, sleep < 6 {
            return (true, .lowSleep)
        }

        // Check large amount
        if amount >= largeAmountThreshold {
            return (true, .largeAmount)
        }

        // Check late night
        let hour = Calendar.current.component(.hour, from: Date())
        if hour >= 23 || hour < 5 {
            return (true, .lateNight)
        }

        // Check impulse pattern
        if hasRecentImpulsePattern() {
            return (true, .impulsePattern)
        }

        return (false, nil)
    }

    func startCoolingOffPeriod(merchant: String, amount: Double, category: String, item: String?, reason: CoolingOffPeriod.CoolingOffReason) -> CoolingOffPeriod {
        let period = CoolingOffPeriod(
            id: UUID().uuidString,
            transactionDetails: CoolingOffPeriod.PendingPurchase(
                merchantName: merchant,
                amount: amount,
                category: category,
                itemDescription: item
            ),
            startTime: Date(),
            endTime: Date().addingTimeInterval(coolingOffDuration),
            reason: reason,
            status: .active,
            reminderSent: false
        )

        activeCoolingOffPeriods.append(period)
        saveCoolingOffPeriods()

        return period
    }

    func completeCoolingOff(periodId: String, purchased: Bool) {
        if let index = activeCoolingOffPeriods.firstIndex(where: { $0.id == periodId }) {
            activeCoolingOffPeriods[index].status = purchased ? .purchased : .canceled
            saveCoolingOffPeriods()
        }
    }

    func checkCoolingOffPeriods() {
        for i in 0..<activeCoolingOffPeriods.count {
            if activeCoolingOffPeriods[i].isExpired && activeCoolingOffPeriods[i].status == .active {
                activeCoolingOffPeriods[i].status = .expired
            }
        }
        saveCoolingOffPeriods()
    }

    private func hasRecentImpulsePattern() -> Bool {
        let recentTransactions = emotionalTransactions.filter {
            $0.timestamp > Calendar.current.date(byAdding: .hour, value: -24, to: Date())!
        }
        let impulseCount = recentTransactions.filter { $0.wasImpulse }.count
        return impulseCount >= 3
    }

    // MARK: - Pattern Analysis

    func analyzePatterns() {
        var detectedPatterns: [EmotionalSpendingPattern] = []

        // Analyze retail therapy pattern
        let sadTransactions = emotionalTransactions.filter {
            $0.moodAtPurchase == .sad || $0.moodAtPurchase == .verySad
        }
        if sadTransactions.count >= 5 {
            let total = sadTransactions.reduce(0) { $0 + $1.amount }
            detectedPatterns.append(EmotionalSpendingPattern(
                id: "retail_therapy",
                pattern: .retailTherapy,
                description: "You tend to shop when feeling down",
                frequency: sadTransactions.count,
                totalAmount: total,
                averageAmount: total / Double(sadTransactions.count),
                commonMoods: [.sad, .verySad],
                commonTriggers: sadTransactions.flatMap { $0.triggers }.uniqued(),
                recommendations: [
                    "Try a walk or exercise instead of shopping when sad",
                    "Call a friend before making purchases when down",
                    "Set up a 'sad day' budget limit"
                ]
            ))
        }

        // Analyze stress shopping
        let stressTransactions = emotionalTransactions.filter {
            $0.moodAtPurchase == .stressed || $0.moodAtPurchase == .anxious
        }
        if stressTransactions.count >= 5 {
            let total = stressTransactions.reduce(0) { $0 + $1.amount }
            detectedPatterns.append(EmotionalSpendingPattern(
                id: "stress_shopping",
                pattern: .stressShopping,
                description: "Stress triggers your shopping behavior",
                frequency: stressTransactions.count,
                totalAmount: total,
                averageAmount: total / Double(stressTransactions.count),
                commonMoods: [.stressed, .anxious],
                commonTriggers: stressTransactions.flatMap { $0.triggers }.uniqued(),
                recommendations: [
                    "Practice stress-relief techniques before shopping",
                    "Use the cooling-off feature for stress purchases",
                    "Try meditation or deep breathing when stressed"
                ]
            ))
        }

        // Analyze late night shopping
        let lateNightTransactions = emotionalTransactions.filter {
            let hour = Calendar.current.component(.hour, from: $0.timestamp)
            return hour >= 22 || hour < 5
        }
        if lateNightTransactions.count >= 5 {
            let total = lateNightTransactions.reduce(0) { $0 + $1.amount }
            detectedPatterns.append(EmotionalSpendingPattern(
                id: "late_night",
                pattern: .lateNightShopping,
                description: "You make purchases late at night",
                frequency: lateNightTransactions.count,
                totalAmount: total,
                averageAmount: total / Double(lateNightTransactions.count),
                commonMoods: lateNightTransactions.compactMap { $0.moodAtPurchase }.uniqued(),
                commonTriggers: [.boredom, .habit],
                recommendations: [
                    "Remove shopping apps from your phone at night",
                    "Set 'Do Not Disturb' for shopping notifications",
                    "Add items to cart but wait until morning"
                ]
            ))
        }

        // Analyze boredom buying
        let boredomTransactions = emotionalTransactions.filter {
            $0.moodAtPurchase == .bored || $0.triggers.contains(.boredom)
        }
        if boredomTransactions.count >= 5 {
            let total = boredomTransactions.reduce(0) { $0 + $1.amount }
            detectedPatterns.append(EmotionalSpendingPattern(
                id: "boredom_buying",
                pattern: .boredomBuying,
                description: "Boredom leads to unnecessary purchases",
                frequency: boredomTransactions.count,
                totalAmount: total,
                averageAmount: total / Double(boredomTransactions.count),
                commonMoods: [.bored],
                commonTriggers: [.boredom, .habit, .socialMedia],
                recommendations: [
                    "Create a list of free activities for bored moments",
                    "Unsubscribe from promotional emails",
                    "Use screen time limits on shopping apps"
                ]
            ))
        }

        // Analyze impulse buying
        let impulseTransactions = emotionalTransactions.filter { $0.wasImpulse }
        if impulseTransactions.count >= 5 {
            let total = impulseTransactions.reduce(0) { $0 + $1.amount }
            let regrettedCount = impulseTransactions.filter { ($0.regretLevel ?? 0) >= 3 }.count
            detectedPatterns.append(EmotionalSpendingPattern(
                id: "impulse_buying",
                pattern: .impulseBuying,
                description: "You make quick purchase decisions - \(Int(Double(regrettedCount) / Double(impulseTransactions.count) * 100))% regretted",
                frequency: impulseTransactions.count,
                totalAmount: total,
                averageAmount: total / Double(impulseTransactions.count),
                commonMoods: impulseTransactions.compactMap { $0.moodAtPurchase }.uniqued(),
                commonTriggers: [.sale, .fomo, .advertising],
                recommendations: [
                    "Enable cooling-off periods for all purchases",
                    "Use the 24-hour rule for non-essential items",
                    "Ask: 'Would I buy this at full price?'"
                ]
            ))
        }

        patterns = detectedPatterns
        savePatterns()
        generateInsights()
    }

    // MARK: - Correlation Analysis

    private func calculateCorrelations() {
        // Mood spending correlation
        var moodTotals: [MoodEntry.Mood: (total: Double, count: Int)] = [:]
        for transaction in emotionalTransactions {
            if let mood = transaction.moodAtPurchase {
                let current = moodTotals[mood] ?? (0, 0)
                moodTotals[mood] = (current.total + transaction.amount, current.count + 1)
            }
        }

        let overallAverage = emotionalTransactions.isEmpty ? 0 : emotionalTransactions.reduce(0) { $0 + $1.amount } / Double(emotionalTransactions.count)

        for (mood, data) in moodTotals {
            let moodAverage = data.total / Double(data.count)
            moodSpendingCorrelation[mood] = overallAverage > 0 ? (moodAverage / overallAverage - 1) * 100 : 0
        }

        // Trigger spending correlation
        var triggerTotals: [EmotionalTrigger: (total: Double, count: Int)] = [:]
        for transaction in emotionalTransactions {
            for trigger in transaction.triggers {
                let current = triggerTotals[trigger] ?? (0, 0)
                triggerTotals[trigger] = (current.total + transaction.amount, current.count + 1)
            }
        }

        for (trigger, data) in triggerTotals {
            let triggerAverage = data.total / Double(data.count)
            triggerSpendingCorrelation[trigger] = overallAverage > 0 ? (triggerAverage / overallAverage - 1) * 100 : 0
        }

        // Time of day correlation
        var hourTotals: [Int: (total: Double, count: Int)] = [:]
        for transaction in emotionalTransactions {
            let hour = Calendar.current.component(.hour, from: transaction.timestamp)
            let current = hourTotals[hour] ?? (0, 0)
            hourTotals[hour] = (current.total + transaction.amount, current.count + 1)
        }

        for (hour, data) in hourTotals {
            let hourAverage = data.total / Double(data.count)
            timeOfDayCorrelation[hour] = overallAverage > 0 ? (hourAverage / overallAverage - 1) * 100 : 0
        }

        // Day of week correlation
        var dayTotals: [Int: (total: Double, count: Int)] = [:]
        for transaction in emotionalTransactions {
            let day = Calendar.current.component(.weekday, from: transaction.timestamp)
            let current = dayTotals[day] ?? (0, 0)
            dayTotals[day] = (current.total + transaction.amount, current.count + 1)
        }

        for (day, data) in dayTotals {
            let dayAverage = data.total / Double(data.count)
            dayOfWeekCorrelation[day] = overallAverage > 0 ? (dayAverage / overallAverage - 1) * 100 : 0
        }
    }

    // MARK: - Insight Generation

    private func generateInsights() {
        var newInsights: [EmotionalInsight] = []

        // Mood-based insights
        for (mood, correlation) in moodSpendingCorrelation {
            if correlation > 30 {
                newInsights.append(EmotionalInsight(
                    id: "mood_\(mood.rawValue)",
                    type: .correlation,
                    title: "Spending Spike When \(mood.rawValue)",
                    message: "You spend \(Int(correlation))% more when feeling \(mood.rawValue.lowercased())",
                    data: EmotionalInsight.InsightData(
                        mood: mood,
                        trigger: nil,
                        amount: nil,
                        timeOfDay: nil,
                        dayOfWeek: nil,
                        comparisonPercentage: correlation
                    ),
                    actionable: true,
                    action: "Set up alerts for \(mood.rawValue.lowercased()) spending",
                    createdAt: Date()
                ))
            }
        }

        // Trigger-based insights
        for (trigger, correlation) in triggerSpendingCorrelation {
            if correlation > 40 {
                newInsights.append(EmotionalInsight(
                    id: "trigger_\(trigger.rawValue)",
                    type: .warning,
                    title: "\(trigger.rawValue) Drives Spending",
                    message: "Purchases triggered by '\(trigger.rawValue)' are \(Int(correlation))% higher than average",
                    data: EmotionalInsight.InsightData(
                        mood: nil,
                        trigger: trigger,
                        amount: nil,
                        timeOfDay: nil,
                        dayOfWeek: nil,
                        comparisonPercentage: correlation
                    ),
                    actionable: true,
                    action: "Review \(trigger.rawValue.lowercased()) purchases",
                    createdAt: Date()
                ))
            }
        }

        // Time-based insights
        if let maxHour = timeOfDayCorrelation.max(by: { $0.value < $1.value }), maxHour.value > 25 {
            let hourString = formatHour(maxHour.key)
            newInsights.append(EmotionalInsight(
                id: "time_peak",
                type: .pattern,
                title: "Peak Spending Time: \(hourString)",
                message: "You spend \(Int(maxHour.value))% more around \(hourString)",
                data: EmotionalInsight.InsightData(
                    mood: nil,
                    trigger: nil,
                    amount: nil,
                    timeOfDay: hourString,
                    dayOfWeek: nil,
                    comparisonPercentage: maxHour.value
                ),
                actionable: true,
                action: "Enable cooling-off for purchases around this time",
                createdAt: Date()
            ))
        }

        // Achievement insight
        let lowRegretTransactions = emotionalTransactions.filter { ($0.regretLevel ?? 0) <= 2 }
        if lowRegretTransactions.count >= 10 {
            let regretRate = Double(lowRegretTransactions.count) / Double(emotionalTransactions.count) * 100
            if regretRate >= 80 {
                newInsights.append(EmotionalInsight(
                    id: "low_regret",
                    type: .achievement,
                    title: "Mindful Spender!",
                    message: "\(Int(regretRate))% of your recent purchases have low regret scores",
                    data: EmotionalInsight.InsightData(
                        mood: nil,
                        trigger: nil,
                        amount: nil,
                        timeOfDay: nil,
                        dayOfWeek: nil,
                        comparisonPercentage: regretRate
                    ),
                    actionable: false,
                    action: nil,
                    createdAt: Date()
                ))
            }
        }

        insights = newInsights
    }

    // MARK: - Risk Assessment

    private func updateSpendingRiskLevel() {
        var risk: Double = 50 // Baseline

        if let mood = currentMood {
            // Mood impact
            risk += (mood.mood.spendingRiskMultiplier - 1) * 50

            // Energy impact
            risk += (mood.energy.spendingImpact - 1) * 30

            // Stress impact
            risk += Double(mood.stressLevel - 5) * 3

            // Trigger impact
            for trigger in mood.triggers {
                switch trigger {
                case .fomo, .sale, .advertising, .socialMedia:
                    risk += 10
                case .boredom, .reward:
                    risk += 8
                case .work:
                    risk += 7
                default:
                    risk += 3
                }
            }
        }

        // Time of day impact
        let hour = Calendar.current.component(.hour, from: Date())
        if hour >= 22 || hour < 6 {
            risk += 15
        }

        // Recent pattern impact
        if !activeCoolingOffPeriods.isEmpty {
            risk += 10
        }

        spendingRiskLevel = max(0, min(100, risk))
    }

    func getRiskAssessment() -> (level: String, color: String, advice: String) {
        if spendingRiskLevel < 30 {
            return ("Low Risk", "green", "Good time to make mindful purchases")
        } else if spendingRiskLevel < 50 {
            return ("Moderate Risk", "yellow", "Consider if purchases are truly needed")
        } else if spendingRiskLevel < 70 {
            return ("Elevated Risk", "orange", "High emotional influence - use cooling-off periods")
        } else {
            return ("High Risk", "red", "Not recommended for non-essential purchases")
        }
    }

    // MARK: - Settings

    func updateSettings(coolingOffEnabled: Bool, coolingOffHours: Int, largeAmountThreshold: Double) {
        self.coolingOffEnabled = coolingOffEnabled
        self.coolingOffDuration = TimeInterval(coolingOffHours * 60 * 60)
        self.largeAmountThreshold = largeAmountThreshold
        saveSettings()
    }

    // MARK: - Persistence

    private func loadData() {
        if let data = userDefaults.data(forKey: moodHistoryKey),
           let moods = try? JSONDecoder().decode([MoodEntry].self, from: data) {
            moodHistory = moods
            currentMood = moods.first
        }

        if let data = userDefaults.data(forKey: transactionsKey),
           let transactions = try? JSONDecoder().decode([EmotionalTransaction].self, from: data) {
            emotionalTransactions = transactions
        }

        if let data = userDefaults.data(forKey: patternsKey),
           let savedPatterns = try? JSONDecoder().decode([EmotionalSpendingPattern].self, from: data) {
            patterns = savedPatterns
        }

        if let data = userDefaults.data(forKey: coolingOffKey),
           let periods = try? JSONDecoder().decode([CoolingOffPeriod].self, from: data) {
            activeCoolingOffPeriods = periods
        }

        if let data = userDefaults.data(forKey: settingsKey),
           let settings = try? JSONDecoder().decode([String: Double].self, from: data) {
            coolingOffEnabled = settings["enabled"] == 1
            coolingOffDuration = settings["duration"] ?? 86400
            largeAmountThreshold = settings["threshold"] ?? 100
        }
    }

    private func saveMoodHistory() {
        if let data = try? JSONEncoder().encode(moodHistory) {
            userDefaults.set(data, forKey: moodHistoryKey)
        }
    }

    private func saveTransactions() {
        if let data = try? JSONEncoder().encode(emotionalTransactions) {
            userDefaults.set(data, forKey: transactionsKey)
        }
    }

    private func savePatterns() {
        if let data = try? JSONEncoder().encode(patterns) {
            userDefaults.set(data, forKey: patternsKey)
        }
    }

    private func saveCoolingOffPeriods() {
        if let data = try? JSONEncoder().encode(activeCoolingOffPeriods) {
            userDefaults.set(data, forKey: coolingOffKey)
        }
    }

    private func saveSettings() {
        let settings: [String: Double] = [
            "enabled": coolingOffEnabled ? 1 : 0,
            "duration": coolingOffDuration,
            "threshold": largeAmountThreshold
        ]
        if let data = try? JSONEncoder().encode(settings) {
            userDefaults.set(data, forKey: settingsKey)
        }
    }

    // MARK: - Helpers

    private func formatHour(_ hour: Int) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h a"
        var components = DateComponents()
        components.hour = hour
        if let date = Calendar.current.date(from: components) {
            return formatter.string(from: date)
        }
        return "\(hour):00"
    }
}

// MARK: - Array Extension

extension Array where Element: Hashable {
    func uniqued() -> [Element] {
        var seen = Set<Element>()
        return filter { seen.insert($0).inserted }
    }
}
