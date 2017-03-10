import HeliumLogger
import Kitura
import KituraStencil
import Stencil

HeliumLogger.use()

let router = Router()
let namespace = Namespace()

// custom namespace code

router.setDefault(templateEngine: StencilTemplteEngine(namespace: namespace))

router.get("/") {
    request, response, next in
    
    defer { next() }
    
    let talk = "talking"
    
    let names = ["Suraya", "Jamie", "Sonika", "Bri"]
    
    let hampsters = [String]()
    
    let quote = "The boy walked down the hall and fell down the stairs"
    
    let context: [String: Any] = ["talk":talk, "names":names, "hampsters":hampsters, "quote":quote]
    
    try response.render("home", context: context)
}

Kitura.addHTTPServer(onPort: 8090, with: router)
Kitura.run()

