import HeliumLogger
import Kitura
import KituraStencil
import Stencil

HeliumLogger.use()

let router = Router()
let namespace = Namespace()

// custom namespace code

// reverse string namespace
namespace.registerFilter("reverse") { (value: Any?) in
    guard let unwrapped = value as? String else { return value }
    return String(unwrapped.characters.reversed())
}

// register Simple Tag lets u work with tags that dont manipulate content 
// print all contentes of a context passed to a template
namespace.registerSimpleTag("debug") { context in
    return String(describing: context.flatten())
}

namespace.registerTag("autoescape", parser:
AutoescapeNode.parse)

router.setDefault(templateEngine: StencilTemplateEngine(namespace: namespace))

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

