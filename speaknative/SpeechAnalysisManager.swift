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
    @Published var wordLevelReport: String?
    @Published var isComparing: Bool = false

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
            await maybeRunWordLevelComparison()
        } catch {
            nativeAudioError = "Failed to generate native speaker audio: \(error.localizedDescription)"
        }

        isGeneratingNativeAudio = false
    }

    func maybeRunWordLevelComparison() async {
        guard let client else { return }
        guard let recordingURL = lastRecordingURL, let nativeURL = nativeSpeakerAudioURL else { return }

        do {
            isComparing = true
            // Direct audio-to-audio analysis with GPT-4o (no local transcription)
            let report = try await client.analyzePronunciationWithAudio(recordingURL: recordingURL, nativeURL: nativeURL)
            wordLevelReport = report
            analysisText = report
        } catch {
            errorMessage = "Word-level analysis failed: \(error.localizedDescription)"
        }
        isComparing = false
    }

    // Ensures native audio exists, then runs comparison
    func runFullAnalysisFlow(narrative: String) async {
        if nativeSpeakerAudioURL == nil {
            await generateNativeSpeakerAudio(for: narrative)
        }
        await maybeRunWordLevelComparison()
    }

    func reset() {
        analysisText = nil
        errorMessage = nil
        nativeSpeakerAudioURL = nil
        nativeAudioError = nil
        lastRecordingURL = nil
        wordLevelReport = nil
        isComparing = false
    }
}
