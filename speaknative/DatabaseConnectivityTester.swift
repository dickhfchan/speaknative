import Foundation
import Network

enum DatabaseConnectivityTester {
    enum TesterError: LocalizedError {
        case configurationMissing
        case invalidURL
        case missingHost
        case invalidPort
        case unsupportedScheme(String)
        case connectionFailed(String)
        case timeout

        var errorDescription: String? {
            switch self {
            case .configurationMissing:
                return "POSTGRES_URL is not configured."
            case .invalidURL:
                return "POSTGRES_URL is not a valid URL."
            case .missingHost:
                return "POSTGRES_URL must include a host."
            case .invalidPort:
                return "POSTGRES_URL has an invalid port."
            case .unsupportedScheme(let scheme):
                return "Unsupported database scheme: \(scheme)."
            case .connectionFailed(let message):
                return "Connection failed: \(message)"
            case .timeout:
                return "Connection attempt timed out."
            }
        }
    }

    static func testConnection(timeout: TimeInterval = 5, bundle: Bundle = .main) async throws -> String {
        guard let urlString = resolvePostgresURL(bundle: bundle) else {
            throw TesterError.configurationMissing
        }

        guard let url = URL(string: urlString) else {
            throw TesterError.invalidURL
        }

        guard let scheme = url.scheme, scheme.hasPrefix("postgres") else {
            throw TesterError.unsupportedScheme(url.scheme ?? "")
        }

        guard let host = url.host else {
            throw TesterError.missingHost
        }

        let port = url.port ?? 5432
        guard port > 0, port <= Int(UInt16.max), let nwPort = NWEndpoint.Port(rawValue: UInt16(port)) else {
            throw TesterError.invalidPort
        }

        try await openTCPConnection(host: host, port: nwPort, timeout: timeout)
        return "Connected to \(host):\(port). Authentication not attempted."
    }

    private static func resolvePostgresURL(bundle: Bundle) -> String? {
        if let envValue = ProcessInfo.processInfo.environment["POSTGRES_URL"], !envValue.isEmpty {
            return envValue
        }

        if let infoValue = bundle.object(forInfoDictionaryKey: "PostgresURL") as? String, !infoValue.isEmpty {
            return infoValue
        }

        guard let envURL = bundle.url(forResource: ".env", withExtension: nil),
              let raw = try? String(contentsOf: envURL, encoding: .utf8) else {
            return nil
        }

        for line in raw.split(separator: "\n") {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            guard !trimmed.isEmpty, !trimmed.hasPrefix("#"), let equalsIndex = trimmed.firstIndex(of: "=") else { continue }
            let key = trimmed[..<equalsIndex].trimmingCharacters(in: .whitespaces)
            if key == "POSTGRES_URL" {
                let valueIndex = trimmed.index(after: equalsIndex)
                let value = trimmed[valueIndex...].trimmingCharacters(in: .whitespaces)
                return value
            }
        }

        return nil
    }

    private static func openTCPConnection(host: String, port: NWEndpoint.Port, timeout: TimeInterval) async throws {
        let queue = DispatchQueue(label: "DatabaseConnectivityTester")
        let connection = NWConnection(host: NWEndpoint.Host(host), port: port, using: .tcp)

        try await withCheckedThrowingContinuation { continuation in
            var didResume = false

            func resume(_ result: Result<Void, Error>) {
                guard !didResume else { return }
                didResume = true
                continuation.resume(with: result)
            }

            let timeoutWorkItem = DispatchWorkItem {
                connection.cancel()
                resume(.failure(TesterError.timeout))
            }

            connection.stateUpdateHandler = { state in
                switch state {
                case .ready:
                    connection.cancel()
                    timeoutWorkItem.cancel()
                    resume(.success(()))
                case .failed(let error):
                    connection.cancel()
                    timeoutWorkItem.cancel()
                    resume(.failure(TesterError.connectionFailed(error.localizedDescription)))
                case .cancelled:
                    timeoutWorkItem.cancel()
                    if !didResume {
                        resume(.failure(TesterError.connectionFailed("Connection cancelled")))
                    }
                default:
                    break
                }
            }

            connection.start(queue: queue)
            DispatchQueue.global().asyncAfter(deadline: .now() + timeout, execute: timeoutWorkItem)
        }
    }
}
