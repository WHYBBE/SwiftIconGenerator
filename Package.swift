// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "SFIconGenerator",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .executable(name: "SFIconGenerator", targets: ["SFIconGeneratorApp"])
    ],
    targets: [
        .executableTarget(
            name: "SFIconGeneratorApp",
            path: "Sources"
        )
    ]
)
