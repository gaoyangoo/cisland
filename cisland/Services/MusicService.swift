import Foundation
import SwiftUI

class MusicService: ObservableObject {
    @Published var musicInfo: MusicInfo
    @Published var isLoading: Bool = false

    private let scriptPath: String
    private var timer: Timer?

    init(scriptPath: String = "/Users/claus/code/claude_code/island/cisland/cisland/hooks/nowplaying.swift") {
        self.scriptPath = scriptPath
        self.musicInfo = MusicInfo(artist: "Unknown", album: "Unknown", title: "No track playing", duration: 0, position: 0, state: "stopped")
    }

    func start() {
        fetchMusicInfo()
        timer = Timer.scheduledTimer(withTimeInterval: 10.0, repeats: true) { [weak self] _ in
            self?.fetchMusicInfo()
        }
    }

    func stop() {
        timer?.invalidate()
        timer = nil
    }

    deinit {
        stop()
    }

    private func fetchMusicInfo() {
        isLoading = true

        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }

            let process = Process()
            process.executableURL = URL(fileURLWithPath: "/usr/bin/osascript")

            let scriptCommand = """
            do shell script "\(self.scriptPath)"
            """

            process.arguments = ["-e", scriptCommand]

            let pipe = Pipe()
            process.standardOutput = pipe
            process.standardError = pipe

            do {
                try process.run()
                process.waitUntilExit()
                let data = pipe.fileHandleForReading.readDataToEndOfFile()
                if let output = String(data: data, encoding: .utf8) {
                    DispatchQueue.main.async {
                        self.parseMusicInfo(output)
                        self.isLoading = false
                    }
                }
            } catch {
                DispatchQueue.main.async {
                    self.musicInfo = MusicInfo(artist: "Unknown", album: "Unknown", title: "Error fetching music info", duration: 0, position: 0, state: "stopped")
                    self.isLoading = false
                }
            }
        }
    }

    private func parseMusicInfo(_ jsonString: String) {
        let decoder = JSONDecoder()
        do {
            // Clean up JSON string
            let cleaned = jsonString.trimmingCharacters(in: .whitespacesAndNewlines)
            if let data = cleaned.data(using: .utf8) {
                let musicInfo = try decoder.decode(MusicInfo.self, from: data)
                self.musicInfo = musicInfo
            }
        } catch {
            // Keep current info on error
            print("Error parsing music info: \(error)")
        }
    }
}

struct MusicInfo: Codable, Hashable {
    let artist: String
    let album: String
    let title: String
    let duration: Double
    let position: Double
    let state: String

    var progress: Double {
        guard duration > 0 else { return 0 }
        return min(max(position / duration, 0), 1)
    }

    var isPlaying: Bool {
        return state == "playing"
    }
}