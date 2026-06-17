import Foundation

struct ClipItem: Identifiable, Codable, Equatable {
    let id: UUID
    let rawText: String
    let contentType: DetectedContent
    let timestamp: Date
    let contentHash: String
    var sourceDevices: Set<DeviceSource>
    var result: String
    var errorMessage: String?
    var isLoading: Bool
    var imageData: Data?
    var imageFilename: String?
    var isFavorite: Bool

    init(
        id: UUID = UUID(),
        rawText: String,
        contentType: DetectedContent,
        timestamp: Date = Date(),
        contentHash: String? = nil,
        sourceDevices: Set<DeviceSource>? = nil,
        result: String = "",
        errorMessage: String? = nil,
        isLoading: Bool = false,
        imageData: Data? = nil,
        imageFilename: String? = nil,
        isFavorite: Bool = false
    ) {
        self.id = id
        self.rawText = rawText
        self.contentType = contentType
        self.timestamp = timestamp
        self.contentHash = contentHash ?? ClipContentHash.hash(for: rawText, data: imageData)
        self.sourceDevices = sourceDevices ?? [DeviceIdentity.current.asSource()]
        self.result = result
        self.errorMessage = errorMessage
        self.isLoading = isLoading
        self.imageData = imageData
        self.imageFilename = imageFilename
        self.isFavorite = isFavorite
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decode(UUID.self, forKey: .id)
        self.rawText = try container.decode(String.self, forKey: .rawText)
        self.contentType = try container.decode(DetectedContent.self, forKey: .contentType)
        self.timestamp = try container.decode(Date.self, forKey: .timestamp)
        self.contentHash = try container.decodeIfPresent(String.self, forKey: .contentHash)
            ?? ClipContentHash.hash(for: rawText, data: nil)
        self.sourceDevices = try container.decodeIfPresent(Set<DeviceSource>.self, forKey: .sourceDevices)
            ?? [DeviceIdentity.current.asSource()]
        self.result = try container.decode(String.self, forKey: .result)
        self.errorMessage = try container.decodeIfPresent(String.self, forKey: .errorMessage)
        self.isLoading = try container.decode(Bool.self, forKey: .isLoading)
        self.imageData = nil
        self.imageFilename = try container.decodeIfPresent(String.self, forKey: .imageFilename)
        self.isFavorite = try container.decodeIfPresent(Bool.self, forKey: .isFavorite) ?? false
    }

    private enum CodingKeys: String, CodingKey {
        case id
        case rawText
        case contentType
        case timestamp
        case contentHash
        case sourceDevices
        case result
        case errorMessage
        case isLoading
        case imageFilename
        case isFavorite
    }
}
