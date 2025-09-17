import Foundation
import AVFoundation
import SwiftUI

@MainActor
final class AudioPlayerManager: NSObject, ObservableObject {
    @Published var isPlaying: Bool = false
    @Published var currentTime: TimeInterval = 0
    @Published var duration: TimeInterval = 0
    @Published var playbackError: String?
    @Published var currentURL: URL?
    
    private var audioPlayer: AVAudioPlayer?
    private var playbackTimer: Timer?
    
    func play(url: URL) {
        do {
            // Stop any current playback
            stop()
            
            // Create new player
            audioPlayer = try AVAudioPlayer(contentsOf: url)
            audioPlayer?.delegate = self
            audioPlayer?.prepareToPlay()
            
            duration = audioPlayer?.duration ?? 0
            currentTime = 0
            playbackError = nil
            currentURL = url
            
            // Start playback
            if audioPlayer?.play() == true {
                isPlaying = true
                startPlaybackTimer()
            } else {
                playbackError = "Failed to start playback"
            }
        } catch {
            playbackError = "Playback error: \(error.localizedDescription)"
        }
    }
    
    func stop() {
        audioPlayer?.stop()
        audioPlayer = nil
        isPlaying = false
        currentTime = 0
        duration = 0
        stopPlaybackTimer()
        currentURL = nil
    }
    
    func pause() {
        audioPlayer?.pause()
        isPlaying = false
        stopPlaybackTimer()
    }
    
    func resume() {
        audioPlayer?.play()
        isPlaying = true
        startPlaybackTimer()
    }
    
    func seek(to time: TimeInterval) {
        audioPlayer?.currentTime = time
        currentTime = time
    }
    
    private func startPlaybackTimer() {
        stopPlaybackTimer()
        playbackTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            Task { @MainActor in
                guard let self = self, let player = self.audioPlayer else { return }
                self.currentTime = player.currentTime
            }
        }
    }
    
    private func stopPlaybackTimer() {
        playbackTimer?.invalidate()
        playbackTimer = nil
    }
}

extension AudioPlayerManager: @preconcurrency AVAudioPlayerDelegate {
    nonisolated func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        Task { @MainActor in
            isPlaying = false
            currentTime = 0
            stopPlaybackTimer()
        }
    }
    
    nonisolated func audioPlayerDecodeErrorDidOccur(_ player: AVAudioPlayer, error: Error?) {
        Task { @MainActor in
            playbackError = "Playback error: \(error?.localizedDescription ?? "Unknown error")"
            isPlaying = false
            stopPlaybackTimer()
        }
    }
}
