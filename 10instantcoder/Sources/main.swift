import CouchDB
import Credentials
import CredentialsGitHub
import Foundation
import HeliumLogger
import Kitura
import KituraNet
import KituraSession
import KituraStencil
import LoggerAPI
import SwiftyJSON

//couchdb connection code
let connectionProperties = ConnectionProperties(host: "localhost", port: 5984, secured: false)
let client = CouchDBClient(connectionProperties: connectionProperties)
let database = client.database("instantcoder")


// decode HTML forms
extension String {
    func removeHTMLEncoding() -> String {
        let result = self.replacingOccurrences(of: "+", with: " ")
        return result.removingPercentEncoding ?? result
    }
}

//error handling
func send(error: String, code: HTTPStatusCode, to response: RouterResponse) {
    _ = try? response.status(code).send(error).end()
}

// helper method for getting login form values & checking they were submitted
// returns finished dictionary
func getPost(for request: RouterRequest, fields: [String]) -> [String: String]? {
    
    // ensure form fields exist
    guard let values = request.body else { return nil }
    
    guard case .urlEncoded(let body) = values else { return nil }
    
    var result = [String: String]()
    
    for field in fields {
        if let value = body[field]?.trimmingCharacters(in: .whitespacesAndNewlines) {
            if value.characters.count > 0 {
                result[field] = value.removeHTMLEncoding()
                continue
            }
        }
        return nil
    }
    return result
}

func context(for request: RouterRequest) -> [String: Any] {
    var result = [String: Any]()
    result["username"] = request.userProfile?.displayName // request.userProfile given to us by Kitura-Credentials
    result["languages"] = ["C++", "C", "Java", "Swift", "Go", "JavaScript", "Objective-C", "Perl", "Python"]
    return result
}
            
             
HeliumLogger.use()

let router = Router()
router.setDefault(templateEngine: StencilTemplateEngine())
router.all("/static", middleware: StaticFileServer())
router.all(middleware: Session(secret: "Suraya's last name is Shivji"))




router.post("/", middleware: BodyParser())

// step 1 for auth: create and register github credentials
let credentials = Credentials()
let gitCredentials = CredentialsGitHub(clientId: "5b7b077f53376f159460",
                                       clientSecret: "9c7da9f62decf95d73fc5db18141ffdbe2fea23c",
                                       callbackUrl: "http://localhost:8090/login/github/callback",
                                       userAgent: "server-side-swift")
credentials.register(plugin: gitCredentials)

// step 2 : assign routes to trigger the authentication
    // one should start authentication process, next should be called by github once user grants approval
    // if auth fails get redirected back to first route, login to try again
// tell router that these two routes are handled by configured credentials object ^^
router.get("/login/github", handler: credentials.authenticate(credentialsType: gitCredentials.name))
router.get("/login/github/callback", handler: credentials.authenticate(credentialsType: gitCredentials.name))
credentials.options["failureRedirect"] = "/login/github"

// step 3 - tell router to use credentials object for /projects and /signup route (/signup assumes github auth but no instantcoder login)
router.all("/projects", middleware: credentials)
router.all("/signup", middleware: credentials)

// home page
router.get("/") {
    request, response, next in
    
    defer { next() }
    
    var pageContext = context(for: request)
    pageContext["page_home"] = true
    
    try response.render("home", context: pageContext)
}

// GET and POST route for /signup --> user has authenticated with github but has not created an instant coder account
router.get("/signup") {
    request, response, next in
    defer { next() }
    
    // guarantees that the user has authenticated using github (if not shouldnt b on this page)
    guard let profile = request.userProfile else { return }
    
    var pageContext = context(for: request)
    
}

router.post("/signup") {
    request, response, next in
    
    defer { next() }
    
    // immediately exit if we're missing github auth details or a valid form submission (the programming language)
    guard let profile = request.userProfile else { return }
    guard let fields = getPost(for: request, fields: ["language"]) else { return }
    
    // check if the user ID already has an account    
    database.retrieve(profile.id) { user, error in
        if let error = error {
            // user wasn't found!
            
            // fetch their full profile from GitHub          
            let gitHubURL = URL(string: "http://api.github.com/ user/\(profile.id)")!
            guard var gitHubProfile = try? Data(contentsOf: gitHubURL) else { return }
            
            // adjust it to fit the format we want: "_id" rather than "id", plus "type" and "language"
            var gitHubJSON = JSON(data: gitHubProfile)
            gitHubJSON["_id"].stringValue = gitHubJSON["id"].stringValue
            _ = gitHubJSON.dictionaryObject?.removeValue(forKey: "id")
            gitHubJSON["type"].stringValue = "coder"
            gitHubJSON["language"].stringValue = fields["language"]!

            database.create(gitHubJSON) { id, rev, doc, error in
                if let doc = doc {
                    // it worked! Activate their profile
                    request.session?["gitHubProfile"] = gitHubJSON
                }
            }
        } else if let user = user {
            // user was found, so just log them in          
            request.session?["gitHubProfile"] = user
        }
    }
    
    // redirect them to the logged-in homepage    
    _ = try? response.redirect("/projects/mine").end()

}

Kitura.addHTTPServer(onPort: 8090, with: router)
Kitura.run()
