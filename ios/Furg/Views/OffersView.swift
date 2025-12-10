//
//  OffersView.swift
//  Furg
//
//  Coupons and offers nearby - find savings opportunities
//

import SwiftUI
import CoreLocation
import EventKit
import os.log

private let offersLogger = Logger(subsystem: "com.furg.app", category: "OffersView")

// MARK: - Offer Models

struct Offer: Identifiable {
    let id = UUID()
    let merchant: String
    let description: String
    let discount: String
    let category: OfferCategory
    let expiresAt: Date
    let distance: Double? // miles
    let logoColor: Color
    let isOnline: Bool
    let code: String?
    let terms: String
    let websiteURL: URL?

    init(merchant: String, description: String, discount: String, category: OfferCategory, expiresAt: Date, distance: Double? = nil, logoColor: Color, isOnline: Bool, code: String? = nil, terms: String, websiteURL: URL? = nil) {
        self.merchant = merchant
        self.description = description
        self.discount = discount
        self.category = category
        self.expiresAt = expiresAt
        self.distance = distance
        self.logoColor = logoColor
        self.isOnline = isOnline
        self.code = code
        self.terms = terms
        self.websiteURL = websiteURL ?? (isOnline ? URL(string: "https://www.\(merchant.lowercased().replacingOccurrences(of: " ", with: "")).com") : nil)
    }
}

enum OfferCategory: String, CaseIterable {
    case dining = "Dining"
    case groceries = "Groceries"
    case shopping = "Shopping"
    case entertainment = "Entertainment"
    case travel = "Travel"
    case gas = "Gas & Auto"
    case health = "Health"

    var icon: String {
        switch self {
        case .dining: return "fork.knife"
        case .groceries: return "cart.fill"
        case .shopping: return "bag.fill"
        case .entertainment: return "ticket.fill"
        case .travel: return "airplane"
        case .gas: return "fuelpump.fill"
        case .health: return "heart.fill"
        }
    }

    var color: Color {
        switch self {
        case .dining: return .orange
        case .groceries: return .green
        case .shopping: return .pink
        case .entertainment: return .purple
        case .travel: return .cyan
        case .gas: return .yellow
        case .health: return .red
        }
    }
}

// MARK: - Offers View

struct OffersView: View {
    @State private var selectedCategory: OfferCategory?
    @State private var searchText = ""
    @State private var showOnlineOnly = false
    @State private var animate = false
    @State private var selectedOffer: Offer?

    var demoOffers: [Offer] {
        let calendar = Calendar.current
        let now = Date()
        return [
            Offer(merchant: "Whole Foods", description: "10% off groceries for Prime members", discount: "10% OFF", category: .groceries, expiresAt: calendar.date(byAdding: .day, value: 3, to: now)!, distance: 0.8, logoColor: .green, isOnline: false, code: nil, terms: "Prime members only. Excludes alcohol."),
            Offer(merchant: "Chipotle", description: "Free chips & guac with entree purchase", discount: "FREE", category: .dining, expiresAt: calendar.date(byAdding: .day, value: 7, to: now)!, distance: 0.3, logoColor: .red, isOnline: false, code: "GUACFREE", terms: "One per customer. In-store only."),
            Offer(merchant: "Amazon", description: "20% off first Subscribe & Save order", discount: "20% OFF", category: .shopping, expiresAt: calendar.date(byAdding: .day, value: 14, to: now)!, distance: nil, logoColor: .orange, isOnline: true, code: "SAVE20", terms: "First-time subscribers only."),
            Offer(merchant: "Shell", description: "$0.10 off per gallon with app", discount: "$0.10/GAL", category: .gas, expiresAt: calendar.date(byAdding: .day, value: 30, to: now)!, distance: 1.2, logoColor: .yellow, isOnline: false, code: nil, terms: "Download Shell app to redeem."),
            Offer(merchant: "AMC Theatres", description: "Tuesday $6 movies all day", discount: "$6 MOVIES", category: .entertainment, expiresAt: calendar.date(byAdding: .day, value: 7, to: now)!, distance: 2.5, logoColor: .red, isOnline: false, code: nil, terms: "Tuesdays only. Standard format."),
            Offer(merchant: "CVS", description: "40% off vitamins this week", discount: "40% OFF", category: .health, expiresAt: calendar.date(byAdding: .day, value: 4, to: now)!, distance: 0.5, logoColor: .red, isOnline: false, code: nil, terms: "ExtraCare members. Limit 2."),
            Offer(merchant: "Uber Eats", description: "$10 off orders $25+ for new users", discount: "$10 OFF", category: .dining, expiresAt: calendar.date(byAdding: .day, value: 30, to: now)!, distance: nil, logoColor: .black, isOnline: true, code: "WELCOME10", terms: "New accounts only."),
            Offer(merchant: "Target", description: "5% off everything with RedCard", discount: "5% OFF", category: .shopping, expiresAt: calendar.date(byAdding: .year, value: 1, to: now)!, distance: 1.8, logoColor: .red, isOnline: true, code: nil, terms: "RedCard holders only."),
        ]
    }

    var filteredOffers: [Offer] {
        var result = demoOffers

        if !searchText.isEmpty {
            result = result.filter {
                $0.merchant.localizedCaseInsensitiveContains(searchText) ||
                $0.description.localizedCaseInsensitiveContains(searchText)
            }
        }

        if let category = selectedCategory {
            result = result.filter { $0.category == category }
        }

        if showOnlineOnly {
            result = result.filter { $0.isOnline }
        }

        return result
    }

    var nearbyOffers: [Offer] {
        filteredOffers.filter { $0.distance != nil }.sorted { ($0.distance ?? 0) < ($1.distance ?? 0) }
    }

    var onlineOffers: [Offer] {
        filteredOffers.filter { $0.isOnline }
    }

    var body: some View {
        ZStack {
            CopilotBackground()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 20) {
                    // Header
                    header
                        .offset(y: animate ? 0 : -20)
                        .opacity(animate ? 1 : 0)

                    // Search
                    searchBar
                        .offset(y: animate ? 0 : 20)
                        .opacity(animate ? 1 : 0)
                        .animation(.spring(response: 0.6).delay(0.1), value: animate)

                    // Category filters
                    categoryFilters
                        .offset(y: animate ? 0 : 20)
                        .opacity(animate ? 1 : 0)
                        .animation(.spring(response: 0.6).delay(0.15), value: animate)

                    // Potential Savings Card
                    savingsCard
                        .offset(y: animate ? 0 : 20)
                        .opacity(animate ? 1 : 0)
                        .animation(.spring(response: 0.6).delay(0.2), value: animate)

                    // Nearby Offers
                    if !nearbyOffers.isEmpty {
                        offerSection(title: "Nearby", icon: "location.fill", offers: nearbyOffers)
                            .offset(y: animate ? 0 : 20)
                            .opacity(animate ? 1 : 0)
                            .animation(.spring(response: 0.6).delay(0.25), value: animate)
                    }

                    // Online Offers
                    if !onlineOffers.isEmpty {
                        offerSection(title: "Online Deals", icon: "globe", offers: onlineOffers)
                            .offset(y: animate ? 0 : 20)
                            .opacity(animate ? 1 : 0)
                            .animation(.spring(response: 0.6).delay(0.3), value: animate)
                    }

                    Spacer(minLength: 120)
                }
                .padding(.horizontal, 20)
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                animate = true
            }
        }
        .sheet(item: $selectedOffer) { offer in
            OfferDetailSheet(offer: offer)
        }
    }

    // MARK: - Header

    private var header: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Offers & Coupons")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundColor(.white)

                Text("\(demoOffers.count) deals near you")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white.opacity(0.5))
            }

            Spacer()

            Toggle(isOn: $showOnlineOnly) {
                Image(systemName: "globe")
            }
            .toggleStyle(.button)
            .tint(.furgMint)
        }
        .padding(.top, 60)
    }

    // MARK: - Search Bar

    private var searchBar: some View {
        HStack(spacing: 12) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 16))
                .foregroundColor(.white.opacity(0.4))

            TextField("Search offers...", text: $searchText)
                .font(.system(size: 15))
                .foregroundColor(.white)
                .tint(.furgMint)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.03))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.white.opacity(0.1), lineWidth: 0.5)
                )
        )
    }

    // MARK: - Category Filters

    private var categoryFilters: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                OfferCategoryChip(
                    title: "All",
                    icon: "square.grid.2x2",
                    isSelected: selectedCategory == nil
                ) {
                    selectedCategory = nil
                }

                ForEach(OfferCategory.allCases, id: \.self) { category in
                    OfferCategoryChip(
                        title: category.rawValue,
                        icon: category.icon,
                        isSelected: selectedCategory == category
                    ) {
                        selectedCategory = category
                    }
                }
            }
        }
    }

    // MARK: - Savings Card

    private var savingsCard: some View {
        VStack(spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("POTENTIAL SAVINGS")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(.white.opacity(0.5))
                        .tracking(1)

                    Text("$127")
                        .font(.system(size: 36, weight: .bold, design: .rounded))
                        .foregroundColor(.furgMint)
                        + Text("/month")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.white.opacity(0.5))
                }

                Spacer()

                ZStack {
                    Circle()
                        .fill(Color.furgMint.opacity(0.2))
                        .frame(width: 60, height: 60)

                    Image(systemName: "tag.fill")
                        .font(.system(size: 24))
                        .foregroundColor(.furgMint)
                }
            }

            Text("Based on your spending habits, these offers could save you money on things you already buy.")
                .font(.system(size: 13))
                .foregroundColor(.white.opacity(0.6))
                .lineSpacing(4)
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.white.opacity(0.03))
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(
                            LinearGradient(
                                colors: [.furgMint.opacity(0.5), .furgMint.opacity(0.1)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                )
        )
    }

    // MARK: - Offer Section

    private func offerSection(title: String, icon: String, offers: [Offer]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 14))
                    .foregroundColor(.furgMint)

                Text(title)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)

                Spacer()

                Text("\(offers.count) offers")
                    .font(.system(size: 13))
                    .foregroundColor(.white.opacity(0.5))
            }

            ForEach(offers) { offer in
                OfferCard(offer: offer) {
                    selectedOffer = offer
                }
            }
        }
    }
}

// MARK: - Supporting Views

private struct OfferCategoryChip: View {
    let title: String
    let icon: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 12))

                Text(title)
                    .font(.system(size: 13, weight: .medium))
            }
            .foregroundColor(isSelected ? .furgCharcoal : .white.opacity(0.8))
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(
                Capsule()
                    .fill(isSelected ? Color.furgMint : Color.white.opacity(0.1))
            )
        }
    }
}

private struct OfferCard: View {
    let offer: Offer
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 14) {
                // Merchant logo
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(offer.logoColor.opacity(0.2))
                        .frame(width: 50, height: 50)

                    Image(systemName: offer.category.icon)
                        .font(.system(size: 20))
                        .foregroundColor(offer.logoColor)
                }

                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(offer.merchant)
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(.white)

                        if offer.isOnline {
                            Image(systemName: "globe")
                                .font(.system(size: 10))
                                .foregroundColor(.white.opacity(0.4))
                        }
                    }

                    Text(offer.description)
                        .font(.system(size: 13))
                        .foregroundColor(.white.opacity(0.6))
                        .lineLimit(1)

                    HStack(spacing: 8) {
                        if let distance = offer.distance {
                            HStack(spacing: 2) {
                                Image(systemName: "location.fill")
                                    .font(.system(size: 9))
                                Text("\(String(format: "%.1f", distance)) mi")
                                    .font(.system(size: 11))
                            }
                            .foregroundColor(.white.opacity(0.4))
                        }

                        Text("Expires \(formatExpiry(offer.expiresAt))")
                            .font(.system(size: 11))
                            .foregroundColor(.white.opacity(0.4))
                    }
                }

                Spacer()

                // Discount badge
                Text(offer.discount)
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(.furgMint)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.furgMint.opacity(0.15))
                    )
            }
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.white.opacity(0.03))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color.white.opacity(0.08), lineWidth: 0.5)
                    )
            )
        }
        .buttonStyle(.plain)
    }

    private func formatExpiry(_ date: Date) -> String {
        let days = Calendar.current.dateComponents([.day], from: Date(), to: date).day ?? 0
        if days == 0 { return "today" }
        if days == 1 { return "tomorrow" }
        if days < 7 { return "in \(days) days" }
        return date.formatted(.dateTime.month().day())
    }
}

private struct OfferDetailSheet: View {
    let offer: Offer
    @Environment(\.dismiss) var dismiss
    @State private var showCopied = false

    var body: some View {
        NavigationStack {
            ZStack {
                Color.furgCharcoal.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 24) {
                        // Hero
                        VStack(spacing: 16) {
                            ZStack {
                                Circle()
                                    .fill(offer.logoColor.opacity(0.2))
                                    .frame(width: 80, height: 80)

                                Image(systemName: offer.category.icon)
                                    .font(.system(size: 32))
                                    .foregroundColor(offer.logoColor)
                            }

                            Text(offer.merchant)
                                .font(.system(size: 24, weight: .bold))
                                .foregroundColor(.white)

                            Text(offer.discount)
                                .font(.system(size: 32, weight: .bold, design: .rounded))
                                .foregroundColor(.furgMint)
                        }
                        .padding(.top, 20)

                        // Description
                        Text(offer.description)
                            .font(.system(size: 16))
                            .foregroundColor(.white.opacity(0.8))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)

                        // Code (if available)
                        if let code = offer.code {
                            VStack(spacing: 8) {
                                Text("PROMO CODE")
                                    .font(.system(size: 11, weight: .semibold))
                                    .foregroundColor(.white.opacity(0.5))
                                    .tracking(1)

                                Button {
                                    UIPasteboard.general.string = code
                                    withAnimation {
                                        showCopied = true
                                    }
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                                        showCopied = false
                                    }
                                } label: {
                                    HStack {
                                        Text(code)
                                            .font(.system(size: 20, weight: .bold, design: .monospaced))
                                            .foregroundColor(.furgMint)

                                        Image(systemName: showCopied ? "checkmark" : "doc.on.doc")
                                            .font(.system(size: 14))
                                            .foregroundColor(.furgMint)
                                    }
                                    .padding(.horizontal, 24)
                                    .padding(.vertical, 16)
                                    .background(
                                        RoundedRectangle(cornerRadius: 12)
                                            .fill(Color.furgMint.opacity(0.1))
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 12)
                                                    .stroke(Color.furgMint.opacity(0.3), style: StrokeStyle(lineWidth: 2, dash: [8]))
                                            )
                                    )
                                }
                            }
                        }

                        // Details
                        VStack(alignment: .leading, spacing: 12) {
                            DetailRowOffers(label: "Category", value: offer.category.rawValue)
                            DetailRowOffers(label: "Expires", value: offer.expiresAt.formatted(.dateTime.month().day().year()))

                            if let distance = offer.distance {
                                DetailRowOffers(label: "Distance", value: "\(String(format: "%.1f", distance)) miles away")
                            }

                            if offer.isOnline {
                                DetailRowOffers(label: "Type", value: "Online Only")
                            }
                        }
                        .padding(16)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color.white.opacity(0.05))
                        )

                        // Terms
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Terms & Conditions")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(.white.opacity(0.5))

                            Text(offer.terms)
                                .font(.system(size: 13))
                                .foregroundColor(.white.opacity(0.6))
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(16)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color.white.opacity(0.05))
                        )

                        // Actions
                        VStack(spacing: 12) {
                            Button {
                                // Set reminder
                                RemindersService.shared.createOfferReminder(merchant: offer.merchant, discount: offer.discount, expiresAt: offer.expiresAt)
                            } label: {
                                HStack {
                                    Image(systemName: "bell.badge")
                                    Text("Remind Me Before Expiry")
                                }
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(
                                    RoundedRectangle(cornerRadius: 14)
                                        .fill(Color.white.opacity(0.1))
                                )
                            }

                            if offer.isOnline, let url = offer.websiteURL {
                                Link(destination: url) {
                                    HStack {
                                        Image(systemName: "arrow.up.right")
                                        Text("Visit Website")
                                    }
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(.furgCharcoal)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 16)
                                    .background(
                                        LinearGradient(
                                            colors: [.furgMint, .furgSeafoam],
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                                    .clipShape(RoundedRectangle(cornerRadius: 14))
                                }
                            }
                        }

                        Spacer(minLength: 40)
                    }
                    .padding(.horizontal, 20)
                }
            }
            .navigationTitle("Offer Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                        .foregroundColor(.furgMint)
                }
            }
        }
    }
}

private struct DetailRowOffers: View {
    let label: String
    let value: String

    var body: some View {
        HStack {
            Text(label)
                .font(.system(size: 14))
                .foregroundColor(.white.opacity(0.5))

            Spacer()

            Text(value)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.white)
        }
    }
}

// MARK: - Reminders Extension

extension RemindersService {
    func createOfferReminder(merchant: String, discount: String, expiresAt: Date) {
        Task {
            guard await requestOfferReminderAccess() else {
                offersLogger.warning("Reminders access denied for offer reminder")
                return
            }

            let reminder = EKReminder(eventStore: eventStore)
            reminder.title = "🏷️ \(merchant) offer expires soon!"
            reminder.notes = "Don't miss out on \(discount) at \(merchant). Offer expires \(formatDate(expiresAt))."
            reminder.calendar = eventStore.defaultCalendarForNewReminders()

            // Set reminder for 1 day before expiry, or today if expiring soon
            let reminderDate = Calendar.current.date(byAdding: .day, value: -1, to: expiresAt) ?? expiresAt
            let finalDate = reminderDate > Date() ? reminderDate : Date()
            reminder.dueDateComponents = Calendar.current.dateComponents([.year, .month, .day, .hour], from: finalDate)

            // Add alarm
            let alarm = EKAlarm(absoluteDate: finalDate)
            reminder.addAlarm(alarm)

            do {
                try eventStore.save(reminder, commit: true)
                offersLogger.info("Created offer reminder for \(merchant)")
            } catch {
                offersLogger.error("Failed to create offer reminder: \(error.localizedDescription)")
            }
        }
    }

    private func requestOfferReminderAccess() async -> Bool {
        do {
            return try await eventStore.requestFullAccessToReminders()
        } catch {
            offersLogger.error("Failed to request reminders access: \(error.localizedDescription)")
            return false
        }
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }
}

#Preview {
    OffersView()
}
