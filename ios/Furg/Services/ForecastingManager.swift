//
//  ForecastingManager.swift
//  Furg
//
//  Cash flow forecasting and predictions
//

import Foundation

@MainActor
class ForecastingManager: ObservableObject {
    @Published var forecast: CashFlowForecast?
    @Published var dailyProjections: [DailyProjection] = []
    @Published var alerts: [ForecastAlert] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let apiClient = APIClient()

    // MARK: - Demo Data

    var demoForecast: CashFlowForecast {
        let today = Date()
        let calendar = Calendar.current

        return CashFlowForecast(
            currentBalance: 2850.00,
            projectedBalance30Days: 1420.00,
            projectedBalance60Days: 980.00,
            projectedBalance90Days: 1650.00,
            expectedIncome: 4800.00,
            expectedExpenses: 3200.00,
            expectedBills: 1450.00,
            safeToSpend: 1200.00,
            lowestProjectedBalance: 680.00,
            lowestBalanceDate: calendar.date(byAdding: .day, value: 28, to: today) ?? today,
            nextPayday: calendar.date(byAdding: .day, value: 12, to: today) ?? today,
            daysUntilPayday: 12
        )
    }

    var demoDailyProjections: [DailyProjection] {
        let calendar = Calendar.current
        let today = Date()

        return (0..<30).map { dayOffset in
            let date = calendar.date(byAdding: .day, value: dayOffset, to: today) ?? today

            // Simulate balance fluctuation
            let baseBalance = 2850.0
            let dailySpend = Double.random(in: 50...150)
            let isBillDay = dayOffset % 7 == 5
            let isPayday = dayOffset == 14

            var balance = baseBalance - (Double(dayOffset) * dailySpend)
            if isBillDay { balance -= 200 }
            if isPayday { balance += 2400 }

            return DailyProjection(
                date: date,
                projectedBalance: Decimal(max(balance, 200)),
                income: isPayday ? 2400 : 0,
                expenses: Decimal(dailySpend + (isBillDay ? 200 : 0)),
                bills: isBillDay ? [ProjectedBill(name: "Rent", amount: 200, dueDate: date)] : [],
                confidence: dayOffset < 7 ? 0.95 : (dayOffset < 14 ? 0.85 : 0.7)
            )
        }
    }

    var demoAlerts: [ForecastAlert] {
        let calendar = Calendar.current
        let today = Date()

        return [
            ForecastAlert(
                id: "1",
                type: .lowBalance,
                title: "Low Balance Warning",
                message: "Your balance may drop to $680 in 28 days. Consider reducing spending.",
                date: calendar.date(byAdding: .day, value: 28, to: today) ?? today,
                severity: .warning,
                actionLabel: "View Details"
            ),
            ForecastAlert(
                id: "2",
                type: .billDue,
                title: "Rent Due Soon",
                message: "Your rent payment of $1,200 is due in 5 days.",
                date: calendar.date(byAdding: .day, value: 5, to: today) ?? today,
                severity: .info,
                actionLabel: "Set Reminder"
            ),
            ForecastAlert(
                id: "3",
                type: .payday,
                title: "Payday Coming",
                message: "Expected deposit of $2,400 in 12 days.",
                date: calendar.date(byAdding: .day, value: 12, to: today) ?? today,
                severity: .positive,
                actionLabel: nil
            )
        ]
    }

    // MARK: - Load Data

    func loadForecast() async {
        isLoading = true
        defer { isLoading = false }

        do {
            forecast = try await apiClient.getForecast()
        } catch {
            forecast = demoForecast
        }
    }

    func loadDailyProjections(days: Int = 30) async {
        do {
            dailyProjections = try await apiClient.getDailyProjections(days: days)
        } catch {
            dailyProjections = demoDailyProjections
        }
    }

    func loadAlerts() async {
        do {
            alerts = try await apiClient.getForecastAlerts()
        } catch {
            alerts = demoAlerts
        }
    }

    func refreshAll() async {
        await loadForecast()
        await loadDailyProjections()
        await loadAlerts()
    }

    // MARK: - Calculations

    func calculateSafeToSpend(until date: Date) -> Decimal {
        guard let forecast = forecast else { return 0 }

        let projections = dailyProjections.filter { $0.date <= date }
        let totalBills = projections.flatMap { $0.bills }.reduce(Decimal(0)) { $0 + $1.amount }
        let buffer: Decimal = 500 // Safety buffer

        return max(0, forecast.currentBalance - totalBills - buffer)
    }

    func wouldCauseLowBalance(spending: Decimal, by date: Date) -> Bool {
        let safeAmount = calculateSafeToSpend(until: date)
        return spending > safeAmount
    }
}

// MARK: - Models

struct CashFlowForecast: Codable {
    let currentBalance: Decimal
    let projectedBalance30Days: Decimal
    let projectedBalance60Days: Decimal
    let projectedBalance90Days: Decimal
    let expectedIncome: Decimal
    let expectedExpenses: Decimal
    let expectedBills: Decimal
    let safeToSpend: Decimal
    let lowestProjectedBalance: Decimal
    let lowestBalanceDate: Date
    let nextPayday: Date
    let daysUntilPayday: Int

    enum CodingKeys: String, CodingKey {
        case currentBalance = "current_balance"
        case projectedBalance30Days = "projected_balance_30_days"
        case projectedBalance60Days = "projected_balance_60_days"
        case projectedBalance90Days = "projected_balance_90_days"
        case expectedIncome = "expected_income"
        case expectedExpenses = "expected_expenses"
        case expectedBills = "expected_bills"
        case safeToSpend = "safe_to_spend"
        case lowestProjectedBalance = "lowest_projected_balance"
        case lowestBalanceDate = "lowest_balance_date"
        case nextPayday = "next_payday"
        case daysUntilPayday = "days_until_payday"
    }
}

struct DailyProjection: Identifiable, Codable {
    var id: Date { date }
    let date: Date
    let projectedBalance: Decimal
    let income: Decimal
    let expenses: Decimal
    let bills: [ProjectedBill]
    let confidence: Double

    enum CodingKeys: String, CodingKey {
        case date
        case projectedBalance = "projected_balance"
        case income, expenses, bills, confidence
    }
}

struct ProjectedBill: Identifiable, Codable {
    var id: String { name + dueDate.description }
    let name: String
    let amount: Decimal
    let dueDate: Date

    enum CodingKeys: String, CodingKey {
        case name, amount
        case dueDate = "due_date"
    }
}

struct ForecastAlert: Identifiable, Codable {
    let id: String
    let type: AlertType
    let title: String
    let message: String
    let date: Date
    let severity: AlertSeverity
    let actionLabel: String?
    var actionType: ForecastActionType {
        switch type {
        case .lowBalance: return .showBalance
        case .billDue: return .showBills
        case .payday: return .none
        case .overdraft: return .showBalance
        case .goalMilestone: return .showGoals
        case .unusualSpending: return .showCategories
        }
    }

    enum CodingKeys: String, CodingKey {
        case id, type, title, message, date, severity
        case actionLabel = "action_label"
    }
}

enum ForecastActionType {
    case showBalance
    case showBills
    case showGoals
    case showCategories
    case none
}

enum AlertType: String, Codable {
    case lowBalance = "low_balance"
    case billDue = "bill_due"
    case payday
    case overdraft
    case goalMilestone = "goal_milestone"
    case unusualSpending = "unusual_spending"
}

enum AlertSeverity: String, Codable {
    case info
    case warning
    case critical
    case positive
}

// MARK: - API Client Extensions

extension APIClient {
    func getForecast() async throws -> CashFlowForecast {
        let response: ForecastAPIResponse = try await get("/forecast")
        return response.toCashFlowForecast()
    }

    func getDailyProjections(days: Int) async throws -> [DailyProjection] {
        let response: DailyProjectionsAPIResponse = try await get("/forecast/daily?days=\(days)")
        return response.projections.map { projection in
            DailyProjection(
                date: ISO8601DateFormatter().date(from: projection.date) ?? Date(),
                projectedBalance: Decimal(projection.projectedBalance),
                income: 0,
                expenses: Decimal(projection.billsDue),
                bills: projection.bills.map { bill in
                    ProjectedBill(
                        name: bill.merchant ?? "Unknown",
                        amount: Decimal(bill.amount ?? 0),
                        dueDate: Date()
                    )
                },
                confidence: 0.8
            )
        }
    }

    func getForecastAlerts() async throws -> [ForecastAlert] {
        let response: ForecastAlertsAPIResponse = try await get("/forecast/alerts")
        return response.alerts.enumerated().map { index, alert in
            ForecastAlert(
                id: "\(index)",
                type: alert.alertType,
                title: alert.title,
                message: alert.message,
                date: Date(),
                severity: alert.alertSeverity,
                actionLabel: alert.action
            )
        }
    }
}

// MARK: - API Response Models

struct ForecastAPIResponse: Codable {
    let currentBalance: Double
    let projectedBalance: Double
    let daysForecast: Int
    let avgMonthlyIncome: Double
    let avgMonthlyExpenses: Double
    let netMonthly: Double
    let riskLevel: String
    let riskMessage: String
    let runwayDays: Int

    enum CodingKeys: String, CodingKey {
        case currentBalance = "current_balance"
        case projectedBalance = "projected_balance"
        case daysForecast = "days_forecast"
        case avgMonthlyIncome = "avg_monthly_income"
        case avgMonthlyExpenses = "avg_monthly_expenses"
        case netMonthly = "net_monthly"
        case riskLevel = "risk_level"
        case riskMessage = "risk_message"
        case runwayDays = "runway_days"
    }

    func toCashFlowForecast() -> CashFlowForecast {
        CashFlowForecast(
            currentBalance: Decimal(currentBalance),
            projectedBalance30Days: Decimal(projectedBalance),
            projectedBalance60Days: Decimal(projectedBalance * 1.5),
            projectedBalance90Days: Decimal(projectedBalance * 2),
            expectedIncome: Decimal(avgMonthlyIncome),
            expectedExpenses: Decimal(avgMonthlyExpenses),
            expectedBills: Decimal(avgMonthlyExpenses * 0.4),
            safeToSpend: Decimal(max(0, currentBalance - avgMonthlyExpenses * 0.5)),
            lowestProjectedBalance: Decimal(min(currentBalance, projectedBalance)),
            lowestBalanceDate: Calendar.current.date(byAdding: .day, value: 14, to: Date()) ?? Date(),
            nextPayday: Calendar.current.date(byAdding: .day, value: 7, to: Date()) ?? Date(),
            daysUntilPayday: 7
        )
    }
}

struct DailyProjectionsAPIResponse: Codable {
    let projections: [DailyProjectionAPI]
    let lowestPoint: Double
    let lowestDate: String

    enum CodingKeys: String, CodingKey {
        case projections
        case lowestPoint = "lowest_point"
        case lowestDate = "lowest_date"
    }
}

struct DailyProjectionAPI: Codable {
    let date: String
    let projectedBalance: Double
    let billsDue: Double
    let bills: [BillAPI]
    let isLow: Bool

    enum CodingKeys: String, CodingKey {
        case date
        case projectedBalance = "projected_balance"
        case billsDue = "bills_due"
        case bills
        case isLow = "is_low"
    }
}

struct BillAPI: Codable {
    let merchant: String?
    let amount: Double?
}

struct ForecastAlertsAPIResponse: Codable {
    let alerts: [ForecastAlertAPI]
    let riskLevel: String

    enum CodingKeys: String, CodingKey {
        case alerts
        case riskLevel = "risk_level"
    }
}

struct ForecastAlertAPI: Codable {
    let type: String
    let title: String
    let message: String
    let action: String?

    var alertType: AlertType {
        switch type {
        case "danger": return .overdraft
        case "warning": return .lowBalance
        case "info": return .billDue
        case "success": return .payday
        default: return .lowBalance
        }
    }

    var alertSeverity: AlertSeverity {
        switch type {
        case "danger": return .critical
        case "warning": return .warning
        case "info": return .info
        case "success": return .positive
        default: return .info
        }
    }
}
