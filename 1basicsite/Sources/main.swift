import Kitura
import LoggerAPI
import HeliumLogger
import KituraStencil

// logger imports allow us to see the logs kitura puts out
// logger API: methods we can call to write log messages
// helium: connects to logger api and prints to terminal

// activate helium
HeliumLogger.use()
let router = Router()
// create instance of stencil template engine
// attach engine instance to router
router.setDefault(templateEngine: StencilTemplateEngine())

// StaticFileServer() : serves static files (html, css, js, images, etc)

// middleware
// layer of code you can inject between the user's request and the routes in here that handle it
// provides fallback for paths that have matching filename in public directory!
router.all("/static", middleware: StaticFileServer())


// dummy data
let bios = [
    "kirk" : "gilmore girls yee",
    "rory" : "yale is great",
    "luke" : "has good pancakes",
    "taylor" : "mayorrrrr"
]

// base route, root of website
// all is neither get nor post, it kinda is  a catch-all (better to bind routes to specific methods in future) ie get, post, put, delete
router.get("/") {
    request, response, next in
    // closure attached to each route (requqest response next)
    // request: what the user's request is: so the url, the headers, any cookies, and query attached string etc (stuff going in)
    // response: lets us send data back with the result of the request (stuff going out)
    // next closure tells router to continue matching paths --> it lets u attach a lot of code to 1 path and have it run in sequence
    
    // response.send
    // lets u deliver content to the user
    // with next, u can send content in multiple handlers
    //    response.send("Welcome to my site!")
    defer { next() }
    try response.render("home", context: [:])
    //    next()
}

router.get("/staff") {
    request, response, next in
    defer { next() }
    
    var context = [String: Any]()
    context["people"] = bios.keys.sorted()
    context["main"] = true
    
    try response.render("staff", context: context)
}

router.get("/staff/:name") {
    request, response, next in
    
    defer { next() }
    
    
    // get name of staff member
    guard let name = request.parameters["name"] else {
        return
    }
    
    // context dictionary to pass to template
    var context = [String: Any]()
    
    // take names from bios dict, sort alphabetically, store in context
    context["people"] = bios.keys.sorted()
    
    if let bio = bios[name] {
        // bio is not nil so the name searched exists in dictionary
        context["name"] = name
        context["bio"] = bio
    }
    
    
    // render template with what we have in context now
    try response.render("staff", context: context)
}

router.get("/contact") {
    request, response, next in
    //    response.send("get in touch with us here!")
    //    next()
    
    defer { next() }
    try response.render("contact", context: [:])
}

Kitura.addHTTPServer(onPort: 8090, with: router)
Kitura.run()
