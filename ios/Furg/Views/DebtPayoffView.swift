import SwiftUI

struct DebtPayoffView: View {
    @StateObject private var debtManager = DebtPayoffManager.shared

    var body: some View {
        NavigationView {
            ZStack {
                Color.furgCharcoal.ignoresSafeArea()

                VStack(spacing: 20) {
                    Text("Debt Payoff")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding()

                    VStack(spacing: 12) {
                        Text("Coming Soon")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.furgMint)
                        Text("Track your debts with snowball and avalanche strategies to become debt-free")
                            .font(.system(size: 14))
                            .foregroundColor(.white.opacity(0.6))
                            .multilineTextAlignment(.center)
                    }
                    .padding(20)
                    .background(Color.white.opacity(0.03))
                    .cornerRadius(12)
                    .padding()

                    Spacer()
                }
            }
            .navigationTitle("Debt Payoff")
        }
    }
}

#Preview {
    DebtPayoffView()
        .environmentObject(FinanceManager())
}
