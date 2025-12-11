//
//  OffersViewV2.swift
//  Furg
//
//  Deals, promotions, and cashback offers
//

import SwiftUI

struct OffersViewV2: View {
    @Environment(\.dismiss) var dismiss
    @State private var selectedCategory: OfferCategory = .all
    @State private var selectedOffer: OfferV2?
    @State private var searchText = ""

    enum OfferCategory: String, CaseIterable {
        case all = "All"
        case dining = "Dining"
        case shopping = "Shopping"
        case travel = "Travel"
        case services = "Services"
    }

    var filteredOffers: [OfferV2] {
        var offers = sampleOffers

        if selectedCategory != .all {
            offers = offers.filter { $0.category == selectedCategory.rawValue }
        }

        if !searchText.isEmpty {
            offers = offers.filter {
                $0.merchant.localizedCaseInsensitiveContains(searchText) ||
                $0.title.localizedCaseInsensitiveContains(searchText)
            }
        }

        return offers
    }

    var featuredOffers: [OfferV2] {
        sampleOffers.filter { $0.isFeatured }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Search
                    searchBar

                    // Earnings summary
                    earningsSummary

                    // Featured offers
                    if searchText.isEmpty && selectedCategory == .all {
                        featuredSection
                    }

                    // Category filter
                    categoryFilter

                    // All offers
                    offersGrid
                }
                .padding(20)
            }
            .background(Color.v2Background)
            .navigationTitle("Offers")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button { dismiss() } label: {
                        Image(systemName: "xmark")
                            .foregroundColor(.v2TextSecondary)
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        // Saved offers
                    } label: {
                        Image(systemName: "bookmark")
                            .foregroundColor(.v2Primary)
                    }
                }
            }
            .sheet(item: $selectedOffer) { offer in
                OfferDetailV2(offer: offer)
                    .presentationBackground(Color.v2Background)
            }
        }
    }

    // MARK: - Search Bar

    var searchBar: some View {
        HStack(spacing: 12) {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.v2TextTertiary)

            TextField("Search offers...", text: $searchText)
                .font(.v2Body)
                .foregroundColor(.v2TextPrimary)

            if !searchText.isEmpty {
                Button {
                    searchText = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.v2TextTertiary)
                }
            }
        }
        .padding(14)
        .background(Color.v2CardBackground)
        .cornerRadius(12)
    }

    // MARK: - Earnings Summary

    var earningsSummary: some View {
        V2Card(padding: 20) {
            HStack(spacing: 20) {
                // Total earned
                VStack(alignment: .leading, spacing: 4) {
                    Text("Lifetime Cashback")
                        .font(.v2CaptionSmall)
                        .foregroundColor(.v2TextTertiary)

                    HStack(alignment: .firstTextBaseline, spacing: 4) {
                        Text("$")
                            .font(.system(size: 18, weight: .medium, design: .rounded))
                            .foregroundColor(.v2Success)
                        Text("247.50")
                            .font(.v2MetricMedium)
                            .foregroundColor(.v2TextPrimary)
                    }
                }

                Spacer()

                // Pending
                VStack(alignment: .trailing, spacing: 4) {
                    Text("Pending")
                        .font(.v2CaptionSmall)
                        .foregroundColor(.v2TextTertiary)

                    Text("$34.20")
                        .font(.v2BodyBold)
                        .foregroundColor(.v2Warning)
                }

                // Available
                VStack(alignment: .trailing, spacing: 4) {
                    Text("Available")
                        .font(.v2CaptionSmall)
                        .foregroundColor(.v2TextTertiary)

                    Text("$18.50")
                        .font(.v2BodyBold)
                        .foregroundColor(.v2Success)
                }
            }

            // Redeem button
            if true { // Has available balance
                Button {
                    // Redeem cashback
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "arrow.down.circle.fill")
                        Text("Redeem $18.50")
                    }
                    .font(.v2Caption)
                    .foregroundColor(.v2Success)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(Color.v2Success.opacity(0.15))
                    .cornerRadius(20)
                }
                .padding(.top, 12)
            }
        }
    }

    // MARK: - Featured Section

    var featuredSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Featured")
                    .font(.v2Headline)
                    .foregroundColor(.v2TextPrimary)

                Image(systemName: "star.fill")
                    .font(.system(size: 12))
                    .foregroundColor(.v2Warning)

                Spacer()
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 14) {
                    ForEach(featuredOffers) { offer in
                        Button {
                            selectedOffer = offer
                        } label: {
                            FeaturedOfferCard(offer: offer)
                        }
                    }
                }
            }
        }
    }

    // MARK: - Category Filter

    var categoryFilter: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(OfferCategory.allCases, id: \.self) { category in
                    Button {
                        withAnimation { selectedCategory = category }
                    } label: {
                        Text(category.rawValue)
                            .font(.v2Caption)
                            .foregroundColor(selectedCategory == category ? .v2TextInverse : .v2TextSecondary)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 10)
                            .background(selectedCategory == category ? Color.v2Primary : Color.v2CardBackground)
                            .cornerRadius(20)
                    }
                }
            }
        }
    }

    // MARK: - Offers Grid

    var offersGrid: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("\(filteredOffers.count) Offers Available")
                .font(.v2Headline)
                .foregroundColor(.v2TextPrimary)

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 14) {
                ForEach(filteredOffers) { offer in
                    Button {
                        selectedOffer = offer
                    } label: {
                        OfferCardV2(offer: offer)
                    }
                }
            }
        }
    }

    // MARK: - Sample Data

    var sampleOffers: [OfferV2] {
        [
            OfferV2(
                merchant: "Uber Eats",
                title: "15% Cashback",
                description: "Get 15% cashback on your next 3 orders. Maximum $10 per order.",
                category: "Dining",
                cashbackPercent: 15,
                maxCashback: 30,
                expiresIn: 5,
                logoColor: .green,
                isFeatured: true,
                isActivated: false
            ),
            OfferV2(
                merchant: "Amazon",
                title: "5% Back",
                description: "Earn 5% cashback on all purchases this week.",
                category: "Shopping",
                cashbackPercent: 5,
                maxCashback: nil,
                expiresIn: 3,
                logoColor: .orange,
                isFeatured: true,
                isActivated: true
            ),
            OfferV2(
                merchant: "Starbucks",
                title: "10% Cashback",
                description: "Enjoy 10% back on coffee and food purchases.",
                category: "Dining",
                cashbackPercent: 10,
                maxCashback: 20,
                expiresIn: 7,
                logoColor: .green,
                isFeatured: false,
                isActivated: false
            ),
            OfferV2(
                merchant: "Target",
                title: "8% Back",
                description: "Earn extra cashback on all in-store and online purchases.",
                category: "Shopping",
                cashbackPercent: 8,
                maxCashback: 50,
                expiresIn: 14,
                logoColor: .red,
                isFeatured: false,
                isActivated: false
            ),
            OfferV2(
                merchant: "Delta Airlines",
                title: "3% Cashback",
                description: "Book flights and earn cashback on your travel.",
                category: "Travel",
                cashbackPercent: 3,
                maxCashback: nil,
                expiresIn: 30,
                logoColor: .blue,
                isFeatured: true,
                isActivated: false
            ),
            OfferV2(
                merchant: "DoorDash",
                title: "12% Back",
                description: "Get cashback on all food delivery orders.",
                category: "Dining",
                cashbackPercent: 12,
                maxCashback: 25,
                expiresIn: 10,
                logoColor: .red,
                isFeatured: false,
                isActivated: true
            ),
            OfferV2(
                merchant: "Nike",
                title: "6% Cashback",
                description: "Earn cashback on shoes, apparel, and gear.",
                category: "Shopping",
                cashbackPercent: 6,
                maxCashback: 40,
                expiresIn: 21,
                logoColor: .black,
                isFeatured: false,
                isActivated: false
            ),
            OfferV2(
                merchant: "Spotify",
                title: "$5 Back",
                description: "Get $5 cashback when you upgrade to Premium.",
                category: "Services",
                cashbackPercent: nil,
                maxCashback: 5,
                expiresIn: 7,
                logoColor: .green,
                isFeatured: false,
                isActivated: false
            ),
            OfferV2(
                merchant: "Hotels.com",
                title: "4% Cashback",
                description: "Book hotels and earn cashback on every stay.",
                category: "Travel",
                cashbackPercent: 4,
                maxCashback: nil,
                expiresIn: 45,
                logoColor: .red,
                isFeatured: false,
                isActivated: false
            ),
            OfferV2(
                merchant: "Best Buy",
                title: "7% Back",
                description: "Earn cashback on electronics and appliances.",
                category: "Shopping",
                cashbackPercent: 7,
                maxCashback: 100,
                expiresIn: 12,
                logoColor: .blue,
                isFeatured: false,
                isActivated: false
            )
        ]
    }
}

// MARK: - Offer Model

struct OfferV2: Identifiable {
    let id = UUID()
    let merchant: String
    let title: String
    let description: String
    let category: String
    let cashbackPercent: Int?
    let maxCashback: Double?
    let expiresIn: Int
    let logoColor: Color
    let isFeatured: Bool
    var isActivated: Bool
}

// MARK: - Featured Offer Card

struct FeaturedOfferCard: View {
    let offer: OfferV2

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                // Logo
                ZStack {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(offer.logoColor.opacity(0.15))
                        .frame(width: 48, height: 48)

                    Text(String(offer.merchant.prefix(1)))
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(offer.logoColor)
                }

                Spacer()

                // Badge
                if offer.isFeatured {
                    Text("HOT")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.v2Accent)
                        .cornerRadius(6)
                }
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(offer.merchant)
                    .font(.v2BodyBold)
                    .foregroundColor(.v2TextPrimary)

                Text(offer.title)
                    .font(.v2MetricMedium)
                    .foregroundColor(.v2Primary)
            }

            HStack {
                Image(systemName: "clock")
                    .font(.system(size: 10))
                Text("\(offer.expiresIn) days left")
                    .font(.v2CaptionSmall)
            }
            .foregroundColor(.v2TextTertiary)
        }
        .frame(width: 180)
        .padding(16)
        .background(Color.v2CardBackground)
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.v2Primary.opacity(0.3), lineWidth: 1)
        )
    }
}

// MARK: - Offer Card

struct OfferCardV2: View {
    let offer: OfferV2

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Logo
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(offer.logoColor.opacity(0.15))
                    .frame(width: 44, height: 44)

                Text(String(offer.merchant.prefix(1)))
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(offer.logoColor)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(offer.merchant)
                    .font(.v2Caption)
                    .foregroundColor(.v2TextSecondary)
                    .lineLimit(1)

                Text(offer.title)
                    .font(.v2BodyBold)
                    .foregroundColor(.v2Primary)
            }

            HStack {
                if offer.isActivated {
                    HStack(spacing: 4) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 10))
                        Text("Active")
                            .font(.v2CaptionSmall)
                    }
                    .foregroundColor(.v2Success)
                } else {
                    Text("\(offer.expiresIn)d left")
                        .font(.v2CaptionSmall)
                        .foregroundColor(.v2TextTertiary)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 10))
                    .foregroundColor(.v2TextTertiary)
            }
        }
        .padding(14)
        .background(Color.v2CardBackground)
        .cornerRadius(14)
    }
}

// MARK: - Offer Detail

struct OfferDetailV2: View {
    let offer: OfferV2
    @Environment(\.dismiss) var dismiss
    @State private var isActivated: Bool

    init(offer: OfferV2) {
        self.offer = offer
        self._isActivated = State(initialValue: offer.isActivated)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    VStack(spacing: 16) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 20)
                                .fill(offer.logoColor.opacity(0.15))
                                .frame(width: 80, height: 80)

                            Text(String(offer.merchant.prefix(1)))
                                .font(.system(size: 36, weight: .bold))
                                .foregroundColor(offer.logoColor)
                        }

                        VStack(spacing: 4) {
                            Text(offer.merchant)
                                .font(.v2Title)
                                .foregroundColor(.v2TextPrimary)

                            Text(offer.title)
                                .font(.v2DisplaySmall)
                                .foregroundColor(.v2Primary)
                        }

                        // Status
                        if isActivated {
                            HStack(spacing: 6) {
                                Image(systemName: "checkmark.circle.fill")
                                Text("Offer Activated")
                            }
                            .font(.v2Caption)
                            .foregroundColor(.v2Success)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(Color.v2Success.opacity(0.15))
                            .cornerRadius(20)
                        }
                    }
                    .padding(.top, 20)

                    // Details
                    V2Card {
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Offer Details")
                                .font(.v2Headline)
                                .foregroundColor(.v2TextPrimary)

                            Text(offer.description)
                                .font(.v2Body)
                                .foregroundColor(.v2TextSecondary)
                                .lineSpacing(4)

                            Divider().background(Color.white.opacity(0.06))

                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Category")
                                        .font(.v2CaptionSmall)
                                        .foregroundColor(.v2TextTertiary)
                                    Text(offer.category)
                                        .font(.v2Body)
                                        .foregroundColor(.v2TextPrimary)
                                }

                                Spacer()

                                VStack(alignment: .trailing, spacing: 4) {
                                    Text("Expires in")
                                        .font(.v2CaptionSmall)
                                        .foregroundColor(.v2TextTertiary)
                                    Text("\(offer.expiresIn) days")
                                        .font(.v2Body)
                                        .foregroundColor(offer.expiresIn <= 3 ? .v2Warning : .v2TextPrimary)
                                }
                            }

                            if let maxCashback = offer.maxCashback {
                                Divider().background(Color.white.opacity(0.06))

                                HStack {
                                    Text("Maximum cashback")
                                        .font(.v2Caption)
                                        .foregroundColor(.v2TextSecondary)
                                    Spacer()
                                    Text("$\(Int(maxCashback))")
                                        .font(.v2BodyBold)
                                        .foregroundColor(.v2Primary)
                                }
                            }
                        }
                    }

                    // Terms
                    V2Card {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Terms & Conditions")
                                .font(.v2Headline)
                                .foregroundColor(.v2TextPrimary)

                            VStack(alignment: .leading, spacing: 8) {
                                TermRow(text: "Valid for new and existing customers")
                                TermRow(text: "Cashback credited within 30 days")
                                TermRow(text: "Cannot be combined with other offers")
                                TermRow(text: "Subject to merchant participation")
                            }
                        }
                    }

                    // Action button
                    Button {
                        withAnimation {
                            isActivated.toggle()
                        }
                    } label: {
                        HStack(spacing: 8) {
                            if isActivated {
                                Image(systemName: "checkmark")
                                Text("Offer Activated")
                            } else {
                                Image(systemName: "bolt.fill")
                                Text("Activate Offer")
                            }
                        }
                        .font(.v2BodyBold)
                        .foregroundColor(isActivated ? .v2Success : .v2TextInverse)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(isActivated ? Color.v2Success.opacity(0.15) : Color.v2Primary)
                        .cornerRadius(14)
                    }

                    // Share
                    Button {
                        // Share offer
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "square.and.arrow.up")
                            Text("Share with Friends")
                        }
                        .font(.v2Body)
                        .foregroundColor(.v2TextSecondary)
                    }
                }
                .padding(20)
            }
            .background(Color.v2Background)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        // Save offer
                    } label: {
                        Image(systemName: "bookmark")
                            .foregroundColor(.v2Primary)
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                        .foregroundColor(.v2Primary)
                }
            }
        }
    }
}

// MARK: - Term Row

struct TermRow: View {
    let text: String

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "circle.fill")
                .font(.system(size: 4))
                .foregroundColor(.v2TextTertiary)
                .padding(.top, 6)

            Text(text)
                .font(.v2Caption)
                .foregroundColor(.v2TextSecondary)
        }
    }
}

// MARK: - Preview

#Preview {
    OffersViewV2()
}
