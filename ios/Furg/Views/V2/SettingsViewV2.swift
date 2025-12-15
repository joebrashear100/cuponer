//
//  SettingsViewV2.swift
//  Furg
//
//  Settings for V2 with V1/V2 toggle
//

import SwiftUI

struct SettingsViewV2: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var authManager: AuthManager
    @AppStorage("useV2Interface") var useV2: Bool = true

    var body: some View {
        NavigationStack {
            ZStack {
                Color.v2Background.ignoresSafeArea()

                List {
                    // Interface Toggle Section
                    Section {
                        Toggle(isOn: $useV2) {
                            HStack {
                                Image(systemName: "paintbrush.fill")
                                    .foregroundColor(.v2Primary)
                                Text("Use V2 Interface")
                            }
                        }
                        .tint(.v2Primary)
                    } header: {
                        Text("Interface")
                    }
                    .listRowBackground(Color.v2CardBackground)

                    // Account Section
                    Section {
                        HStack {
                            Image(systemName: "person.circle.fill")
                                .foregroundColor(.v2Primary)
                            Text("Account")
                            Spacer()
                            Text("joe@example.com")
                                .foregroundColor(.v2TextTertiary)
                        }
                    } header: {
                        Text("Account")
                    }
                    .listRowBackground(Color.v2CardBackground)

                    // About Section
                    Section {
                        HStack {
                            Image(systemName: "info.circle.fill")
                                .foregroundColor(.v2Info)
                            Text("Version")
                            Spacer()
                            Text("2.0.0")
                                .foregroundColor(.v2TextTertiary)
                        }
                    } header: {
                        Text("About")
                    }
                    .listRowBackground(Color.v2CardBackground)
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                        .foregroundColor(.v2Primary)
                }
            }
        }
    }
}
