# Server Side Swift
**ACAD 490 Research:** projects completed while researching using Swift on the server.

## Projects
1. Starter Site
	* **Description:** simple site that has dummy pages for the home, contact, and staff
	* **Outcomes:** setting up the server, integrating Kitura with project, using the swift package manager, templating in Swift, logging
	* **[Code](https://github.com/surayashivji/KituraProgress/tree/master/1basicsite)**
2. VotingAPI
	* **Description:** system that allows users to make topics to vote on and cast their own votes.
	* **Outcomes:** building an API with Swift, learning to use CouchDB, understanding the concepts behind many typical Swift features, interfacing API from front end, techniques for blocking SQL injection / dealing with URL encoding
	* **[Code](https://github.com/surayashivji/KituraProgress/tree/master/2votingapi)**
3. Routing Practice
	* **Description:** going deeper into Kitura's router capabilities
	* **Outcomes:** route chaining (variadic approach), route chaining (multiple HTTP methods route() approach), different ways to read user data (url params with get, url encoded form with post, url encoded with get, json with post), routing regular expressions
	* **[Code](https://github.com/surayashivji/KituraProgress/tree/master/3routing)**
4. Forum
	* **Description:** Forum where people can signup/login and reply to forums with posts / subsequent replies. 
	* **Outcomes:** querying couchdb, integrating javascript views with Swift, custom stencil filters, user credentials, sessions, encryption (hashing, salting, rounds)
	* **[Code](https://github.com/surayashivji/KituraProgress/tree/master/4forum)**
5. Name
	* **Description:** 
	* **Outcomes:** 
	* **[Code](https://github.com/surayashivji/KituraProgress/tree/master/5)**

## Credits
* [Kitura](https://github.com/IBM-Swift/Kitura) - IBM's Swift web framework and HTTP server.
* [Helium Logger](https://github.com/IBM-Swift/HeliumLogger) - lightweight logging framework for Swift.
* [Stencil](https://github.com/IBM-Swift/Kitura-StencilTemplateEngine) - templating language for Swift.
* [CouchDB](https://github.com/IBM-Swift/Kitura-CouchDB) - NoSQL database
* [Bootstrap](http://getbootstrap.com/) - CSS
* [Kitura-Sessions](https://github.com/IBM-Swift/Kitura-Session) - Track user sessions