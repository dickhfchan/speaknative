import Foundation

struct AzureConfig {
    static var endpoint: URL? {
        guard let urlString = Bundle.main.object(forInfoDictionaryKey: "AZURE_OPENAI_ENDPOINT") as? String else { return nil }
        return URL(string: urlString)
    }

    static var apiKey: String? {
        Bundle.main.object(forInfoDictionaryKey: "AZURE_OPENAI_API_KEY") as? String
    }

    static var deployment: String? {
        Bundle.main.object(forInfoDictionaryKey: "AZURE_OPENAI_DEPLOYMENT") as? String
    }
}


