// swift-tools-version: 6.0
// Built through React Native's SwiftPM autolinker, which links this package at
// <app>/build/generated/autolinking/libs/react-native-pdf. The relative package
// paths resolve from there to the app's React Native xcframeworks and codegen output.
// This file has no scaffolder marker, so `react-native spm scaffold` leaves it alone.

import Foundation
import PackageDescription

// The target path is the package root, and SwiftPM scans all of it for implicit
// resources: example/ or FabricExample/ assets, or any in node_modules/, would
// demand a defaultLocalization. So exclude every root entry the target does not use.
// Listing the entries, not naming them, works in a repo checkout and in an npm
// install alike; excluding a missing path makes SwiftPM warn.
// SwiftPM caches this manifest's result and does not see the listing change.
// When a root entry appears or disappears after the first resolve (for
// example node_modules/ from `yarn install` or `rm -rf`), reset the package
// cache: in Xcode, File > Packages > Reset Package Caches; for `swift build`,
// delete ~/Library/Caches/org.swift.swiftpm/manifests.
let usedRootEntries: Set<String> = ["ios", "react-native-spm-prefix.h", "Package.swift"]
let unusedRootEntries = try! FileManager.default.contentsOfDirectory(atPath: Context.packageDirectory)
    .filter { !usedRootEntries.contains($0) }
    .sorted()

let package = Package(
    name: "react-native-pdf",
    platforms: [.iOS("15.1")],
    products: [
        .library(name: "react-native-pdf", targets: ["react-native-pdf"]),
    ],
    dependencies: [
        .package(name: "ReactNative", path: "../../../../xcframeworks"),
        .package(name: "React-GeneratedCode", path: "../../../ios"),
    ],
    targets: [
        .target(
            name: "react-native-pdf",
            dependencies: [.product(name: "ReactHeaders", package: "ReactNative"), .product(name: "ReactNativeHeaders", package: "ReactNative"), .product(name: "ReactNativeDependenciesHeaders", package: "ReactNative"), .product(name: "ReactAppHeaders", package: "React-GeneratedCode")],
            path: ".",
            exclude: ["ios/RNPDFPdf.xcodeproj"] + unusedRootEntries,
            sources: ["ios/RNPDFPdf"],
            publicHeadersPath: "ios/RNPDFPdf",
            // CocoaPods gets RCT_NEW_ARCH_ENABLED from install_modules_dependencies;
            // without it the Fabric component view in RNPDFPdfView.mm is compiled out.
            cSettings: [.headerSearchPath("ios/RNPDFPdf"), .headerSearchPath("."), .unsafeFlags(["-include", "react-native-spm-prefix.h"]), .define("RCT_NEW_ARCH_ENABLED", to: "1")],
            cxxSettings: [.headerSearchPath("ios/RNPDFPdf"), .headerSearchPath("."), .unsafeFlags(["-include", "react-native-spm-prefix.h"]), .define("DEBUG", .when(configuration: .debug)), .define("NDEBUG", .when(configuration: .release)), .define("RCT_NEW_ARCH_ENABLED", to: "1")],
            linkerSettings: [.linkedFramework("UIKit"), .linkedFramework("Foundation"), .linkedFramework("CoreGraphics"), .linkedFramework("PDFKit")]
        ),
    ],
    cxxLanguageStandard: .cxx20
)
