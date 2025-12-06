//
//  SettingsView.swift
//  Furg
//
//  Modern glassmorphism settings view
//

import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var authManager: AuthManager
    @EnvironmentObject var plaidManager: PlaidManager
    @State private var profile: UserProfile?
    @State private var showSignOutAlert = false
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

                // Settings sections
                VStack(spacing: 16) {
                    SettingsSection(title: "FURG SETTINGS") {
                        SettingsRow(
                            icon: "flame.fill",
                            title: "Intensity Mode",
                            value: profile?.intensityMode?.capitalized ?? "Moderate",
                            color: .furgWarning
                        )

                        SettingsRow(
                            icon: "target",
                            title: "Savings Goal",
                            value: "Configure",
                            color: .furgMint
                        )

                        SettingsRow(
                            icon: "shield.fill",
                            title: "Emergency Buffer",
                            value: profile?.emergencyBuffer != nil ? "$\(Int(profile!.emergencyBuffer!))" : "$500",
                            color: .furgSuccess
                        )
                    }
                    .offset(y: animate ? 0 : 20)
                    .opacity(animate ? 1 : 0)
                    .animation(.easeOut(duration: 0.5).delay(0.2), value: animate)

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

                        SettingsRow(
                            icon: "lock.shield.fill",
                            title: "Privacy Policy",
                            value: "",
                            color: .white.opacity(0.5),
                            showChevron: true
                        )

                        SettingsRow(
                            icon: "doc.text.fill",
                            title: "Terms of Service",
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
    }

    private func loadProfile() async {
        do {
            profile = try await apiClient.getProfile()
        } catch {
            print("Failed to load profile: \(error)")
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

#Preview {
    ZStack {
        AnimatedMeshBackground()
        SettingsView()
    }
    .environmentObject(AuthManager())
    .environmentObject(PlaidManager())
}
