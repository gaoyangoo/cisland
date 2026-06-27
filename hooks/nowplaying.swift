import Foundation

guard let h = dlopen(
    "/System/Library/PrivateFrameworks/MediaRemote.framework/MediaRemote", RTLD_NOW
) else { exit(0) }

typealias MRBlock = @convention(block) (NSDictionary) -> Void
typealias MRFunc  = @convention(c) (DispatchQueue, MRBlock) -> Void
let fn = unsafeBitCast(dlsym(h, "MRMediaRemoteGetNowPlayingInfo")!, to: MRFunc.self)

var result: NSDictionary?
fn(.main, { info in result = info } as MRBlock)

let deadline = Date().addingTimeInterval(2)
while result == nil && Date() < deadline {
    RunLoop.main.run(mode: .default, before: Date().addingTimeInterval(0.05))
}

guard let info = result else { exit(0) }

let t = info["kMRMediaRemoteNowPlayingInfoTitle"]  as? String ?? ""
let a = info["kMRMediaRemoteNowPlayingInfoArtist"] as? String ?? ""
let b = info["kMRMediaRemoteNowPlayingInfoAlbum"]  as? String ?? ""
let u = info["kMRMediaRemoteNowPlayingInfoDuration"] as? Double ?? 0
let p = info["kMRMediaRemoteNowPlayingInfoElapsedTime"] as? Double ?? 0
let q = info["kMRMediaRemoteNowPlayingInfoPlaybackRate"] as? Double ?? 0

// Artwork — some apps/macOS provide it as raw data (try both Data and NSData)
var artBase64 = ""
let artKey = "kMRMediaRemoteNowPlayingInfoArtworkData"
if let artData = info[artKey] as? Data {
    artBase64 = artData.base64EncodedString()
} else if let artNSData = info[artKey] as? NSData {
    artBase64 = (artNSData as Data).base64EncodedString()
} else if let artObj = (info as NSObject).value(forKey: artKey) as? NSData {
    artBase64 = (artObj as Data).base64EncodedString()
}

var o: [String: Any] = [
    "artist": a,
    "album": b,
    "title": t.isEmpty ? "Unknown" : t,
    "duration": u,
    "position": p,
    "state": q > 0 ? "playing" : "stopped",
    "artwork": artBase64
]

if let d = try? JSONSerialization.data(withJSONObject: o) {
    print(String(data: d, encoding: .utf8)!)
}
