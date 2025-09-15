import Foundation

final class RecordingViewModel: ObservableObject {
    @Published var isRecording = false
    @Published var recordedURL: URL?
    private let recorder = VoiceRecordingService()

    func start() {
        do {
            try recorder.startRecording()
            isRecording = true
        } catch {
            isRecording = false
        }
    }

    func stop() {
        recordedURL = recorder.stopRecording()
        isRecording = false
    }
}


