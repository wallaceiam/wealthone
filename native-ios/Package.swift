// swift-tools-version: 6.0
import PackageDescription

let package = Package(
  name: "WealthOneCore", products: [.library(name: "WealthOneCore", targets: ["WealthOneCore"])],
  targets: [
    .target(name: "WealthOneCore"),
    .target(name: "WealthOneShared", path: "Shared"),
    .testTarget(name: "WealthOneCoreTests", dependencies: ["WealthOneCore", "WealthOneShared"]),
  ])
