import PackageDescription
let package = Package(name: "6templates", dependencies:
    [.Package(url: "https://github.com/IBM-Swift/Kitura.git", majorVersion: 1),
     .Package(url: "https://github.com/IBM-Swift/Kitura-StencilTemplateEngine.git", majorVersion: 1),
     .Package(url: "https://github.com/IBM-Swift/HeliumLogger.git", majorVersion: 1),
     .Package(url: "https://github.com/IBM-Swift/swift-html-entities.git", majorVersion: 2)
        // html entities - renders html tags as text 
    ]
)
