//
//  LocationInsightsView.swift
//  Furg
//
//  Shows location-based spending insights and nearby offers
//

import SwiftUI
import CoreLocation
import MapKit

struct LocationInsightsView: View {
    @StateObject private var locationManager = LocationManager.shared
    @Environment(\.dismiss) var dismiss
    @State private var animate = false
    @State private var selectedTab = 0
    @State private var showingPermissionAlert = false
    @State private var mapRegion = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194),
        span: MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1)
    )

    var body: some View {
        NavigationStack {
            ZStack {
                Color.furgCharcoal.ignoresSafeArea()

                if locationManager.isLocationEnabled {
                    mainContent
                } else {
                    permissionView
                }
            }
            .navigationTitle("Location Insights")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                        .foregroundColor(.furgMint)
                }
            }
            .onAppear {
                loadData()
                withAnimation(.spring(response: 0.6)) {
                    animate = true
                }
            }
            .alert("Location Access Required", isPresented: $showingPermissionAlert) {
                Button("Open Settings") {
                    if let url = URL(string: UIApplication.openSettingsURLString) {
                        UIApplication.shared.open(url)
                    }
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("Enable location access in Settings to see spending insights based on where you shop.")
            }
        }
    }

    // MARK: - Main Content

    private var mainContent: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 24) {
                // Current location header
                currentLocationCard
                    .offset(y: animate ? 0 : 20)
                    .opacity(animate ? 1 : 0)

                // Tab selector
                PillTabBar(selectedIndex: $selectedTab, tabs: ["By Area", "Nearby", "Insights"])
                    .offset(y: animate ? 0 : 20)
                    .opacity(animate ? 1 : 0)
                    .animation(.spring(response: 0.6).delay(0.1), value: animate)

                // Tab content
                switch selectedTab {
                case 0:
                    spendingByAreaContent
                case 1:
                    nearbyMerchantsContent
                default:
                    insightsContent
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 40)
        }
    }

    // MARK: - Current Location Card

    private var currentLocationCard: some View {
        VStack(spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 8) {
                        Image(systemName: "location.fill")
                            .font(.system(size: 14))
                            .foregroundColor(.furgMint)

                        Text("Current Location")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.white.opacity(0.6))
                    }

                    Text(locationManager.currentNeighborhood ?? "Unknown")
                        .font(.system(size: 22, weight: .bold))
                        .foregroundColor(.white)

                    if let city = locationManager.currentCity {
                        Text(city)
                            .font(.system(size: 14))
                            .foregroundColor(.white.opacity(0.5))
                    }
                }

                Spacer()

                // Mini map
                Map(coordinateRegion: $mapRegion, showsUserLocation: true)
                    .frame(width: 80, height: 80)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.white.opacity(0.2), lineWidth: 1)
                    )
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color.white.opacity(0.1), lineWidth: 0.5)
                )
        )
    }

    // MARK: - Spending By Area

    private var spendingByAreaContent: some View {
        VStack(spacing: 16) {
            // Map overview
            Map(coordinateRegion: $mapRegion, annotationItems: locationManager.spendingByLocation.compactMap { spending -> SpendingAnnotation? in
                guard let coordinate = spending.coordinate else { return nil }
                return SpendingAnnotation(spending: spending)
            }) { annotation in
                MapAnnotation(coordinate: annotation.coordinate) {
                    VStack(spacing: 4) {
                        ZStack {
                            Circle()
                                .fill(Color.furgMint)
                                .frame(width: 40, height: 40)

                            Text("\(annotation.spending.percentOfTotal)%")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(.furgCharcoal)
                        }
                        .shadow(color: .black.opacity(0.3), radius: 4, y: 2)

                        Text(annotation.spending.neighborhood)
                            .font(.system(size: 9, weight: .medium))
                            .foregroundColor(.white)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.furgCharcoal.opacity(0.8))
                            .cornerRadius(4)
                    }
                }
            }
            .frame(height: 200)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.white.opacity(0.1), lineWidth: 0.5)
            )
            .offset(y: animate ? 0 : 20)
            .opacity(animate ? 1 : 0)
            .animation(.spring(response: 0.6).delay(0.2), value: animate)

            // Area breakdown
            VStack(spacing: 12) {
                ForEach(Array(locationManager.spendingByLocation.enumerated()), id: \.element.id) { index, spending in
                    SpendingAreaRow(spending: spending, rank: index + 1)
                        .offset(y: animate ? 0 : 20)
                        .opacity(animate ? 1 : 0)
                        .animation(.spring(response: 0.6).delay(0.3 + Double(index) * 0.05), value: animate)
                }
            }
        }
    }

    // MARK: - Nearby Merchants

    private var nearbyMerchantsContent: some View {
        VStack(spacing: 16) {
            ForEach(Array(locationManager.nearbyMerchants.enumerated()), id: \.element.id) { index, merchant in
                NearbyMerchantCard(merchant: merchant)
                    .offset(y: animate ? 0 : 20)
                    .opacity(animate ? 1 : 0)
                    .animation(.spring(response: 0.6).delay(0.2 + Double(index) * 0.05), value: animate)
            }
        }
    }

    // MARK: - Insights Content

    private var insightsContent: some View {
        VStack(spacing: 16) {
            ForEach(Array(locationManager.locationInsights.enumerated()), id: \.element.id) { index, insight in
                LocationInsightCard(insight: insight)
                    .offset(y: animate ? 0 : 20)
                    .opacity(animate ? 1 : 0)
                    .animation(.spring(response: 0.6).delay(0.2 + Double(index) * 0.05), value: animate)
            }
        }
    }

    // MARK: - Permission View

    private var permissionView: some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: "location.circle.fill")
                .font(.system(size: 80))
                .foregroundStyle(
                    LinearGradient(
                        colors: [.furgMint, .furgSeafoam],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

            VStack(spacing: 12) {
                Text("Enable Location")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(.white)

                Text("See where you spend the most, discover nearby deals, and get location-based insights.")
                    .font(.system(size: 16))
                    .foregroundColor(.white.opacity(0.6))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }

            Button {
                if locationManager.authorizationStatus == .denied {
                    showingPermissionAlert = true
                } else {
                    locationManager.requestAuthorization()
                }
            } label: {
                HStack {
                    Image(systemName: "location.fill")
                    Text("Enable Location")
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
            .padding(.horizontal, 40)

            Spacer()
        }
    }

    // MARK: - Helpers

    private func loadData() {
        locationManager.startUpdatingLocation()
        locationManager.fetchSpendingByLocation()
        locationManager.fetchNearbyMerchants()
        locationManager.generateLocationInsights()

        // Update map region if we have location
        if let location = locationManager.currentLocation {
            mapRegion = MKCoordinateRegion(
                center: location.coordinate,
                span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
            )
        }
    }
}

// MARK: - Supporting Views

struct SpendingAnnotation: Identifiable {
    let id = UUID()
    let spending: LocationSpending
    var coordinate: CLLocationCoordinate2D {
        spending.coordinate ?? CLLocationCoordinate2D()
    }
}

struct SpendingAreaRow: View {
    let spending: LocationSpending
    let rank: Int

    var body: some View {
        HStack(spacing: 14) {
            // Rank
            Text("#\(rank)")
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(.furgMint)
                .frame(width: 28)

            // Info
            VStack(alignment: .leading, spacing: 4) {
                Text(spending.neighborhood)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.white)

                HStack(spacing: 8) {
                    Text(spending.city)
                        .font(.system(size: 12))
                        .foregroundColor(.white.opacity(0.5))

                    Text("•")
                        .foregroundColor(.white.opacity(0.3))

                    Text("\(spending.transactionCount) transactions")
                        .font(.system(size: 12))
                        .foregroundColor(.white.opacity(0.5))
                }
            }

            Spacer()

            // Amount
            VStack(alignment: .trailing, spacing: 4) {
                Text(formatCurrency(spending.totalSpent))
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundColor(.white)

                Text("\(spending.percentOfTotal)%")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.furgMint)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(Color.white.opacity(0.1), lineWidth: 0.5)
                )
        )
    }
}

struct NearbyMerchantCard: View {
    let merchant: NearbyMerchant

    var body: some View {
        VStack(spacing: 12) {
            HStack(spacing: 14) {
                // Category icon
                ZStack {
                    Circle()
                        .fill(categoryColor.opacity(0.2))
                        .frame(width: 44, height: 44)

                    Image(systemName: categoryIcon)
                        .font(.system(size: 18))
                        .foregroundColor(categoryColor)
                }

                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(merchant.name)
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(.white)

                        if merchant.hasOffer {
                            Text("OFFER")
                                .font(.system(size: 9, weight: .bold))
                                .foregroundColor(.furgCharcoal)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.furgSuccess)
                                .clipShape(Capsule())
                        }
                    }

                    HStack(spacing: 8) {
                        Image(systemName: "location")
                            .font(.system(size: 10))

                        Text(String(format: "%.1f mi", merchant.distance))

                        Text("•")

                        Text(merchant.category)
                    }
                    .font(.system(size: 12))
                    .foregroundColor(.white.opacity(0.5))
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 4) {
                    Text(formatCurrency(merchant.averageSpend))
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .foregroundColor(.white)

                    Text("avg spend")
                        .font(.system(size: 10))
                        .foregroundColor(.white.opacity(0.4))
                }
            }

            if merchant.hasOffer, let offer = merchant.offerDescription {
                HStack {
                    Image(systemName: "tag.fill")
                        .font(.system(size: 12))
                        .foregroundColor(.furgSuccess)

                    Text(offer)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.furgSuccess)

                    Spacer()

                    Text("View")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.furgMint)
                }
                .padding(12)
                .background(Color.furgSuccess.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 10))
            }

            // Stats row
            HStack(spacing: 24) {
                LocationStatItem(value: "\(merchant.visitCount)", label: "visits")

                if let lastVisit = merchant.lastVisit {
                    LocationStatItem(value: formatRelativeDate(lastVisit), label: "last visit")
                }

                Spacer()
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.white.opacity(0.1), lineWidth: 0.5)
                )
        )
    }

    private var categoryColor: Color {
        switch merchant.category {
        case "Groceries": return .green
        case "Food & Dining": return .orange
        case "Coffee": return .brown
        case "Shopping": return .blue
        case "Entertainment": return .purple
        default: return .furgMint
        }
    }

    private var categoryIcon: String {
        switch merchant.category {
        case "Groceries": return "cart.fill"
        case "Food & Dining": return "fork.knife"
        case "Coffee": return "cup.and.saucer.fill"
        case "Shopping": return "bag.fill"
        case "Entertainment": return "film.fill"
        default: return "building.2.fill"
        }
    }

    private func formatRelativeDate(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}

struct LocationStatItem: View {
    let value: String
    let label: String

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(value)
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(.white)

            Text(label)
                .font(.system(size: 10))
                .foregroundColor(.white.opacity(0.4))
        }
    }
}

struct LocationInsightCard: View {
    let insight: LocationInsight

    var insightColor: Color {
        switch insight.type {
        case .success: return .furgSuccess
        case .warning: return .furgWarning
        case .info: return .furgInfo
        case .danger: return .furgDanger
        }
    }

    var body: some View {
        HStack(spacing: 14) {
            // Icon
            ZStack {
                Circle()
                    .fill(insightColor.opacity(0.2))
                    .frame(width: 44, height: 44)

                Image(systemName: insight.icon)
                    .font(.system(size: 18))
                    .foregroundColor(insightColor)
            }

            VStack(alignment: .leading, spacing: 6) {
                Text(insight.title)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.white)

                Text(insight.description)
                    .font(.system(size: 13))
                    .foregroundColor(.white.opacity(0.6))
                    .lineLimit(2)
            }

            Spacer()

            Button {
                // Handle action
            } label: {
                Text(insight.actionLabel)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.furgMint)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(insightColor.opacity(0.3), lineWidth: 1)
                )
        )
    }
}

// MARK: - Helpers

private func formatCurrency(_ amount: Double) -> String {
    let formatter = NumberFormatter()
    formatter.numberStyle = .currency
    formatter.maximumFractionDigits = 0
    return formatter.string(from: NSNumber(value: amount)) ?? "$0"
}

// MARK: - Preview

#Preview {
    LocationInsightsView()
}
