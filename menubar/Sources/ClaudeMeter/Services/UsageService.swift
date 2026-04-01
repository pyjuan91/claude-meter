import Foundation

// MARK: - Fetch usage data from claude.ai API

enum UsageService {

    enum UsageError: LocalizedError {
        case invalidURL
        case httpError(Int, String?)
        case noData
        case decodingFailed(Error)

        var errorDescription: String? {
            switch self {
            case .invalidURL:
                return "Invalid usage API URL."
            case .httpError(let code, let body):
                return "HTTP \(code)" + (body.map { ": \($0)" } ?? "")
            case .noData:
                return "Empty response from usage API."
            case .decodingFailed(let err):
                return "Failed to decode usage JSON: \(err.localizedDescription)"
            }
        }
    }

    /// Fetch real-time usage for the given org.
    static func fetchUsage(orgId: String, sessionKey: String) async throws -> UsageData {
        let urlString = "https://claude.ai/api/organizations/\(orgId)/usage"
        guard let url = URL(string: urlString) else { throw UsageError.invalidURL }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("sessionKey=\(sessionKey)", forHTTPHeaderField: "Cookie")
        request.setValue("claude.ai", forHTTPHeaderField: "Host")
        // Mimic a normal browser request so the API doesn't reject us
        request.setValue(
            "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko)",
            forHTTPHeaderField: "User-Agent"
        )
        request.timeoutInterval = 15

        let (data, response) = try await URLSession.shared.data(for: request)

        if let http = response as? HTTPURLResponse, http.statusCode != 200 {
            let body = String(data: data.prefix(500), encoding: .utf8)
            throw UsageError.httpError(http.statusCode, body)
        }

        guard !data.isEmpty else { throw UsageError.noData }

        do {
            return try JSONDecoder().decode(UsageData.self, from: data)
        } catch {
            throw UsageError.decodingFailed(error)
        }
    }
}
