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
    
    
    ctx.setStrokeColor(black.cgColor)
    ctx.setLineWidth(8)
    
    ctx.addEllipse(
        in: CGRect(
            x: 650,
            y: 520,
            width: 190,
            height: 190
        )
    )
    ctx.strokePath()
    
    ctx.setStrokeColor(blue.cgColor)
    ctx.setLineWidth(12)
    
    ctx.addEllipse(
        in: CGRect(
            x: 690,
            y: 560,
            width: 110,
            height: 110
        )
    )
    ctx.strokePath()
    
    
    ctx.setStrokeColor(black.cgColor)
    ctx.setLineCap(.round)
    
    // thick diagonal line
    ctx.setLineWidth(14)
    ctx.move(to: CGPoint(x: 50, y: 650))
    ctx.addLine(to: CGPoint(x: 360, y: 500))
    ctx.strokePath()
    
    // another diagonal line
    ctx.setLineWidth(7)
    ctx.move(to: CGPoint(x: 300, y: 100))
    ctx.addLine(to: CGPoint(x: 580, y: 400))
    ctx.strokePath()
    
    // vertical line
    ctx.setLineWidth(9)
    ctx.move(to: CGPoint(x: 520, y: 80))
    ctx.addLine(to: CGPoint(x: 520, y: 570))
    ctx.strokePath()
    
    // thin diagonal line
    ctx.setLineWidth(4)
    ctx.move(to: CGPoint(x: 700, y: 80))
    ctx.addLine(to: CGPoint(x: 930, y: 330))
    ctx.strokePath()
    
    
    let dotPositions = [
        CGPoint(x: 440, y: 180),
        CGPoint(x: 480, y: 220),
        CGPoint(x: 560, y: 150),
        CGPoint(x: 760, y: 450),
        CGPoint(x: 870, y: 600),
        CGPoint(x: 350, y: 760),
        CGPoint(x: 180, y: 540),
        CGPoint(x: 900, y: 820)
    ]
    
    ctx.setFillColor(black.cgColor)
    
    for point in dotPositions {
        let radius = CGFloat.random(in: 6...14)
        
        ctx.addEllipse(
            in: CGRect(
                x: point.x - radius,
                y: point.y - radius,
                width: radius * 2,
                height: radius * 2
            )
        )
        
        ctx.drawPath(using: .fill)
    }
    
    
    let smallCircles = [
        (CGPoint(x: 420, y: 330), CGFloat(35), red),
        (CGPoint(x: 580, y: 300), CGFloat(25), yellow),
        (CGPoint(x: 760, y: 370), CGFloat(45), blue),
        (CGPoint(x: 330, y: 580), CGFloat(30), yellow),
        (CGPoint(x: 830, y: 150), CGFloat(28), red),
        (CGPoint(x: 170, y: 800), CGFloat(45), blue)
    ]
    
    for circle in smallCircles {
        let point = circle.0
        let radius = circle.1
        let color = circle.2
        
        ctx.setFillColor(color.cgColor)
        
        ctx.addEllipse(
            in: CGRect(
                x: point.x - radius,
                y: point.y - radius,
                width: radius * 2,
                height: radius * 2
            )
        )
        
        ctx.drawPath(using: .fill)
    }
    
    
    // black arc
    ctx.setStrokeColor(black.cgColor)
    ctx.setLineWidth(10)
    
    ctx.addArc(
        center: CGPoint(x: 850, y: 760),
        radius: 100,
        startAngle: 0,
        endAngle: .pi,
        clockwise: false
    )
    
    ctx.strokePath()
    
    
    // blue arc
    ctx.setStrokeColor(blue.cgColor)
    ctx.setLineWidth(14)
    
    ctx.addArc(
        center: CGPoint(x: 300, y: 880),
        radius: 90,
        startAngle: .pi,
        endAngle: .pi * 1.5,
        clockwise: false
    )
    
    ctx.strokePath()
    
    
    // Instead of many random rectangles,
    // use only a few deliberate geometric shapes.
    
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
    
    
    for _ in 0..<4 {
        let radius = CGFloat.random(in: 20...45)
        let x = CGFloat.random(
            in: radius...(CGFloat(dim) - radius)
        )
        let y = CGFloat.random(
            in: radius...(CGFloat(dim) - radius)
        )
        
        ctx.setStrokeColor(black.cgColor)
        ctx.setLineWidth(5)
        
        ctx.addEllipse(
            in: CGRect(
                x: x - radius,
                y: y - radius,
                width: radius * 2,
                height: radius * 2
            )
        )
        
        ctx.strokePath()
    }
}


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
