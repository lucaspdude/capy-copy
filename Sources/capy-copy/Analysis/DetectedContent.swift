import Foundation

enum DetectedContent: Codable, Equatable {
    case url
    case code
    case date(Date)
    case address(String)
    case text
    case image
    case video(URL?)
    case media

    var isMedia: Bool {
        switch self {
        case .image, .video, .media:
            return true
        case .url, .code, .date, .address, .text:
            return false
        }
    }

    var iconName: String {
        switch self {
        case .url: return "link"
        case .code: return "curlybraces"
        case .date: return "calendar"
        case .address: return "mappin.and.ellipse"
        case .text: return "text.alignleft"
        case .image: return "photo"
        case .video: return "film"
        case .media: return "photo.stack"
        }
    }

    var localizedName: String {
        switch self {
        case .url:
            return NSLocalizedString("content.url", tableName: nil, bundle: .module, comment: "URL content type")
        case .code:
            return NSLocalizedString("content.code", tableName: nil, bundle: .module, comment: "Code content type")
        case .date:
            return NSLocalizedString("content.date", tableName: nil, bundle: .module, comment: "Date content type")
        case .address:
            return NSLocalizedString("content.address", tableName: nil, bundle: .module, comment: "Address content type")
        case .text:
            return NSLocalizedString("content.text", tableName: nil, bundle: .module, comment: "Plain text content type")
        case .image:
            return NSLocalizedString("content.image", tableName: nil, bundle: .module, comment: "Image content type")
        case .video:
            return NSLocalizedString("content.video", tableName: nil, bundle: .module, comment: "Video content type")
        case .media:
            return NSLocalizedString("content.media", tableName: nil, bundle: .module, comment: "Media content type")
        }
    }

    private enum CodingKeys: String, CodingKey {
        case kind
        case value
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let kind = try container.decode(String.self, forKey: .kind)

        switch kind {
        case "url":
            self = .url
        case "code":
            self = .code
        case "date":
            let date = try container.decode(Date.self, forKey: .value)
            self = .date(date)
        case "address":
            let address = try container.decode(String.self, forKey: .value)
            self = .address(address)
        case "text":
            self = .text
        case "image":
            self = .image
        case "video":
            let urlString = try container.decodeIfPresent(String.self, forKey: .value)
            self = .video(urlString.flatMap { URL(string: $0) })
        case "media":
            self = .media
        default:
            throw DecodingError.dataCorruptedError(forKey: .kind, in: container, debugDescription: "Unknown kind: \(kind)")
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        switch self {
        case .url:
            try container.encode("url", forKey: .kind)
        case .code:
            try container.encode("code", forKey: .kind)
        case .date(let date):
            try container.encode("date", forKey: .kind)
            try container.encode(date, forKey: .value)
        case .address(let address):
            try container.encode("address", forKey: .kind)
            try container.encode(address, forKey: .value)
        case .text:
            try container.encode("text", forKey: .kind)
        case .image:
            try container.encode("image", forKey: .kind)
        case .video(let url):
            try container.encode("video", forKey: .kind)
            try container.encode(url?.absoluteString, forKey: .value)
        case .media:
            try container.encode("media", forKey: .kind)
        }
    }
}
