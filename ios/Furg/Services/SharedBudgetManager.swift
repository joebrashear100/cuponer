//
//  SharedBudgetManager.swift
//  Furg
//
//  Shared budgets and goals for couples, families, and groups
//

import Foundation
import SwiftUI
import Combine

// MARK: - Models

struct SharedBudget: Identifiable, Codable {
    let id: UUID
    var name: String
    var type: SharedBudgetType
    var members: [BudgetMember]
    var categories: [SharedCategory]
    var totalBudget: Double
    var currentSpending: Double
    var startDate: Date
    var endDate: Date?
    var isActive: Bool
    var icon: String
    var color: String
    var createdBy: UUID
    let createdAt: Date

    var remainingBudget: Double {
        totalBudget - currentSpending
    }

    var percentUsed: Double {
        guard totalBudget > 0 else { return 0 }
        return currentSpending / totalBudget
    }

    var memberCount: Int {
        members.count
    }
}

enum SharedBudgetType: String, Codable, CaseIterable {
    case couple = "Couple"
    case family = "Family"
    case roommates = "Roommates"
    case trip = "Trip"
    case event = "Event"
    case project = "Project"
    case custom = "Custom"

    var icon: String {
        switch self {
        case .couple: return "heart.fill"
        case .family: return "figure.2.and.child.holdinghands"
        case .roommates: return "house.fill"
        case .trip: return "airplane"
        case .event: return "party.popper.fill"
        case .project: return "hammer.fill"
        case .custom: return "folder.fill"
        }
    }

    var defaultColor: String {
        switch self {
        case .couple: return "pink"
        case .family: return "blue"
        case .roommates: return "green"
        case .trip: return "cyan"
        case .event: return "purple"
        case .project: return "orange"
        case .custom: return "gray"
        }
    }
}

struct BudgetMember: Identifiable, Codable {
    let id: UUID
    var name: String
    var email: String?
    var role: MemberRole
    var contributionPercent: Double
    var totalContributed: Double
    var totalSpent: Double
    var avatar: String?
    var isCurrentUser: Bool
    let joinedAt: Date

    var balance: Double {
        totalContributed - totalSpent
    }
}

enum MemberRole: String, Codable, CaseIterable {
    case owner = "Owner"
    case admin = "Admin"
    case member = "Member"
    case viewer = "Viewer"

    var canEdit: Bool {
        self == .owner || self == .admin
    }

    var canAddExpenses: Bool {
        self != .viewer
    }
}

struct SharedCategory: Identifiable, Codable {
    let id: UUID
    var name: String
    var budgetAmount: Double
    var currentSpending: Double
    var icon: String
    var color: String

    var percentUsed: Double {
        guard budgetAmount > 0 else { return 0 }
        return currentSpending / budgetAmount
    }

    var remaining: Double {
        budgetAmount - currentSpending
    }
}

struct SharedExpense: Identifiable, Codable {
    let id: UUID
    let budgetId: UUID
    let categoryId: UUID?
    let memberId: UUID
    var description: String
    var amount: Double
    var date: Date
    var splitType: SplitType
    var splits: [ExpenseSplit]
    var receipt: String? // URL or local path
    var notes: String?
    var isSettled: Bool
    let createdAt: Date
}

enum SplitType: String, Codable, CaseIterable {
    case equal = "Split Equally"
    case percentage = "By Percentage"
    case exact = "Exact Amounts"
    case paidByOne = "One Pays All"

    var icon: String {
        switch self {
        case .equal: return "equal.circle.fill"
        case .percentage: return "percent"
        case .exact: return "number.circle.fill"
        case .paidByOne: return "person.fill"
        }
    }
}

struct ExpenseSplit: Identifiable, Codable {
    let id: UUID
    let memberId: UUID
    var amount: Double
    var isPaid: Bool
    var paidDate: Date?
}

struct SharedGoal: Identifiable, Codable {
    let id: UUID
    let budgetId: UUID
    var name: String
    var targetAmount: Double
    var currentAmount: Double
    var deadline: Date?
    var contributions: [SharedGoalContribution]
    var icon: String
    var color: String
    var isCompleted: Bool

    var percentComplete: Double {
        guard targetAmount > 0 else { return 0 }
        return min(1, currentAmount / targetAmount)
    }

    var remaining: Double {
        max(0, targetAmount - currentAmount)
    }
}

struct SharedGoalContribution: Identifiable, Codable {
    let id: UUID
    let memberId: UUID
    let amount: Double
    let date: Date
    let notes: String?
}

struct SettlementSummary: Identifiable {
    let id = UUID()
    let fromMember: BudgetMember
    let toMember: BudgetMember
    let amount: Double
}

// MARK: - Shared Budget Manager

class SharedBudgetManager: ObservableObject {
    static let shared = SharedBudgetManager()

    @Published var budgets: [SharedBudget] = []
    @Published var expenses: [SharedExpense] = []
    @Published var sharedGoals: [SharedGoal] = []
    @Published var currentUserId: UUID = UUID()

    private let userDefaults = UserDefaults.standard
    private let budgetsKey = "furg_shared_budgets"
    private let expensesKey = "furg_shared_expenses"
    private let goalsKey = "furg_shared_goals"
    private let userIdKey = "furg_user_id"

    init() {
        loadUserId()
        loadBudgets()
        loadExpenses()
        loadSharedGoals()
    }

    // MARK: - Budget Management

    func createBudget(
        name: String,
        type: SharedBudgetType,
        totalBudget: Double,
        categories: [SharedCategory] = []
    ) -> SharedBudget {
        let currentUser = BudgetMember(
            id: currentUserId,
            name: "Me",
            email: nil,
            role: .owner,
            contributionPercent: 100,
            totalContributed: 0,
            totalSpent: 0,
            avatar: nil,
            isCurrentUser: true,
            joinedAt: Date()
        )

        let budget = SharedBudget(
            id: UUID(),
            name: name,
            type: type,
            members: [currentUser],
            categories: categories,
            totalBudget: totalBudget,
            currentSpending: 0,
            startDate: Date(),
            endDate: nil,
            isActive: true,
            icon: type.icon,
            color: type.defaultColor,
            createdBy: currentUserId,
            createdAt: Date()
        )

        budgets.append(budget)
        saveBudgets()
        return budget
    }

    func updateBudget(_ budget: SharedBudget) {
        if let index = budgets.firstIndex(where: { $0.id == budget.id }) {
            budgets[index] = budget
            saveBudgets()
        }
    }

    func deleteBudget(_ budget: SharedBudget) {
        budgets.removeAll { $0.id == budget.id }
        expenses.removeAll { $0.budgetId == budget.id }
        sharedGoals.removeAll { $0.budgetId == budget.id }
        saveBudgets()
        saveExpenses()
        saveSharedGoals()
    }

    func addMember(to budgetId: UUID, member: BudgetMember) {
        guard let index = budgets.firstIndex(where: { $0.id == budgetId }) else { return }
        budgets[index].members.append(member)

        // Recalculate contribution percentages
        let memberCount = budgets[index].members.count
        let equalShare = 100.0 / Double(memberCount)
        for i in 0..<budgets[index].members.count {
            budgets[index].members[i].contributionPercent = equalShare
        }

        saveBudgets()
    }

    func removeMember(memberId: UUID, from budgetId: UUID) {
        guard let index = budgets.firstIndex(where: { $0.id == budgetId }) else { return }
        budgets[index].members.removeAll { $0.id == memberId }
        saveBudgets()
    }

    // MARK: - Expense Management

    func addExpense(
        to budgetId: UUID,
        categoryId: UUID?,
        description: String,
        amount: Double,
        splitType: SplitType,
        paidBy: UUID,
        notes: String? = nil
    ) {
        guard let budgetIndex = budgets.firstIndex(where: { $0.id == budgetId }) else { return }

        let members = budgets[budgetIndex].members
        var splits: [ExpenseSplit] = []

        switch splitType {
        case .equal:
            let shareAmount = amount / Double(members.count)
            for member in members {
                splits.append(ExpenseSplit(
                    id: UUID(),
                    memberId: member.id,
                    amount: shareAmount,
                    isPaid: member.id == paidBy,
                    paidDate: member.id == paidBy ? Date() : nil
                ))
            }
        case .paidByOne:
            for member in members {
                splits.append(ExpenseSplit(
                    id: UUID(),
                    memberId: member.id,
                    amount: member.id == paidBy ? amount : 0,
                    isPaid: member.id == paidBy,
                    paidDate: member.id == paidBy ? Date() : nil
                ))
            }
        case .percentage:
            for member in members {
                let shareAmount = amount * (member.contributionPercent / 100)
                splits.append(ExpenseSplit(
                    id: UUID(),
                    memberId: member.id,
                    amount: shareAmount,
                    isPaid: member.id == paidBy,
                    paidDate: member.id == paidBy ? Date() : nil
                ))
            }
        case .exact:
            // For exact, splits should be provided separately
            let shareAmount = amount / Double(members.count)
            for member in members {
                splits.append(ExpenseSplit(
                    id: UUID(),
                    memberId: member.id,
                    amount: shareAmount,
                    isPaid: member.id == paidBy,
                    paidDate: member.id == paidBy ? Date() : nil
                ))
            }
        }

        let expense = SharedExpense(
            id: UUID(),
            budgetId: budgetId,
            categoryId: categoryId,
            memberId: paidBy,
            description: description,
            amount: amount,
            date: Date(),
            splitType: splitType,
            splits: splits,
            receipt: nil,
            notes: notes,
            isSettled: false,
            createdAt: Date()
        )

        expenses.append(expense)

        // Update budget spending
        budgets[budgetIndex].currentSpending += amount

        // Update member spending
        if let memberIndex = budgets[budgetIndex].members.firstIndex(where: { $0.id == paidBy }) {
            budgets[budgetIndex].members[memberIndex].totalSpent += amount
        }

        // Update category spending
        if let categoryId = categoryId,
           let categoryIndex = budgets[budgetIndex].categories.firstIndex(where: { $0.id == categoryId }) {
            budgets[budgetIndex].categories[categoryIndex].currentSpending += amount
        }

        saveBudgets()
        saveExpenses()
    }

    func settleExpense(_ expenseId: UUID, memberId: UUID) {
        guard let index = expenses.firstIndex(where: { $0.id == expenseId }) else { return }

        if let splitIndex = expenses[index].splits.firstIndex(where: { $0.memberId == memberId }) {
            expenses[index].splits[splitIndex].isPaid = true
            expenses[index].splits[splitIndex].paidDate = Date()
        }

        // Check if all splits are settled
        if expenses[index].splits.allSatisfy({ $0.isPaid }) {
            expenses[index].isSettled = true
        }

        saveExpenses()
    }

    // MARK: - Settlement Calculations

    func calculateSettlements(for budgetId: UUID) -> [SettlementSummary] {
        guard let budget = budgets.first(where: { $0.id == budgetId }) else { return [] }

        let budgetExpenses = expenses.filter { $0.budgetId == budgetId }
        var balances: [UUID: Double] = [:]

        // Calculate net balance for each member
        for member in budget.members {
            var balance = 0.0

            for expense in budgetExpenses {
                // Add what they paid
                if expense.memberId == member.id {
                    balance += expense.amount
                }

                // Subtract what they owe
                if let split = expense.splits.first(where: { $0.memberId == member.id }) {
                    balance -= split.amount
                }
            }

            balances[member.id] = balance
        }

        // Generate settlement recommendations
        var settlements: [SettlementSummary] = []
        var debtors = balances.filter { $0.value < -0.01 }.sorted { $0.value < $1.value }
        var creditors = balances.filter { $0.value > 0.01 }.sorted { $0.value > $1.value }

        while !debtors.isEmpty && !creditors.isEmpty {
            let debtor = debtors[0]
            let creditor = creditors[0]

            guard let debtorMember = budget.members.first(where: { $0.id == debtor.key }),
                  let creditorMember = budget.members.first(where: { $0.id == creditor.key }) else {
                break
            }

            let amount = min(abs(debtor.value), creditor.value)

            settlements.append(SettlementSummary(
                fromMember: debtorMember,
                toMember: creditorMember,
                amount: amount
            ))

            // Update balances
            debtors[0] = (debtor.key, debtor.value + amount)
            creditors[0] = (creditor.key, creditor.value - amount)

            if abs(debtors[0].value) < 0.01 {
                debtors.removeFirst()
            }
            if creditors[0].value < 0.01 {
                creditors.removeFirst()
            }
        }

        return settlements
    }

    // MARK: - Shared Goals

    func createSharedGoal(
        budgetId: UUID,
        name: String,
        targetAmount: Double,
        deadline: Date?,
        icon: String = "star.fill",
        color: String = "yellow"
    ) {
        let goal = SharedGoal(
            id: UUID(),
            budgetId: budgetId,
            name: name,
            targetAmount: targetAmount,
            currentAmount: 0,
            deadline: deadline,
            contributions: [],
            icon: icon,
            color: color,
            isCompleted: false
        )

        sharedGoals.append(goal)
        saveSharedGoals()
    }

    func contributeToGoal(_ goalId: UUID, memberId: UUID, amount: Double, notes: String? = nil) {
        guard let index = sharedGoals.firstIndex(where: { $0.id == goalId }) else { return }

        let contribution = SharedGoalContribution(
            id: UUID(),
            memberId: memberId,
            amount: amount,
            date: Date(),
            notes: notes
        )

        sharedGoals[index].contributions.append(contribution)
        sharedGoals[index].currentAmount += amount

        if sharedGoals[index].currentAmount >= sharedGoals[index].targetAmount {
            sharedGoals[index].isCompleted = true
        }

        // Update member contribution in budget
        if let budget = budgets.first(where: { $0.id == sharedGoals[index].budgetId }),
           let budgetIndex = budgets.firstIndex(where: { $0.id == budget.id }),
           let memberIndex = budgets[budgetIndex].members.firstIndex(where: { $0.id == memberId }) {
            budgets[budgetIndex].members[memberIndex].totalContributed += amount
            saveBudgets()
        }

        saveSharedGoals()
    }

    // MARK: - Analytics

    func getExpensesByCategory(for budgetId: UUID) -> [(String, Double)] {
        guard let budget = budgets.first(where: { $0.id == budgetId }) else { return [] }

        return budget.categories.map { ($0.name, $0.currentSpending) }
            .sorted { $0.1 > $1.1 }
    }

    func getExpensesByMember(for budgetId: UUID) -> [(String, Double)] {
        guard let budget = budgets.first(where: { $0.id == budgetId }) else { return [] }

        return budget.members.map { ($0.name, $0.totalSpent) }
            .sorted { $0.1 > $1.1 }
    }

    func getMemberBalance(memberId: UUID, in budgetId: UUID) -> Double {
        guard let budget = budgets.first(where: { $0.id == budgetId }),
              let member = budget.members.first(where: { $0.id == memberId }) else {
            return 0
        }

        return member.balance
    }

    // MARK: - Persistence

    private func loadUserId() {
        if let data = userDefaults.data(forKey: userIdKey),
           let id = try? JSONDecoder().decode(UUID.self, from: data) {
            currentUserId = id
        } else {
            currentUserId = UUID()
            if let data = try? JSONEncoder().encode(currentUserId) {
                userDefaults.set(data, forKey: userIdKey)
            }
        }
    }

    private func saveBudgets() {
        if let data = try? JSONEncoder().encode(budgets) {
            userDefaults.set(data, forKey: budgetsKey)
        }
    }

    private func loadBudgets() {
        guard let data = userDefaults.data(forKey: budgetsKey),
              let loaded = try? JSONDecoder().decode([SharedBudget].self, from: data) else {
            addDemoBudget()
            return
        }
        budgets = loaded
    }

    private func saveExpenses() {
        if let data = try? JSONEncoder().encode(expenses) {
            userDefaults.set(data, forKey: expensesKey)
        }
    }

    private func loadExpenses() {
        guard let data = userDefaults.data(forKey: expensesKey),
              let loaded = try? JSONDecoder().decode([SharedExpense].self, from: data) else {
            return
        }
        expenses = loaded
    }

    private func saveSharedGoals() {
        if let data = try? JSONEncoder().encode(sharedGoals) {
            userDefaults.set(data, forKey: goalsKey)
        }
    }

    private func loadSharedGoals() {
        guard let data = userDefaults.data(forKey: goalsKey),
              let loaded = try? JSONDecoder().decode([SharedGoal].self, from: data) else {
            return
        }
        sharedGoals = loaded
    }

    private func addDemoBudget() {
        let partnerId = UUID()

        var budget = SharedBudget(
            id: UUID(),
            name: "Household Budget",
            type: .couple,
            members: [
                BudgetMember(
                    id: currentUserId,
                    name: "Me",
                    email: nil,
                    role: .owner,
                    contributionPercent: 50,
                    totalContributed: 500,
                    totalSpent: 450,
                    avatar: nil,
                    isCurrentUser: true,
                    joinedAt: Date()
                ),
                BudgetMember(
                    id: partnerId,
                    name: "Partner",
                    email: "partner@email.com",
                    role: .admin,
                    contributionPercent: 50,
                    totalContributed: 500,
                    totalSpent: 380,
                    avatar: nil,
                    isCurrentUser: false,
                    joinedAt: Date()
                )
            ],
            categories: [
                SharedCategory(id: UUID(), name: "Groceries", budgetAmount: 600, currentSpending: 420, icon: "cart.fill", color: "green"),
                SharedCategory(id: UUID(), name: "Utilities", budgetAmount: 300, currentSpending: 250, icon: "bolt.fill", color: "yellow"),
                SharedCategory(id: UUID(), name: "Entertainment", budgetAmount: 200, currentSpending: 160, icon: "film.fill", color: "purple")
            ],
            totalBudget: 2000,
            currentSpending: 830,
            startDate: Calendar.current.date(byAdding: .day, value: -15, to: Date())!,
            endDate: nil,
            isActive: true,
            icon: "heart.fill",
            color: "pink",
            createdBy: currentUserId,
            createdAt: Calendar.current.date(byAdding: .month, value: -2, to: Date())!
        )

        budgets.append(budget)
        saveBudgets()

        // Add a shared goal
        createSharedGoal(
            budgetId: budget.id,
            name: "Vacation Fund",
            targetAmount: 3000,
            deadline: Calendar.current.date(byAdding: .month, value: 6, to: Date()),
            icon: "airplane",
            color: "cyan"
        )

        if var goal = sharedGoals.first {
            goal.currentAmount = 850
            goal.contributions = [
                SharedGoalContribution(id: UUID(), memberId: currentUserId, amount: 450, date: Calendar.current.date(byAdding: .day, value: -30, to: Date())!, notes: nil),
                SharedGoalContribution(id: UUID(), memberId: partnerId, amount: 400, date: Calendar.current.date(byAdding: .day, value: -20, to: Date())!, notes: nil)
            ]
            sharedGoals[0] = goal
            saveSharedGoals()
        }
    }
}
