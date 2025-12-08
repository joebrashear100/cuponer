import Foundation
import Combine

// MARK: - Conversation Memory Models

struct FinancialMemory: Identifiable, Codable {
    let id: String
    let type: MemoryType
    let content: String
    let context: MemoryContext
    let createdAt: Date
    var lastAccessed: Date
    var accessCount: Int
    var importance: Importance
    var tags: [String]
    var relatedMemoryIds: [String]
    var isArchived: Bool

    enum MemoryType: String, Codable, CaseIterable {
        case goal = "Goal"
        case preference = "Preference"
        case decision = "Decision"
        case milestone = "Milestone"
        case concern = "Concern"
        case plan = "Plan"
        case insight = "Insight"
        case fact = "Personal Fact"
        case wish = "Wish"
        case commitment = "Commitment"
    }

    struct MemoryContext: Codable {
        let category: String?
        let amount: Double?
        let targetDate: Date?
        let priority: Int?
        let sentiment: Sentiment?
        let entities: [Entity]

        enum Sentiment: String, Codable {
            case positive, neutral, negative, anxious, excited, determined
        }

        struct Entity: Codable {
            let type: EntityType
            let value: String

            enum EntityType: String, Codable {
                case person, merchant, category, amount, date, product, location
            }
        }
    }

    enum Importance: String, Codable, CaseIterable {
        case low, medium, high, critical

        var weight: Double {
            switch self {
            case .low: return 1.0
            case .medium: return 2.0
            case .high: return 3.0
            case .critical: return 5.0
            }
        }
    }
}

struct FinancialGoal: Identifiable, Codable {
    let id: String
    var name: String
    var description: String
    var targetAmount: Double
    var currentAmount: Double
    var targetDate: Date?
    var category: GoalCategory
    var priority: Int
    var status: Status
    var milestones: [Milestone]
    var linkedMemoryIds: [String]
    var createdAt: Date
    var updatedAt: Date

    enum GoalCategory: String, Codable, CaseIterable {
        case savings = "Savings"
        case purchase = "Purchase"
        case debt = "Debt Payoff"
        case investment = "Investment"
        case emergency = "Emergency Fund"
        case retirement = "Retirement"
        case travel = "Travel"
        case education = "Education"
        case home = "Home"
        case vehicle = "Vehicle"
        case other = "Other"

        var icon: String {
            switch self {
            case .savings: return "banknote.fill"
            case .purchase: return "bag.fill"
            case .debt: return "creditcard.fill"
            case .investment: return "chart.line.uptrend.xyaxis"
            case .emergency: return "cross.case.fill"
            case .retirement: return "beach.umbrella.fill"
            case .travel: return "airplane"
            case .education: return "graduationcap.fill"
            case .home: return "house.fill"
            case .vehicle: return "car.fill"
            case .other: return "star.fill"
            }
        }
    }

    enum Status: String, Codable {
        case active, paused, completed, abandoned
    }

    struct Milestone: Identifiable, Codable {
        let id: String
        let name: String
        let targetAmount: Double
        var isCompleted: Bool
        var completedAt: Date?
    }

    var progress: Double {
        guard targetAmount > 0 else { return 0 }
        return min(currentAmount / targetAmount, 1.0)
    }

    var remainingAmount: Double {
        return max(targetAmount - currentAmount, 0)
    }
}

struct UserPreference: Identifiable, Codable {
    let id: String
    let category: PreferenceCategory
    var value: String
    var confidence: Double
    var learnedFrom: [String] // Memory IDs
    var lastUpdated: Date

    enum PreferenceCategory: String, Codable, CaseIterable {
        case riskTolerance = "Risk Tolerance"
        case spendingStyle = "Spending Style"
        case savingsApproach = "Savings Approach"
        case investmentStyle = "Investment Style"
        case notificationPreference = "Notification Preference"
        case budgetingMethod = "Budgeting Method"
        case financialPriority = "Financial Priority"
        case shoppingHabit = "Shopping Habit"
        case brandLoyalty = "Brand Loyalty"
        case dealSensitivity = "Deal Sensitivity"
    }
}

struct ConversationContext: Codable {
    var recentTopics: [String]
    var currentGoalFocus: String?
    var pendingQuestions: [String]
    var userMood: String?
    var lastInteraction: Date
    var sessionCount: Int
}

struct MemorySearchResult: Identifiable {
    let id: String
    let memory: FinancialMemory
    let relevanceScore: Double
    let matchedTerms: [String]
}

// MARK: - Conversation Memory Manager

class ConversationMemoryManager: ObservableObject {
    static let shared = ConversationMemoryManager()

    // MARK: - Published Properties
    @Published var memories: [FinancialMemory] = []
    @Published var goals: [FinancialGoal] = []
    @Published var preferences: [UserPreference] = []
    @Published var conversationContext: ConversationContext

    @Published var totalMemories: Int = 0
    @Published var activeGoals: Int = 0
    @Published var knownPreferences: Int = 0

    // Quick access
    @Published var recentMemories: [FinancialMemory] = []
    @Published var importantMemories: [FinancialMemory] = []

    // MARK: - Private Properties
    private let userDefaults = UserDefaults.standard
    private let memoriesKey = "conversationMemory_memories"
    private let goalsKey = "conversationMemory_goals"
    private let preferencesKey = "conversationMemory_preferences"
    private let contextKey = "conversationMemory_context"

    // Memory importance decay factor
    private let decayFactor: Double = 0.95 // Per week

    // MARK: - Initialization

    init() {
        self.conversationContext = ConversationContext(
            recentTopics: [],
            currentGoalFocus: nil,
            pendingQuestions: [],
            userMood: nil,
            lastInteraction: Date(),
            sessionCount: 0
        )

        loadData()
        calculateStats()
        applyMemoryDecay()
    }

    // MARK: - Memory Management

    func addMemory(type: FinancialMemory.MemoryType, content: String, context: FinancialMemory.MemoryContext, importance: FinancialMemory.Importance = .medium, tags: [String] = []) -> FinancialMemory {
        let memory = FinancialMemory(
            id: UUID().uuidString,
            type: type,
            content: content,
            context: context,
            createdAt: Date(),
            lastAccessed: Date(),
            accessCount: 1,
            importance: importance,
            tags: tags,
            relatedMemoryIds: findRelatedMemories(for: content, tags: tags),
            isArchived: false
        )

        memories.insert(memory, at: 0)
        saveMemories()
        updateStats()

        return memory
    }

    func rememberGoal(_ description: String, amount: Double?, targetDate: Date?, category: FinancialGoal.GoalCategory = .other) {
        // Create memory
        let context = FinancialMemory.MemoryContext(
            category: category.rawValue,
            amount: amount,
            targetDate: targetDate,
            priority: 1,
            sentiment: .determined,
            entities: extractEntities(from: description)
        )

        let memory = addMemory(
            type: .goal,
            content: description,
            context: context,
            importance: .high,
            tags: ["goal", category.rawValue.lowercased()]
        )

        // Create corresponding goal
        let goal = FinancialGoal(
            id: UUID().uuidString,
            name: description,
            description: description,
            targetAmount: amount ?? 0,
            currentAmount: 0,
            targetDate: targetDate,
            category: category,
            priority: 1,
            status: .active,
            milestones: generateMilestones(for: amount ?? 0),
            linkedMemoryIds: [memory.id],
            createdAt: Date(),
            updatedAt: Date()
        )

        goals.insert(goal, at: 0)
        saveGoals()
        updateStats()
    }

    func rememberPreference(_ value: String, category: UserPreference.PreferenceCategory) {
        // Create memory
        let context = FinancialMemory.MemoryContext(
            category: category.rawValue,
            amount: nil,
            targetDate: nil,
            priority: nil,
            sentiment: nil,
            entities: []
        )

        let memory = addMemory(
            type: .preference,
            content: "\(category.rawValue): \(value)",
            context: context,
            importance: .medium,
            tags: ["preference", category.rawValue.lowercased()]
        )

        // Update or create preference
        if let index = preferences.firstIndex(where: { $0.category == category }) {
            var pref = preferences[index]
            pref.value = value
            pref.confidence = min(pref.confidence + 0.1, 1.0)
            pref.learnedFrom.append(memory.id)
            pref.lastUpdated = Date()
            preferences[index] = pref
        } else {
            let pref = UserPreference(
                id: UUID().uuidString,
                category: category,
                value: value,
                confidence: 0.7,
                learnedFrom: [memory.id],
                lastUpdated: Date()
            )
            preferences.append(pref)
        }

        savePreferences()
        updateStats()
    }

    func rememberDecision(_ decision: String, amount: Double? = nil, sentiment: FinancialMemory.MemoryContext.Sentiment = .neutral) {
        let context = FinancialMemory.MemoryContext(
            category: nil,
            amount: amount,
            targetDate: nil,
            priority: nil,
            sentiment: sentiment,
            entities: extractEntities(from: decision)
        )

        _ = addMemory(
            type: .decision,
            content: decision,
            context: context,
            importance: sentiment == .negative ? .high : .medium,
            tags: ["decision"]
        )
    }

    func rememberConcern(_ concern: String) {
        let context = FinancialMemory.MemoryContext(
            category: nil,
            amount: nil,
            targetDate: nil,
            priority: 2,
            sentiment: .anxious,
            entities: extractEntities(from: concern)
        )

        _ = addMemory(
            type: .concern,
            content: concern,
            context: context,
            importance: .high,
            tags: ["concern", "follow-up"]
        )
    }

    func rememberFact(_ fact: String, category: String? = nil) {
        let context = FinancialMemory.MemoryContext(
            category: category,
            amount: nil,
            targetDate: nil,
            priority: nil,
            sentiment: nil,
            entities: extractEntities(from: fact)
        )

        _ = addMemory(
            type: .fact,
            content: fact,
            context: context,
            importance: .medium,
            tags: ["fact", category?.lowercased()].compactMap { $0 }
        )
    }

    func rememberMilestone(_ milestone: String, amount: Double?, goalId: String? = nil) {
        let context = FinancialMemory.MemoryContext(
            category: nil,
            amount: amount,
            targetDate: nil,
            priority: nil,
            sentiment: .excited,
            entities: extractEntities(from: milestone)
        )

        let memory = addMemory(
            type: .milestone,
            content: milestone,
            context: context,
            importance: .high,
            tags: ["milestone", "achievement"]
        )

        // Link to goal if specified
        if let goalId = goalId,
           let index = goals.firstIndex(where: { $0.id == goalId }) {
            var goal = goals[index]
            goal.linkedMemoryIds.append(memory.id)
            goals[index] = goal
            saveGoals()
        }
    }

    // MARK: - Memory Retrieval

    func recall(query: String, limit: Int = 10) -> [MemorySearchResult] {
        let queryTerms = query.lowercased().split(separator: " ").map { String($0) }
        var results: [MemorySearchResult] = []

        for memory in memories where !memory.isArchived {
            var score: Double = 0
            var matchedTerms: [String] = []

            let contentLower = memory.content.lowercased()
            let tagsLower = memory.tags.map { $0.lowercased() }

            for term in queryTerms {
                if contentLower.contains(term) {
                    score += 2.0
                    matchedTerms.append(term)
                }
                if tagsLower.contains(where: { $0.contains(term) }) {
                    score += 1.5
                    matchedTerms.append(term)
                }
                if memory.context.category?.lowercased().contains(term) == true {
                    score += 1.0
                    matchedTerms.append(term)
                }
            }

            // Apply importance weight
            score *= memory.importance.weight

            // Apply recency boost
            let daysSinceCreation = Calendar.current.dateComponents([.day], from: memory.createdAt, to: Date()).day ?? 0
            let recencyBoost = max(0, 1.0 - Double(daysSinceCreation) / 365.0)
            score *= (1.0 + recencyBoost * 0.5)

            // Apply access frequency boost
            let accessBoost = min(Double(memory.accessCount) / 10.0, 1.0)
            score *= (1.0 + accessBoost * 0.3)

            if score > 0 {
                results.append(MemorySearchResult(
                    id: memory.id,
                    memory: memory,
                    relevanceScore: score,
                    matchedTerms: matchedTerms
                ))
            }
        }

        // Sort by relevance and limit
        let sorted = results.sorted { $0.relevanceScore > $1.relevanceScore }
        return Array(sorted.prefix(limit))
    }

    func getMemoriesOfType(_ type: FinancialMemory.MemoryType) -> [FinancialMemory] {
        return memories.filter { $0.type == type && !$0.isArchived }
    }

    func getGoalsInCategory(_ category: FinancialGoal.GoalCategory) -> [FinancialGoal] {
        return goals.filter { $0.category == category && $0.status == .active }
    }

    func getPreference(for category: UserPreference.PreferenceCategory) -> UserPreference? {
        return preferences.first { $0.category == category }
    }

    func getRelevantMemoriesForContext(_ context: String) -> [FinancialMemory] {
        let results = recall(query: context, limit: 5)
        return results.map { $0.memory }
    }

    // MARK: - Goal Management

    func updateGoalProgress(_ goalId: String, newAmount: Double) {
        guard let index = goals.firstIndex(where: { $0.id == goalId }) else { return }

        var goal = goals[index]
        let previousAmount = goal.currentAmount
        goal.currentAmount = newAmount
        goal.updatedAt = Date()

        // Check milestones
        for i in 0..<goal.milestones.count {
            if !goal.milestones[i].isCompleted && newAmount >= goal.milestones[i].targetAmount {
                goal.milestones[i].isCompleted = true
                goal.milestones[i].completedAt = Date()

                // Remember milestone
                rememberMilestone(
                    "Reached \(goal.milestones[i].name) for \(goal.name)",
                    amount: goal.milestones[i].targetAmount,
                    goalId: goalId
                )
            }
        }

        // Check goal completion
        if newAmount >= goal.targetAmount && goal.status == .active {
            goal.status = .completed
            rememberMilestone("Completed goal: \(goal.name)!", amount: goal.targetAmount, goalId: goalId)
        }

        goals[index] = goal
        saveGoals()
    }

    // MARK: - Context Management

    func updateContext(topic: String? = nil, goalFocus: String? = nil, mood: String? = nil) {
        if let topic = topic {
            conversationContext.recentTopics.insert(topic, at: 0)
            if conversationContext.recentTopics.count > 10 {
                conversationContext.recentTopics.removeLast()
            }
        }

        if let goalFocus = goalFocus {
            conversationContext.currentGoalFocus = goalFocus
        }

        if let mood = mood {
            conversationContext.userMood = mood
        }

        conversationContext.lastInteraction = Date()
        conversationContext.sessionCount += 1

        saveContext()
    }

    func addPendingQuestion(_ question: String) {
        conversationContext.pendingQuestions.append(question)
        saveContext()
    }

    func resolvePendingQuestion(_ question: String) {
        conversationContext.pendingQuestions.removeAll { $0 == question }
        saveContext()
    }

    // MARK: - Summary Generation

    func generateUserProfile() -> String {
        var profile: [String] = []

        // Goals summary
        let activeGoals = goals.filter { $0.status == .active }
        if !activeGoals.isEmpty {
            profile.append("Active Goals:")
            for goal in activeGoals.prefix(5) {
                profile.append("  - \(goal.name): \(Int(goal.progress * 100))% complete")
            }
        }

        // Preferences summary
        if !preferences.isEmpty {
            profile.append("\nKnown Preferences:")
            for pref in preferences where pref.confidence > 0.5 {
                profile.append("  - \(pref.category.rawValue): \(pref.value)")
            }
        }

        // Recent concerns
        let concerns = getMemoriesOfType(.concern)
        if !concerns.isEmpty {
            profile.append("\nRecent Concerns:")
            for concern in concerns.prefix(3) {
                profile.append("  - \(concern.content)")
            }
        }

        // Key decisions
        let decisions = getMemoriesOfType(.decision).filter { $0.importance == .high }
        if !decisions.isEmpty {
            profile.append("\nImportant Decisions:")
            for decision in decisions.prefix(3) {
                profile.append("  - \(decision.content)")
            }
        }

        return profile.joined(separator: "\n")
    }

    func generateContextSummary() -> String {
        var summary: [String] = []

        if !conversationContext.recentTopics.isEmpty {
            summary.append("Recent topics: \(conversationContext.recentTopics.prefix(3).joined(separator: ", "))")
        }

        if let goalFocus = conversationContext.currentGoalFocus {
            summary.append("Currently focused on: \(goalFocus)")
        }

        if let mood = conversationContext.userMood {
            summary.append("User mood: \(mood)")
        }

        if !conversationContext.pendingQuestions.isEmpty {
            summary.append("Pending questions: \(conversationContext.pendingQuestions.count)")
        }

        return summary.joined(separator: "\n")
    }

    // MARK: - Private Methods

    private func extractEntities(from text: String) -> [FinancialMemory.MemoryContext.Entity] {
        var entities: [FinancialMemory.MemoryContext.Entity] = []

        // Extract amounts
        let amountPattern = "\\$([0-9,]+\\.?[0-9]*)"
        if let regex = try? NSRegularExpression(pattern: amountPattern, options: []) {
            let range = NSRange(text.startIndex..., in: text)
            let matches = regex.matches(in: text, range: range)
            for match in matches {
                if let matchRange = Range(match.range, in: text) {
                    entities.append(FinancialMemory.MemoryContext.Entity(
                        type: .amount,
                        value: String(text[matchRange])
                    ))
                }
            }
        }

        // Extract dates
        let datePatterns = ["next month", "this year", "by 2025", "in \\d+ months?", "in \\d+ years?"]
        for pattern in datePatterns {
            if let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive) {
                let range = NSRange(text.startIndex..., in: text)
                if let match = regex.firstMatch(in: text, range: range),
                   let matchRange = Range(match.range, in: text) {
                    entities.append(FinancialMemory.MemoryContext.Entity(
                        type: .date,
                        value: String(text[matchRange])
                    ))
                }
            }
        }

        // Extract common financial categories
        let categories = ["savings", "investing", "retirement", "vacation", "house", "car", "debt", "emergency fund"]
        for category in categories {
            if text.lowercased().contains(category) {
                entities.append(FinancialMemory.MemoryContext.Entity(
                    type: .category,
                    value: category.capitalized
                ))
            }
        }

        return entities
    }

    private func findRelatedMemories(for content: String, tags: [String]) -> [String] {
        let results = recall(query: content, limit: 3)
        return results.map { $0.memory.id }
    }

    private func generateMilestones(for amount: Double) -> [FinancialGoal.Milestone] {
        guard amount > 0 else { return [] }

        let milestonePercentages = [0.25, 0.5, 0.75, 1.0]
        return milestonePercentages.map { percentage in
            FinancialGoal.Milestone(
                id: UUID().uuidString,
                name: "\(Int(percentage * 100))% Complete",
                targetAmount: amount * percentage,
                isCompleted: false,
                completedAt: nil
            )
        }
    }

    private func applyMemoryDecay() {
        let calendar = Calendar.current

        for i in 0..<memories.count {
            let weeksSinceAccess = calendar.dateComponents([.weekOfYear], from: memories[i].lastAccessed, to: Date()).weekOfYear ?? 0

            if weeksSinceAccess > 0 && memories[i].importance != .critical {
                // Apply decay to importance
                // Note: In a real app, this would be a calculated relevance score
            }
        }
    }

    private func updateStats() {
        totalMemories = memories.filter { !$0.isArchived }.count
        activeGoals = goals.filter { $0.status == .active }.count
        knownPreferences = preferences.count
        recentMemories = Array(memories.filter { !$0.isArchived }.prefix(10))
        importantMemories = memories.filter { $0.importance == .high || $0.importance == .critical }.filter { !$0.isArchived }
    }

    private func calculateStats() {
        updateStats()
    }

    // MARK: - Persistence

    private func loadData() {
        if let data = userDefaults.data(forKey: memoriesKey),
           let saved = try? JSONDecoder().decode([FinancialMemory].self, from: data) {
            memories = saved
        }

        if let data = userDefaults.data(forKey: goalsKey),
           let saved = try? JSONDecoder().decode([FinancialGoal].self, from: data) {
            goals = saved
        }

        if let data = userDefaults.data(forKey: preferencesKey),
           let saved = try? JSONDecoder().decode([UserPreference].self, from: data) {
            preferences = saved
        }

        if let data = userDefaults.data(forKey: contextKey),
           let saved = try? JSONDecoder().decode(ConversationContext.self, from: data) {
            conversationContext = saved
        }
    }

    private func saveMemories() {
        if let data = try? JSONEncoder().encode(memories) {
            userDefaults.set(data, forKey: memoriesKey)
        }
    }

    private func saveGoals() {
        if let data = try? JSONEncoder().encode(goals) {
            userDefaults.set(data, forKey: goalsKey)
        }
    }

    private func savePreferences() {
        if let data = try? JSONEncoder().encode(preferences) {
            userDefaults.set(data, forKey: preferencesKey)
        }
    }

    private func saveContext() {
        if let data = try? JSONEncoder().encode(conversationContext) {
            userDefaults.set(data, forKey: contextKey)
        }
    }
}
