import Foundation
import SwiftUI
import AVFoundation

final class SpeechPracticeRecorder: NSObject, ObservableObject {
    enum PermissionState {
        case undetermined
        case granted
        case denied
        case failed(Error)
    }

    @Published private(set) var permission: PermissionState
    @Published private(set) var isRecording: Bool = false
    @Published private(set) var level: Double = 0
    @Published private(set) var lastRecordingURL: URL?
    @Published private(set) var lastRecordingSummary: RecordingSummary?
    @Published var presentPermissionAlert: Bool = false

    private let audioSession = AVAudioSession.sharedInstance()
    private var audioRecorder: AVAudioRecorder?
    private var meterTimer: DispatchSourceTimer?
    private let meterQueue = DispatchQueue(label: "SpeechPracticeRecorder.meter")
    private var levelAccumulator = LevelAccumulator()
    private var recordingStartDate: Date?

    override init() {
        switch audioSession.recordPermission {
        case .undetermined:
            permission = .undetermined
        case .denied:
            permission = .denied
        case .granted:
            permission = .granted
        @unknown default:
            permission = .undetermined
        }
        super.init()
    }

    func requestPermission() {
        guard case .undetermined = permission else { return }

        audioSession.requestRecordPermission { [weak self] granted in
            DispatchQueue.main.async {
                self?.permission = granted ? .granted : .denied
                if !granted {
                    self?.presentPermissionAlert = true
                }
            }
        }
    }

    func startRecording() {
        switch permission {
        case .undetermined:
            requestPermission()
            return
        case .denied:
            presentPermissionAlert = true
            return
        case .failed:
            return
        case .granted:
            break
        }

        guard !isRecording else { return }

        do {
            try configureSession()
            let url = makeRecordingURL()
            let recorder = try AVAudioRecorder(url: url, settings: recordingSettings())
            recorder.isMeteringEnabled = true
            recorder.delegate = self
            recorder.record()

            audioRecorder = recorder
            lastRecordingURL = url
            lastRecordingSummary = nil
            recordingStartDate = Date()
            meterQueue.sync {
                levelAccumulator.reset()
            }
            isRecording = true
            scheduleMeterUpdates()
        } catch {
            permission = .failed(error)
            presentPermissionAlert = true
        }
    }

    func stopRecording() {
        guard isRecording else { return }

        let recordedDuration = audioRecorder?.currentTime ?? (Date().timeIntervalSince(recordingStartDate ?? Date()))
        audioRecorder?.stop()
        audioRecorder = nil
        isRecording = false
        level = 0
        cancelMeterUpdates()

        let duration = recordedDuration
        let summary: RecordingSummary? = {
            guard let url = lastRecordingURL else { return nil }
            return meterQueue.sync {
                let snapshot = levelAccumulator.snapshotAndReset()
                return RecordingSummary(
                    url: url,
                    averageLevel: snapshot.average,
                    peakLevel: snapshot.peak,
                    sampleCount: snapshot.count,
                    duration: duration
                )
            }
        }()
        recordingStartDate = nil

        DispatchQueue.main.async {
            self.lastRecordingSummary = summary
        }

        try? audioSession.setActive(false, options: [.notifyOthersOnDeactivation])
    }

    private func configureSession() throws {
        try audioSession.setCategory(.playAndRecord, mode: .spokenAudio, options: [.defaultToSpeaker, .mixWithOthers])
        try audioSession.setActive(true, options: [])
    }

    private func makeRecordingURL() -> URL {
        let filename = "practice-" + ISO8601DateFormatter().string(from: Date()) + ".m4a"
        let folder = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first ?? FileManager.default.temporaryDirectory
        return folder.appendingPathComponent(filename)
    }

    private func recordingSettings() -> [String: Any] {
        [
            AVFormatIDKey: kAudioFormatMPEG4AAC,
            AVSampleRateKey: 44_100,
            AVNumberOfChannelsKey: 1,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
        ]
    }

    private func scheduleMeterUpdates() {
        cancelMeterUpdates()

        let timer = DispatchSource.makeTimerSource(queue: meterQueue)
        timer.schedule(deadline: .now(), repeating: .milliseconds(100))
        timer.setEventHandler { [weak self] in
            guard let self, let recorder = self.audioRecorder else { return }
            recorder.updateMeters()
            let decibels = recorder.averagePower(forChannel: 0)
            let normalized = Self.normalizedLevel(from: decibels)
            self.levelAccumulator.add(normalized)
            DispatchQueue.main.async {
                withAnimation(.linear(duration: 0.1)) {
                    self.level = normalized
                }
            }
        }

        timer.resume()
        meterTimer = timer
    }

    private func cancelMeterUpdates() {
        meterTimer?.cancel()
        meterTimer = nil
    }

    private static func normalizedLevel(from decibels: Float) -> Double {
        let minDecibels: Float = -80
        if decibels <= minDecibels { return 0 }
        if decibels >= 0 { return 1 }
        let clipped = max(min(decibels, 0), minDecibels)
        return Double((clipped - minDecibels) / -minDecibels)
    }
}

extension SpeechPracticeRecorder: AVAudioRecorderDelegate {
    func audioRecorderEncodeErrorDidOccur(_ recorder: AVAudioRecorder, error: Error?) {
        DispatchQueue.main.async {
            self.permission = .failed(error ?? NSError(domain: "SpeechPracticeRecorder", code: -1, userInfo: nil))
            self.presentPermissionAlert = true
            self.stopRecording()
        }
    }
}

extension SpeechPracticeRecorder {
    struct RecordingSummary: Equatable {
        let url: URL
        let averageLevel: Double
        let peakLevel: Double
        let sampleCount: Int
        let duration: TimeInterval
    }

    private struct LevelAccumulator {
        private var sum: Double = 0
        private var count: Int = 0
        private var peak: Double = 0

        mutating func add(_ value: Double) {
            sum += value
            count += 1
            peak = max(peak, value)
        }

        mutating func reset() {
            sum = 0
            count = 0
            peak = 0
        }

        mutating func snapshotAndReset() -> (average: Double, peak: Double, count: Int) {
            defer { reset() }
            guard count > 0 else { return (0, 0, 0) }
            return (sum / Double(count), peak, count)
        }
    }
}
