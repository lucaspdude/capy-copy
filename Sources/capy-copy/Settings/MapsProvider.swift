import Foundation

enum MapsProvider: String, CaseIterable, Identifiable, Codable {
    case appleMaps = "Apple Maps"
    case googleMaps = "Google Maps"

    var id: String { rawValue }

    func mapsURL(for address: String) -> URL? {
        switch self {
        case .appleMaps:
            var components = URLComponents()
            components.scheme = "https"
            components.host = "maps.apple.com"
            components.path = "/"
            components.queryItems = [URLQueryItem(name: "q", value: address)]
            return components.url
        case .googleMaps:
            var components = URLComponents()
            components.scheme = "https"
            components.host = "www.google.com"
            components.path = "/maps/search/"
            components.queryItems = [
                URLQueryItem(name: "api", value: "1"),
                URLQueryItem(name: "query", value: address)
            ]
            return components.url
        }
    }
}
