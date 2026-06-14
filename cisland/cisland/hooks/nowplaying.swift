#!/usr/bin/env swift

import Foundation

struct MusicInfo: Codable {
    let artist: String
    let album: String
    let title: String
    let duration: Double
    let position: Double
    let state: String // "playing" or "paused"
}

extension MusicInfo {
    func jsonEncoded() -> String {
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        if let data = try? encoder.encode(self) {
            return String(data: data, encoding: .utf8) ?? "{}"
        }
        return "{}"
    }
}

// Use osascript to get Music app info
let script = """
tell application "Music"
    if it is running then
        if player state is not stopped then
            set currentTrack to current track
            set artist to artist of currentTrack
            set album to album of currentTrack
            set title to name of currentTrack
            set duration to duration of currentTrack
            set position to player position

            if player state is playing then
                set state to "playing"
            else
                set state to "paused"
            end if

            return "{\"artist\":\"\" & artist,\"album\":\"\" & album,\"title\":\"\" & title,\"duration\":" & duration & ",\"position\":" & position & ",\"state\":\"\" & state & "}"
        else
            return "{\"artist\":\"Unknown\",\"album\":\"Unknown\",\"title\":\"No track playing\",\"duration\":0,\"position\":0,\"state\":\"stopped\"}"
        end if
    else
        return "{\"artist\":\"Unknown\",\"album\":\"Unknown\",\"title\":\"Music app not running\",\"duration\":0,\"position\":0,\"state\":\"stopped\"}"
    end if
end tell
"""

let appleScript = NSAppleScript(source: script)
if let output = appleScript?.executeAndReturnError(nil),
   let jsonString = output.stringValue {
    // Extract JSON from AppleScript output
    let jsonStart = jsonString.range(of: "{\"")?.lowerBound
    let jsonEnd = jsonString.range(of: "\"}")?.upperBound
    if let start = jsonStart, let end = jsonEnd {
        let json = String(jsonString[start..<end])
        print(json)
    }
} else {
    // Fallback to default values
    print(MusicInfo(artist: "Unknown", album: "Unknown", title: "Music app not running", duration: 0, position: 0, state: "stopped").jsonEncoded())
}