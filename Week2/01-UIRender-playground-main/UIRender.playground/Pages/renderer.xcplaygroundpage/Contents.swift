
// Drawing system images and text

import UIKit

let dim = 1024.0

let renderer = UIGraphicsImageRenderer(size: CGSize(width: dim*3, height: dim))

var image = renderer.image { (context) in
    
    UIColor.darkGray.setStroke()
    let rt = renderer.format.bounds
    context.stroke(rt)
    
    let gray = 0.8
    UIColor(red: gray, green: gray, blue:gray, alpha: 1.0).setFill();
    context.fill(rt)
    
    let x = rt.width * 0.05
    let y = 0.0
        
    let font = UIFont.systemFont(ofSize: rt.height * 0.8)
    
    let string = NSAttributedString(string: "👨🏿", attributes: [.font: font ])
    string.draw(at: CGPoint(x: x, y: y))
    
    let x1 = x + rt.width * 0.6
    let str2 = NSAttributedString(string: "👩🏾", attributes: [.font: font])
    str2.draw(at: CGPoint(x: x1, y: y))
    
    let psign = UIImage(systemName: "peacesign")!
    // let psign = psign.withTintColor(.init(red: 1.0, green: 1.0, blue: 0.0, alpha: 1.0))
    let x2 = rt.width * 0.2
    let imgTint = psign.withTintColor(.yellow)
    imgTint.draw(in: CGRect(x: x2, y: 0, width: rt.height, height: rt.height));
    
    let sp = rt.width * 0.1
    let p2 = psign.withTintColor(.red)
    p2.draw(in: CGRect(x: x2 + sp, y: 0, width: rt.height, height: rt.height))
    
    let p3 = psign.withTintColor(UIColor(red: 0, green: 1.0, blue: 0, alpha: 0.5))
    p3.draw(in: CGRect(x: x2 + sp*2, y: 0, width: rt.height, height: rt.height))

}

image
