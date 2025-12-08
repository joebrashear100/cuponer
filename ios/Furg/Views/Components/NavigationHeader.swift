//
//  NavigationHeader.swift
//  Furg
//
//  Unified navigation header components
//

import SwiftUI

struct FurgNavigationHeader: View {
    let title: String
    let subtitle: String?
    let showBackButton: Bool
    let trailingContent: AnyView?
    @Environment(\.dismiss) var dismiss

    init(
        title: String,
        subtitle: String? = nil,
        showBackButton: Bool = false,
        @ViewBuilder trailing: () -> some View = { EmptyView() }
    ) {
        self.title = title
        self.subtitle = subtitle
        self.showBackButton = showBackButton
        self.trailingContent = AnyView(trailing())
    }

    var body: some View {
        HStack(spacing: 16) {
            if showBackButton {
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(width: 40, height: 40)
                        .background(Color.white.opacity(0.1))
                        .clipShape(Circle())
                }
            }

            VStack(alignment: .leading, spacing: 2) {
                if let subtitle = subtitle {
                    Text(subtitle)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.white.opacity(0.5))
                }

                Text(title)
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(.white)
            }

            Spacer()

            trailingContent
        }
        .padding(.horizontal, 20)
        .padding(.top, 16)
    }
}

struct FurgGreetingHeader: View {
    let userName: String?
    let trailingContent: AnyView?

    init(
        userName: String? = nil,
        @ViewBuilder trailing: () -> some View = { EmptyView() }
    ) {
        self.userName = userName
        self.trailingContent = AnyView(trailing())
    }

    private var greeting: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 5..<12: return "Good morning"
        case 12..<17: return "Good afternoon"
        case 17..<21: return "Good evening"
        default: return "Good night"
        }
    }

    var body: some View {
        HStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 4) {
                Text(greeting)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white.opacity(0.6))

                if let name = userName {
                    Text(name)
                        .font(.system(size: 26, weight: .bold))
                        .foregroundColor(.white)
                } else {
                    Text("Welcome back")
                        .font(.system(size: 26, weight: .bold))
                        .foregroundColor(.white)
                }
            }

            Spacer()

            trailingContent
        }
        .padding(.horizontal, 20)
        .padding(.top, 60)
    }
}

struct FurgSheetHeader: View {
    let title: String
    let leadingAction: (() -> Void)?
    let leadingLabel: String
    let trailingAction: (() -> Void)?
    let trailingLabel: String

    init(
        title: String,
        leadingLabel: String = "Cancel",
        leadingAction: (() -> Void)? = nil,
        trailingLabel: String = "Done",
        trailingAction: (() -> Void)? = nil
    ) {
        self.title = title
        self.leadingLabel = leadingLabel
        self.leadingAction = leadingAction
        self.trailingLabel = trailingLabel
        self.trailingAction = trailingAction
    }

    var body: some View {
        HStack {
            if let action = leadingAction {
                Button(action: action) {
                    Text(leadingLabel)
                        .font(.system(size: 16))
                        .foregroundColor(.white.opacity(0.7))
                }
            } else {
                Color.clear.frame(width: 60)
            }

            Spacer()

            Text(title)
                .font(.system(size: 17, weight: .semibold))
                .foregroundColor(.white)

            Spacer()

            if let action = trailingAction {
                Button(action: action) {
                    Text(trailingLabel)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.furgMint)
                }
            } else {
                Color.clear.frame(width: 60)
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
    }
}

#Preview {
    ZStack {
        Color.furgCharcoal.ignoresSafeArea()

        VStack(spacing: 40) {
            FurgNavigationHeader(
                title: "Settings",
                subtitle: "App preferences",
                showBackButton: true
            ) {
                Image(systemName: "bell.fill")
                    .foregroundColor(.furgMint)
            }

            FurgGreetingHeader(userName: "Alex") {
                Circle()
                    .fill(Color.furgMint)
                    .frame(width: 44, height: 44)
                    .overlay(
                        Text("AC")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.furgCharcoal)
                    )
            }

            FurgSheetHeader(
                title: "New Transaction",
                leadingAction: {},
                trailingAction: {}
            )

            Spacer()
        }
    }
}
