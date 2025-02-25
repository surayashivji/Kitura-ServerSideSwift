import PackageDescription

let package = Package(name: "8asciiart",
                      dependencies:
    [
                        .Package(url: "https://github.com/IBM-Swift/Kitura.git", majorVersion: 1),
                        .Package(url: "https://github.com/IBM-Swift/Kitura-StencilTemplateEngine.git", majorVersion: 1),
                        .Package(url: "https://github.com/IBM-Swift/HeliumLogger.git", majorVersion: 1),
                        .Package(url: "https://github.com/twostraws/SwiftGD.git", majorVersion: 1)
    ])
