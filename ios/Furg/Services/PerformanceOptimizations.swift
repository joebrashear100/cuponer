//
//  PerformanceOptimizations.swift
//  Furg
//
//  Performance utilities and optimizations
//

import Foundation
import SwiftUI
import Combine

// MARK: - Debouncer

/// Debounces rapid calls to prevent excessive processing
final class Debouncer {
    private let delay: TimeInterval
    private var workItem: DispatchWorkItem?
    private let queue: DispatchQueue

    init(delay: TimeInterval, queue: DispatchQueue = .main) {
        self.delay = delay
        self.queue = queue
    }

    func debounce(action: @escaping () -> Void) {
        workItem?.cancel()
        workItem = DispatchWorkItem(block: action)
        queue.asyncAfter(deadline: .now() + delay, execute: workItem!)
    }

    func cancel() {
        workItem?.cancel()
    }
}

// MARK: - Throttler

/// Throttles calls to a maximum frequency
final class Throttler {
    private let interval: TimeInterval
    private var lastExecutionTime: Date?
    private let queue: DispatchQueue

    init(interval: TimeInterval, queue: DispatchQueue = .main) {
        self.interval = interval
        self.queue = queue
    }

    func throttle(action: @escaping () -> Void) {
        let now = Date()

        if let lastTime = lastExecutionTime,
           now.timeIntervalSince(lastTime) < interval {
            return
        }

        lastExecutionTime = now
        queue.async(execute: action)
    }
}

// MARK: - Lazy Loading List

/// Optimized list that loads items lazily with prefetching
struct LazyLoadingList<Data: RandomAccessCollection, Content: View, Placeholder: View>: View
where Data.Element: Identifiable, Data.Index: Hashable {

    let data: Data
    let content: (Data.Element) -> Content
    let placeholder: () -> Placeholder
    let onLoadMore: (() -> Void)?
    let loadMoreThreshold: Int

    @State private var visibleIndices: Set<Data.Index> = []

    init(
        _ data: Data,
        loadMoreThreshold: Int = 5,
        onLoadMore: (() -> Void)? = nil,
        @ViewBuilder content: @escaping (Data.Element) -> Content,
        @ViewBuilder placeholder: @escaping () -> Placeholder
    ) {
        self.data = data
        self.loadMoreThreshold = loadMoreThreshold
        self.onLoadMore = onLoadMore
        self.content = content
        self.placeholder = placeholder
    }

    var body: some View {
        LazyVStack(spacing: 0) {
            ForEach(Array(data.enumerated()), id: \.element.id) { index, item in
                content(item)
                    .onAppear {
                        checkLoadMore(index: index)
                    }
            }
        }
    }

    private func checkLoadMore(index: Int) {
        let itemIndex = data.index(data.startIndex, offsetBy: index)
        let endIndex = data.index(data.endIndex, offsetBy: -loadMoreThreshold)

        if itemIndex >= endIndex {
            onLoadMore?()
        }
    }
}

// MARK: - Optimized ScrollView

/// ScrollView with performance optimizations
struct OptimizedScrollView<Content: View>: View {
    let showsIndicators: Bool
    let content: Content

    @State private var contentSize: CGSize = .zero

    init(
        showsIndicators: Bool = false,
        @ViewBuilder content: () -> Content
    ) {
        self.showsIndicators = showsIndicators
        self.content = content()
    }

    var body: some View {
        ScrollView(showsIndicators: showsIndicators) {
            content
                .background(
                    GeometryReader { geometry in
                        Color.clear.preference(
                            key: ContentSizePreferenceKey.self,
                            value: geometry.size
                        )
                    }
                )
        }
        .onPreferenceChange(ContentSizePreferenceKey.self) { size in
            contentSize = size
        }
    }
}

private struct ContentSizePreferenceKey: PreferenceKey {
    static var defaultValue: CGSize = .zero
    static func reduce(value: inout CGSize, nextValue: () -> CGSize) {
        value = nextValue()
    }
}

// MARK: - Background Task Manager

final class BackgroundTaskManager {
    static let shared = BackgroundTaskManager()

    private var backgroundTask: UIBackgroundTaskIdentifier = .invalid

    private init() {}

    func beginBackgroundTask(name: String, expirationHandler: (() -> Void)? = nil) {
        endBackgroundTask()

        backgroundTask = UIApplication.shared.beginBackgroundTask(withName: name) {
            expirationHandler?()
            self.endBackgroundTask()
        }
    }

    func endBackgroundTask() {
        guard backgroundTask != .invalid else { return }
        UIApplication.shared.endBackgroundTask(backgroundTask)
        backgroundTask = .invalid
    }

    var remainingBackgroundTime: TimeInterval {
        UIApplication.shared.backgroundTimeRemaining
    }
}

// MARK: - Memory Monitor

final class MemoryMonitor: ObservableObject {
    static let shared = MemoryMonitor()

    @Published var memoryUsage: UInt64 = 0
    @Published var memoryWarning = false

    private var timer: Timer?

    private init() {
        startMonitoring()

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(didReceiveMemoryWarning),
            name: UIApplication.didReceiveMemoryWarningNotification,
            object: nil
        )
    }

    private func startMonitoring() {
        timer = Timer.scheduledTimer(withTimeInterval: 5, repeats: true) { [weak self] _ in
            self?.updateMemoryUsage()
        }
    }

    private func updateMemoryUsage() {
        var info = mach_task_basic_info()
        var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size) / 4

        let result = withUnsafeMutablePointer(to: &info) {
            $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
                task_info(mach_task_self_, task_flavor_t(MACH_TASK_BASIC_INFO), $0, &count)
            }
        }

        if result == KERN_SUCCESS {
            DispatchQueue.main.async {
                self.memoryUsage = info.resident_size
            }
        }
    }

    @objc private func didReceiveMemoryWarning() {
        DispatchQueue.main.async {
            self.memoryWarning = true
        }

        // Clear caches
        CacheManager.shared.clearMemoryCache()

        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            self.memoryWarning = false
        }
    }

    var formattedMemoryUsage: String {
        ByteCountFormatter.string(fromByteCount: Int64(memoryUsage), countStyle: .memory)
    }
}

// MARK: - Render Performance

/// Wrapper to prevent unnecessary re-renders
struct EquatableView<Content: View, Value: Equatable>: View, Equatable {
    let value: Value
    let content: (Value) -> Content

    init(_ value: Value, @ViewBuilder content: @escaping (Value) -> Content) {
        self.value = value
        self.content = content
    }

    var body: some View {
        content(value)
    }

    static func == (lhs: EquatableView<Content, Value>, rhs: EquatableView<Content, Value>) -> Bool {
        lhs.value == rhs.value
    }
}

// MARK: - Animation Performance

extension View {
    /// Only applies animation when conditions are met (e.g., not reduced motion)
    func conditionalAnimation<V: Equatable>(
        _ animation: Animation?,
        value: V,
        condition: Bool = true
    ) -> some View {
        self.animation(condition ? animation : nil, value: value)
    }

    /// Prevents layout thrashing by using fixed frames
    func optimizedFrame(width: CGFloat? = nil, height: CGFloat? = nil) -> some View {
        self
            .frame(width: width, height: height)
            .fixedSize(horizontal: width != nil, vertical: height != nil)
    }
}

// MARK: - Prefetch Manager

final class PrefetchManager {
    static let shared = PrefetchManager()

    private var prefetchTasks: [String: Task<Void, Never>] = [:]
    private let queue = DispatchQueue(label: "com.furg.prefetch", qos: .utility)

    private init() {}

    func prefetch<T>(
        key: String,
        fetch: @escaping () async throws -> T,
        store: @escaping (T) -> Void
    ) {
        // Cancel existing task for this key
        prefetchTasks[key]?.cancel()

        prefetchTasks[key] = Task {
            do {
                let result = try await fetch()
                await MainActor.run {
                    store(result)
                }
            } catch {
                // Silently fail prefetch
            }
            prefetchTasks.removeValue(forKey: key)
        }
    }

    func cancelPrefetch(key: String) {
        prefetchTasks[key]?.cancel()
        prefetchTasks.removeValue(forKey: key)
    }

    func cancelAllPrefetches() {
        prefetchTasks.values.forEach { $0.cancel() }
        prefetchTasks.removeAll()
    }
}

// MARK: - Search Optimization

/// Optimized search with debouncing and caching
class SearchManager<Result: Identifiable>: ObservableObject {
    @Published var query = ""
    @Published var results: [Result] = []
    @Published var isSearching = false

    private var searchTask: Task<Void, Never>?
    private let debouncer = Debouncer(delay: 0.3)
    private var searchCache: [String: [Result]] = [:]
    private let maxCacheSize = 20

    func search(using searchFunction: @escaping (String) async -> [Result]) {
        debouncer.debounce { [weak self] in
            guard let self = self else { return }

            let searchQuery = self.query.trimmingCharacters(in: .whitespaces)

            // Check cache
            if let cached = self.searchCache[searchQuery] {
                self.results = cached
                return
            }

            // Cancel previous search
            self.searchTask?.cancel()

            guard !searchQuery.isEmpty else {
                self.results = []
                return
            }

            self.isSearching = true

            self.searchTask = Task {
                let searchResults = await searchFunction(searchQuery)

                await MainActor.run {
                    self.results = searchResults
                    self.isSearching = false

                    // Cache results
                    self.cacheResults(searchResults, for: searchQuery)
                }
            }
        }
    }

    private func cacheResults(_ results: [Result], for query: String) {
        if searchCache.count >= maxCacheSize {
            // Remove oldest entry (simple FIFO)
            if let firstKey = searchCache.keys.first {
                searchCache.removeValue(forKey: firstKey)
            }
        }
        searchCache[query] = results
    }

    func clearCache() {
        searchCache.removeAll()
    }
}
