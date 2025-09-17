import Foundation

@MainActor
final class SpeechAnalysisManager: ObservableObject {
    @Published var isAnalyzing: Bool = false
    @Published var analysisText: String?
    @Published var errorMessage: String?

    private let client: AzureOpenAIClient?

    init() {
        do {
            client = try AzureOpenAIClient()
        } catch {
            client = nil
            errorMessage = "Azure configuration error: \(error.localizedDescription)"
        }
    }

    func analyze(summary: SpeechPracticeRecorder.RecordingSummary) async {
        guard let client else {
            errorMessage = "Azure client is unavailable. Check your configuration."
            return
        }

        isAnalyzing = true
        errorMessage = nil

        do {
            let response = try await client.analyze(summary: summary)
            analysisText = response
        } catch {
            errorMessage = "Analysis failed: \(error.localizedDescription)"
        }

        isAnalyzing = false
    }

    func reset() {
        analysisText = nil
        errorMessage = nil
    }
}
