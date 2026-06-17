import Foundation

enum MapsProvider: String, CaseIterable, Identifiable, Codable {
    case appleMaps = "Apple Maps"
    case googleMaps = "Google Maps"

    var id: String { rawValue }

    func mapsURL(for address: String) -> URL? {
        var components = URLComponents()
        switch self {
        case .appleMaps:
            components.scheme = "https"
            components.host = "maps.apple.com"
            components.path = "/"
            components.queryItems = [URLQueryItem(name: "q", value: address)]
        case .googleMaps:
            components.scheme = "https"
            components.host = "www.google.com"
            components.path = "/maps/search/"
            components.queryItems = [
                URLQueryItem(name: "api", value: "1"),
                URLQueryItem(name: "query", value: address)
            ]
        }
        return components.url
    }
}
