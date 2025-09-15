import Foundation

struct SpeechAnalysisIssueDTO: Codable {
    let type: String
    let word: String
    let position: Int
    let severity: Double
    let description: String
    let suggestion: String
}

struct SpeechAnalysisResponseDTO: Codable {
    let text: String
    let pronunciation_score: Double
    let issues: [SpeechAnalysisIssueDTO]
    let confidence: Double
    let processing_time: Double
}

final class SpeechAnalysisService {
    enum ServiceError: Error { case missingConfig, invalidEndpoint }

    func analyze(audioFileURL: URL, expectedText: String) async throws -> AnalysisResult {
        guard let endpoint = AzureConfig.endpoint, let apiKey = AzureConfig.apiKey, let deployment = AzureConfig.deployment else {
            throw ServiceError.missingConfig
        }

        var components = URLComponents(url: endpoint, resolvingAgainstBaseURL: false)
        let basePath = components?.path ?? ""
        let newPath = basePath.appending("/openai/deployments/\(deployment)/audio/transcriptions")
        components?.path = newPath
        guard let url = components?.url else { throw ServiceError.invalidEndpoint }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue(apiKey, forHTTPHeaderField: "api-key")

        let boundary = "Boundary-\(UUID().uuidString)"
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")

        let formData = try buildMultipartFormData(boundary: boundary, fileURL: audioFileURL, fields: [
            "model": "whisper-1",
            "language": "en",
            "prompt": expectedText,
            "response_format": "json",
            "temperature": "0.0"
        ])
        request.httpBody = formData

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse else { throw AppError.network("Invalid response") }
        guard (200..<300).contains(http.statusCode) else {
            switch http.statusCode {
            case 401: throw AppError.network("Unauthorized (401)")
            case 429: throw AppError.network("Rate limit exceeded (429)")
            case 500...599: throw AppError.network("Server error (\(http.statusCode))")
            default: throw AppError.network("HTTP error (\(http.statusCode))")
            }
        }

        let dto = try JSONDecoder().decode(SpeechAnalysisResponseDTO.self, from: data)
        let issues = dto.issues.map { issue in
            PronunciationIssue(id: UUID(), analysisResultId: UUID(), type: PronunciationIssueType(rawValue: issue.type) ?? .vowel, word: issue.word, position: issue.position, severity: Float(issue.severity), description: issue.description, suggestion: issue.suggestion)
        }
        return AnalysisResult(id: UUID(), recordingId: UUID(), overallScore: Float(dto.pronunciation_score), issues: issues, processingTime: dto.processing_time, confidence: Float(dto.confidence), createdAt: Date())
    }

    private func buildMultipartFormData(boundary: String, fileURL: URL, fields: [String: String]) throws -> Data {
        var body = Data()
        for (key, value) in fields {
            body.appendString("--\(boundary)\r\n")
            body.appendString("Content-Disposition: form-data; name=\"\(key)\"\r\n\r\n")
            body.appendString("\(value)\r\n")
        }
        let filename = fileURL.lastPathComponent
        let mimeType = "audio/m4a"
        let fileData = try Data(contentsOf: fileURL)
        body.appendString("--\(boundary)\r\n")
        body.appendString("Content-Disposition: form-data; name=\"file\"; filename=\"\(filename)\"\r\n")
        body.appendString("Content-Type: \(mimeType)\r\n\r\n")
        body.append(fileData)
        body.appendString("\r\n")
        body.appendString("--\(boundary)--\r\n")
        return body
    }
}

private extension Data {
    mutating func appendString(_ string: String) { if let data = string.data(using: .utf8) { append(data) } }
}


