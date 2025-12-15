//
//  SpendingLimitsViewV2.swift
//  Furg
//
//  Spending limits for V2
//

import SwiftUI

struct SpendingLimitsViewV2: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var financeManager: FinanceManager

    var body: some View {
        NavigationStack {
            ZStack {
                Color.v2Background.ignoresSafeArea()

                VStack {
                    Text("Spending Limits")
                        .font(.v2Title)
                        .foregroundColor(.v2TextPrimary)

                    Text("Coming soon...")
                        .foregroundColor(.v2TextSecondary)
                }
            }
            .navigationTitle("Limits")
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
