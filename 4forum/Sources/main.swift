import CouchDB
import Cryptor//encryption
import Foundation
import HeliumLogger
import Kitura
import KituraNet//http status codes
import KituraSession//read/write user sessions
import KituraStencil
import LoggerAPI
import SwiftyJSON

//error handling
func send(error: String, code: HTTPStatusCode, to response: RouterResponse) {
    _ = try? response.status(code).send(error).end()
}

// maintain sessions
func context(for request: RouterRequest) -> [String: Any] {
    var result = [String: String]()
    result["username"] = "testing"
    return result
}

HeliumLogger.use()

let connectionProperties = ConnectionProperties(host: "localhost", port: 5984, secured: false)
let client = CouchDBClient(connectionProperties: connectionProperties)
let database = client.database("forum")

let router = Router()
router.setDefault(templateEngine: StencilTemplateEngine())
router.post("/", middleware: BodyParser())
// StaticFileServer() : serves static files (html, css, js, images, etc)
// middleware
// layer of code you can inject between the user's request and the routes in here that handle it
// provides fallback for paths that have matching filename in public directory!
router.all("/static", middleware: StaticFileServer())

router.get("/") {
    request, response, next in
    
    // query the list of forums using the forums view (lists them all)
    // design document is called forum
    
    // queryByView -- result of this is stored in couchdb
    database.queryByView("forums", ofDesign: "forum",
                         usingParameters: []) { forums, error in
                            
                            defer { next() }
                            if let error = error {
                                send(error: error.localizedDescription, code: .internalServerError, to: response)
                            } else if let forums = forums {
                                // success
                                var forumContext = context(for: request)
                                forumContext["forums"] = forums["rows"].arrayObject // convert SwiftyJSON to array to give to template
                                _ = try? response.render("home", context: forumContext)
                            }
    }
}

Kitura.addHTTPServer(onPort: 8090, with: router)
Kitura.run()
