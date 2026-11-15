import Foundation
import AVFoundation
import MediaPlayer
import UIKit

@MainActor
final class RadioPlayer: ObservableObject {
    static let streamURL = URL(string: "https://streaming.live365.com/a08505")!
    static let nowPlayingURL = URL(string: "https://api.live365.com/station/a08505")!

    @Published var isPlaying = false
    @Published var isBuffering = false
    @Published var title = "Live from Chicago"
    @Published var artist = "WWO Radio 96.9"
    @Published var status = "Press Play to start listening"

    private var player: AVPlayer?
    private var statusObserver: NSKeyValueObservation?
    private var pollTask: Task<Void, Never>?

    init() {
        try? AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
        setupRemoteCommands()
        startPolling()
    }

    func toggle() { isPlaying ? stop() : play() }

    func play() {
        try? AVAudioSession.sharedInstance().setActive(true)
        let item = AVPlayerItem(url: Self.streamURL)
        let p = AVPlayer(playerItem: item)
        p.automaticallyWaitsToMinimizeStalling = true
        statusObserver = p.observe(\.timeControlStatus, options: [.new]) { [weak self] pl, _ in
            Task { @MainActor in self?.update(for: pl.timeControlStatus) }
        }
        player = p
        p.play()
        isPlaying = true
        isBuffering = true
        status = "Connecting…"
        updateNowPlayingInfo()
    }

    func stop() {
        player?.pause()
        player = nil
        statusObserver = nil
        isPlaying = false
        isBuffering = false
        status = "Press Play to start listening"
        MPNowPlayingInfoCenter.default().playbackState = .stopped
    }

    private func update(for s: AVPlayer.TimeControlStatus) {
        guard isPlaying else { return }
        switch s {
        case .playing: isBuffering = false; status = "Live now"
        case .waitingToPlayAtSpecifiedRate: isBuffering = true; status = "Buffering…"
        default: break
        }
        updateNowPlayingInfo()
    }

    private func setupRemoteCommands() {
        let c = MPRemoteCommandCenter.shared()
        c.playCommand.addTarget { [weak self] _ in Task { @MainActor in self?.play() }; return .success }
        c.pauseCommand.addTarget { [weak self] _ in Task { @MainActor in self?.stop() }; return .success }
        c.stopCommand.addTarget { [weak self] _ in Task { @MainActor in self?.stop() }; return .success }
        c.togglePlayPauseCommand.addTarget { [weak self] _ in Task { @MainActor in self?.toggle() }; return .success }
    }

    private func updateNowPlayingInfo() {
        var info: [String: Any] = [
            MPMediaItemPropertyTitle: title,
            MPMediaItemPropertyArtist: artist,
            MPMediaItemPropertyAlbumTitle: "WWO Radio 96.9",
            MPNowPlayingInfoPropertyIsLiveStream: true,
            MPNowPlayingInfoPropertyPlaybackRate: isPlaying ? 1.0 : 0.0
        ]
        if let img = UIImage(named: "Logo") {
            info[MPMediaItemPropertyArtwork] = MPMediaItemArtwork(boundsSize: img.size) { _ in img }
        }
        MPNowPlayingInfoCenter.default().nowPlayingInfo = info
        MPNowPlayingInfoCenter.default().playbackState = isPlaying ? .playing : .stopped
    }

    private func startPolling() {
        pollTask = Task { [weak self] in
            while !Task.isCancelled {
                await self?.fetchNowPlaying()
                try? await Task.sleep(nanoseconds: 20_000_000_000)
            }
        }
    }

    private func fetchNowPlaying() async {
        do {
            let (data, resp) = try await URLSession.shared.data(from: Self.nowPlayingURL)
            guard (resp as? HTTPURLResponse)?.statusCode == 200,
                  let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let ct = json["current-track"] as? [String: Any] else { return }
            let t = (ct["title"] as? String ?? "").trimmingCharacters(in: .whitespaces)
            let a = (ct["artist"] as? String ?? "").trimmingCharacters(in: .whitespaces)
            title = t.isEmpty ? "Live from Chicago" : t
            artist = a.isEmpty ? "WWO Radio 96.9" : a
            updateNowPlayingInfo()
        } catch { }
    }
}
