import SwiftUI

struct ContentView: View {
    @StateObject private var model = BlinkBlurModel()

    var body: some View {
        ZStack(alignment: .bottom) {
            Color.black.ignoresSafeArea()

            FaceCameraView(model: model)
                .ignoresSafeArea()

            if let image = model.image {
                GeometryReader { geometry in
                    Image(decorative: image, scale: 1, orientation: .upMirrored)
                        .resizable()
                        .scaledToFill()
                        .frame(width: geometry.size.width, height: geometry.size.height)
                        .clipped()
                }
                .ignoresSafeArea()
            }

            VStack(alignment: .leading, spacing: 8) {
                Text(model.cameraError ?? statusText)
                    .font(.headline)
                Text("Blinks: \(model.blinkCount)   Blur: \(Int(model.blurRadius))")
                    .font(.subheadline.monospacedDigit())
                Text("Blink to add blur. It fades away over time.")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.75))
            }
            .foregroundStyle(.white)
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(.black.opacity(0.58), in: RoundedRectangle(cornerRadius: 16))
            .padding()
        }
        .ignoresSafeArea()
        .preferredColorScheme(.dark)
    }

    private var statusText: String {
        guard model.isSupported else { return "Face tracking is unavailable on this device" }
        return model.faceDetected ? "Face detected" : "Looking for your face…"
    }
}
