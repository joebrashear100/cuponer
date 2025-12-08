//
//  CacheManager.swift
//  Furg
//
//  Centralized caching for improved performance
//

import Foundation
import SwiftUI

final class CacheManager {
    static let shared = CacheManager()

    // Memory caches
    private let memoryCache = NSCache<NSString, AnyObject>()
    private let imageCache = NSCache<NSString, UIImage>()

    // Disk cache directory
    private let cacheDirectory: URL

    // Cache expiration
    private var expirationTimes: [String: Date] = [:]
    private let defaultExpiration: TimeInterval = 300 // 5 minutes

    private init() {
        // Configure memory cache limits
        memoryCache.countLimit = 100
        memoryCache.totalCostLimit = 50 * 1024 * 1024 // 50 MB

        imageCache.countLimit = 50
        imageCache.totalCostLimit = 30 * 1024 * 1024 // 30 MB

        // Setup disk cache directory
        let fileManager = FileManager.default
        let cachesDirectory = fileManager.urls(for: .cachesDirectory, in: .userDomainMask).first!
        cacheDirectory = cachesDirectory.appendingPathComponent("FurgCache", isDirectory: true)

        try? fileManager.createDirectory(at: cacheDirectory, withIntermediateDirectories: true)

        // Clean expired cache on init
        cleanExpiredCache()

        // Observe memory warnings
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleMemoryWarning),
            name: UIApplication.didReceiveMemoryWarningNotification,
            object: nil
        )
    }

    // MARK: - Memory Cache

    func set<T: AnyObject>(_ object: T, forKey key: String, expiration: TimeInterval? = nil) {
        let cacheKey = NSString(string: key)
        memoryCache.setObject(object, forKey: cacheKey)
        expirationTimes[key] = Date().addingTimeInterval(expiration ?? defaultExpiration)
    }

    func get<T: AnyObject>(forKey key: String) -> T? {
        // Check expiration
        if let expirationTime = expirationTimes[key], Date() > expirationTime {
            remove(forKey: key)
            return nil
        }

        let cacheKey = NSString(string: key)
        return memoryCache.object(forKey: cacheKey) as? T
    }

    func remove(forKey key: String) {
        let cacheKey = NSString(string: key)
        memoryCache.removeObject(forKey: cacheKey)
        expirationTimes.removeValue(forKey: key)
    }

    // MARK: - Codable Cache

    func setCodable<T: Codable>(_ object: T, forKey key: String, expiration: TimeInterval? = nil) {
        if let data = try? JSONEncoder().encode(object) {
            set(data as AnyObject, forKey: key, expiration: expiration)

            // Also save to disk for persistence
            saveToDisk(data, forKey: key)
        }
    }

    func getCodable<T: Codable>(forKey key: String) -> T? {
        // Try memory cache first
        if let data: Data = get(forKey: key) {
            return try? JSONDecoder().decode(T.self, from: data)
        }

        // Try disk cache
        if let data = loadFromDisk(forKey: key) {
            // Restore to memory cache
            set(data as AnyObject, forKey: key)
            return try? JSONDecoder().decode(T.self, from: data)
        }

        return nil
    }

    // MARK: - Image Cache

    func setImage(_ image: UIImage, forKey key: String) {
        let cacheKey = NSString(string: key)
        imageCache.setObject(image, forKey: cacheKey)

        // Save to disk
        if let data = image.jpegData(compressionQuality: 0.8) {
            saveToDisk(data, forKey: "img_\(key)")
        }
    }

    func getImage(forKey key: String) -> UIImage? {
        let cacheKey = NSString(string: key)

        // Try memory cache
        if let image = imageCache.object(forKey: cacheKey) {
            return image
        }

        // Try disk cache
        if let data = loadFromDisk(forKey: "img_\(key)"),
           let image = UIImage(data: data) {
            imageCache.setObject(image, forKey: cacheKey)
            return image
        }

        return nil
    }

    // MARK: - Disk Cache

    private func saveToDisk(_ data: Data, forKey key: String) {
        let fileURL = cacheDirectory.appendingPathComponent(key.md5Hash)
        try? data.write(to: fileURL)
    }

    private func loadFromDisk(forKey key: String) -> Data? {
        let fileURL = cacheDirectory.appendingPathComponent(key.md5Hash)
        return try? Data(contentsOf: fileURL)
    }

    private func removeFromDisk(forKey key: String) {
        let fileURL = cacheDirectory.appendingPathComponent(key.md5Hash)
        try? FileManager.default.removeItem(at: fileURL)
    }

    // MARK: - Cache Management

    func clearMemoryCache() {
        memoryCache.removeAllObjects()
        imageCache.removeAllObjects()
        expirationTimes.removeAll()
    }

    func clearDiskCache() {
        try? FileManager.default.removeItem(at: cacheDirectory)
        try? FileManager.default.createDirectory(at: cacheDirectory, withIntermediateDirectories: true)
    }

    func clearAllCache() {
        clearMemoryCache()
        clearDiskCache()
    }

    private func cleanExpiredCache() {
        let now = Date()
        for (key, expiration) in expirationTimes where now > expiration {
            remove(forKey: key)
        }
    }

    @objc private func handleMemoryWarning() {
        clearMemoryCache()
    }

    // MARK: - Cache Stats

    var memoryCacheCount: Int {
        // NSCache doesn't expose count, so we track expiration times as proxy
        expirationTimes.count
    }

    var diskCacheSize: Int64 {
        let fileManager = FileManager.default
        guard let files = try? fileManager.contentsOfDirectory(at: cacheDirectory, includingPropertiesForKeys: [.fileSizeKey]) else {
            return 0
        }

        return files.reduce(0) { total, file in
            let size = (try? file.resourceValues(forKeys: [.fileSizeKey]).fileSize) ?? 0
            return total + Int64(size)
        }
    }
}

// MARK: - String Extension for Hashing

extension String {
    var md5Hash: String {
        let data = Data(self.utf8)
        var hash = [UInt8](repeating: 0, count: Int(CC_MD5_DIGEST_LENGTH))

        _ = data.withUnsafeBytes { buffer in
            CC_MD5(buffer.baseAddress, CC_LONG(data.count), &hash)
        }

        return hash.map { String(format: "%02x", $0) }.joined()
    }
}

// Import for MD5
import CommonCrypto

// MARK: - Cached Image View

struct CachedAsyncImage: View {
    let url: URL?
    let placeholder: Image
    let errorImage: Image

    @State private var image: UIImage?
    @State private var isLoading = false
    @State private var hasError = false

    init(
        url: URL?,
        placeholder: Image = Image(systemName: "photo"),
        errorImage: Image = Image(systemName: "exclamationmark.triangle")
    ) {
        self.url = url
        self.placeholder = placeholder
        self.errorImage = errorImage
    }

    var body: some View {
        Group {
            if let image = image {
                Image(uiImage: image)
                    .resizable()
            } else if hasError {
                errorImage
                    .foregroundColor(.white.opacity(0.3))
            } else if isLoading {
                ProgressView()
            } else {
                placeholder
                    .foregroundColor(.white.opacity(0.3))
            }
        }
        .onAppear {
            loadImage()
        }
    }

    private func loadImage() {
        guard let url = url else { return }

        let cacheKey = url.absoluteString

        // Check cache first
        if let cachedImage = CacheManager.shared.getImage(forKey: cacheKey) {
            self.image = cachedImage
            return
        }

        // Load from network
        isLoading = true

        Task {
            do {
                let (data, _) = try await URLSession.shared.data(from: url)
                if let downloadedImage = UIImage(data: data) {
                    CacheManager.shared.setImage(downloadedImage, forKey: cacheKey)
                    await MainActor.run {
                        self.image = downloadedImage
                        self.isLoading = false
                    }
                }
            } catch {
                await MainActor.run {
                    self.hasError = true
                    self.isLoading = false
                }
            }
        }
    }
}
