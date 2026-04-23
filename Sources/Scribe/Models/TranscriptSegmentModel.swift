import Foundation

struct TranscriptSegmentModel: Identifiable, Equatable, Sendable {
    let id: Int
    let text: String
    let startTime: TimeInterval
    let endTime: TimeInterval
}
