import Testing
@testable import Scribe

@Test
func transcriptFormatterCollapsesRepeatedBlankLines() {
    let raw = "  First line  \n\n\n Second line \n\n"
    let cleaned = TranscriptFormatter.clean(raw)

    #expect(cleaned == "First line\n\nSecond line")
}

@Test
func transcriptFormatterRemovesWhisperSpecialTokens() {
    let raw = "<|startoftranscript|><|0.00|> Hello there <|5.84|> world."
    let cleaned = TranscriptFormatter.cleanSegment(raw)

    #expect(cleaned == "Hello there world.")
}
