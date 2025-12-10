import SwiftUI

struct MerchantIntelligenceView: View {
    @StateObject private var merchantManager = MerchantIntelligenceManager.shared
    @State private var searchText = ""
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.furgCharcoal.ignoresSafeArea()
                
                VStack(spacing: 20) {
                    Text("Store Intelligence")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding()
                    
                    VStack(spacing: 12) {
                        Text("Coming Soon")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.furgMint)
                        Text("Smart merchant intelligence and deal insights will be available here")
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
            .navigationTitle("Merchants")
        }
    }
}

#Preview {
    MerchantIntelligenceView()
        .environmentObject(FinanceManager())
}
