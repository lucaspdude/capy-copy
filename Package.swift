// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "capy-copy",
    defaultLocalization: "en",
    platforms: [.macOS(.v14)],
    products: [
        .executable(name: "capy-copy", targets: ["capy-copy"])
    ],
    dependencies: [],
    targets: [
        .executableTarget(
            name: "capy-copy",
            dependencies: [],
            path: "Sources/capy-copy",
            linkerSettings: [
                .linkedFramework("Carbon"),
                .linkedFramework("SystemConfiguration"),
                .linkedFramework("QuickLookThumbnailing"),
                .linkedFramework("CloudKit"),
                .linkedFramework("EventKit")
            ]
        ),
        .testTarget(
            name: "capy-copyTests",
            dependencies: ["capy-copy"],
            path: "Tests/capy-copyTests"
        )
    ]
)
