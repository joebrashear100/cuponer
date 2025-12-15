//
//  ForecastViewV2.swift
//  Furg
//
//  Financial forecast for V2
//

import SwiftUI

struct ForecastViewV2: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var financeManager: FinanceManager

    var body: some View {
        NavigationStack {
            ZStack {
                Color.v2Background.ignoresSafeArea()

                VStack {
                    Text("Forecast")
                        .font(.v2Title)
                        .foregroundColor(.v2TextPrimary)

                    Text("Coming soon...")
                        .foregroundColor(.v2TextSecondary)
                }
            }
            .navigationTitle("Forecast")
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
