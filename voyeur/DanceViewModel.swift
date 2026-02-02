import Foundation
import Combine

enum AppState {
    case welcome
    case loading(String)
    case browsing
    case error(String)
}

@MainActor
class DanceViewModel: ObservableObject {
    @Published var appState: AppState = .welcome
    @Published var videos: [VideoResult] = []
    
    private let peopleService = PeopleService.shared
    private let videoProber = VideoProber.shared
    private let cacheManager = VideoCacheManager.shared
    
    // Status message for legacy compatibility or simple status display
    @Published var statusMessage: String = ""
    @Published var isLoading: Bool = false
    
    func scanForVideos() async {
        appState = .loading("Fetching character list...")
        statusMessage = "Fetching character list..."
        isLoading = true
        
        do {
            // 1. Fetch People
            let people = try await peopleService.fetchPeople()
            appState = .loading("Probing videos for \(people.count) characters...")
            statusMessage = "Found \(people.count) characters. Probing videos..."
            
            // 2. Probe Videos concurrently (Chunked to avoid flooding)
            var foundVideos: [VideoResult] = []
            let characters = people // .prefix(10) // Debug: Limit to 10 for speed if needed
            
            // simple chunkSize for characters
            let chunkSize = 5 
            var processedCount = 0
            
            for chunk in characters.chunked(into: chunkSize) {
                await withTaskGroup(of: [VideoResult].self) { group in
                    for person in chunk {
                        group.addTask {
                            return await self.videoProber.probeCharacter(person: person)
                        }
                    }
                    
                    for await res in group {
                        foundVideos.append(contentsOf: res)
                    }
                }
                processedCount += chunk.count
                let msg = "Scanned \(processedCount)/\(characters.count) characters..."
                print(msg)
                appState = .loading(msg)
            }
            
            self.videos = foundVideos
            
            if videos.isEmpty {
                appState = .error("No videos found.")
                statusMessage = "No videos found."
            } else {
                appState = .browsing
                statusMessage = "Found \(videos.count) videos."
            }
            
        } catch {
            appState = .error(error.localizedDescription)
            statusMessage = "Error: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
    
    func downloadAll() async {
        guard !videos.isEmpty else { return }
        
        appState = .loading("Downloading \(videos.count) videos...")
        statusMessage = "Starting download..."
        isLoading = true
        
        let total = videos.count
        var completed = 0
        
        // Similar chunked download logic can go here, or delegate to CacheManager
        // For now, naive loop or delegate
        for video in videos {
             do {
                 try await cacheManager.cacheVideo(url: video.url, filename: video.filename)
                 completed += 1
                 statusMessage = "Downloaded \(completed)/\(total)"
             } catch {
                 print("Failed to download \(video.filename): \(error)")
             }
        }
        
        statusMessage = "Download complete."
        appState = .browsing
        isLoading = false
    }
    
    // Helper to clear and reload
    func reload() {
        videos.removeAll()
        cacheManager.clearAllCache()
        Task {
            await scanForVideos()
        }
    }
    
    // Check if a specific video result is cached
    func isCached(_ video: VideoResult) -> Bool {
        return cacheManager.isVideoCached(filename: video.filename)
    }
}

// Helper for chunking
extension Array {
    func chunked(into size: Int) -> [[Element]] {
        return stride(from: 0, to: count, by: size).map {
            Array(self[$0 ..< Swift.min($0 + size, count)])
        }
    }
}
