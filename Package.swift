// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "RightMouseUtility",
    platforms: [.macOS(.v13)],
    targets: [
        .target(name: "RightMouseCore", path: "Sources/Core"),
        .testTarget(name: "CoreTests", dependencies: ["RightMouseCore"], path: "Tests/CoreTests")
    ]
)
