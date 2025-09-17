import Foundation

@MainActor
final class SpeechAnalysisManager: ObservableObject {
    @Published var isAnalyzing: Bool = false
    @Published var analysisText: String?
    @Published var errorMessage: String?
    @Published var isGeneratingNativeAudio: Bool = false
    @Published var nativeSpeakerAudioURL: URL?
    @Published var nativeAudioError: String?
    @Published var lastRecordingURL: URL?

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
        lastRecordingURL = summary.url

        do {
            let response = try await client.analyze(summary: summary)
            analysisText = response
        } catch {
            errorMessage = "Analysis failed: \(error.localizedDescription)"
        }

        isAnalyzing = false
    }

    func generateNativeSpeakerAudio(for narrative: String) async {
        guard let client else {
            nativeAudioError = "Azure client is unavailable. Check your configuration."
            return
        }

        isGeneratingNativeAudio = true
        nativeAudioError = nil
        nativeSpeakerAudioURL = nil

        do {
            let audioURL = try await client.generateNativeSpeakerAudio(for: narrative)
            nativeSpeakerAudioURL = audioURL
        } catch {
            nativeAudioError = "Failed to generate native speaker audio: \(error.localizedDescription)"
        }

        isGeneratingNativeAudio = false
    }

    func reset() {
        analysisText = nil
        errorMessage = nil
        nativeSpeakerAudioURL = nil
        nativeAudioError = nil
        lastRecordingURL = nil
    }
}
