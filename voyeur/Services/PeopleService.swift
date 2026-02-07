import Foundation

struct Person: Codable, Identifiable {
    var id: String { name }
    let name: String
    
    // Decoding strategy to handle potential extra fields gracefully
    // although JSONDecoder ignores them by default.
}

class PeopleService {
    static let shared = PeopleService()
    
    // Custom URLSession with extended timeout
    private lazy var urlSession: URLSession = {
        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = 60  // 請求超時 60 秒
        configuration.timeoutIntervalForResource = 120  // 資源超時 120 秒
        return URLSession(configuration: configuration)
    }()
    
    private init() {}
    
    func fetchPeople() async throws -> [Person] {
        // Construct URL using Gateway API Base URL
        // Gateway endpoint: /people/names (Note: apiBaseURL includes /tymg)
        // Returns: [String] (e.g. ["Wavo", "Chiaki"])
        let baseURLString = AppConfig.apiBaseURL
        let endpoint = "/people/names" 
        
        guard let url = URL(string: baseURLString + endpoint) else {
            throw URLError(.badURL)
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.timeoutInterval = 60  // 增加到 60 秒
        
        print("Fetching people names from: \(url.absoluteString)")
        
        let (data, response) = try await urlSession.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
             throw URLError(.badServerResponse)
        }
        
        guard httpResponse.statusCode == 200 else {
            print("People names fetch failed with status: \(httpResponse.statusCode)")
            throw URLError(.badServerResponse)
        }
        
        do {
            let names = try JSONDecoder().decode([String].self, from: data)
            // Map simple strings to Person objects
            return names.map { Person(name: $0) }
        } catch {
            print("Decoding error: \(error)")
            // Fallback debugging
            if let str = String(data: data, encoding: .utf8) {
                print("Received data: \(str)")
            }
            throw error
        }
    }
}
