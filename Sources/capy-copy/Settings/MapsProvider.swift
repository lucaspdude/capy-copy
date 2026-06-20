import Foundation

enum MapsProvider: String, CaseIterable, Identifiable, Codable {
    case appleMaps = "Apple Maps"

    var id: String { rawValue }

    func mapsURL(for address: String) -> URL? {
        var components = URLComponents()
        components.scheme = "https"
        components.host = "maps.apple.com"
        components.path = "/"
        components.queryItems = [URLQueryItem(name: "q", value: address)]
        return components.url
    }
}
