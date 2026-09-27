import Foundation

enum CatalogError: Error, Equatable {
    case offline
    case server

    init(_ error: Error) {
        if let catalogError = error as? CatalogError {
            self = catalogError
        } else if let urlError = error as? URLError {
            switch urlError.code {
            case .notConnectedToInternet,
                 .timedOut,
                 .networkConnectionLost,
                 .cannotFindHost,
                 .cannotConnectToHost,
                 .dnsLookupFailed,
                 .dataNotAllowed,
                 .internationalRoamingOff,
                 .callIsActive:
                self = .offline
            default:
                self = .server
            }
        } else {
            self = .server
        }
    }
}

/// Downloads the product catalog from DummyJSON.
final class CatalogService {
    static let shared = CatalogService()

    private let baseURL = URL(string: "https://dummyjson.com")!
    private let session: URLSession

    init(session: URLSession? = nil) {
        if let session = session {
            self.session = session
        } else {
            let configuration = URLSessionConfiguration.default
            configuration.timeoutIntervalForRequest = 15
            configuration.timeoutIntervalForResource = 15
            self.session = URLSession(configuration: configuration)
        }
    }

    func fetchGroceries() async throws -> [CatalogProduct] {
        let response: CatalogResponse = try await get(baseURL.appendingPathComponent("products"))
        return response.products
    }

    func search(_ query: String) async throws -> [CatalogProduct] {
        var components = URLComponents(
            url: baseURL.appendingPathComponent("products/search"),
            resolvingAgainstBaseURL: false
        )
        components?.queryItems = [URLQueryItem(name: "q", value: query)]
        guard let url = components?.url else {
            throw CatalogError.server
        }
        let response: CatalogResponse = try await get(url)
        return response.products
    }

    private func get<T: Decodable>(_ url: URL) async throws -> T {
        let (data, response) = try await session.data(from: url)
        if let httpResponse = response as? HTTPURLResponse,
           !(200...299).contains(httpResponse.statusCode) {
            throw CatalogError.server
        }
        return try JSONDecoder().decode(T.self, from: data)
    }
}
