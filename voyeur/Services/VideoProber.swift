import Foundation

struct VideoResult: Identifiable, Hashable {
    var id: String { url.absoluteString }
    let personName: String
    let url: URL
    let filename: String
}

class VideoProber {
    static let shared = VideoProber()
    private init() {}
    
    // Configuration
    private let maxIndex = 50
    private let maxConsecutiveMisses = 3
    
    /// Constructs the base URL for video images, appending /images/people if needed
    private func constructBaseVideoURL() -> String {
        // Use Resource URL (Remote) for heavy assets
        // Format: <ResourceBase>/images/people/<name>.mp4
        let baseURL = AppConfig.resourceBaseURL
        
        // Ensure cleaner path joining
        let cleanBase = baseURL.hasSuffix("/") ? String(baseURL.dropLast()) : baseURL
        return "\(cleanBase)/images/people"
    }
    
    /// Probes for all valid videos for a given person
    func probeCharacter(person: Person) async -> [VideoResult] {
        let baseVideoPath = constructBaseVideoURL()
        var results: [VideoResult] = []
        
        // 1. Check Main Video: {name}.mp4
        if let mainURL = await checkVideoExists(basePath: baseVideoPath, name: person.name, suffix: "") {
            results.append(mainURL)
        }
        
        // 2. Check Numbered Videos: {name}{i}.mp4
        let batchSize = 5
        var currentIndex = 1
        var consecutiveMisses = 0
        
        while currentIndex <= maxIndex && consecutiveMisses < maxConsecutiveMisses {
            let endIndex = min(currentIndex + batchSize - 1, maxIndex)
            let range = currentIndex...endIndex
            
            // Execute batch concurrently
            let batchResults = await withTaskGroup(of: (Int, VideoResult?).self) { group in
                for i in range {
                    group.addTask {
                        let url = await self.checkVideoExists(basePath: baseVideoPath, name: person.name, suffix: "\(i)")
                        return (i, url)
                    }
                }
                
                var batchMap: [Int: VideoResult] = [:]
                for await (index, result) in group {
                    if let res = result {
                        batchMap[index] = res
                    }
                }
                return batchMap
            }
            
            // Process batch results sequentially to respect consecutive miss logic
            for i in range {
                if let res = batchResults[i] {
                    results.append(res)
                    consecutiveMisses = 0
                } else {
                    consecutiveMisses += 1
                }
            }
            
            currentIndex += batchSize
        }
        
        return results
    }
    
    /// Checks HEAD for a specific video file
    private func checkVideoExists(basePath: String, name: String, suffix: String) async -> VideoResult? {
        // Handle URL encoding if name contains special chars?
        // dance.ts implies names are used directly.
        let filename = "\(name)\(suffix).mp4"
        let sep = basePath.hasSuffix("/") ? "" : "/"
        
        // Basic percent encoding just in case
        guard let encodedFilename = filename.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed),
              let url = URL(string: "\(basePath)\(sep)\(encodedFilename)") else {
            return nil
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "HEAD"
        request.timeoutInterval = 10
        request.cachePolicy = .reloadIgnoringLocalAndRemoteCacheData // Force check
        
        do {
            let (_, response) = try await URLSession.shared.data(for: request)
            if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 {
                // Return original URL (not encoded 2x) or encoded? 
                // Using the one that worked.
                return VideoResult(personName: name, url: url, filename: filename)
            }
        } catch {
            return nil
        }
        return nil
    }
}
