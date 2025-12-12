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
        .executable(
            name: "MyBurpServer",
            targets: ["MyBurpServer"]),
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-nio.git", from: "2.62.0"),
    ],
    targets: [
        .target(
            name: "MyBurpInterceptor",
            dependencies: [],
            path: "Sources/MyBurpInterceptor"),
        .executableTarget(
            name: "MyBurpServer",
            dependencies: [
                "MyBurpInterceptor",
                .product(name: "NIOCore", package: "swift-nio"),
                .product(name: "NIOPosix", package: "swift-nio"),
                .product(name: "NIOHTTP1", package: "swift-nio"),
            ],
            path: "Sources/MyBurpServer"),
        .testTarget(
            name: "MyBurpInterceptorTests",
            dependencies: ["MyBurpInterceptor"],
            path: "Tests/MyBurpInterceptorTests"),
    ]
)
