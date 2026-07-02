// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "TwoTierPremiumAccess",
    platforms: [
        .iOS(.v17)
    ],
    products: [
        .library(
            name: "TwoTierPremiumAccess",
            targets: ["TwoTierPremiumAccess"]
        )
    ],
    targets: [
        .target(
            name: "TwoTierPremiumAccess"
        )
    ]
)
