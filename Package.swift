// swift-tools-version:5.9
import PackageDescription

let package = Package(
  name: "SystemAudioDump",
  platforms: [
    .macOS(.v13)
  ],
  dependencies: [
    // no external deps
  ],
  targets: [
    .executableTarget(
      name: "SystemAudioDump",
      dependencies: [],
      path: "Sources/SystemAudioDump"
    )
  ]
)
