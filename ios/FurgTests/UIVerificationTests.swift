//
//  UIVerificationTests.swift
//  FurgTests
//
//  UI Verification Tests - Automated view rendering checks
//

import XCTest
import SwiftUI
@testable import Furg

final class UIVerificationTests: XCTestCase {

    // MARK: - Test All Main Views

    func testAllViews() {
        // Core navigation views
        testMainTabView()
        testToolsHubView()
        testDashboardView()
        testSettingsView()

        // Transaction & Finance views
        testTransactionsListView()
        testCashFlowView()
        testIncomeTrackerView()

        // Premium features
        testCardRecommendationsView()
        testFinancialHealthView()
        testSpendingPredictionsView()
    }

    // MARK: - Individual View Tests

    func testMainTabView() {
        let authManager = AuthManager()
        let financeManager = FinanceManager()
        let chatManager = ChatManager()
        let plaidManager = PlaidManager()
        let goalsManager = GoalsManager()

        let view = MainTabView()
            .environmentObject(authManager)
            .environmentObject(financeManager)
            .environmentObject(chatManager)
            .environmentObject(plaidManager)
            .environmentObject(goalsManager)

        UIVerifier.verifyView(view, name: "MainTabView")
    }

    func testToolsHubView() {
        let financeManager = FinanceManager()

        let view = ToolsHubView()
            .environmentObject(financeManager)

        UIVerifier.verifyView(view, name: "ToolsHubView")
    }

    func testDashboardView() {
        let financeManager = FinanceManager()

        let view = DashboardView()
            .environmentObject(financeManager)

        UIVerifier.verifyView(view, name: "DashboardView")
    }

    func testSettingsView() {
        let authManager = AuthManager()

        let view = SettingsView()
            .environmentObject(authManager)

        UIVerifier.verifyView(view, name: "SettingsView")
    }

    func testTransactionsListView() {
        let financeManager = FinanceManager()

        let view = TransactionsListView()
            .environmentObject(financeManager)

        UIVerifier.verifyView(view, name: "TransactionsListView")
    }

    func testCashFlowView() {
        let financeManager = FinanceManager()

        let view = CashFlowView()
            .environmentObject(financeManager)

        UIVerifier.verifyView(view, name: "CashFlowView")
    }

    func testIncomeTrackerView() {
        let financeManager = FinanceManager()

        let view = IncomeTrackerView()
            .environmentObject(financeManager)

        UIVerifier.verifyView(view, name: "IncomeTrackerView")
    }

    func testCardRecommendationsView() {
        let financeManager = FinanceManager()

        let view = CardRecommendationsView()
            .environmentObject(financeManager)

        UIVerifier.verifyView(view, name: "CardRecommendationsView")
    }

    func testFinancialHealthView() {
        let financeManager = FinanceManager()

        let view = FinancialHealthView()
            .environmentObject(financeManager)

        UIVerifier.verifyView(view, name: "FinancialHealthView")
    }

    func testSpendingPredictionsView() {
        let financeManager = FinanceManager()

        let view = SpendingPredictionsView()
            .environmentObject(financeManager)

        UIVerifier.verifyView(view, name: "SpendingPredictionsView")
    }

    // MARK: - Template for Adding New Views
    /*
    func testYourNewView() {
        // Create required managers
        let financeManager = FinanceManager()

        let view = YourNewView()
            .environmentObject(financeManager)

        UIVerifier.verifyView(view, name: "YourNewView")
    }
    */
}
