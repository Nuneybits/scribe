import AppKit
import Foundation
import Observation
import UniformTypeIdentifiers

@MainActor
@Observable
final class ScribeWorkspace {
    var selectedAudio: AudioSource?
    var transcriptDocument: TranscriptDocument?
    var draftTranscriptText = ""
    var statusLine = "Drop in a voice memo and Scribe will turn it into a readable local transcript."
    var isTargeted = false
    var isTranscribing = false
    var progressFraction: Double?
    var transcriptionStartedAt: Date?
    var lastTranscriptDate: Date?
    var warningMessage: String?
    var errorMessage: String?

    let playback = AudioPlaybackController()
    nonisolated(unsafe) private let transcriptionService = WhisperKitTranscriptionService()
    private var lastPartialRenderAt: Date?
    private var lastPartialParagraphCount = 0
    private var previewSegmentIndex: [String: TranscriptSegmentModel] = [:]
    private var furthestPreviewTime: TimeInterval = 0

    let supportedTypes = ["mp3", "m4a", "wav", "mp4", "aiff", "caf", "aac", "mov"]

    var transcriptText: String {
        if let transcriptDocument {
            return transcriptDocument.plainText
        }

        return draftTranscriptText
    }

    func importAudio(from urls: [URL]) async {
        guard let firstURL = urls.first else { return }
        guard supportedTypes.contains(firstURL.pathExtension.lowercased()) else {
            errorMessage = ScribeError.unsupportedFile.localizedDescription
            statusLine = "Scribe accepts common audio files and iPhone Voice Memos exports."
            return
        }

        selectedAudio = await AudioFileAnalyzer.analyze(url: firstURL)
        transcriptDocument = nil
        draftTranscriptText = ""
        warningMessage = nil
        progressFraction = nil
        errorMessage = nil
        lastTranscriptDate = nil

        do {
            try playback.load(url: firstURL)
        } catch {
            errorMessage = error.localizedDescription
        }

        statusLine = "Loaded \(firstURL.lastPathComponent)."
        await transcribeSelectedAudio()
    }

    func selectAudioWithOpenPanel() async {
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        panel.canChooseFiles = true
        panel.allowedContentTypes = [
            .audio,
            .mpeg4Audio,
            .wav,
            .aiff,
            .quickTimeMovie,
            .mpeg4Movie
        ]

        if panel.runModal() == .OK, let url = panel.url {
            await importAudio(from: [url])
        }
    }

    func transcribeSelectedAudio() async {
        guard let selectedAudio else {
            errorMessage = ScribeError.noAudioSelected.localizedDescription
            return
        }

        isTranscribing = true
        errorMessage = nil
        warningMessage = nil
        progressFraction = nil
        transcriptDocument = nil
        draftTranscriptText = ""
        transcriptionStartedAt = .now
        lastPartialRenderAt = nil
        lastPartialParagraphCount = 0
        previewSegmentIndex = [:]
        furthestPreviewTime = 0
        statusLine = "Preparing \(selectedAudio.url.lastPathComponent)…"

        do {
            let result = try await transcriptionService.transcribe(audioURL: selectedAudio.url) { [weak self] update in
                Task { @MainActor in
                    guard let self else { return }
                    self.statusLine = self.statusText(for: update)

                    if update.partialSegments.isEmpty == false {
                        self.furthestPreviewTime = max(
                            self.furthestPreviewTime,
                            update.partialSegments.map(\.endTime).max() ?? 0
                        )
                        let groupedParagraphs = self.previewParagraphs(from: self.accumulatedPreviewSegments(with: update.partialSegments))
                        let nextDraft = groupedParagraphs
                            .map(\.text)
                            .joined(separator: "\n\n")

                        if self.shouldApplyPartialTranscriptUpdate(nextDraft, paragraphCount: groupedParagraphs.count) {
                            self.draftTranscriptText = nextDraft
                        }
                    }

                    self.progressFraction = self.displayProgress(for: update)
                }
            }

            guard result.paragraphs.isEmpty == false else {
                throw ScribeError.emptyTranscript
            }

            transcriptDocument = result
            draftTranscriptText = result.plainText
            lastTranscriptDate = result.generatedAt
            progressFraction = 1
            transcriptionStartedAt = nil
            statusLine = "Transcript ready."
        } catch {
            warningMessage = draftTranscriptText.isEmpty ? nil : "Transcription stopped early. The partial transcript is still available."
            errorMessage = error.localizedDescription
            progressFraction = nil
            transcriptionStartedAt = nil
            statusLine = draftTranscriptText.isEmpty ? "The transcription hit a snag." : "Transcription stopped early, but your text was preserved."
        }

        isTranscribing = false
    }

    private func shouldApplyPartialTranscriptUpdate(_ nextDraft: String, paragraphCount: Int) -> Bool {
        guard nextDraft.isEmpty == false else { return false }
        guard nextDraft != draftTranscriptText else { return false }

        let now = Date()
        let timeElapsed = now.timeIntervalSince(lastPartialRenderAt ?? .distantPast)
        let characterDelta = nextDraft.count - draftTranscriptText.count
        let paragraphDelta = paragraphCount - lastPartialParagraphCount

        let shouldApply =
            draftTranscriptText.isEmpty ||
            timeElapsed >= 4.5 ||
            paragraphDelta >= 2 ||
            characterDelta >= 900

        if shouldApply {
            lastPartialRenderAt = now
            lastPartialParagraphCount = paragraphCount
        }

        return shouldApply
    }

    private func previewParagraphs(from segments: [TranscriptSegmentModel]) -> [TranscriptParagraph] {
        let orderedSegments = segments.sorted {
            if $0.startTime == $1.startTime {
                if $0.endTime == $1.endTime {
                    return $0.id < $1.id
                }
                return $0.endTime < $1.endTime
            }
            return $0.startTime < $1.startTime
        }

        let groupedParagraphs = ParagraphGrouper.group(segments: orderedSegments)

        // Keep the preview stable by preferring completed-looking paragraphs while transcription is in flight.
        if isTranscribing, groupedParagraphs.count > 1 {
            return Array(groupedParagraphs.dropLast())
        }

        return groupedParagraphs
    }

    private func accumulatedPreviewSegments(with incomingSegments: [TranscriptSegmentModel]) -> [TranscriptSegmentModel] {
        for segment in incomingSegments {
            previewSegmentIndex[previewKey(for: segment)] = segment
        }

        return Array(previewSegmentIndex.values)
    }

    private func previewKey(for segment: TranscriptSegmentModel) -> String {
        let start = Int((segment.startTime * 100).rounded())
        let end = Int((segment.endTime * 100).rounded())
        return "\(start)-\(end)"
    }

    private func displayProgress(for update: WhisperKitProgressUpdate) -> Double? {
        let phase = update.phaseDescription.lowercased()
        let totalDuration = max(playback.duration, 1)

        if phase.contains("downloading") {
            let downloadProgress = update.fractionCompleted ?? 0
            return 0.02 + (0.10 * downloadProgress)
        }

        if phase.contains("preparing") || phase.contains("prewarm") || phase.contains("load") {
            return 0.12
        }

        if phase.contains("convert") || phase.contains("audioencoder") || phase.contains("mel") {
            return 0.20
        }

        if phase.contains("decoding") {
            return 0.94
        }

        if phase.contains("ready") || phase.contains("finished") {
            return 1
        }

        if phase.contains("transcribing") || update.partialSegments.isEmpty == false {
            let transcriptProgress = min(1, furthestPreviewTime / totalDuration)
            return 0.20 + (0.70 * transcriptProgress)
        }

        return nil
    }

    private func statusText(for update: WhisperKitProgressUpdate) -> String {
        let phase = update.phaseDescription.lowercased()

        if phase.contains("downloading") {
            if let progressFraction = update.fractionCompleted {
                return "Downloading model \(Int(progressFraction * 100))%"
            }
            return "Downloading model"
        }

        if phase.contains("preparing") || phase.contains("prewarm") || phase.contains("load") {
            return "Preparing local model"
        }

        if phase.contains("convert") || phase.contains("audioencoder") || phase.contains("mel") {
            return "Reading audio"
        }

        if phase.contains("decoding") {
            return "Refining transcript"
        }

        if phase.contains("transcribing") || update.partialSegments.isEmpty == false {
            return "Transcribing locally"
        }

        if phase.contains("ready") || phase.contains("finished") {
            return "Transcript ready."
        }

        return update.phaseDescription
    }

    func exportTranscript(_ format: TranscriptExportFormat) {
        guard let transcriptDocument else { return }

        let panel = NSSavePanel()
        panel.canCreateDirectories = true
        let baseName = selectedAudio?.url.deletingPathExtension().lastPathComponent ?? "scribe-transcript"
        panel.nameFieldStringValue = "\(baseName).\(format.fileExtension)"
        panel.allowedContentTypes = [.plainText]

        guard panel.runModal() == .OK, let url = panel.url else { return }

        do {
            let contents = TranscriptExporter.contents(for: transcriptDocument, format: format)
            try contents.write(to: url, atomically: true, encoding: .utf8)
            statusLine = "Saved transcript to \(url.lastPathComponent)."
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func copyTranscript() {
        let copyText: String
        if let transcriptDocument {
            copyText = TranscriptDisplayFormatter.copyText(
                from: transcriptDocument,
                totalDuration: max(playback.duration, transcriptDocument.paragraphs.last?.endTime ?? 0)
            )
        } else {
            guard transcriptText.isEmpty == false else { return }
            copyText = transcriptText
        }

        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(copyText, forType: .string)
        statusLine = "Transcript copied with timestamps."
    }

    func seekToParagraph(_ paragraph: TranscriptParagraph) {
        playback.seek(to: paragraph.startTime)
        statusLine = "Jumped to \(ScribeTimeFormatter.playback(paragraph.startTime))."
    }
}
