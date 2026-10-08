// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "menubar-kit",
    platforms: [.macOS(.v13)],
    products: [.library(name: "MenuBarKit", targets: ["MenuBarKit"])],
    targets: [
        .target(name: "MenuBarKit", path: "Sources/MenuBarKit"),
        .testTarget(name: "MenuBarKitTests", dependencies: ["MenuBarKit"], path: "Tests/MenuBarKitTests")
    ]
)
