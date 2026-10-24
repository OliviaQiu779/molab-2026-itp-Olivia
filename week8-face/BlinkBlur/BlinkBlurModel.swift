//Core Image CIFilter Source: https://developer.apple.com/documentation/coreimage/cifilter-swift.class
//Codex Prompt: Use ARKit to detect blinks and Core Image’s CIGaussianBlur filter to blur the live camera feed. Each blink increases the blur intensity, up to a maximum radius of 35. Count each blink only once, and allow a new blink after the eyes reopen. When the user stops blinking, gradually reduce the blur by one level every 0.5 seconds until the image is clear.

import ARKit
import CoreImage
import CoreImage.CIFilterBuiltins
import SwiftUI

@MainActor
final class BlinkBlurModel: ObservableObject {
    @Published private(set) var image: CGImage?
    @Published private(set) var faceDetected = false
    @Published private(set) var blinkCount = 0
    @Published private(set) var isSupported = ARFaceTrackingConfiguration.isSupported
    @Published private(set) var cameraError: String?

    private(set) var blurLayers: CGFloat = 0
    private var eyesWereClosed = false
    private var lastFrameSubmitted: TimeInterval = 0
    private var lastDecayTime = Date()
    private let maximumLayers: CGFloat = 7
    private let secondsPerLayer: CGFloat = 0.5
    private let renderQueue = DispatchQueue(label: "app.blinkblur.render", qos: .userInitiated)
    private let context = CIContext(options: [.cacheIntermediates: false])

    var blurRadius: CGFloat { min(blurLayers * 5, 35) }

    func update(blendShapes: [ARFaceAnchor.BlendShapeLocation: NSNumber]) {
        faceDetected = true
        decayBlur()

        let left = blendShapes[.eyeBlinkLeft]?.floatValue ?? 0
        let right = blendShapes[.eyeBlinkRight]?.floatValue ?? 0
        let bothClosed = left > 0.68 && right > 0.68
        let bothOpen = left < 0.28 && right < 0.28

        if bothClosed && !eyesWereClosed {
            eyesWereClosed = true
            blinkCount += 1
            blurLayers = min(maximumLayers, blurLayers + 1)
            lastDecayTime = Date()
        } else if bothOpen {
            eyesWereClosed = false
        }
    }

    func faceLost() {
        faceDetected = false
        eyesWereClosed = false
    }

    func processCameraFrame(_ pixelBuffer: CVPixelBuffer, timestamp: TimeInterval) {
        guard timestamp - lastFrameSubmitted >= 1.0 / 15.0 else { return }
        lastFrameSubmitted = timestamp
        decayBlur()
        let radius = blurRadius
        let context = self.context

        renderQueue.async { [weak self] in
            let source = CIImage(cvPixelBuffer: pixelBuffer).oriented(forExifOrientation: 6)
            let output: CIImage
            if radius > 0.05 {
                let blurred = source.clampedToExtent()
                    .applyingFilter("CIGaussianBlur", parameters: [kCIInputRadiusKey: radius])
                output = blurred.cropped(to: source.extent)
            } else {
                output = source
            }
            guard let cgImage = context.createCGImage(output, from: source.extent) else { return }
            Task { @MainActor [weak self] in
                self?.image = cgImage
            }
        }
    }

    func setCameraError(_ message: String) {
        cameraError = message
    }

    private func decayBlur() {
        let now = Date()
        let elapsed = max(0, now.timeIntervalSince(lastDecayTime))
        lastDecayTime = now
        blurLayers = max(0, blurLayers - CGFloat(elapsed) / secondsPerLayer)
    }
}
