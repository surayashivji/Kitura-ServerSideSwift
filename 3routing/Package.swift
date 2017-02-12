import PackageDescription

let package = Package(
    name: "3routing",
    dependencies: [
    .Package(url: "https://github.com/IBM-Swift/Kitura.git", majorVersion: 1),
    .Package(url: "https://github.com/IBM-Swift/HeliumLogger.git", majorVersion: 1)
    ]
)
