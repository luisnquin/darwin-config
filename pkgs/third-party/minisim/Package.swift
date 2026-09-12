// swift-tools-version:5.9
// SwiftPM manifest standing in for MiniSim.xcodeproj so the app builds with a
// plain Swift toolchain. Sparkle, LaunchAtLogin and SwiftLint are dropped: the
// first two ship prebuilt binaries, the last one is a build plugin.
import PackageDescription

let package = Package(
  name: "MiniSim",
  platforms: [.macOS(.v13)],
  dependencies: [
    .package(url: "https://github.com/sindresorhus/KeyboardShortcuts", branch: "main"),
    .package(url: "https://github.com/sindresorhus/Settings", branch: "main"),
    .package(url: "https://github.com/xnth97/SymbolPicker.git", from: "1.5.3"),
    .package(url: "https://github.com/ZeeZide/CodeEditor.git", from: "1.2.6"),
    .package(url: "https://github.com/vtourraine/AcknowList", from: "3.2.0"),
    .package(url: "https://github.com/JohnSundell/ShellOut.git", from: "2.3.0"),
  ],
  targets: [
    .executableTarget(
      name: "MiniSim",
      dependencies: [
        .product(name: "KeyboardShortcuts", package: "KeyboardShortcuts"),
        .product(name: "Settings", package: "Settings"),
        .product(name: "SymbolPicker", package: "SymbolPicker"),
        .product(name: "CodeEditor", package: "CodeEditor"),
        .product(name: "AcknowList", package: "AcknowList"),
        .product(name: "ShellOut", package: "ShellOut"),
      ],
      path: "MiniSim",
      exclude: [
        "AppleScript Commands",
        "Assets.xcassets",
        "Info.plist",
        "MainMenu.xib",
        "MiniSim.entitlements",
        "MiniSimRelease.entitlements",
        "Preview Content",
      ]
    ),
  ],
  swiftLanguageVersions: [.v5]
)
