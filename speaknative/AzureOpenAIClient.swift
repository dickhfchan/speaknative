import Foundation
import AVFoundation

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
        case underlying(String)

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
            case .underlying(let message):
                return message
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
        let messages = requestMessages(for: summary)
        return try await sendChat(messages: messages, temperature: 0.4, maxTokens: 320)
    }

    func sendTestPrompt(_ prompt: String) async throws -> String {
        let messages: [[String: Any]] = [
            [
                "role": "system",
                "content": "You are a helpful assistant."
            ],
            [
                "role": "user",
                "content": prompt
            ]
        ]

        return try await sendChat(messages: messages, temperature: 0.2, maxTokens: 120)
    }
    
    func generateNativeSpeakerAudio(for narrative: String) async throws -> URL {
        // Use the original narrative directly for TTS generation
        // This ensures we get the exact same text with native pronunciation
        let ttsManager = await TTSManager()
        return try await ttsManager.generateAudio(for: narrative)
    }

    // MARK: - Audio Transcription (Whisper / Azure OpenAI Audio API)
    func transcribeAudio(at fileURL: URL, language: String = "en") async throws -> String {
        var components = URLComponents(url: configuration.endpoint.appendingPathComponent("openai/deployments/\(configuration.deployment)/audio/transcriptions"), resolvingAgainstBaseURL: false)
        components?.queryItems = [URLQueryItem(name: "api-version", value: configuration.apiVersion)]

        guard let url = components?.url else { throw ClientError.invalidURL }

        let audioData = try Data(contentsOf: fileURL)
        let boundary = "Boundary-\(UUID().uuidString)"

        var body = Data()
        func appendFormField(name: String, value: String) {
            body.append("--\(boundary)\r\n".data(using: .utf8)!)
            body.append("Content-Disposition: form-data; name=\"\(name)\"\r\n\r\n".data(using: .utf8)!)
            body.append("\(value)\r\n".data(using: .utf8)!)
        }
        func appendFileField(name: String, filename: String, mime: String, data: Data) {
            body.append("--\(boundary)\r\n".data(using: .utf8)!)
            body.append("Content-Disposition: form-data; name=\"\(name)\"; filename=\"\(filename)\"\r\n".data(using: .utf8)!)
            body.append("Content-Type: \(mime)\r\n\r\n".data(using: .utf8)!)
            body.append(data)
            body.append("\r\n".data(using: .utf8)!)
        }

        // Required fields vary; we set response format json and language
        appendFormField(name: "response_format", value: "json")
        appendFormField(name: "language", value: language)
        appendFileField(name: "file", filename: fileURL.lastPathComponent, mime: "audio/m4a", data: audioData)
        body.append("--\(boundary)--\r\n".data(using: .utf8)!)

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.httpBody = body
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        request.setValue(configuration.apiKey, forHTTPHeaderField: "api-key")

        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await session.data(for: request)
        } catch {
            throw ClientError.underlying("Network error: \(error.localizedDescription)")
        }
        guard let http = response as? HTTPURLResponse else { throw ClientError.invalidResponse }
        guard (200..<300).contains(http.statusCode) else {
            let message = String(data: data, encoding: .utf8) ?? "<no message>"
            throw ClientError.requestFailed(status: http.statusCode, message: message)
        }

        // Expect JSON: { text: "..." } or similar
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        if let text = json?["text"] as? String, !text.isEmpty {
            return text
        }
        // Some variants may return segments; fallback to concatenation
        if let segments = json?["segments"] as? [[String: Any]] {
            let combined = segments.compactMap { $0["text"] as? String }.joined(separator: " ")
            if !combined.isEmpty { return combined }
        }
        throw ClientError.emptyResponse
    }

    // MARK: - Word-level Comparison
    func compareRecording(recordingText: String, nativeText: String) async throws -> String {
        let system = "You are a strict pronunciation coach. Compare the two transcripts word-by-word. Output ONLY specific issues, aligned to individual words/sounds. Avoid generic feedback."
        let user = "Native text:\n\(nativeText)\n\nUser transcript:\n\(recordingText)\n\nInstructions:\n- Align words in order.\n- For each mismatched, mispronounced, added, or omitted word, output a bullet in this format: \n  - word: <word> | issue: <substitution/omission/addition/mispronunciation> | detail: <specific sound/phoneme difference> | fix: <short tip>\n- If a word matches but has stress/intonation issues, mark issue as 'prosody' with a brief note.\n- Keep it concise and exhaustive."

        let messages: [[String: Any]] = [
            ["role": "system", "content": system],
            ["role": "user", "content": user]
        ]

        return try await sendChat(messages: messages, temperature: 0.1, maxTokens: 800)
    }

    // MARK: - Direct audio comparison (GPT-4o with input_audio parts)
    func analyzePronunciationWithAudio(recordingURL: URL, nativeURL: URL) async throws -> String {
        // Validate files exist and are non-empty
        let fm = FileManager.default
        guard fm.fileExists(atPath: recordingURL.path) else { throw ClientError.underlying("Recording file not found: \(recordingURL.lastPathComponent)") }
        guard fm.fileExists(atPath: nativeURL.path) else { throw ClientError.underlying("Native file not found: \(nativeURL.lastPathComponent)") }

        func fileSize(_ url: URL) -> UInt64 { (try? fm.attributesOfItem(atPath: url.path)[.size] as? UInt64) ?? 0 }
        guard fileSize(recordingURL) > 0 else { throw ClientError.underlying("Recording file is empty.") }
        guard fileSize(nativeURL) > 0 else { throw ClientError.underlying("Native file is empty.") }

        // No conversion expected; we now record and synthesize as WAV directly
        let recordingData: Data
        let nativeData: Data
        do {
            recordingData = try Data(contentsOf: recordingURL)
            nativeData = try Data(contentsOf: nativeURL)
        } catch {
            throw ClientError.underlying("Failed to read audio: \(error.localizedDescription)")
        }
        let recB64 = recordingData.base64EncodedString()
        let natB64 = nativeData.base64EncodedString()

        let system = "You are a strict pronunciation coach. Compare the user's recording to the native reference at the word/phoneme level. Output only concise bullets of issues and fixes."

        // Azure chat-completions only accepts text/image_url blocks. Embed audio as base64 text.
        let maxPreview = 24_000 // truncate long base64 to keep payload reasonable
        let recPreview = recB64.count > maxPreview ? String(recB64.prefix(maxPreview)) + "...<truncated>" : recB64
        let natPreview = natB64.count > maxPreview ? String(natB64.prefix(maxPreview)) + "...<truncated>" : natB64

        let userText = """
        Here are two base64-encoded WAV audios.
        Audio A (user recording, wav/pcm16/16k/mono, base64):
        \(recPreview)

        Audio B (native reference, wav/pcm16/16k/mono, base64):
        \(natPreview)

        """


        // Instructions:
        // - Decode both audios.
        // - Align words.
        // - For each problematic word/sound, output one bullet:
        //   - word | issue | detail | fix
        // - Keep it specific and brief.

        let messages: [[String: Any]] = [
            ["role": "system", "content": system],
            ["role": "user", "content": userText]
        ]

        return try await sendChat(messages: messages, temperature: 0.1, maxTokens: 800)
    }

    // MARK: - WAV Conversion
    private func convertToWavIfNeeded(_ url: URL) async throws -> URL {
        // If already WAV, return as-is
        if url.pathExtension.lowercased() == "wav" { return url }

        let srcFile = try AVAudioFile(forReading: url)
        let srcFormat = srcFile.processingFormat
        // Target WAV format: keep source rate/channels to minimize conversion issues
        guard let dstFormat = AVAudioFormat(commonFormat: .pcmFormatInt16,
                                            sampleRate: srcFormat.sampleRate,
                                            channels: srcFormat.channelCount,
                                            interleaved: true) else { throw ClientError.invalidResponse }

        let tempDir = FileManager.default.temporaryDirectory
        let outURL = tempDir.appendingPathComponent("converted-\(UUID().uuidString).wav")
        let dstFile = try AVAudioFile(
            forWriting: outURL,
            settings: dstFormat.settings,
            commonFormat: .pcmFormatInt16,
            interleaved: true
        )

        // Create converter only if formats differ
        let converter = AVAudioConverter(from: srcFormat, to: dstFormat)

        // We'll convert in chunks
        let srcFrameCapacity: AVAudioFrameCount = 4096
        let srcBuffer = AVAudioPCMBuffer(pcmFormat: srcFormat, frameCapacity: srcFrameCapacity)!

        while true {
            try srcFile.read(into: srcBuffer, frameCount: srcFrameCapacity)
            if srcBuffer.frameLength == 0 { break }

            if let converter {
                // Prepare output buffer for converted audio
                let dstCapacity = AVAudioFrameCount(Double(srcBuffer.frameLength) * (dstFormat.sampleRate / srcFormat.sampleRate)) + 1024
                guard let dstBuffer = AVAudioPCMBuffer(pcmFormat: dstFormat, frameCapacity: dstCapacity) else { break }
                dstBuffer.frameLength = 0

                var srcConsumed = false
                let status = converter.convert(to: dstBuffer, error: nil) { (_, outStatus) -> AVAudioBuffer? in
                    if srcConsumed {
                        outStatus.pointee = .noDataNow
                        return nil
                    }
                    srcConsumed = true
                    outStatus.pointee = .haveData
                    return srcBuffer
                }

                switch status {
                case .error:
                    throw ClientError.invalidResponse
                case .endOfStream, .haveData, .inputRanDry:
                    break
                @unknown default:
                    break
                }

                if dstBuffer.frameLength > 0 {
                    try dstFile.write(from: dstBuffer)
                }
            } else {
                // Formats match; write directly
                try dstFile.write(from: srcBuffer)
            }
        }

        return outURL
    }

    private func requestMessages(for summary: SpeechPracticeRecorder.RecordingSummary) -> [[String: Any]] {
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
            [
                "role": "system",
                "content": "You are an encouraging American accent coach who recommends actionable pronunciation exercises."
            ],
            [
                "role": "user",
                "content": userPrompt
            ]
        ]
    }

    private func sendChat(messages: [[String: Any]], temperature: Double, maxTokens: Int) async throws -> String {
        var components = URLComponents(url: configuration.endpoint.appendingPathComponent("openai/deployments/\(configuration.deployment)/chat/completions"), resolvingAgainstBaseURL: false)
        components?.queryItems = [URLQueryItem(name: "api-version", value: configuration.apiVersion)]

        guard let url = components?.url else { throw ClientError.invalidURL }

        let payload: [String: Any] = [
            "messages": messages,
            "temperature": temperature,
            "max_tokens": maxTokens
        ]

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

        do {
            return try extractContent(from: data)
        } catch {
            let bodySnippet = String(data: data, encoding: .utf8) ?? "<non-utf8 body>"
            throw ClientError.underlying("Invalid JSON response. Body: \(bodySnippet)")
        }
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

