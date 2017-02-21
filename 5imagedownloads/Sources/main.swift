import Foundation
import HeliumLogger
import Kitura
import KituraStencil
import LoggerAPI
import SwiftGD

HeliumLogger.use()

let router = Router()

router.setDefault(templateEngine: StencilTemplateEngine())
router.post("/", middleware: BodyParser())
router.all("/static", middleware: StaticFileServer())

// the directories we need throughout the app
// root = where uploads folder is (where we will be storing the images)
let rootDirectory = URL(fileURLWithPath: "\(FileManager().currentDirectoryPath)/public/uploads")
Log.info("fiel manager thing for root: \(FileManager().currentDirectoryPath)")
let originalsDirectory = rootDirectory.appendingPathComponent("originals")
let thumbsDirectory = rootDirectory.appendingPathComponent("thumbs")

router.get("/") {
    request, response, next in
    defer { next() }
    
    // 1 get list of all images in the originals directory
    // use FileManager to get Contents of directory - comes back as URLs with paths
    let fileManager = FileManager()
    guard let files: [URL] = try? fileManager.contentsOfDirectory(at: originalsDirectory, includingPropertiesForKeys: nil) else {
        return
    }
    
    // 2 strip out everything but filename (ie /path/uploads/name.png to name.png)
    let fileNamesList: [String] = files.map { $0.lastPathComponent }
    
    // 3 make sure no hidden files shown
    let visibleFiles: [String] = fileNamesList.filter { !$0.hasPrefix(".") } // no hidden files included
    
    // 4 render array of files into stencil context
    try response.render("home", context: ["files": visibleFiles])
}

router.post("/upload") {
    request, response, next in
    
    defer { next() }
    
    // pull out the multi part encoded form data
    guard let values = request.body else { return }
    
    // ensure values is multi part, if so pull it out and put it into parts
    guard case .multipart(let parts) = values else { return }
    
    // array of files we are willing to accept
    let acceptableTypes = ["image/png", "image/jpeg"]
    
    for part in parts {
        // make sure image is valid type
        guard acceptableTypes.contains(part.type) else { continue }
        
        // extract data, move onto next part if it fails
        // ensure party.body contains raw data
        guard case .raw(let data) = part.body else { continue }
        
        // replace spaces in filename
        let cleanedFileName = part.filename.replacingOccurrences(of: " ", with: "-")
        
        
        guard let files: [URL] = try? FileManager().contentsOfDirectory(at: originalsDirectory, includingPropertiesForKeys: nil) else {
            return
        }
        let fileNamesList: [String] = files.map { $0.lastPathComponent }
        if !fileNamesList.contains(cleanedFileName) {
            // convert into URL we can write to
            let originalURL = originalsDirectory.appendingPathComponent(cleanedFileName)
            
            // write full size original image
            _ = try? data.write(to: originalURL)
            
            // create a matching URL in the thumbnails directory
            let thumbURL = thumbsDirectory.appendingPathComponent(cleanedFileName)
            
            // load the original into a SwiftGD image
            if let image = Image(url: originalURL) {
                // attempt to resize  down to a thumbnail
                if let resized = image.resizedTo(width: 300) {
                    // it worked – save it
                    resized.write(to: thumbURL)
                }
            }
        }
        else {
            Log.info("duplicate image upload")
        }
        
        
    }
    // reload the homepage
    
    try response.redirect("/")
}

Kitura.addHTTPServer(onPort: 8090, with: router)
Kitura.run()
