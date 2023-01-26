// swift-tools-version: 5.7

import PackageDescription

let package = Package(
    name: "WRCalendarView",
    defaultLocalization: "en",
    platforms: [
        .iOS(.v13)
    ],
    products: [
        .library(
            name: "WRCalendarView",
            targets: ["WRCalendarView"]),
    ],
    dependencies: [
        .package(url: "https://github.com/HealthTap/DateTools", from: "5.0.0"),
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages this package depends on.
        .target(
            name: "WRCalendarView",
            dependencies: [
                .product(name: "DateToolsSwift", package: "DateTools")
            ]),
        .testTarget(
            name: "WRCalendarViewTests",
            dependencies: ["WRCalendarView"]),
    ]
)
