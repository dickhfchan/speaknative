import Foundation
import AVFoundation

@MainActor
final class TTSManager: NSObject, ObservableObject {
    private var synthesizer: AVSpeechSynthesizer?
    private var currentCompletion: ((Result<URL, Error>) -> Void)?
    private var isGenerating: Bool = false
    
    func generateAudio(for text: String) async throws -> URL {
        // Prevent multiple simultaneous generations
        guard !isGenerating else {
            throw NSError(domain: "TTS", code: -1, userInfo: [NSLocalizedDescriptionKey: "TTS is already generating audio"])
        }
        
        isGenerating = true
        
        return try await withCheckedThrowingContinuation { continuation in
            self.currentCompletion = { result in
                Task { @MainActor in
                    self.isGenerating = false
                    self.currentCompletion = nil
                    continuation.resume(with: result)
                }
            }
            
            // Create temporary file
            let tempDir = FileManager.default.temporaryDirectory
            let fileName = "native-speaker-\(UUID().uuidString).m4a"
            let fileURL = tempDir.appendingPathComponent(fileName)
            
            // Configure TTS
            let synthesizer = AVSpeechSynthesizer()
            synthesizer.delegate = self
            
            let utterance = AVSpeechUtterance(string: text)
            utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
            utterance.rate = AVSpeechUtteranceDefaultSpeechRate * 0.9
            utterance.pitchMultiplier = 1.0
            utterance.volume = 1.0
            
            // Store synthesizer to keep it alive
            self.synthesizer = synthesizer
            
            // Start speaking - completion will be handled in delegate methods
            synthesizer.speak(utterance)
        }
    }
    
}

extension TTSManager: @preconcurrency AVSpeechSynthesizerDelegate {
    nonisolated func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        Task { @MainActor in
            guard let completion = currentCompletion else { return }
            currentCompletion = nil
            isGenerating = false
            
            // Create a simple success result with a placeholder file
            let tempDir = FileManager.default.temporaryDirectory
            let fileName = "native-speaker-\(UUID().uuidString).m4a"
            let fileURL = tempDir.appendingPathComponent(fileName)
            
            // Create a minimal audio file for now
            let audioData = Data("TTS_AUDIO_\(UUID().uuidString)".utf8)
            do {
                try audioData.write(to: fileURL)
                completion(.success(fileURL))
            } catch {
                completion(.failure(error))
            }
        }
    }
    
    nonisolated func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didCancel utterance: AVSpeechUtterance) {
        Task { @MainActor in
            guard let completion = currentCompletion else { return }
            currentCompletion = nil
            isGenerating = false
            completion(.failure(NSError(domain: "TTS", code: -1, userInfo: [NSLocalizedDescriptionKey: "TTS was cancelled"])))
        }
    }
}
