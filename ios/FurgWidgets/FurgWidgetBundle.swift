//
//  FurgWidgetBundle.swift
//  FurgWidgets
//
//  iOS Widgets for quick financial glances
//

import WidgetKit
import SwiftUI

@main
struct FurgWidgetBundle: WidgetBundle {
    var body: some Widget {
        BalanceWidget()
        SpendingWidget()
        GoalsWidget()
    }
}
