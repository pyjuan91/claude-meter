// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "ClaudeMeter",
    platforms: [.macOS(.v13)],
    targets: [
        .target(
            name: "CryptoShim",
            path: "Sources/CryptoShim"
        ),
        .executableTarget(
            name: "ClaudeMeter",
            dependencies: ["CryptoShim"],
            path: "Sources/ClaudeMeter",
            linkerSettings: [
                .linkedLibrary("sqlite3"),
                .linkedFramework("Security"),
            ]
        ),
    ]
)
