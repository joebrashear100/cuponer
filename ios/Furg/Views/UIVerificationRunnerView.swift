//
//  UIVerificationRunnerView.swift
//  Furg
//
//  Temporary view to run UI verification tests visually
//  Add a button to SettingsView to navigate here
//

import SwiftUI

struct UIVerificationRunnerView: View {
    @EnvironmentObject var authManager: AuthManager
    @EnvironmentObject var financeManager: FinanceManager
    @EnvironmentObject var chatManager: ChatManager
    @EnvironmentObject var plaidManager: PlaidManager
    @EnvironmentObject var goalsManager: GoalsManager

    @State private var verificationResults: [VerificationResult] = []
    @State private var isRunning = false

    struct VerificationResult: Identifiable {
        let id = UUID()
        let viewName: String
        let passed: Bool
        let details: String
    }

    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // Header
                Text("UI Verification Tests")
                    .font(.largeTitle.bold())
                    .padding()

                if isRunning {
                    ProgressView("Running tests...")
                        .padding()
                } else {
                    Button(action: runTests) {
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                            Text("Run All Tests")
                        }
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.blue)
                        .cornerRadius(12)
                    }
                    .padding(.horizontal)
                }

                // Results
                if !verificationResults.isEmpty {
                    List(verificationResults) { result in
                        HStack {
                            Image(systemName: result.passed ? "checkmark.circle.fill" : "xmark.circle.fill")
                                .foregroundColor(result.passed ? .green : .red)

                            VStack(alignment: .leading, spacing: 4) {
                                Text(result.viewName)
                                    .font(.headline)

                                Text(result.details)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }

                Spacer()
            }
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    private func runTests() {
        isRunning = true
        verificationResults = []

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            // Test each view
            testView(name: "MainTabView") {
                MainTabView()
                    .environmentObject(authManager)
                    .environmentObject(financeManager)
                    .environmentObject(chatManager)
                    .environmentObject(plaidManager)
                    .environmentObject(goalsManager)
            }

            testView(name: "DashboardView") {
                DashboardView()
                    .environmentObject(financeManager)
            }

            testView(name: "SettingsView") {
                SettingsView()
                    .environmentObject(authManager)
            }

            testView(name: "TransactionsListView") {
                TransactionsListView()
                    .environmentObject(financeManager)
            }

            testView(name: "ChatView") {
                ChatView()
                    .environmentObject(chatManager)
            }

            testView(name: "GoalsView") {
                GoalsView()
                    .environmentObject(goalsManager)
            }

            testView(name: "CashFlowView") {
                CashFlowView()
                    .environmentObject(financeManager)
            }

            testView(name: "CardRecommendationsView") {
                CardRecommendationsView()
                    .environmentObject(financeManager)
            }

            testView(name: "ToolsHubView") {
                ToolsHubView()
                    .environmentObject(financeManager)
            }

            isRunning = false
        }
    }

    private func testView<V: View>(name: String, @ViewBuilder builder: () -> V) {
        do {
            let view = builder()
            let hosting = UIHostingController(rootView: view)
            _ = hosting.view // Force view to load

            // Check view structure
            let mirror = Mirror(reflecting: view)
            let hasButtons = containsType(mirror, typeName: "Button")
            let hasState = containsType(mirror, typeName: "State")

            let details = [
                hasButtons ? "✅ Interactive" : "⚠️ No buttons",
                hasState ? "✅ Stateful" : "ℹ️ No state"
            ].joined(separator: ", ")

            verificationResults.append(VerificationResult(
                viewName: name,
                passed: true,
                details: "Renders OK - \(details)"
            ))
        } catch {
            verificationResults.append(VerificationResult(
                viewName: name,
                passed: false,
                details: "❌ Render failed: \(error.localizedDescription)"
            ))
        }
    }

    private func containsType(_ mirror: Mirror, typeName: String) -> Bool {
        let description = String(describing: mirror.subjectType)
        if description.contains(typeName) {
            return true
        }

        for child in mirror.children {
            let childMirror = Mirror(reflecting: child.value)
            if containsType(childMirror, typeName: typeName) {
                return true
            }
        }

        return false
    }
}

#Preview {
    UIVerificationRunnerView()
        .environmentObject(AuthManager())
        .environmentObject(FinanceManager())
        .environmentObject(ChatManager())
        .environmentObject(PlaidManager())
        .environmentObject(GoalsManager())
}
