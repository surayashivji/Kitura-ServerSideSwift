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
    result["username"] = request.session?["username"].string
    return result
}

// clean up html (percent signs, + symbols)
extension String {
    func removingHTMLEncoding() -> String {
        let result = self.replacingOccurrences(of: "+", with: "")
        return result.removingPercentEncoding ?? result
    }
}

// helper method for getting login form values and checking they were submitted
// similar to project 2 logic but now it returns finished dictionary
func getPost(for request: RouterRequest, fields: [String]) -> [String: String]? {
    
    // ensure form fields exist
    guard let values = request.body else { return nil }
    
    guard case .urlEncoded(let body) = values else { return nil }
    
    var result = [String: String]()
    
    for field in fields {
        if let value = body[field]?.trimmingCharacters(in: .whitespacesAndNewlines) {
            if value.characters.count > 0 {
                result[field] = value.removingHTMLEncoding()
                continue
            }
        }
        return nil
    }
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

// MARK: Security
// using SHA-512 algorithm across 250,000 rounds
// deriveKey outputs array of integers
func password(from str:String, salt: String) -> String {
    let key = PBKDF.deriveKey(fromPassword: str, salt: salt, prf: .sha512, rounds: 250_000, derivedKeyLength: 64)
    // convert array of integers into a string so we ca n store it as a password
    return CryptoUtils.hexString(from: key)
}

// MARK: Routes
router.setDefault(templateEngine: StencilTemplateEngine(namespace: namespace))

router.post("/", middleware: BodyParser())

// StaticFileServer() : serves static files (html, css, js, images, etc)
// middleware
// layer of code you can inject between the user's request and the routes in here that handle it
// provides fallback for paths that have matching filename in public directory!
router.all("/static", middleware: StaticFileServer())

// we need session for all routes
// attach it to all routes
// session secret (can be whwatever, trojan thing) encrypts the session id on the user's machine
router.all(middleware: Session(secret: "Fight on trojans!"))

router.get("/") {
    request, response, next in
    
    // query the list of forums using the forums view (lists them all)
    // design document is called forum
    
    // queryByView -- result of this is stored in couchdb
    // OF DESIGN -- design document where the view is (forum on couchdb)
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


router.get("/forum/:forumid/:messageid") {
    request, response, next in
    
    guard let forumID = request.parameters["forumid"],
        let messageID = request.parameters["messageid"] else {
            try response.status(.badRequest).end()
            return
    }
    
    database.retrieve(forumID) { forum, error in
        if let error = error {
            send(error: error.localizedDescription, code: .notFound, to: response)
        } else if let forum = forum {
            database.retrieve(messageID) { message, error in
                if let error = error {
                    send(error: error.localizedDescription, code: .notFound, to: response)
                } else if let message = message {
                    database.queryByView("forum_replies", ofDesign: "forum", usingParameters: [.keys([messageID as Database.KeyType])]) { replies, error in
                        defer { next() }
                        
                        if let error = error {
                            send(error: error.localizedDescription, code: .internalServerError, to: response)
                        } else if let replies = replies {
                            var pageContext = context(for: request)
                            pageContext["forum_id"] = forum["_id"].stringValue
                            pageContext["forum_name"] = forum["name"].stringValue
                            pageContext["message"] = message.dictionaryObject!
                            pageContext["replies"] = replies["rows"].arrayObject
                            
                            _ = try? response.render("message", context: pageContext)
                        }
                    }
                }
            }
        }
    }
}

router.get("/users/login") {
    request, response, next in
    defer { next() }
    
    try response.render("login", context: [:])
}


// POST Method - triggered when user hits login form
// STEPS
// 1 - extract form values, ensure they exist
// 2 - get user document from couchdb that matches the user name they entered
// 3 - use password method to compare the pass entered with hashed value we saved
// 4 - compare it with hased result we have in db
// 5 - on success - save username in session, redirect home
router.post("/users/login") {
    request, response, next in
    
    // make sure all correct fields are present
    if let fields = getPost(for: request, fields: ["username", "password"]) {
        // load user from couchdb
        database.retrieve(fields["username"]!) { doc, error in
            defer { next() }
            
            if let error = error {
                //  user doesn't exist
                send(error: "Unable to load user.", code: .badRequest, to: response)
                
            } else if let doc = doc {
                // load salt and password from couchdb user document
                let savedSalt = doc["salt"].stringValue
                let savedPassword = doc["password"].stringValue
                
                // hash  user's input password with the saved salt
                // this should produce the same password we have saved in couchdb
                let testPassword = password(from: fields["password"]!, salt: savedSalt)
                
                if testPassword == savedPassword {
                    // pass was correct - save username in session and redirect to home page
                    request.session!["username"].string = doc["_id"].string
                    _ = try? response.redirect("/")
                } else {
                    // wrong password
                    print("no password match!")
                }
            }
            
        }
    } else {
        // all fields not present, form not filled in properly
        send(error: "Missing fields", code: .badRequest, to: response)
    }
}

Kitura.addHTTPServer(onPort: 8090, with: router)
Kitura.run()
