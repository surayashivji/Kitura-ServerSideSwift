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

HeliumLogger.use()

let router = Router()
router.setDefault(
