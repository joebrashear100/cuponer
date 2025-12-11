//
//  SettingsViewV2.swift
//  Furg
//
//  Complete settings with all configuration options
//

import SwiftUI

struct SettingsViewV2: View {
    @Environment(\.dismiss) var dismiss
    @AppStorage("notificationsEnabled") private var notificationsEnabled = true
    @AppStorage("biometricEnabled") private var biometricEnabled = false
    @AppStorage("roundUpEnabled") private var roundUpEnabled = false
    @AppStorage("weeklyReportEnabled") private var weeklyReportEnabled = true
    @AppStorage("budgetAlertsEnabled") private var budgetAlertsEnabled = true

    @State private var showConnectBank = false
    @State private var showExportData = false
    @State private var showDeleteConfirm = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Profile Section
                    profileSection

                    // Connected Accounts
                    accountsSection

                    // Features
                    featuresSection

                    // Notifications
                    notificationsSection

                    // Security
                    securitySection

                    // Data & Privacy
                    dataSection

                    // About
                    aboutSection

                    // Danger Zone
                    dangerSection
                }
                .padding(20)
            }
            .background(Color.v2Background)
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                        .foregroundColor(.v2Primary)
                }
            }
            .sheet(isPresented: $showConnectBank) {
                ConnectBankViewV2()
                    .presentationBackground(Color.v2Background)
            }
        }
    }

    // MARK: - Profile Section

    var profileSection: some View {
        V2Card {
            HStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(V2Gradients.primary)
                        .frame(width: 64, height: 64)

                    Text("JB")
                        .font(.v2Title)
                        .foregroundColor(.v2TextInverse)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text("Joe Brashear")
                        .font(.v2Headline)
                        .foregroundColor(.v2TextPrimary)

                    Text("joe@example.com")
                        .font(.v2Caption)
                        .foregroundColor(.v2TextSecondary)

                    HStack(spacing: 4) {
                        Image(systemName: "crown.fill")
                            .font(.system(size: 10))
                        Text("Premium Member")
                            .font(.v2CaptionSmall)
                    }
                    .foregroundColor(.v2Premium)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .foregroundColor(.v2TextTertiary)
            }
        }
    }

    // MARK: - Accounts Section

    var accountsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Connected Accounts")
                .font(.v2Caption)
                .foregroundColor(.v2TextSecondary)
                .padding(.leading, 4)

            V2Card(padding: 0) {
                VStack(spacing: 0) {
                    ConnectedAccountRow(
                        icon: "building.columns.fill",
                        name: "Chase Bank",
                        detail: "Checking •••• 4521",
                        color: .v2Info
                    )

                    Divider().background(Color.white.opacity(0.06))

                    ConnectedAccountRow(
                        icon: "creditcard.fill",
                        name: "Apple Card",
                        detail: "Credit •••• 8832",
                        color: .v2TextPrimary
                    )

                    Divider().background(Color.white.opacity(0.06))

                    Button {
                        showConnectBank = true
                    } label: {
                        HStack {
                            Image(systemName: "plus.circle.fill")
                                .foregroundColor(.v2Primary)
                            Text("Add Account")
                                .font(.v2Body)
                                .foregroundColor(.v2Primary)
                            Spacer()
                        }
                        .padding(16)
                    }
                }
            }
        }
    }

    // MARK: - Features Section

    var featuresSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Features")
                .font(.v2Caption)
                .foregroundColor(.v2TextSecondary)
                .padding(.leading, 4)

            V2Card(padding: 0) {
                VStack(spacing: 0) {
                    SettingsToggleRow(
                        icon: "arrow.up.circle.fill",
                        title: "Round-Up Savings",
                        subtitle: "Automatically round up purchases",
                        isOn: $roundUpEnabled,
                        color: .v2Primary
                    )

                    Divider().background(Color.white.opacity(0.06))

                    SettingsNavigationRow(
                        icon: "chart.bar.fill",
                        title: "Spending Limits",
                        subtitle: "Set category budgets",
                        color: .v2Warning
                    ) {
                        // Navigate to spending limits
                    }

                    Divider().background(Color.white.opacity(0.06))

                    SettingsNavigationRow(
                        icon: "arrow.left.arrow.right",
                        title: "Subscriptions",
                        subtitle: "Manage recurring payments",
                        color: .v2Premium
                    ) {
                        // Navigate to subscriptions
                    }
                }
            }
        }
    }

    // MARK: - Notifications Section

    var notificationsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Notifications")
                .font(.v2Caption)
                .foregroundColor(.v2TextSecondary)
                .padding(.leading, 4)

            V2Card(padding: 0) {
                VStack(spacing: 0) {
                    SettingsToggleRow(
                        icon: "bell.fill",
                        title: "Push Notifications",
                        subtitle: "Transaction alerts & reminders",
                        isOn: $notificationsEnabled,
                        color: .v2Accent
                    )

                    Divider().background(Color.white.opacity(0.06))

                    SettingsToggleRow(
                        icon: "exclamationmark.triangle.fill",
                        title: "Budget Alerts",
                        subtitle: "When approaching limits",
                        isOn: $budgetAlertsEnabled,
                        color: .v2Warning
                    )

                    Divider().background(Color.white.opacity(0.06))

                    SettingsToggleRow(
                        icon: "doc.text.fill",
                        title: "Weekly Reports",
                        subtitle: "Spending summary every Sunday",
                        isOn: $weeklyReportEnabled,
                        color: .v2Info
                    )
                }
            }
        }
    }

    // MARK: - Security Section

    var securitySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Security")
                .font(.v2Caption)
                .foregroundColor(.v2TextSecondary)
                .padding(.leading, 4)

            V2Card(padding: 0) {
                VStack(spacing: 0) {
                    SettingsToggleRow(
                        icon: "faceid",
                        title: "Face ID / Touch ID",
                        subtitle: "Unlock with biometrics",
                        isOn: $biometricEnabled,
                        color: .v2Primary
                    )

                    Divider().background(Color.white.opacity(0.06))

                    SettingsNavigationRow(
                        icon: "key.fill",
                        title: "Change Password",
                        subtitle: nil,
                        color: .v2TextSecondary
                    ) { }

                    Divider().background(Color.white.opacity(0.06))

                    SettingsNavigationRow(
                        icon: "shield.checkered",
                        title: "Two-Factor Auth",
                        subtitle: "Enabled",
                        color: .v2Success
                    ) { }
                }
            }
        }
    }

    // MARK: - Data Section

    var dataSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Data & Privacy")
                .font(.v2Caption)
                .foregroundColor(.v2TextSecondary)
                .padding(.leading, 4)

            V2Card(padding: 0) {
                VStack(spacing: 0) {
                    SettingsNavigationRow(
                        icon: "square.and.arrow.up",
                        title: "Export Data",
                        subtitle: "Download your financial data",
                        color: .v2Info
                    ) {
                        showExportData = true
                    }

                    Divider().background(Color.white.opacity(0.06))

                    SettingsNavigationRow(
                        icon: "doc.text",
                        title: "Privacy Policy",
                        subtitle: nil,
                        color: .v2TextSecondary
                    ) { }

                    Divider().background(Color.white.opacity(0.06))

                    SettingsNavigationRow(
                        icon: "doc.plaintext",
                        title: "Terms of Service",
                        subtitle: nil,
                        color: .v2TextSecondary
                    ) { }
                }
            }
        }
    }

    // MARK: - About Section

    var aboutSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("About")
                .font(.v2Caption)
                .foregroundColor(.v2TextSecondary)
                .padding(.leading, 4)

            V2Card(padding: 0) {
                VStack(spacing: 0) {
                    HStack {
                        Image(systemName: "info.circle.fill")
                            .foregroundColor(.v2Info)
                        Text("Version")
                            .font(.v2Body)
                            .foregroundColor(.v2TextPrimary)
                        Spacer()
                        Text("2.0 (7)")
                            .font(.v2Body)
                            .foregroundColor(.v2TextSecondary)
                    }
                    .padding(16)

                    Divider().background(Color.white.opacity(0.06))

                    SettingsNavigationRow(
                        icon: "star.fill",
                        title: "Rate App",
                        subtitle: nil,
                        color: .v2Warning
                    ) { }

                    Divider().background(Color.white.opacity(0.06))

                    SettingsNavigationRow(
                        icon: "questionmark.circle.fill",
                        title: "Help & Support",
                        subtitle: nil,
                        color: .v2Primary
                    ) { }
                }
            }
        }
    }

    // MARK: - Danger Section

    var dangerSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            V2Card(padding: 0) {
                VStack(spacing: 0) {
                    Button {
                        // Log out
                    } label: {
                        HStack {
                            Image(systemName: "rectangle.portrait.and.arrow.right")
                                .foregroundColor(.v2Danger)
                            Text("Log Out")
                                .font(.v2Body)
                                .foregroundColor(.v2Danger)
                            Spacer()
                        }
                        .padding(16)
                    }

                    Divider().background(Color.white.opacity(0.06))

                    Button {
                        showDeleteConfirm = true
                    } label: {
                        HStack {
                            Image(systemName: "trash.fill")
                                .foregroundColor(.v2Danger)
                            Text("Delete Account")
                                .font(.v2Body)
                                .foregroundColor(.v2Danger)
                            Spacer()
                        }
                        .padding(16)
                    }
                }
            }
            .alert("Delete Account?", isPresented: $showDeleteConfirm) {
                Button("Cancel", role: .cancel) { }
                Button("Delete", role: .destructive) { }
            } message: {
                Text("This will permanently delete all your data. This action cannot be undone.")
            }
        }
    }
}

// MARK: - Settings Row Components

struct SettingsToggleRow: View {
    let icon: String
    let title: String
    let subtitle: String?
    @Binding var isOn: Bool
    let color: Color

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.system(size: 18))
                .foregroundColor(color)
                .frame(width: 24)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.v2Body)
                    .foregroundColor(.v2TextPrimary)

                if let subtitle = subtitle {
                    Text(subtitle)
                        .font(.v2CaptionSmall)
                        .foregroundColor(.v2TextTertiary)
                }
            }

            Spacer()

            Toggle("", isOn: $isOn)
                .tint(.v2Primary)
                .labelsHidden()
        }
        .padding(16)
    }
}

struct SettingsNavigationRow: View {
    let icon: String
    let title: String
    let subtitle: String?
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 14) {
                Image(systemName: icon)
                    .font(.system(size: 18))
                    .foregroundColor(color)
                    .frame(width: 24)

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.v2Body)
                        .foregroundColor(.v2TextPrimary)

                    if let subtitle = subtitle {
                        Text(subtitle)
                            .font(.v2CaptionSmall)
                            .foregroundColor(.v2TextTertiary)
                    }
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.v2TextTertiary)
            }
            .padding(16)
        }
    }
}

struct ConnectedAccountRow: View {
    let icon: String
    let name: String
    let detail: String
    let color: Color

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.15))
                    .frame(width: 40, height: 40)

                Image(systemName: icon)
                    .font(.system(size: 16))
                    .foregroundColor(color)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(name)
                    .font(.v2Body)
                    .foregroundColor(.v2TextPrimary)

                Text(detail)
                    .font(.v2CaptionSmall)
                    .foregroundColor(.v2TextTertiary)
            }

            Spacer()

            Image(systemName: "checkmark.circle.fill")
                .foregroundColor(.v2Success)
        }
        .padding(16)
    }
}

// MARK: - Preview

#Preview {
    SettingsViewV2()
}
