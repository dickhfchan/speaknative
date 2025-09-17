import Foundation
import AVFoundation

final class TTSManager: NSObject, ObservableObject {
    private var synthesizer: AVSpeechSynthesizer?
    private var currentCompletion: ((Result<URL, Error>) -> Void)?
    private var isGenerating: Bool = false
    private var audioFile: AVAudioFile?
    private var outputURL: URL?
    private let ttsQueue = DispatchQueue(label: "TTSManager.FileWriteQueue")
    private var wroteAnyFrames: Bool = false
    private var didRetryOnce: Bool = false
    private var lastText: String?
    private var converter: AVAudioConverter?
    
    func generateAudio(for text: String) async throws -> URL {
        // Prevent multiple simultaneous generations
        // If a previous synthesis is still speaking, stop it and allow restart
        if let synthesizer, synthesizer.isSpeaking {
            synthesizer.stopSpeaking(at: .immediate)
        }
        
        guard !isGenerating else {
            throw NSError(domain: "TTS", code: -1, userInfo: [NSLocalizedDescriptionKey: "TTS is already generating audio"])
        }
        
        isGenerating = true
        didRetryOnce = false
        wroteAnyFrames = false
        lastText = text
        
        return try await withCheckedThrowingContinuation { [self] continuation in
            self.currentCompletion = { result in
                DispatchQueue.main.async { [self] in
                    self.isGenerating = false
                    self.currentCompletion = nil
                    self.audioFile = nil
                    self.outputURL = nil
                    continuation.resume(with: result)
                }
            }
            
            // Create temporary file
            let tempDir = FileManager.default.temporaryDirectory
            let fileName = "native-speaker-\(UUID().uuidString).wav"
            let fileURL = tempDir.appendingPathComponent(fileName)
            self.outputURL = fileURL
            
            // Configure TTS
            let synthesizer = AVSpeechSynthesizer()
            synthesizer.delegate = self
            
            let utterance = AVSpeechUtterance(string: text)
            utterance.voice = bestEnglishUSVoice()
            // Slower, clear, and natural cadence
            utterance.rate = 0.42
            utterance.pitchMultiplier = 0.95
            utterance.volume = 1.0
            utterance.preUtteranceDelay = 0.08
            utterance.postUtteranceDelay = 0.06
            
            // Store synthesizer to keep it alive
            self.synthesizer = synthesizer
            
            // Activate audio session for playback-only TTS generation
            let session = AVAudioSession.sharedInstance()
            do {
                try session.setCategory(.playback, mode: .default, options: [.duckOthers])
                try session.setActive(true, options: [])
            } catch {
                // If session activation fails, still attempt TTS but report error on completion
            }

            // Request buffers and write them to file
            wroteAnyFrames = false
            synthesizer.write(utterance) { [self] buffer in
                guard let pcmBuffer = buffer as? AVAudioPCMBuffer, pcmBuffer.frameLength > 0 else { return }
                self.ttsQueue.async { [weak self] in
                    guard let self else { return }
                    do {
                        // Lazily create destination file and converter on first buffer
                        if self.audioFile == nil, let url = self.outputURL {
                            let dstFormat = AVAudioFormat(commonFormat: .pcmFormatInt16,
                                                          sampleRate: 16_000,
                                                          channels: 1,
                                                          interleaved: true)!
                            self.converter = AVAudioConverter(from: pcmBuffer.format, to: dstFormat)
                            self.audioFile = try AVAudioFile(forWriting: url,
                                                             settings: dstFormat.settings,
                                                             commonFormat: .pcmFormatInt16,
                                                             interleaved: true)
                        }

                        guard let file = self.audioFile else { return }

                        if let converter = self.converter, let dstFormat = file.processingFormat as AVAudioFormat? {
                            let ratio = dstFormat.sampleRate / pcmBuffer.format.sampleRate
                            let dstCapacity = AVAudioFrameCount(Double(pcmBuffer.frameLength) * ratio) + 1024
                            guard let dstBuffer = AVAudioPCMBuffer(pcmFormat: dstFormat, frameCapacity: dstCapacity) else { return }
                            dstBuffer.frameLength = 0

                            var srcProvided = false
                            let status = converter.convert(to: dstBuffer, error: nil) { (_, outStatus) -> AVAudioBuffer? in
                                if srcProvided {
                                    outStatus.pointee = .noDataNow
                                    return nil
                                }
                                srcProvided = true
                                outStatus.pointee = .haveData
                                return pcmBuffer
                            }

                            if status == .error { return }
                            if dstBuffer.frameLength > 0 {
                                try file.write(from: dstBuffer)
                                self.wroteAnyFrames = true
                            }
                        } else {
                            // Fallback: write as-is
                            try file.write(from: pcmBuffer)
                            self.wroteAnyFrames = true
                        }
                    } catch {
                        self.finishWithFailure(error)
                    }
                }
            }
        }
    }
    
}

extension TTSManager: @preconcurrency AVSpeechSynthesizerDelegate {
    nonisolated func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        DispatchQueue.main.async { [self] in
            guard let completion = self.currentCompletion else { return }
            self.currentCompletion = nil
            self.isGenerating = false
            let session = AVAudioSession.sharedInstance()
            try? session.setActive(false, options: [.notifyOthersOnDeactivation])
            self.synthesizer = nil
            let url = self.outputURL
            self.audioFile = nil
            self.outputURL = nil
            if let url, wroteAnyFrames, (try? FileManager.default.attributesOfItem(atPath: url.path)[.size] as? NSNumber)?.intValue ?? 0 > 0 {
                completion(.success(url))
            } else {
                // Retry once if we received only zero-length buffers
                if !didRetryOnce, let retryText = lastText {
                    didRetryOnce = true
                    currentCompletion = completion
                    // Re-run generation on next runloop to avoid reentrancy
                    DispatchQueue.main.async { [self] in
                        Task {
                            _ = try? await generateAudio(for: retryText)
                        }
                    }
                } else {
                    completion(.failure(NSError(domain: "TTS", code: -2, userInfo: [NSLocalizedDescriptionKey: "Generated audio file is empty."])) )
                }
            }
        }
    }
    
    nonisolated func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didCancel utterance: AVSpeechUtterance) {
        DispatchQueue.main.async { [self] in
            guard let completion = self.currentCompletion else { return }
            self.currentCompletion = nil
            self.isGenerating = false
            let session = AVAudioSession.sharedInstance()
            try? session.setActive(false, options: [.notifyOthersOnDeactivation])
            self.synthesizer = nil
            completion(.failure(NSError(domain: "TTS", code: -1, userInfo: [NSLocalizedDescriptionKey: "TTS was cancelled"])))
        }
    }
}

// MARK: - Helpers
extension TTSManager {
    private func bestEnglishUSVoice() -> AVSpeechSynthesisVoice? {
        // Prefer enhanced/compact US English voices if available
        let preferredIdentifiers = [
            "com.apple.ttsbundle.Samantha-compact", // en-US female
            "com.apple.ttsbundle.Alex-premium",     // en-US male
            "com.apple.ttsbundle.Aaron-compact",
            "com.apple.ttsbundle.Fred"
        ]
        let voices = AVSpeechSynthesisVoice.speechVoices()
        if let match = voices.first(where: { $0.language == "en-US" && preferredIdentifiers.contains($0.identifier) }) {
            return match
        }
        // Fallback to any en-US voice
        if let us = voices.first(where: { $0.language == "en-US" }) { return us }
        // Final fallback: system default
        return AVSpeechSynthesisVoice(language: "en-US")
    }

    private func finishWithFailure(_ error: Error) {
        DispatchQueue.main.async { [self] in
            let session = AVAudioSession.sharedInstance()
            try? session.setActive(false, options: [.notifyOthersOnDeactivation])
            let completion = self.currentCompletion
            self.currentCompletion = nil
            self.isGenerating = false
            self.audioFile = nil
            let url = self.outputURL
            self.outputURL = nil
            if let url { try? FileManager.default.removeItem(at: url) }
            completion?(.failure(error))
        }
    }
}
