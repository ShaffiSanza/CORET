import CoreImage
import CoreImage.CIFilterBuiltins
import UIKit
import Vision

enum ImageProcessor: Sendable {

    /// Remove background from image data using Apple Vision (iOS 17+).
    /// Returns PNG data with transparent background, or nil on failure.
    static func removeBackground(from data: Data) async -> Data? {
        await Task.detached(priority: .userInitiated) {
            guard let ciImage = CIImage(data: data) else { return nil }

            let request = VNGenerateForegroundInstanceMaskRequest()
            let handler = VNImageRequestHandler(ciImage: ciImage, options: [:])

            do {
                try handler.perform([request])
            } catch {
                return nil
            }

            guard let result = request.results?.first else { return nil }

            let maskPixelBuffer: CVPixelBuffer
            do {
                maskPixelBuffer = try result.generateScaledMaskForImage(
                    forInstances: result.allInstances,
                    from: handler
                )
            } catch {
                return nil
            }

            let maskCIImage = CIImage(cvPixelBuffer: maskPixelBuffer)
            let context = CIContext()

            let blendFilter = CIFilter.blendWithMask()
            blendFilter.inputImage = ciImage
            blendFilter.backgroundImage = CIImage.empty()
            blendFilter.maskImage = maskCIImage

            guard let outputImage = blendFilter.outputImage,
                  let cgImage = context.createCGImage(outputImage, from: ciImage.extent) else {
                return nil
            }

            return UIImage(cgImage: cgImage).pngData()
        }.value
    }

    /// Download image from URL and remove background.
    static func processSearchImage(from url: URL) async -> Data? {
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            return await removeBackground(from: data)
        } catch {
            return nil
        }
    }
}
