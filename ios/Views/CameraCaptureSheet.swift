import SwiftUI
import PhotosUI
import COREEngine

struct CameraCaptureSheet: View {
    let viewModel: WardrobeViewModel
    let onUpload: (UUID, Data) async -> Void
    @Environment(\.theme) private var theme
    @Environment(\.dismiss) private var dismiss

    @State private var selectedPhoto: PhotosPickerItem?
    @State private var capturedImage: UIImage?
    @State private var showCamera = false
    @State private var isUploading = false
    @State private var statusMessage: String?

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Spacer()

                if let image = capturedImage {
                    // Preview
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .frame(maxHeight: 300)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .shadow(radius: 10)

                    if isUploading {
                        HStack(spacing: 8) {
                            ProgressView()
                            Text(statusMessage ?? "Behandler...")
                                .font(.dmSans(13))
                                .foregroundStyle(theme.text2)
                        }
                    } else {
                        Button {
                            Task { await upload() }
                        } label: {
                            Text("Last opp og analyser")
                                .font(.dmSans(14, weight: .medium))
                                .foregroundStyle(theme.bg)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                                .background(RoundedRectangle(cornerRadius: 10).fill(theme.gold))
                        }
                        .padding(.horizontal, 40)

                        Button("Ta nytt bilde") {
                            capturedImage = nil
                        }
                        .font(.dmSans(13))
                        .foregroundStyle(theme.text3)
                    }
                } else {
                    // Capture options
                    Image(systemName: "camera.circle")
                        .font(.system(size: 64))
                        .foregroundStyle(theme.text4)

                    Text("Ta bilde av plagget")
                        .font(.instrumentSerif(22))
                        .foregroundStyle(theme.text)

                    Text("Vi fjerner bakgrunn og analyserer farger automatisk")
                        .font(.dmSans(13))
                        .foregroundStyle(theme.text3)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)

                    HStack(spacing: 16) {
                        // Camera button
                        Button { showCamera = true } label: {
                            VStack(spacing: 6) {
                                Image(systemName: "camera.fill")
                                    .font(.system(size: 24))
                                Text("Kamera")
                                    .font(.dmSans(12, weight: .medium))
                            }
                            .foregroundStyle(theme.bg)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 20)
                            .background(RoundedRectangle(cornerRadius: 12).fill(theme.gold))
                        }

                        // Photo picker
                        PhotosPicker(selection: $selectedPhoto, matching: .images) {
                            VStack(spacing: 6) {
                                Image(systemName: "photo.on.rectangle")
                                    .font(.system(size: 24))
                                Text("Bibliotek")
                                    .font(.dmSans(12, weight: .medium))
                            }
                            .foregroundStyle(theme.text)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 20)
                            .background(RoundedRectangle(cornerRadius: 12).fill(theme.surface))
                        }
                    }
                    .padding(.horizontal, 40)
                }

                Spacer()
            }
            .background(theme.bg)
            .navigationTitle("Ta bilde")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Avbryt") { dismiss() }
                }
            }
            .fullScreenCover(isPresented: $showCamera) {
                CameraView { image in
                    capturedImage = image
                }
            }
            .onChange(of: selectedPhoto) { _, item in
                guard let item else { return }
                Task {
                    if let data = try? await item.loadTransferable(type: Data.self),
                       let image = UIImage(data: data) {
                        capturedImage = image
                    }
                }
            }
        }
    }

    private func upload() async {
        guard let image = capturedImage,
              let data = image.jpegData(compressionQuality: 0.85) else { return }
        isUploading = true
        statusMessage = "Fjerner bakgrunn..."
        let garmentId = UUID()
        await onUpload(garmentId, data)
        statusMessage = "Ferdig!"
        isUploading = false
        dismiss()
    }
}

// MARK: - UIImagePickerController Camera

struct CameraView: UIViewControllerRepresentable {
    let onCapture: (UIImage) -> Void
    @Environment(\.dismiss) private var dismiss

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = .camera
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    func makeCoordinator() -> Coordinator { Coordinator(onCapture: onCapture, dismiss: dismiss) }

    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let onCapture: (UIImage) -> Void
        let dismiss: DismissAction

        init(onCapture: @escaping (UIImage) -> Void, dismiss: DismissAction) {
            self.onCapture = onCapture
            self.dismiss = dismiss
        }

        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
            if let image = info[.originalImage] as? UIImage {
                onCapture(image)
            }
            dismiss()
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            dismiss()
        }
    }
}
