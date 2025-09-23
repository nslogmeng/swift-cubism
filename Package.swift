// swift-tools-version: 6.1
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Cubism",
    platforms: [
        .iOS(.v17),
        .macOS(.v14),
        .watchOS(.v8),
        .tvOS(.v17)
    ],
    products: [
        // Products define the executables and libraries a package produces, making them visible to other packages.
        .library(name: "Cubism", targets: ["Cubism"]),
    ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .target(
            name: "Cubism",
            dependencies: [
                .target(name: "CubismBridge")
            ],
        ),
        .target(
            name: "CubismBridge",
            dependencies: [
                .target(name: "CubismFramework")
            ],
            cxxSettings: [
                .headerSearchPath("src")
            ],
            linkerSettings: [
                .linkedLibrary("stdc++"),
                .linkedFramework("UIKit", .when(platforms: [.iOS, .tvOS])),
                .linkedFramework("Metal", .when(platforms: [.iOS, .tvOS]))
            ]
        ),
        .target(
            name: "CubismFramework",
            dependencies: [
                .target(name: "Live2DCubismCore")
            ],
            exclude: [
                "README.md",
                "README.ja.md",
                "CHANGELOG.md",
                "TRANSLATION.md",

                "CMakeLists.txt",

                "src/CMakeLists.txt",
                "src/Effect/CMakeLists.txt",
                "src/Id/CMakeLists.txt",
                "src/Math/CMakeLists.txt",
                "src/Model/CMakeLists.txt",
                "src/Motion/CMakeLists.txt",
                "src/Physics/CMakeLists.txt",
                "src/Rendering/CMakeLists.txt",
                "src/Type/CMakeLists.txt",
                "src/Utils/CMakeLists.txt",

                // use metal render
                "src/Rendering/Metal/CMakeLists.txt",
                // exclude other renders
                "src/Rendering/D3D9",
                "src/Rendering/D3D11",
                "src/Rendering/OpenGL",
                "src/Rendering/Vulkan",
            ],
            publicHeadersPath: "include",
            cSettings: [
                .unsafeFlags(["-fno-objc-arc"])
            ],
            cxxSettings: [
                .headerSearchPath("src")
            ],
            linkerSettings: [
                .linkedFramework("Live2DCubismCore"),

                .linkedLibrary("stdc++"),
                .linkedFramework("UIKit", .when(platforms: [.iOS, .tvOS])),
                .linkedFramework("Metal", .when(platforms: [.iOS, .tvOS]))
            ]
        ),
        .binaryTarget(
            name: "Live2DCubismCore",
            path: "Core/Live2DCubismCore.xcframework"
        ),
        .testTarget(
            name: "CubismTests",
            dependencies: ["Cubism"]
        ),
    ],
    cxxLanguageStandard: .cxx14
)
