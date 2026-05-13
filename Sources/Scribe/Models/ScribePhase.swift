import Foundation

/// The Top Strip redesign organises the entire UI around three mutually-
/// exclusive phases. Everything else — chrome treatment, body view, footer
/// hints — is a function of which phase the workspace is currently in.
enum ScribePhase: Sendable, Equatable {
    /// No audio loaded yet. Hero is the drop disc.
    case idle
    /// The local model is working. Hero is the live draft.
    case transcribing
    /// A transcript exists (either complete, or a partial draft preserved
    /// after a failed run). Hero is the finished/preserved transcript.
    case ready
}

extension ScribeWorkspace {
    /// Derived from the existing workspace state — no separate stored field
    /// to keep in sync. If you change the underlying state machine, update
    /// this single computed property.
    var phase: ScribePhase {
        if isTranscribing { return .transcribing }
        if transcriptDocument != nil { return .ready }
        if draftTranscriptText.isEmpty == false { return .ready }
        return .idle
    }
}
