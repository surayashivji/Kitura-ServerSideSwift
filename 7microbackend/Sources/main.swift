import Cryptor
import Foundation
import Kitura
import KituraNet
import HeliumLogger
import LoggerAPI
import MySQL
import SwiftyJSON

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
                result[field] = value.removeHTMLEncoding()
                continue
            }
        }
        return nil
    }
    return result
}

func password(from str: String, salt: String) -> String {
    let key = PBKDF.deriveKey(fromPassword: str, salt: salt, prf: .sha512, rounds: 250_000, derivedKeyLength: 64)
    
    return CryptoUtils.hexString(from: key)
}

extension String {
    func removeHTMLEncoding() -> String {
        let result = self.replacingOccurrences(of: "+", with: "")
        return result.removingPercentEncoding ?? result
    }
}

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

// test with: curl localhost:8090/login -d "username=twostraws" -d "password=twostraws"
router.post("/login") {
    request, response, next in
    defer { next() }
    
    // make sure two required fields exist!
    guard let fields = getPost(for: request, fields: ["username", "password"]) else {
//        send(error: "Missing required fields", code: .badRequest, to: response)
        return
    }
    
    // connect to mysql
    let (db, connection) = try connectToDatabase()
    
    // pull out password and salt for the user
    let query = "SELECT `password`, `salt` FROM `users` WHERE `id` = ?;"
    let users = try db.execute(query, [fields["username"]!])
    
    // ensure we got a row back from database
    guard let user = users.first else { return }
    
    // pull both values (the password and salt) from mysql query
    guard let savedPassword = user["password"]?.string else { return }
    guard let savedSalt = user["salt"]?.string else { return }
    
    // use saved salt to create a hash from submitted password
    let testPassword = password(from: fields["password"]!, salt: savedSalt)
    
    /// compare new hash against existing hash
    if savedPassword == testPassword {
        // success! clear out expired tokens
        try db.execute("DELETE FROM `tokens` WHERE `expiry` < NOW()", [], connection)
        
        // generate new random token 
        let token = UUID().uuidString
        
        // add token to db for user with new expiration date
        try db.execute("INSERT INTO `tokens` VALUES (?, ?, DATE_ADD(NOW(), INTERVAL 1 DAY));", [token, fields["username"]!], connection)
        
        // send token back to user
        var result = [String: Any]()
        result["status"] = "ok"
        result["token"] = token
        
        let json = JSON(result)
        
        do {
            try response.status(.OK).send(json: json).end()
        } catch {
            Log.warning("Failed to send /login for user \(user) \(error.localizedDescription)")
        }
     }
}


Kitura.addHTTPServer(onPort: 8090, with: router)
Kitura.run()
