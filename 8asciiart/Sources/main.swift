import Foundation
import HeliumLogger
import Kitura
import KituraStencil
import LoggerAPI
import SwiftGD

HeliumLogger.use() //logging
let router = Router()
router.setDefault(templateEngine: StencilTemplateEngine())

router.get("/") {
    request, response, next in
    defer { next() }
    
    try response.render("home", context: [:])
}

Kitura.addHTTPServer(onPort: 8090, with: router)
Kitura.run()
