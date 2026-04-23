import Foundation
import WhisperKit

struct WhisperKitProgressUpdate: Sendable {
    let phaseDescription: String
    let fractionCompleted: Double?
    let partialSegments: [TranscriptSegmentModel]
}

final class WhisperKitTranscriptionService {
    private let modelVariant = "openai_whisper-small.en"
    private let modelRepo = "argmaxinc/whisperkit-coreml"
    private var whisperKit: WhisperKit?

    func transcribe(
        audioURL: URL,
        progress: @escaping @Sendable (WhisperKitProgressUpdate) -> Void
    ) async throws -> TranscriptDocument {
        let kit = try await prepareWhisperKit(progress: progress)

        progress(
            WhisperKitProgressUpdate(
                phaseDescription: "Transcribing audio locally…",
                fractionCompleted: 0,
                partialSegments: []
            )
        )

        kit.transcriptionStateCallback = { state in
            progress(
                WhisperKitProgressUpdate(
                    phaseDescription: state.description,
                    fractionCompleted: nil,
                    partialSegments: []
                )
            )
        }

        kit.segmentDiscoveryCallback = { segments in
            let mapped = Self.mapSegments(segments)

            let lastEndTime = mapped.last?.endTime ?? 0
            let totalAudio = max(0.001, kit.currentTimings.inputAudioSeconds)
            let fractionCompleted = min(1, lastEndTime / totalAudio)

            progress(
                WhisperKitProgressUpdate(
                    phaseDescription: "Transcribing audio locally…",
                    fractionCompleted: fractionCompleted,
                    partialSegments: mapped
                )
            )
        }

        let decodeOptions = DecodingOptions(
            verbose: false,
            task: .transcribe,
            language: "en",
            skipSpecialTokens: true,
            wordTimestamps: false
        )

        let results = try await kit.transcribe(audioPath: audioURL.path, decodeOptions: decodeOptions) { _ in
            return true
        }

        let segments = Self.mapSegments(results.flatMap(\.segments))

        let paragraphs = ParagraphGrouper.group(segments: segments)

        progress(
            WhisperKitProgressUpdate(
                phaseDescription: "Transcript ready.",
                fractionCompleted: 1,
                partialSegments: segments
            )
        )

        return TranscriptDocument(
            language: results.first?.language,
            segments: segments,
            paragraphs: paragraphs,
            generatedAt: .now
        )
    }

    private func prepareWhisperKit(
        progress: @escaping @Sendable (WhisperKitProgressUpdate) -> Void
    ) async throws -> WhisperKit {
        if let whisperKit {
            return whisperKit
        }

        let downloadBase = try modelBaseURL()

        progress(
            WhisperKitProgressUpdate(
                phaseDescription: "Preparing the local model…",
                fractionCompleted: nil,
                partialSegments: []
            )
        )

        let modelFolder = try await WhisperKit.download(
            variant: modelVariant,
            downloadBase: downloadBase,
            from: modelRepo
        ) { downloadProgress in
            progress(
                WhisperKitProgressUpdate(
                    phaseDescription: "Downloading the local model…",
                    fractionCompleted: downloadProgress.fractionCompleted,
                    partialSegments: []
                )
            )
        }

        let config = WhisperKitConfig(
            model: modelVariant,
            downloadBase: downloadBase,
            modelRepo: modelRepo,
            modelFolder: modelFolder.path,
            verbose: false,
            logLevel: .none,
            prewarm: false,
            load: true,
            download: false
        )

        let whisperKit = try await WhisperKit(config)
        self.whisperKit = whisperKit
        return whisperKit
    }

    private func modelBaseURL() throws -> URL {
        let applicationSupport = try FileManager.default.url(
            for: .applicationSupportDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
        )
        let baseURL = applicationSupport.appendingPathComponent("Scribe", isDirectory: true)
        try FileManager.default.createDirectory(at: baseURL, withIntermediateDirectories: true, attributes: nil)
        return baseURL
    }

    private static func mapSegments(_ segments: [TranscriptionSegment]) -> [TranscriptSegmentModel] {
        segments.compactMap { segment in
            let cleanedText = TranscriptFormatter.cleanSegment(segment.text)
            guard cleanedText.isEmpty == false else { return nil }

            return TranscriptSegmentModel(
                id: segment.id,
                text: cleanedText,
                startTime: TimeInterval(segment.start),
                endTime: TimeInterval(segment.end)
            )
        }
    }
}
