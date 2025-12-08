//
//  SpendingPredictionsView.swift
//  Furg
//
//  AI-powered spending predictions based on seasonal patterns
//

import SwiftUI
import Charts

struct SpendingPredictionsView: View {
    @StateObject private var predictionManager = SpendingPredictionManager.shared
    @State private var selectedPeriod: PredictionPeriod = .thisMonth
    @State private var animate = false

    var body: some View {
        NavigationStack {
            ZStack {
                Color.furgCharcoal.ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 24) {
                        // Period Selector
                        periodSelector
                            .opacity(animate ? 1 : 0)
                            .offset(y: animate ? 0 : 20)

                        // Main Prediction Card
                        if let prediction = predictionManager.currentPredictions.first(where: { $0.period == selectedPeriod }) {
                            mainPredictionCard(prediction)
                                .opacity(animate ? 1 : 0)
                                .offset(y: animate ? 0 : 20)
                                .animation(.spring(response: 0.6).delay(0.1), value: animate)
                        }

                        // Seasonal Alerts
                        if !predictionManager.seasonalAlerts.isEmpty {
                            seasonalAlertsSection
                                .opacity(animate ? 1 : 0)
                                .offset(y: animate ? 0 : 20)
                                .animation(.spring(response: 0.6).delay(0.15), value: animate)
                        }

                        // Category Predictions
                        categoryPredictionsSection
                            .opacity(animate ? 1 : 0)
                            .offset(y: animate ? 0 : 20)
                            .animation(.spring(response: 0.6).delay(0.2), value: animate)

                        // Upcoming Events
                        upcomingEventsSection
                            .opacity(animate ? 1 : 0)
                            .offset(y: animate ? 0 : 20)
                            .animation(.spring(response: 0.6).delay(0.25), value: animate)

                        // Contributing Factors
                        if let prediction = predictionManager.currentPredictions.first(where: { $0.period == selectedPeriod }) {
                            factorsSection(prediction.factors)
                                .opacity(animate ? 1 : 0)
                                .offset(y: animate ? 0 : 20)
                                .animation(.spring(response: 0.6).delay(0.3), value: animate)
                        }

                        Spacer(minLength: 100)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                }
            }
            .navigationTitle("Predictions")
            .navigationBarTitleDisplayMode(.large)
            .onAppear {
                withAnimation(.spring(response: 0.6)) {
                    animate = true
                }
                predictionManager.generatePredictions()
            }
        }
    }

    // MARK: - Period Selector

    private var periodSelector: some View {
        HStack(spacing: 8) {
            ForEach(PredictionPeriod.allCases, id: \.self) { period in
                Button {
                    withAnimation(.spring(response: 0.3)) {
                        selectedPeriod = period
                    }
                } label: {
                    Text(period.rawValue)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(selectedPeriod == period ? .furgCharcoal : .white.opacity(0.7))
                        .padding(.horizontal, 14)
                        .padding(.vertical, 10)
                        .background(selectedPeriod == period ? Color.furgMint : Color.white.opacity(0.08))
                        .clipShape(Capsule())
                }
            }
        }
    }

    // MARK: - Main Prediction Card

    private func mainPredictionCard(_ prediction: SpendingPrediction) -> some View {
        VStack(spacing: 20) {
            // Predicted vs Historical
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Predicted Spending")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.white.opacity(0.6))

                    Text("$\(Int(prediction.predictedAmount))")
                        .font(.system(size: 36, weight: .bold, design: .rounded))
                        .foregroundColor(.white)

                    // Variance indicator
                    HStack(spacing: 4) {
                        Image(systemName: prediction.variance > 0 ? "arrow.up.right" : "arrow.down.right")
                            .font(.system(size: 10, weight: .bold))

                        Text("\(abs(Int(prediction.variance)))% vs average")
                            .font(.system(size: 12, weight: .medium))
                    }
                    .foregroundColor(prediction.variance > 10 ? .furgWarning : (prediction.variance < -10 ? .furgSuccess : .white.opacity(0.6)))
                }

                Spacer()

                // Confidence meter
                VStack(alignment: .trailing, spacing: 4) {
                    Text("Confidence")
                        .font(.system(size: 11))
                        .foregroundColor(.white.opacity(0.5))

                    ZStack {
                        Circle()
                            .stroke(Color.white.opacity(0.1), lineWidth: 4)
                            .frame(width: 50, height: 50)

                        Circle()
                            .trim(from: 0, to: prediction.confidence)
                            .stroke(Color.furgMint, lineWidth: 4)
                            .frame(width: 50, height: 50)
                            .rotationEffect(.degrees(-90))

                        Text("\(Int(prediction.confidence * 100))%")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.furgMint)
                    }
                }
            }

            // Comparison bar
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Historical Average")
                        .font(.system(size: 11))
                        .foregroundColor(.white.opacity(0.5))
                    Spacer()
                    Text("$\(Int(prediction.historicalAverage))")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.white.opacity(0.7))
                }

                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.white.opacity(0.1))
                            .frame(height: 8)

                        // Historical marker
                        let historicalWidth = min(1, prediction.historicalAverage / max(prediction.predictedAmount, prediction.historicalAverage)) * geo.size.width
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.white.opacity(0.3))
                            .frame(width: historicalWidth, height: 8)

                        // Predicted marker
                        let predictedWidth = min(1, prediction.predictedAmount / max(prediction.predictedAmount, prediction.historicalAverage)) * geo.size.width
                        RoundedRectangle(cornerRadius: 4)
                            .fill(prediction.variance > 10 ? Color.furgWarning : Color.furgMint)
                            .frame(width: predictedWidth, height: 8)
                    }
                }
                .frame(height: 8)
            }

            // Recommendations
            if !prediction.recommendations.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(prediction.recommendations, id: \.self) { recommendation in
                        HStack(alignment: .top, spacing: 8) {
                            Text("•")
                                .foregroundColor(.furgMint)
                            Text(recommendation)
                                .font(.system(size: 12))
                                .foregroundColor(.white.opacity(0.8))
                        }
                    }
                }
                .padding(12)
                .background(Color.furgMint.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 10))
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color.white.opacity(0.1), lineWidth: 0.5)
                )
        )
    }

    // MARK: - Seasonal Alerts

    private var seasonalAlertsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundColor(.furgWarning)
                Text("Seasonal Alerts")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white.opacity(0.6))
            }

            ForEach(predictionManager.seasonalAlerts, id: \.self) { alert in
                HStack(spacing: 10) {
                    Text(alert)
                        .font(.system(size: 13))
                        .foregroundColor(.white.opacity(0.9))
                }
                .padding(12)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.furgWarning.opacity(0.15))
                .clipShape(RoundedRectangle(cornerRadius: 10))
            }
        }
    }

    // MARK: - Category Predictions

    private var categoryPredictionsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Category Outlook")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.white.opacity(0.6))

            ForEach(predictionManager.categoryPredictions.prefix(6)) { prediction in
                CategoryPredictionRow(prediction: prediction)
            }
        }
    }

    // MARK: - Upcoming Events

    private var upcomingEventsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "calendar")
                    .foregroundColor(.furgMint)
                Text("Upcoming Events")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white.opacity(0.6))
            }

            ForEach(predictionManager.upcomingEvents.prefix(5)) { event in
                UpcomingEventRow(event: event)
            }
        }
    }

    // MARK: - Factors Section

    private func factorsSection(_ factors: [PredictionFactor]) -> some View {
        guard !factors.isEmpty else { return AnyView(EmptyView()) }

        return AnyView(
            VStack(alignment: .leading, spacing: 12) {
                Text("Contributing Factors")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white.opacity(0.6))

                ForEach(factors) { factor in
                    FactorRow(factor: factor)
                }
            }
        )
    }
}

// MARK: - Supporting Views

struct CategoryPredictionRow: View {
    let prediction: CategoryPrediction

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: categoryIcon(prediction.category))
                .font(.system(size: 16))
                .foregroundColor(categoryColor(prediction.category))
                .frame(width: 40, height: 40)
                .background(categoryColor(prediction.category).opacity(0.2))
                .clipShape(RoundedRectangle(cornerRadius: 10))

            VStack(alignment: .leading, spacing: 4) {
                Text(prediction.category)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white)

                if !prediction.factors.isEmpty {
                    Text(prediction.factors.first ?? "")
                        .font(.system(size: 11))
                        .foregroundColor(.white.opacity(0.5))
                        .lineLimit(1)
                }
            }

            Spacer()

            HStack(spacing: 8) {
                Text("$\(Int(prediction.predictedAmount))")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.white)

                Image(systemName: prediction.trend.icon)
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(prediction.trend.color)
            }
        }
        .padding(12)
        .background(Color.white.opacity(0.05))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private func categoryIcon(_ category: String) -> String {
        switch category {
        case "Food & Dining": return "fork.knife"
        case "Shopping": return "bag.fill"
        case "Transportation": return "car.fill"
        case "Entertainment": return "film.fill"
        case "Utilities": return "bolt.fill"
        case "Travel": return "airplane"
        case "Health & Medical": return "heart.fill"
        default: return "dollarsign.circle.fill"
        }
    }

    private func categoryColor(_ category: String) -> Color {
        switch category {
        case "Food & Dining": return .orange
        case "Shopping": return .pink
        case "Transportation": return .blue
        case "Entertainment": return .purple
        case "Utilities": return .yellow
        case "Travel": return .cyan
        case "Health & Medical": return .red
        default: return .gray
        }
    }
}

struct UpcomingEventRow: View {
    let event: UpcomingEvent

    var body: some View {
        HStack(spacing: 14) {
            VStack {
                Text(dayOfWeek(event.date))
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(.white.opacity(0.5))
                Text(dayNumber(event.date))
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.white)
            }
            .frame(width: 44)

            VStack(alignment: .leading, spacing: 4) {
                Text(event.name)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white)

                Text(event.description)
                    .font(.system(size: 11))
                    .foregroundColor(.white.opacity(0.5))
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                Text("+$\(Int(event.expectedImpact))")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.furgWarning)

                Text(event.category)
                    .font(.system(size: 10))
                    .foregroundColor(.white.opacity(0.4))
            }
        }
        .padding(12)
        .background(Color.white.opacity(0.05))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private func dayOfWeek(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE"
        return formatter.string(from: date).uppercased()
    }

    private func dayNumber(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "d"
        return formatter.string(from: date)
    }
}

struct FactorRow: View {
    let factor: PredictionFactor

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: factor.icon)
                .font(.system(size: 16))
                .foregroundColor(factor.impact > 0 ? .furgWarning : .furgSuccess)
                .frame(width: 36, height: 36)
                .background((factor.impact > 0 ? Color.furgWarning : Color.furgSuccess).opacity(0.2))
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: 2) {
                Text(factor.name)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white)

                Text(factor.description)
                    .font(.system(size: 11))
                    .foregroundColor(.white.opacity(0.5))
            }

            Spacer()

            Text(factor.impact > 0 ? "+$\(Int(factor.impact))" : "-$\(Int(abs(factor.impact)))")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(factor.impact > 0 ? .furgWarning : .furgSuccess)
        }
        .padding(12)
        .background(Color.white.opacity(0.05))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

#Preview {
    SpendingPredictionsView()
}
