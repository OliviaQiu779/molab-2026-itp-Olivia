//
//  ContentView.swift
//  week3-Aquarium
//
//  Created by 邱若雨 on 2026/9/18.
//

import SwiftUI

struct Fish {
    var x: Double
    var y: Double
    var size: Double
    var direction: Bool
    var emoji: String
}

struct ContentView: View {
    
    @State private var fish: [Fish] = []
    
    // Array of ocean emojis
    let seaAnimals = [
        "🐟",
        "🐠",
        "🐡",
        "🦈",
        "🐙",
        "🦈",
        "🫍",
        "🐬",
        "🐳",
        "🐋",
        "🪼",
        "🪸",
        "🐚"
    ]
    
    var body: some View {
        VStack {
            
            Text("Welcome to Aquarium")
                .font(.title)
                .bold()
            
            Canvas { context, size in
                
                // Water background
                //Path:The outline of a 2D shape.
                context.fill(
                    Path(CGRect(origin: .zero, size: size)),
                    with: .color(.blue.opacity(0.15))
                )
                
                // Draw all the sea animals
                for animal in fish {
                    
                    let x = animal.x * size.width
                    let y = animal.y * size.height
                    
                    let text = Text(animal.emoji)
                        .font(.system(size: animal.size))
                    
                    context.draw(
                        text,
                        at: CGPoint(x: x, y: y)
                    )
                }
            }
            .clipShape(
                RoundedRectangle(cornerRadius: 20)
            )
            .padding()
            
            Button("Generate New Animals") {
                generateFish()
            }
            .buttonStyle(.borderedProminent)
            .padding(.bottom)
        }
        .onAppear {
            generateFish()
        }
    }
    
    // Generate random sea animals
    func generateFish() {
        
        var newFish: [Fish] = []
        
        //random location and random size
        for _ in 0..<20 {
            let newAnimal = Fish(
                x: Double.random(in: 0.08...0.92),
                y: Double.random(in: 0.10...0.90),
                size: Double.random(in: 25...100),
                direction: Bool.random(),
                emoji: seaAnimals.randomElement()!
            )
            
            newFish.append(newAnimal)
        }
        
        fish = newFish
    }
}

#Preview {
    ContentView()
}
