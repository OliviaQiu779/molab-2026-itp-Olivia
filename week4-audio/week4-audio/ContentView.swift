import SwiftUI
import AVFoundation

struct ContentView: View {
    @State private var sleepTime = Date()
    @State private var selectedSound = "🌊"
    @State private var isSet = false
    
    var body: some View {
        NavigationStack {
            if isSet {
                SleepView(
                    sleepTime: sleepTime,
                    selectedSound: selectedSound,
                    onCancel: {
                        isSet = false
                    }
                )
            } else {
                VStack(spacing: 30) {
                    
                    Text("🌙 Sleep Sound")
                        .font(.largeTitle)
                        .bold()
                    
                    Text("When do you want to sleep?")
                        .font(.headline)
                    
                    DatePicker(
                        "Sleep Time",
                        selection: $sleepTime,
                        displayedComponents: .hourAndMinute
                    )
                    .datePickerStyle(.wheel)
                    .labelsHidden()
                    
                    Text("Choose your sound")
                        .font(.headline)
                    
                    HStack(spacing: 25) {
                        
                        Button("🌊") {
                            selectedSound = "🌊"
                        }
                        
                        Button("🌧️") {
                            selectedSound = "🌧️"
                        }
                        
                        Button("🔥") {
                            selectedSound = "🔥"
                        }
                        
                        Button("🌲") {
                            selectedSound = "🌲"
                        }
                    }
                    .font(.system(size: 40))
                    
                    Text("Selected: \(selectedSound)")
                    
                    Button("Set Sleep Time") {
                        isSet = true
                    }
                    .buttonStyle(.borderedProminent)
                }
                .padding()
            }
        }
    }
}


struct SleepView: View {
    let sleepTime: Date
    let selectedSound: String
    let onCancel: () -> Void
    
    @State private var currentTime = Date()
    @State private var hasPlayed = false
    @State private var audioPlayer: AVAudioPlayer?
    
    var body: some View {
        VStack(spacing: 30) {
            
            Text("🌙 Good Night")
                .font(.largeTitle)
                .bold()
            
            Text("Your sound:")
                .font(.headline)
            
            Text(selectedSound)
                .font(.system(size: 70))
            
            Text("Sound will start at")
                .font(.headline)
            
            Text(sleepTime, style: .time)
                .font(.title)
            
            if hasPlayed {
                Text("🔊 Playing...")
                    .font(.title2)
            } else {
                Text("Waiting for bedtime...")
                    .foregroundStyle(.secondary)
            }
            
            Button("Cancel") {
                audioPlayer?.stop()
                onCancel()
            }
            .buttonStyle(.bordered)
        }
        .padding()
        .onAppear {
            startTimer()
        }
    }
    
    func startTimer() {
        Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { timer in
            
            currentTime = Date()
            
            if currentTime >= sleepTime && !hasPlayed {
                playSound()
                hasPlayed = true
                timer.invalidate()
            }
        }
    }
    
    func playSound() {
        
        var soundName = "ocean"
        
        if selectedSound == "🌧️" {
            soundName = "rain"
        } else if selectedSound == "🔥" {
            soundName = "fire"
        } else if selectedSound == "🌲" {
            soundName = "forest"
        }
        
        guard let url = Bundle.main.url(
            forResource: soundName,
            withExtension: "wav"
        ) else {
            print("\(soundName).mp3 not found")
            return
        }
        
        audioPlayer = try? AVAudioPlayer(contentsOf: url)
        audioPlayer?.play()
    }
}


#Preview {
    ContentView()
}
