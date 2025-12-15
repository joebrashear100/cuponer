//
//  ConnectBankViewV2.swift
//  Furg
//
//  Plaid bank connection for V2
//

import SwiftUI

struct ConnectBankViewV2: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var plaidManager: PlaidManager

    var body: some View {
        NavigationStack {
            ZStack {
                Color.v2Background.ignoresSafeArea()

                VStack {
                    Text("Connect Bank")
                        .font(.v2Title)
                        .foregroundColor(.v2TextPrimary)

                    Text("Coming soon...")
                        .foregroundColor(.v2TextSecondary)
                }
            }
            .navigationTitle("Connect Bank")
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
