import AVFoundation
import Foundation

enum MicrophonePermissionStatus {
    case granted
    case denied
    case undetermined
}

final class PermissionsManager {
    static let shared = PermissionsManager()

    func microphonePermissionStatus() -> MicrophonePermissionStatus {
        switch AVAudioSession.sharedInstance().recordPermission {
        case .granted: return .granted
        case .denied: return .denied
        case .undetermined: return .undetermined
        @unknown default: return .undetermined
        }
    }

    func requestMicrophonePermission(completion: @escaping (MicrophonePermissionStatus) -> Void) {
        AVAudioSession.sharedInstance().requestRecordPermission { granted in
            DispatchQueue.main.async {
                completion(granted ? .granted : .denied)
            }
        }
    }

    func ensureMicrophonePermission(completion: @escaping (Result<Void, AppError>) -> Void) {
        switch microphonePermissionStatus() {
        case .granted:
            completion(.success(()))
        case .undetermined:
            requestMicrophonePermission { status in
                if status == .granted { completion(.success(())) }
                else { completion(.failure(.permissionDenied("Microphone access is required to record"))) }
            }
        case .denied:
            completion(.failure(.permissionDenied("Please enable microphone in Settings")))
        }
    }
}


