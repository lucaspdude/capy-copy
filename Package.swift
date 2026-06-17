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
            resources: [
                .process("Resources")
            ],
            linkerSettings: [
                .linkedFramework("Carbon"),
                .linkedFramework("EventKit"),
                .linkedFramework("SystemConfiguration"),
                .linkedFramework("QuickLookThumbnailing"),
                .linkedFramework("CloudKit")
            ]
        ),
        .testTarget(
            name: "capy-copyTests",
            dependencies: ["capy-copy"],
            path: "Tests/capy-copyTests"
        )
    ]
)
