import SwiftUI

struct LifeIntegrationView: View {
    @StateObject private var lifeSimulator = LifeSimulator.shared
    @State private var showingScenarioBuilder = false
    @State private var selectedScenario: LifeScenario?

    var savedScenarios: [LifeScenario] {
        lifeSimulator.savedScenarios.sorted { $0.createdAt > $1.createdAt }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.furgCharcoal.ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 24) {
                        // Header
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Life Scenarios")
                                .font(.system(size: 28, weight: .bold))
                                .foregroundColor(.white)

                            Text("Plan and model financial scenarios")
                                .font(.system(size: 14))
                                .foregroundColor(.white.opacity(0.6))
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 20)
                        .padding(.top, 16)

                        // Add Scenario Button
                        Button(action: { showingScenarioBuilder = true }) {
                            HStack(spacing: 12) {
                                Image(systemName: "plus.circle.fill")
                                    .font(.system(size: 18))

                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Build New Scenario")
                                        .font(.system(size: 15, weight: .semibold))

                                    Text("Model what-if scenarios")
                                        .font(.system(size: 12))
                                }

                                Spacer()

                                Image(systemName: "chevron.right")
                                    .font(.system(size: 12, weight: .semibold))
                            }
                            .foregroundColor(.white)
                            .padding(16)
                            .background(Color.furgMint.opacity(0.2))
                            .cornerRadius(12)
                        }
                        .padding(.horizontal, 20)

                        // Saved Scenarios
                        if savedScenarios.isEmpty {
                            VStack(spacing: 20) {
                                Image(systemName: "chart.line.uptrend.xyaxis")
                                    .font(.system(size: 40))
                                    .foregroundColor(.white.opacity(0.2))

                                VStack(spacing: 8) {
                                    Text("No scenarios yet")
                                        .font(.system(size: 16, weight: .semibold))
                                        .foregroundColor(.white)

                                    Text("Create your first scenario to start planning")
                                        .font(.system(size: 13))
                                        .foregroundColor(.white.opacity(0.5))
                                        .multilineTextAlignment(.center)
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .padding(40)
                        } else {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Your Scenarios")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 20)

                                ForEach(savedScenarios) { scenario in
                                    NavigationLink(destination: ScenarioDetailView(scenario: scenario)) {
                                        ScenarioRow(scenario: scenario)
                                    }
                                    .padding(.horizontal, 20)
                                }
                            }
                        }

                        // Scenario Types Reference
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Scenario Types")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.white)
                                .padding(.horizontal, 20)

                            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                                ForEach(LifeScenario.ScenarioType.allCases.prefix(6), id: \.self) { scenarioType in
                                    VStack(spacing: 8) {
                                        Image(systemName: scenarioType.icon)
                                            .font(.system(size: 24))
                                            .foregroundColor(.furgMint)

                                        Text(scenarioType.rawValue)
                                            .font(.system(size: 12, weight: .semibold))
                                            .foregroundColor(.white)
                                            .multilineTextAlignment(.center)
                                            .lineLimit(2)
                                    }
                                    .padding(12)
                                    .frame(maxWidth: .infinity)
                                    .background(Color.white.opacity(0.05))
                                    .cornerRadius(10)
                                }
                            }
                            .padding(.horizontal, 20)
                        }

                        Spacer(minLength: 40)
                    }
                }
            }
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $showingScenarioBuilder) {
                ScenarioBuilderView()
            }
        }
    }
}

// MARK: - Supporting Views

struct ScenarioRow: View {
    let scenario: LifeScenario

    var body: some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                Image(systemName: scenario.type.icon)
                    .font(.system(size: 24))
                    .foregroundColor(.furgMint)

                VStack(alignment: .leading, spacing: 4) {
                    Text(scenario.title)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(.white)

                    Text(scenario.description)
                        .font(.system(size: 12))
                        .foregroundColor(.white.opacity(0.6))
                        .lineLimit(1)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 4) {
                    Text(String(format: "$%.0f", scenario.comparison.netWorthDifference))
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(scenario.comparison.netWorthDifference >= 0 ? .furgSuccess : .furgDanger)

                    Text("net worth impact")
                        .font(.system(size: 10))
                        .foregroundColor(.white.opacity(0.5))
                }
            }

            HStack(spacing: 8) {
                Text(scenario.type.rawValue)
                    .font(.system(size: 11))
                    .foregroundColor(.white.opacity(0.5))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.white.opacity(0.05))
                    .cornerRadius(6)

                Text(scenario.createdAt.formatted(.dateTime.month(.abbreviated).day()))
                    .font(.system(size: 11))
                    .foregroundColor(.white.opacity(0.5))

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(.white.opacity(0.3))
            }
        }
        .padding(14)
        .background(Color.white.opacity(0.05))
        .cornerRadius(12)
    }
}

// MARK: - Scenario Builder

struct ScenarioBuilderView: View {
    @StateObject private var lifeSimulator = LifeSimulator.shared
    @Environment(\.dismiss) var dismiss
    @State private var selectedScenarioType: LifeScenario.ScenarioType = .moveToCity
    @State private var scenarioName = ""
    @State private var scenarioDescription = ""
    @State private var timeHorizon = 10
    @State private var isSimulating = false

    var body: some View {
        NavigationStack {
            ZStack {
                Color.furgCharcoal.ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 20) {
                        // Scenario Type Selection
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Scenario Type")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(.white)

                            Picker("Scenario Type", selection: $selectedScenarioType) {
                                ForEach(LifeScenario.ScenarioType.allCases, id: \.self) { type in
                                    HStack {
                                        Image(systemName: type.icon)
                                        Text(type.rawValue)
                                    }
                                    .tag(type)
                                }
                            }
                            .tint(.furgMint)
                            .pickerStyle(.navigationLink)
                        }
                        .padding(16)
                        .background(Color.white.opacity(0.05))
                        .cornerRadius(12)

                        // Scenario Name
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Scenario Name")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(.white)

                            TextField("e.g., Move to NYC", text: $scenarioName)
                                .foregroundColor(.white)
                                .padding(12)
                                .background(Color.white.opacity(0.1))
                                .cornerRadius(10)
                        }
                        .padding(16)
                        .background(Color.white.opacity(0.05))
                        .cornerRadius(12)

                        // Description
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Description")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(.white)

                            TextField("Describe your scenario", text: $scenarioDescription, axis: .vertical)
                                .lineLimit(4...6)
                                .foregroundColor(.white)
                                .padding(12)
                                .background(Color.white.opacity(0.1))
                                .cornerRadius(10)
                        }
                        .padding(16)
                        .background(Color.white.opacity(0.05))
                        .cornerRadius(12)

                        // Time Horizon
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Text("Time Horizon")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(.white)

                                Spacer()

                                Text("\(timeHorizon) years")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(.furgMint)
                            }

                            Slider(value: Binding(
                                get: { Double(timeHorizon) },
                                set: { timeHorizon = Int($0) }
                            ), in: 1...30, step: 1)
                                .tint(.furgMint)
                        }
                        .padding(16)
                        .background(Color.white.opacity(0.05))
                        .cornerRadius(12)

                        // Create Button
                        Button(action: createScenario) {
                            HStack(spacing: 10) {
                                if isSimulating {
                                    ProgressView()
                                        .tint(.furgCharcoal)
                                } else {
                                    Image(systemName: "checkmark.circle.fill")
                                }

                                Text("Create & Simulate")
                                    .font(.system(size: 15, weight: .semibold))
                            }
                            .frame(maxWidth: .infinity)
                            .foregroundColor(.furgCharcoal)
                            .padding(14)
                            .background(Color.furgMint)
                            .cornerRadius(10)
                        }
                        .disabled(isSimulating || scenarioName.isEmpty)

                        Spacer(minLength: 20)
                    }
                    .padding(20)
                }
            }
            .navigationTitle("New Scenario")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") { dismiss() }
                        .foregroundColor(.furgMint)
                }
            }
        }
    }

    private func createScenario() {
        isSimulating = true

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            var parameters = ScenarioParameters()
            parameters.timeHorizonYears = timeHorizon

            let scenario = lifeSimulator.simulateGenericScenario(
                type: selectedScenarioType,
                description: scenarioDescription.isEmpty ? selectedScenarioType.rawValue : scenarioDescription,
                parameters: parameters,
                timeHorizonYears: timeHorizon
            )

            lifeSimulator.addScenario(scenario)
            isSimulating = false
            dismiss()
        }
    }
}

// MARK: - Scenario Detail View

struct ScenarioDetailView: View {
    let scenario: LifeScenario
    @StateObject private var lifeSimulator = LifeSimulator.shared
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                Color.furgCharcoal.ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 24) {
                        // Header
                        VStack(spacing: 12) {
                            Image(systemName: scenario.type.icon)
                                .font(.system(size: 40))
                                .foregroundColor(.furgMint)

                            Text(scenario.title)
                                .font(.system(size: 24, weight: .bold))
                                .foregroundColor(.white)

                            Text(scenario.description)
                                .font(.system(size: 14))
                                .foregroundColor(.white.opacity(0.6))
                                .multilineTextAlignment(.center)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(20)

                        // Impact Summary
                        VStack(spacing: 12) {
                            ImpactMetric(
                                label: "Net Worth Impact",
                                value: String(format: "$%.0f", scenario.comparison.netWorthDifference),
                                valueColor: scenario.comparison.netWorthDifference >= 0 ? .furgSuccess : .furgDanger
                            )

                            ImpactMetric(
                                label: "Total Savings Impact",
                                value: String(format: "$%.0f", scenario.comparison.totalSavingsDifference),
                                valueColor: scenario.comparison.totalSavingsDifference >= 0 ? .furgSuccess : .furgDanger
                            )

                            if let months = scenario.comparison.breakEvenMonths {
                                ImpactMetric(
                                    label: "Break-Even",
                                    value: "\(months) months",
                                    valueColor: .furgInfo
                                )
                            }
                        }
                        .padding(16)
                        .background(Color.white.opacity(0.05))
                        .cornerRadius(12)
                        .padding(.horizontal, 20)

                        // Recommendation
                        VStack(alignment: .leading, spacing: 12) {
                            HStack(spacing: 10) {
                                Image(systemName: "lightbulb.fill")
                                    .foregroundColor(.furgWarning)

                                Text("Recommendation")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(.white)
                            }

                            Text(scenario.comparison.recommendation)
                                .font(.system(size: 13))
                                .foregroundColor(.white.opacity(0.7))
                                .lineLimit(nil)
                        }
                        .padding(16)
                        .background(Color.white.opacity(0.05))
                        .cornerRadius(12)
                        .padding(.horizontal, 20)

                        // Pros and Cons
                        HStack(alignment: .top, spacing: 16) {
                            VStack(alignment: .leading, spacing: 8) {
                                HStack(spacing: 6) {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(.furgSuccess)
                                    Text("Pros")
                                        .font(.system(size: 13, weight: .semibold))
                                }
                                .foregroundColor(.furgSuccess)

                                ForEach(scenario.comparison.prosAndCons.pros, id: \.self) { pro in
                                    Text("• \(pro)")
                                        .font(.system(size: 12))
                                        .foregroundColor(.white.opacity(0.7))
                                }
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)

                            VStack(alignment: .leading, spacing: 8) {
                                HStack(spacing: 6) {
                                    Image(systemName: "xmark.circle.fill")
                                        .foregroundColor(.furgDanger)
                                    Text("Cons")
                                        .font(.system(size: 13, weight: .semibold))
                                }
                                .foregroundColor(.furgDanger)

                                ForEach(scenario.comparison.prosAndCons.cons, id: \.self) { con in
                                    Text("• \(con)")
                                        .font(.system(size: 12))
                                        .foregroundColor(.white.opacity(0.7))
                                }
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        .padding(16)
                        .background(Color.white.opacity(0.05))
                        .cornerRadius(12)
                        .padding(.horizontal, 20)

                        // Action Buttons
                        VStack(spacing: 12) {
                            Button(action: { lifeSimulator.deleteScenario(scenario) }) {
                                HStack(spacing: 8) {
                                    Image(systemName: "trash.fill")
                                    Text("Delete Scenario")
                                }
                                .frame(maxWidth: .infinity)
                                .foregroundColor(.furgDanger)
                                .padding(12)
                                .background(Color.furgDanger.opacity(0.2))
                                .cornerRadius(10)
                            }
                        }
                        .padding(.horizontal, 20)

                        Spacer(minLength: 40)
                    }
                    .padding(.vertical, 20)
                }
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                        .foregroundColor(.furgMint)
                }
            }
        }
    }
}

struct ImpactMetric: View {
    let label: String
    let value: String
    let valueColor: Color

    var body: some View {
        HStack {
            Text(label)
                .font(.system(size: 13))
                .foregroundColor(.white.opacity(0.6))

            Spacer()

            Text(value)
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(valueColor)
        }
    }
}

#Preview {
    LifeIntegrationView()
        .environmentObject(FinanceManager())
}
