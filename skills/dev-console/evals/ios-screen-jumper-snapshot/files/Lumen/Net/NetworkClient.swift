import Foundation

/// Every server call in the app goes through here.
final class NetworkClient {
    static let shared = NetworkClient()
    /// Debug: makes every request fail as if the phone had no connection.
    var simulateOffline = false

    func data(for request: URLRequest) async throws -> (Data, URLResponse) {
        if simulateOffline { throw URLError(.notConnectedToInternet) }
        return try await URLSession.shared.data(for: request)
    }
}
