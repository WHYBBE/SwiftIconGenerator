// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "SwiftIconGenerator",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .executable(name: "SwiftIconGenerator", targets: ["SwiftIconGeneratorApp"])
    ],
    targets: [
        .executableTarget(
            name: "SwiftIconGeneratorApp",
            path: "Sources"
        )
    ]
)
