import Foundation

enum ScribeTimeFormatter {
    static func playback(_ interval: TimeInterval) -> String {
        let totalSeconds = max(0, Int(interval.rounded()))
        let hours = totalSeconds / 3600
        let minutes = (totalSeconds % 3600) / 60
        let seconds = totalSeconds % 60

        if hours > 0 {
            return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
        }

        return String(format: "%02d:%02d", minutes, seconds)
    }

    static func subtitle(_ interval: TimeInterval) -> String {
        let bounded = max(0, interval)
        let totalMilliseconds = Int((bounded * 1000).rounded())
        let hours = totalMilliseconds / 3_600_000
        let minutes = (totalMilliseconds % 3_600_000) / 60_000
        let seconds = (totalMilliseconds % 60_000) / 1_000
        let milliseconds = totalMilliseconds % 1_000

        return String(format: "%02d:%02d:%02d,%03d", hours, minutes, seconds, milliseconds)
    }
}
