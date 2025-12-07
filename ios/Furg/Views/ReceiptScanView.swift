//
//  ReceiptScanView.swift
//  Furg
//
//  Beautiful receipt scanning interface with camera and results
//

import SwiftUI
import PhotosUI

struct ReceiptScanView: View {
    @StateObject private var scanner = ReceiptScanner()
    @Environment(\.dismiss) var dismiss
    @State private var showImagePicker = false
    @State private var showCamera = false
    @State private var selectedImage: UIImage?
    @State private var showResults = false
    @State private var animate = false

    var body: some View {
        NavigationStack {
            ZStack {
                Color.furgCharcoal.ignoresSafeArea()

                LinearGradient(
                    colors: [Color.furgMint.opacity(0.05), Color.clear],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 32) {
                        if scanner.lastReceipt == nil || !showResults {
                            scanSection
                        } else {
                            resultsSection
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                    .padding(.bottom, 100)
                }

                // Scanning overlay
                if scanner.isScanning {
                    scanningOverlay
                }
            }
            .navigationTitle("Scan Receipt")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                        .foregroundColor(.furgMint)
                }
            }
            .sheet(isPresented: $showImagePicker) {
                PhotoPicker(image: $selectedImage)
            }
            .sheet(isPresented: $showCamera) {
                CameraPicker(image: $selectedImage)
            }
            .onChange(of: selectedImage) { _, newImage in
                if let image = newImage {
                    Task {
                        await scanner.scanReceipt(from: image)
                        withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                            showResults = true
                        }
                    }
                }
            }
            .onAppear {
                withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                    animate = true
                }
            }
        }
    }

    // MARK: - Scan Section

    private var scanSection: some View {
        VStack(spacing: 40) {
            // Hero illustration
            VStack(spacing: 20) {
                ZStack {
                    // Scanning animation
                    ForEach(0..<3) { i in
                        Circle()
                            .stroke(Color.furgMint.opacity(0.3 - Double(i) * 0.1), lineWidth: 2)
                            .frame(width: CGFloat(100 + i * 40), height: CGFloat(100 + i * 40))
                            .scaleEffect(animate ? 1.1 : 1.0)
                            .animation(
                                .easeInOut(duration: 1.5)
                                .repeatForever(autoreverses: true)
                                .delay(Double(i) * 0.2),
                                value: animate
                            )
                    }

                    Circle()
                        .fill(Color.furgMint.opacity(0.1))
                        .frame(width: 100, height: 100)

                    Image(systemName: "doc.text.viewfinder")
                        .font(.system(size: 44))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.furgMint, .furgSeafoam],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                }

                VStack(spacing: 8) {
                    Text("Scan Your Receipt")
                        .font(.system(size: 26, weight: .bold))
                        .foregroundColor(.white)

                    Text("Extract items and prices automatically for better expense tracking")
                        .font(.system(size: 15))
                        .foregroundColor(.white.opacity(0.6))
                        .multilineTextAlignment(.center)
                        .lineSpacing(4)
                }
            }
            .padding(.top, 40)
            .offset(y: animate ? 0 : -20)
            .opacity(animate ? 1 : 0)

            // Scan options
            VStack(spacing: 16) {
                // Camera button
                Button {
                    showCamera = true
                } label: {
                    HStack(spacing: 14) {
                        ZStack {
                            Circle()
                                .fill(Color.furgMint.opacity(0.15))
                                .frame(width: 48, height: 48)

                            Image(systemName: "camera.fill")
                                .font(.system(size: 20))
                                .foregroundColor(.furgMint)
                        }

                        VStack(alignment: .leading, spacing: 4) {
                            Text("Take Photo")
                                .font(.system(size: 17, weight: .semibold))
                                .foregroundColor(.white)

                            Text("Use camera to capture receipt")
                                .font(.system(size: 13))
                                .foregroundColor(.white.opacity(0.5))
                        }

                        Spacer()

                        Image(systemName: "chevron.right")
                            .foregroundColor(.white.opacity(0.3))
                    }
                    .padding(20)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color.white.opacity(0.05))
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(Color.furgMint.opacity(0.3), lineWidth: 1)
                            )
                    )
                }
                .buttonStyle(.plain)

                // Photo library button
                Button {
                    showImagePicker = true
                } label: {
                    HStack(spacing: 14) {
                        ZStack {
                            Circle()
                                .fill(Color.white.opacity(0.1))
                                .frame(width: 48, height: 48)

                            Image(systemName: "photo.on.rectangle")
                                .font(.system(size: 20))
                                .foregroundColor(.white)
                        }

                        VStack(alignment: .leading, spacing: 4) {
                            Text("Choose from Photos")
                                .font(.system(size: 17, weight: .semibold))
                                .foregroundColor(.white)

                            Text("Select receipt image from library")
                                .font(.system(size: 13))
                                .foregroundColor(.white.opacity(0.5))
                        }

                        Spacer()

                        Image(systemName: "chevron.right")
                            .foregroundColor(.white.opacity(0.3))
                    }
                    .padding(20)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color.white.opacity(0.05))
                    )
                }
                .buttonStyle(.plain)
            }
            .offset(y: animate ? 0 : 20)
            .opacity(animate ? 1 : 0)

            // Tips
            VStack(alignment: .leading, spacing: 16) {
                Text("Tips for best results")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.white.opacity(0.7))

                VStack(alignment: .leading, spacing: 12) {
                    TipRow(icon: "light.max", text: "Good lighting helps accuracy")
                    TipRow(icon: "arrow.up.left.and.arrow.down.right", text: "Capture the full receipt")
                    TipRow(icon: "hand.raised.slash", text: "Keep steady, avoid blur")
                    TipRow(icon: "rectangle.portrait", text: "Flat surface works best")
                }
            }
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.white.opacity(0.03))
            )
            .offset(y: animate ? 0 : 20)
            .opacity(animate ? 1 : 0)
        }
    }

    // MARK: - Results Section

    private var resultsSection: some View {
        VStack(spacing: 24) {
            if let receipt = scanner.lastReceipt {
                // Header
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(receipt.merchantName ?? "Receipt")
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(.white)

                        if let date = receipt.date {
                            Text(date.formatted(date: .abbreviated, time: .omitted))
                                .font(.system(size: 14))
                                .foregroundColor(.white.opacity(0.5))
                        }
                    }

                    Spacer()

                    Button {
                        withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                            showResults = false
                            selectedImage = nil
                            scanner.lastReceipt = nil
                        }
                    } label: {
                        Image(systemName: "arrow.counterclockwise")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.furgMint)
                            .padding(12)
                            .background(Circle().fill(Color.furgMint.opacity(0.15)))
                    }
                }

                // Total card
                if let total = receipt.total {
                    VStack(spacing: 16) {
                        Text("Total")
                            .font(.system(size: 14))
                            .foregroundColor(.white.opacity(0.5))

                        Text(String(format: "$%.2f", total))
                            .font(.system(size: 48, weight: .bold, design: .rounded))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [.furgMint, .furgSeafoam],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )

                        HStack(spacing: 24) {
                            if let subtotal = receipt.subtotal {
                                VStack(spacing: 4) {
                                    Text("Subtotal")
                                        .font(.system(size: 12))
                                        .foregroundColor(.white.opacity(0.5))
                                    Text(String(format: "$%.2f", subtotal))
                                        .font(.system(size: 16, weight: .semibold))
                                        .foregroundColor(.white)
                                }
                            }

                            if let tax = receipt.tax {
                                VStack(spacing: 4) {
                                    Text("Tax")
                                        .font(.system(size: 12))
                                        .foregroundColor(.white.opacity(0.5))
                                    Text(String(format: "$%.2f", tax))
                                        .font(.system(size: 16, weight: .semibold))
                                        .foregroundColor(.white)
                                }
                            }
                        }
                    }
                    .padding(24)
                    .frame(maxWidth: .infinity)
                    .background(
                        RoundedRectangle(cornerRadius: 20)
                            .fill(Color.white.opacity(0.05))
                            .overlay(
                                RoundedRectangle(cornerRadius: 20)
                                    .stroke(Color.furgMint.opacity(0.2), lineWidth: 1)
                            )
                    )
                }

                // Items list
                if !receipt.items.isEmpty {
                    VStack(alignment: .leading, spacing: 16) {
                        HStack {
                            Text("Items (\(receipt.items.count))")
                                .font(.system(size: 18, weight: .bold))
                                .foregroundColor(.white)

                            Spacer()

                            Text("Tap to categorize")
                                .font(.system(size: 12))
                                .foregroundColor(.furgMint)
                        }

                        ForEach(receipt.items) { item in
                            ItemRow(item: item, scanner: scanner)
                        }
                    }
                    .padding(20)
                    .background(
                        RoundedRectangle(cornerRadius: 20)
                            .fill(Color.white.opacity(0.05))
                    )
                }

                // Actions
                VStack(spacing: 12) {
                    Button {
                        // Save receipt to transaction
                    } label: {
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                            Text("Save to Transactions")
                        }
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(.black)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 18)
                        .background(Color.furgMint)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                    }

                    Button {
                        // Link to existing transaction
                    } label: {
                        HStack {
                            Image(systemName: "link")
                            Text("Link to Existing Transaction")
                        }
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(.furgMint)
                    }
                }
            }
        }
    }

    // MARK: - Scanning Overlay

    private var scanningOverlay: some View {
        ZStack {
            Color.black.opacity(0.7)
                .ignoresSafeArea()

            VStack(spacing: 24) {
                ZStack {
                    Circle()
                        .stroke(Color.furgMint.opacity(0.3), lineWidth: 4)
                        .frame(width: 80, height: 80)

                    Circle()
                        .trim(from: 0, to: 0.3)
                        .stroke(Color.furgMint, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                        .frame(width: 80, height: 80)
                        .rotationEffect(.degrees(animate ? 360 : 0))
                        .animation(.linear(duration: 1).repeatForever(autoreverses: false), value: animate)
                }

                VStack(spacing: 8) {
                    Text("Scanning Receipt...")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.white)

                    Text("Extracting items and prices")
                        .font(.system(size: 14))
                        .foregroundColor(.white.opacity(0.6))
                }
            }
        }
    }
}

// MARK: - Supporting Views

private struct TipRow: View {
    let icon: String
    let text: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundColor(.furgMint)
                .frame(width: 20)

            Text(text)
                .font(.system(size: 14))
                .foregroundColor(.white.opacity(0.7))
        }
    }
}

private struct ItemRow: View {
    let item: ReceiptScanner.ReceiptItem
    let scanner: ReceiptScanner
    @State private var showCategoryPicker = false

    var body: some View {
        HStack(spacing: 14) {
            // Category indicator
            ZStack {
                Circle()
                    .fill(categoryColor.opacity(0.15))
                    .frame(width: 40, height: 40)

                Image(systemName: categoryIcon)
                    .font(.system(size: 16))
                    .foregroundColor(categoryColor)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(item.name)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(.white)
                    .lineLimit(1)

                HStack(spacing: 8) {
                    if item.quantity > 1 {
                        Text("Qty: \(item.quantity)")
                            .font(.system(size: 12))
                            .foregroundColor(.white.opacity(0.5))
                    }

                    Text(category)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(categoryColor)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(categoryColor.opacity(0.15))
                        .clipShape(Capsule())
                }
            }

            Spacer()

            Text(item.formattedPrice)
                .font(.system(size: 15, weight: .semibold, design: .rounded))
                .foregroundColor(.white)
        }
        .padding(.vertical, 8)
    }

    private var category: String {
        item.category ?? scanner.categorizeItem(item)
    }

    private var categoryColor: Color {
        switch category {
        case "Groceries": return .furgMint
        case "Beverages": return .blue
        case "Snacks": return .orange
        case "Household": return .purple
        case "Personal Care": return .pink
        default: return .gray
        }
    }

    private var categoryIcon: String {
        switch category {
        case "Groceries": return "cart.fill"
        case "Beverages": return "cup.and.saucer.fill"
        case "Snacks": return "leaf.fill"
        case "Household": return "house.fill"
        case "Personal Care": return "heart.fill"
        default: return "tag.fill"
        }
    }
}

// MARK: - Photo Picker

struct PhotoPicker: UIViewControllerRepresentable {
    @Binding var image: UIImage?

    func makeUIViewController(context: Context) -> PHPickerViewController {
        var config = PHPickerConfiguration()
        config.selectionLimit = 1
        config.filter = .images

        let picker = PHPickerViewController(configuration: config)
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: PHPickerViewController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, PHPickerViewControllerDelegate {
        let parent: PhotoPicker

        init(_ parent: PhotoPicker) {
            self.parent = parent
        }

        func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
            picker.dismiss(animated: true)

            guard let provider = results.first?.itemProvider,
                  provider.canLoadObject(ofClass: UIImage.self) else { return }

            provider.loadObject(ofClass: UIImage.self) { image, _ in
                DispatchQueue.main.async {
                    self.parent.image = image as? UIImage
                }
            }
        }
    }
}

// MARK: - Camera Picker

struct CameraPicker: UIViewControllerRepresentable {
    @Binding var image: UIImage?
    @Environment(\.dismiss) var dismiss

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = .camera
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: CameraPicker

        init(_ parent: CameraPicker) {
            self.parent = parent
        }

        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
            if let image = info[.originalImage] as? UIImage {
                parent.image = image
            }
            parent.dismiss()
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.dismiss()
        }
    }
}

#Preview {
    ReceiptScanView()
}
