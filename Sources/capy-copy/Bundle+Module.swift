import Foundation

extension Bundle {
    /// When the executable is packaged as a macOS app bundle, resources live in
    /// `Contents/Resources` and are exposed through `Bundle.main`. SwiftPM's
    /// generated `Bundle.module` is not used because the project no longer
    /// processes resources through the package manifest.
    static let module = Bundle.main
}
