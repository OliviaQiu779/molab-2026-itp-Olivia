import SwiftUI
import Combine

// MARK: - Visual Style

private enum QudgeStyle {
    static let background = Color(
        red: 0.025,
        green: 0.027,
        blue: 0.035
    )

    static let surface = Color(
        red: 0.075,
        green: 0.08,
        blue: 0.095
    )

    static let accent = Color(
        red: 0.83,
        green: 1.0,
        blue: 0.24
    )

    static let muted = Color.white.opacity(0.48)
    static let border = Color.white.opacity(0.14)
}

// MARK: - Moment Home

struct MomentView: View {
    @EnvironmentObject private var store: MomentStore
    @Binding var selectedTab: AppTab

    @State private var showDetail = false
    @State private var selectedRoll: FilmRoll?

    private let ticker = Timer.publish(
        every: 1,
        on: .main,
        in: .common
    ).autoconnect()

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 30) {
                    if let window = store.current {
                        liveSection(window)
                    } else {
                        emptyState
                    }

                    rollsSection
                }
                .padding(.top, 12)
                .padding(.bottom, 36)
            }
            .background(QudgeStyle.background)
            .navigationTitle(store.group.name.uppercased())
            .toolbar {
                #if DEBUG
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        Button("Simulate friend photo") {
                            store.simulateFriendPhoto()
                        }

                        Button("End window now") {
                            store.endWindowNow()
                        }
                    } label: {
                        Image(systemName: "ellipsis")
                            .foregroundStyle(QudgeStyle.accent)
                    }
                }
                #endif
            }
            .toolbarColorScheme(.dark, for: .navigationBar)
        }
        .preferredColorScheme(.dark)
        .tint(QudgeStyle.accent)
        .onReceive(ticker) { date in
            store.closeIfExpired(now: date)
        }
        .fullScreenCover(isPresented: $showDetail) {
            MomentDetailView()
                .environmentObject(store)
        }
        .sheet(item: $selectedRoll) { roll in
            FilmRollDetail(roll: roll)
        }
    }

    // MARK: Live Moment

    private func liveSection(
        _ window: MomentWindow
    ) -> some View {
        VStack(spacing: 22) {
            HStack {
                HStack(spacing: 8) {
                    Circle()
                        .fill(QudgeStyle.accent)
                        .frame(width: 6, height: 6)

                    Text("LIVE MOMENT")
                        .font(
                            .system(
                                size: 10,
                                weight: .bold,
                                design: .monospaced
                            )
                        )
                        .tracking(2)
                        .foregroundStyle(QudgeStyle.accent)
                }

                Spacer()

                Text("ACTIVE")
                    .font(
                        .system(
                            size: 9,
                            weight: .medium,
                            design: .monospaced
                        )
                    )
                    .tracking(1.5)
                    .foregroundStyle(QudgeStyle.muted)
            }
            .padding(.horizontal, 22)

            MomentCollage(
                items: StackItem.ordered(
                    members: store.group.members,
                    captures: window.captures
                )
            ) {
                showDetail = true
            }

            VStack(spacing: 10) {
                Text(
                    "\(window.captures.count) / "
                    + "\(store.group.members.count)"
                )
                .font(
                    .system(
                        size: 34,
                        weight: .medium,
                        design: .rounded
                    )
                )
                .monospacedDigit()
                .foregroundStyle(.white)

                Text("PEOPLE HAVE SHARED")
                    .font(
                        .system(
                            size: 9,
                            weight: .medium,
                            design: .monospaced
                        )
                    )
                    .tracking(2)
                    .foregroundStyle(QudgeStyle.muted)

                if !store.hasPostedMyPhoto {
                    Button {
                        selectedTab = .camera
                    } label: {
                        HStack(spacing: 10) {
                            Image(systemName: "camera")

                            Text("CAPTURE YOUR MOMENT")
                                .tracking(1.5)
                        }
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(.black)
                        .padding(.horizontal, 24)
                        .frame(height: 48)
                        .background(
                            QudgeStyle.accent,
                            in: Capsule()
                        )
                    }
                    .padding(.top, 12)
                }
            }
        }
    }

    // MARK: Empty State

    private var emptyState: some View {
        VStack(alignment: .leading, spacing: 24) {
            Text("NO ACTIVE\nMOMENT.")
                .font(
                    .system(
                        size: 43,
                        weight: .bold,
                        design: .rounded
                    )
                )
                .tracking(-1.5)
                .foregroundStyle(.white)
                .fixedSize(
                    horizontal: false,
                    vertical: true
                )

            Rectangle()
                .fill(QudgeStyle.accent)
                .frame(width: 42, height: 3)

            Text(
                "Your next shared moment starts when "
                + "your group's window opens."
            )
            .font(.system(size: 14))
            .foregroundStyle(QudgeStyle.muted)
            .lineSpacing(5)

            Button {
                store.startWindow()
                selectedTab = .camera
            } label: {
                HStack(spacing: 10) {
                    Image(systemName: "plus")

                    Text("START A MOMENT")
                        .tracking(1.5)
                }
                .font(.system(size: 11, weight: .bold))
                .foregroundStyle(.black)
                .padding(.horizontal, 24)
                .frame(height: 48)
                .background(
                    QudgeStyle.accent,
                    in: Capsule()
                )
            }
        }
        .frame(
            maxWidth: .infinity,
            alignment: .leading
        )
        .padding(.horizontal, 24)
        .padding(.top, 46)
        .padding(.bottom, 24)
    }

    // MARK: Archive

    @ViewBuilder
    private var rollsSection: some View {
        if !store.rolls.isEmpty {
            VStack(alignment: .leading, spacing: 22) {
                HStack(alignment: .firstTextBaseline) {
                    Text("THE ARCHIVE")
                        .font(.system(size: 13, weight: .bold))
                        .tracking(2)
                        .foregroundStyle(.white)

                    Spacer()

                    Text(
                        String(
                            format: "%02d MOMENTS",
                            store.rolls.count
                        )
                    )
                    .font(
                        .system(
                            size: 9,
                            weight: .medium,
                            design: .monospaced
                        )
                    )
                    .tracking(1)
                    .foregroundStyle(QudgeStyle.muted)
                }
                .padding(.horizontal, 22)

                LazyVStack(spacing: 26) {
                    ForEach(store.rolls) { roll in
                        Button {
                            selectedRoll = roll
                        } label: {
                            RollHistoryCard(roll: roll)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 20)
            }
        }
    }
}

// MARK: - Stack Item

enum StackItem: Identifiable {
    case photo(Capture, Friend)
    case pending(Friend)

    var id: String {
        switch self {
        case .photo(let capture, _):
            return capture.id.uuidString

        case .pending(let friend):
            return "pending-" + friend.id.uuidString
        }
    }

    var isPending: Bool {
        if case .pending = self {
            return true
        }

        return false
    }

    static func ordered(
        members: [Friend],
        captures: [Capture]
    ) -> [StackItem] {
        let posted: [StackItem] = captures
            .sorted {
                $0.capturedAt < $1.capturedAt
            }
            .compactMap { capture in
                guard let friend = members.first(
                    where: { $0.id == capture.friendID }
                ) else {
                    return nil
                }

                return .photo(capture, friend)
            }

        let pending: [StackItem] = members
            .filter { member in
                !captures.contains {
                    $0.friendID == member.id
                }
            }
            .map {
                StackItem.pending($0)
            }

        return posted + pending
    }
}

// MARK: - Photo Card

struct PhotoCard: View {
    let capture: Capture
    let friend: Friend
    var compact = false

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .bottomLeading) {
                if let image = PebbleStorage.loadImage(
                    named: capture.imageFileName
                ) {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                        .frame(
                            width: geometry.size.width,
                            height: geometry.size.height
                        )
                        .clipped()
                } else {
                    QudgeStyle.surface
                }

                LinearGradient(
                    colors: [
                        .clear,
                        .black.opacity(0.15),
                        .black.opacity(0.85)
                    ],
                    startPoint: .center,
                    endPoint: .bottom
                )

                VStack(alignment: .leading, spacing: 4) {
                    Text(friend.name.uppercased())
                        .font(
                            .system(
                                size: compact ? 10 : 13,
                                weight: .bold
                            )
                        )
                        .tracking(1)

                    Text(capture.placeName.uppercased())
                        .font(
                            .system(
                                size: compact ? 8 : 9,
                                weight: .medium
                            )
                        )
                        .tracking(1)
                        .lineLimit(1)

                    Text(capture.localTimeString)
                        .font(
                            .system(
                                size: 9,
                                weight: .medium,
                                design: .monospaced
                            )
                        )
                }
                .foregroundStyle(.white)
                .padding(compact ? 12 : 16)
            }
            .frame(
                width: geometry.size.width,
                height: geometry.size.height
            )
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
                .stroke(
                    .white.opacity(0.22),
                    lineWidth: 1
                )
            }
            .shadow(
                color: .black.opacity(0.5),
                radius: 16,
                y: 8
            )
        }
    }
}

// MARK: - Pending Card

struct PendingCard: View {
    let friend: Friend
    var compact = false

    var body: some View {
        ZStack {
            RoundedRectangle(
                cornerRadius: 18,
                style: .continuous
            )
            .fill(
                LinearGradient(
                    colors: [
                        Color(
                            red: 0.11,
                            green: 0.12,
                            blue: 0.15
                        ),
                        Color(
                            red: 0.035,
                            green: 0.04,
                            blue: 0.05
                        )
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )

            Circle()
                .fill(QudgeStyle.accent.opacity(0.11))
                .frame(width: 130, height: 130)
                .blur(radius: 35)
                .offset(x: 40, y: -45)

            VStack(spacing: compact ? 7 : 12) {
                Text(friend.initial)
                    .font(
                        .system(
                            size: compact ? 52 : 82,
                            weight: .medium,
                            design: .rounded
                        )
                    )
                    .foregroundStyle(QudgeStyle.accent)

                Text(friend.name.uppercased())
                    .font(
                        .system(
                            size: compact ? 10 : 13,
                            weight: .bold
                        )
                    )
                    .tracking(1)

                TimelineView(
                    .periodic(from: .now, by: 30)
                ) { context in
                    Text(
                        "\(friend.homeCity.uppercased()) · "
                        + "\(LocalTime.clock(context.date, in: friend.timeZone))"
                    )
                    .font(
                        .system(
                            size: compact ? 8 : 9,
                            weight: .medium,
                            design: .monospaced
                        )
                    )
                    .multilineTextAlignment(.center)
                    .foregroundStyle(QudgeStyle.muted)
                }

                HStack(spacing: 5) {
                    Circle()
                        .fill(QudgeStyle.accent)
                        .frame(width: 4, height: 4)

                    Text("AWAITING")
                        .font(
                            .system(
                                size: 8,
                                weight: .bold,
                                design: .monospaced
                            )
                        )
                        .tracking(1.5)
                        .foregroundStyle(QudgeStyle.accent)
                }
                .padding(.top, 3)
            }
            .padding(10)
        }
        .overlay {
            RoundedRectangle(
                cornerRadius: 18,
                style: .continuous
            )
            .stroke(
                LinearGradient(
                    colors: [
                        .white.opacity(0.32),
                        .white.opacity(0.06)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ),
                lineWidth: 1
            )
        }
    }
}

// MARK: - Moment Detail

struct MomentDetailView: View {
    @EnvironmentObject private var store: MomentStore
    @Environment(\.dismiss) private var dismiss

    @State private var zoomed: Capture?

    private let columns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    if let window = store.current {
                        header(window)

                        LazyVGrid(
                            columns: columns,
                            spacing: 12
                        ) {
                            ForEach(
                                StackItem.ordered(
                                    members: store.group.members,
                                    captures: window.captures
                                )
                            ) { item in
                                cell(item)
                            }
                        }
                        .padding(.horizontal, 16)
                    }
                }
                .padding(.vertical, 20)
            }
            .background(QudgeStyle.background)
            .navigationTitle("THE MOMENT")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("DONE") {
                        dismiss()
                    }
                    .font(.system(size: 11, weight: .bold))
                    .tracking(1)
                }
            }
        }
        .preferredColorScheme(.dark)
        .onChange(of: store.current?.id) { _, newValue in
            if newValue == nil {
                dismiss()
            }
        }
        .fullScreenCover(item: $zoomed) { capture in
            PhotoZoomView(
                capture: capture,
                friend: store.member(id: capture.friendID)
            )
        }
    }

    private func header(
        _ window: MomentWindow
    ) -> some View {
        TimelineView(
            .periodic(from: .now, by: 1)
        ) { context in
            let remaining = max(
                0,
                Int(
                    window.endsAt.timeIntervalSince(
                        context.date
                    )
                )
            )

            let total = max(
                1,
                window.endsAt.timeIntervalSince(
                    window.startedAt
                )
            )

            let progress = min(
                1,
                max(
                    0,
                    context.date.timeIntervalSince(
                        window.startedAt
                    ) / total
                )
            )

            VStack(spacing: 12) {
                Text(
                    String(
                        format: "%02d:%02d",
                        remaining / 60,
                        remaining % 60
                    )
                )
                .font(
                    .system(
                        size: 46,
                        weight: .medium,
                        design: .rounded
                    )
                )
                .monospacedDigit()
                .foregroundStyle(QudgeStyle.accent)

                Text(
                    "\(window.captures.count) / "
                    + "\(store.group.members.count) SHARED"
                )
                .font(
                    .system(
                        size: 9,
                        weight: .medium,
                        design: .monospaced
                    )
                )
                .tracking(2)
                .foregroundStyle(QudgeStyle.muted)

                ProgressView(value: progress)
                    .tint(QudgeStyle.accent)
                    .padding(.horizontal, 48)
            }
        }
    }

    @ViewBuilder
    private func cell(
        _ item: StackItem
    ) -> some View {
        switch item {
        case .photo(let capture, let friend):
            PhotoCard(
                capture: capture,
                friend: friend,
                compact: true
            )
            .aspectRatio(3.0 / 4.0, contentMode: .fit)
            .onTapGesture {
                zoomed = capture
            }

        case .pending(let friend):
            PendingCard(
                friend: friend,
                compact: true
            )
            .aspectRatio(3.0 / 4.0, contentMode: .fit)
        }
    }
}

// MARK: - Photo Zoom

struct PhotoZoomView: View {
    let capture: Capture
    let friend: Friend?

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack(alignment: .topTrailing) {
            QudgeStyle.background
                .ignoresSafeArea()

            VStack(spacing: 18) {
                Spacer(minLength: 40)

                if let image = PebbleStorage.loadImage(
                    named: capture.imageFileName
                ) {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .clipShape(
                            RoundedRectangle(
                                cornerRadius: 18,
                                style: .continuous
                            )
                        )
                        .padding(.horizontal, 12)
                }

                VStack(spacing: 8) {
                    Text(
                        (friend?.name ?? "Friend").uppercased()
                    )
                    .font(.headline)
                    .tracking(1)

                    Label(
                        capture.placeName,
                        systemImage: "location"
                    )

                    Label(
                        capture.localTimeString,
                        systemImage: "clock"
                    )
                }
                .font(.subheadline)
                .foregroundStyle(.white)

                Spacer(minLength: 50)
            }

            Button {
                dismiss()
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(.white)
                    .padding(14)
                    .background(
                        .white.opacity(0.1),
                        in: Circle()
                    )
                    .padding()
            }
        }
        .preferredColorScheme(.dark)
    }
}

// MARK: - Archive Card

struct RollHistoryCard: View {
    let roll: FilmRoll

    private var displayedFrames: [FilmRoll.Frame] {
        Array(roll.frames.suffix(4))
    }

    private let columns = [
        GridItem(.flexible(), spacing: 8),
        GridItem(.flexible(), spacing: 8)
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                VStack(alignment: .leading, spacing: 5) {
                    Text(
                        roll.endedAt.formatted(
                            date: .abbreviated,
                            time: .omitted
                        ).uppercased()
                    )
                    .font(.system(size: 12, weight: .bold))
                    .tracking(1.5)
                    .foregroundStyle(.white)

                    Text("\(roll.frames.count) PHOTOS")
                        .font(
                            .system(
                                size: 9,
                                weight: .medium,
                                design: .monospaced
                            )
                        )
                        .tracking(1.5)
                        .foregroundStyle(QudgeStyle.muted)
                }

                Spacer()

                Image(systemName: "arrow.up.right")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(QudgeStyle.accent)
            }

            LazyVGrid(
                columns: columns,
                spacing: 8
            ) {
                ForEach(displayedFrames) { frame in
                    archivePhoto(frame)
                }
            }

            HStack(spacing: 7) {
                Rectangle()
                    .fill(QudgeStyle.accent)
                    .frame(width: 18, height: 2)

                Text(roll.groupName.uppercased())
                    .font(.system(size: 9, weight: .semibold))
                    .tracking(1.5)
                    .foregroundStyle(QudgeStyle.muted)
            }
        }
        .padding(12)
        .background(QudgeStyle.surface)
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
            .stroke(QudgeStyle.border, lineWidth: 1)
        }
        .frame(maxWidth: .infinity)
        .contentShape(
            RoundedRectangle(
                cornerRadius: 18,
                style: .continuous
            )
        )
    }

    private func archivePhoto(
        _ frame: FilmRoll.Frame
    ) -> some View {
        GeometryReader { geometry in
            ZStack(alignment: .bottomLeading) {
                if let image = PebbleStorage.loadImage(
                    named: frame.imageFileName
                ) {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                        .frame(
                            width: geometry.size.width,
                            height: geometry.size.height
                        )
                        .clipped()
                } else {
                    QudgeStyle.surface
                }

                LinearGradient(
                    colors: [
                        .clear,
                        .black.opacity(0.85)
                    ],
                    startPoint: .center,
                    endPoint: .bottom
                )

                VStack(alignment: .leading, spacing: 4) {
                    Text(frame.memberName.uppercased())
                        .font(.system(size: 10, weight: .bold))
                        .tracking(0.8)
                        .lineLimit(1)

                    Text(frame.placeName)
                        .font(.system(size: 9, weight: .medium))
                        .lineLimit(1)

                    Text(
                        LocalTime.string(
                            frame.capturedAt,
                            in: TimeZone(
                                identifier: frame.timeZoneID
                            ) ?? .current
                        )
                    )
                    .font(
                        .system(
                            size: 9,
                            weight: .medium,
                            design: .monospaced
                        )
                    )
                }
                .foregroundStyle(.white)
                .padding(9)
            }
            .clipShape(
                RoundedRectangle(
                    cornerRadius: 10,
                    style: .continuous
                )
            )
            .overlay {
                RoundedRectangle(
                    cornerRadius: 10,
                    style: .continuous
                )
                .stroke(.white.opacity(0.12), lineWidth: 1)
            }
        }
        .aspectRatio(3.0 / 4.0, contentMode: .fit)
    }
}

// MARK: - Full-width Photo Archive

struct FilmStripView: View {
    let roll: FilmRoll
    var compact = false

    var body: some View {
        VStack(spacing: 16) {
            ForEach(roll.frames) { frame in
                archivePhoto(frame)
                    .frame(maxWidth: .infinity)
            }
        }
        .frame(maxWidth: .infinity)
    }

    private func archivePhoto(
        _ frame: FilmRoll.Frame
    ) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            if let image = PebbleStorage.loadImage(
                named: frame.imageFileName
            ) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: .infinity)
                    .background(.black)
            } else {
                Rectangle()
                    .fill(QudgeStyle.surface)
                    .frame(height: 220)
            }

            VStack(alignment: .leading, spacing: 6) {
                Text(frame.memberName.uppercased())
                    .font(.system(size: 12, weight: .bold))
                    .tracking(1.2)
                    .foregroundStyle(.white)

                Text(frame.placeName)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(.white.opacity(0.85))

                HStack(spacing: 6) {
                    Image(systemName: "clock")
                        .font(.system(size: 9))

                    Text(
                        LocalTime.string(
                            frame.capturedAt,
                            in: TimeZone(
                                identifier: frame.timeZoneID
                            ) ?? .current
                        )
                    )
                    .font(
                        .system(
                            size: 10,
                            weight: .medium,
                            design: .monospaced
                        )
                    )
                }
                .foregroundStyle(.white.opacity(0.6))
            }
            .padding(14)
            .frame(
                maxWidth: .infinity,
                alignment: .leading
            )
            .background(QudgeStyle.surface)
        }
        .clipShape(
            RoundedRectangle(
                cornerRadius: 14,
                style: .continuous
            )
        )
        .overlay {
            RoundedRectangle(
                cornerRadius: 14,
                style: .continuous
            )
            .stroke(QudgeStyle.border, lineWidth: 1)
        }
    }
}

// MARK: - Film Roll Detail

struct FilmRollDetail: View {
    let roll: FilmRoll

    @Environment(\.dismiss) private var dismiss

    private var shareText: String {
        let date = roll.endedAt.formatted(
            date: .long,
            time: .omitted
        )

        let details = roll.frames.map { frame in
            let zone = TimeZone(
                identifier: frame.timeZoneID
            ) ?? .current

            return """
            \(frame.memberName)
            \(frame.placeName)
            \(LocalTime.string(frame.capturedAt, in: zone))
            """
        }

        return """
        \(roll.groupName)
        \(date)
        \(roll.frames.count) photos

        \(details.joined(separator: "\n\n"))
        """
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    VStack(alignment: .leading, spacing: 10) {
                        Text(
                            roll.endedAt.formatted(
                                date: .long,
                                time: .omitted
                            ).uppercased()
                        )
                        .font(
                            .system(
                                size: 24,
                                weight: .bold
                            )
                        )
                        .tracking(-0.5)
                        .foregroundStyle(.white)

                        HStack(spacing: 8) {
                            Rectangle()
                                .fill(QudgeStyle.accent)
                                .frame(width: 24, height: 2)

                            Text(
                                "\(roll.frames.count) PHOTOS / "
                                + roll.groupName.uppercased()
                            )
                            .font(
                                .system(
                                    size: 9,
                                    weight: .medium,
                                    design: .monospaced
                                )
                            )
                            .tracking(1.2)
                            .foregroundStyle(QudgeStyle.muted)
                        }
                    }

                    FilmStripView(roll: roll)
                }
                .padding(.horizontal, 16)
                .padding(.top, 18)
                .padding(.bottom, 32)
            }
            .background(
                QudgeStyle.background
                    .ignoresSafeArea()
            )
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(
                                .system(
                                    size: 12,
                                    weight: .semibold
                                )
                            )
                            .foregroundStyle(.white)
                            .frame(width: 36, height: 36)
                            .background(
                                .white.opacity(0.08),
                                in: Circle()
                            )
                            .overlay {
                                Circle()
                                    .stroke(
                                        QudgeStyle.border,
                                        lineWidth: 1
                                    )
                            }
                    }
                    .accessibilityLabel("Close")
                }

                ToolbarItem(placement: .principal) {
                    Text("MOMENT")
                        .font(
                            .system(
                                size: 10,
                                weight: .bold,
                                design: .monospaced
                            )
                        )
                        .tracking(3)
                        .foregroundStyle(QudgeStyle.accent)
                }

                ToolbarItem(placement: .topBarTrailing) {
                    ShareLink(item: shareText) {
                        Image(
                            systemName: "square.and.arrow.up"
                        )
                        .font(
                            .system(
                                size: 15,
                                weight: .medium
                            )
                        )
                        .foregroundStyle(QudgeStyle.accent)
                        .frame(width: 36, height: 36)
                    }
                    .accessibilityLabel("Share moment")
                }
            }
            .toolbarTitleDisplayMode(.inline)
        }
        .preferredColorScheme(.dark)
        .tint(QudgeStyle.accent)
        .presentationDragIndicator(.visible)
    }
}
