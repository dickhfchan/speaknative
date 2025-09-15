import Foundation
import os

enum AppLog {
    private static let subsystem = Bundle.main.bundleIdentifier ?? "speaknative"

    static let app = Logger(subsystem: subsystem, category: "app")
    static let network = Logger(subsystem: subsystem, category: "network")
    static let audio = Logger(subsystem: subsystem, category: "audio")
    static let coredata = Logger(subsystem: subsystem, category: "coredata")
}


