import SwiftUI

struct LifeIntegrationView: View {
    @StateObject private var lifeContext = LifeContextManager.shared

    var body: some View {
        NavigationView {
            ZStack {
                Color.furgCharcoal.ignoresSafeArea()

                VStack(spacing: 20) {
                    Text("Life Integration")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding()

                    VStack(spacing: 12) {
                        Text("Coming Soon")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.furgMint)
                        Text("Connect your life events to spending patterns and get personalized insights")
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
            .navigationTitle("Life")
        }
    }
}

#Preview {
    LifeIntegrationView()
        .environmentObject(FinanceManager())
}
