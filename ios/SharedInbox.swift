import Foundation

enum SharedInbox {
    static let group = "group.de.clipfolio.clipfolio"
    static let defaults = UserDefaults(suiteName: group)
    static var folder: URL {
        get throws {
            guard let container = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: group) else {
                throw CocoaError(.fileNoSuchFile)
            }
            let directory = container.appendingPathComponent("Incoming", isDirectory: true)
            try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
            return directory
        }
    }

    static func files() throws -> [URL] {
        try FileManager.default.contentsOfDirectory(at: folder, includingPropertiesForKeys: nil)
            .filter { $0.pathExtension == "json" }
    }

    static func tagNames() -> [String] {
        var names = defaults?.stringArray(forKey: "tags") ?? ["Workout", "Rezepte", "Laufen", "Inspiration"]
        // Another share can arrive before the library has been opened.
        for file in (try? files()) ?? [] {
            guard let data = try? Data(contentsOf: file),
                  let item = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let tags = item["tags"] as? [String] else { continue }
            for tag in tags where !names.contains(where: { $0.caseInsensitiveCompare(tag) == .orderedSame }) {
                names.append(tag)
            }
        }
        return names
    }
}
