import Foundation
import Combine

class VideoCacheManager: ObservableObject {
    static let shared = VideoCacheManager()
    
    private let fileManager = FileManager.default
    private let cacheDirectoryName = "DanceVideos"
    
    @Published var downloadProgress: [String: Double] = [:]
    
    // MARK: - Directory Management
    
    private var cacheDirectoryURL: URL? {
        guard let cacheDir = fileManager.urls(for: .cachesDirectory, in: .userDomainMask).first else {
            return nil
        }
        return cacheDir.appendingPathComponent(cacheDirectoryName)
    }
    
    init() {
        createCacheDirectoryIfNeeded()
    }
    
    private func createCacheDirectoryIfNeeded() {
        guard let url = cacheDirectoryURL else { return }
        if !fileManager.fileExists(atPath: url.path) {
            try? fileManager.createDirectory(at: url, withIntermediateDirectories: true)
        }
    }
    
    // MARK: - File Operations
    
    func getCachedFileURL(filename: String) -> URL? {
        return cacheDirectoryURL?.appendingPathComponent(filename)
    }
    
    func isVideoCached(filename: String) -> Bool {
        guard let url = getCachedFileURL(filename: filename) else { return false }
        return fileManager.fileExists(atPath: url.path)
    }
    
    func clearAllCache() {
        guard let url = cacheDirectoryURL else { return }
        do {
            let fileURLs = try fileManager.contentsOfDirectory(at: url, includingPropertiesForKeys: nil)
            for fileURL in fileURLs {
                try fileManager.removeItem(at: fileURL)
            }
            print("Cache cleared successfully.")
        } catch {
            print("Error clearing cache: \(error)")
        }
        
        // Notify UI update implicitly via objectWillChange if needed, 
        // though strictly file existence checks are pull-based usually.
        DispatchQueue.main.async {
            self.objectWillChange.send()
        }
    }
    
    // MARK: - Download Logic
    
    func cacheVideo(url: URL, filename: String) async throws {
        guard let destinationURL = getCachedFileURL(filename: filename) else {
            throw VideoCacheError.invalidDestination
        }
        
        // Check if already exists
        if fileManager.fileExists(atPath: destinationURL.path) {
            return // Already cached
        }
        
        let (tempURL, response) = try await URLSession.shared.download(from: url)
        
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw VideoCacheError.downloadFailed
        }
        
        // Move file to permanent location
        if fileManager.fileExists(atPath: destinationURL.path) {
             try fileManager.removeItem(at: destinationURL)
        }
        try fileManager.moveItem(at: tempURL, to: destinationURL)
        
        print("Downloaded and cached: \(filename)")
    }
}

enum VideoCacheError: Error {
    case invalidDestination
    case downloadFailed
}
