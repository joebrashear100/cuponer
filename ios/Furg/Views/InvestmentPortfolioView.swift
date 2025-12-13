import SwiftUI

struct InvestmentPortfolioView: View {
    @StateObject private var investmentManager = InvestmentPortfolioManager.shared

    var body: some View {
        NavigationView {
            ZStack {
                Color.furgCharcoal.ignoresSafeArea()

                VStack(spacing: 20) {
                    Text("Investment Portfolio")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding()

                    VStack(spacing: 12) {
                        Text("Coming Soon")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.furgMint)
                        Text("Track your investment portfolio across multiple brokerages and get comprehensive analytics")
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
            .navigationTitle("Investments")
        }
    }
}

#Preview {
    InvestmentPortfolioView()
        .environmentObject(FinanceManager())
}
