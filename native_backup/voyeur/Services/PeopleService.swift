import Foundation

struct Person: Codable, Identifiable {
    var id: String { name }
    let name: String
    let originArmyName: String?
    
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
        // Gateway endpoint: /people/get-all (Note: apiBaseURL includes /tymg)
        let baseURLString = AppConfig.apiBaseURL
        let endpoint = "/people/get-all" 
        
        guard let url = URL(string: baseURLString + endpoint) else {
            throw URLError(.badURL)
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.timeoutInterval = 60  // 增加到 60 秒
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        print("Fetching all people from: \(url.absoluteString)")
        
        let (data, response) = try await urlSession.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
             throw URLError(.badServerResponse)
        }
        
        guard httpResponse.statusCode == 200 else {
            print("People fetch failed with status: \(httpResponse.statusCode)")
            throw URLError(.badServerResponse)
        }
        
        do {
            let people = try JSONDecoder().decode([Person].self, from: data)
            return people
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
