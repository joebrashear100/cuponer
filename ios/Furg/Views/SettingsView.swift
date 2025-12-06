//
//  SettingsView.swift
//  Furg
//
//  Modern glassmorphism settings view with all features
//

import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var authManager: AuthManager
    @EnvironmentObject var plaidManager: PlaidManager
    @EnvironmentObject var roundUpManager: RoundUpManager
    @State private var profile: UserProfile?
    @State private var showSignOutAlert = false
    @State private var showIntensitySheet = false
    @State private var showBufferSheet = false
    @State private var showRoundUpSettings = false
    @State private var showForecast = false
    @State private var showNotificationSettings = false
    @State private var showWishlist = false
    @State private var showSpendingLimits = false
    @State private var animate = false

    private let apiClient = APIClient()

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 24) {
                // Header
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("App")
                            .font(.furgBody)
                            .foregroundColor(.white.opacity(0.6))
                        Text("Settings")
                            .font(.furgLargeTitle)
                            .foregroundColor(.white)
                    }
                    Spacer()
                }
                .padding(.top, 60)

                // Profile card
                ProfileCard(profile: profile)
                    .offset(y: animate ? 0 : 20)
                    .opacity(animate ? 1 : 0)
                    .animation(.easeOut(duration: 0.5).delay(0.1), value: animate)

                // FURG Settings
                VStack(spacing: 16) {
                    SettingsSection(title: "FURG PERSONALITY") {
                        Button {
                            showIntensitySheet = true
                        } label: {
                            SettingsRow(
                                icon: "flame.fill",
                                title: "Intensity Mode",
                                value: profile?.intensityMode?.capitalized ?? "Moderate",
                                color: .furgWarning,
                                showChevron: true
                            )
                        }
                        .buttonStyle(.plain)

                        Divider().background(Color.white.opacity(0.1))

                        Button {
                            showBufferSheet = true
                        } label: {
                            SettingsRow(
                                icon: "shield.fill",
                                title: "Emergency Buffer",
                                value: profile?.emergencyBuffer != nil ? "$\(Int(profile!.emergencyBuffer!))" : "$500",
                                color: .furgSuccess,
                                showChevron: true
                            )
                        }
                        .buttonStyle(.plain)
                    }
                    .offset(y: animate ? 0 : 20)
                    .opacity(animate ? 1 : 0)
                    .animation(.easeOut(duration: 0.5).delay(0.2), value: animate)

                    // Automation Settings
                    SettingsSection(title: "AUTOMATION") {
                        Button {
                            showRoundUpSettings = true
                        } label: {
                            HStack(spacing: 14) {
                                ZStack {
                                    Circle()
                                        .fill(Color.furgMint.opacity(0.15))
                                        .frame(width: 36, height: 36)
                                    Image(systemName: "arrow.up.circle.fill")
                                        .font(.system(size: 14, weight: .semibold))
                                        .foregroundColor(.furgMint)
                                }

                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Round-Up Investing")
                                        .font(.furgBody)
                                        .foregroundColor(.white)
                                    Text(roundUpManager.config.enabled ? "Enabled" : "Disabled")
                                        .font(.furgCaption)
                                        .foregroundColor(roundUpManager.config.enabled ? .furgMint : .white.opacity(0.4))
                                }

                                Spacer()

                                Image(systemName: "chevron.right")
                                    .font(.caption)
                                    .foregroundColor(.white.opacity(0.3))
                            }
                            .padding(16)
                        }
                        .buttonStyle(.plain)

                        Divider().background(Color.white.opacity(0.1))

                        Button {
                            showForecast = true
                        } label: {
                            SettingsRow(
                                icon: "chart.line.uptrend.xyaxis",
                                title: "Cash Flow Forecast",
                                value: "View",
                                color: .furgInfo,
                                showChevron: true
                            )
                        }
                        .buttonStyle(.plain)

                        Divider().background(Color.white.opacity(0.1))

                        Button {
                            showNotificationSettings = true
                        } label: {
                            SettingsRow(
                                icon: "bell.fill",
                                title: "Notifications",
                                value: "Customize",
                                color: .furgWarning,
                                showChevron: true
                            )
                        }
                        .buttonStyle(.plain)
                    }
                    .offset(y: animate ? 0 : 20)
                    .opacity(animate ? 1 : 0)
                    .animation(.easeOut(duration: 0.5).delay(0.25), value: animate)

                    // Tools & Features
                    SettingsSection(title: "TOOLS & FEATURES") {
                        Button {
                            showWishlist = true
                        } label: {
                            SettingsRow(
                                icon: "heart.fill",
                                title: "Wishlist",
                                value: "Plan purchases",
                                color: .pink,
                                showChevron: true
                            )
                        }
                        .buttonStyle(.plain)

                        Divider().background(Color.white.opacity(0.1))

                        Button {
                            showSpendingLimits = true
                        } label: {
                            SettingsRow(
                                icon: "gauge.with.needle.fill",
                                title: "Spending Limits",
                                value: "Set budgets",
                                color: .furgWarning,
                                showChevron: true
                            )
                        }
                        .buttonStyle(.plain)
                    }
                    .offset(y: animate ? 0 : 20)
                    .opacity(animate ? 1 : 0)
                    .animation(.easeOut(duration: 0.5).delay(0.27), value: animate)

                    // Connected banks
                    SettingsSection(title: "CONNECTED BANKS") {
                        if plaidManager.linkedBanks.isEmpty {
                            Button {
                                Task { await plaidManager.presentPlaidLink() }
                            } label: {
                                HStack {
                                    ZStack {
                                        Circle()
                                            .fill(Color.furgMint.opacity(0.15))
                                            .frame(width: 40, height: 40)
                                        Image(systemName: "plus")
                                            .foregroundColor(.furgMint)
                                    }

                                    Text("Connect Your Bank")
                                        .font(.furgBody)
                                        .foregroundColor(.white)

                                    Spacer()

                                    Image(systemName: "chevron.right")
                                        .foregroundColor(.white.opacity(0.3))
                                }
                                .padding(16)
                            }
                            .buttonStyle(.plain)
                        } else {
                            ForEach(plaidManager.linkedBanks) { bank in
                                HStack {
                                    ZStack {
                                        Circle()
                                            .fill(Color.furgSeafoam.opacity(0.15))
                                            .frame(width: 40, height: 40)
                                        Image(systemName: "building.columns.fill")
                                            .foregroundColor(.furgSeafoam)
                                    }

                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(bank.name)
                                            .font(.furgBody)
                                            .foregroundColor(.white)
                                        Text("Synced \(bank.lastSynced, style: .relative) ago")
                                            .font(.furgCaption)
                                            .foregroundColor(.white.opacity(0.4))
                                    }

                                    Spacer()

                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(.furgSuccess)
                                }
                                .padding(16)
                            }

                            HStack(spacing: 12) {
                                Button {
                                    Task { await plaidManager.presentPlaidLink() }
                                } label: {
                                    Text("Add Bank")
                                        .font(.furgCaption)
                                        .foregroundColor(.white.opacity(0.7))
                                        .padding(.horizontal, 16)
                                        .padding(.vertical, 10)
                                        .background(Color.white.opacity(0.1))
                                        .clipShape(Capsule())
                                }

                                Button {
                                    Task { await plaidManager.syncBanks() }
                                } label: {
                                    Text("Sync All")
                                        .font(.furgCaption)
                                        .foregroundColor(.furgCharcoal)
                                        .padding(.horizontal, 16)
                                        .padding(.vertical, 10)
                                        .background(Color.furgMint)
                                        .clipShape(Capsule())
                                }
                            }
                            .padding(.horizontal, 16)
                            .padding(.bottom, 16)
                        }
                    }
                    .offset(y: animate ? 0 : 20)
                    .opacity(animate ? 1 : 0)
                    .animation(.easeOut(duration: 0.5).delay(0.3), value: animate)

                    // About section
                    SettingsSection(title: "ABOUT") {
                        SettingsRow(
                            icon: "info.circle.fill",
                            title: "Version",
                            value: "1.0.0",
                            color: .furgInfo
                        )

                        Divider().background(Color.white.opacity(0.1))

                        SettingsRow(
                            icon: "lock.shield.fill",
                            title: "Privacy Policy",
                            value: "",
                            color: .white.opacity(0.5),
                            showChevron: true
                        )

                        Divider().background(Color.white.opacity(0.1))

                        SettingsRow(
                            icon: "doc.text.fill",
                            title: "Terms of Service",
                            value: "",
                            color: .white.opacity(0.5),
                            showChevron: true
                        )

                        Divider().background(Color.white.opacity(0.1))

                        SettingsRow(
                            icon: "questionmark.circle.fill",
                            title: "Help & Support",
                            value: "",
                            color: .white.opacity(0.5),
                            showChevron: true
                        )
                    }
                    .offset(y: animate ? 0 : 20)
                    .opacity(animate ? 1 : 0)
                    .animation(.easeOut(duration: 0.5).delay(0.4), value: animate)

                    // Sign out button
                    Button {
                        showSignOutAlert = true
                    } label: {
                        HStack {
                            Image(systemName: "rectangle.portrait.and.arrow.right")
                            Text("Sign Out")
                        }
                        .font(.furgHeadline)
                        .foregroundColor(.furgDanger)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Color.furgDanger.opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(Color.furgDanger.opacity(0.3), lineWidth: 1)
                        )
                    }
                    .offset(y: animate ? 0 : 20)
                    .opacity(animate ? 1 : 0)
                    .animation(.easeOut(duration: 0.5).delay(0.5), value: animate)
                }

                Spacer(minLength: 120)
            }
            .padding(.horizontal, 20)
        }
        .task {
            await loadProfile()
            await roundUpManager.loadConfig()
        }
        .onAppear {
            withAnimation { animate = true }
        }
        .alert("Sign Out", isPresented: $showSignOutAlert) {
            Button("Cancel", role: .cancel) {}
            Button("Sign Out", role: .destructive) {
                authManager.signOut()
            }
        } message: {
            Text("Are you sure you want to sign out?")
        }
        .sheet(isPresented: $showIntensitySheet) {
            IntensityModeSheet(currentMode: profile?.intensityMode ?? "moderate") { newMode in
                Task {
                    await updateIntensityMode(newMode)
                }
            }
        }
        .sheet(isPresented: $showBufferSheet) {
            EmergencyBufferSheet(currentBuffer: profile?.emergencyBuffer ?? 500) { newBuffer in
                Task {
                    await updateEmergencyBuffer(newBuffer)
                }
            }
        }
        .sheet(isPresented: $showRoundUpSettings) {
            RoundUpSettingsView()
                .environmentObject(roundUpManager)
                .environmentObject(GoalsManager())
        }
        .sheet(isPresented: $showForecast) {
            ForecastView()
                .environmentObject(ForecastingManager())
        }
        .sheet(isPresented: $showNotificationSettings) {
            NotificationSettingsSheet()
        }
        .sheet(isPresented: $showWishlist) {
            NavigationStack {
                ZStack {
                    AnimatedMeshBackground()
                    WishlistView()
                }
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Done") {
                            showWishlist = false
                        }
                        .foregroundColor(.white.opacity(0.7))
                    }
                }
            }
            .environmentObject(WishlistManager())
        }
        .sheet(isPresented: $showSpendingLimits) {
            NavigationStack {
                SpendingLimitsView()
            }
            .environmentObject(SpendingLimitsManager())
        }
    }

    private func loadProfile() async {
        do {
            profile = try await apiClient.getProfile()
        } catch {
            print("Failed to load profile: \(error)")
        }
    }

    private func updateIntensityMode(_ mode: String) async {
        do {
            try await apiClient.updateProfile(["intensity_mode": mode])
            profile?.intensityMode = mode
        } catch {
            print("Failed to update intensity mode: \(error)")
        }
    }

    private func updateEmergencyBuffer(_ buffer: Double) async {
        do {
            try await apiClient.updateProfile(["emergency_buffer": buffer])
            profile?.emergencyBuffer = buffer
        } catch {
            print("Failed to update emergency buffer: \(error)")
        }
    }
}

// MARK: - Profile Card

struct ProfileCard: View {
    let profile: UserProfile?

    var body: some View {
        HStack(spacing: 16) {
            // Avatar
            ZStack {
                Circle()
                    .fill(FurgGradients.mintGradient)
                    .frame(width: 60, height: 60)

                Text(initials)
                    .font(.furgTitle2)
                    .foregroundColor(.furgCharcoal)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(profile?.name ?? "User")
                    .font(.furgHeadline)
                    .foregroundColor(.white)

                if let location = profile?.location {
                    HStack(spacing: 4) {
                        Image(systemName: "location.fill")
                            .font(.caption2)
                        Text(location)
                            .font(.furgCaption)
                    }
                    .foregroundColor(.white.opacity(0.5))
                }

                if let employer = profile?.employer {
                    HStack(spacing: 4) {
                        Image(systemName: "building.2.fill")
                            .font(.caption2)
                        Text(employer)
                            .font(.furgCaption)
                    }
                    .foregroundColor(.white.opacity(0.5))
                }
            }

            Spacer()

            Image(systemName: "pencil")
                .foregroundColor(.furgMint)
                .padding(10)
                .background(Color.furgMint.opacity(0.15))
                .clipShape(Circle())
        }
        .padding(20)
        .glassCard()
    }

    var initials: String {
        guard let name = profile?.name else { return "?" }
        let parts = name.split(separator: " ")
        let first = parts.first?.first.map(String.init) ?? ""
        let last = parts.count > 1 ? parts.last?.first.map(String.init) ?? "" : ""
        return (first + last).uppercased()
    }
}

// MARK: - Settings Section

struct SettingsSection<Content: View>: View {
    let title: String
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(title)
                .font(.furgCaption)
                .foregroundColor(.white.opacity(0.4))
                .tracking(1)
                .padding(.horizontal, 4)
                .padding(.bottom, 12)

            VStack(spacing: 0) {
                content
            }
            .glassCard(cornerRadius: 20, opacity: 0.08)
        }
    }
}

// MARK: - Settings Row

struct SettingsRow: View {
    let icon: String
    let title: String
    let value: String
    let color: Color
    var showChevron: Bool = false

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.15))
                    .frame(width: 36, height: 36)

                Image(systemName: icon)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(color)
            }

            Text(title)
                .font(.furgBody)
                .foregroundColor(.white)

            Spacer()

            if !value.isEmpty {
                Text(value)
                    .font(.furgBody)
                    .foregroundColor(.white.opacity(0.4))
            }

            if showChevron {
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.3))
            }
        }
        .padding(16)
    }
}

// MARK: - Intensity Mode Sheet

struct IntensityModeSheet: View {
    let currentMode: String
    let onSelect: (String) -> Void
    @Environment(\.dismiss) var dismiss

    let modes = [
        ("mild", "Mild", "Gentle nudges, minimal roasting", "leaf.fill"),
        ("moderate", "Moderate", "Balanced roasting and encouragement", "flame.fill"),
        ("insanity", "Insanity", "Maximum roasting, no mercy", "bolt.fill")
    ]

    var body: some View {
        ZStack {
            AnimatedMeshBackground()

            VStack(spacing: 24) {
                HStack {
                    Button { dismiss() } label: {
                        Image(systemName: "xmark")
                            .font(.title3)
                            .foregroundColor(.white.opacity(0.7))
                            .padding(12)
                            .glassCard(cornerRadius: 12, opacity: 0.1)
                    }
                    Spacer()
                    Text("Intensity Mode")
                        .font(.furgTitle2)
                        .foregroundColor(.white)
                    Spacer()
                    Color.clear.frame(width: 44)
                }
                .padding(.top, 20)

                Text("How hard should FURG roast you?")
                    .font(.furgBody)
                    .foregroundColor(.white.opacity(0.6))

                VStack(spacing: 12) {
                    ForEach(modes, id: \.0) { mode in
                        Button {
                            onSelect(mode.0)
                            dismiss()
                        } label: {
                            HStack(spacing: 16) {
                                ZStack {
                                    Circle()
                                        .fill(modeColor(mode.0).opacity(0.2))
                                        .frame(width: 48, height: 48)

                                    Image(systemName: mode.3)
                                        .font(.title3)
                                        .foregroundColor(modeColor(mode.0))
                                }

                                VStack(alignment: .leading, spacing: 4) {
                                    Text(mode.1)
                                        .font(.furgHeadline)
                                        .foregroundColor(.white)

                                    Text(mode.2)
                                        .font(.furgCaption)
                                        .foregroundColor(.white.opacity(0.5))
                                }

                                Spacer()

                                if currentMode == mode.0 {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(.furgMint)
                                }
                            }
                            .padding(16)
                            .background(currentMode == mode.0 ? Color.furgMint.opacity(0.1) : Color.white.opacity(0.05))
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                        }
                    }
                }

                Spacer()
            }
            .padding(.horizontal, 20)
        }
    }

    func modeColor(_ mode: String) -> Color {
        switch mode {
        case "mild": return .furgSuccess
        case "moderate": return .furgWarning
        case "insanity": return .furgError
        default: return .furgMint
        }
    }
}

// MARK: - Emergency Buffer Sheet

struct EmergencyBufferSheet: View {
    let currentBuffer: Double
    let onSave: (Double) -> Void
    @Environment(\.dismiss) var dismiss
    @State private var bufferAmount: String

    init(currentBuffer: Double, onSave: @escaping (Double) -> Void) {
        self.currentBuffer = currentBuffer
        self.onSave = onSave
        self._bufferAmount = State(initialValue: String(Int(currentBuffer)))
    }

    var body: some View {
        ZStack {
            AnimatedMeshBackground()

            VStack(spacing: 24) {
                HStack {
                    Button { dismiss() } label: {
                        Image(systemName: "xmark")
                            .font(.title3)
                            .foregroundColor(.white.opacity(0.7))
                            .padding(12)
                            .glassCard(cornerRadius: 12, opacity: 0.1)
                    }
                    Spacer()
                    Text("Emergency Buffer")
                        .font(.furgTitle2)
                        .foregroundColor(.white)
                    Spacer()
                    Color.clear.frame(width: 44)
                }
                .padding(.top, 20)

                VStack(spacing: 8) {
                    Text("PROTECTED AMOUNT")
                        .font(.furgCaption)
                        .foregroundColor(.white.opacity(0.5))
                        .tracking(2)

                    HStack(alignment: .center, spacing: 4) {
                        Text("$")
                            .font(.system(size: 32, weight: .medium, design: .rounded))
                            .foregroundColor(.furgMint)

                        TextField("500", text: $bufferAmount)
                            .font(.system(size: 48, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.center)
                            .frame(maxWidth: 180)
                    }
                }
                .padding(24)
                .glassCard()

                Text("FURG will never let you spend this safety cushion. This money is protected from your spending urges.")
                    .font(.furgCaption)
                    .foregroundColor(.white.opacity(0.6))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 20)

                // Quick amounts
                HStack(spacing: 12) {
                    ForEach([250, 500, 1000, 2000], id: \.self) { amount in
                        Button {
                            bufferAmount = String(amount)
                        } label: {
                            Text("$\(amount)")
                                .font(.furgCaption)
                                .foregroundColor(bufferAmount == String(amount) ? .furgCharcoal : .white.opacity(0.7))
                                .padding(.horizontal, 16)
                                .padding(.vertical, 10)
                                .background(bufferAmount == String(amount) ? Color.furgMint : Color.white.opacity(0.1))
                                .clipShape(Capsule())
                        }
                    }
                }

                Spacer()

                Button {
                    if let amount = Double(bufferAmount), amount > 0 {
                        onSave(amount)
                        dismiss()
                    }
                } label: {
                    HStack {
                        Image(systemName: "shield.fill")
                        Text("Set Buffer")
                    }
                    .font(.furgHeadline)
                    .foregroundColor(.furgCharcoal)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 18)
                    .background(FurgGradients.mintGradient)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                }
                .padding(.bottom, 20)
            }
            .padding(.horizontal, 20)
        }
    }
}

// MARK: - Notification Settings Sheet

struct NotificationSettingsSheet: View {
    @Environment(\.dismiss) var dismiss
    @State private var spendingAlerts = true
    @State private var billReminders = true
    @State private var goalMilestones = true
    @State private var dailySummary = false
    @State private var weeklyReport = true
    @State private var roastNotifications = true

    var body: some View {
        ZStack {
            AnimatedMeshBackground()

            VStack(spacing: 24) {
                HStack {
                    Button { dismiss() } label: {
                        Image(systemName: "xmark")
                            .font(.title3)
                            .foregroundColor(.white.opacity(0.7))
                            .padding(12)
                            .glassCard(cornerRadius: 12, opacity: 0.1)
                    }
                    Spacer()
                    Text("Notifications")
                        .font(.furgTitle2)
                        .foregroundColor(.white)
                    Spacer()
                    Color.clear.frame(width: 44)
                }
                .padding(.top, 20)

                ScrollView {
                    VStack(spacing: 16) {
                        NotificationToggle(
                            title: "Spending Alerts",
                            description: "Get roasted when you overspend",
                            icon: "exclamationmark.triangle.fill",
                            color: .furgWarning,
                            isOn: $spendingAlerts
                        )

                        NotificationToggle(
                            title: "Bill Reminders",
                            description: "Never miss a payment",
                            icon: "calendar.badge.exclamationmark",
                            color: .furgInfo,
                            isOn: $billReminders
                        )

                        NotificationToggle(
                            title: "Goal Milestones",
                            description: "Celebrate your progress",
                            icon: "star.fill",
                            color: .furgMint,
                            isOn: $goalMilestones
                        )

                        NotificationToggle(
                            title: "Daily Summary",
                            description: "Morning spending recap",
                            icon: "sun.max.fill",
                            color: .orange,
                            isOn: $dailySummary
                        )

                        NotificationToggle(
                            title: "Weekly Report",
                            description: "Sunday financial check-in",
                            icon: "chart.bar.fill",
                            color: .purple,
                            isOn: $weeklyReport
                        )

                        NotificationToggle(
                            title: "FURG Roasts",
                            description: "Random motivational burns",
                            icon: "flame.fill",
                            color: .furgError,
                            isOn: $roastNotifications
                        )
                    }
                }

                Spacer()
            }
            .padding(.horizontal, 20)
        }
    }
}

struct NotificationToggle: View {
    let title: String
    let description: String
    let icon: String
    let color: Color
    @Binding var isOn: Bool

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.2))
                    .frame(width: 40, height: 40)

                Image(systemName: icon)
                    .font(.body)
                    .foregroundColor(color)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.furgBody)
                    .foregroundColor(.white)

                Text(description)
                    .font(.furgCaption)
                    .foregroundColor(.white.opacity(0.5))
            }

            Spacer()

            Toggle("", isOn: $isOn)
                .labelsHidden()
                .tint(.furgMint)
        }
        .padding(14)
        .glassCard(cornerRadius: 14, opacity: 0.08)
    }
}

#Preview {
    ZStack {
        AnimatedMeshBackground()
        SettingsView()
    }
    .environmentObject(AuthManager())
    .environmentObject(PlaidManager())
    .environmentObject(RoundUpManager())
}
