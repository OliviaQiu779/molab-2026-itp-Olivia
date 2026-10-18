import UIKit

/// Everything lives under Documents/Pebble:
///   Images/<uuid>.jpg        photos
///   Rolls/roll_<uuid>.json   finished film rolls (one per window)
///   current_window.json      the window that is still open (survives relaunch)
enum PebbleStorage {
    private static let fm = FileManager.default

    static let root: URL = {
        let docs = fm.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let url = docs.appendingPathComponent("Pebble", isDirectory: true)
        try? fm.createDirectory(at: url, withIntermediateDirectories: true)
        return url
    }()

    static var imagesDir: URL { subdir("Images") }
    static var rollsDir: URL { subdir("Rolls") }
    private static var currentURL: URL { root.appendingPathComponent("current_window.json") }

    private static func subdir(_ name: String) -> URL {
        let url = root.appendingPathComponent(name, isDirectory: true)
        try? fm.createDirectory(at: url, withIntermediateDirectories: true)
        return url
    }

    static let encoder: JSONEncoder = {
        let e = JSONEncoder()
        e.dateEncodingStrategy = .iso8601
        e.outputFormatting = [.prettyPrinted, .sortedKeys]
        return e
    }()

    static let decoder: JSONDecoder = {
        let d = JSONDecoder()
        d.dateDecodingStrategy = .iso8601
        return d
    }()

    // MARK: Images

    private static let cache = NSCache<NSString, UIImage>()

    static func saveImage(_ image: UIImage) throws -> String {
        let name = UUID().uuidString + ".jpg"
        let small = image.resized(maxDimension: 1440)
        guard let data = small.jpegData(compressionQuality: 0.85) else {
            throw CocoaError(.fileWriteUnknown)
        }
        try data.write(to: imagesDir.appendingPathComponent(name), options: .atomic)
        cache.setObject(small, forKey: name as NSString)
        return name
    }

    static func loadImage(named name: String) -> UIImage? {
        if let hit = cache.object(forKey: name as NSString) { return hit }
        guard let img = UIImage(contentsOfFile: imagesDir.appendingPathComponent(name).path) else { return nil }
        cache.setObject(img, forKey: name as NSString)
        return img
    }

    // MARK: Film rolls

    static func saveRoll(_ roll: FilmRoll) throws {
        let data = try encoder.encode(roll)
        try data.write(to: rollsDir.appendingPathComponent("roll_\(roll.id.uuidString).json"), options: .atomic)
    }

    static func loadRolls() -> [FilmRoll] {
        let files = (try? fm.contentsOfDirectory(at: rollsDir, includingPropertiesForKeys: nil)) ?? []
        return files
            .filter { $0.pathExtension == "json" }
            .compactMap { try? decoder.decode(FilmRoll.self, from: Data(contentsOf: $0)) }
            .sorted { $0.endedAt > $1.endedAt }
    }

    // MARK: Open window

    static func saveCurrent(_ window: MomentWindow?) {
        guard let window else {
            try? fm.removeItem(at: currentURL)
            return
        }
        if let data = try? encoder.encode(window) {
            try? data.write(to: currentURL, options: .atomic)
        }
    }

    static func loadCurrent() -> MomentWindow? {
        guard let data = try? Data(contentsOf: currentURL) else { return nil }
        return try? decoder.decode(MomentWindow.self, from: data)
    }
}
