// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "MyBurp",
    platforms: [
        .iOS(.v14),
        .macOS(.v11)
    ],
    products: [
        .library(
            name: "MyBurpInterceptor",
            targets: ["MyBurpInterceptor"]),
    ],
    targets: [
        .target(
            name: "MyBurpInterceptor",
            dependencies: [],
            path: "Sources/MyBurpInterceptor"),
        .testTarget(
            name: "MyBurpInterceptorTests",
            dependencies: ["MyBurpInterceptor"],
            path: "Tests/MyBurpInterceptorTests"),
    ]
)
