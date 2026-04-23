import Testing
@testable import Scribe

@Test
func paragraphGrouperStartsNewParagraphAfterLongPause() {
    let segments = [
        TranscriptSegmentModel(id: 1, text: "First part.", startTime: 0, endTime: 1.0),
        TranscriptSegmentModel(id: 2, text: "Still same paragraph.", startTime: 1.1, endTime: 2.0),
        TranscriptSegmentModel(id: 3, text: "New paragraph.", startTime: 3.5, endTime: 4.1)
    ]

    let paragraphs = ParagraphGrouper.group(segments: segments, pauseThreshold: 1.2, maxWords: 90)

    #expect(paragraphs.count == 2)
    #expect(paragraphs[0].text == "First part. Still same paragraph.")
    #expect(paragraphs[1].startTime == 3.5)
}

@Test
func transcriptExporterProducesSRTWithSegmentTimestamps() {
    let segments = [
        TranscriptSegmentModel(id: 1, text: "Hello world.", startTime: 0.0, endTime: 1.2),
        TranscriptSegmentModel(id: 2, text: "Second line.", startTime: 1.3, endTime: 2.8)
    ]

    let document = TranscriptDocument(
        language: "en",
        segments: segments,
        paragraphs: ParagraphGrouper.group(segments: segments),
        generatedAt: .now
    )

    let srt = TranscriptExporter.srt(document)

    #expect(srt.contains("00:00:00,000 --> 00:00:01,200"))
    #expect(srt.contains("00:00:01,300 --> 00:00:02,800"))
    #expect(srt.contains("Second line."))
}

@Test
func transcriptDisplayFormatterAddsSparseTimestampsForCopy() {
    let paragraphs = [
        TranscriptParagraph(text: "Opening paragraph.", startTime: 0, endTime: 10, segmentIDs: [1]),
        TranscriptParagraph(text: "Middle paragraph.", startTime: 120, endTime: 140, segmentIDs: [2]),
        TranscriptParagraph(text: "Five minute marker.", startTime: 305, endTime: 320, segmentIDs: [3])
    ]

    let document = TranscriptDocument(
        language: "en",
        segments: [],
        paragraphs: paragraphs,
        generatedAt: .now
    )

    let copied = TranscriptDisplayFormatter.copyText(from: document, totalDuration: 1800)

    #expect(copied.contains("[00:00] Opening paragraph."))
    #expect(copied.contains("[05:05] Five minute marker."))
    #expect(copied.contains("\n\nMiddle paragraph."))
}

@Test
func transcriptExporterAddsSparseTimestampsToPlainText() {
    let paragraphs = [
        TranscriptParagraph(text: "Opening paragraph.", startTime: 0, endTime: 10, segmentIDs: [1]),
        TranscriptParagraph(text: "Middle paragraph.", startTime: 120, endTime: 140, segmentIDs: [2]),
        TranscriptParagraph(text: "Five minute marker.", startTime: 305, endTime: 320, segmentIDs: [3])
    ]

    let document = TranscriptDocument(
        language: "en",
        segments: [],
        paragraphs: paragraphs,
        generatedAt: .now
    )

    let exported = TranscriptExporter.contents(for: document, format: .plainText)

    #expect(exported.contains("[00:00] Opening paragraph."))
    #expect(exported.contains("[05:05] Five minute marker."))
    #expect(exported.contains("\n\nMiddle paragraph."))
}
