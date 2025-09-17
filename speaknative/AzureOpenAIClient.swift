import Foundation

struct AzureOpenAIClient {
    struct Configuration {
        let endpoint: URL
        let apiKey: String
        let deployment: String
        let apiVersion: String
    }

    enum ClientError: LocalizedError {
        case configurationMissing(String)
        case invalidURL
        case invalidResponse
        case requestFailed(status: Int, message: String)
        case emptyResponse

        var errorDescription: String? {
            switch self {
            case .configurationMissing(let key):
                return "Missing Azure configuration for \(key)."
            case .invalidURL:
                return "Azure endpoint URL is invalid."
            case .invalidResponse:
                return "Azure response could not be validated."
            case .requestFailed(let status, let message):
                return "Azure request failed with status \(status): \(message)"
            case .emptyResponse:
                return "Azure response did not include any analysis text."
            }
        }
    }

    private let configuration: Configuration
    private let session: URLSession

    init(bundle: Bundle = .main, session: URLSession = .shared) throws {
        self.configuration = try Self.loadConfiguration(from: bundle)
        self.session = session
    }

    func analyze(summary: SpeechPracticeRecorder.RecordingSummary) async throws -> String {
        var components = URLComponents(url: configuration.endpoint.appendingPathComponent("openai/deployments/\(configuration.deployment)/chat/completions"), resolvingAgainstBaseURL: false)
        components?.queryItems = [URLQueryItem(name: "api-version", value: configuration.apiVersion)]

        guard let url = components?.url else { throw ClientError.invalidURL }

        let payload = requestBody(for: summary)
        let body = try JSONSerialization.data(withJSONObject: payload, options: [])

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.httpBody = body
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(configuration.apiKey, forHTTPHeaderField: "api-key")

        let (data, response) = try await session.data(for: request)

        guard let http = response as? HTTPURLResponse else {
            throw ClientError.invalidResponse
        }

        guard (200..<300).contains(http.statusCode) else {
            let message = String(data: data, encoding: .utf8) ?? "<no message>"
            throw ClientError.requestFailed(status: http.statusCode, message: message)
        }

        return try extractContent(from: data)
    }

    private func requestBody(for summary: SpeechPracticeRecorder.RecordingSummary) -> [String: Any] {
        let average = String(format: "%.2f", summary.averageLevel)
        let peak = String(format: "%.2f", summary.peakLevel)
        let duration = String(format: "%.1f", summary.duration)

        let userPrompt = """
        I recorded a narration with the following microphone metrics:
        - Duration: \(duration) seconds
        - Average intensity (0-1 scale): \(average)
        - Peak intensity (0-1 scale): \(peak)
        - Sample count: \(summary.sampleCount)

        Provide constructive feedback comparing the performance to a native American English speaker. Highlight the most likely pronunciation issues based on these metrics and suggest targeted exercises: one at the word level, one at the phrase level, and one for a longer narrative practice. Keep the guidance empathetic and concise.
        """

        return [
            "messages": [
                [
                    "role": "system",
                    "content": "You are an encouraging American accent coach who recommends actionable pronunciation exercises."
                ],
                [
                    "role": "user",
                    "content": userPrompt
                ]
            ],
            "temperature": 0.4,
            "max_tokens": 320
        ]
    }

    private func extractContent(from data: Data) throws -> String {
        let jsonObject = try JSONSerialization.jsonObject(with: data, options: [])
        guard
            let root = jsonObject as? [String: Any],
            let choices = root["choices"] as? [[String: Any]],
            let firstChoice = choices.first,
            let message = firstChoice["message"] as? [String: Any]
        else {
            throw ClientError.invalidResponse
        }

        if let text = message["content"] as? String {
            return text.trimmingCharacters(in: .whitespacesAndNewlines)
        }

        if let parts = message["content"] as? [[String: Any]] {
            let combined = parts.compactMap { $0["text"] as? String }.joined(separator: "\n")
            if !combined.isEmpty {
                return combined.trimmingCharacters(in: .whitespacesAndNewlines)
            }
        }

        throw ClientError.emptyResponse
    }

    private static func loadConfiguration(from bundle: Bundle) throws -> Configuration {
        let environment = ProcessInfo.processInfo.environment
        if
            let endpointString = environment["AZURE_ENDPOINT_URL"],
            let apiKey = environment["AZURE_API_KEY"],
            let deployment = environment["AZURE_DEPLOYMENT"],
            let apiVersion = environment["AZURE_API_VERSION"],
            let endpointURL = URL(string: endpointString)
        {
            return Configuration(endpoint: endpointURL, apiKey: apiKey, deployment: deployment, apiVersion: apiVersion)
        }

        if
            let endpointString = bundle.object(forInfoDictionaryKey: "AzureEndpointURL") as? String,
            let apiKey = bundle.object(forInfoDictionaryKey: "AzureAPIKey") as? String,
            let deployment = bundle.object(forInfoDictionaryKey: "AzureDeployment") as? String,
            let apiVersion = bundle.object(forInfoDictionaryKey: "AzureAPIVersion") as? String,
            let endpointURL = URL(string: endpointString)
        {
            return Configuration(endpoint: endpointURL, apiKey: apiKey, deployment: deployment, apiVersion: apiVersion)
        }

        guard let envURL = bundle.url(forResource: ".env", withExtension: nil) else {
            throw ClientError.configurationMissing(".env file")
        }

        let raw = try String(contentsOf: envURL, encoding: .utf8)
        let pairs = Self.parseEnv(raw)

        guard let endpointString = pairs["AZURE_ENDPOINT_URL"], let endpointURL = URL(string: endpointString) else {
            throw ClientError.configurationMissing("AZURE_ENDPOINT_URL")
        }
        guard let apiKey = pairs["AZURE_API_KEY"], !apiKey.isEmpty else {
            throw ClientError.configurationMissing("AZURE_API_KEY")
        }
        guard let deployment = pairs["AZURE_DEPLOYMENT"], !deployment.isEmpty else {
            throw ClientError.configurationMissing("AZURE_DEPLOYMENT")
        }
        guard let apiVersion = pairs["AZURE_API_VERSION"], !apiVersion.isEmpty else {
            throw ClientError.configurationMissing("AZURE_API_VERSION")
        }

        return Configuration(endpoint: endpointURL, apiKey: apiKey, deployment: deployment, apiVersion: apiVersion)
    }

    private static func parseEnv(_ contents: String) -> [String: String] {
        var result: [String: String] = [:]
        contents.split(separator: "\n").forEach { line in
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            guard !trimmed.isEmpty, !trimmed.hasPrefix("#"), let equalsIndex = trimmed.firstIndex(of: "=") else { return }
            let key = trimmed[..<equalsIndex].trimmingCharacters(in: .whitespaces)
            let valueIndex = trimmed.index(after: equalsIndex)
            let value = trimmed[valueIndex...].trimmingCharacters(in: .whitespaces)
            result[key] = value
        }
        return result
    }
}
