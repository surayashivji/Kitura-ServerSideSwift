import Foundation
import HeliumLogger
import Kitura
import KituraStencil
import LoggerAPI
import SwiftGD

func image(from request: RouterRequest) -> Image? {
    // decode url for image by removing percents and stuff
    // pull url from request
    guard let imageFilename = request.queryParameters["url"] else { return nil }
    guard let imageDecoded = imageFilename.removingPercentEncoding else { return nil }
    
    // convert user's url from html input into URL object
    
    guard let imageURL = URL(string: imageDecoded) else { return nil }
    
    // we have a valid url! so now download image data from the url into Data object
    // data contents of init - connects to remote server and fetches content
    
    if let imageData = try? Data(contentsOf: imageURL) {
        // save image data to disk in temp location so that swift gd can read it
        // use user's temporary directory
        let temporaryName = NSTemporaryDirectory().appending("input.png")
        let temporaryURL = URL(fileURLWithPath: temporaryName)
        
        _ = try? imageData.write(to: temporaryURL)
        
        // return swift GD image object
        if let image = Image(url: temporaryURL) {
            return image
        }
    }
    return nil
}

HeliumLogger.use() //logging
let router = Router()
router.setDefault(templateEngine: StencilTemplateEngine())

router.get("/") {
    request, response, next in
    defer { next() }
    
    try response.render("home", context: [:])
}

router.get("/fetch") {
    request, response, next in
    defer { next() }
    
    // fetch the image that the user requested!
    guard let image = image(from: request) else { return }
    
    // create array for 10 ascii characters we will be using to draw images
    let asciiBlocks = ["@", "#", "*", "+", ";", ":", ",", ".", "`", " "]
    
    // set image size and block size
    // block size : if its 1, it means 1 pixel to 1 ascii, if its 10 its asci / every 10 pixel
    let imageSize = image.size
    let blockSize = 1 // draws every other character
    
    // 2d string array
    var rows = [[String]]()
    // we may add a ton of rows to it so call reserveCapacity() for performance so we can allocate space upfront
    rows.reserveCapacity(imageSize.height)
    
    
    // ASCII CONVERSTION
    // swift gd has method to get color for a pixel at a specific point
    // loop over height/width of image -> pull out colors -> map them to asciiBlocks value
    
    // loop over image height
    for y in stride(from: 0, to: imageSize.height, by: blockSize) {
        // create new row
        // reserve enough capacity for all pixels!
        var row = [String]()
        row.reserveCapacity(imageSize.width/blockSize)
        
        // loop over heihgt
        for x in stride(from: 0, to: imageSize.width, by: blockSize) {
//            // get pixel @ current location
            let color = image.get(pixel: Point(x: x, y: y))
//            /// figure out brightness of pixel
            let brightness = (color.redComponent * 0.299) +
                            (color.blueComponent * 0.114) +
                            (color.greenComponent * 0.587)
//             multiply by three so that it indexes match to asciiBlocks (0-9) and round
            let sum = Int(round(brightness * 3))
//            // map brightness to an ascii character
            row.append(asciiBlocks[sum])
        }
       
        //append ot result
        rows.append(row)
    }
    
    // convert 2d array into single string separated by line breaks and spaces
    // use reduced() and joined()
    // joined() lets us join together characters in each row
    // reduce() method converts array of items into 1 item - use to build one big string of each row from joined()
    let output = rows.reduce("") { // "" is inital value since $0 wont have anything at first
        $0 + $1.joined(separator: " ") + "\n" // $1 is urrent row neded to be converted to string
    }
    // so $0 - string with all rows converted to ascii so far
    // $1 - current row that needs to be converted to a string
    
    try response.send(output).end()
    
}

Kitura.addHTTPServer(onPort: 8090, with: router)
Kitura.run()
