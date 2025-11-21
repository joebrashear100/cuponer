//
//  SettingsView.swift
//  Furg
//
//  Settings and profile management
//

import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var authManager: AuthManager
    @EnvironmentObject var plaidManager: PlaidManager
    @State private var profile: UserProfile?
    @State private var showSignOutAlert = false

    private let apiClient = APIClient()

    var body: some View {
        NavigationView {
            List {
                // Profile section
                Section("Profile") {
                    if let profile = profile {
                        if let name = profile.name {
                            LabeledContent("Name", value: name)
                        }
                        if let location = profile.location {
                            LabeledContent("Location", value: location)
                        }
                        if let employer = profile.employer {
                            LabeledContent("Employer", value: employer)
                        }
                        if let salary = profile.salary {
                            LabeledContent("Salary", value: "$\(Int(salary))/year")
                        }

                        NavigationLink("Edit Profile") {
                            ProfileEditView(profile: $profile)
                        }
                    } else {
                        Text("Loading profile...")
                            .foregroundColor(.gray)
                    }
                }

                // Intensity mode
                Section("FURG Settings") {
                    if let intensityMode = profile?.intensityMode {
                        HStack {
                            Text("Intensity Mode")
                            Spacer()
                            Text(intensityMode.capitalized)
                                .foregroundColor(.gray)
                        }
                    }

                    NavigationLink("Savings Goal") {
                        SavingsGoalView()
                    }

                    if let buffer = profile?.emergencyBuffer {
                        LabeledContent("Emergency Buffer", value: "$\(Int(buffer))")
                    }
                }

                // Connected banks
                Section("Connected Banks") {
                    if plaidManager.linkedBanks.isEmpty {
                        Button("Connect Bank") {
                            Task {
                                await plaidManager.presentPlaidLink()
                            }
                        }
                    } else {
                        ForEach(plaidManager.linkedBanks) { bank in
                            HStack {
                                VStack(alignment: .leading) {
                                    Text(bank.name)
                                    Text("Last synced: \(bank.lastSynced, style: .relative) ago")
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                }
                                Spacer()
                            }
                        }

                        Button("Add Another Bank") {
                            Task {
                                await plaidManager.presentPlaidLink()
                            }
                        }

                        Button("Sync All Banks") {
                            Task {
                                await plaidManager.syncBanks()
                            }
                        }
                    }
                }

                // App info
                Section("About") {
                    LabeledContent("Version", value: "1.0.0")
                    Link("Privacy Policy", destination: URL(string: "https://furg.app/privacy")!)
                    Link("Terms of Service", destination: URL(string: "https://furg.app/terms")!)
                }

                // Sign out
                Section {
                    Button(role: .destructive, action: { showSignOutAlert = true }) {
                        Text("Sign Out")
                            .frame(maxWidth: .infinity, alignment: .center)
                    }
                }
            }
            .navigationTitle("Settings")
            .task {
                await loadProfile()
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
    }

    private func loadProfile() async {
        do {
            profile = try await apiClient.getProfile()
        } catch {
            print("Failed to load profile: \(error)")
        }
    }
}

struct ProfileEditView: View {
    @Environment(\.dismiss) var dismiss
    @Binding var profile: UserProfile?
    @State private var name = ""
    @State private var location = ""
    @State private var employer = ""
    @State private var salary = ""

    private let apiClient = APIClient()

    var body: some View {
        Form {
            Section("Personal Info") {
                TextField("Name", text: $name)
                TextField("Location", text: $location)
            }

            Section("Employment") {
                TextField("Employer", text: $employer)
                TextField("Annual Salary", text: $salary)
                    .keyboardType(.numberPad)
            }

            Section {
                Button("Save") {
                    Task {
                        await saveProfile()
                    }
                }
                .frame(maxWidth: .infinity, alignment: .center)
            }
        }
        .navigationTitle("Edit Profile")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            if let profile = profile {
                name = profile.name ?? ""
                location = profile.location ?? ""
                employer = profile.employer ?? ""
                if let salaryValue = profile.salary {
                    salary = "\(Int(salaryValue))"
                }
            }
        }
    }

    private func saveProfile() async {
        var updates: [String: Any] = [:]

        if !name.isEmpty {
            updates["name"] = name
        }
        if !location.isEmpty {
            updates["location"] = location
        }
        if !employer.isEmpty {
            updates["employer"] = employer
        }
        if let salaryValue = Double(salary) {
            updates["salary"] = salaryValue
        }

        do {
            try await apiClient.updateProfile(updates)
            dismiss()
        } catch {
            print("Failed to save profile: \(error)")
        }
    }
}

struct SavingsGoalView: View {
    @Environment(\.dismiss) var dismiss
    @State private var amount = ""
    @State private var deadline = Date()
    @State private var purpose = ""
    @State private var frequency = "weekly"

    private let apiClient = APIClient()

    var body: some View {
        Form {
            Section("Goal") {
                TextField("Amount", text: $amount)
                    .keyboardType(.numberPad)

                DatePicker("Deadline", selection: $deadline, displayedComponents: .date)

                TextField("Purpose", text: $purpose)
                    .placeholder(when: purpose.isEmpty) {
                        Text("e.g., house down payment")
                    }
            }

            Section("Frequency") {
                Picker("Auto-save", selection: $frequency) {
                    Text("Weekly").tag("weekly")
                    Text("Bi-weekly").tag("biweekly")
                    Text("Monthly").tag("monthly")
                }
                .pickerStyle(.segmented)
            }

            Section {
                Button("Set Goal") {
                    Task {
                        await setGoal()
                    }
                }
                .frame(maxWidth: .infinity, alignment: .center)
            }
        }
        .navigationTitle("Savings Goal")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func setGoal() async {
        guard let amountValue = Double(amount), amountValue > 0 else { return }
        guard !purpose.isEmpty else { return }

        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let deadlineString = formatter.string(from: deadline)

        do {
            try await apiClient.setSavingsGoal(
                amount: amountValue,
                deadline: deadlineString,
                purpose: purpose,
                frequency: frequency
            )
            dismiss()
        } catch {
            print("Failed to set goal: \(error)")
        }
    }
}

extension View {
    func placeholder<Content: View>(
        when shouldShow: Bool,
        alignment: Alignment = .leading,
        @ViewBuilder placeholder: () -> Content) -> some View {

        ZStack(alignment: alignment) {
            placeholder().opacity(shouldShow ? 1 : 0)
            self
        }
    }
}

#Preview {
    SettingsView()
        .environmentObject(AuthManager())
        .environmentObject(PlaidManager())
}
