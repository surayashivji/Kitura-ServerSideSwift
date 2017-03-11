import Cryptor
import Foundation
import Kitura
import KituraNet
import HeliumLogger
import LoggerAPI
import MySQL
import SwiftyJSON

func connectToDatabase() throws -> (Database, Connection) {
    let mysql = try Database(
        host: "localhost",
        user: "swiftt",
        password: "swiftt",
        database: "swiftt"
    )
    let connection = try mysql.makeConnection()
    return (mysql, connection)
}

HeliumLogger.use()

let router = Router()
router.post("/", middleware: BodyParser())

router.get("/:user/posts") {
    request, response, next in
    defer { next() }
    
    guard let user = request.parameters["user"] else { return }
    
    // separate query from any parameters we want to send because 
    // that way database can ensure parameters are safe
    // avoids SQL injection
    
    let (db, connection) = try connectToDatabase()
    
    let query = "SELECT `id`, `user`, `message`, `date` FROM `posts` WHERE `user` = ? ORDER BY `date` DESC;"
    
    let posts = try db.execute(query, [user], connection)
    
    // need to convert mysql data back to JSON
    // vapor's mysql code sends back a bunch of Node objects....
    // we need to convert nodes to dictionaries and dictionaries to swiftyjson objects
    
    var parsedPosts = [[String:Any]]() // array of dicts
    
    // posts is an array of nodes
    // convert posts into dictionary of data
    
    for post in posts { // for each post in posts of Node objects - post = 1 node
        var postDictionary = [String: Any]()
        postDictionary["id"] = post["id"]?.int
        postDictionary["user"] = post["user"]?.string
        postDictionary["message"] = post["message"]?.string
        postDictionary["date"] = post["date"]?.string
        
        parsedPosts.append(postDictionary)
    }
    
    var result = [String: Any]()
    result["status"] = "ok"
    result["posts"] = parsedPosts
    
    // convert response to json for sending out
    let json = JSON(result)
    
    do {
        try response.status(.OK).send(json: json).end()
    } catch {
        Log.warning("Failed to send /:user/posts for \(user): \(error.localizedDescription)")
    }
}

Kitura.addHTTPServer(onPort: 8090, with: router)
Kitura.run()
