import SwiftUI

// TODO: Implement QuickTransactionView with proper RecurringTransactionManager
struct QuickTransactionView: View {
    var body: some View {
        Text("Quick Transaction View (TODO)")
    }
}

struct QuickAddConfirmView: View {
    let template: TransactionTemplate
    @Environment(\.dismiss) var dismiss

    var body: some View {
        Text("Confirm Transaction")
    }
}

struct TemplateRow: View {
    let template: TransactionTemplate
    let action: () -> Void
    let onFavorite: () -> Void

    var body: some View {
        HStack {
            Text(template.name)
        }
    }
}

struct AddTemplateView: View {
    @Environment(\.dismiss) var dismiss

    var body: some View {
        Text("Add Template")
    }
}

#Preview {
    QuickTransactionView()
}
