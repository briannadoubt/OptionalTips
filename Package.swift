// swift-tools-version: 6.0
import PackageDescription
let package = Package(
    name: "OptionalTips",
    defaultLocalization: "en",
    platforms: [.iOS(.v17), .macOS(.v14), .visionOS(.v1), .tvOS(.v17)],
    products: [.library(name: "OptionalTips", targets: ["OptionalTips"])],
    targets: [
        .target(name: "OptionalTips", resources: [.process("Resources")]),
        .testTarget(name: "OptionalTipsTests", dependencies: ["OptionalTips"], resources: [.copy("LocalTips.storekit")])
    ]
)
