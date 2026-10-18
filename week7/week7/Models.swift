import SwiftUI

// MARK: - Core models

struct Friend: Identifiable, Codable, Hashable {
    let id: UUID
    var name: String
    var colorHex: String
    var homeCity: String
    var timeZoneID: String

    var timeZone: TimeZone { TimeZone(identifier: timeZoneID) ?? .current }
    var initial: String { String(name.prefix(1)).uppercased() }
    var color: Color { Color(hex: colorHex) }
}

struct PebbleGroup: Identifiable, Codable, Hashable {
    let id: UUID
    var name: String
    var members: [Friend]
}

/// One photo taken by one member inside a window.
struct Capture: Identifiable, Codable, Hashable {
    let id: UUID
    let friendID: UUID
    var imageFileName: String      // file inside Documents/Pebble/Images
    var capturedAt: Date
    var timeZoneID: String         // time zone where the photo was taken
    var placeName: String          // e.g. "Tokyo, Japan"

    var timeZone: TimeZone { TimeZone(identifier: timeZoneID) ?? .current }
    var localTimeString: String { LocalTime.string(capturedAt, in: timeZone) }
}

/// A live (or just-finished) window.
struct MomentWindow: Identifiable, Codable, Hashable {
    let id: UUID
    let groupID: UUID
    var startedAt: Date
    var endsAt: Date
    var startedBy: UUID
    var captures: [Capture]
}

/// What a window turns into when it ends. This is the JSON file saved to disk.
struct FilmRoll: Identifiable, Codable, Hashable {
    struct Frame: Identifiable, Codable, Hashable {
        var id: UUID
        var memberName: String
        var imageFileName: String
        var capturedAt: Date
        var timeZoneID: String
        var placeName: String

        var timeZone: TimeZone { TimeZone(identifier: timeZoneID) ?? .current }
        var localTimeString: String { LocalTime.string(capturedAt, in: timeZone) }
    }

    let id: UUID
    var groupID: UUID
    var groupName: String
    var startedAt: Date
    var endedAt: Date
    var frames: [Frame]
}

// MARK: - Helpers

enum LocalTime {
    /// "Thu 9:41 PM" in the given time zone.
    static func string(_ date: Date, in tz: TimeZone) -> String {
        let f = DateFormatter()
        f.timeZone = tz
        f.setLocalizedDateFormatFromTemplate("EEEjmm")
        return f.string(from: date)
    }

    /// "9:41 PM" only.
    static func clock(_ date: Date, in tz: TimeZone) -> String {
        let f = DateFormatter()
        f.timeZone = tz
        f.timeStyle = .short
        f.dateStyle = .none
        return f.string(from: date)
    }
}

extension Color {
    init(hex: String) {
        let s = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var v: UInt64 = 0
        Scanner(string: s).scanHexInt64(&v)
        self.init(
            red: Double((v >> 16) & 0xFF) / 255,
            green: Double((v >> 8) & 0xFF) / 255,
            blue: Double(v & 0xFF) / 255
        )
    }
}

extension UIImage {
    /// Fixes orientation and caps the longest side so JPEGs stay small.
    func resized(maxDimension: CGFloat) -> UIImage {
        let longest = max(size.width, size.height)
        let scale = min(1, maxDimension / longest)
        let target = CGSize(width: size.width * scale, height: size.height * scale)
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        return UIGraphicsImageRenderer(size: target, format: format).image { _ in
            draw(in: CGRect(origin: .zero, size: target))
        }
    }
}

// MARK: - Demo data (replace with real backend later)

enum DemoData {
    static let me = Friend(
        id: UUID(uuidString: "00000000-0000-0000-0000-000000000001")!,
        name: "You", colorHex: "#FF8A65", homeCity: "New York", timeZoneID: "America/New_York")

    static func make() -> (group: PebbleGroup, me: Friend) {
        let members = [
            me,
            Friend(id: UUID(uuidString: "00000000-0000-0000-0000-000000000002")!,
                   name: "Yuki", colorHex: "#64B5F6", homeCity: "Tokyo", timeZoneID: "Asia/Tokyo"),
            Friend(id: UUID(uuidString: "00000000-0000-0000-0000-000000000003")!,
                   name: "Mia", colorHex: "#81C784", homeCity: "London", timeZoneID: "Europe/London"),
            Friend(id: UUID(uuidString: "00000000-0000-0000-0000-000000000004")!,
                   name: "Leo", colorHex: "#BA68C8", homeCity: "Sydney", timeZoneID: "Australia/Sydney"),
        ]
        let group = PebbleGroup(
            id: UUID(uuidString: "00000000-0000-0000-0000-0000000000AA")!,
            name: "Pebble Crew", members: members)
        return (group, me)
    }

    /// Fake photo so you can test without a backend or a real camera.
    static func sampleImage(for friend: Friend) -> UIImage {
        let size = CGSize(width: 900, height: 1200)
        let base = UIColor(Color(hex: friend.colorHex))
        return UIGraphicsImageRenderer(size: size).image { ctx in
            let colors = [base.cgColor, UIColor.black.withAlphaComponent(0.55).cgColor] as CFArray
            let grad = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(), colors: colors, locations: [0, 1])!
            ctx.cgContext.drawLinearGradient(grad, start: .zero, end: CGPoint(x: size.width, y: size.height), options: [])
            let text = friend.homeCity as NSString
            let attrs: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 120, weight: .heavy),
                .foregroundColor: UIColor.white.withAlphaComponent(0.9)
            ]
            let ts = text.size(withAttributes: attrs)
            text.draw(at: CGPoint(x: (size.width - ts.width) / 2, y: (size.height - ts.height) / 2), withAttributes: attrs)
        }
    }
}
