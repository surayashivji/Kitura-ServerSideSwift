import PackageDescription
// add package dependencies for Kitura, Stencil (templating), and Helium (debugging)
let package = Package(
    name: "1basicsite",
    dependencies: [
        .Package(url: "https://github.com/IBM-Swift/Kitura.git", majorVersion: 1),
        .Package(url: "https://github.com/IBM-Swift/HeliumLogger.git", majorVersion: 1),
        .Package(url: "https://github.com/IBM-Swift/Kitura-StencilTemplateEngine.git", majorVersion: 1)
    ]
)
