import SwiftUI
import PhotosUI

struct CameraView: View {
    @EnvironmentObject private var store: MomentStore
    @Binding var selectedTab: AppTab

    @StateObject private var camera = CameraModel()
    @StateObject private var location = LocationService()
    @State private var pickerItem: PhotosPickerItem?

    private let accent = Color(
        red: 0.83,
        green: 1.0,
        blue: 0.24
    )

    private let surface = Color(
        red: 0.075,
        green: 0.08,
        blue: 0.095
    )

    private var stampTimeZone: TimeZone {
        location.timeZone ?? .current
    }

    private var stampPlace: String {
        location.placeName ?? "Locating…"
    }

    var body: some View {
        ZStack {
            Color.black
                .ignoresSafeArea()

            VStack(spacing: 0) {
                header
                    .padding(.top, 12)
                    .padding(.bottom, 22)

                cameraFrame

                controls
                    .padding(.top, 24)

                Spacer(minLength: 12)

                footer
                    .padding(.bottom, 12)
            }
            .padding(.horizontal, 20)
        }
        .preferredColorScheme(.dark)
        .onAppear {
            camera.onPhoto = { image in
                handle(image)
            }

            camera.start()
            location.start()
        }
        .onDisappear {
            camera.stop()
        }
        .onChange(of: pickerItem) { _, item in
            guard let item else { return }

            Task {
                if let data = try? await item.loadTransferable(
                    type: Data.self
                ), let image = UIImage(data: data) {
                    await MainActor.run {
                        handle(image)
                    }
                }

                await MainActor.run {
                    pickerItem = nil
                }
            }
        }
    }

    // MARK: - Header

    private var header: some View {
        VStack(spacing: 10) {
            HStack(alignment: .center) {
                VStack(alignment: .leading, spacing: 5) {
                    Text("PEBBLE")
                        .font(
                            .system(
                                size: 11,
                                weight: .black,
                                design: .monospaced
                            )
                        )
                        .tracking(4)
                        .foregroundStyle(accent)

                    Text("MOMENT CAPTURE")
                        .font(
                            .system(
                                size: 9,
                                weight: .medium,
                                design: .monospaced
                            )
                        )
                        .tracking(2)
                        .foregroundStyle(.white.opacity(0.48))
                }

                Spacer()

                HStack(spacing: 6) {
                    Circle()
                        .fill(store.hasPostedMyPhoto ? .gray : accent)
                        .frame(width: 6, height: 6)

                    Text(store.hasPostedMyPhoto ? "POSTED" : "READY")
                        .font(
                            .system(
                                size: 9,
                                weight: .bold,
                                design: .monospaced
                            )
                        )
                        .tracking(1.5)
                        .foregroundStyle(
                            store.hasPostedMyPhoto
                                ? .white.opacity(0.45)
                                : accent
                        )
                }
                .padding(.horizontal, 11)
                .padding(.vertical, 8)
                .overlay {
                    Capsule()
                        .stroke(.white.opacity(0.17), lineWidth: 1)
                }
            }

            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [
                            accent.opacity(0.7),
                            .white.opacity(0.12),
                            .clear
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .frame(height: 1)

            HStack(alignment: .center) {
                Text(headerTitle)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(.white.opacity(0.9))
                    .lineLimit(2)

                Spacer(minLength: 8)

                if let window = store.current,
                   !store.hasPostedMyPhoto {
                    TimelineView(.periodic(from: .now, by: 1)) { context in
                        Text(
                            Self.countdown(
                                until: window.endsAt,
                                now: context.date
                            )
                        )
                        .font(
                            .system(
                                size: 11,
                                weight: .semibold,
                                design: .monospaced
                            )
                        )
                        .monospacedDigit()
                        .foregroundStyle(accent)
                    }
                }
            }
        }
    }

    private var headerTitle: String {
        if store.hasPostedMyPhoto {
            return "Your moment is captured."
        }

        if store.current != nil {
            return "You're part of this moment."
        }

        return "Capture a moment to begin."
    }

    // MARK: - Camera frame

    private var cameraFrame: some View {
        ZStack(alignment: .bottomLeading) {
            previewArea

            // Viewfinder guides
            GeometryReader { geometry in
                let width = geometry.size.width
                let height = geometry.size.height
                let cornerLength: CGFloat = 20

                Path { path in
                    // Top left
                    path.move(to: CGPoint(x: 1, y: cornerLength))
                    path.addLine(to: CGPoint(x: 1, y: 1))
                    path.addLine(to: CGPoint(x: cornerLength, y: 1))

                    // Top right
                    path.move(to: CGPoint(x: width - cornerLength, y: 1))
                    path.addLine(to: CGPoint(x: width - 1, y: 1))
                    path.addLine(to: CGPoint(x: width - 1, y: cornerLength))

                    // Bottom left
                    path.move(to: CGPoint(x: 1, y: height - cornerLength))
                    path.addLine(to: CGPoint(x: 1, y: height - 1))
                    path.addLine(to: CGPoint(x: cornerLength, y: height - 1))

                    // Bottom right
                    path.move(to: CGPoint(x: width - cornerLength, y: height - 1))
                    path.addLine(to: CGPoint(x: width - 1, y: height - 1))
                    path.addLine(to: CGPoint(x: width - 1, y: height - cornerLength))
                }
                .stroke(accent.opacity(0.85), lineWidth: 1.5)
            }
            .padding(10)
            .allowsHitTesting(false)

            // Center crosshair
            Image(systemName: "plus")
                .font(.system(size: 12, weight: .ultraLight))
                .foregroundStyle(.white.opacity(0.55))
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .allowsHitTesting(false)

            // Bottom metadata overlay
            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 6) {
                    Circle()
                        .fill(accent)
                        .frame(width: 5, height: 5)

                    Text("LIVE VIEW")
                        .font(
                            .system(
                                size: 9,
                                weight: .bold,
                                design: .monospaced
                            )
                        )
                        .tracking(2)
                        .foregroundStyle(.white.opacity(0.85))

                    Spacer()

                    Text("Q / 01")
                        .font(
                            .system(
                                size: 9,
                                weight: .medium,
                                design: .monospaced
                            )
                        )
                        .foregroundStyle(.white.opacity(0.55))
                }

                Rectangle()
                    .fill(.white.opacity(0.25))
                    .frame(height: 1)

                stamp
            }
            .padding(18)
            .background {
                LinearGradient(
                    colors: [
                        .clear,
                        .black.opacity(0.25),
                        .black.opacity(0.82)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            }
        }
        .aspectRatio(3.0 / 4.0, contentMode: .fit)
        .clipShape(
            RoundedRectangle(
                cornerRadius: 18,
                style: .continuous
            )
        )
        .overlay {
            RoundedRectangle(
                cornerRadius: 18,
                style: .continuous
            )
            .stroke(.white.opacity(0.17), lineWidth: 1)
        }
        .overlay(alignment: .topTrailing) {
            Image(systemName: "viewfinder")
                .font(.system(size: 17, weight: .ultraLight))
                .foregroundStyle(accent.opacity(0.9))
                .padding(24)
                .allowsHitTesting(false)
        }
    }


    @ViewBuilder
    private var previewArea: some View {
        if camera.permissionDenied {
            message(
                "Camera access is off.\nEnable it in Settings → Qudge.",
                symbol: "camera.fill"
            )
        } else if !camera.cameraAvailable {
            message(
                "No camera available\n(Simulator?)",
                symbol: "camera.metering.unknown"
            )
        } else {
            CameraPreview(session: camera.session)
        }
    }

    private func message(
        _ text: String,
        symbol: String
    ) -> some View {
        VStack(spacing: 12) {
            Image(systemName: symbol)
                .font(.system(size: 28, weight: .ultraLight))
                .foregroundStyle(accent)

            Text(text)
                .font(.system(size: 12))
                .multilineTextAlignment(.center)
                .lineSpacing(4)
                .foregroundStyle(.white.opacity(0.75))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(surface)
    }

    // MARK: - Photo stamp

    private var stamp: some View {
        TimelineView(.periodic(from: .now, by: 1)) { context in
            VStack(alignment: .leading, spacing: 5) {
                Text(stampPlace.uppercased())
                    .font(
                        .system(
                            size: 11,
                            weight: .bold,
                            design: .monospaced
                        )
                    )
                    .tracking(1)
                    .lineLimit(1)

                HStack(spacing: 6) {
                    Image(systemName: "clock")
                        .font(.system(size: 9))

                    Text(
                        LocalTime.string(
                            context.date,
                            in: stampTimeZone
                        )
                    )
                    .font(
                        .system(
                            size: 10,
                            weight: .medium,
                            design: .monospaced
                        )
                    )

                    Text("·")

                    Text("LOCAL TIME")
                        .font(
                            .system(
                                size: 8,
                                weight: .medium,
                                design: .monospaced
                            )
                        )
                        .tracking(1)
                }
                .foregroundStyle(.white.opacity(0.7))
            }
            .foregroundStyle(.white)
        }
    }

    // MARK: - Controls

    private var controls: some View {
        VStack(spacing: 20) {
            HStack(alignment: .center) {
                // Photo library
                PhotosPicker(
                    selection: $pickerItem,
                    matching: .images
                ) {
                    VStack(spacing: 8) {
                        Image(systemName: "photo.on.rectangle")
                            .font(.system(size: 19, weight: .regular))
                            .frame(width: 52, height: 52)
                            .background(surface, in: Circle())
                            .overlay {
                                Circle()
                                    .stroke(
                                        .white.opacity(0.17),
                                        lineWidth: 1
                                    )
                            }

                        Text("LIBRARY")
                            .font(
                                .system(
                                    size: 8,
                                    weight: .semibold,
                                    design: .monospaced
                                )
                            )
                            .tracking(1)
                    }
                    .foregroundStyle(.white.opacity(0.85))
                    .frame(width: 76)
                }
                .disabled(store.hasPostedMyPhoto)

                Spacer()

                // Shutter
                Button {
                    camera.capture()
                } label: {
                    ZStack {
                        Circle()
                            .stroke(
                                store.hasPostedMyPhoto
                                    ? .white.opacity(0.2)
                                    : accent,
                                lineWidth: 2
                            )
                            .frame(width: 78, height: 78)

                        Circle()
                            .stroke(
                                store.hasPostedMyPhoto
                                    ? .white.opacity(0.12)
                                    : accent.opacity(0.3),
                                lineWidth: 1
                            )
                            .frame(width: 64, height: 64)

                        Circle()
                            .fill(
                                store.hasPostedMyPhoto
                                    ? Color.gray.opacity(0.4)
                                    : accent
                            )
                            .frame(width: 52, height: 52)

                        if store.hasPostedMyPhoto {
                            Image(systemName: "checkmark")
                                .font(.system(size: 18, weight: .bold))
                                .foregroundStyle(.white.opacity(0.8))
                        }
                    }
                    .frame(width: 84, height: 84)
                    .contentShape(Circle())
                }
                .buttonStyle(.plain)
                .disabled(
                    store.hasPostedMyPhoto || !camera.cameraAvailable
                )
                .accessibilityLabel("Take photo")

                Spacer()

                // Flip camera
                Button {
                    camera.flip()
                } label: {
                    VStack(spacing: 8) {
                        Image(
                            systemName: "arrow.triangle.2.circlepath.camera"
                        )
                        .font(.system(size: 19, weight: .regular))
                        .frame(width: 52, height: 52)
                        .background(surface, in: Circle())
                        .overlay {
                            Circle()
                                .stroke(
                                    .white.opacity(0.17),
                                    lineWidth: 1
                                )
                        }

                        Text("FLIP")
                            .font(
                                .system(
                                    size: 8,
                                    weight: .semibold,
                                    design: .monospaced
                                )
                            )
                            .tracking(1)
                    }
                    .foregroundStyle(.white.opacity(0.85))
                    .frame(width: 76)
                }
                .buttonStyle(.plain)
                .disabled(!camera.cameraAvailable)
            }

            Text(
                store.hasPostedMyPhoto
                    ? "YOUR MOMENT IS LOCKED IN"
                    : "ONE PHOTO. ONE SHARED MOMENT."
            )
            .font(
                .system(
                    size: 9,
                    weight: .medium,
                    design: .monospaced
                )
            )
            .tracking(1.8)
            .foregroundStyle(
                store.hasPostedMyPhoto
                    ? accent
                    : .white.opacity(0.4)
            )
        }
    }

    // MARK: - Footer

    private var footer: some View {
        HStack(spacing: 6) {
            Image(systemName: "location")
                .font(.system(size: 9))

            Text(stampPlace.uppercased())
                .lineLimit(1)

            Spacer()

            Text("QUDGE / CAMERA")
        }
        .font(
            .system(
                size: 8,
                weight: .medium,
                design: .monospaced
            )
        )
        .tracking(1)
        .foregroundStyle(.white.opacity(0.32))
    }

    // MARK: - Actions

    private func handle(_ image: UIImage) {
        store.submitMyPhoto(
            image,
            placeName: location.placeName ?? "Somewhere",
            timeZone: stampTimeZone
        )

        selectedTab = .moment
    }

    private static func countdown(
        until end: Date,
        now: Date
    ) -> String {
        let seconds = max(0, Int(end.timeIntervalSince(now)))
        return String(
            format: "%02d:%02d LEFT",
            seconds / 60,
            seconds % 60
        )
    }
}
 
