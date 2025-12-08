//
//  PillTabBar.swift
//  Furg
//
//  Unified pill-style segmented tab bar component
//

import SwiftUI

struct PillTabBar: View {
    @Binding var selectedIndex: Int
    let tabs: [String]
    var accentColor: Color = .furgMint

    var body: some View {
        HStack(spacing: 0) {
            ForEach(tabs.indices, id: \.self) { index in
                Button {
                    withAnimation(.spring(response: 0.3)) {
                        selectedIndex = index
                    }
                } label: {
                    Text(tabs[index])
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(selectedIndex == index ? .white : .white.opacity(0.5))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(
                            selectedIndex == index ?
                            accentColor.opacity(0.3) :
                            Color.clear
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                }
            }
        }
        .padding(4)
        .background(Color.white.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

struct ScrollingPillTabBar: View {
    @Binding var selectedIndex: Int
    let tabs: [String]
    var accentColor: Color = .furgMint

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(tabs.indices, id: \.self) { index in
                    Button {
                        withAnimation(.spring(response: 0.3)) {
                            selectedIndex = index
                        }
                    } label: {
                        Text(tabs[index])
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(selectedIndex == index ? .furgCharcoal : .white.opacity(0.7))
                            .padding(.horizontal, 16)
                            .padding(.vertical, 10)
                            .background(selectedIndex == index ? accentColor : Color.white.opacity(0.1))
                            .clipShape(Capsule())
                    }
                }
            }
        }
    }
}

struct IconPillTabBar: View {
    @Binding var selectedIndex: Int
    let tabs: [(icon: String, label: String)]
    var accentColor: Color = .furgMint

    var body: some View {
        HStack(spacing: 8) {
            ForEach(tabs.indices, id: \.self) { index in
                Button {
                    withAnimation(.spring(response: 0.3)) {
                        selectedIndex = index
                    }
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: tabs[index].icon)
                            .font(.system(size: 14))

                        Text(tabs[index].label)
                            .font(.system(size: 13, weight: .medium))
                    }
                    .foregroundColor(selectedIndex == index ? .furgCharcoal : .white.opacity(0.7))
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(selectedIndex == index ? accentColor : Color.white.opacity(0.1))
                    .clipShape(Capsule())
                }
            }
        }
    }
}

#Preview {
    ZStack {
        Color.furgCharcoal.ignoresSafeArea()

        VStack(spacing: 30) {
            PillTabBar(selectedIndex: .constant(0), tabs: ["Day", "Week", "Month", "Year"])

            ScrollingPillTabBar(selectedIndex: .constant(1), tabs: ["All", "Food", "Shopping", "Travel", "Entertainment"])

            IconPillTabBar(selectedIndex: .constant(0), tabs: [
                ("chart.bar.fill", "Overview"),
                ("list.bullet", "Details"),
                ("gear", "Settings")
            ])
        }
        .padding()
    }
}
