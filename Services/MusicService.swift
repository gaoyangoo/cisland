import Foundation
import SwiftUI

class MusicService: ObservableObject {
    static let shared = MusicService()

    @Published var musicInfo = MusicInfo(title: "No track playing")
    @Published var artwork: NSImage?
    @Published var isLoading = false

    private var timer: Timer?
    private var fetchTask: Process?

    private init() {}

    func start() {
        guard timer == nil else { return }
        fetch()
        timer = Timer.scheduledTimer(withTimeInterval: 5, repeats: true) { [weak self] _ in
            self?.fetch()
        }
    }

    func stop() { timer?.invalidate(); timer = nil }
    deinit { stop() }

    private func fetch() {
        DispatchQueue.global(qos: .utility).async { [weak self] in
            guard let self else { return }
            guard let json = runNowPlayingScript(),
                  let d = json.data(using: .utf8),
                  let info = try? JSONDecoder().decode(MusicInfo.self, from: d) else { return }
            DispatchQueue.main.async {
                self.musicInfo = info
                if !info.artwork.isEmpty,
                   let d = Data(base64Encoded: info.artwork),
                   let img = NSImage(data: d) {
                    self.artwork = img
                }
            }
        }
    }
}

// MARK: - Helper script (run via /usr/bin/swift — Apple binary with entitlements)

private func runNowPlayingScript() -> String? {
    let src = helperScriptPath()
    guard FileManager.default.fileExists(atPath: src) else { return nil }

    let task = Process()
    task.executableURL = URL(fileURLWithPath: "/usr/bin/swift")
    task.arguments = [src]
    let pipe = Pipe()
    task.standardOutput = pipe
    task.standardError = FileHandle.nullDevice
    do {
        try task.run()
        task.waitUntilExit()
        return String(data: pipe.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8)?
            .trimmingCharacters(in: .whitespacesAndNewlines)
    } catch { return nil }
}

private func helperScriptPath() -> String {
    return Bundle.main.bundlePath + "/Contents/Resources/hooks/nowplaying.swift"
}

// MARK: - Model

struct MusicInfo: Codable, Hashable {
    var artist = ""
    var album = ""
    var title = "No track playing"
    var duration = 0.0
    var position = 0.0
    var state = "stopped"
    var artwork = ""

    var progress: Double {
        guard duration > 0 else { return 0 }
        return min(max(position / duration, 0), 1)
    }
    var isPlaying: Bool { state == "playing" }
}
