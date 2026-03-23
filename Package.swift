// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "KeyboardCleaner",
    platforms: [
        .macOS(.v13)
    ],
    targets: [
        .executableTarget(
            name: "KeyboardCleaner",
            path: "KeyboardCleaner",
            exclude: [
                "Info.plist"
            ],
            resources: [
                .process("Resources")
            ],
            linkerSettings: [
                .linkedFramework("Cocoa"),
                .linkedFramework("ApplicationServices")
            ]
        ),
        .testTarget(
            name: "KeyboardCleanerTests",
            dependencies: ["KeyboardCleaner"],
            path: "KeyboardCleanerTests"
        )
    ]
)
