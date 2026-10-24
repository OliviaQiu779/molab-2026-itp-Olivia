import ARKit
import SceneKit
import SwiftUI

/// Hosts ARKit's front camera and forwards face blend shapes and camera frames.
/// The live filtered image is displayed by SwiftUI above this transparent view.
struct FaceCameraView: UIViewRepresentable {
    let model: BlinkBlurModel

    func makeCoordinator() -> Coordinator { Coordinator(model: model) }

    func makeUIView(context: Context) -> ARSCNView {
        let view = ARSCNView(frame: .zero)
        view.delegate = context.coordinator
        view.session.delegate = context.coordinator
        view.scene = SCNScene()
        view.backgroundColor = .clear
        view.isOpaque = false

        guard ARFaceTrackingConfiguration.isSupported else {
            model.setCameraError("Face tracking requires a TrueDepth front camera.")
            return view
        }
        let configuration = ARFaceTrackingConfiguration()
        configuration.maximumNumberOfTrackedFaces = 1
        view.session.run(configuration, options: [.resetTracking, .removeExistingAnchors])
        return view
    }

    func updateUIView(_ uiView: ARSCNView, context: Context) {}

    static func dismantleUIView(_ uiView: ARSCNView, coordinator: Coordinator) {
        uiView.session.pause()
    }

    final class Coordinator: NSObject, ARSCNViewDelegate, ARSessionDelegate {
        private let model: BlinkBlurModel

        init(model: BlinkBlurModel) { self.model = model }

        nonisolated func renderer(_ renderer: SCNSceneRenderer, nodeFor anchor: ARAnchor) -> SCNNode? {
            guard anchor is ARFaceAnchor,
                  let device = renderer.device,
                  let geometry = ARSCNFaceGeometry(device: device) else { return nil }
            geometry.firstMaterial?.fillMode = .lines
            geometry.firstMaterial?.diffuse.contents = UIColor.clear
            geometry.firstMaterial?.colorBufferWriteMask = []
            return SCNNode(geometry: geometry)
        }

        nonisolated func renderer(_ renderer: SCNSceneRenderer, didUpdate node: SCNNode, for anchor: ARAnchor) {
            guard let face = anchor as? ARFaceAnchor else { return }
            (node.geometry as? ARSCNFaceGeometry)?.update(from: face.geometry)
            let shapes = face.blendShapes
            let tracked = face.isTracked
            Task { @MainActor [weak model] in
                if tracked { model?.update(blendShapes: shapes) }
                else { model?.faceLost() }
            }
        }

        nonisolated func renderer(_ renderer: SCNSceneRenderer, didRemove node: SCNNode, for anchor: ARAnchor) {
            guard anchor is ARFaceAnchor else { return }
            Task { @MainActor [weak model] in model?.faceLost() }
        }

        nonisolated func session(_ session: ARSession, didUpdate frame: ARFrame) {
            let buffer = frame.capturedImage
            let timestamp = frame.timestamp
            Task { @MainActor [weak model] in
                model?.processCameraFrame(buffer, timestamp: timestamp)
            }
        }

        nonisolated func session(_ session: ARSession, didFailWithError error: Error) {
            Task { @MainActor [weak model] in model?.setCameraError(error.localizedDescription) }
        }

        nonisolated func sessionWasInterrupted(_ session: ARSession) {
            Task { @MainActor [weak model] in model?.faceLost() }
        }
    }
}
