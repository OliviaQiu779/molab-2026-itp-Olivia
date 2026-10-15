//
//  ContentView.swift
//  Voice Recorder
//
//  Created by 邱若雨 on 2026/10/12.
//  Copyright © 2026 Pinlun. All rights reserved.
//

import SwiftUI
import AVFoundation
import Combine

//Audio Emoji Model

struct AudioEmoji: Identifiable, Codable, Equatable {
    var id: UUID = UUID()
    var emoji: String
    var name: String
    var fileName: String
}

// Built-in Sound Model

struct BuiltInSound: Identifiable {
    let id: String
    let emoji: String
    let name: String
    let resource: String
}

// Home Page

struct ContentView: View {
    @State private var audioRecorder = AudioRecorder()
    @State private var sleepTime = Date()
    @State private var selectedSoundID = "builtin-ocean"
    @State private var customSounds: [AudioEmoji] = []
    @State private var showRecorder = false
    @State private var soundToDelete: AudioEmoji?
    @State private var showDeleteConfirmation = false
    @State private var errorMessage = ""
    @State private var showError = false

    private let builtInSounds: [BuiltInSound] = [
        BuiltInSound(
            id: "builtin-ocean",
            emoji: "🌊",
            name: "Ocean",
            resource: "ocean"
        ),
        BuiltInSound(
            id: "builtin-rain",
            emoji: "🌧️",
            name: "Rain",
            resource: "rain"
        ),
        BuiltInSound(
            id: "builtin-fire",
            emoji: "🔥",
            name: "Fire",
            resource: "fire"
        ),
        BuiltInSound(
            id: "builtin-forest",
            emoji: "🌲",
            name: "Forest",
            resource: "forest"
        )
    ]

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Text("🌙 Sleep Sound")
                    .font(.largeTitle.bold())

                VStack(spacing: 8) {
                    Text("When do you want to sleep?")
                        .font(.headline)

                    DatePicker(
                        "Sleep Time",
                        selection: $sleepTime,
                        displayedComponents: .hourAndMinute
                    )
                    .datePickerStyle(.wheel)
                    .labelsHidden()
                }

                Text("Choose your sound")
                    .font(.headline)

                LazyVGrid(
                    columns: Array(
                        repeating: GridItem(.flexible()),
                        count: 3
                    ),
                    spacing: 14
                ) {
                    ForEach(builtInSounds) { sound in
                        soundTile(
                            id: sound.id,
                            emoji: sound.emoji,
                            name: sound.name
                        )
                    }

                    ForEach(customSounds) { sound in
                        soundTile(
                            id: sound.id.uuidString,
                            emoji: sound.emoji,
                            name: sound.name,
                            onDelete: {
                                soundToDelete = sound
                                showDeleteConfirmation = true
                            }
                        )
                    }

                    Button {
                        showRecorder = true
                    } label: {
                        VStack(spacing: 8) {
                            Image(systemName: "mic.circle.fill")
                                .font(.system(size: 38))
                                .foregroundStyle(.red)

                            Text("Record")
                                .font(.caption.weight(.medium))
                        }
                        .frame(maxWidth: .infinity, minHeight: 92)
                        .background(
                            Color.gray.opacity(0.10),
                            in: RoundedRectangle(cornerRadius: 16)
                        )
                    }
                    .buttonStyle(.plain)
                }

                NavigationLink {
                    SleepView(
                        sleepTime: sleepTime,
                        selectedSoundID: selectedSoundID,
                        builtInSounds: builtInSounds,
                        customSounds: customSounds
                    )
                } label: {
                    Text("Set Sleep Time")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                }
                .buttonStyle(.borderedProminent)

                Spacer(minLength: 0)
            }
            .padding()
            .navigationDestination(isPresented: $showRecorder) {
                RecorderPage { emoji, name, sourceURL in
                    saveCustomSound(
                        emoji: emoji,
                        name: name,
                        sourceURL: sourceURL
                    )
                }
            }
            .onAppear {
                loadCustomSounds()
            }
            .alert("Something went wrong", isPresented: $showError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(errorMessage)
            }
            .confirmationDialog(
                "Delete this custom sound?",
                isPresented: $showDeleteConfirmation,
                titleVisibility: .visible
            ) {
                Button("Delete Sound", role: .destructive) {
                    if let sound = soundToDelete {
                        deleteCustomSound(sound)
                    }
                    soundToDelete = nil
                }
                Button("Cancel", role: .cancel) {
                    soundToDelete = nil
                }
            } message: {
                Text("This will delete the recording and its saved details.")
            }
        }
        .environment(audioRecorder)
    }

    private func soundTile(
        id: String,
        emoji: String,
        name: String,
        onDelete: (() -> Void)? = nil
    ) -> some View {
        let isSelected = selectedSoundID == id

        return ZStack(alignment: .topTrailing) {
            Button {
                selectedSoundID = id
            } label: {
                VStack(spacing: 8) {
                    Text(emoji)
                        .font(.system(size: 38))

                    Text(name)
                        .font(.caption.weight(.medium))
                        .lineLimit(1)
                }
                .frame(maxWidth: .infinity, minHeight: 92)
                .background(
                    isSelected
                        ? Color.blue.opacity(0.14)
                        : Color.gray.opacity(0.10),
                    in: RoundedRectangle(cornerRadius: 16)
                )
                .overlay {
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(
                            isSelected ? Color.blue : Color.clear,
                            lineWidth: 2
                        )
                }
            }
            .buttonStyle(.plain)

            // This delete button appears only on custom sound tiles.
            if let onDelete {
                Button(action: onDelete) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 20))
                        .symbolRenderingMode(.palette)
                        .foregroundStyle(.white, .red)
                        .padding(5)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Delete \(name)")
            }
        }
    }

    private var selectedSoundDescription: (emoji: String, name: String)? {
        if let sound = builtInSounds.first(where: {
            $0.id == selectedSoundID
        }) {
            return (sound.emoji, sound.name)
        }

        if let sound = customSounds.first(where: {
            $0.id.uuidString == selectedSoundID
        }) {
            return (sound.emoji, sound.name)
        }

        return nil
    }


    private var metadataURL: URL {
        FileManager.default
            .urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("customAudioEmojis.json")
    }

    private func loadCustomSounds() {
        guard FileManager.default.fileExists(
            atPath: metadataURL.path
        ) else {
            return
        }

        do {
            let data = try Data(contentsOf: metadataURL)
            customSounds = try JSONDecoder().decode(
                [AudioEmoji].self,
                from: data
            )
        } catch {
            errorMessage =
                "Could not load saved sounds: \(error.localizedDescription)"
            showError = true
        }
    }

    private func saveCustomSound(
        emoji: String,
        name: String,
        sourceURL: URL
    ) {
        do {
            let fileName = "custom-\(UUID().uuidString).m4a"

            let destinationURL = FileManager.default
                .urls(for: .documentDirectory, in: .userDomainMask)[0]
                .appendingPathComponent(fileName)

            try FileManager.default.copyItem(
                at: sourceURL,
                to: destinationURL
            )

            let newSound = AudioEmoji(
                emoji: emoji,
                name: name,
                fileName: fileName
            )

            let updatedSounds = [newSound] + customSounds
            let data = try JSONEncoder().encode(updatedSounds)

            try data.write(to: metadataURL, options: .atomic)

            customSounds = updatedSounds
            selectedSoundID = newSound.id.uuidString
        } catch {
            errorMessage =
                "Could not save your recording: \(error.localizedDescription)"
            showError = true
        }
    }

    private func deleteCustomSound(_ sound: AudioEmoji) {
        do {
            let documentsURL = FileManager.default
                .urls(for: .documentDirectory, in: .userDomainMask)[0]
            let audioURL = documentsURL.appendingPathComponent(sound.fileName)

            // Delete the actual audio file if it still exists.
            if FileManager.default.fileExists(atPath: audioURL.path) {
                try FileManager.default.removeItem(at: audioURL)
            }

            // Remove only this sound's metadata and keep other custom sounds.
            let updatedSounds = customSounds.filter { $0.id != sound.id }
            let data = try JSONEncoder().encode(updatedSounds)
            try data.write(to: metadataURL, options: .atomic)

            customSounds = updatedSounds

            // If the deleted sound was selected, switch back to Ocean.
            if selectedSoundID == sound.id.uuidString {
                selectedSoundID = "builtin-ocean"
            }
        } catch {
            errorMessage =
                "Could not delete the recording: \(error.localizedDescription)"
            showError = true
        }
    }

}

// Recording Page

struct RecorderPage: View {
    let onSave: (String, String, URL) -> Void

    @Environment(AudioRecorder.self) private var audioRecorder
    @Environment(\.dismiss) private var dismiss

    @State private var isChoosingEmoji = false
    @State private var recordingURL: URL?
    @State private var selectedEmoji = "🎵"
    @State private var soundName = "My Sound"
    @State private var errorMessage = ""
    @State private var showError = false

    private let fixedEmojis = [
        "🎵", "🐱", "🌙", "🌿",
        "🐦", "💧", "✨", "🐻",
        "🌸", "☁️", "🦋", "⭐"
    ]

    var body: some View {
        VStack(spacing: 24) {
            if !isChoosingEmoji {
                Spacer()

                Text("🎙️")
                    .font(.system(size: 76))

                Text(
                    audioRecorder.recording
                        ? "Recording…"
                        : "Record Your Sound"
                )
                .font(.title2.bold())

                Button {
                    if audioRecorder.recording {
                        finishRecording()
                    } else {
                        audioRecorder.startRecording()
                    }
                } label: {
                    Image(
                        systemName: audioRecorder.recording
                            ? "stop.circle.fill"
                            : "record.circle"
                    )
                    .font(.system(size: 82))
                    .foregroundStyle(.red)
                    .frame(width: 110, height: 110)
                }
                .buttonStyle(.plain)

                Text(
                    audioRecorder.recording
                        ? "Stop Recording"
                        : "Start Recording"
                )
                .font(.headline)

                Spacer()
            } else {
                Text("Choose an Emoji")
                    .font(.title2.bold())

                LazyVGrid(
                    columns: Array(
                        repeating: GridItem(.flexible()),
                        count: 4
                    ),
                    spacing: 14
                ) {
                    ForEach(fixedEmojis, id: \.self) { emoji in
                        Button {
                            selectedEmoji = emoji
                        } label: {
                            Text(emoji)
                                .font(.system(size: 34))
                                .frame(
                                    maxWidth: .infinity,
                                    minHeight: 62
                                )
                                .background(
                                    selectedEmoji == emoji
                                        ? Color.blue.opacity(0.16)
                                        : Color.gray.opacity(0.10),
                                    in: RoundedRectangle(cornerRadius: 12)
                                )
                                .overlay {
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(
                                            selectedEmoji == emoji
                                                ? Color.blue
                                                : Color.clear,
                                            lineWidth: 2
                                        )
                                }
                        }
                        .buttonStyle(.plain)
                    }
                }

                TextField("Sound name", text: $soundName)
                    .textFieldStyle(.roundedBorder)

                Button("Save Audio Emoji") {
                    guard let recordingURL else {
                        errorMessage = "No recording file was found."
                        showError = true
                        return
                    }

                    let trimmedName = soundName.trimmingCharacters(
                        in: .whitespacesAndNewlines
                    )

                    onSave(
                        selectedEmoji,
                        trimmedName.isEmpty ? "My Sound" : trimmedName,
                        recordingURL
                    )

                    dismiss()
                }
                .buttonStyle(.borderedProminent)

                Button("Discard Recording", role: .destructive) {
                    if let recordingURL {
                        audioRecorder.deleteRecording(
                            urlsToDelete: [recordingURL]
                        )
                    }
                    dismiss()
                }
            }
        }
        .padding(28)
        .navigationTitle("Voice Recorder")
        .navigationBarTitleDisplayMode(.inline)
        .alert("Recording Error", isPresented: $showError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(errorMessage)
        }
        .onDisappear {
            if audioRecorder.recording {
                audioRecorder.stopRecording()
            }
        }
    }

    private func finishRecording() {
        guard let url = audioRecorder.audioRecorder?.url else {
            errorMessage = "Could not find the recording file."
            showError = true
            return
        }

        audioRecorder.stopRecording()
        recordingURL = url
        isChoosingEmoji = true
    }
}

// Sleep / Audio Playback Page

struct SleepView: View {
    let sleepTime: Date
    let selectedSoundID: String
    let builtInSounds: [BuiltInSound]
    let customSounds: [AudioEmoji]

    @State private var audioPlayer: AVAudioPlayer?
    @State private var playbackStatus = "Preparing audio..."
    @State private var playbackError = ""
    @State private var showPlaybackError = false
    @State private var hasAttemptedPlayback = false

    private var selectedDescription: (emoji: String, name: String) {
        if let sound = builtInSounds.first(where: {
            $0.id == selectedSoundID
        }) {
            return (sound.emoji, sound.name)
        }

        if let sound = customSounds.first(where: {
            $0.id.uuidString == selectedSoundID
        }) {
            return (sound.emoji, sound.name)
        }

        return ("🌊", "Ocean")
    }

    var body: some View {
        VStack(spacing: 28) {
            Text("🌙 Good Night")
                .font(.largeTitle.bold())

            Text(selectedDescription.emoji)
                .font(.system(size: 76))

            Text(selectedDescription.name)
                .font(.title2.bold())

            Text("Your selected sleep time")
                .font(.headline)

            Text(sleepTime, style: .time)
                .font(.title)

            Text(playbackStatus)
                .font(.headline)
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            Button {
                // Allow the user to retry playback manually.
                playSelectedSound()
            } label: {
                Label("Play Sound Now", systemImage: "play.fill")
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
            }
            .buttonStyle(.borderedProminent)

            Button(role: .destructive) {
                audioPlayer?.stop()
                audioPlayer = nil
                playbackStatus = "Playback stopped."
            } label: {
                Label("Stop Sound", systemImage: "stop.fill")
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
            }

            Spacer()
        }
        .padding()
        .onAppear {
            // No bedtime timer: attempt playback immediately.
            guard !hasAttemptedPlayback else { return }
            hasAttemptedPlayback = true
            playSelectedSound()
        }
        .onDisappear {
            audioPlayer?.stop()
            audioPlayer = nil
        }
        .alert("Audio Playback Error", isPresented: $showPlaybackError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(playbackError)
        }
    }

    private func playSelectedSound() {
        do {
            // Stop any previous player before starting a new one.
            audioPlayer?.stop()
            audioPlayer = nil

            let session = AVAudioSession.sharedInstance()
            try session.setCategory(
                .playback,
                mode: .default,
                options: []
            )
            try session.setActive(true)

            let soundURL: URL

            if let builtIn = builtInSounds.first(where: {
                $0.id == selectedSoundID
            }) {
                guard let url = Bundle.main.url(
                    forResource: builtIn.resource,
                    withExtension: "wav"
                ) else {
                    throw NSError(
                        domain: "SleepSound",
                        code: 1,
                        userInfo: [
                            NSLocalizedDescriptionKey:
                                "Missing file: \(builtIn.resource).wav. In Xcode, select this audio file and check Target Membership for your app."
                        ]
                    )
                }

                soundURL = url
            } else if let custom = customSounds.first(where: {
                $0.id.uuidString == selectedSoundID
            }) {
                let documentsURL = FileManager.default
                    .urls(
                        for: .documentDirectory,
                        in: .userDomainMask
                    )[0]

                let url = documentsURL
                    .appendingPathComponent(custom.fileName)

                guard FileManager.default.fileExists(
                    atPath: url.path
                ) else {
                    throw NSError(
                        domain: "SleepSound",
                        code: 2,
                        userInfo: [
                            NSLocalizedDescriptionKey:
                                "The saved recording does not exist at \(url.lastPathComponent). Please record it again."
                        ]
                    )
                }

                soundURL = url
            } else {
                throw NSError(
                    domain: "SleepSound",
                    code: 3,
                    userInfo: [
                        NSLocalizedDescriptionKey:
                            "No valid sound is selected. Return to the home page and choose a sound."
                    ]
                )
            }

            let player = try AVAudioPlayer(contentsOf: soundURL)
            player.numberOfLoops = -1

            guard player.prepareToPlay() else {
                throw NSError(
                    domain: "SleepSound",
                    code: 4,
                    userInfo: [
                        NSLocalizedDescriptionKey:
                            "The audio file was found, but the player could not prepare it."
                    ]
                )
            }

            guard player.play() else {
                throw NSError(
                    domain: "SleepSound",
                    code: 5,
                    userInfo: [
                        NSLocalizedDescriptionKey:
                            "The audio player could not start playback."
                    ]
                )
            }

            // Keep a strong reference to the player.
            audioPlayer = player
            playbackStatus = "Playing sound..."

        } catch {
            playbackStatus = "Could not play audio."
            playbackError = error.localizedDescription
            showPlaybackError = true
        }
    }
}

#Preview {
    ContentView()
}
