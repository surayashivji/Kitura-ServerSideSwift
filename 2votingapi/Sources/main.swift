import Foundation
import Kitura
import HeliumLogger
import LoggerAPI
import SwiftyJSON
import CouchDB

HeliumLogger.use()

let router = Router()

// connect to couchdb
let connection = ConnectionProperties(host: "http://localhost.com", port: 5984, secured: false)
let databaseClient = CouchDBClient(connectionProperties: connection)
let database = databaseClient.database("polls")

// routes

// get request for all polls
router.get("/polls/list") {
    request, response, next in

    // (this is still synchronous)
    database.retrieveAll(includeDocuments: true
        , callback: { (docs, error) in
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
            }
    })
    
    let status = ["status":"ok"]
    let result = ["result" : status]
    let json = JSON(result)
    
    response.status(.OK).send(json: json)
}

// create new poll
router.post("/polls/create") {
    request, response, next in
    defer { next() }
}

// vote on a poll
router.post("/polls/vote/:pollid/:option") {
    request, response, next in
    defer { next() }
}

Kitura.addHTTPServer(onPort: 8090, with: router)
Kitura.run()
