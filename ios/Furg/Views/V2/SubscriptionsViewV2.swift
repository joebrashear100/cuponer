//
//  SubscriptionsViewV2.swift
//  Furg
//
//  Subscription tracking for V2
//

import SwiftUI

struct SubscriptionsViewV2: View {
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                Color.v2Background.ignoresSafeArea()

                VStack {
                    Text("Subscriptions")
                        .font(.v2Title)
                        .foregroundColor(.v2TextPrimary)

                    Text("Coming soon...")
                        .foregroundColor(.v2TextSecondary)
                }
            }
            .navigationTitle("Subscriptions")
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
