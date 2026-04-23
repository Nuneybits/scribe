import Foundation

struct AudioSource: Identifiable, Equatable {
    let id = UUID()
    let url: URL
    let fileSizeDescription: String
    let durationDescription: String
    let formatDescription: String
}
