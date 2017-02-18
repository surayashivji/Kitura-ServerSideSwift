import CouchDB
import Cryptor//encryption
import Foundation
import HeliumLogger
import Stencil
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
//router.setDefault(templateEngine: StencilTemplateEngine())
let namespace = Namespace()
// custom filter - formatting date
namespace.registerFilter("format_date") { (value: Any?) in
    if let value = value as? String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"
        if let date = formatter.date(from: value) {
            formatter.dateStyle = .long
            formatter.timeStyle = .medium
            return formatter.string(from: date)
        }
    }
    return value
}
router.setDefault(templateEngine: StencilTemplateEngine(namespace: namespace))

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
                                // render all the forums
                                forumContext["forums"] = forums["rows"].arrayObject // convert SwiftyJSON to array to give to template
                                _ = try? response.render("home", context: forumContext)
                            }
    }
}

router.get("/forum/:forumid") {
    request, response, next in
    
    guard let forumID = request.parameters["forumid"] else {
        send(error: "Missing Forum ID", code: .badRequest, to: response)
        return
    }
    
    database.retrieve(forumID) { forum, error in
        if let error = error {
            send(error: error.localizedDescription, code: .notFound, to: response)
        } else if let forum = forum {
            database.queryByView("forum_posts", ofDesign: "forum", usingParameters: [.keys([forumID as Database.KeyType]), .descending(true)]) { messages, error in
                defer { next() }
                
                if let error = error {
                    send(error: error.localizedDescription, code: .internalServerError, to: response)
                } else if let messages = messages {
                    var pageContext = context(for: request)
                    pageContext["forum_id"] = forum["_id"].stringValue
                    pageContext["forum_name"] = forum["name"].stringValue
                    pageContext["messages"] = messages["rows"].arrayObject
                    
                    _ = try? response.render("forum", context: pageContext)
                }
            }
        }
    }
}

Kitura.addHTTPServer(onPort: 8090, with: router)
Kitura.run()
