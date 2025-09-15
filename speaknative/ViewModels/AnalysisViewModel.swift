import Foundation

final class AnalysisViewModel: ObservableObject {
    @Published var result: AnalysisResult?
    @Published var isLoading = false
    private let service = SpeechAnalysisService()

    @MainActor
    func analyze(audioURL: URL, expectedText: String) async {
        isLoading = true
        defer { isLoading = false }
        do {
            let res = try await service.analyze(audioFileURL: audioURL, expectedText: expectedText)
            result = res
        } catch {
            result = nil
        }
    }
}


