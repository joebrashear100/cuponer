//
//  AchievementsView.swift
//  Furg
//
//  Gamification achievements and streaks view
//

import SwiftUI

struct AchievementsView: View {
    @StateObject private var achievementsManager = AchievementsManager.shared
    @Environment(\.dismiss) var dismiss
    @State private var animate = false
    @State private var selectedCategory: AchievementCategory?
    @State private var showUnlockedOnly = false

    var filteredAchievements: [Achievement] {
        var result = achievementsManager.achievements

        if let category = selectedCategory {
            result = result.filter { $0.category == category }
        }

        if showUnlockedOnly {
            result = result.filter { $0.isUnlocked }
        }

        return result
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.furgCharcoal.ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 24) {
                        // Stats header
                        statsHeader
                            .offset(y: animate ? 0 : 20)
                            .opacity(animate ? 1 : 0)

                        // Current streak
                        streakCard
                            .offset(y: animate ? 0 : 20)
                            .opacity(animate ? 1 : 0)
                            .animation(.spring(response: 0.6).delay(0.1), value: animate)

                        // Weekly challenge
                        if let challenge = achievementsManager.weeklyChallenge {
                            weeklyChallengeCard(challenge)
                                .offset(y: animate ? 0 : 20)
                                .opacity(animate ? 1 : 0)
                                .animation(.spring(response: 0.6).delay(0.15), value: animate)
                        }

                        // Filter tabs
                        categoryFilter
                            .offset(y: animate ? 0 : 20)
                            .opacity(animate ? 1 : 0)
                            .animation(.spring(response: 0.6).delay(0.2), value: animate)

                        // Achievements grid
                        achievementsGrid
                            .offset(y: animate ? 0 : 20)
                            .opacity(animate ? 1 : 0)
                            .animation(.spring(response: 0.6).delay(0.25), value: animate)

                        Spacer(minLength: 40)
                    }
                    .padding(.horizontal, 20)
                }

                // Recent unlock overlay
                if let unlock = achievementsManager.recentUnlock {
                    achievementUnlockOverlay(unlock)
                }
            }
            .navigationTitle("Achievements")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                        .foregroundColor(.furgMint)
                }
            }
            .onAppear {
                withAnimation(.spring(response: 0.6)) {
                    animate = true
                }
            }
        }
    }

    // MARK: - Stats Header

    private var statsHeader: some View {
        HStack(spacing: 16) {
            // Level
            VStack(spacing: 8) {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [.furgMint, .furgSeafoam],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 60, height: 60)

                    Text("\(achievementsManager.level)")
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundColor(.furgCharcoal)
                }

                Text("Level")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.white.opacity(0.5))
            }

            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("\(achievementsManager.totalPoints)")
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundColor(.white)

                    Text("points")
                        .font(.system(size: 14))
                        .foregroundColor(.white.opacity(0.5))
                }

                // Progress to next level
                VStack(alignment: .leading, spacing: 4) {
                    GeometryReader { geometry in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color.white.opacity(0.1))

                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color.furgMint)
                                .frame(width: geometry.size.width * levelProgress)
                        }
                    }
                    .frame(height: 8)

                    Text("\(achievementsManager.pointsToNextLevel()) points to Level \(achievementsManager.level + 1)")
                        .font(.system(size: 10))
                        .foregroundColor(.white.opacity(0.4))
                }
            }

            Spacer()

            // Unlocked count
            VStack(spacing: 4) {
                Text("\(achievementsManager.unlockedAchievements.count)")
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundColor(.furgSuccess)

                Text("of \(achievementsManager.achievements.count)")
                    .font(.system(size: 11))
                    .foregroundColor(.white.opacity(0.4))

                Text("Unlocked")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(.white.opacity(0.5))
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color.white.opacity(0.1), lineWidth: 0.5)
                )
        )
    }

    private var levelProgress: Double {
        let thresholds = [0, 50, 150, 300, 500, 750, 1000, 1500, 2000, 3000, 5000]
        guard achievementsManager.level < thresholds.count else { return 1 }
        let currentThreshold = thresholds[achievementsManager.level - 1]
        let nextThreshold = thresholds[achievementsManager.level]
        let progress = Double(achievementsManager.totalPoints - currentThreshold) / Double(nextThreshold - currentThreshold)
        return min(max(progress, 0), 1)
    }

    // MARK: - Streak Card

    private var streakCard: some View {
        HStack(spacing: 20) {
            // Current streak
            VStack(spacing: 8) {
                HStack(spacing: 4) {
                    Image(systemName: "flame.fill")
                        .font(.system(size: 24))
                        .foregroundColor(.orange)

                    Text("\(achievementsManager.currentStreak.currentDays)")
                        .font(.system(size: 36, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                }

                Text("Day Streak")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.white.opacity(0.5))

                if achievementsManager.currentStreak.isActive {
                    Text("Active")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(.furgSuccess)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.furgSuccess.opacity(0.2))
                        .clipShape(Capsule())
                }
            }

            Divider()
                .frame(height: 60)
                .background(Color.white.opacity(0.2))

            // Best streak
            VStack(spacing: 8) {
                Text("\(achievementsManager.currentStreak.longestDays)")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundColor(.furgMint)

                Text("Best Streak")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.white.opacity(0.5))
            }

            Spacer()

            // Streak milestone
            VStack(alignment: .trailing, spacing: 4) {
                let nextMilestone = nextStreakMilestone()
                Text("\(nextMilestone - achievementsManager.currentStreak.currentDays)")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.white)

                Text("days to \(nextMilestone)-day")
                    .font(.system(size: 10))
                    .foregroundColor(.white.opacity(0.4))

                Text("milestone")
                    .font(.system(size: 10))
                    .foregroundColor(.white.opacity(0.4))
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color.orange.opacity(0.3), lineWidth: 1)
                )
        )
    }

    private func nextStreakMilestone() -> Int {
        let milestones = [7, 14, 30, 60, 100, 180, 365]
        let current = achievementsManager.currentStreak.currentDays
        return milestones.first { $0 > current } ?? 365
    }

    // MARK: - Weekly Challenge

    private func weeklyChallengeCard(_ challenge: WeeklyChallenge) -> some View {
        VStack(spacing: 16) {
            HStack {
                Image(systemName: "calendar.badge.clock")
                    .foregroundColor(.furgWarning)

                Text("Weekly Challenge")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white)

                Spacer()

                Text("\(challenge.daysRemaining) days left")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.furgWarning)
            }

            HStack(spacing: 16) {
                Image(systemName: challenge.icon)
                    .font(.system(size: 28))
                    .foregroundColor(.furgMint)
                    .frame(width: 50, height: 50)
                    .background(Color.furgMint.opacity(0.2))
                    .clipShape(RoundedRectangle(cornerRadius: 12))

                VStack(alignment: .leading, spacing: 6) {
                    Text(challenge.title)
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.white)

                    Text(challenge.description)
                        .font(.system(size: 13))
                        .foregroundColor(.white.opacity(0.6))
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 4) {
                    Text("+\(challenge.points)")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.furgMint)

                    Text("points")
                        .font(.system(size: 10))
                        .foregroundColor(.white.opacity(0.4))
                }
            }

            // Progress bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.white.opacity(0.1))

                    RoundedRectangle(cornerRadius: 4)
                        .fill(
                            LinearGradient(
                                colors: [.furgMint, .furgSeafoam],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: geometry.size.width * challenge.progress)
                }
            }
            .frame(height: 8)
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color.furgWarning.opacity(0.3), lineWidth: 1)
                )
        )
    }

    // MARK: - Category Filter

    private var categoryFilter: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                FilterChip(title: "All", isSelected: selectedCategory == nil) {
                    selectedCategory = nil
                }

                ForEach(AchievementCategory.allCases, id: \.self) { category in
                    FilterChip(title: category.rawValue, isSelected: selectedCategory == category) {
                        selectedCategory = category
                    }
                }

                Spacer()

                Button {
                    showUnlockedOnly.toggle()
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: showUnlockedOnly ? "checkmark.circle.fill" : "circle")
                        Text("Unlocked")
                    }
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(showUnlockedOnly ? .furgMint : .white.opacity(0.5))
                }
            }
        }
    }

    // MARK: - Achievements Grid

    private var achievementsGrid: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
            ForEach(filteredAchievements) { achievement in
                AchievementCard(achievement: achievement)
            }
        }
    }

    // MARK: - Unlock Overlay

    private func achievementUnlockOverlay(_ achievement: Achievement) -> some View {
        VStack(spacing: 20) {
            Spacer()

            VStack(spacing: 16) {
                // Glow effect
                ZStack {
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [achievement.tier.color.opacity(0.6), .clear],
                                center: .center,
                                startRadius: 0,
                                endRadius: 80
                            )
                        )
                        .frame(width: 160, height: 160)
                        .blur(radius: 30)

                    Image(systemName: achievement.icon)
                        .font(.system(size: 60))
                        .foregroundColor(achievement.tier.color)
                }

                Text("Achievement Unlocked!")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white.opacity(0.6))

                Text(achievement.name)
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(.white)

                Text(achievement.description)
                    .font(.system(size: 14))
                    .foregroundColor(.white.opacity(0.6))
                    .multilineTextAlignment(.center)

                HStack(spacing: 4) {
                    Text("+\(achievement.points)")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.furgMint)

                    Text("points")
                        .font(.system(size: 14))
                        .foregroundColor(.white.opacity(0.5))
                }
            }
            .padding(32)
            .background(
                RoundedRectangle(cornerRadius: 28)
                    .fill(.ultraThinMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: 28)
                            .stroke(achievement.tier.color.opacity(0.5), lineWidth: 2)
                    )
            )
            .padding(.horizontal, 40)

            Spacer()
        }
        .background(Color.black.opacity(0.7))
        .transition(.opacity)
    }
}

// MARK: - Supporting Views

struct FilterChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(isSelected ? .furgCharcoal : .white.opacity(0.7))
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(isSelected ? Color.furgMint : Color.white.opacity(0.1))
                .clipShape(Capsule())
        }
    }
}

struct AchievementCard: View {
    let achievement: Achievement

    var body: some View {
        VStack(spacing: 12) {
            // Icon
            ZStack {
                Circle()
                    .fill(achievement.isUnlocked ? achievement.tier.color.opacity(0.3) : Color.white.opacity(0.1))
                    .frame(width: 60, height: 60)

                Image(systemName: achievement.icon)
                    .font(.system(size: 24))
                    .foregroundColor(achievement.isUnlocked ? achievement.tier.color : .white.opacity(0.3))

                // Tier badge
                if achievement.isUnlocked {
                    Circle()
                        .fill(achievement.tier.color)
                        .frame(width: 16, height: 16)
                        .overlay(
                            Image(systemName: "checkmark")
                                .font(.system(size: 8, weight: .bold))
                                .foregroundColor(.white)
                        )
                        .offset(x: 22, y: -22)
                }
            }

            VStack(spacing: 4) {
                Text(achievement.name)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(achievement.isUnlocked ? .white : .white.opacity(0.5))
                    .multilineTextAlignment(.center)
                    .lineLimit(2)

                if !achievement.isUnlocked {
                    // Progress bar
                    GeometryReader { geometry in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 2)
                                .fill(Color.white.opacity(0.1))

                            RoundedRectangle(cornerRadius: 2)
                                .fill(Color.furgMint.opacity(0.5))
                                .frame(width: geometry.size.width * achievement.progressPercentage)
                        }
                    }
                    .frame(height: 4)
                    .padding(.horizontal, 8)
                }

                HStack(spacing: 4) {
                    Text("+\(achievement.points)")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(achievement.isUnlocked ? .furgMint : .white.opacity(0.3))

                    Text("pts")
                        .font(.system(size: 10))
                        .foregroundColor(.white.opacity(0.3))
                }
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(
                            achievement.isUnlocked ? achievement.tier.color.opacity(0.4) : Color.white.opacity(0.1),
                            lineWidth: achievement.isUnlocked ? 1.5 : 0.5
                        )
                )
        )
        .opacity(achievement.isUnlocked ? 1 : 0.7)
    }
}

// MARK: - Preview

#Preview {
    AchievementsView()
}
