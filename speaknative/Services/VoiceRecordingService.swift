import AVFoundation
import Foundation

final class VoiceRecordingService: NSObject, AVAudioRecorderDelegate {
    private var recorder: AVAudioRecorder?
    private(set) var currentFileURL: URL?

    func startRecording() throws {
        let session = AVAudioSession.sharedInstance()
        try session.setCategory(.playAndRecord, mode: .spokenAudio, options: [.defaultToSpeaker, .allowBluetooth])
        try session.setActive(true, options: .notifyOthersOnDeactivation)

        let tempDir = FileManager.default.temporaryDirectory
        let fileURL = tempDir.appendingPathComponent("recording-\(UUID().uuidString).m4a")
        currentFileURL = fileURL

        let settings: [String: Any] = [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey: 44100,
            AVNumberOfChannelsKey: 1,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
        ]

        recorder = try AVAudioRecorder(url: fileURL, settings: settings)
        recorder?.delegate = self
        guard recorder?.record() == true else { throw AppError.recordingFailed("Unable to start recording") }
    }

    func stopRecording() -> URL? {
        recorder?.stop()
        let url = currentFileURL
        recorder = nil
        return url
    }
}


