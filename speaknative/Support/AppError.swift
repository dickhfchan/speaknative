import Foundation

enum AppError: Error, LocalizedError, Equatable {
    case configurationMissing(String)
    case permissionDenied(String)
    case recordingFailed(String)
    case analysisFailed(String)
    case network(String)

    var errorDescription: String? {
        switch self {
        case .configurationMissing(let key): return "Configuration missing: \(key)"
        case .permissionDenied(let reason): return "Permission denied: \(reason)"
        case .recordingFailed(let reason): return "Recording failed: \(reason)"
        case .analysisFailed(let reason): return "Analysis failed: \(reason)"
        case .network(let reason): return "Network error: \(reason)"
        }
    }
}


