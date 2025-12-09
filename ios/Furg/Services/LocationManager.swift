//
//  LocationManager.swift
//  Furg
//
//  Manages location services for spending insights and nearby offers
//

import Foundation
import CoreLocation
import Combine

class LocationManager: NSObject, ObservableObject {
    static let shared = LocationManager()

    private let locationManager = CLLocationManager()
    private var geocoder = CLGeocoder()

    @Published var currentLocation: CLLocation?
    @Published var currentCity: String?
    @Published var currentNeighborhood: String?
    @Published var authorizationStatus: CLAuthorizationStatus = .notDetermined
    @Published var isLocationEnabled = false
    @Published var lastError: Error?

    // Location-based spending data
    @Published var spendingByLocation: [LocationSpending] = []
    @Published var nearbyMerchants: [NearbyMerchant] = []
    @Published var locationInsights: [LocationInsight] = []

    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyHundredMeters
        locationManager.distanceFilter = 100 // Update every 100 meters
        authorizationStatus = locationManager.authorizationStatus
        updateLocationEnabled()
    }

    // MARK: - Authorization

    func requestAuthorization() {
        locationManager.requestWhenInUseAuthorization()
    }

    private func updateLocationEnabled() {
        isLocationEnabled = authorizationStatus == .authorizedWhenInUse || authorizationStatus == .authorizedAlways
    }

    // MARK: - Location Updates

    func startUpdatingLocation() {
        guard isLocationEnabled else {
            requestAuthorization()
            return
        }
        locationManager.startUpdatingLocation()
    }

    func stopUpdatingLocation() {
        locationManager.stopUpdatingLocation()
    }

    func getCurrentLocation() async -> CLLocation? {
        startUpdatingLocation()

        // Wait for location update
        for _ in 0..<10 {
            if let location = currentLocation {
                return location
            }
            try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
        }

        return currentLocation
    }

    // MARK: - Reverse Geocoding

    private func reverseGeocode(_ location: CLLocation) {
        geocoder.reverseGeocodeLocation(location) { [weak self] placemarks, error in
            guard let self = self else { return }

            if let error = error {
                DispatchQueue.main.async { [weak self] in
                    self?.lastError = error
                }
                return
            }

            guard let placemark = placemarks?.first else { return }

            // Capture values before dispatch to avoid retain cycle
            let city = placemark.locality
            let neighborhood = placemark.subLocality ?? placemark.name

            DispatchQueue.main.async { [weak self] in
                self?.currentCity = city
                self?.currentNeighborhood = neighborhood
            }
        }
    }

    // MARK: - Location-Based Insights

    func fetchSpendingByLocation() {
        // Demo data - would come from API in production
        spendingByLocation = [
            LocationSpending(
                neighborhood: "Downtown",
                city: "San Francisco",
                totalSpent: 1245.67,
                transactionCount: 23,
                topCategory: "Food & Dining",
                percentOfTotal: 32,
                coordinate: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194)
            ),
            LocationSpending(
                neighborhood: "Mission District",
                city: "San Francisco",
                totalSpent: 867.45,
                transactionCount: 18,
                topCategory: "Shopping",
                percentOfTotal: 22,
                coordinate: CLLocationCoordinate2D(latitude: 37.7599, longitude: -122.4148)
            ),
            LocationSpending(
                neighborhood: "SOMA",
                city: "San Francisco",
                totalSpent: 654.32,
                transactionCount: 12,
                topCategory: "Entertainment",
                percentOfTotal: 17,
                coordinate: CLLocationCoordinate2D(latitude: 37.7785, longitude: -122.3957)
            ),
            LocationSpending(
                neighborhood: "Castro",
                city: "San Francisco",
                totalSpent: 432.10,
                transactionCount: 8,
                topCategory: "Food & Dining",
                percentOfTotal: 11,
                coordinate: CLLocationCoordinate2D(latitude: 37.7609, longitude: -122.4350)
            ),
            LocationSpending(
                neighborhood: "Other",
                city: "Various",
                totalSpent: 687.23,
                transactionCount: 15,
                topCategory: "Various",
                percentOfTotal: 18,
                coordinate: nil
            )
        ]
    }

    func fetchNearbyMerchants() {
        // Demo data
        nearbyMerchants = [
            NearbyMerchant(
                name: "Whole Foods Market",
                category: "Groceries",
                distance: 0.3,
                averageSpend: 87.45,
                visitCount: 12,
                lastVisit: Calendar.current.date(byAdding: .day, value: -3, to: Date()),
                hasOffer: true,
                offerDescription: "5% cashback this week"
            ),
            NearbyMerchant(
                name: "Starbucks",
                category: "Coffee",
                distance: 0.1,
                averageSpend: 6.75,
                visitCount: 45,
                lastVisit: Calendar.current.date(byAdding: .day, value: -1, to: Date()),
                hasOffer: false,
                offerDescription: nil
            ),
            NearbyMerchant(
                name: "Target",
                category: "Shopping",
                distance: 0.8,
                averageSpend: 124.32,
                visitCount: 8,
                lastVisit: Calendar.current.date(byAdding: .day, value: -7, to: Date()),
                hasOffer: true,
                offerDescription: "10% off electronics"
            ),
            NearbyMerchant(
                name: "Chipotle",
                category: "Food & Dining",
                distance: 0.2,
                averageSpend: 14.50,
                visitCount: 15,
                lastVisit: Calendar.current.date(byAdding: .day, value: -5, to: Date()),
                hasOffer: false,
                offerDescription: nil
            )
        ]
    }

    func generateLocationInsights() {
        // Generate smart insights based on location data
        locationInsights = [
            LocationInsight(
                icon: "mappin.circle.fill",
                title: "Top Spending Area",
                description: "Downtown accounts for 32% of your spending. Consider setting a budget for this area.",
                type: .warning,
                actionLabel: "Set Area Budget"
            ),
            LocationInsight(
                icon: "arrow.up.right.circle.fill",
                title: "Spending Trend",
                description: "You've been spending 24% more in Mission District this month compared to last.",
                type: .info,
                actionLabel: "View Details"
            ),
            LocationInsight(
                icon: "tag.circle.fill",
                title: "Nearby Deal",
                description: "Whole Foods has 5% cashback - you're only 0.3 mi away!",
                type: .success,
                actionLabel: "View Offer"
            ),
            LocationInsight(
                icon: "clock.circle.fill",
                title: "Spending Pattern",
                description: "You tend to spend more on weekends in SOMA. Average: $89 vs $42 weekday.",
                type: .info,
                actionLabel: "Learn More"
            )
        ]
    }
}

// MARK: - CLLocationManagerDelegate

extension LocationManager: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }

        DispatchQueue.main.async { [weak self] in
            self?.currentLocation = location
            self?.reverseGeocode(location)
        }
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        DispatchQueue.main.async { [weak self] in
            self?.lastError = error
        }
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        let status = manager.authorizationStatus
        DispatchQueue.main.async { [weak self] in
            self?.authorizationStatus = status
            self?.updateLocationEnabled()

            if self?.isLocationEnabled == true {
                self?.startUpdatingLocation()
            }
        }
    }
}

// MARK: - Models

struct LocationSpending: Identifiable {
    let id = UUID()
    let neighborhood: String
    let city: String
    let totalSpent: Double
    let transactionCount: Int
    let topCategory: String
    let percentOfTotal: Int
    let coordinate: CLLocationCoordinate2D?
}

struct NearbyMerchant: Identifiable {
    let id = UUID()
    let name: String
    let category: String
    let distance: Double // in miles
    let averageSpend: Double
    let visitCount: Int
    let lastVisit: Date?
    let hasOffer: Bool
    let offerDescription: String?
}

struct LocationInsight: Identifiable {
    let id = UUID()
    let icon: String
    let title: String
    let description: String
    let type: InsightType
    let actionLabel: String

    enum InsightType {
        case success, warning, info, danger

        var color: String {
            switch self {
            case .success: return "furgSuccess"
            case .warning: return "furgWarning"
            case .info: return "furgInfo"
            case .danger: return "furgDanger"
            }
        }
    }
}
