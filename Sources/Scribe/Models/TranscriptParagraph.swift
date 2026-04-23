import Foundation

struct TranscriptParagraph: Identifiable, Equatable, Sendable {
    let id: UUID
    let text: String
    let startTime: TimeInterval
    let endTime: TimeInterval
    let segmentIDs: [Int]

    init(
        id: UUID = UUID(),
        text: String,
        startTime: TimeInterval,
        endTime: TimeInterval,
        segmentIDs: [Int]
    ) {
        self.id = id
        self.text = text
        self.startTime = startTime
        self.endTime = endTime
        self.segmentIDs = segmentIDs
    }
}
