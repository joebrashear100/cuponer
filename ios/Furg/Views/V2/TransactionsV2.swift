//
//  TransactionsV2.swift
//  Furg
//
//  Transaction history for V2
//

import SwiftUI

struct TransactionsV2: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var financeManager: FinanceManager

    var body: some View {
        NavigationStack {
            ZStack {
                Color.v2Background.ignoresSafeArea()

                VStack {
                    Text("Transactions")
                        .font(.v2Title)
                        .foregroundColor(.v2TextPrimary)

                    Text("Coming soon...")
                        .foregroundColor(.v2TextSecondary)
                }
            }
            .navigationTitle("Transactions")
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
