import Kitura
import HeliumLogger

HeliumLogger.use()
let router = Router()
//
//router.get("/hello") {
//    request, response, next in
//    defer { next() }
//    response.send("Hello")
//}
//
//router.get("/hello") {
//    request, response, next in
//    defer { next() }
//    response.send(", World")
//}

// route chaning in kitura
// router methods like get() post() and all() are variadic
// variadic --> they accept one or more closures to run, kitura stops chain if next() isn't called


// rewrite with chaining - used for multiple code segments with same router method
router.get("/hello", handler: {
    request, response, next in
    defer { next() }
    response.send("hello")
}, {
    request, response, next in
    defer { next() }
    response.send(", world")
})

// route() function used for using multiple HTTP methods on same path
// how route() works ==> creates a sub router behind the scenes ( a route responsible for only this section of routes)
router.route("/test")
    .get() {
        request, response, next in
        defer { next() }
        response.send("Hey! Using GET on /test")
        
    }.post() {
        request, response, next in
        defer { next() }
        response.send("Using POST on /test")
    }

// Reading User Data
// 4 ways to read user data

// 1 - url paramaters that are declared in the route ie /users/:name
router.get("/games/:name") {
    request, response, next in
    defer {  next() }
    
    // putting it in url makes it available in request paramaters dict
    guard let name = request.parameters["name"] else { return }
    response.send("Load the \(name) game")
}

// 2 - reading url encoded form paramaters that were submitted using POST (using BodyParser)
// most common with websites, complex in Kitura

// two steps: first add BodyParser middleware to the route
router.post("/employees/add", middleware: BodyParser())

// next, read submitted value
router.post("/employees/add") {
    request, response, next in
    
    // first, ensure request has a body
    guard let values = request.body else {
        try response.status(.badRequest).end()
        return
    }
    
    // pull out body's url-encoded parameters
    guard case .urlEncoded(let body) = values else {
        try response.status(.badRequest).end()
        return
    }
    
    // find value u want
    guard let name = body["name"] else { return }
    
    response.send("New employee named \(name) added")
    next()
}

// 3 - read in url encoded paramaters with GET request
// ie http://localhost:8090/platforms?name=iOS
// easier than working with POST values
router.get("/platforms") {
    request, response, next in
    
    guard let name = request.queryParameters["name"] else {
        try response.status(.badRequest).end()
        return
    }
    
    response.send("Loading the \(name) Platform")
    
    next()
}

// *** GENERALLY, URL parameters should be first choice, POST second choice, and GET third choice *** (get easier but suited for reading data)

// 4 -final way to submit values is using JSON
// similar to using url encoded values over POST but ends with a SwiftyJson objectrather than regular dict
router.post("/messages/create", middleware: BodyParser())

// regular route closure
router.post("/messages/create") {
    request, response, next in
    
    guard let values = request.body else {
        try response.status(.badRequest).end()
        return
    }
    
    guard case .json(let body) = values else {
        try response.status(.badRequest).end()
        return
    }
    
    // body is a swifty json object now
    // string (unlike stringValue) returns an optional string so use if let to unwrap
    if let title = body["title"].string {
        response.send("Adding new message with the title \(title)")
    } else {
        response.send("Provide a title.")
    }
    next()
}

// REGEX use groups to capture regex since technically Kitura does it automatically
// match routes such as "/search/2016/Usc"
// search/numbers 0 - 9 /one or more letters case insensitive
// stored in request params like any other url params
// regular expressions built into kitura router
router.get("/search/([0-9]+)/([A-Za-z]+)") {
    
    request, response, next in
    
    defer { next() }
    
    guard let year = request.parameters["0"] else { return }// first regex position in URL
    guard let string = request.parameters["1"] else { return }
    
     response.send("You searched for \(string) in \(year)")
}

// decode HTML forms
extension String {
    func removeHTMLEncoding() -> String {
        let result = self.replacingOccurrences(of: "+", with: " ")
        return result.removingPercentEncoding ?? result
    }
}

Kitura.addHTTPServer(onPort: 8090, with: router)
Kitura.run()
