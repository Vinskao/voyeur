import Foundation

struct Person: Codable, Identifiable {
    var id: String { name }
    let name: String
    
    // Decoding strategy to handle potential extra fields gracefully
    // although JSONDecoder ignores them by default.
}

class PeopleService {
    static let shared = PeopleService()
    
    private init() {}
    
    func fetchPeople() async throws -> [Person] {
        // Construct URL
        let baseURLString = AppConfig.baseURL
        // Ensure no double slashes if baseURL ends with /
        let endpoint = baseURLString.hasSuffix("/") ? "people/get-all" : "/people/get-all"
        guard let url = URL(string: baseURLString + endpoint) else {
            throw URLError(.badURL)
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.timeoutInterval = 30
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        print("Fetching people from: \(url.absoluteString)")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
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
