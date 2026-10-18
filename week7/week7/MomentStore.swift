import SwiftUI
import Combine

@MainActor
final class MomentStore: ObservableObject {
    static let windowDuration: TimeInterval = 60 * 60   // one hour

    @Published private(set) var group: PebbleGroup
    @Published private(set) var current: MomentWindow?
    @Published private(set) var rolls: [FilmRoll]
    let me: Friend

    init() {
        let demo = DemoData.make()
        group = demo.group
        me = demo.me
        rolls = PebbleStorage.loadRolls()
        current = PebbleStorage.loadCurrent()
        closeIfExpired()
    }

    // MARK: Queries

    var hasPostedMyPhoto: Bool {
        current?.captures.contains { $0.friendID == me.id } ?? false
    }

    func capture(for friend: Friend) -> Capture? {
        current?.captures.first { $0.friendID == friend.id }
    }

    func member(id: UUID) -> Friend? {
        group.members.first { $0.id == id }
    }

    /// Captures sorted oldest → newest.
    var sortedCaptures: [Capture] {
        (current?.captures ?? []).sorted { $0.capturedAt < $1.capturedAt }
    }

    // MARK: Window lifecycle

    /// Normally the server opens a window for everyone at the shared reminder time.
    /// A user can also open one by taking a photo (see `submitMyPhoto`).
    func startWindow(by starter: Friend? = nil) {
        guard current == nil else { return }
        let now = Date()
        current = MomentWindow(
            id: UUID(), groupID: group.id,
            startedAt: now, endsAt: now.addingTimeInterval(Self.windowDuration),
            startedBy: (starter ?? me).id, captures: [])
        PebbleStorage.saveCurrent(current)
    }

    func submitMyPhoto(_ image: UIImage, placeName: String, timeZone: TimeZone) {
        if current == nil { startWindow(by: me) }
        add(image, from: me, placeName: placeName, timeZone: timeZone)
    }

    private func add(_ image: UIImage, from friend: Friend, placeName: String, timeZone: TimeZone) {
        guard var window = current,
              !window.captures.contains(where: { $0.friendID == friend.id }),
              let file = try? PebbleStorage.saveImage(image) else { return }
        window.captures.append(Capture(
            id: UUID(), friendID: friend.id, imageFileName: file,
            capturedAt: Date(), timeZoneID: timeZone.identifier, placeName: placeName))
        current = window
        PebbleStorage.saveCurrent(window)
    }

    /// Call every second from the UI; turns the window into a film roll when time is up.
    func closeIfExpired(now: Date = Date()) {
        guard let window = current, now >= window.endsAt else { return }
        finish(window, at: window.endsAt)
    }

    func endWindowNow() {
        guard let window = current else { return }
        finish(window, at: Date())
    }

    private func finish(_ window: MomentWindow, at end: Date) {
        defer {
            current = nil
            PebbleStorage.saveCurrent(nil)
        }
        guard !window.captures.isEmpty else { return }   // nobody posted → no roll

        let frames = window.captures
            .sorted { $0.capturedAt < $1.capturedAt }
            .map { c in
                FilmRoll.Frame(
                    id: c.id,
                    memberName: member(id: c.friendID)?.name ?? "Friend",
                    imageFileName: c.imageFileName,
                    capturedAt: c.capturedAt,
                    timeZoneID: c.timeZoneID,
                    placeName: c.placeName)
            }
        let roll = FilmRoll(
            id: window.id, groupID: group.id, groupName: group.name,
            startedAt: window.startedAt, endedAt: end, frames: frames)
        try? PebbleStorage.saveRoll(roll)
        rolls.insert(roll, at: 0)
    }

    // MARK: Debug helpers (no backend yet)

    func simulateFriendPhoto() {
        if current == nil { startWindow(by: group.members.first { $0.id != me.id }) }
        guard let friend = group.members.first(where: { $0.id != me.id && capture(for: $0) == nil }) else { return }
        add(DemoData.sampleImage(for: friend), from: friend,
            placeName: friend.homeCity, timeZone: friend.timeZone)
    }
}
