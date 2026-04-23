import AVFoundation
import Foundation
import Observation

@MainActor
@Observable
final class AudioPlaybackController: NSObject, @preconcurrency AVAudioPlayerDelegate {
    private var player: AVAudioPlayer?
    private var timer: Timer?

    var duration: TimeInterval = 0
    var currentTime: TimeInterval = 0
    var isPlaying = false
    var isLoaded = false

    func load(url: URL) throws {
        stop()

        let player = try AVAudioPlayer(contentsOf: url)
        player.delegate = self
        player.prepareToPlay()

        self.player = player
        duration = player.duration
        currentTime = 0
        isLoaded = true
    }

    func play() {
        guard let player else { return }
        player.play()
        isPlaying = true
        startTimer()
    }

    func pause() {
        player?.pause()
        isPlaying = false
        stopTimer()
        refreshTime()
    }

    func stop() {
        player?.stop()
        player?.currentTime = 0
        isPlaying = false
        refreshTime()
        stopTimer()
    }

    func seek(to time: TimeInterval) {
        guard let player else { return }
        player.currentTime = min(max(0, time), player.duration)
        refreshTime()
    }

    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        isPlaying = false
        stopTimer()
        refreshTime()
    }

    private func startTimer() {
        stopTimer()

        timer = Timer.scheduledTimer(withTimeInterval: 0.2, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.refreshTime()
            }
        }
    }

    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }

    private func refreshTime() {
        currentTime = player?.currentTime ?? 0
        duration = player?.duration ?? duration
    }
}
