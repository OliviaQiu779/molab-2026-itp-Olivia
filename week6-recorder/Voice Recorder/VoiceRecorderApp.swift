//
//  VoiceRecorderApp.swift
//  Voice Recorder
//


import SwiftUI

@main
struct VoiceRecorderApp: App {
    @State var audioRecorder = AudioRecorder()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(audioRecorder)
        }
    }
}
