import Foundation
import Kitura
import HeliumLogger
import LoggerAPI
import SwiftyJSON
import CouchDB


HeliumLogger.use()

let router = Router()

// connect to couchdb
let connection = ConnectionProperties(host: "localhost", port: 5984, secured: false)
let databaseClient = CouchDBClient(connectionProperties: connection)
let database = databaseClient.database("polls")

// routes

// get request for all polls
router.get("/polls/list") {
    request, response, next in

    // (this is still synchronous)
    
    database.retrieveAll(includeDocuments: true) { docs, error
        in
            // executed when documents are fetched
            // docs : results of fetch, error: error
            defer { next() }
            
            if let error = error {
                let errorMessage = error.localizedDescription
                let status = ["status": "error",
                              "message": errorMessage]
                let result = ["result": status]
                let json = JSON(result)
                response.status(.OK).send(json: json)
            } else {
                // success
                // curl -X GET "$COUCH/polls/_all_docs?include_docs=true" = DOCS result
                // docs["rows"] is the "rows" array in the result
                // so we're looping through eahc poll
                let status = ["status":"ok"]
                var polls = [[String: Any]]() // array of dictionaries - array of each poll
                if let docs = docs {
                    for document in docs["rows"].arrayValue {
                        var poll = [String : Any]() // dictionary for string:any
                        // create poll from docs data
                        poll["id"] = document["id"].stringValue
                        poll["title"] = document["doc"]["title"].stringValue
                        poll["option1"] = document["doc"]["option1"].stringValue
                        poll["option2"] = document["doc"]["option2"].stringValue
                        poll["votes1"] = document["doc"]["votes1"].stringValue
                        poll["votes2"] = document["doc"]["votes2"].stringValue
                        
                        polls.append(poll)
                    }
                    
                }
                let result: [String: Any] = ["result": status,
                                             "polls": polls]
                let json = JSON(result)
                response.status(.OK).send(json: json)
        }
    }
}

// create new poll

// so by the time the 2nd "/polls/create" route is executed 
// Kitura will have already parsed the data
router.post("/polls/create", middleware: BodyParser())

router.post("/polls/create") {
    request, response, next in
    defer { next() }
    
    // request -- contains the request sent in by the user
    // request -- has a 'body' property that contains the parsed body
    // -- so we dont know type of data sent yet, but we can check it exists
    
    // CHECK THAT BODY EXISTS:
    // remember to never trust user data! (secure client, secure server too)
    // check and unwrap the body parameter safely!!
    // if the body is missing -- immediately send the .badRequetst status and exit closure
    guard let values = request.body else {
        try response.status(.badRequest).end() // response to user = bad request! then end it since its a try and returns an object
        return
    }
    
    //n 
}

// vote on a poll
router.post("/polls/vote/:pollid/:option") {
    request, response, next in
    defer { next() }
}

Kitura.addHTTPServer(onPort: 8090, with: router)
Kitura.run()
