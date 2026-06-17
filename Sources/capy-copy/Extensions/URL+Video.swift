import Foundation
import UniformTypeIdentifiers

extension URL {
    var isVideo: Bool {
        if let uti = UTType(filenameExtension: pathExtension) {
            return uti.conforms(to: .movie) || uti.conforms(to: .video)
        }
        let videoExtensions = Set([
            "mp4", "mov", "m4v", "avi", "mkv", "wmv", "flv", "webm", "mpeg", "mpg", "3gp", "ts"
        ])
        return videoExtensions.contains(pathExtension.lowercased())
    }
}
