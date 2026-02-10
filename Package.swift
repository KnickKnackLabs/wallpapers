// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "wallpapers",
    platforms: [.macOS(.v13)],
    targets: [
        .target(name: "WallpaperKit"),
        .executableTarget(name: "generate", dependencies: ["WallpaperKit"]),
        .executableTarget(name: "setup", dependencies: ["WallpaperKit"]),
    ]
)
