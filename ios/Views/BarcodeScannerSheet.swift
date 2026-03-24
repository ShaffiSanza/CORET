import SwiftUI
import AVFoundation

struct BarcodeScannerSheet: View {
    let onResult: (APIClient.BarcodeLookupResponse) -> Void
    @Environment(\.theme) private var theme
    @Environment(\.dismiss) private var dismiss

    @State private var scannedCode: String?
    @State private var isLooking = false
    @State private var errorMessage: String?
    @State private var manualCode = ""
    @State private var showManualEntry = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                if showManualEntry {
                    manualEntryView
                } else {
                    scannerView
                }
            }
            .background(theme.bg)
            .navigationTitle("Skann strekkode")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Avbryt") { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button(showManualEntry ? "Kamera" : "Manuelt") {
                        showManualEntry.toggle()
                    }
                    .font(.dmSans(13, weight: .medium))
                }
            }
        }
    }

    @ViewBuilder
    private var scannerView: some View {
        ZStack {
            BarcodeCameraView { code in
                guard scannedCode == nil else { return }
                scannedCode = code
                Task { await lookup(barcode: code) }
            }

            // Overlay frame
            RoundedRectangle(cornerRadius: 12)
                .strokeBorder(theme.gold, lineWidth: 2)
                .frame(width: 260, height: 100)

            VStack {
                Spacer()
                if isLooking {
                    HStack(spacing: 8) {
                        ProgressView().tint(.white)
                        Text("S\u{00F8}ker opp \(scannedCode ?? "")...")
                            .font(.dmSans(13))
                            .foregroundStyle(.white)
                    }
                    .padding(12)
                    .background(Capsule().fill(.black.opacity(0.7)))
                } else if let error = errorMessage {
                    Text(error)
                        .font(.dmSans(13))
                        .foregroundStyle(.white)
                        .padding(12)
                        .background(Capsule().fill(Color.coretRed.opacity(0.8)))
                        .onTapGesture { scannedCode = nil; errorMessage = nil }
                }
                Spacer().frame(height: 80)
            }
        }
    }

    @ViewBuilder
    private var manualEntryView: some View {
        VStack(spacing: 20) {
            Spacer()
            Image(systemName: "barcode")
                .font(.system(size: 48))
                .foregroundStyle(theme.text4)

            TextField("Skriv inn strekkode (8-14 siffer)", text: $manualCode)
                .keyboardType(.numberPad)
                .font(.dmSans(16))
                .multilineTextAlignment(.center)
                .padding(14)
                .background {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(theme.surface)
                }
                .padding(.horizontal, 40)

            Button {
                Task { await lookup(barcode: manualCode) }
            } label: {
                Text("Sl\u{00E5} opp")
                    .font(.dmSans(14, weight: .medium))
                    .foregroundStyle(theme.bg)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(RoundedRectangle(cornerRadius: 10).fill(theme.gold))
            }
            .disabled(manualCode.count < 8 || isLooking)
            .opacity(manualCode.count < 8 ? 0.5 : 1)
            .padding(.horizontal, 40)

            if isLooking {
                ProgressView()
            }
            if let error = errorMessage {
                Text(error)
                    .font(.dmSans(13))
                    .foregroundStyle(Color.coretRed)
            }
            Spacer()
        }
    }

    @MainActor
    private func lookup(barcode: String) async {
        isLooking = true
        errorMessage = nil
        do {
            let result = try await APIClient.shared.barcodeLookup(barcode: barcode)
            if result.success {
                onResult(result)
                dismiss()
            } else {
                errorMessage = "Ingen treff p\u{00E5} denne koden"
                scannedCode = nil
            }
        } catch {
            errorMessage = "Feil ved oppslag"
            scannedCode = nil
        }
        isLooking = false
    }
}

// MARK: - AVFoundation Barcode Camera

struct BarcodeCameraView: UIViewRepresentable {
    let onCode: (String) -> Void

    func makeUIView(context: Context) -> UIView {
        let view = UIView(frame: .zero)
        let session = AVCaptureSession()

        guard let device = AVCaptureDevice.default(for: .video),
              let input = try? AVCaptureDeviceInput(device: device) else { return view }

        session.addInput(input)

        let output = AVCaptureMetadataOutput()
        session.addOutput(output)
        output.setMetadataObjectsDelegate(context.coordinator, queue: .main)
        output.metadataObjectTypes = [.ean8, .ean13, .upce, .code128, .code39]

        let previewLayer = AVCaptureVideoPreviewLayer(session: session)
        previewLayer.videoGravity = .resizeAspectFill
        previewLayer.frame = UIScreen.main.bounds
        view.layer.addSublayer(previewLayer)

        Task { @MainActor in
            session.startRunning()
        }

        context.coordinator.session = session
        return view
    }

    func updateUIView(_ uiView: UIView, context: Context) {}

    func makeCoordinator() -> Coordinator { Coordinator(onCode: onCode) }

    class Coordinator: NSObject, AVCaptureMetadataOutputObjectsDelegate {
        let onCode: (String) -> Void
        var session: AVCaptureSession?
        private var hasReported = false

        init(onCode: @escaping (String) -> Void) { self.onCode = onCode }

        func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {
            guard !hasReported,
                  let obj = metadataObjects.first as? AVMetadataMachineReadableCodeObject,
                  let code = obj.stringValue else { return }
            hasReported = true
            session?.stopRunning()
            onCode(code)
        }
    }
}
