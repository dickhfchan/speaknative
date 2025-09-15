import Foundation

struct QueuedAnalysis: Codable, Equatable {
    let id: UUID
    let audioURL: URL
    let expectedText: String
    let enqueuedAt: Date
}

final class OfflineQueueService {
    private let queueKey = "offline.queue"
    private let analysis = SpeechAnalysisService()

    func enqueue(audioURL: URL, expectedText: String) {
        var queue = loadQueue()
        queue.append(QueuedAnalysis(id: UUID(), audioURL: audioURL, expectedText: expectedText, enqueuedAt: Date()))
        saveQueue(queue)
    }

    func dequeue() -> QueuedAnalysis? {
        var queue = loadQueue()
        guard !queue.isEmpty else { return nil }
        let item = queue.removeFirst()
        saveQueue(queue)
        return item
    }

    func loadQueue() -> [QueuedAnalysis] {
        guard let data = UserDefaults.standard.data(forKey: queueKey) else { return [] }
        return (try? JSONDecoder().decode([QueuedAnalysis].self, from: data)) ?? []
    }

    private func saveQueue(_ queue: [QueuedAnalysis]) {
        if let data = try? JSONEncoder().encode(queue) {
            UserDefaults.standard.set(data, forKey: queueKey)
        }
    }

    @MainActor
    func processNextIfOnline() async {
        guard let item = dequeue() else { return }
        do {
            _ = try await analysis.analyze(audioFileURL: item.audioURL, expectedText: item.expectedText)
        } catch {
            // re-enqueue on failure
            enqueue(audioURL: item.audioURL, expectedText: item.expectedText)
        }
    }
}


