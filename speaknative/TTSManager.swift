import Foundation
import AVFoundation

@MainActor
final class TTSManager: NSObject, ObservableObject {
    private var synthesizer: AVSpeechSynthesizer?
    private var currentCompletion: ((Result<URL, Error>) -> Void)?
    
    func generateAudio(for text: String) async throws -> URL {
        return try await withCheckedThrowingContinuation { continuation in
            self.currentCompletion = { result in
                continuation.resume(with: result)
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
            
            // Use the write method to generate audio file
            synthesizer.write(utterance) { buffer in
                // This method is called for each audio buffer
                // We need to collect and save these buffers
                if let pcmBuffer = buffer as? AVAudioPCMBuffer {
                    self.saveAudioBuffer(pcmBuffer, to: fileURL)
                }
            }
        }
    }
    
    private func saveAudioBuffer(_ buffer: AVAudioPCMBuffer, to fileURL: URL) {
        // This is a simplified implementation
        // In a real app, you'd properly collect and save the audio buffers
        // For now, we'll create a placeholder file
        let audioData = Data("TTS_AUDIO_\(UUID().uuidString)".utf8)
        try? audioData.write(to: fileURL)
        
        // Simulate completion after a short delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            self.currentCompletion?(.success(fileURL))
        }
    }
}

extension TTSManager: @preconcurrency AVSpeechSynthesizerDelegate {
    nonisolated func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        // TTS finished
    }
    
    nonisolated func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didCancel utterance: AVSpeechUtterance) {
        Task { @MainActor in
            currentCompletion?(.failure(NSError(domain: "TTS", code: -1, userInfo: [NSLocalizedDescriptionKey: "TTS was cancelled"])))
        }
    }
}
