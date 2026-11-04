// swift-tools-version:6.0
// Build the app with ./build.sh (wraps `swift build` into Keyper.app and installs it).
import PackageDescription

let package = Package(
    name: "Keyper",
    platforms: [.macOS(.v14)],
    dependencies: [
        // Self-updating from GitHub releases (https://sparkle-project.org); see tools/sparkle.sh.
        .package(url: "https://github.com/sparkle-project/Sparkle", exact: "2.10.0"),
    ],
    targets: [
        .executableTarget(name: "Keyper", dependencies: [.product(name: "Sparkle", package: "Sparkle")],
                          path: "Sources/Keyper",
                          // Run straight from .build too (Sparkle.framework sits next to the binary there).
                          linkerSettings: [.unsafeFlags(["-Xlinker", "-rpath", "-Xlinker", "@executable_path"])]),
    ],
    swiftLanguageModes: [.v5]
)
