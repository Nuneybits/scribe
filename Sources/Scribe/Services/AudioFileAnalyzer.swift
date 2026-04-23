import AVFoundation
import Foundation

enum AudioFileAnalyzer {
    static func analyze(url: URL) async -> AudioSource {
        let fileSizeDescription = describeFileSize(for: url)
        let formatDescription = url.pathExtension.uppercased().isEmpty ? "Audio" : url.pathExtension.uppercased()
        let durationDescription = await describeDuration(for: url)

        return AudioSource(
            url: url,
            fileSizeDescription: fileSizeDescription,
            durationDescription: durationDescription,
            formatDescription: formatDescription
        )
    }

    private static func describeFileSize(for url: URL) -> String {
        let values = try? url.resourceValues(forKeys: [.fileSizeKey])
        let byteCount = Int64(values?.fileSize ?? 0)
        guard byteCount > 0 else { return "Unknown size" }

        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useKB, .useMB, .useGB]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: byteCount)
    }

    private static func describeDuration(for url: URL) async -> String {
        let asset = AVURLAsset(url: url)
        guard let duration = try? await asset.load(.duration) else {
            return "Unknown length"
        }

        let totalSeconds = CMTimeGetSeconds(duration)
        guard totalSeconds.isFinite, totalSeconds > 0 else {
            return "Unknown length"
        }

        let formatter = DateComponentsFormatter()
        formatter.unitsStyle = .abbreviated
        formatter.allowedUnits = totalSeconds >= 3600 ? [.hour, .minute, .second] : [.minute, .second]
        return formatter.string(from: totalSeconds) ?? "Unknown length"
    }
}
