// swift-tools-version: 6.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "MimiGaiaExtension-iOS",
    platforms: [
            .iOS(.v15)
        ],
    products: [
        // Products define the executables and libraries a package produces, making them visible to other packages.
        .library(
            name: "MimiGaiaExtension",
            targets: ["MimiGaiaExtension"]
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/MimiHearingTechnologies/GaiaSDK-iOS.git", branch: "main")
    ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .target(
            name: "MimiGaiaExtension",
            dependencies: [
                .product(name: "GaiaCore", package: "GaiaSDK-iOS"),
                .product(name: "GaiaBase", package: "GaiaSDK-iOS"),
                .product(name: "Packets", package: "GaiaSDK-iOS"),
                .product(name: "GaiaLogger", package: "GaiaSDK-iOS")
            ]
        ),
        .testTarget(
            name: "MimiGaiaExtensionTests",
            dependencies: [
                "MimiGaiaExtension",
                .product(name: "GaiaCore", package: "GaiaSDK-iOS"),
                .product(name: "GaiaBase", package: "GaiaSDK-iOS"),
                .product(name: "Packets", package: "GaiaSDK-iOS"),
                .product(name: "GaiaLogger", package: "GaiaSDK-iOS")
            ]
        ),
    ]
)
