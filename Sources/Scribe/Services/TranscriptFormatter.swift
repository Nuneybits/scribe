import Foundation

enum TranscriptFormatter {
    static func cleanSegment(_ rawText: String) -> String {
        let strippedTokens = rawText.replacingOccurrences(
            of: #"<\|[^|]+?\|>"#,
            with: " ",
            options: .regularExpression
        )

        let normalizedWhitespace = strippedTokens.replacingOccurrences(
            of: #"\s+"#,
            with: " ",
            options: .regularExpression
        )

        let normalizedPunctuationSpacing = normalizedWhitespace
            .replacingOccurrences(of: #" \."#, with: ".", options: .regularExpression)
            .replacingOccurrences(of: #" ,"#, with: ",", options: .regularExpression)
            .replacingOccurrences(of: #" \?"#, with: "?", options: .regularExpression)
            .replacingOccurrences(of: #" !"#, with: "!", options: .regularExpression)
            .replacingOccurrences(of: #" :"#, with: ":", options: .regularExpression)
            .replacingOccurrences(of: #" ;"#, with: ";", options: .regularExpression)

        return normalizedPunctuationSpacing.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    static func clean(_ rawText: String) -> String {
        let normalizedLineEndings = rawText
            .replacingOccurrences(of: "\r\n", with: "\n")
            .split(separator: "\n", omittingEmptySubsequences: false)
            .map { cleanSegment(String($0)) }
            .joined(separator: "\n")

        let lines = normalizedLineEndings
            .split(separator: "\n", omittingEmptySubsequences: false)
            .map { $0.trimmingCharacters(in: .whitespaces) }

        var collapsedLines: [String] = []
        var previousWasBlank = false

        for line in lines {
            let isBlank = line.isEmpty
            if isBlank, previousWasBlank {
                continue
            }

            collapsedLines.append(line)
            previousWasBlank = isBlank
        }

        return collapsedLines
            .joined(separator: "\n")
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
