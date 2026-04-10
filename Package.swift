// swift-tools-version: 5.8
import PackageDescription

let package = Package(
    name: "OpenMoaKeyboardCore",
    products: [
        .library(
            name: "OpenMoaKeyboardCore",
            targets: ["OpenMoaKeyboardCore"]
        ),
    ],
    targets: [
        .target(
            name: "OpenMoaKeyboardCore",
            path: "Sources/OpenMoaKeyboardCore"
        ),
        .testTarget(
            name: "OpenMoaKeyboardCoreTests",
            dependencies: ["OpenMoaKeyboardCore"],
            path: "Tests/OpenMoaKeyboardCoreTests"
        ),
    ]
)
