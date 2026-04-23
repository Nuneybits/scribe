import Foundation

enum ScribeError: LocalizedError {
    case unsupportedFile
    case noAudioSelected
    case emptyTranscript
    case transcriptionFailed(String)

    var errorDescription: String? {
        switch self {
        case .unsupportedFile:
            "That file type is not supported yet. Try an MP3, M4A, WAV, MP4, AIFF, or CAF recording."
        case .noAudioSelected:
            "Drop an audio file into Scribe or choose one from disk first."
        case .emptyTranscript:
            "The transcription finished, but no readable text came back."
        case .transcriptionFailed(let reason):
            "The transcription failed: \(reason)"
        }
    }
}
