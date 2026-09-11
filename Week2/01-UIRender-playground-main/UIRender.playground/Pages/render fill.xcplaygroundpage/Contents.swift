
// drawing colored shapes using UIGraphicsImageRenderer
// https://developer.apple.com/documentation/uikit/uigraphicsimagerenderer
// https://developer.apple.com/documentation/uikit/uigraphicsrenderercontext

import UIKit

let sz = CGSize(width: 200, height: 100)
let renderer = UIGraphicsImageRenderer(size: sz)

let image = renderer.image { context in
    
    UIColor.red.setFill()
    context.fill(CGRect(x: 0, y: 0, width: 50, height: 50))
    UIColor.green.setFill()
    context.fill(CGRect(x: 50, y: 0, width: 50, height: 50))
    UIColor.yellow.setFill()
    context.fill(CGRect(x: 100, y: 0, width: 50, height: 50))
    UIColor.black.setFill()
    context.fill(CGRect(x: 150, y: 0, width: 50, height: 50))

    UIColor.darkGray.setStroke()
    context.stroke(renderer.format.bounds)
    
    var box = renderer.format.bounds
    for _ in 1...4 {
        box = box.insetBy(dx: 4, dy: 4)
        context.stroke(box)
    }
    // UIColor(red: 158/255, green: 215/255, blue: 245/255, alpha: 1).setFill()
}

image

