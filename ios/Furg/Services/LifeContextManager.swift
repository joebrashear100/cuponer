import Foundation
import EventKit
import HealthKit
import CoreLocation
import Combine

// MARK: - Life Context Models

struct CalendarEvent: Identifiable, Codable {
    let id: String
    let title: String
    let startDate: Date
    let endDate: Date
    let location: String?
    let isAllDay: Bool
    let eventType: EventType
    var estimatedCost: Double?
    var budgetAllocated: Double?
    var associatedTransactions: [String] // Transaction IDs

    enum EventType: String, Codable, CaseIterable {
        case travel
        case wedding
        case birthday
        case holiday
        case medical
        case business
        case social
        case fitness
        case entertainment
        case shopping
        case dining
        case other

        var icon: String {
            switch self {
            case .travel: return "airplane"
            case .wedding: return "heart.fill"
            case .birthday: return "gift.fill"
            case .holiday: return "star.fill"
            case .medical: return "cross.case.fill"
            case .business: return "briefcase.fill"
            case .social: return "person.3.fill"
            case .fitness: return "figure.run"
            case .entertainment: return "ticket.fill"
            case .shopping: return "bag.fill"
            case .dining: return "fork.knife"
            case .other: return "calendar"
            }
        }

        var defaultBudgetMultiplier: Double {
            switch self {
            case .travel: return 500
            case .wedding: return 200
            case .birthday: return 50
            case .holiday: return 100
            case .medical: return 100
            case .business: return 50
            case .social: return 75
            case .fitness: return 20
            case .entertainment: return 100
            case .shopping: return 150
            case .dining: return 60
            case .other: return 30
            }
        }
    }
}

struct HealthContext: Codable {
    var averageSleepHours: Double
    var lastNightSleep: Double?
    var stressLevel: StressLevel
    var activityLevel: ActivityLevel
    var heartRateVariability: Double?
    var stepCount: Int
    var activeCalories: Double
    var mindfulMinutes: Int
    var lastUpdated: Date

    enum StressLevel: String, Codable, CaseIterable {
        case low, moderate, elevated, high

        var spendingRiskMultiplier: Double {
            switch self {
            case .low: return 1.0
            case .moderate: return 1.15
            case .elevated: return 1.35
            case .high: return 1.6
            }
        }

        var color: String {
            switch self {
            case .low: return "green"
            case .moderate: return "yellow"
            case .elevated: return "orange"
            case .high: return "red"
            }
        }
    }

    enum ActivityLevel: String, Codable, CaseIterable {
        case sedentary, light, moderate, active, veryActive
    }

    static var empty: HealthContext {
        HealthContext(
            averageSleepHours: 7,
            lastNightSleep: nil,
            stressLevel: .moderate,
            activityLevel: .moderate,
            heartRateVariability: nil,
            stepCount: 0,
            activeCalories: 0,
            mindfulMinutes: 0,
            lastUpdated: Date()
        )
    }
}

struct LocationContext: Codable {
    var currentLocation: SavedLocation?
    var homeLocation: SavedLocation?
    var workLocation: SavedLocation?
    var frequentLocations: [SavedLocation]
    var currentMode: LocationMode
    var isInHomeCity: Bool
    var lastUpdated: Date

    enum LocationMode: String, Codable {
        case home
        case work
        case commuting
        case traveling
        case shopping
        case dining
        case unknown
    }

    struct SavedLocation: Codable, Identifiable {
        var id: String { "\(latitude),\(longitude)" }
        let latitude: Double
        let longitude: Double
        let name: String?
        let address: String?
        let category: LocationCategory?
        var visitCount: Int
        var averageSpend: Double?
        var lastVisit: Date?
    }

    enum LocationCategory: String, Codable, CaseIterable {
        case home, work, grocery, restaurant, shopping, entertainment, fitness, medical, travel, gas, other
    }

    static var empty: LocationContext {
        LocationContext(
            currentLocation: nil,
            homeLocation: nil,
            workLocation: nil,
            frequentLocations: [],
            currentMode: .unknown,
            isInHomeCity: true,
            lastUpdated: Date()
        )
    }
}

struct RelationshipContext: Codable {
    var people: [Person]
    var sharedExpensePartners: [String] // Person IDs
    var upcomingGiftOccasions: [GiftOccasion]

    struct Person: Identifiable, Codable {
        let id: String
        var name: String
        var relationship: RelationshipType
        var birthday: Date?
        var anniversary: Date?
        var totalSharedExpenses: Double
        var totalGiftsGiven: Double
        var giftBudget: Double?
        var notes: String?
    }

    enum RelationshipType: String, Codable, CaseIterable {
        case partner, spouse, family, friend, colleague, other

        var defaultGiftBudget: Double {
            switch self {
            case .partner, .spouse: return 200
            case .family: return 75
            case .friend: return 50
            case .colleague: return 25
            case .other: return 30
            }
        }
    }

    struct GiftOccasion: Identifiable, Codable {
        let id: String
        let personId: String
        let personName: String
        let occasion: String
        let date: Date
        var budgetAllocated: Double
        var giftIdeas: [String]
        var purchased: Bool
    }

    static var empty: RelationshipContext {
        RelationshipContext(people: [], sharedExpensePartners: [], upcomingGiftOccasions: [])
    }
}

struct LifeContextSnapshot: Codable {
    let timestamp: Date
    let calendar: CalendarContext
    let health: HealthContext
    let location: LocationContext
    let relationships: RelationshipContext
    let spendingRiskScore: Double // 0-100, higher = more likely to overspend
    let recommendations: [ContextualRecommendation]

    struct CalendarContext: Codable {
        let upcomingEvents: [CalendarEvent]
        let totalUpcomingCosts: Double
        let busyDaysThisWeek: Int
        let hasUpcomingTravel: Bool
        let nextMajorEvent: CalendarEvent?
    }

    struct ContextualRecommendation: Identifiable, Codable {
        let id: String
        let type: RecommendationType
        let title: String
        let message: String
        let priority: Priority
        let actionable: Bool
        let action: String?

        enum RecommendationType: String, Codable {
            case budgetAlert, spendingRisk, upcomingExpense, savingsOpportunity, healthCorrelation, locationBased
        }

        enum Priority: String, Codable {
            case low, medium, high, urgent
        }
    }
}

// MARK: - Life Context Manager

class LifeContextManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    static let shared = LifeContextManager()

    // MARK: - Published Properties
    @Published var calendarEvents: [CalendarEvent] = []
    @Published var healthContext: HealthContext = .empty
    @Published var locationContext: LocationContext = .empty
    @Published var relationshipContext: RelationshipContext = .empty
    @Published var currentSnapshot: LifeContextSnapshot?
    @Published var spendingRiskScore: Double = 50
    @Published var contextualAlerts: [LifeContextSnapshot.ContextualRecommendation] = []

    @Published var calendarAccessGranted = false
    @Published var healthAccessGranted = false
    @Published var locationAccessGranted = false

    @Published var isLoading = false
    @Published var lastSyncTime: Date?

    // MARK: - Private Properties
    private let eventStore = EKEventStore()
    private let healthStore = HKHealthStore()
    private let locationManager = CLLocationManager()
    private var cancellables = Set<AnyCancellable>()

    private let userDefaults = UserDefaults.standard
    private let calendarEventsKey = "lifeContext_calendarEvents"
    private let healthContextKey = "lifeContext_health"
    private let locationContextKey = "lifeContext_location"
    private let relationshipContextKey = "lifeContext_relationships"

    // MARK: - Initialization

    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyHundredMeters
        loadSavedData()
    }

    // MARK: - Permissions

    func requestAllPermissions() {
        requestCalendarAccess()
        requestHealthAccess()
        requestLocationAccess()
    }

    func requestCalendarAccess() {
        if #available(iOS 17.0, *) {
            eventStore.requestFullAccessToEvents { [weak self] granted, error in
                DispatchQueue.main.async {
                    self?.calendarAccessGranted = granted
                    if granted {
                        self?.fetchCalendarEvents()
                    }
                }
            }
        } else {
            eventStore.requestAccess(to: .event) { [weak self] granted, error in
                DispatchQueue.main.async {
                    self?.calendarAccessGranted = granted
                    if granted {
                        self?.fetchCalendarEvents()
                    }
                }
            }
        }
    }

    func requestHealthAccess() {
        guard HKHealthStore.isHealthDataAvailable() else { return }

        let typesToRead: Set<HKObjectType> = [
            HKObjectType.categoryType(forIdentifier: .sleepAnalysis)!,
            HKObjectType.quantityType(forIdentifier: .heartRateVariabilitySDNN)!,
            HKObjectType.quantityType(forIdentifier: .stepCount)!,
            HKObjectType.quantityType(forIdentifier: .activeEnergyBurned)!,
            HKObjectType.categoryType(forIdentifier: .mindfulSession)!,
            HKObjectType.quantityType(forIdentifier: .heartRate)!
        ]

        healthStore.requestAuthorization(toShare: nil, read: typesToRead) { [weak self] success, error in
            DispatchQueue.main.async {
                self?.healthAccessGranted = success
                if success {
                    self?.fetchHealthData()
                }
            }
        }
    }

    func requestLocationAccess() {
        locationManager.requestWhenInUseAuthorization()
    }

    // MARK: - Calendar Integration

    func fetchCalendarEvents() {
        let startDate = Date()
        let endDate = Calendar.current.date(byAdding: .month, value: 3, to: startDate)!

        let predicate = eventStore.predicateForEvents(withStart: startDate, end: endDate, calendars: nil)
        let events = eventStore.events(matching: predicate)

        DispatchQueue.main.async {
            self.calendarEvents = events.map { event in
                let eventType = self.classifyEvent(event)
                return CalendarEvent(
                    id: event.eventIdentifier ?? UUID().uuidString,
                    title: event.title ?? "Untitled",
                    startDate: event.startDate,
                    endDate: event.endDate,
                    location: event.location,
                    isAllDay: event.isAllDay,
                    eventType: eventType,
                    estimatedCost: eventType.defaultBudgetMultiplier,
                    budgetAllocated: nil,
                    associatedTransactions: []
                )
            }
            self.saveCalendarEvents()
            self.generateContextualAlerts()
        }
    }

    private func classifyEvent(_ event: EKEvent) -> CalendarEvent.EventType {
        let title = (event.title ?? "").lowercased()
        let location = (event.location ?? "").lowercased()
        let notes = (event.notes ?? "").lowercased()
        let combined = "\(title) \(location) \(notes)"

        // Travel indicators
        if combined.contains("flight") || combined.contains("airport") || combined.contains("hotel") ||
           combined.contains("airbnb") || combined.contains("vacation") || combined.contains("trip") {
            return .travel
        }

        // Wedding indicators
        if combined.contains("wedding") || combined.contains("reception") || combined.contains("ceremony") {
            return .wedding
        }

        // Birthday indicators
        if combined.contains("birthday") || combined.contains("bday") || combined.contains("party") {
            return .birthday
        }

        // Medical indicators
        if combined.contains("doctor") || combined.contains("dentist") || combined.contains("hospital") ||
           combined.contains("appointment") || combined.contains("checkup") || combined.contains("therapy") {
            return .medical
        }

        // Business indicators
        if combined.contains("meeting") || combined.contains("conference") || combined.contains("presentation") ||
           combined.contains("interview") || combined.contains("work") {
            return .business
        }

        // Fitness indicators
        if combined.contains("gym") || combined.contains("workout") || combined.contains("yoga") ||
           combined.contains("run") || combined.contains("training") || combined.contains("class") {
            return .fitness
        }

        // Entertainment indicators
        if combined.contains("concert") || combined.contains("show") || combined.contains("movie") ||
           combined.contains("theater") || combined.contains("game") || combined.contains("match") {
            return .entertainment
        }

        // Dining indicators
        if combined.contains("dinner") || combined.contains("lunch") || combined.contains("brunch") ||
           combined.contains("restaurant") || combined.contains("reservation") {
            return .dining
        }

        // Shopping indicators
        if combined.contains("shopping") || combined.contains("mall") || combined.contains("store") {
            return .shopping
        }

        // Social indicators
        if combined.contains("hangout") || combined.contains("drinks") || combined.contains("coffee") ||
           combined.contains("friend") || combined.contains("family") {
            return .social
        }

        // Holiday indicators
        if combined.contains("christmas") || combined.contains("thanksgiving") || combined.contains("holiday") ||
           combined.contains("easter") || combined.contains("new year") {
            return .holiday
        }

        return .other
    }

    // MARK: - Health Integration

    func fetchHealthData() {
        fetchSleepData()
        fetchHeartRateVariability()
        fetchStepCount()
        fetchActiveCalories()
        fetchMindfulMinutes()
    }

    private func fetchSleepData() {
        guard let sleepType = HKObjectType.categoryType(forIdentifier: .sleepAnalysis) else { return }

        let now = Date()
        let startOfDay = Calendar.current.startOfDay(for: now)
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: startOfDay)!

        let predicate = HKQuery.predicateForSamples(withStart: yesterday, end: now, options: .strictStartDate)
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)

        let query = HKSampleQuery(sampleType: sleepType, predicate: predicate, limit: HKObjectQueryNoLimit, sortDescriptors: [sortDescriptor]) { [weak self] _, samples, _ in
            guard let samples = samples as? [HKCategorySample] else { return }

            var totalSleep: TimeInterval = 0
            for sample in samples {
                if sample.value == HKCategoryValueSleepAnalysis.asleepUnspecified.rawValue ||
                   sample.value == HKCategoryValueSleepAnalysis.asleepCore.rawValue ||
                   sample.value == HKCategoryValueSleepAnalysis.asleepDeep.rawValue ||
                   sample.value == HKCategoryValueSleepAnalysis.asleepREM.rawValue {
                    totalSleep += sample.endDate.timeIntervalSince(sample.startDate)
                }
            }

            let sleepHours = totalSleep / 3600

            DispatchQueue.main.async {
                self?.healthContext.lastNightSleep = sleepHours
                self?.updateStressLevel()
                self?.saveHealthContext()
            }
        }

        healthStore.execute(query)
    }

    private func fetchHeartRateVariability() {
        guard let hrvType = HKQuantityType.quantityType(forIdentifier: .heartRateVariabilitySDNN) else { return }

        let now = Date()
        let startDate = Calendar.current.date(byAdding: .day, value: -1, to: now)!
        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: now, options: .strictStartDate)

        let query = HKStatisticsQuery(quantityType: hrvType, quantitySamplePredicate: predicate, options: .discreteAverage) { [weak self] _, result, _ in
            guard let result = result, let average = result.averageQuantity() else { return }

            let hrv = average.doubleValue(for: HKUnit.secondUnit(with: .milli))

            DispatchQueue.main.async {
                self?.healthContext.heartRateVariability = hrv
                self?.updateStressLevel()
                self?.saveHealthContext()
            }
        }

        healthStore.execute(query)
    }

    private func fetchStepCount() {
        guard let stepType = HKQuantityType.quantityType(forIdentifier: .stepCount) else { return }

        let now = Date()
        let startOfDay = Calendar.current.startOfDay(for: now)
        let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: now, options: .strictStartDate)

        let query = HKStatisticsQuery(quantityType: stepType, quantitySamplePredicate: predicate, options: .cumulativeSum) { [weak self] _, result, _ in
            guard let result = result, let sum = result.sumQuantity() else { return }

            let steps = Int(sum.doubleValue(for: HKUnit.count()))

            DispatchQueue.main.async {
                self?.healthContext.stepCount = steps
                self?.updateActivityLevel()
                self?.saveHealthContext()
            }
        }

        healthStore.execute(query)
    }

    private func fetchActiveCalories() {
        guard let calorieType = HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned) else { return }

        let now = Date()
        let startOfDay = Calendar.current.startOfDay(for: now)
        let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: now, options: .strictStartDate)

        let query = HKStatisticsQuery(quantityType: calorieType, quantitySamplePredicate: predicate, options: .cumulativeSum) { [weak self] _, result, _ in
            guard let result = result, let sum = result.sumQuantity() else { return }

            let calories = sum.doubleValue(for: HKUnit.kilocalorie())

            DispatchQueue.main.async {
                self?.healthContext.activeCalories = calories
                self?.saveHealthContext()
            }
        }

        healthStore.execute(query)
    }

    private func fetchMindfulMinutes() {
        guard let mindfulType = HKObjectType.categoryType(forIdentifier: .mindfulSession) else { return }

        let now = Date()
        let startDate = Calendar.current.date(byAdding: .day, value: -7, to: now)!
        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: now, options: .strictStartDate)

        let query = HKSampleQuery(sampleType: mindfulType, predicate: predicate, limit: HKObjectQueryNoLimit, sortDescriptors: nil) { [weak self] _, samples, _ in
            guard let samples = samples as? [HKCategorySample] else { return }

            var totalMinutes: TimeInterval = 0
            for sample in samples {
                totalMinutes += sample.endDate.timeIntervalSince(sample.startDate)
            }

            DispatchQueue.main.async {
                self?.healthContext.mindfulMinutes = Int(totalMinutes / 60)
                self?.saveHealthContext()
            }
        }

        healthStore.execute(query)
    }

    private func updateStressLevel() {
        var stressScore: Double = 50 // Baseline

        // Sleep impact
        if let sleep = healthContext.lastNightSleep {
            if sleep < 5 {
                stressScore += 30
            } else if sleep < 6 {
                stressScore += 20
            } else if sleep < 7 {
                stressScore += 10
            } else if sleep >= 8 {
                stressScore -= 10
            }
        }

        // HRV impact (lower HRV = higher stress)
        if let hrv = healthContext.heartRateVariability {
            if hrv < 20 {
                stressScore += 25
            } else if hrv < 40 {
                stressScore += 15
            } else if hrv < 60 {
                stressScore += 5
            } else if hrv > 80 {
                stressScore -= 15
            }
        }

        // Mindfulness impact
        if healthContext.mindfulMinutes > 30 {
            stressScore -= 15
        } else if healthContext.mindfulMinutes > 10 {
            stressScore -= 5
        }

        // Clamp and categorize
        stressScore = max(0, min(100, stressScore))

        if stressScore < 30 {
            healthContext.stressLevel = .low
        } else if stressScore < 50 {
            healthContext.stressLevel = .moderate
        } else if stressScore < 70 {
            healthContext.stressLevel = .elevated
        } else {
            healthContext.stressLevel = .high
        }
    }

    private func updateActivityLevel() {
        let steps = healthContext.stepCount
        let calories = healthContext.activeCalories

        if steps > 12000 || calories > 600 {
            healthContext.activityLevel = .veryActive
        } else if steps > 8000 || calories > 400 {
            healthContext.activityLevel = .active
        } else if steps > 5000 || calories > 250 {
            healthContext.activityLevel = .moderate
        } else if steps > 2500 || calories > 100 {
            healthContext.activityLevel = .light
        } else {
            healthContext.activityLevel = .sedentary
        }
    }

    // MARK: - Location Integration

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }

        let savedLocation = LocationContext.SavedLocation(
            latitude: location.coordinate.latitude,
            longitude: location.coordinate.longitude,
            name: nil,
            address: nil,
            category: nil,
            visitCount: 1,
            averageSpend: nil,
            lastVisit: Date()
        )

        locationContext.currentLocation = savedLocation
        locationContext.lastUpdated = Date()

        updateLocationMode(location)
        checkIfInHomeCity(location)

        saveLocationContext()
        generateContextualAlerts()
    }

    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        locationAccessGranted = status == .authorizedWhenInUse || status == .authorizedAlways

        if locationAccessGranted {
            locationManager.startUpdatingLocation()
        }
    }

    private func updateLocationMode(_ location: CLLocation) {
        // Check against known locations
        if let home = locationContext.homeLocation {
            let homeLocation = CLLocation(latitude: home.latitude, longitude: home.longitude)
            if location.distance(from: homeLocation) < 100 {
                locationContext.currentMode = .home
                return
            }
        }

        if let work = locationContext.workLocation {
            let workLocation = CLLocation(latitude: work.latitude, longitude: work.longitude)
            if location.distance(from: workLocation) < 100 {
                locationContext.currentMode = .work
                return
            }
        }

        // Check frequent locations
        for frequentLocation in locationContext.frequentLocations {
            let savedLoc = CLLocation(latitude: frequentLocation.latitude, longitude: frequentLocation.longitude)
            if location.distance(from: savedLoc) < 100 {
                if let category = frequentLocation.category {
                    switch category {
                    case .grocery, .shopping:
                        locationContext.currentMode = .shopping
                    case .restaurant:
                        locationContext.currentMode = .dining
                    default:
                        locationContext.currentMode = .unknown
                    }
                    return
                }
            }
        }

        locationContext.currentMode = .unknown
    }

    private func checkIfInHomeCity(_ location: CLLocation) {
        guard let home = locationContext.homeLocation else {
            locationContext.isInHomeCity = true
            return
        }

        let homeLocation = CLLocation(latitude: home.latitude, longitude: home.longitude)
        let distance = location.distance(from: homeLocation)

        // More than 50 miles from home = traveling
        locationContext.isInHomeCity = distance < 80000

        if !locationContext.isInHomeCity {
            locationContext.currentMode = .traveling
        }
    }

    func setHomeLocation(_ location: CLLocation, name: String? = nil) {
        locationContext.homeLocation = LocationContext.SavedLocation(
            latitude: location.coordinate.latitude,
            longitude: location.coordinate.longitude,
            name: name ?? "Home",
            address: nil,
            category: .home,
            visitCount: 0,
            averageSpend: nil,
            lastVisit: nil
        )
        saveLocationContext()
    }

    func setWorkLocation(_ location: CLLocation, name: String? = nil) {
        locationContext.workLocation = LocationContext.SavedLocation(
            latitude: location.coordinate.latitude,
            longitude: location.coordinate.longitude,
            name: name ?? "Work",
            address: nil,
            category: .work,
            visitCount: 0,
            averageSpend: nil,
            lastVisit: nil
        )
        saveLocationContext()
    }

    // MARK: - Relationship Management

    func addPerson(_ person: RelationshipContext.Person) {
        relationshipContext.people.append(person)
        updateGiftOccasions()
        saveRelationshipContext()
    }

    func updatePerson(_ person: RelationshipContext.Person) {
        if let index = relationshipContext.people.firstIndex(where: { $0.id == person.id }) {
            relationshipContext.people[index] = person
            updateGiftOccasions()
            saveRelationshipContext()
        }
    }

    func removePerson(_ personId: String) {
        relationshipContext.people.removeAll { $0.id == personId }
        relationshipContext.sharedExpensePartners.removeAll { $0 == personId }
        updateGiftOccasions()
        saveRelationshipContext()
    }

    private func updateGiftOccasions() {
        let calendar = Calendar.current
        let now = Date()
        let threeMonthsLater = calendar.date(byAdding: .month, value: 3, to: now)!

        var occasions: [RelationshipContext.GiftOccasion] = []

        for person in relationshipContext.people {
            // Check birthday
            if let birthday = person.birthday {
                let thisYearBirthday = calendar.date(bySetting: .year, value: calendar.component(.year, from: now), of: birthday) ?? birthday

                if thisYearBirthday >= now && thisYearBirthday <= threeMonthsLater {
                    occasions.append(RelationshipContext.GiftOccasion(
                        id: "\(person.id)_birthday_\(calendar.component(.year, from: now))",
                        personId: person.id,
                        personName: person.name,
                        occasion: "Birthday",
                        date: thisYearBirthday,
                        budgetAllocated: person.giftBudget ?? person.relationship.defaultGiftBudget,
                        giftIdeas: [],
                        purchased: false
                    ))
                }
            }

            // Check anniversary
            if let anniversary = person.anniversary {
                let thisYearAnniversary = calendar.date(bySetting: .year, value: calendar.component(.year, from: now), of: anniversary) ?? anniversary

                if thisYearAnniversary >= now && thisYearAnniversary <= threeMonthsLater {
                    occasions.append(RelationshipContext.GiftOccasion(
                        id: "\(person.id)_anniversary_\(calendar.component(.year, from: now))",
                        personId: person.id,
                        personName: person.name,
                        occasion: "Anniversary",
                        date: thisYearAnniversary,
                        budgetAllocated: person.giftBudget ?? person.relationship.defaultGiftBudget,
                        giftIdeas: [],
                        purchased: false
                    ))
                }
            }
        }

        relationshipContext.upcomingGiftOccasions = occasions.sorted { $0.date < $1.date }
    }

    // MARK: - Contextual Intelligence

    func generateContextualAlerts() {
        var alerts: [LifeContextSnapshot.ContextualRecommendation] = []

        // Health-based alerts
        if healthContext.stressLevel == .high {
            alerts.append(LifeContextSnapshot.ContextualRecommendation(
                id: "stress_high",
                type: .healthCorrelation,
                title: "High Stress Detected",
                message: "Your stress indicators are elevated. You're \(Int((healthContext.stressLevel.spendingRiskMultiplier - 1) * 100))% more likely to impulse spend. Consider a 24-hour cooling off period for non-essential purchases.",
                priority: .high,
                actionable: true,
                action: "Enable cooling off period"
            ))
        }

        if let sleep = healthContext.lastNightSleep, sleep < 6 {
            alerts.append(LifeContextSnapshot.ContextualRecommendation(
                id: "low_sleep",
                type: .healthCorrelation,
                title: "Low Sleep Alert",
                message: "You got \(String(format: "%.1f", sleep)) hours of sleep. Research shows sleep-deprived people spend 18% more on average. Be mindful of purchases today.",
                priority: .medium,
                actionable: false,
                action: nil
            ))
        }

        // Location-based alerts
        if locationContext.currentMode == .traveling {
            alerts.append(LifeContextSnapshot.ContextualRecommendation(
                id: "traveling",
                type: .locationBased,
                title: "Travel Mode Active",
                message: "You're away from home. Travel budgets have been activated and foreign transaction fees are being tracked.",
                priority: .low,
                actionable: false,
                action: nil
            ))
        }

        // Calendar-based alerts
        let upcomingExpensiveEvents = calendarEvents.filter {
            $0.startDate > Date() &&
            $0.startDate < Calendar.current.date(byAdding: .day, value: 14, to: Date())! &&
            ($0.estimatedCost ?? 0) > 100
        }

        for event in upcomingExpensiveEvents.prefix(3) {
            alerts.append(LifeContextSnapshot.ContextualRecommendation(
                id: "event_\(event.id)",
                type: .upcomingExpense,
                title: "Upcoming: \(event.title)",
                message: "Estimated cost: $\(Int(event.estimatedCost ?? 0)). Make sure you've budgeted for this event.",
                priority: .medium,
                actionable: true,
                action: "Allocate budget"
            ))
        }

        // Gift occasion alerts
        let upcomingGifts = relationshipContext.upcomingGiftOccasions.filter {
            !$0.purchased && $0.date < Calendar.current.date(byAdding: .day, value: 14, to: Date())!
        }

        for occasion in upcomingGifts {
            alerts.append(LifeContextSnapshot.ContextualRecommendation(
                id: "gift_\(occasion.id)",
                type: .upcomingExpense,
                title: "\(occasion.personName)'s \(occasion.occasion)",
                message: "Coming up on \(formatDate(occasion.date)). Budget: $\(Int(occasion.budgetAllocated))",
                priority: occasion.date < Calendar.current.date(byAdding: .day, value: 7, to: Date())! ? .high : .medium,
                actionable: true,
                action: "Find gift ideas"
            ))
        }

        self.contextualAlerts = alerts.sorted { $0.priority.rawValue > $1.priority.rawValue }
        updateSpendingRiskScore()
    }

    private func updateSpendingRiskScore() {
        var risk: Double = 50 // Baseline

        // Stress impact
        risk += (healthContext.stressLevel.spendingRiskMultiplier - 1) * 50

        // Sleep impact
        if let sleep = healthContext.lastNightSleep {
            if sleep < 5 { risk += 20 }
            else if sleep < 6 { risk += 15 }
            else if sleep < 7 { risk += 5 }
        }

        // Location impact
        if locationContext.currentMode == .shopping { risk += 15 }
        if locationContext.currentMode == .traveling { risk += 10 }

        // Time of day impact
        let hour = Calendar.current.component(.hour, from: Date())
        if hour >= 22 || hour < 6 { risk += 10 } // Late night shopping risk

        // Day of week impact
        let weekday = Calendar.current.component(.weekday, from: Date())
        if weekday == 6 || weekday == 7 { risk += 5 } // Weekend spending risk

        spendingRiskScore = max(0, min(100, risk))
    }

    func createSnapshot() -> LifeContextSnapshot {
        let upcomingEvents = calendarEvents.filter { $0.startDate > Date() }.sorted { $0.startDate < $1.startDate }
        let totalUpcomingCosts = upcomingEvents.reduce(0) { $0 + ($1.estimatedCost ?? 0) }

        let calendar = Calendar.current
        let startOfWeek = calendar.dateInterval(of: .weekOfYear, for: Date())?.start ?? Date()
        let endOfWeek = calendar.date(byAdding: .day, value: 7, to: startOfWeek) ?? Date()
        let busyDays = Set(calendarEvents.filter { $0.startDate >= startOfWeek && $0.startDate <= endOfWeek }.map {
            calendar.component(.day, from: $0.startDate)
        }).count

        let snapshot = LifeContextSnapshot(
            timestamp: Date(),
            calendar: LifeContextSnapshot.CalendarContext(
                upcomingEvents: Array(upcomingEvents.prefix(10)),
                totalUpcomingCosts: totalUpcomingCosts,
                busyDaysThisWeek: busyDays,
                hasUpcomingTravel: upcomingEvents.contains { $0.eventType == .travel },
                nextMajorEvent: upcomingEvents.first { ($0.estimatedCost ?? 0) > 100 }
            ),
            health: healthContext,
            location: locationContext,
            relationships: relationshipContext,
            spendingRiskScore: spendingRiskScore,
            recommendations: contextualAlerts
        )

        currentSnapshot = snapshot
        return snapshot
    }

    // MARK: - Persistence

    private func loadSavedData() {
        if let data = userDefaults.data(forKey: calendarEventsKey),
           let events = try? JSONDecoder().decode([CalendarEvent].self, from: data) {
            calendarEvents = events
        }

        if let data = userDefaults.data(forKey: healthContextKey),
           let context = try? JSONDecoder().decode(HealthContext.self, from: data) {
            healthContext = context
        }

        if let data = userDefaults.data(forKey: locationContextKey),
           let context = try? JSONDecoder().decode(LocationContext.self, from: data) {
            locationContext = context
        }

        if let data = userDefaults.data(forKey: relationshipContextKey),
           let context = try? JSONDecoder().decode(RelationshipContext.self, from: data) {
            relationshipContext = context
        }
    }

    private func saveCalendarEvents() {
        if let data = try? JSONEncoder().encode(calendarEvents) {
            userDefaults.set(data, forKey: calendarEventsKey)
        }
    }

    private func saveHealthContext() {
        healthContext.lastUpdated = Date()
        if let data = try? JSONEncoder().encode(healthContext) {
            userDefaults.set(data, forKey: healthContextKey)
        }
    }

    private func saveLocationContext() {
        if let data = try? JSONEncoder().encode(locationContext) {
            userDefaults.set(data, forKey: locationContextKey)
        }
    }

    private func saveRelationshipContext() {
        if let data = try? JSONEncoder().encode(relationshipContext) {
            userDefaults.set(data, forKey: relationshipContextKey)
        }
    }

    // MARK: - Helpers

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }

    func syncAll() {
        isLoading = true

        if calendarAccessGranted { fetchCalendarEvents() }
        if healthAccessGranted { fetchHealthData() }
        if locationAccessGranted { locationManager.requestLocation() }

        updateGiftOccasions()
        generateContextualAlerts()
        _ = createSnapshot()

        lastSyncTime = Date()
        isLoading = false
    }
}
