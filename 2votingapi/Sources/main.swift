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

extension String {
    func removeHTMLEncoding() -> String {
        let result = self.replacingOccurrences(of: "+", with: " ")
        return result.removingPercentEncoding ?? result
    }
}

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
    
    // 2: check we have data submitted
    // CHECK THAT BODY EXISTS:
    // remember to never trust user data! (secure client, secure server too)
    // check and unwrap the body parameter safely!!
    // if the body is missing -- immediately send the .badRequetst status and exit closure
    guard let values = request.body else {
        try response.status(.badRequest).end() // response to user = bad request! then end it since its a try and returns an object
        return
    }
    
    // 3: try and pull out url-encoded values from submission
    // pull out url encoded values from user's submission
    // kitura stores parsed body using an enum with associated value
    // since we dont know how / in what form kitura will store the body (ie json, swiftyjson, urlenceded) we do a check
    
    // this says: check that values is set to the .urlEncoded valeu -- if so set its value into
    // constant called body
    // so this unwraps value into a variable (body) and checks for specific enum value
    guard case .urlEncoded(let body) = values else {
        try response.status(.badRequest).end()
        return
    }
    
    // 4: array of fields to check
    // so now we have body = dictionary containing keys/values submitted to route
    // array of fields we want to look for (what body would theoretically have, depends on user input)
    let fields = ["title", "option1", "option2"]
    
    var poll = [String: Any]()
    
    for field in fields {
        // check that field exists, and remove any whitespce if it does
        if let value = body[field]?.trimmingCharacters(in: .whitespacesAndNewlines) {
            /// make sure it has at least one character
            if value.characters.count > 0 {
                // add it to list of parsed values
                poll[field] = value.removeHTMLEncoding() // string (value) calling removeHTMLEncoding cuz we exntended String class to use it
                // go back to beginning of loop now
                
                // it exists! so go to next vlaue
                continue
            }
        }
        
        // value doesnt exist, send error & exit
        // one or more fields not there, get out
        try response.status(.badRequest).end()
        return
    }
    
    // successsfully validated user's info -- now we can create a couchDB document! (to store the data)
    
    // fill in default values for vote counts (they start at 0, remmember that user just created a poll)
    poll["votes1"] = 0
    poll["votes2"] = 0
    
    // convert the dictionary to json, which is what couchdb takes in
    let json = JSON(poll)
    
    database.create(json) { id, revision, doc, error in
        defer { next() }
        
        if let id = id {
            // document made successfully! return it to user
            
            let status = ["status": "ok", "id": id]
            let result = ["result": status]
            let json = JSON(result)
            
            response.status(.OK).send(json: json)
            
        } else {
            // something went wrong - show what / try and find out what 
            let errorMsg = error?.localizedDescription ?? "Unkown error"
            let status = ["status": "error",
                          "message": errorMsg]
            let result = ["result": status]
            let json = JSON(result)
            
            // show internal server error / we know its not client problem cuz we already
            // validated all the data
            response.status(.internalServerError).send(json: json)
        }
    }
}

// vote on a poll
router.post("/polls/vote/:pollid/:option") {
    request, response, next in
    
    
    // check that both parameters have the values
    // response - what we send back to user
    // request - what user sent in to us
    
    // step 1: check that the parameters exist so they did submit values
    guard let poll = request.parameters["pollid"],
        let option = request.parameters["option"] else {
            try response.status(.badRequest).end()
            return
    }
    
    // step 2: pull out the poll from couchdb that the user requested
    // poll = the poll id they requested
    database.retrieve(poll) {
        doc, error in
        defer { next() }
        
        if let error = error {
            // something wrong - couldnt get poll from database . poll not found
            let errorMsg = error.localizedDescription
            let status = ["status": "error",
                          "message": errorMsg]
            let result = ["result" : status]
            let json = JSON(result)
            
            response.status(.notFound).send(json: json)
            
            next()
        } else if let doc = doc {
            // update document in couch db with new poll vote
            // now doc = the couchdb document of tha tone poll the user wants to ote on
            // doc = a swiftyjson object
            
            // make a copy of doc, add one to the relevant poll vote, save it again to couchdb
            let id = doc["_id"].stringValue
            let rev = doc["_rev"].stringValue
            
            var newDocument = doc
            if option == "1" {
                newDocument["votes1"].intValue += 1
            } else if option == "2" {
                newDocument["votes2"].intValue += 1
            }
            
            // now we need to update the couchdb doc with this new doc
            database.update(id, rev: rev, document: newDocument) {
                rev, doc, error in
                
                // we eget back new rev number, updated json doc, and error code
                defer { next() }
                
                if let error = error {
                    let status = ["status": "error"]
                    let result = ["result": status]
                    let json = JSON(result)
                    
                    response.status(.conflict).send(json: json)
                } else {
                    let status = ["status": "ok"]
                    let result = ["result": status]
                    let json = JSON(result)
                    response.status(.OK).send(json: json)
                }
            }
            
        }
    }
    
    defer { next() }
}

Kitura.addHTTPServer(onPort: 8090, with: router)
Kitura.run()
