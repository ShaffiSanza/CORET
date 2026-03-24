import Foundation
import COREEngine

/// Central HTTP client for CORET backend API.
/// All garment input methods route through here.
actor APIClient {
    static let shared = APIClient()

    // DEBUG: localhost for dev, RELEASE: Railway production
    #if DEBUG
    var baseURL: URL = URL(string: "http://localhost:8000")!
    #else
    var baseURL: URL = URL(string: "https://coret-production.up.railway.app")!
    #endif

    private let session: URLSession
    private let decoder: JSONDecoder
    private let encoder: JSONEncoder

    private init() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 30
        session = URLSession(configuration: config)
        decoder = JSONDecoder()
        encoder = JSONEncoder()
    }

    func setBaseURL(_ url: URL) {
        baseURL = url
    }

    // MARK: - Product Search

    struct ProductSearchResponse: Codable {
        let imageUrl: String?
        let productTitle: String?
        let brand: String?
        let sourceUrl: String?
        let success: Bool

        enum CodingKeys: String, CodingKey {
            case imageUrl = "image_url"
            case productTitle = "product_title"
            case brand
            case sourceUrl = "source_url"
            case success
        }
    }

    func productSearch(query: String) async throws -> ProductSearchResponse {
        let url = baseURL.appendingPathComponent("api/product-search")
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try encoder.encode(["query": query])
        let (data, _) = try await session.data(for: request)
        return try decoder.decode(ProductSearchResponse.self, from: data)
    }

    // MARK: - Barcode Lookup

    struct BarcodeLookupResponse: Codable {
        let imageUrl: String?
        let productTitle: String?
        let brand: String?
        let category: String?
        let description: String?
        let success: Bool

        enum CodingKeys: String, CodingKey {
            case imageUrl = "image_url"
            case productTitle = "product_title"
            case brand, category, description, success
        }
    }

    func barcodeLookup(barcode: String) async throws -> BarcodeLookupResponse {
        let url = baseURL.appendingPathComponent("api/barcode-lookup")
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try encoder.encode(["barcode": barcode])
        let (data, _) = try await session.data(for: request)
        return try decoder.decode(BarcodeLookupResponse.self, from: data)
    }

    // MARK: - Image Upload

    struct ImageUploadResponse: Codable {
        let garmentId: String
        let colors: ColorResult?
        let images: ImageResult?

        enum CodingKeys: String, CodingKey {
            case garmentId = "garment_id"
            case colors, images
        }

        struct ColorResult: Codable {
            let dominantColor: String?
            let colorTemperature: String?
            let palette: [String]?

            enum CodingKeys: String, CodingKey {
                case dominantColor = "dominant_color"
                case colorTemperature = "color_temperature"
                case palette
            }
        }

        struct ImageResult: Codable {
            let full: String?
            let display: String?
            let preview: String?
        }
    }

    func uploadImage(garmentId: UUID, imageData: Data) async throws -> ImageUploadResponse {
        let url = baseURL.appendingPathComponent("api/garments/\(garmentId.uuidString)/image")
        var request = URLRequest(url: url)
        request.httpMethod = "POST"

        let boundary = UUID().uuidString
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")

        var body = Data()
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"image\"; filename=\"garment.jpg\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: image/jpeg\r\n\r\n".data(using: .utf8)!)
        body.append(imageData)
        body.append("\r\n--\(boundary)--\r\n".data(using: .utf8)!)
        request.httpBody = body

        let (data, _) = try await session.data(for: request)
        return try decoder.decode(ImageUploadResponse.self, from: data)
    }

    // MARK: - Wardrobe Import

    struct ImportRequest: Codable {
        let garments: [ImportGarment]

        struct ImportGarment: Codable {
            let name: String?
            let category: String
            let baseGroup: String
            let colorTemperature: String?
            let dominantColor: String?
            let silhouette: String?
        }
    }

    struct ImportResponse: Codable {
        let imported: Int
        let garmentIds: [String]
        let warnings: [String]

        enum CodingKeys: String, CodingKey {
            case imported
            case garmentIds = "garment_ids"
            case warnings
        }
    }

    func importWardrobe(garments: [ImportRequest.ImportGarment]) async throws -> ImportResponse {
        let url = baseURL.appendingPathComponent("api/wardrobe/import")
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try encoder.encode(ImportRequest(garments: garments))
        let (data, _) = try await session.data(for: request)
        return try decoder.decode(ImportResponse.self, from: data)
    }

    // MARK: - Extract Metadata (for barcode/search enrichment)

    struct MetadataResponse: Codable {
        let category: String?
        let baseGroup: String?
        let silhouette: String?
        let colorTemperature: String?
        let season: String?

        enum CodingKeys: String, CodingKey {
            case category
            case baseGroup = "base_group"
            case silhouette
            case colorTemperature = "color_temperature"
            case season
        }
    }

    func extractMetadata(productTitle: String, brand: String?) async throws -> MetadataResponse {
        let url = baseURL.appendingPathComponent("api/product-metadata")
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        var body: [String: String] = ["product_title": productTitle]
        if let brand { body["brand"] = brand }
        request.httpBody = try encoder.encode(body)
        let (data, _) = try await session.data(for: request)
        return try decoder.decode(MetadataResponse.self, from: data)
    }
}
