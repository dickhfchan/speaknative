import Foundation

final class NarrativeViewModel: ObservableObject {
    @Published var narratives: [Narrative] = []
    @Published var selected: Narrative?

    func loadSample() {
        narratives = [
            Narrative(id: UUID(), title: "Morning Routine", content: "I wake up and make coffee.", difficulty: 1, duration: 10, nativeAudioURL: "", createdAt: Date(), updatedAt: Date()),
            Narrative(id: UUID(), title: "At the Office", content: "I work with my colleagues.", difficulty: 2, duration: 12, nativeAudioURL: "", createdAt: Date(), updatedAt: Date())
        ]
    }
}


