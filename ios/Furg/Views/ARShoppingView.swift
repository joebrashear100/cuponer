//
//  ARShoppingView.swift
//  Furg
//
//  Created for radical life integration - AR shopping experience
//

import SwiftUI
import AVFoundation
import ARKit

struct ARShoppingView: View {
    @StateObject private var arManager = ARShoppingManager.shared
    @StateObject private var viewModel = ARShoppingViewModel()
    @State private var showingPermissionAlert = false
    @State private var showingProductDetail = false
    @State private var selectedProduct: ARProductDetection?
    @State private var showingSessionSummary = false
    @State private var flashEnabled = false

    var body: some View {
        ZStack {
            // Camera preview
            if viewModel.cameraPermissionGranted {
                CameraPreviewView(viewModel: viewModel)
                    .ignoresSafeArea()

                // AR Annotations overlay
                ARAnnotationsOverlay(
                    annotations: arManager.annotations,
                    detectedProducts: arManager.detectedProducts,
                    onProductTap: { product in
                        selectedProduct = product
                        showingProductDetail = true
                    }
                )

                // Top controls
                VStack {
                    ARTopControlsView(
                        isSessionActive: arManager.isSessionActive,
                        flashEnabled: $flashEnabled,
                        onFlashToggle: { viewModel.toggleFlash() },
                        onClose: { viewModel.stopSession() }
                    )

                    Spacer()

                    // Bottom info and controls
                    ARBottomControlsView(
                        detectedCount: arManager.detectedProducts.count,
                        sessionDuration: 0,
                        isSessionActive: arManager.isSessionActive,
                        onStartSession: {
                            arManager.startShoppingSession()
                            viewModel.startCapturing()
                        },
                        onEndSession: {
                            arManager.endShoppingSession()
                            showingSessionSummary = true
                        }
                    )
                }
                .padding()
            } else {
                // Permission request view
                CameraPermissionView(
                    onRequestPermission: {
                        viewModel.requestCameraPermission()
                    }
                )
            }
        }
        .navigationTitle("AR Shopping")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            viewModel.checkCameraPermission()
        }
        .onDisappear {
            viewModel.stopSession()
            if arManager.isSessionActive {
                arManager.endShoppingSession()
            }
        }
        .alert("Camera Access Required", isPresented: $showingPermissionAlert) {
            Button("Settings") {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("Please enable camera access in Settings to use AR Shopping.")
        }
        .sheet(isPresented: $showingProductDetail) {
            if let product = selectedProduct {
                ProductDetailSheet(product: product)
            }
        }
        .sheet(isPresented: $showingSessionSummary) {
            SessionSummarySheet(session: arManager.pastSessions.first)
        }
    }
}

// MARK: - View Model

class ARShoppingViewModel: NSObject, ObservableObject {
    @Published var cameraPermissionGranted = false
    @Published var isCapturing = false

    private var captureSession: AVCaptureSession?
    private var videoOutput: AVCaptureVideoDataOutput?
    private let sessionQueue = DispatchQueue(label: "camera.session.queue")
    private let processingQueue = DispatchQueue(label: "frame.processing.queue")

    var previewLayer: AVCaptureVideoPreviewLayer?

    func checkCameraPermission() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            cameraPermissionGranted = true
            setupCaptureSession()
        case .notDetermined:
            requestCameraPermission()
        default:
            cameraPermissionGranted = false
        }
    }

    func requestCameraPermission() {
        AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
            DispatchQueue.main.async {
                self?.cameraPermissionGranted = granted
                if granted {
                    self?.setupCaptureSession()
                }
            }
        }
    }

    private func setupCaptureSession() {
        sessionQueue.async { [weak self] in
            guard let self = self else { return }

            let session = AVCaptureSession()
            session.sessionPreset = .high

            guard let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back),
                  let input = try? AVCaptureDeviceInput(device: device) else {
                return
            }

            if session.canAddInput(input) {
                session.addInput(input)
            }

            let output = AVCaptureVideoDataOutput()
            output.setSampleBufferDelegate(self, queue: self.processingQueue)
            output.alwaysDiscardsLateVideoFrames = true

            if session.canAddOutput(output) {
                session.addOutput(output)
            }

            self.captureSession = session
            self.videoOutput = output

            DispatchQueue.main.async {
                self.previewLayer = AVCaptureVideoPreviewLayer(session: session)
                self.previewLayer?.videoGravity = .resizeAspectFill
            }
        }
    }

    func startCapturing() {
        sessionQueue.async { [weak self] in
            self?.captureSession?.startRunning()
            DispatchQueue.main.async {
                self?.isCapturing = true
            }
        }
    }

    func stopSession() {
        sessionQueue.async { [weak self] in
            self?.captureSession?.stopRunning()
            DispatchQueue.main.async {
                self?.isCapturing = false
            }
        }
    }

    func toggleFlash() {
        guard let device = AVCaptureDevice.default(for: .video),
              device.hasTorch else { return }

        try? device.lockForConfiguration()
        device.torchMode = device.torchMode == .on ? .off : .on
        device.unlockForConfiguration()
    }
}

extension ARShoppingViewModel: AVCaptureVideoDataOutputSampleBufferDelegate {
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }

        // Process every 10th frame to avoid overwhelming
        Task {
            let results = await ARShoppingManager.shared.processFrame(pixelBuffer)

            for result in results {
                let _ = ARShoppingManager.shared.analyzeProduct(result)
            }
        }
    }
}

// MARK: - Camera Preview

struct CameraPreviewView: UIViewRepresentable {
    @ObservedObject var viewModel: ARShoppingViewModel

    func makeUIView(context: Context) -> UIView {
        let view = UIView(frame: .zero)
        view.backgroundColor = .black

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            if let previewLayer = viewModel.previewLayer {
                previewLayer.frame = view.bounds
                view.layer.addSublayer(previewLayer)
            }
        }

        return view
    }

    func updateUIView(_ uiView: UIView, context: Context) {
        viewModel.previewLayer?.frame = uiView.bounds
    }
}

// MARK: - Permission View

struct CameraPermissionView: View {
    let onRequestPermission: () -> Void

    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "camera.viewfinder")
                .font(.system(size: 80))
                .foregroundColor(.blue)

            Text("AR Shopping")
                .font(.title)
                .fontWeight(.bold)

            Text("Point your camera at products to see instant affordability analysis, price comparisons, and the best card to use.")
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
                .padding(.horizontal, 32)

            VStack(alignment: .leading, spacing: 16) {
                FeatureRow(icon: "dollarsign.circle.fill", text: "See prices in hours of your work")
                FeatureRow(icon: "creditcard.fill", text: "Best card recommendations")
                FeatureRow(icon: "chart.bar.fill", text: "Price comparisons across stores")
                FeatureRow(icon: "brain.head.profile", text: "Smart affordability insights")
            }
            .padding(.vertical)

            Button(action: onRequestPermission) {
                Text("Enable Camera")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .cornerRadius(12)
            }
            .padding(.horizontal, 32)
        }
        .padding()
    }
}

struct FeatureRow: View {
    let icon: String
    let text: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(.blue)
                .frame(width: 24)
            Text(text)
                .foregroundColor(.primary)
        }
    }
}

// MARK: - AR Annotations Overlay

struct ARAnnotationsOverlay: View {
    let annotations: [ARAnnotation]
    let detectedProducts: [ARProductDetection]
    let onProductTap: (ARProductDetection) -> Void

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Product detection cards
                ForEach(detectedProducts) { product in
                    ProductAnnotationCard(product: product)
                        .position(
                            x: geometry.size.width * CGFloat.random(in: 0.2...0.8),
                            y: geometry.size.height * CGFloat.random(in: 0.3...0.7)
                        )
                        .onTapGesture {
                            onProductTap(product)
                        }
                }

                // Scanning indicator
                ScanningIndicator()
                    .position(x: geometry.size.width / 2, y: geometry.size.height / 2)
            }
        }
    }
}

struct ProductAnnotationCard: View {
    let product: ARProductDetection

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Product name and price
            HStack {
                Text(product.productName)
                    .font(.headline)
                    .lineLimit(1)
                Spacer()
                if let price = product.detectedPrice {
                    Text(CurrencyFormatter.format(price))
                        .font(.headline)
                        .foregroundColor(.green)
                }
            }

            // Affordability indicator
            if let affordability = product.affordabilityAnalysis {
                HStack(spacing: 4) {
                    Image(systemName: AffordabilityColors.icon(for: affordability.impactLevel.rawValue))
                        .foregroundColor(AffordabilityColors.color(for: affordability.impactLevel.rawValue))
                    Text("\(String(format: "%.1f", affordability.hoursOfWork)) hours of work")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            // Best card recommendation
            if let card = product.bestCard {
                HStack(spacing: 4) {
                    Image(systemName: "creditcard.fill")
                        .font(.caption)
                        .foregroundColor(.blue)
                    Text("Use \(card.cardName)")
                        .font(.caption)
                        .foregroundColor(.blue)
                    if card.estimatedReward > 0 {
                        Text("(\(CurrencyFormatter.format(card.estimatedReward)) back)")
                            .font(.caption2)
                            .foregroundColor(.green)
                    }
                }
            }

            // Price comparison badge
            if let comparison = product.priceComparison, comparison.potentialSavings > 0 {
                HStack(spacing: 4) {
                    Image(systemName: "arrow.down.circle.fill")
                        .foregroundColor(.orange)
                    Text("Save \(CurrencyFormatter.format(comparison.potentialSavings)) at \(comparison.bestPrice?.store ?? "other store")")
                        .font(.caption)
                        .foregroundColor(.orange)
                }
            }
        }
        .padding(12)
        .background(Color.white.opacity(0.03))
        .cornerRadius(12)
        .frame(width: 220)
        .shadow(radius: 8)
    }
}

struct ScanningIndicator: View {
    @State private var isAnimating = false

    var body: some View {
        ZStack {
            // Corner brackets
            ForEach(0..<4) { index in
                ScannerCorner()
                    .rotationEffect(.degrees(Double(index) * 90))
            }
        }
        .frame(width: 200, height: 200)
        .opacity(0.8)
        .scaleEffect(isAnimating ? 1.05 : 0.95)
        .animation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true), value: isAnimating)
        .onAppear {
            isAnimating = true
        }
    }
}

struct ScannerCorner: View {
    var body: some View {
        Path { path in
            path.move(to: CGPoint(x: -80, y: -100))
            path.addLine(to: CGPoint(x: -100, y: -100))
            path.addLine(to: CGPoint(x: -100, y: -80))
        }
        .stroke(Color.white, lineWidth: 3)
    }
}

// MARK: - Top Controls

struct ARTopControlsView: View {
    let isSessionActive: Bool
    @Binding var flashEnabled: Bool
    let onFlashToggle: () -> Void
    let onClose: () -> Void

    var body: some View {
        HStack {
            // Session status
            if isSessionActive {
                HStack(spacing: 6) {
                    Circle()
                        .fill(Color.red)
                        .frame(width: 8, height: 8)
                    Text("Shopping")
                        .font(.caption)
                        .fontWeight(.medium)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color.white.opacity(0.03))
                .cornerRadius(20)
            }

            Spacer()

            // Flash toggle
            Button(action: {
                flashEnabled.toggle()
                onFlashToggle()
            }) {
                Image(systemName: flashEnabled ? "bolt.fill" : "bolt.slash.fill")
                    .font(.title3)
                    .foregroundColor(.white)
                    .padding(10)
                    .background(Color.white.opacity(0.03))
                    .clipShape(Circle())
            }
        }
    }
}

// MARK: - Bottom Controls

struct ARBottomControlsView: View {
    let detectedCount: Int
    let sessionDuration: TimeInterval
    let isSessionActive: Bool
    let onStartSession: () -> Void
    let onEndSession: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            // Stats bar
            if isSessionActive {
                HStack(spacing: 24) {
                    StatBadge(icon: "tag.fill", value: "\(detectedCount)", label: "Products")
                    StatBadge(icon: "clock.fill", value: formatDuration(sessionDuration), label: "Duration")
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
                .background(Color.white.opacity(0.03))
                .cornerRadius(16)
            }

            // Main action button
            Button(action: {
                if isSessionActive {
                    onEndSession()
                } else {
                    onStartSession()
                }
            }) {
                HStack {
                    Image(systemName: isSessionActive ? "stop.fill" : "viewfinder")
                    Text(isSessionActive ? "End Session" : "Start Shopping")
                }
                .font(.headline)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(isSessionActive ? Color.red : Color.blue)
                .cornerRadius(12)
            }
        }
    }

    private func formatDuration(_ duration: TimeInterval) -> String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}

struct StatBadge: View {
    let icon: String
    let value: String
    let label: String

    var body: some View {
        VStack(spacing: 4) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.caption)
                Text(value)
                    .fontWeight(.bold)
            }
            Text(label)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
    }
}

// MARK: - Product Detail Sheet

struct ProductDetailSheet: View {
    let product: ARProductDetection
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Main product info
                    VStack(alignment: .leading, spacing: 8) {
                        Text(product.productName)
                            .font(.title2)
                            .fontWeight(.bold)

                        HStack {
                            if let price = product.detectedPrice {
                                Text(CurrencyFormatter.format(price))
                                    .font(.title)
                                    .fontWeight(.bold)
                                    .foregroundColor(.green)
                            }

                            Spacer()

                            Text(product.category)
                                .font(.caption)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(Color.blue.opacity(0.1))
                                .cornerRadius(8)
                        }
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)

                    // Affordability Analysis
                    if let affordability = product.affordabilityAnalysis {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Affordability Analysis")
                                .font(.headline)

                            AffordabilityRow(
                                icon: "clock",
                                title: "Time Cost",
                                value: "\(String(format: "%.1f", affordability.hoursOfWork)) hours of work"
                            )

                            AffordabilityRow(
                                icon: "chart.pie",
                                title: "Budget Impact",
                                value: "\(String(format: "%.1f", affordability.percentOfMonthlyBudget))% of monthly budget"
                            )

                            AffordabilityRow(
                                icon: "chart.bar",
                                title: "Discretionary Spend",
                                value: "\(String(format: "%.1f", affordability.percentOfDailyBudget))% of daily budget"
                            )

                            HStack {
                                Text("Overall:")
                                    .fontWeight(.medium)
                                Spacer()
                                Text(AffordabilityColors.displayText(for: affordability.impactLevel.rawValue))
                                    .fontWeight(.bold)
                                    .foregroundColor(AffordabilityColors.color(for: affordability.impactLevel.rawValue))
                            }
                            .padding(.top, 8)
                        }
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(12)
                    }

                    // Card Recommendation
                    if let card = product.bestCard {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Best Card to Use")
                                .font(.headline)

                            HStack {
                                Image(systemName: "creditcard.fill")
                                    .font(.title2)
                                    .foregroundColor(.blue)

                                VStack(alignment: .leading) {
                                    Text(card.cardName)
                                        .fontWeight(.semibold)
                                    Text("\(String(format: "%.1f", card.rewardRate))% \(card.rewardType)")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }

                                Spacer()

                                Text("+\(CurrencyFormatter.format(card.estimatedReward))")
                                    .font(.title3)
                                    .fontWeight(.bold)
                                    .foregroundColor(.green)
                            }

                            if let offer = card.specialOffer {
                                Text(offer)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(12)
                    }

                    // Price Comparison
                    if let comparison = product.priceComparison {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Price Comparison")
                                .font(.headline)

                            ForEach(comparison.alternatives) { storePrice in
                                HStack {
                                    Text(storePrice.store)
                                    Spacer()
                                    Text(CurrencyFormatter.format(storePrice.price))
                                        .fontWeight(storePrice.store == comparison.bestPrice?.store ? .bold : .regular)
                                        .foregroundColor(storePrice.store == comparison.bestPrice?.store ? .green : .primary)
                                    if storePrice.store == comparison.bestPrice?.store {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundColor(.green)
                                    }
                                }
                            }

                            if comparison.potentialSavings > 0 {
                                HStack {
                                    Text("Potential Savings:")
                                        .fontWeight(.medium)
                                    Spacer()
                                    Text(CurrencyFormatter.format(comparison.potentialSavings))
                                        .fontWeight(.bold)
                                        .foregroundColor(.green)
                                }
                                .padding(.top, 8)
                            }
                        }
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(12)
                    }

                    // Actions
                    VStack(spacing: 12) {
                        Button(action: {
                            ARShoppingManager.shared.addToWishlist(product.id)
                        }) {
                            Label("Add to Wishlist", systemImage: "heart")
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.blue)
                                .foregroundColor(.white)
                                .cornerRadius(12)
                        }

                        Button(action: {
                            // Set price alert
                        }) {
                            Label("Set Price Alert", systemImage: "bell")
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color(.systemGray5))
                                .foregroundColor(.primary)
                                .cornerRadius(12)
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("Product Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct AffordabilityRow: View {
    let icon: String
    let title: String
    let value: String

    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(.blue)
                .frame(width: 24)
            Text(title)
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .fontWeight(.medium)
        }
    }
}

// MARK: - Session Summary Sheet

struct SessionSummarySheet: View {
    let session: ARShoppingSession?
    @Environment(\.dismiss) private var dismiss

    private var sessionDuration: TimeInterval {
        guard let session = session else { return 0 }
        let endTime = session.endTime ?? Date()
        return endTime.timeIntervalSince(session.startTime)
    }

    var body: some View {
        NavigationView {
            if let session = session {
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        // Session stats
                        HStack(spacing: 16) {
                            SessionStatCard(
                                icon: "tag.fill",
                                value: "\(session.detectedProducts.count)",
                                label: "Products Scanned",
                                color: .blue
                            )

                            SessionStatCard(
                                icon: "clock.fill",
                                value: TimeFormatter.formatDurationReadable(sessionDuration),
                                label: "Duration",
                                color: .purple
                            )
                        }

                        // Store visited
                        if let storeName = session.storeName {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Store Visited")
                                    .font(.headline)

                                HStack {
                                    Image(systemName: "building.2")
                                        .foregroundColor(.blue)
                                    Text(storeName)
                                    Spacer()
                                }
                                .padding(.vertical, 4)
                            }
                            .padding()
                            .background(Color(.systemGray6))
                            .cornerRadius(12)
                        }

                        // Scanned items
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Items Scanned")
                                .font(.headline)

                            ForEach(session.detectedProducts) { product in
                                HStack {
                                    Image(systemName: "barcode.viewfinder")
                                        .foregroundColor(.green)
                                    Text(product.productName)
                                    Spacer()
                                    if let price = product.detectedPrice {
                                        Text(CurrencyFormatter.format(price))
                                            .foregroundColor(.secondary)
                                    }
                                }
                                .padding(.vertical, 4)
                            }

                            if session.detectedProducts.isEmpty {
                                Text("No items were scanned in this session")
                                    .foregroundColor(.secondary)
                                    .italic()
                            }
                        }
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(12)

                        // Financial summary
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Financial Summary")
                                .font(.headline)

                            HStack {
                                Text("Total Potential Spend:")
                                Spacer()
                                Text(CurrencyFormatter.format(session.totalPotentialSpend))
                                    .fontWeight(.semibold)
                            }

                            HStack {
                                Text("Potential Savings Found:")
                                Spacer()
                                Text(CurrencyFormatter.format(session.totalPotentialSavings))
                                    .fontWeight(.semibold)
                                    .foregroundColor(.green)
                            }

                            HStack {
                                Text("Items Added to Cart:")
                                Spacer()
                                Text("\(session.productsAddedToCart.count)")
                                    .fontWeight(.semibold)
                            }
                        }
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(12)

                        // Summary insights
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Session Insights")
                                .font(.headline)

                            Text("You scanned \(session.detectedProducts.count) products\(session.storeName != nil ? " at \(session.storeName!)" : "") during your shopping trip.")
                                .foregroundColor(.secondary)
                        }
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(12)
                    }
                    .padding()
                }
                .navigationTitle("Shopping Summary")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("Done") {
                            dismiss()
                        }
                    }
                }
            } else {
                VStack {
                    Text("No session data available")
                        .foregroundColor(.secondary)
                }
                .navigationTitle("Shopping Summary")
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("Done") {
                            dismiss()
                        }
                    }
                }
            }
        }
    }
}

struct SessionStatCard: View {
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
                .font(.title)
                .fontWeight(.bold)

            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

#Preview {
    NavigationView {
        ARShoppingView()
    }
}
