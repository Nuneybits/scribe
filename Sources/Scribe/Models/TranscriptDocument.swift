import Foundation

struct TranscriptDocument: Equatable, Sendable {
    let language: String?
    let segments: [TranscriptSegmentModel]
    let paragraphs: [TranscriptParagraph]
    let generatedAt: Date

    var plainText: String {
        paragraphs.map(\.text).joined(separator: "\n\n")
    }
}
