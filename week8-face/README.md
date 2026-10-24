# BlinkBlur

A SwiftUI iOS app that uses ARKit face blend shapes to detect a complete two-eye blink and add Core Image Gaussian blur to the front-camera preview. Each complete blink adds a layer of Gaussian blur. Blur strength fades continuously; blur fades at about 2 layers per second (one layer every 0.5 seconds), with a seven-layer cap.

## Requirements

- Xcode with the iOS SDK
- An iPhone or iPad with a TrueDepth front camera and AR face-tracking support (the simulator cannot provide this camera)

Open `BlinkBlur.xcodeproj`, select an eligible device, and run. Camera access is requested on first launch.
