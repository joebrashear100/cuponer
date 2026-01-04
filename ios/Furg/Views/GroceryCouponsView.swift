//
//  GroceryCouponsView.swift
//  Furg
//
//  Location-based grocery coupons with personal preference controls
//

import SwiftUI
import CoreLocation

struct GroceryCouponsView: View {
    @StateObject private var couponManager = GroceryCouponManager.shared
    @StateObject private var locationManager = LocationManager.shared
    @State private var showPreferences = false
    @State private var selectedCoupon: GroceryCoupon?
    @State private var animate = false
    @State private var showStoreFilter = false

    var body: some View {
        ZStack {
            CopilotBackground()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 20) {
                    // Header
                    header
                        .offset(y: animate ? 0 : -20)
                        .opacity(animate ? 1 : 0)

                    // Location status
                    locationStatus
                        .offset(y: animate ? 0 : 20)
                        .opacity(animate ? 1 : 0)
                        .animation(.spring(response: 0.6).delay(0.1), value: animate)

                    // Quick filters
                    quickFilters
                        .offset(y: animate ? 0 : 20)
                        .opacity(animate ? 1 : 0)
                        .animation(.spring(response: 0.6).delay(0.15), value: animate)

                    // Savings summary
                    savingsSummary
                        .offset(y: animate ? 0 : 20)
                        .opacity(animate ? 1 : 0)
                        .animation(.spring(response: 0.6).delay(0.2), value: animate)

                    // Store filter chips
                    if !couponManager.availableChains.isEmpty {
                        storeFilterChips
                            .offset(y: animate ? 0 : 20)
                            .opacity(animate ? 1 : 0)
                            .animation(.spring(response: 0.6).delay(0.25), value: animate)
                    }

                    // Expiring soon section
                    if !couponManager.expiringSoonCoupons.isEmpty {
                        expiringSoonSection
                            .offset(y: animate ? 0 : 20)
                            .opacity(animate ? 1 : 0)
                            .animation(.spring(response: 0.6).delay(0.3), value: animate)
                    }

                    // Main coupon list
                    couponsList
                        .offset(y: animate ? 0 : 20)
                        .opacity(animate ? 1 : 0)
                        .animation(.spring(response: 0.6).delay(0.35), value: animate)

                    Spacer(minLength: 100)
                }
                .padding()
            }
        }
        .sheet(isPresented: $showPreferences) {
            PreferencesSheet(preferences: $couponManager.preferences) {
                couponManager.savePreferences()
            }
        }
        .sheet(item: $selectedCoupon) { coupon in
            CouponDetailSheet(coupon: coupon, isClipped: couponManager.isCouponClipped(coupon)) {
                couponManager.clipCoupon(coupon)
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.8)) {
                animate = true
            }
            locationManager.startUpdatingLocation()
            Task {
                await couponManager.fetchCouponsForCurrentLocation()
            }
        }
    }

    // MARK: - Header

    private var header: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Grocery Coupons")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.white, .white.opacity(0.8)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )

                if let city = locationManager.currentCity {
                    Text("Near \(city)")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
            }

            Spacer()

            Button {
                showPreferences = true
            } label: {
                Image(systemName: "slider.horizontal.3")
                    .font(.title2)
                    .foregroundColor(.white)
                    .padding(12)
                    .background(Color.white.opacity(0.1))
                    .clipShape(Circle())
            }
        }
    }

    // MARK: - Location Status

    private var locationStatus: some View {
        Group {
            if !locationManager.isLocationEnabled {
                HStack {
                    Image(systemName: "location.slash.fill")
                        .foregroundColor(.orange)

                    Text("Enable location to find nearby coupons")
                        .font(.subheadline)
                        .foregroundColor(.white)

                    Spacer()

                    Button("Enable") {
                        locationManager.requestAuthorization()
                    }
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(.black)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Color.green)
                    .cornerRadius(20)
                }
                .padding()
                .background(Color.orange.opacity(0.2))
                .cornerRadius(12)
            }
        }
    }

    // MARK: - Quick Filters

    private var quickFilters: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                // Search field
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.gray)
                    TextField("Search coupons...", text: $couponManager.searchQuery)
                        .foregroundColor(.white)
                }
                .padding(12)
                .background(Color.white.opacity(0.1))
                .cornerRadius(10)
                .frame(width: 200)

                // Category filters
                ForEach(couponManager.availableCategories.prefix(5)) { category in
                    CategoryChip(
                        category: category,
                        isSelected: couponManager.selectedCategory == category
                    ) {
                        withAnimation {
                            if couponManager.selectedCategory == category {
                                couponManager.selectedCategory = nil
                            } else {
                                couponManager.selectedCategory = category
                            }
                        }
                    }
                }
            }
            .padding(.horizontal, 4)
        }
    }

    // MARK: - Savings Summary

    private var savingsSummary: some View {
        HStack(spacing: 16) {
            SavingsCard(
                icon: "tag.fill",
                value: "\(couponManager.filteredCoupons.count)",
                label: "Coupons",
                color: .green
            )

            SavingsCard(
                icon: "dollarsign.circle.fill",
                value: String(format: "$%.0f", couponManager.totalPotentialSavings),
                label: "Potential Savings",
                color: .cyan
            )

            SavingsCard(
                icon: "building.2.fill",
                value: "\(couponManager.nearbyStores.count)",
                label: "Stores",
                color: .purple
            )
        }
    }

    // MARK: - Store Filter Chips

    private var storeFilterChips: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Filter by Store")
                    .font(.headline)
                    .foregroundColor(.white)

                Spacer()

                if couponManager.selectedChain != nil {
                    Button("Clear") {
                        withAnimation {
                            couponManager.selectedChain = nil
                        }
                    }
                    .font(.subheadline)
                    .foregroundColor(.green)
                }
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(couponManager.availableChains) { chain in
                        StoreChip(
                            chain: chain,
                            isSelected: couponManager.selectedChain == chain,
                            isPreferred: couponManager.preferences.preferredStores.contains(chain)
                        ) {
                            withAnimation {
                                if couponManager.selectedChain == chain {
                                    couponManager.selectedChain = nil
                                } else {
                                    couponManager.selectedChain = chain
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    // MARK: - Expiring Soon Section

    private var expiringSoonSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "clock.badge.exclamationmark.fill")
                    .foregroundColor(.orange)
                Text("Expiring Soon")
                    .font(.headline)
                    .foregroundColor(.white)
                Spacer()
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(couponManager.expiringSoonCoupons.prefix(5)) { coupon in
                        ExpiringCouponCard(coupon: coupon) {
                            selectedCoupon = coupon
                        }
                    }
                }
            }
        }
        .padding()
        .background(Color.orange.opacity(0.1))
        .cornerRadius(16)
    }

    // MARK: - Coupons List

    private var couponsList: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("All Coupons")
                    .font(.headline)
                    .foregroundColor(.white)

                Spacer()

                Menu {
                    ForEach(CouponSortOption.allCases) { option in
                        Button {
                            couponManager.preferences.sortBy = option
                            couponManager.savePreferences()
                        } label: {
                            HStack {
                                Text(option.displayName)
                                if couponManager.preferences.sortBy == option {
                                    Image(systemName: "checkmark")
                                }
                            }
                        }
                    }
                } label: {
                    HStack(spacing: 4) {
                        Text(couponManager.preferences.sortBy.displayName)
                            .font(.subheadline)
                        Image(systemName: "chevron.down")
                            .font(.caption)
                    }
                    .foregroundColor(.green)
                }
            }

            if couponManager.isLoading {
                HStack {
                    Spacer()
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .green))
                    Spacer()
                }
                .padding(.vertical, 40)
            } else if couponManager.filteredCoupons.isEmpty {
                EmptyStateView()
            } else {
                LazyVStack(spacing: 12) {
                    ForEach(couponManager.filteredCoupons) { coupon in
                        CouponCard(
                            coupon: coupon,
                            isClipped: couponManager.isCouponClipped(coupon)
                        ) {
                            selectedCoupon = coupon
                        } onClip: {
                            couponManager.clipCoupon(coupon)
                        }
                    }
                }
            }
        }
    }
}

// MARK: - Supporting Views

struct CategoryChip: View {
    let category: GroceryCouponCategory
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: category.icon)
                    .font(.caption)
                Text(category.displayName)
                    .font(.subheadline)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(isSelected ? Color.green : Color.white.opacity(0.1))
            .foregroundColor(isSelected ? .black : .white)
            .cornerRadius(20)
        }
    }
}

struct StoreChip: View {
    let chain: GroceryChain
    let isSelected: Bool
    let isPreferred: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: chain.icon)
                    .font(.caption)
                Text(chain.displayName)
                    .font(.subheadline)
                if isPreferred {
                    Image(systemName: "star.fill")
                        .font(.caption2)
                        .foregroundColor(.yellow)
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(isSelected ? Color.green : Color.white.opacity(0.1))
            .foregroundColor(isSelected ? .black : .white)
            .cornerRadius(20)
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(isPreferred && !isSelected ? Color.yellow.opacity(0.5) : Color.clear, lineWidth: 1)
            )
        }
    }
}

struct SavingsCard: View {
    let icon: String
    let value: String
    let label: String
    let color: Color

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)

            Text(value)
                .font(.title2.weight(.bold))
                .foregroundColor(.white)

            Text(label)
                .font(.caption)
                .foregroundColor(.gray)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color.white.opacity(0.05))
        .cornerRadius(12)
    }
}

struct ExpiringCouponCard: View {
    let coupon: GroceryCoupon
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text(coupon.chain.displayName)
                        .font(.caption.weight(.semibold))
                        .foregroundColor(.white)
                    Spacer()
                    Text(coupon.expiresIn)
                        .font(.caption2)
                        .foregroundColor(.orange)
                }

                Text(coupon.formattedDiscount)
                    .font(.headline.weight(.bold))
                    .foregroundColor(.green)

                Text(coupon.title)
                    .font(.caption)
                    .foregroundColor(.gray)
                    .lineLimit(2)
            }
            .padding()
            .frame(width: 160)
            .background(Color.white.opacity(0.1))
            .cornerRadius(12)
        }
    }
}

struct CouponCard: View {
    let coupon: GroceryCoupon
    let isClipped: Bool
    let action: () -> Void
    let onClip: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                // Store icon
                ZStack {
                    Circle()
                        .fill(Color(hex: coupon.chain.iconColor).opacity(0.2))
                        .frame(width: 50, height: 50)

                    Image(systemName: coupon.chain.icon)
                        .font(.title3)
                        .foregroundColor(Color(hex: coupon.chain.iconColor))
                }

                // Coupon details
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(coupon.chain.displayName)
                            .font(.caption.weight(.semibold))
                            .foregroundColor(.gray)

                        if coupon.requiresLoyaltyCard {
                            Image(systemName: "creditcard.fill")
                                .font(.caption2)
                                .foregroundColor(.cyan)
                        }
                    }

                    Text(coupon.title)
                        .font(.subheadline.weight(.medium))
                        .foregroundColor(.white)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)

                    HStack(spacing: 8) {
                        Text(coupon.expiresIn)
                            .font(.caption)
                            .foregroundColor(.gray)

                        if let code = coupon.code {
                            Text(code)
                                .font(.caption.weight(.semibold))
                                .foregroundColor(.cyan)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.cyan.opacity(0.2))
                                .cornerRadius(4)
                        }
                    }
                }

                Spacer()

                // Discount & clip button
                VStack(alignment: .trailing, spacing: 8) {
                    Text(coupon.formattedDiscount)
                        .font(.headline.weight(.bold))
                        .foregroundColor(.green)

                    Button {
                        onClip()
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: isClipped ? "checkmark" : "plus")
                                .font(.caption)
                            Text(isClipped ? "Clipped" : "Clip")
                                .font(.caption.weight(.semibold))
                        }
                        .foregroundColor(isClipped ? .gray : .black)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(isClipped ? Color.gray.opacity(0.3) : Color.green)
                        .cornerRadius(16)
                    }
                    .disabled(isClipped)
                }
            }
            .padding()
            .background(Color.white.opacity(0.05))
            .cornerRadius(16)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct EmptyStateView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "tag.slash")
                .font(.system(size: 48))
                .foregroundColor(.gray)

            Text("No coupons found")
                .font(.headline)
                .foregroundColor(.white)

            Text("Try adjusting your filters or preferences")
                .font(.subheadline)
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
        }
        .padding(.vertical, 40)
    }
}

// MARK: - Preferences Sheet

struct PreferencesSheet: View {
    @Binding var preferences: GroceryCouponPreferences
    @Environment(\.dismiss) private var dismiss
    let onSave: () -> Void

    var body: some View {
        NavigationView {
            ZStack {
                Color.black.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 24) {
                        // Preferred Stores
                        PreferenceSection(title: "Preferred Stores", subtitle: "These stores will appear first") {
                            FlowLayout(spacing: 8) {
                                ForEach(GroceryChain.allCases.filter { $0.hasCouponProgram }) { chain in
                                    ToggleChip(
                                        title: chain.displayName,
                                        isSelected: preferences.preferredStores.contains(chain),
                                        color: .green
                                    ) {
                                        if preferences.preferredStores.contains(chain) {
                                            preferences.preferredStores.removeAll { $0 == chain }
                                        } else {
                                            preferences.preferredStores.append(chain)
                                            preferences.excludedStores.removeAll { $0 == chain }
                                        }
                                    }
                                }
                            }
                        }

                        // Excluded Stores
                        PreferenceSection(title: "Excluded Stores", subtitle: "Hide coupons from these stores") {
                            FlowLayout(spacing: 8) {
                                ForEach(GroceryChain.allCases.filter { $0.hasCouponProgram }) { chain in
                                    ToggleChip(
                                        title: chain.displayName,
                                        isSelected: preferences.excludedStores.contains(chain),
                                        color: .red
                                    ) {
                                        if preferences.excludedStores.contains(chain) {
                                            preferences.excludedStores.removeAll { $0 == chain }
                                        } else {
                                            preferences.excludedStores.append(chain)
                                            preferences.preferredStores.removeAll { $0 == chain }
                                        }
                                    }
                                }
                            }
                        }

                        // Dietary Preferences
                        PreferenceSection(title: "Dietary Preferences", subtitle: "Prioritize coupons matching your diet") {
                            FlowLayout(spacing: 8) {
                                ForEach(DietaryPreference.allCases) { pref in
                                    ToggleChip(
                                        title: pref.displayName,
                                        icon: pref.icon,
                                        isSelected: preferences.dietaryPreferences.contains(pref),
                                        color: .cyan
                                    ) {
                                        if preferences.dietaryPreferences.contains(pref) {
                                            preferences.dietaryPreferences.removeAll { $0 == pref }
                                        } else {
                                            preferences.dietaryPreferences.append(pref)
                                        }
                                    }
                                }
                            }
                        }

                        // Distance Slider
                        PreferenceSection(title: "Maximum Distance", subtitle: "\(String(format: "%.1f", preferences.maxDistanceMiles)) miles") {
                            Slider(value: $preferences.maxDistanceMiles, in: 1...25, step: 0.5)
                                .accentColor(.green)
                        }

                        // Notification Settings
                        PreferenceSection(title: "Notifications", subtitle: nil) {
                            VStack(spacing: 12) {
                                Toggle("New coupons nearby", isOn: $preferences.notifyNewCoupons)
                                    .tint(.green)
                                Toggle("Expiring coupons", isOn: $preferences.notifyExpiringCoupons)
                                    .tint(.green)
                            }
                            .foregroundColor(.white)
                        }

                        Spacer(minLength: 40)
                    }
                    .padding()
                }
            }
            .navigationTitle("Preferences")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(.gray)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        onSave()
                        dismiss()
                    }
                    .foregroundColor(.green)
                    .fontWeight(.semibold)
                }
            }
        }
    }
}

struct PreferenceSection<Content: View>: View {
    let title: String
    let subtitle: String?
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                    .foregroundColor(.white)
                if let subtitle = subtitle {
                    Text(subtitle)
                        .font(.caption)
                        .foregroundColor(.gray)
                }
            }
            content
        }
    }
}

struct ToggleChip: View {
    let title: String
    var icon: String? = nil
    let isSelected: Bool
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 4) {
                if let icon = icon {
                    Image(systemName: icon)
                        .font(.caption)
                }
                Text(title)
                    .font(.subheadline)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(isSelected ? color : Color.white.opacity(0.1))
            .foregroundColor(isSelected ? .white : .gray)
            .cornerRadius(16)
        }
    }
}

// MARK: - Coupon Detail Sheet

struct CouponDetailSheet: View {
    let coupon: GroceryCoupon
    let isClipped: Bool
    let onClip: () -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var codeCopied = false

    var body: some View {
        NavigationView {
            ZStack {
                Color.black.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 24) {
                        // Store header
                        HStack {
                            ZStack {
                                Circle()
                                    .fill(Color(hex: coupon.chain.iconColor).opacity(0.2))
                                    .frame(width: 60, height: 60)
                                Image(systemName: coupon.chain.icon)
                                    .font(.title2)
                                    .foregroundColor(Color(hex: coupon.chain.iconColor))
                            }

                            VStack(alignment: .leading) {
                                Text(coupon.chain.displayName)
                                    .font(.headline)
                                    .foregroundColor(.white)
                                Text(coupon.category.displayName)
                                    .font(.subheadline)
                                    .foregroundColor(.gray)
                            }

                            Spacer()
                        }

                        // Discount
                        Text(coupon.formattedDiscount)
                            .font(.system(size: 48, weight: .bold))
                            .foregroundColor(.green)

                        // Title & description
                        VStack(spacing: 8) {
                            Text(coupon.title)
                                .font(.title3.weight(.semibold))
                                .foregroundColor(.white)
                                .multilineTextAlignment(.center)

                            Text(coupon.description)
                                .font(.body)
                                .foregroundColor(.gray)
                                .multilineTextAlignment(.center)
                        }

                        // Code (if available)
                        if let code = coupon.code {
                            VStack(spacing: 8) {
                                Text("Promo Code")
                                    .font(.caption)
                                    .foregroundColor(.gray)

                                Button {
                                    UIPasteboard.general.string = code
                                    codeCopied = true
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                                        codeCopied = false
                                    }
                                } label: {
                                    HStack {
                                        Text(code)
                                            .font(.title3.weight(.bold).monospaced())
                                        Image(systemName: codeCopied ? "checkmark" : "doc.on.doc")
                                            .font(.body)
                                    }
                                    .foregroundColor(.cyan)
                                    .padding()
                                    .background(Color.cyan.opacity(0.2))
                                    .cornerRadius(12)
                                }
                            }
                        }

                        // Details
                        VStack(spacing: 12) {
                            DetailRow(icon: "clock", label: "Expires", value: coupon.expiresIn)

                            if let min = coupon.minimumPurchase {
                                DetailRow(icon: "cart", label: "Minimum Purchase", value: String(format: "$%.2f", min))
                            }

                            if let limit = coupon.limitPerCustomer {
                                DetailRow(icon: "person", label: "Limit", value: "\(limit) per customer")
                            }

                            if coupon.requiresLoyaltyCard {
                                DetailRow(icon: "creditcard", label: "Requires", value: "Loyalty Card")
                            }

                            if coupon.isStackable {
                                DetailRow(icon: "square.stack.3d.up", label: "Stackable", value: "Yes")
                            }
                        }
                        .padding()
                        .background(Color.white.opacity(0.05))
                        .cornerRadius(12)

                        // Clip button
                        Button {
                            onClip()
                        } label: {
                            HStack {
                                Image(systemName: isClipped ? "checkmark.circle.fill" : "plus.circle.fill")
                                Text(isClipped ? "Coupon Clipped" : "Clip Coupon")
                                    .fontWeight(.semibold)
                            }
                            .foregroundColor(isClipped ? .gray : .black)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(isClipped ? Color.gray.opacity(0.3) : Color.green)
                            .cornerRadius(12)
                        }
                        .disabled(isClipped)

                        Spacer(minLength: 40)
                    }
                    .padding()
                }
            }
            .navigationTitle("Coupon Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(.green)
                }
            }
        }
    }
}

struct DetailRow: View {
    let icon: String
    let label: String
    let value: String

    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(.gray)
                .frame(width: 24)
            Text(label)
                .foregroundColor(.gray)
            Spacer()
            Text(value)
                .foregroundColor(.white)
        }
    }
}

// MARK: - Flow Layout Helper

struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = FlowResult(in: proposal.width ?? 0, subviews: subviews, spacing: spacing)
        return result.size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = FlowResult(in: bounds.width, subviews: subviews, spacing: spacing)
        for (index, subview) in subviews.enumerated() {
            subview.place(at: CGPoint(x: bounds.minX + result.positions[index].x,
                                      y: bounds.minY + result.positions[index].y),
                          proposal: .unspecified)
        }
    }

    struct FlowResult {
        var size: CGSize = .zero
        var positions: [CGPoint] = []

        init(in maxWidth: CGFloat, subviews: Subviews, spacing: CGFloat) {
            var x: CGFloat = 0
            var y: CGFloat = 0
            var lineHeight: CGFloat = 0

            for subview in subviews {
                let size = subview.sizeThatFits(.unspecified)
                if x + size.width > maxWidth && x > 0 {
                    x = 0
                    y += lineHeight + spacing
                    lineHeight = 0
                }
                positions.append(CGPoint(x: x, y: y))
                lineHeight = max(lineHeight, size.height)
                x += size.width + spacing
                self.size.width = max(self.size.width, x)
            }
            self.size.height = y + lineHeight
        }
    }
}

// MARK: - Color Extension

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3:
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6:
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

// MARK: - Preview

#Preview {
    GroceryCouponsView()
}
