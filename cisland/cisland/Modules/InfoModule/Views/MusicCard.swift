import SwiftUI

struct MusicCard: View {
    @StateObject private var musicService = MusicService()

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "music.note")
                    .foregroundColor(.primary)
                    .font(.title2)

                Text("Now Playing")
                    .font(.headline)
                    .fontWeight(.semibold)

                Spacer()

                if musicService.isLoading {
                    ProgressView()
                        .scaleEffect(0.5)
                }
            }

            Divider()

            VStack(alignment: .leading, spacing: 4) {
                Text(musicService.musicInfo.title)
                    .font(.title3)
                    .fontWeight(.medium)
                    .lineLimit(2)

                Text(musicService.musicInfo.artist)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .lineLimit(1)

                Text(musicService.musicInfo.album)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }

            if musicService.musicInfo.isPlaying {
                VStack(alignment: .leading, spacing: 4) {
                    ProgressView(value: musicService.musicInfo.progress)
                        .progressViewStyle(LinearProgressViewStyle(tint: .accentColor))

                    Text(formatTime(musicService.musicInfo.position) + " / " + formatTime(musicService.musicInfo.duration))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            } else {
                Text(musicService.musicInfo.state.capitalized)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .italic()
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 2)
    }

    private func formatTime(_ seconds: Double) -> String {
        let minutes = Int(seconds) / 60
        let remainingSeconds = Int(seconds) % 60
        return String(format: "%d:%02d", minutes, remainingSeconds)
    }
}

struct MusicCard_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
            MusicCard()
                .padding()
                .background(Color(.systemGroupedBackground))
            MusicCard()
                .padding()
                .preferredColorScheme(.dark)
        }
    }
}