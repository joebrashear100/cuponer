//
//  DataExportManager.swift
//  Furg
//
//  Export financial data to PDF and CSV formats
//

import Foundation
import SwiftUI
import PDFKit
import UniformTypeIdentifiers

// MARK: - Models

enum ExportFormat: String, CaseIterable {
    case csv = "CSV"
    case pdf = "PDF"

    var fileExtension: String {
        rawValue.lowercased()
    }

    var utType: UTType {
        switch self {
        case .csv: return .commaSeparatedText
        case .pdf: return .pdf
        }
    }
}

enum ExportDataType: String, CaseIterable {
    case transactions = "Transactions"
    case budget = "Budget Summary"
    case categories = "Category Breakdown"
    case subscriptions = "Subscriptions"
    case debts = "Debt Summary"
    case income = "Income Summary"
    case goals = "Savings Goals"
    case fullReport = "Full Financial Report"

    var icon: String {
        switch self {
        case .transactions: return "list.bullet.rectangle"
        case .budget: return "chart.pie.fill"
        case .categories: return "folder.fill"
        case .subscriptions: return "repeat.circle.fill"
        case .debts: return "creditcard.fill"
        case .income: return "arrow.down.circle.fill"
        case .goals: return "target"
        case .fullReport: return "doc.text.fill"
        }
    }
}

struct ExportOptions {
    var dataType: ExportDataType = .transactions
    var format: ExportFormat = .csv
    var dateRange: DateRange = .thisMonth
    var includeCategories: Bool = true
    var includeMerchants: Bool = true
    var includeNotes: Bool = false

    enum DateRange: String, CaseIterable {
        case thisWeek = "This Week"
        case thisMonth = "This Month"
        case lastMonth = "Last Month"
        case last3Months = "Last 3 Months"
        case last6Months = "Last 6 Months"
        case thisYear = "This Year"
        case lastYear = "Last Year"
        case allTime = "All Time"
        case custom = "Custom Range"

        var dateInterval: (start: Date, end: Date) {
            let calendar = Calendar.current
            let now = Date()

            switch self {
            case .thisWeek:
                let start = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: now))!
                return (start, now)
            case .thisMonth:
                let start = calendar.date(from: calendar.dateComponents([.year, .month], from: now))!
                return (start, now)
            case .lastMonth:
                let start = calendar.date(byAdding: .month, value: -1, to: calendar.date(from: calendar.dateComponents([.year, .month], from: now))!)!
                let end = calendar.date(from: calendar.dateComponents([.year, .month], from: now))!
                return (start, end)
            case .last3Months:
                let start = calendar.date(byAdding: .month, value: -3, to: now)!
                return (start, now)
            case .last6Months:
                let start = calendar.date(byAdding: .month, value: -6, to: now)!
                return (start, now)
            case .thisYear:
                let start = calendar.date(from: calendar.dateComponents([.year], from: now))!
                return (start, now)
            case .lastYear:
                var components = calendar.dateComponents([.year], from: now)
                components.year! -= 1
                let start = calendar.date(from: components)!
                components.year! += 1
                let end = calendar.date(from: components)!
                return (start, end)
            case .allTime, .custom:
                return (Date.distantPast, now)
            }
        }
    }
}

struct ExportResult {
    let success: Bool
    let fileURL: URL?
    let fileName: String
    let error: String?
}

// MARK: - Data Export Manager

class DataExportManager: ObservableObject {
    static let shared = DataExportManager()

    @Published var isExporting = false
    @Published var exportProgress: Double = 0
    @Published var lastExportResult: ExportResult?

    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter
    }()

    private let currencyFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        return formatter
    }()

    // MARK: - Export Functions

    func export(options: ExportOptions, customStartDate: Date? = nil, customEndDate: Date? = nil) async -> ExportResult {
        await MainActor.run {
            isExporting = true
            exportProgress = 0
        }

        let dateRange = options.dateRange == .custom && customStartDate != nil && customEndDate != nil
            ? (customStartDate!, customEndDate!)
            : options.dateRange.dateInterval

        let result: ExportResult

        switch options.format {
        case .csv:
            result = await exportToCSV(dataType: options.dataType, dateRange: dateRange, options: options)
        case .pdf:
            result = await exportToPDF(dataType: options.dataType, dateRange: dateRange, options: options)
        }

        await MainActor.run {
            isExporting = false
            exportProgress = 1.0
            lastExportResult = result
        }

        return result
    }

    // MARK: - CSV Export

    private func exportToCSV(dataType: ExportDataType, dateRange: (Date, Date), options: ExportOptions) async -> ExportResult {
        await MainActor.run { exportProgress = 0.2 }

        var csvContent = ""

        switch dataType {
        case .transactions:
            csvContent = generateTransactionsCSV(dateRange: dateRange, options: options)
        case .budget:
            csvContent = generateBudgetCSV()
        case .categories:
            csvContent = generateCategoriesCSV(dateRange: dateRange)
        case .subscriptions:
            csvContent = generateSubscriptionsCSV()
        case .debts:
            csvContent = generateDebtsCSV()
        case .income:
            csvContent = generateIncomeCSV()
        case .goals:
            csvContent = generateGoalsCSV()
        case .fullReport:
            csvContent = generateFullReportCSV(dateRange: dateRange, options: options)
        }

        await MainActor.run { exportProgress = 0.8 }

        // Save to temp file
        let fileName = "Furg_\(dataType.rawValue.replacingOccurrences(of: " ", with: "_"))_\(formatDateForFileName(Date())).csv"
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)

        do {
            try csvContent.write(to: tempURL, atomically: true, encoding: .utf8)
            return ExportResult(success: true, fileURL: tempURL, fileName: fileName, error: nil)
        } catch {
            return ExportResult(success: false, fileURL: nil, fileName: fileName, error: error.localizedDescription)
        }
    }

    private func generateTransactionsCSV(dateRange: (Date, Date), options: ExportOptions) -> String {
        var csv = "Date,Merchant,Amount,Category,Account,Notes\n"

        let transactions = RealTimeTransactionManager.shared.recentTransactions.filter {
            $0.date >= dateRange.0 && $0.date <= dateRange.1
        }

        for transaction in transactions.sorted(by: { $0.date > $1.date }) {
            let date = dateFormatter.string(from: transaction.date)
            let merchant = escapeCSV(transaction.merchantName)
            let amount = String(format: "%.2f", transaction.amount)
            let category = options.includeCategories ? escapeCSV(transaction.category) : ""
            let account = escapeCSV(transaction.accountName)
            let notes = options.includeNotes ? "" : ""

            csv += "\(date),\(merchant),\(amount),\(category),\(account),\(notes)\n"
        }

        return csv
    }

    private func generateBudgetCSV() -> String {
        var csv = "Category,Budget,Spent,Remaining,Percent Used\n"

        // Demo data - in real app, pull from budget manager
        let budgetData = [
            ("Food & Dining", 600.0, 450.0),
            ("Shopping", 400.0, 380.0),
            ("Transportation", 200.0, 150.0),
            ("Entertainment", 150.0, 120.0),
            ("Utilities", 250.0, 245.0)
        ]

        for (category, budget, spent) in budgetData {
            let remaining = budget - spent
            let percentUsed = spent / budget * 100
            csv += "\(category),\(String(format: "%.2f", budget)),\(String(format: "%.2f", spent)),\(String(format: "%.2f", remaining)),\(String(format: "%.1f", percentUsed))%\n"
        }

        return csv
    }

    private func generateCategoriesCSV(dateRange: (Date, Date)) -> String {
        var csv = "Category,Total Spent,Transaction Count,Average Transaction\n"

        let transactions = RealTimeTransactionManager.shared.recentTransactions.filter {
            $0.date >= dateRange.0 && $0.date <= dateRange.1 && $0.amount < 0
        }

        let grouped = Dictionary(grouping: transactions) { $0.category }

        for (category, txns) in grouped.sorted(by: { $0.value.reduce(0) { $0 + abs($1.amount) } > $1.value.reduce(0) { $0 + abs($1.amount) } }) {
            let total = txns.reduce(0) { $0 + abs($1.amount) }
            let count = txns.count
            let average = total / Double(max(1, count))

            csv += "\(escapeCSV(category)),\(String(format: "%.2f", total)),\(count),\(String(format: "%.2f", average))\n"
        }

        return csv
    }

    private func generateSubscriptionsCSV() -> String {
        var csv = "Name,Category,Amount,Frequency,Annual Cost,Status\n"

        // Demo data
        let subscriptions = [
            ("Netflix", "Streaming", 15.99, "Monthly", "Active"),
            ("Spotify", "Music", 9.99, "Monthly", "Active"),
            ("Amazon Prime", "Shopping", 139.0, "Annual", "Active"),
            ("Adobe Creative Cloud", "Software", 54.99, "Monthly", "Active"),
            ("Gym Membership", "Fitness", 49.99, "Monthly", "Active")
        ]

        for (name, category, amount, frequency, status) in subscriptions {
            let annualCost = frequency == "Annual" ? amount : amount * 12
            csv += "\(escapeCSV(name)),\(category),\(String(format: "%.2f", amount)),\(frequency),\(String(format: "%.2f", annualCost)),\(status)\n"
        }

        return csv
    }

    private func generateDebtsCSV() -> String {
        var csv = "Name,Type,Original Balance,Current Balance,Interest Rate,Minimum Payment,Payoff Date\n"

        let debts = DebtPayoffManager.shared.debts

        for debt in debts {
            csv += "\(escapeCSV(debt.name)),\(debt.type.rawValue),\(String(format: "%.2f", debt.originalBalance)),\(String(format: "%.2f", debt.currentBalance)),\(String(format: "%.2f", debt.interestRate * 100))%,\(String(format: "%.2f", debt.minimumPayment)),\(dateFormatter.string(from: debt.payoffDate))\n"
        }

        return csv
    }

    private func generateIncomeCSV() -> String {
        var csv = "Source,Type,Amount,Frequency,Monthly Amount,Annual Amount\n"

        let sources = IncomeManager.shared.incomeSources

        for source in sources where source.isActive {
            csv += "\(escapeCSV(source.name)),\(source.type.rawValue),\(String(format: "%.2f", source.amount)),\(source.frequency.rawValue),\(String(format: "%.2f", source.monthlyAmount)),\(String(format: "%.2f", source.annualAmount))\n"
        }

        return csv
    }

    private func generateGoalsCSV() -> String {
        var csv = "Goal Name,Target Amount,Current Amount,Progress,Deadline\n"

        // Demo goals
        let goals = [
            ("Emergency Fund", 10000.0, 6500.0, "65%", "Dec 2025"),
            ("Vacation", 3000.0, 1200.0, "40%", "Jun 2025"),
            ("New Car", 15000.0, 4500.0, "30%", "Dec 2026")
        ]

        for (name, target, current, progress, deadline) in goals {
            csv += "\(escapeCSV(name)),\(String(format: "%.2f", target)),\(String(format: "%.2f", current)),\(progress),\(deadline)\n"
        }

        return csv
    }

    private func generateFullReportCSV(dateRange: (Date, Date), options: ExportOptions) -> String {
        var csv = "FURG FINANCIAL REPORT\n"
        csv += "Generated: \(dateFormatter.string(from: Date()))\n"
        csv += "Period: \(dateFormatter.string(from: dateRange.0)) - \(dateFormatter.string(from: dateRange.1))\n\n"

        csv += "=== INCOME SUMMARY ===\n"
        csv += generateIncomeCSV()
        csv += "\n"

        csv += "=== DEBT SUMMARY ===\n"
        csv += generateDebtsCSV()
        csv += "\n"

        csv += "=== BUDGET SUMMARY ===\n"
        csv += generateBudgetCSV()
        csv += "\n"

        csv += "=== CATEGORY BREAKDOWN ===\n"
        csv += generateCategoriesCSV(dateRange: dateRange)
        csv += "\n"

        csv += "=== SUBSCRIPTIONS ===\n"
        csv += generateSubscriptionsCSV()
        csv += "\n"

        csv += "=== SAVINGS GOALS ===\n"
        csv += generateGoalsCSV()

        return csv
    }

    // MARK: - PDF Export

    private func exportToPDF(dataType: ExportDataType, dateRange: (Date, Date), options: ExportOptions) async -> ExportResult {
        await MainActor.run { exportProgress = 0.2 }

        let pdfDocument = PDFDocument()
        let pageRect = CGRect(x: 0, y: 0, width: 612, height: 792) // Letter size

        // Create PDF renderer
        let renderer = UIGraphicsPDFRenderer(bounds: pageRect)

        let data = renderer.pdfData { context in
            context.beginPage()

            // Draw header
            drawPDFHeader(in: context.cgContext, rect: pageRect, title: "FURG Financial Report", subtitle: "\(dataType.rawValue)")

            // Draw content based on type
            switch dataType {
            case .transactions:
                drawTransactionsPDF(in: context.cgContext, rect: pageRect, dateRange: dateRange, options: options)
            case .budget:
                drawBudgetPDF(in: context.cgContext, rect: pageRect)
            case .debts:
                drawDebtsPDF(in: context.cgContext, rect: pageRect)
            case .income:
                drawIncomePDF(in: context.cgContext, rect: pageRect)
            case .fullReport:
                drawFullReportPDF(in: context, rect: pageRect, dateRange: dateRange, options: options)
            default:
                drawGenericPDF(in: context.cgContext, rect: pageRect, dataType: dataType)
            }

            // Draw footer
            drawPDFFooter(in: context.cgContext, rect: pageRect)
        }

        await MainActor.run { exportProgress = 0.8 }

        // Save to temp file
        let fileName = "Furg_\(dataType.rawValue.replacingOccurrences(of: " ", with: "_"))_\(formatDateForFileName(Date())).pdf"
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)

        do {
            try data.write(to: tempURL)
            return ExportResult(success: true, fileURL: tempURL, fileName: fileName, error: nil)
        } catch {
            return ExportResult(success: false, fileURL: nil, fileName: fileName, error: error.localizedDescription)
        }
    }

    private func drawPDFHeader(in context: CGContext, rect: CGRect, title: String, subtitle: String) {
        let titleFont = UIFont.systemFont(ofSize: 24, weight: .bold)
        let subtitleFont = UIFont.systemFont(ofSize: 14, weight: .medium)
        let dateFont = UIFont.systemFont(ofSize: 10, weight: .regular)

        let titleAttributes: [NSAttributedString.Key: Any] = [
            .font: titleFont,
            .foregroundColor: UIColor.black
        ]

        let subtitleAttributes: [NSAttributedString.Key: Any] = [
            .font: subtitleFont,
            .foregroundColor: UIColor.darkGray
        ]

        let dateAttributes: [NSAttributedString.Key: Any] = [
            .font: dateFont,
            .foregroundColor: UIColor.gray
        ]

        let titleString = NSAttributedString(string: title, attributes: titleAttributes)
        let subtitleString = NSAttributedString(string: subtitle, attributes: subtitleAttributes)
        let dateString = NSAttributedString(string: "Generated: \(dateFormatter.string(from: Date()))", attributes: dateAttributes)

        titleString.draw(at: CGPoint(x: 50, y: 50))
        subtitleString.draw(at: CGPoint(x: 50, y: 80))
        dateString.draw(at: CGPoint(x: 50, y: 100))

        // Draw separator line
        context.setStrokeColor(UIColor.lightGray.cgColor)
        context.setLineWidth(1)
        context.move(to: CGPoint(x: 50, y: 120))
        context.addLine(to: CGPoint(x: rect.width - 50, y: 120))
        context.strokePath()
    }

    private func drawPDFFooter(in context: CGContext, rect: CGRect) {
        let footerFont = UIFont.systemFont(ofSize: 9, weight: .regular)
        let footerAttributes: [NSAttributedString.Key: Any] = [
            .font: footerFont,
            .foregroundColor: UIColor.gray
        ]

        let footerString = NSAttributedString(string: "Generated by FURG - Your Financial Companion", attributes: footerAttributes)
        footerString.draw(at: CGPoint(x: 50, y: rect.height - 40))
    }

    private func drawTransactionsPDF(in context: CGContext, rect: CGRect, dateRange: (Date, Date), options: ExportOptions) {
        var yPosition: CGFloat = 140

        let headerFont = UIFont.systemFont(ofSize: 12, weight: .semibold)
        let bodyFont = UIFont.systemFont(ofSize: 10, weight: .regular)

        let headerAttributes: [NSAttributedString.Key: Any] = [.font: headerFont, .foregroundColor: UIColor.black]
        let bodyAttributes: [NSAttributedString.Key: Any] = [.font: bodyFont, .foregroundColor: UIColor.darkGray]

        // Table headers
        "Date".draw(at: CGPoint(x: 50, y: yPosition), withAttributes: headerAttributes)
        "Merchant".draw(at: CGPoint(x: 130, y: yPosition), withAttributes: headerAttributes)
        "Amount".draw(at: CGPoint(x: 320, y: yPosition), withAttributes: headerAttributes)
        "Category".draw(at: CGPoint(x: 400, y: yPosition), withAttributes: headerAttributes)

        yPosition += 20

        let transactions = RealTimeTransactionManager.shared.recentTransactions
            .filter { $0.date >= dateRange.0 && $0.date <= dateRange.1 }
            .sorted { $0.date > $1.date }
            .prefix(30)

        for transaction in transactions {
            let shortDate = DateFormatter()
            shortDate.dateFormat = "MM/dd"

            shortDate.string(from: transaction.date).draw(at: CGPoint(x: 50, y: yPosition), withAttributes: bodyAttributes)
            String(transaction.merchantName.prefix(25)).draw(at: CGPoint(x: 130, y: yPosition), withAttributes: bodyAttributes)

            let amountColor = transaction.amount < 0 ? UIColor.red : UIColor.systemGreen
            let amountAttributes: [NSAttributedString.Key: Any] = [.font: bodyFont, .foregroundColor: amountColor]
            String(format: "$%.2f", transaction.amount).draw(at: CGPoint(x: 320, y: yPosition), withAttributes: amountAttributes)

            String(transaction.category.prefix(15)).draw(at: CGPoint(x: 400, y: yPosition), withAttributes: bodyAttributes)

            yPosition += 18

            if yPosition > rect.height - 60 {
                break
            }
        }
    }

    private func drawBudgetPDF(in context: CGContext, rect: CGRect) {
        var yPosition: CGFloat = 140

        let headerFont = UIFont.systemFont(ofSize: 12, weight: .semibold)
        let bodyFont = UIFont.systemFont(ofSize: 10, weight: .regular)

        let headerAttributes: [NSAttributedString.Key: Any] = [.font: headerFont, .foregroundColor: UIColor.black]
        let bodyAttributes: [NSAttributedString.Key: Any] = [.font: bodyFont, .foregroundColor: UIColor.darkGray]

        "Category".draw(at: CGPoint(x: 50, y: yPosition), withAttributes: headerAttributes)
        "Budget".draw(at: CGPoint(x: 200, y: yPosition), withAttributes: headerAttributes)
        "Spent".draw(at: CGPoint(x: 280, y: yPosition), withAttributes: headerAttributes)
        "Remaining".draw(at: CGPoint(x: 360, y: yPosition), withAttributes: headerAttributes)
        "Used".draw(at: CGPoint(x: 450, y: yPosition), withAttributes: headerAttributes)

        yPosition += 25

        let budgetData = [
            ("Food & Dining", 600.0, 450.0),
            ("Shopping", 400.0, 380.0),
            ("Transportation", 200.0, 150.0),
            ("Entertainment", 150.0, 120.0),
            ("Utilities", 250.0, 245.0)
        ]

        for (category, budget, spent) in budgetData {
            category.draw(at: CGPoint(x: 50, y: yPosition), withAttributes: bodyAttributes)
            String(format: "$%.0f", budget).draw(at: CGPoint(x: 200, y: yPosition), withAttributes: bodyAttributes)
            String(format: "$%.0f", spent).draw(at: CGPoint(x: 280, y: yPosition), withAttributes: bodyAttributes)
            String(format: "$%.0f", budget - spent).draw(at: CGPoint(x: 360, y: yPosition), withAttributes: bodyAttributes)
            String(format: "%.0f%%", spent / budget * 100).draw(at: CGPoint(x: 450, y: yPosition), withAttributes: bodyAttributes)

            yPosition += 20
        }
    }

    private func drawDebtsPDF(in context: CGContext, rect: CGRect) {
        var yPosition: CGFloat = 140

        let titleFont = UIFont.systemFont(ofSize: 14, weight: .bold)
        let bodyFont = UIFont.systemFont(ofSize: 10, weight: .regular)

        let titleAttributes: [NSAttributedString.Key: Any] = [.font: titleFont, .foregroundColor: UIColor.black]
        let bodyAttributes: [NSAttributedString.Key: Any] = [.font: bodyFont, .foregroundColor: UIColor.darkGray]

        let debts = DebtPayoffManager.shared.debts

        // Summary
        "Total Debt: \(String(format: "$%.2f", DebtPayoffManager.shared.totalDebt))".draw(at: CGPoint(x: 50, y: yPosition), withAttributes: titleAttributes)
        yPosition += 30

        for debt in debts {
            debt.name.draw(at: CGPoint(x: 50, y: yPosition), withAttributes: titleAttributes)
            yPosition += 18
            "Balance: \(String(format: "$%.2f", debt.currentBalance)) | APR: \(String(format: "%.1f%%", debt.interestRate * 100)) | Min: \(String(format: "$%.2f", debt.minimumPayment))".draw(at: CGPoint(x: 50, y: yPosition), withAttributes: bodyAttributes)
            yPosition += 25
        }
    }

    private func drawIncomePDF(in context: CGContext, rect: CGRect) {
        var yPosition: CGFloat = 140

        let titleFont = UIFont.systemFont(ofSize: 14, weight: .bold)
        let bodyFont = UIFont.systemFont(ofSize: 10, weight: .regular)

        let titleAttributes: [NSAttributedString.Key: Any] = [.font: titleFont, .foregroundColor: UIColor.black]
        let bodyAttributes: [NSAttributedString.Key: Any] = [.font: bodyFont, .foregroundColor: UIColor.darkGray]

        let income = IncomeManager.shared

        "Total Monthly Income: \(String(format: "$%.2f", income.totalMonthlyIncome))".draw(at: CGPoint(x: 50, y: yPosition), withAttributes: titleAttributes)
        yPosition += 30

        for source in income.incomeSources where source.isActive {
            source.name.draw(at: CGPoint(x: 50, y: yPosition), withAttributes: titleAttributes)
            yPosition += 18
            "\(source.type.rawValue) | \(source.frequency.rawValue) | \(String(format: "$%.2f", source.amount))".draw(at: CGPoint(x: 50, y: yPosition), withAttributes: bodyAttributes)
            yPosition += 25
        }
    }

    private func drawGenericPDF(in context: CGContext, rect: CGRect, dataType: ExportDataType) {
        let bodyFont = UIFont.systemFont(ofSize: 12, weight: .regular)
        let bodyAttributes: [NSAttributedString.Key: Any] = [.font: bodyFont, .foregroundColor: UIColor.darkGray]

        "Data export for \(dataType.rawValue)".draw(at: CGPoint(x: 50, y: 150), withAttributes: bodyAttributes)
    }

    private func drawFullReportPDF(in context: UIGraphicsPDFRendererContext, rect: CGRect, dateRange: (Date, Date), options: ExportOptions) {
        // Page 1 - Summary
        drawTransactionsPDF(in: context.cgContext, rect: rect, dateRange: dateRange, options: options)

        // Page 2 - Budget
        context.beginPage()
        drawPDFHeader(in: context.cgContext, rect: rect, title: "FURG Financial Report", subtitle: "Budget Summary")
        drawBudgetPDF(in: context.cgContext, rect: rect)
        drawPDFFooter(in: context.cgContext, rect: rect)

        // Page 3 - Debts
        context.beginPage()
        drawPDFHeader(in: context.cgContext, rect: rect, title: "FURG Financial Report", subtitle: "Debt Summary")
        drawDebtsPDF(in: context.cgContext, rect: rect)
        drawPDFFooter(in: context.cgContext, rect: rect)

        // Page 4 - Income
        context.beginPage()
        drawPDFHeader(in: context.cgContext, rect: rect, title: "FURG Financial Report", subtitle: "Income Summary")
        drawIncomePDF(in: context.cgContext, rect: rect)
        drawPDFFooter(in: context.cgContext, rect: rect)
    }

    // MARK: - Helpers

    private func escapeCSV(_ string: String) -> String {
        if string.contains(",") || string.contains("\"") || string.contains("\n") {
            return "\"\(string.replacingOccurrences(of: "\"", with: "\"\""))\""
        }
        return string
    }

    private func formatDateForFileName(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }
}
