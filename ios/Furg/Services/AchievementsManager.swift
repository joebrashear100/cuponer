//
//  AchievementsManager.swift
//  Furg
//
//  Gamification system for financial achievements and streaks
//

import Foundation
import SwiftUI
import Combine

class AchievementsManager: ObservableObject {
    static let shared = AchievementsManager()

    @Published var achievements: [Achievement] = []
    @Published var unlockedAchievements: [Achievement] = []
    @Published var currentStreak: SpendingStreak = SpendingStreak()
    @Published var weeklyChallenge: WeeklyChallenge?
    @Published var totalPoints: Int = 0
    @Published var level: Int = 1
    @Published var recentUnlock: Achievement?

    private var cancellables = Set<AnyCancellable>()

    private init() {
        setupAchievements()
        loadProgress()
        generateWeeklyChallenge()
    }

    // MARK: - Achievements Setup

    private func setupAchievements() {
        achievements = [
            // Savings Achievements
            Achievement(
                id: "first_save",
                name: "First Steps",
                description: "Make your first savings contribution",
                icon: "leaf.fill",
                category: .savings,
                points: 10,
                requirement: 1,
                tier: .bronze
            ),
            Achievement(
                id: "save_100",
                name: "Benjamin Saver",
                description: "Save $100 total",
                icon: "banknote.fill",
                category: .savings,
                points: 25,
                requirement: 100,
                tier: .bronze
            ),
            Achievement(
                id: "save_1000",
                name: "Thousand Club",
                description: "Save $1,000 total",
                icon: "dollarsign.circle.fill",
                category: .savings,
                points: 100,
                requirement: 1000,
                tier: .silver
            ),
            Achievement(
                id: "save_10000",
                name: "Five-Figure Saver",
                description: "Save $10,000 total",
                icon: "star.circle.fill",
                category: .savings,
                points: 500,
                requirement: 10000,
                tier: .gold
            ),
            Achievement(
                id: "emergency_fund",
                name: "Safety Net",
                description: "Build a 3-month emergency fund",
                icon: "shield.fill",
                category: .savings,
                points: 250,
                requirement: 3,
                tier: .gold
            ),

            // Budget Achievements
            Achievement(
                id: "budget_week",
                name: "Budget Rookie",
                description: "Stay under budget for a week",
                icon: "chart.pie.fill",
                category: .budget,
                points: 15,
                requirement: 7,
                tier: .bronze
            ),
            Achievement(
                id: "budget_month",
                name: "Budget Pro",
                description: "Stay under budget for a month",
                icon: "checkmark.circle.fill",
                category: .budget,
                points: 50,
                requirement: 30,
                tier: .silver
            ),
            Achievement(
                id: "budget_quarter",
                name: "Budget Master",
                description: "Stay under budget for 3 months",
                icon: "crown.fill",
                category: .budget,
                points: 200,
                requirement: 90,
                tier: .gold
            ),

            // Goal Achievements
            Achievement(
                id: "first_goal",
                name: "Goal Setter",
                description: "Create your first savings goal",
                icon: "target",
                category: .goals,
                points: 10,
                requirement: 1,
                tier: .bronze
            ),
            Achievement(
                id: "goal_achieved",
                name: "Goal Crusher",
                description: "Achieve a savings goal",
                icon: "flag.fill",
                category: .goals,
                points: 100,
                requirement: 1,
                tier: .silver
            ),
            Achievement(
                id: "five_goals",
                name: "Ambitious",
                description: "Complete 5 savings goals",
                icon: "flame.fill",
                category: .goals,
                points: 300,
                requirement: 5,
                tier: .gold
            ),

            // Streak Achievements
            Achievement(
                id: "streak_7",
                name: "Week Warrior",
                description: "7-day under-budget streak",
                icon: "bolt.fill",
                category: .streaks,
                points: 20,
                requirement: 7,
                tier: .bronze
            ),
            Achievement(
                id: "streak_30",
                name: "Month Master",
                description: "30-day under-budget streak",
                icon: "bolt.circle.fill",
                category: .streaks,
                points: 75,
                requirement: 30,
                tier: .silver
            ),
            Achievement(
                id: "streak_100",
                name: "Century Club",
                description: "100-day under-budget streak",
                icon: "bolt.shield.fill",
                category: .streaks,
                points: 500,
                requirement: 100,
                tier: .platinum
            ),

            // Special Achievements
            Achievement(
                id: "no_spend_day",
                name: "Zero Hero",
                description: "Complete a no-spend day",
                icon: "0.circle.fill",
                category: .special,
                points: 5,
                requirement: 1,
                tier: .bronze
            ),
            Achievement(
                id: "no_spend_week",
                name: "Frugal Week",
                description: "Complete a no-spend week (excluding essentials)",
                icon: "lock.fill",
                category: .special,
                points: 100,
                requirement: 7,
                tier: .gold
            ),
            Achievement(
                id: "early_bird",
                name: "Early Bird",
                description: "Pay a bill before the due date",
                icon: "clock.fill",
                category: .special,
                points: 10,
                requirement: 1,
                tier: .bronze
            ),
            Achievement(
                id: "debt_crusher",
                name: "Debt Crusher",
                description: "Pay off a debt completely",
                icon: "hammer.fill",
                category: .special,
                points: 200,
                requirement: 1,
                tier: .gold
            )
        ]
    }

    // MARK: - Progress Management

    func loadProgress() {
        // Load from UserDefaults in production
        // Demo: Unlock some achievements
        let unlockedIds = ["first_save", "save_100", "budget_week", "first_goal", "no_spend_day", "early_bird"]
        unlockedAchievements = achievements.filter { unlockedIds.contains($0.id) }

        for i in achievements.indices {
            if unlockedIds.contains(achievements[i].id) {
                achievements[i].isUnlocked = true
                achievements[i].unlockedDate = Calendar.current.date(byAdding: .day, value: -Int.random(in: 1...30), to: Date())
            }
        }

        calculateTotalPoints()
        calculateLevel()

        // Demo streak
        currentStreak = SpendingStreak(
            currentDays: 12,
            longestDays: 23,
            lastUnderBudgetDate: Date(),
            startDate: Calendar.current.date(byAdding: .day, value: -12, to: Date())!
        )
    }

    func checkAndUnlockAchievement(id: String, currentProgress: Double) {
        guard let index = achievements.firstIndex(where: { $0.id == id }),
              !achievements[index].isUnlocked else { return }

        achievements[index].currentProgress = currentProgress

        if currentProgress >= Double(achievements[index].requirement) {
            unlockAchievement(at: index)
        }
    }

    private func unlockAchievement(at index: Int) {
        achievements[index].isUnlocked = true
        achievements[index].unlockedDate = Date()

        let achievement = achievements[index]
        unlockedAchievements.append(achievement)
        recentUnlock = achievement

        // Haptic feedback
        ThemeManager.shared.triggerNotificationHaptic(.success)

        calculateTotalPoints()
        calculateLevel()

        // Clear recent unlock after delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
            self.recentUnlock = nil
        }
    }

    private func calculateTotalPoints() {
        totalPoints = unlockedAchievements.reduce(0) { $0 + $1.points }
    }

    private func calculateLevel() {
        // Level thresholds
        let thresholds = [0, 50, 150, 300, 500, 750, 1000, 1500, 2000, 3000, 5000]

        for (index, threshold) in thresholds.enumerated() {
            if totalPoints >= threshold {
                level = index + 1
            }
        }
    }

    func pointsToNextLevel() -> Int {
        let thresholds = [50, 150, 300, 500, 750, 1000, 1500, 2000, 3000, 5000, 10000]
        guard level <= thresholds.count else { return 0 }
        return thresholds[level - 1] - totalPoints
    }

    // MARK: - Streak Management

    func recordDayUnderBudget() {
        let calendar = Calendar.current

        if let lastDate = currentStreak.lastUnderBudgetDate,
           calendar.isDate(lastDate, inSameDayAs: Date()) {
            return // Already recorded today
        }

        if let lastDate = currentStreak.lastUnderBudgetDate,
           let daysSince = calendar.dateComponents([.day], from: lastDate, to: Date()).day,
           daysSince == 1 {
            // Continue streak
            currentStreak.currentDays += 1
        } else {
            // Start new streak
            currentStreak.currentDays = 1
            currentStreak.startDate = Date()
        }

        currentStreak.lastUnderBudgetDate = Date()

        if currentStreak.currentDays > currentStreak.longestDays {
            currentStreak.longestDays = currentStreak.currentDays
        }

        // Check streak achievements
        checkAndUnlockAchievement(id: "streak_7", currentProgress: Double(currentStreak.currentDays))
        checkAndUnlockAchievement(id: "streak_30", currentProgress: Double(currentStreak.currentDays))
        checkAndUnlockAchievement(id: "streak_100", currentProgress: Double(currentStreak.currentDays))
    }

    func breakStreak() {
        currentStreak.currentDays = 0
        currentStreak.startDate = nil
    }

    // MARK: - Weekly Challenges

    func generateWeeklyChallenge() {
        let challenges = [
            WeeklyChallenge(
                title: "No Eating Out",
                description: "Don't spend on restaurants or takeout this week",
                icon: "fork.knife",
                targetAmount: 0,
                category: "Food & Dining",
                points: 50,
                daysRemaining: daysUntilSunday()
            ),
            WeeklyChallenge(
                title: "Coffee Budget",
                description: "Spend less than $20 on coffee shops",
                icon: "cup.and.saucer.fill",
                targetAmount: 20,
                category: "Coffee",
                points: 30,
                daysRemaining: daysUntilSunday()
            ),
            WeeklyChallenge(
                title: "Shopping Freeze",
                description: "No non-essential shopping this week",
                icon: "bag.fill",
                targetAmount: 0,
                category: "Shopping",
                points: 75,
                daysRemaining: daysUntilSunday()
            ),
            WeeklyChallenge(
                title: "Entertainment Diet",
                description: "Spend less than $50 on entertainment",
                icon: "film.fill",
                targetAmount: 50,
                category: "Entertainment",
                points: 40,
                daysRemaining: daysUntilSunday()
            ),
            WeeklyChallenge(
                title: "Save $100",
                description: "Contribute $100 to your savings goals",
                icon: "banknote.fill",
                targetAmount: 100,
                category: nil,
                points: 60,
                daysRemaining: daysUntilSunday()
            )
        ]

        weeklyChallenge = challenges.randomElement()
    }

    private func daysUntilSunday() -> Int {
        let calendar = Calendar.current
        let today = calendar.component(.weekday, from: Date())
        return (8 - today) % 7
    }

    func completeWeeklyChallenge() {
        guard let challenge = weeklyChallenge else { return }

        totalPoints += challenge.points
        calculateLevel()
        ThemeManager.shared.triggerNotificationHaptic(.success)

        // Generate new challenge
        generateWeeklyChallenge()
    }
}

// MARK: - Models

struct Achievement: Identifiable {
    let id: String
    let name: String
    let description: String
    let icon: String
    let category: AchievementCategory
    let points: Int
    let requirement: Int
    let tier: AchievementTier
    var currentProgress: Double = 0
    var isUnlocked: Bool = false
    var unlockedDate: Date?

    var progressPercentage: Double {
        min(currentProgress / Double(requirement), 1.0)
    }
}

enum AchievementCategory: String, CaseIterable {
    case savings = "Savings"
    case budget = "Budget"
    case goals = "Goals"
    case streaks = "Streaks"
    case special = "Special"

    var color: Color {
        switch self {
        case .savings: return .furgSuccess
        case .budget: return .furgMint
        case .goals: return .furgWarning
        case .streaks: return .orange
        case .special: return .purple
        }
    }
}

enum AchievementTier: String {
    case bronze = "Bronze"
    case silver = "Silver"
    case gold = "Gold"
    case platinum = "Platinum"

    var color: Color {
        switch self {
        case .bronze: return Color(red: 0.8, green: 0.5, blue: 0.2)
        case .silver: return Color(red: 0.75, green: 0.75, blue: 0.8)
        case .gold: return Color(red: 1.0, green: 0.84, blue: 0.0)
        case .platinum: return Color(red: 0.9, green: 0.95, blue: 1.0)
        }
    }
}

struct SpendingStreak {
    var currentDays: Int = 0
    var longestDays: Int = 0
    var lastUnderBudgetDate: Date?
    var startDate: Date?

    var isActive: Bool {
        guard let lastDate = lastUnderBudgetDate else { return false }
        let calendar = Calendar.current
        let daysSince = calendar.dateComponents([.day], from: lastDate, to: Date()).day ?? 0
        return daysSince <= 1
    }
}

struct WeeklyChallenge: Identifiable {
    let id = UUID()
    let title: String
    let description: String
    let icon: String
    let targetAmount: Double
    let category: String?
    let points: Int
    let daysRemaining: Int
    var currentAmount: Double = 0
    var isCompleted: Bool = false

    var progress: Double {
        guard targetAmount > 0 else { return currentAmount == 0 ? 1 : 0 }
        return 1 - min(currentAmount / targetAmount, 1)
    }
}
