import SwiftUI
import AVFoundation
import Combine

struct ContentView: View {

    @State private var sleepTime = Date()

    @State private var selectedSound = "🌊"

    // Duration
    @State private var playDuration = 30

    var body: some View {

        NavigationStack {

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


                // Sound Selection

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
                    .foregroundStyle(.secondary)


                // Duration

                Text("How long should it play?")
                    .font(.headline)

               // Stepper: A control that performs increment and decrement actions.
                Stepper(
                    formatDuration(playDuration),
                    value: $playDuration,
                    in: 30...7200,
                    step: 30
                )
                .padding(.horizontal, 40)


                // Set Sleep Time Button

                NavigationLink {

                    SleepView(
                        sleepTime: sleepTime,
                        selectedSound: selectedSound,
                        playDuration: playDuration
                    )

                } label: {

                    Text("Set Sleep Time")
                }
                .buttonStyle(.borderedProminent)

            }
            .padding()
        }
    }


    // Format Duration

    func formatDuration(_ seconds: Int) -> String {

        let minutes = seconds / 60
        let seconds = seconds % 60

        return String(
            format: "%02d:%02d",
            minutes,
            seconds
        )
    }
}


// SleepView

struct SleepView: View {

    let sleepTime: Date

    let selectedSound: String

    let playDuration: Int

    @State private var currentTime = Date()

    @State private var timeRemaining: Int

    @State private var audioPlayer: AVAudioPlayer?


    // Timer updates every second

    let timer = Timer.publish(
        every: 1,
        on: .main,
        in: .common
    )
    .autoconnect()


    // Initialize

    init(
        sleepTime: Date,
        selectedSound: String,
        playDuration: Int
    ) {

        self.sleepTime = sleepTime

        self.selectedSound = selectedSound

        self.playDuration = playDuration

        _timeRemaining = State(
            initialValue: playDuration
        )
    }


    //Body

    var body: some View {

        VStack(spacing: 30) {

            Text("🌙 Good Night")
                .font(.largeTitle)
                .bold()


            Text("Your sound:")
                .font(.headline)

            Text(selectedSound)
                .font(.system(size: 70))


            // Waiting for selected time

            if currentTime < sleepTime {

                Text("Waiting for bedtime...")
                    .foregroundStyle(.secondary)

                Text("Sound will start at")
                    .font(.headline)

                Text(sleepTime, style: .time)
                    .font(.title)

            }


            // Sound is playing

            else if timeRemaining > 0 {

                Text("🔊 Playing...")
                    .font(.title2)

                Text(formatDuration(timeRemaining))
                    .font(.system(size: 70))
                    .monospacedDigit()

                Text("Time remaining")
                    .foregroundStyle(.secondary)

            }


            // Finished

            else {

                Text("🌙 Good Night")
                    .font(.title2)

                Text("Sound finished")
                    .foregroundStyle(.secondary)
            }


            // Stop Button

            Button("Stop") {

                audioPlayer?.stop()

            }
            .buttonStyle(.bordered)

        }
        .padding()


        // Timer

        .onReceive(timer) { _ in

            currentTime = Date()


            // Wait until selected time

            if currentTime >= sleepTime {

                // Start sound only once

                if audioPlayer == nil && timeRemaining > 0 {

                    playSound()
                }


                // Countdown

                if timeRemaining > 0 {

                    timeRemaining -= 1
                }


                // Stop sound when countdown reaches zero

                if timeRemaining == 0 {

                    audioPlayer?.stop()

                    audioPlayer = nil
                }
            }
        }


        // Stop audio when leaving page

        .onDisappear {

            audioPlayer?.stop()
        }
    }


    // Play Sound

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

            print("\(soundName).wav not found")

            return
        }


        audioPlayer = try? AVAudioPlayer(
            contentsOf: url
        )


        // Loop continuously

        audioPlayer?.numberOfLoops = -1

        audioPlayer?.play()
    }


    // Format Duration

    func formatDuration(_ seconds: Int) -> String {

        let minutes = seconds / 60

        let seconds = seconds % 60

        return String(
            format: "%02d:%02d",
            minutes,
            seconds
        )
    }
}


// Preview

#Preview {

    ContentView()
}
