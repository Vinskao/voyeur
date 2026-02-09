import SwiftUI
import AVFoundation

struct VideoThumbnailView: View {
    let video: VideoResult
    @State private var thumbnailImage: UIImage?
    @State private var isLoading = true
    
    var body: some View {
        ZStack {
            Color.black
            
            if let image = thumbnailImage {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
            } else if isLoading {
                ProgressView()
                    .tint(.white)
            }
        }
        .onAppear {
            generateThumbnail()
        }
    }
    
    private func generateThumbnail() {
        Task {
            // Use cached file if available, otherwise remote URL
            let finalURL: URL
            if let cacheURL = VideoCacheManager.shared.getCachedFileURL(filename: video.filename),
               FileManager.default.fileExists(atPath: cacheURL.path) {
                finalURL = cacheURL
            } else {
                finalURL = video.url
            }
            
            let asset = AVURLAsset(url: finalURL)
            let imageGenerator = AVAssetImageGenerator(asset: asset)
            imageGenerator.appliesPreferredTrackTransform = true
            imageGenerator.requestedTimeToleranceAfter = .zero
            imageGenerator.requestedTimeToleranceBefore = .zero
            
            // Increase timeout for remote videos
            imageGenerator.maximumSize = CGSize(width: 1920, height: 1080)
            
            do {
                // Wait for asset to be ready first
                let isPlayable = try await asset.load(.isPlayable)
                guard isPlayable else {
                    print("Asset not playable for \(video.filename)")
                    await MainActor.run {
                        self.isLoading = false
                    }
                    return
                }
                
                // Generate thumbnail at 1 second into the video
                let time = CMTime(seconds: 1.0, preferredTimescale: 600)
                let (cgImage, _) = try await imageGenerator.image(at: time)
                await MainActor.run {
                    self.thumbnailImage = UIImage(cgImage: cgImage)
                    self.isLoading = false
                }
            } catch {
                print("Failed to generate thumbnail for \(video.filename): \(error)")
                await MainActor.run {
                    self.isLoading = false
                }
            }
        }
    }
}
