//
//  ReceiptScannerV2.swift
//  Furg
//
//  Camera-based receipt scanning with OCR
//

import SwiftUI

struct ReceiptScannerV2: View {
    @Environment(\.dismiss) var dismiss
    @State private var scanState: ScanState = .ready
    @State private var scannedReceipt: ScannedReceiptV2?
    @State private var showManualEntry = false

    enum ScanState {
        case ready
        case scanning
        case processing
        case complete
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.v2Background.ignoresSafeArea()

                switch scanState {
                case .ready, .scanning:
                    scannerView
                case .processing:
                    processingView
                case .complete:
                    if let receipt = scannedReceipt {
                        resultView(receipt: receipt)
                    }
                }
            }
            .navigationTitle("Scan Receipt")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button { dismiss() } label: {
                        Image(systemName: "xmark")
                            .foregroundColor(.v2TextSecondary)
                    }
                }
            }
            .sheet(isPresented: $showManualEntry) {
                ManualEntrySheetV2()
                    .presentationBackground(Color.v2Background)
            }
        }
    }

    // MARK: - Scanner View

    var scannerView: some View {
        VStack(spacing: 24) {
            Spacer()

            // Camera preview placeholder
            ZStack {
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color.v2CardBackground)
                    .frame(height: 400)

                // Scan frame
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.v2Primary, lineWidth: 3)
                    .frame(width: 280, height: 360)

                // Corner markers
                VStack {
                    HStack {
                        CornerMarker(rotation: 0)
                        Spacer()
                        CornerMarker(rotation: 90)
                    }
                    Spacer()
                    HStack {
                        CornerMarker(rotation: 270)
                        Spacer()
                        CornerMarker(rotation: 180)
                    }
                }
                .frame(width: 280, height: 360)

                // Instructions
                VStack {
                    Spacer()
                    Text("Position receipt within frame")
                        .font(.v2Caption)
                        .foregroundColor(.v2TextSecondary)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(Color.v2Background.opacity(0.8))
                        .cornerRadius(8)
                        .padding(.bottom, 20)
                }
            }
            .padding(.horizontal, 20)

            Spacer()

            // Controls
            VStack(spacing: 16) {
                // Capture button
                Button {
                    simulateScan()
                } label: {
                    ZStack {
                        Circle()
                            .stroke(Color.v2Primary, lineWidth: 4)
                            .frame(width: 72, height: 72)

                        Circle()
                            .fill(Color.v2Primary)
                            .frame(width: 58, height: 58)

                        Image(systemName: "camera.fill")
                            .font(.system(size: 24))
                            .foregroundColor(.v2TextInverse)
                    }
                }

                // Options
                HStack(spacing: 40) {
                    Button {
                        // Photo library
                    } label: {
                        VStack(spacing: 6) {
                            Image(systemName: "photo.on.rectangle")
                                .font(.system(size: 24))
                            Text("Gallery")
                                .font(.v2CaptionSmall)
                        }
                        .foregroundColor(.v2TextSecondary)
                    }

                    Button {
                        showManualEntry = true
                    } label: {
                        VStack(spacing: 6) {
                            Image(systemName: "keyboard")
                                .font(.system(size: 24))
                            Text("Manual")
                                .font(.v2CaptionSmall)
                        }
                        .foregroundColor(.v2TextSecondary)
                    }
                }
            }
            .padding(.bottom, 40)
        }
    }

    // MARK: - Processing View

    var processingView: some View {
        VStack(spacing: 24) {
            Spacer()

            ZStack {
                Circle()
                    .stroke(Color.v2CardBackground, lineWidth: 4)
                    .frame(width: 100, height: 100)

                Circle()
                    .trim(from: 0, to: 0.7)
                    .stroke(Color.v2Primary, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                    .frame(width: 100, height: 100)
                    .rotationEffect(.degrees(-90))

                Image(systemName: "doc.text.viewfinder")
                    .font(.system(size: 36))
                    .foregroundColor(.v2Primary)
            }

            VStack(spacing: 8) {
                Text("Processing Receipt")
                    .font(.v2Title)
                    .foregroundColor(.v2TextPrimary)

                Text("Extracting merchant, items, and total...")
                    .font(.v2Body)
                    .foregroundColor(.v2TextSecondary)
            }

            Spacer()
        }
    }

    // MARK: - Result View

    func resultView(receipt: ScannedReceiptV2) -> some View {
        ScrollView {
            VStack(spacing: 24) {
                // Success header
                VStack(spacing: 12) {
                    ZStack {
                        Circle()
                            .fill(Color.v2Success.opacity(0.15))
                            .frame(width: 72, height: 72)

                        Image(systemName: "checkmark")
                            .font(.system(size: 32, weight: .bold))
                            .foregroundColor(.v2Success)
                    }

                    Text("Receipt Scanned!")
                        .font(.v2Title)
                        .foregroundColor(.v2TextPrimary)
                }
                .padding(.top, 20)

                // Receipt details
                V2Card {
                    VStack(spacing: 16) {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(receipt.merchant)
                                    .font(.v2Headline)
                                    .foregroundColor(.v2TextPrimary)

                                Text(receipt.date.formatted(date: .abbreviated, time: .shortened))
                                    .font(.v2Caption)
                                    .foregroundColor(.v2TextSecondary)
                            }

                            Spacer()

                            Text("-$\(String(format: "%.2f", receipt.total))")
                                .font(.v2DisplaySmall)
                                .foregroundColor(.v2TextPrimary)
                        }

                        Divider().background(Color.white.opacity(0.1))

                        // Items
                        ForEach(receipt.items, id: \.name) { item in
                            HStack {
                                Text(item.name)
                                    .font(.v2Body)
                                    .foregroundColor(.v2TextSecondary)
                                Spacer()
                                Text("$\(String(format: "%.2f", item.price))")
                                    .font(.v2Body)
                                    .foregroundColor(.v2TextSecondary)
                            }
                        }

                        Divider().background(Color.white.opacity(0.1))

                        // Category
                        HStack {
                            Text("Category")
                                .font(.v2Caption)
                                .foregroundColor(.v2TextSecondary)

                            Spacer()

                            Menu {
                                ForEach(["Food & Dining", "Shopping", "Transportation", "Entertainment"], id: \.self) { cat in
                                    Button(cat) { }
                                }
                            } label: {
                                HStack(spacing: 6) {
                                    Text(receipt.category)
                                        .font(.v2Body)
                                        .foregroundColor(.v2Primary)
                                    Image(systemName: "chevron.down")
                                        .font(.system(size: 10))
                                        .foregroundColor(.v2Primary)
                                }
                            }
                        }
                    }
                }

                // Actions
                VStack(spacing: 12) {
                    Button {
                        dismiss()
                    } label: {
                        Text("Save Transaction")
                            .font(.v2BodyBold)
                            .foregroundColor(.v2TextInverse)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(Color.v2Primary)
                            .cornerRadius(14)
                    }

                    Button {
                        scanState = .ready
                        scannedReceipt = nil
                    } label: {
                        Text("Scan Another")
                            .font(.v2Body)
                            .foregroundColor(.v2TextSecondary)
                    }
                }
            }
            .padding(20)
        }
    }

    // MARK: - Helpers

    func simulateScan() {
        scanState = .processing

        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            scannedReceipt = ScannedReceiptV2(
                merchant: "Whole Foods Market",
                date: Date(),
                items: [
                    (name: "Organic Bananas", price: 2.99),
                    (name: "Almond Milk", price: 4.49),
                    (name: "Avocados (3)", price: 5.99),
                    (name: "Sourdough Bread", price: 4.99),
                    (name: "Organic Eggs", price: 6.99)
                ],
                total: 25.45,
                category: "Food & Dining"
            )
            scanState = .complete
        }
    }
}

// MARK: - Corner Marker

struct CornerMarker: View {
    let rotation: Double

    var body: some View {
        Path { path in
            path.move(to: CGPoint(x: 0, y: 20))
            path.addLine(to: CGPoint(x: 0, y: 0))
            path.addLine(to: CGPoint(x: 20, y: 0))
        }
        .stroke(Color.v2Primary, style: StrokeStyle(lineWidth: 4, lineCap: .round, lineJoin: .round))
        .frame(width: 20, height: 20)
        .rotationEffect(.degrees(rotation))
    }
}

// MARK: - Scanned Receipt Model

struct ScannedReceiptV2 {
    let merchant: String
    let date: Date
    let items: [(name: String, price: Double)]
    let total: Double
    let category: String
}

// MARK: - Manual Entry Sheet

struct ManualEntrySheetV2: View {
    @Environment(\.dismiss) var dismiss
    @State private var merchant = ""
    @State private var amount = ""
    @State private var category = "Food & Dining"
    @State private var date = Date()

    let categories = ["Food & Dining", "Shopping", "Transportation", "Entertainment", "Bills", "Other"]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    FormFieldV2(label: "Merchant", placeholder: "Store name", text: $merchant)

                    FormFieldV2(label: "Amount", placeholder: "$0.00", text: $amount, keyboardType: .decimalPad)

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Category")
                            .font(.v2Caption)
                            .foregroundColor(.v2TextSecondary)

                        Menu {
                            ForEach(categories, id: \.self) { cat in
                                Button(cat) { category = cat }
                            }
                        } label: {
                            HStack {
                                Text(category)
                                    .foregroundColor(.v2TextPrimary)
                                Spacer()
                                Image(systemName: "chevron.down")
                                    .foregroundColor(.v2TextTertiary)
                            }
                            .font(.v2Body)
                            .padding(14)
                            .background(Color.v2CardBackground)
                            .cornerRadius(12)
                        }
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Date")
                            .font(.v2Caption)
                            .foregroundColor(.v2TextSecondary)

                        DatePicker("", selection: $date, displayedComponents: [.date])
                            .datePickerStyle(.compact)
                            .labelsHidden()
                            .tint(.v2Primary)
                    }

                    Spacer(minLength: 40)

                    Button {
                        dismiss()
                    } label: {
                        Text("Add Transaction")
                            .font(.v2BodyBold)
                            .foregroundColor(.v2TextInverse)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(merchant.isEmpty || amount.isEmpty ? Color.v2TextTertiary : Color.v2Primary)
                            .cornerRadius(14)
                    }
                    .disabled(merchant.isEmpty || amount.isEmpty)
                }
                .padding(20)
            }
            .background(Color.v2Background)
            .navigationTitle("Manual Entry")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                        .foregroundColor(.v2TextSecondary)
                }
            }
        }
    }
}

// MARK: - Preview

#Preview {
    ReceiptScannerV2()
}
