import UIKit

// canvas
let dim = 1024.0

let renderer = UIGraphicsImageRenderer(
    size: CGSize(width: dim, height: dim)
)

// create image
let image = renderer.image { context in
    let ctx = context.cgContext
    let box = renderer.format.bounds
    
    // white background
    UIColor.white.setFill()
    context.fill(box)
    
    // Kandinsky color palette
    let red = UIColor(red: 0.85, green: 0.08, blue: 0.08, alpha: 1)
    let blue = UIColor(red: 0.05, green: 0.20, blue: 0.85, alpha: 1)
    let yellow = UIColor(red: 1.0, green: 0.78, blue: 0.05, alpha: 1)
    let black = UIColor.black
    
    
    // large blue circle
    ctx.setFillColor(blue.cgColor)
    ctx.addEllipse(
        in: CGRect(
            x: 90,
            y: 120,
            width: 300,
            height: 300
        )
    )
    ctx.drawPath(using: .fill)
    
    // large red circle
    ctx.setFillColor(red.cgColor)
    ctx.addEllipse(
        in: CGRect(
            x: 620,
            y: 180,
            width: 220,
            height: 220
        )
    )
    ctx.drawPath(using: .fill)
    
    // large yellow circle
    ctx.setFillColor(yellow.cgColor)
    ctx.addEllipse(
        in: CGRect(
            x: 420,
            y: 650,
            width: 260,
            height: 260
        )
    )
    ctx.drawPath(using: .fill)
    
    
    // black outer circle
    ctx.setStrokeColor(black.cgColor)
    ctx.setLineWidth(10)
    ctx.addEllipse(
        in: CGRect(
            x: 130,
            y: 160,
            width: 220,
            height: 220
        )
    )
    ctx.strokePath()
    
    // red inner circle
    ctx.setFillColor(red.cgColor)
    ctx.addEllipse(
        in: CGRect(
            x: 185,
            y: 215,
            width: 110,
            height: 110
        )
    )
    ctx.drawPath(using: .fill)
    
    // small black circle inside
    ctx.setFillColor(black.cgColor)
    ctx.addEllipse(
        in: CGRect(
            x: 225,
            y: 255,
            width: 30,
            height: 30
        )
    )
    ctx.drawPath(using: .fill)
    
   
    // diagonal line 1
    ctx.setLineWidth(10)
    ctx.move(to: CGPoint(x: 50, y: 650))
    ctx.addLine(to: CGPoint(x: 360, y: 500))
    ctx.strokePath()
    
    //diagonal line 2
    ctx.setLineWidth(7)
    ctx.move(to: CGPoint(x: 300, y: 100))
    ctx.addLine(to: CGPoint(x: 580, y: 400))
    ctx.strokePath()
    
    // vertical line
    ctx.setLineWidth(9)
    ctx.move(to: CGPoint(x: 520, y: 80))
    ctx.addLine(to: CGPoint(x: 520, y: 570))
    ctx.strokePath()
    
    
    let smallCircles = [
        (CGPoint(x: 420, y: 330), CGFloat(35), red),
        (CGPoint(x: 580, y: 300), CGFloat(25), yellow),
        (CGPoint(x: 760, y: 370), CGFloat(45), blue),
        (CGPoint(x: 330, y: 580), CGFloat(30), yellow),
        (CGPoint(x: 830, y: 150), CGFloat(28), red),
        (CGPoint(x: 170, y: 800), CGFloat(45), blue)
    ]
    
    // rectangles
    
    ctx.setFillColor(yellow.cgColor)
    ctx.fill(
        CGRect(
            x: 80,
            y: 450,
            width: 100,
            height: 45
        )
    )
    
    ctx.setFillColor(red.cgColor)
    ctx.fill(
        CGRect(
            x: 760,
            y: 850,
            width: 120,
            height: 45
        )
    )
    
    ctx.setFillColor(blue.cgColor)
    ctx.fill(
        CGRect(
            x: 450,
            y: 480,
            width: 55,
            height: 130
        )
    )
    
    
    let data = image.pngData()
    
    let folder = FileManager.default.urls(
        for: .documentDirectory,
        in: .userDomainMask
    ).first!
    
    let filePath = folder.appendingPathComponent(
        "kandinsky2026-09.png"
    )
    
    do {
        try data?.write(to: filePath)
        
        print("Image saved!")
        print("filePath: \(filePath)")
        
        // Terminal command to copy to Downloads
        print("cp \(filePath.path) ~/Downloads/.")
        
    } catch {
        print("Error: \(error)")
    }
}
