//
//  HealthKitManager.swift
//  Furg
//
//  HealthKit integration for correlating health data with spending patterns
//

import Foundation
import HealthKit
import SwiftUI

@MainActor
class HealthKitManager: ObservableObject {
    static let shared = HealthKitManager()

    private let healthStore = HKHealthStore()

    @Published var isAuthorized = false
    @Published var stepCount: Int = 0
    @Published var activeCalories: Double = 0
    @Published var workoutMinutes: Int = 0
    @Published var sleepHours: Double = 0
    @Published var mindfulMinutes: Int = 0
    @Published var healthScore: Int = 75 // 0-100 score

    // Spending correlations
    @Published var fitnessSpendingEfficiency: Double = 0 // Cost per workout
    @Published var healthyFoodPercentage: Double = 0

    private init() {}

    var isHealthDataAvailable: Bool {
        HKHealthStore.isHealthDataAvailable()
    }

    // MARK: - Authorization

    func requestAuthorization() async -> Bool {
        guard isHealthDataAvailable else { return false }

        let typesToRead: Set<HKObjectType> = [
            HKObjectType.quantityType(forIdentifier: .stepCount)!,
            HKObjectType.quantityType(forIdentifier: .activeEnergyBurned)!,
            HKObjectType.quantityType(forIdentifier: .appleExerciseTime)!,
            HKObjectType.categoryType(forIdentifier: .sleepAnalysis)!,
            HKObjectType.categoryType(forIdentifier: .mindfulSession)!,
            HKObjectType.workoutType()
        ]

        do {
            try await healthStore.requestAuthorization(toShare: [], read: typesToRead)
            isAuthorized = true
            await fetchAllHealthData()
            return true
        } catch {
            print("HealthKit authorization failed: \(error)")
            return false
        }
    }

    // MARK: - Data Fetching

    func fetchAllHealthData() async {
        await withTaskGroup(of: Void.self) { group in
            group.addTask { await self.fetchStepCount() }
            group.addTask { await self.fetchActiveCalories() }
            group.addTask { await self.fetchWorkoutMinutes() }
            group.addTask { await self.fetchSleepHours() }
            group.addTask { await self.fetchMindfulMinutes() }
        }
        calculateHealthScore()
    }

    private func fetchStepCount() async {
        guard let stepType = HKQuantityType.quantityType(forIdentifier: .stepCount) else { return }

        let now = Date()
        let startOfDay = Calendar.current.startOfDay(for: now)
        let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: now)

        do {
            let result = try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Double, Error>) in
                let query = HKStatisticsQuery(quantityType: stepType, quantitySamplePredicate: predicate, options: .cumulativeSum) { _, statistics, error in
                    if let error = error {
                        continuation.resume(throwing: error)
                        return
                    }
                    let sum = statistics?.sumQuantity()?.doubleValue(for: .count()) ?? 0
                    continuation.resume(returning: sum)
                }
                healthStore.execute(query)
            }
            stepCount = Int(result)
        } catch {
            print("Error fetching step count: \(error)")
        }
    }

    private func fetchActiveCalories() async {
        guard let calorieType = HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned) else { return }

        let now = Date()
        let startOfDay = Calendar.current.startOfDay(for: now)
        let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: now)

        do {
            let result = try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Double, Error>) in
                let query = HKStatisticsQuery(quantityType: calorieType, quantitySamplePredicate: predicate, options: .cumulativeSum) { _, statistics, error in
                    if let error = error {
                        continuation.resume(throwing: error)
                        return
                    }
                    let sum = statistics?.sumQuantity()?.doubleValue(for: .kilocalorie()) ?? 0
                    continuation.resume(returning: sum)
                }
                healthStore.execute(query)
            }
            activeCalories = result
        } catch {
            print("Error fetching calories: \(error)")
        }
    }

    private func fetchWorkoutMinutes() async {
        guard let exerciseType = HKQuantityType.quantityType(forIdentifier: .appleExerciseTime) else { return }

        let now = Date()
        let weekAgo = Calendar.current.date(byAdding: .day, value: -7, to: now)!
        let predicate = HKQuery.predicateForSamples(withStart: weekAgo, end: now)

        do {
            let result = try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Double, Error>) in
                let query = HKStatisticsQuery(quantityType: exerciseType, quantitySamplePredicate: predicate, options: .cumulativeSum) { _, statistics, error in
                    if let error = error {
                        continuation.resume(throwing: error)
                        return
                    }
                    let sum = statistics?.sumQuantity()?.doubleValue(for: .minute()) ?? 0
                    continuation.resume(returning: sum)
                }
                healthStore.execute(query)
            }
            workoutMinutes = Int(result)
        } catch {
            print("Error fetching workout minutes: \(error)")
        }
    }

    private func fetchSleepHours() async {
        guard let sleepType = HKCategoryType.categoryType(forIdentifier: .sleepAnalysis) else { return }

        let now = Date()
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: now)!
        let predicate = HKQuery.predicateForSamples(withStart: yesterday, end: now)

        do {
            let samples = try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<[HKCategorySample], Error>) in
                let query = HKSampleQuery(sampleType: sleepType, predicate: predicate, limit: HKObjectQueryNoLimit, sortDescriptors: nil) { _, samples, error in
                    if let error = error {
                        continuation.resume(throwing: error)
                        return
                    }
                    continuation.resume(returning: (samples as? [HKCategorySample]) ?? [])
                }
                healthStore.execute(query)
            }

            let totalSleep = samples
                .filter { $0.value == HKCategoryValueSleepAnalysis.asleepUnspecified.rawValue ||
                         $0.value == HKCategoryValueSleepAnalysis.asleepCore.rawValue ||
                         $0.value == HKCategoryValueSleepAnalysis.asleepDeep.rawValue ||
                         $0.value == HKCategoryValueSleepAnalysis.asleepREM.rawValue }
                .reduce(0.0) { $0 + $1.endDate.timeIntervalSince($1.startDate) }

            sleepHours = totalSleep / 3600
        } catch {
            print("Error fetching sleep: \(error)")
        }
    }

    private func fetchMindfulMinutes() async {
        guard let mindfulType = HKCategoryType.categoryType(forIdentifier: .mindfulSession) else { return }

        let now = Date()
        let weekAgo = Calendar.current.date(byAdding: .day, value: -7, to: now)!
        let predicate = HKQuery.predicateForSamples(withStart: weekAgo, end: now)

        do {
            let samples = try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<[HKCategorySample], Error>) in
                let query = HKSampleQuery(sampleType: mindfulType, predicate: predicate, limit: HKObjectQueryNoLimit, sortDescriptors: nil) { _, samples, error in
                    if let error = error {
                        continuation.resume(throwing: error)
                        return
                    }
                    continuation.resume(returning: (samples as? [HKCategorySample]) ?? [])
                }
                healthStore.execute(query)
            }

            let totalMinutes = samples.reduce(0.0) { $0 + $1.endDate.timeIntervalSince($1.startDate) / 60 }
            mindfulMinutes = Int(totalMinutes)
        } catch {
            print("Error fetching mindful minutes: \(error)")
        }
    }

    // MARK: - Health Score Calculation

    private func calculateHealthScore() {
        var score = 0

        // Steps (max 25 points for 10,000+ steps)
        score += min(25, Int(Double(stepCount) / 10000 * 25))

        // Active calories (max 25 points for 500+ cal)
        score += min(25, Int(activeCalories / 500 * 25))

        // Sleep (max 25 points for 7-9 hours)
        if sleepHours >= 7 && sleepHours <= 9 {
            score += 25
        } else if sleepHours >= 6 && sleepHours <= 10 {
            score += 15
        } else {
            score += 5
        }

        // Workout minutes (max 25 points for 150+ min/week)
        score += min(25, Int(Double(workoutMinutes) / 150 * 25))

        healthScore = score
    }

    // MARK: - Spending Correlations

    func calculateFitnessSpendingEfficiency(gymCost: Double, workoutsThisMonth: Int) {
        guard workoutsThisMonth > 0 else {
            fitnessSpendingEfficiency = gymCost
            return
        }
        fitnessSpendingEfficiency = gymCost / Double(workoutsThisMonth)
    }

    // MARK: - Health Insights

    func getHealthInsights() -> [HealthInsight] {
        var insights: [HealthInsight] = []

        if stepCount < 5000 {
            insights.append(HealthInsight(
                type: .warning,
                title: "Get Moving!",
                message: "You've only taken \(stepCount) steps today. Walking more could reduce your transportation spending.",
                icon: "figure.walk"
            ))
        }

        if sleepHours < 6 {
            insights.append(HealthInsight(
                type: .alert,
                title: "Sleep Deficit",
                message: "Poor sleep is linked to impulse spending. Try to get 7-9 hours tonight.",
                icon: "moon.zzz.fill"
            ))
        }

        if workoutMinutes >= 150 {
            insights.append(HealthInsight(
                type: .success,
                title: "Fitness Goal Met!",
                message: "You've hit 150+ workout minutes this week. Your gym membership is paying off!",
                icon: "figure.run"
            ))
        }

        if healthScore >= 80 {
            insights.append(HealthInsight(
                type: .success,
                title: "Excellent Health Score",
                message: "Your health score of \(healthScore) is great! Healthy habits often lead to better financial habits.",
                icon: "heart.fill"
            ))
        }

        return insights
    }
}

// MARK: - Health Insight Model

struct HealthInsight: Identifiable {
    let id = UUID()
    let type: InsightType
    let title: String
    let message: String
    let icon: String

    enum InsightType {
        case success, warning, alert, info

        var color: Color {
            switch self {
            case .success: return .furgSuccess
            case .warning: return .furgWarning
            case .alert: return .furgDanger
            case .info: return .furgInfo
            }
        }
    }
}
