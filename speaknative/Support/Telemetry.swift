import Foundation

enum TelemetryEvent: String {
    case appLaunch, startRecording, stopRecording, analysisStart, analysisSuccess, analysisFailure
}

enum Telemetry {
    static func log(_ event: TelemetryEvent, metadata: [String: String] = [:]) {
        #if DEBUG
        print("[Telemetry] \(event.rawValue): \(metadata)")
        #endif
    }
}


