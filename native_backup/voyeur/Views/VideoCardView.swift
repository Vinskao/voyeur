import SwiftUI
import AVKit

struct VideoCardView: View {
    let video: VideoResult
    @Binding var isActive: Bool
    @State private var player: AVQueuePlayer?
    @State private var looper: AVPlayerLooper?
    @State private var isReadyToPlay = false
    @State private var loadError = false
    @State private var observer: Any?
    
    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            GeometryReader { geometry in
                if isActive {
                    // Active: Show playing video
                    ZStack {
                        if let player = player {
                            VideoPlayerView(player: player)
                                .edgesIgnoringSafeArea(.all)
                                .onAppear { player.play() }
                                .opacity(isReadyToPlay ? 1 : 0)
                        }
                        
                        if !isReadyToPlay && !loadError {
                            Color.black.edgesIgnoringSafeArea(.all)
                            ProgressView()
                                .tint(.white)
                        }
                        
                        if loadError {
                            VStack {
                                Image(systemName: "video.slash")
                                    .font(.largeTitle)
                                Text("Failed to load video")
                                    .font(.caption)
                            }
                            .foregroundStyle(.white)
                        }
                    }
                    .frame(width: geometry.size.width, height: geometry.size.height)
                    .onAppear {
                        if player == nil { setupPlayer() }
                    }
                } else {
                    // Inactive: Show static thumbnail
                    VideoThumbnailView(video: video)
                        .edgesIgnoringSafeArea(.all)
                        .frame(width: geometry.size.width, height: geometry.size.height)
                }
            }
            
            // Name Overlay
            Text(video.personName)
                .font(.headline)
                .bold()
                .foregroundStyle(.white)
                .shadow(radius: 2)
                .padding(8)
                .background(.ultraThinMaterial)
                .cornerRadius(8)
                .padding(12)
        }
        .onAppear {
            if isActive {
                setupPlayer()
            }
        }
        .onChange(of: isActive) { oldValue, newValue in
            if newValue {
                setupPlayer()
            } else {
                cleanupPlayer()
            }
        }
        .onDisappear {
            player?.pause()
            player = nil 
            looper = nil
        }
    }
    
    private func setupPlayer() {
        if player != nil {
            if isActive { player?.play() }
            return
        }
        
        let finalURL: URL
        if let cacheURL = VideoCacheManager.shared.getCachedFileURL(filename: video.filename),
           FileManager.default.fileExists(atPath: cacheURL.path) {
            finalURL = cacheURL
        } else {
            finalURL = video.url
        }
        
        let asset = AVAsset(url: finalURL)
        let playerItem = AVPlayerItem(asset: asset)
        
        // Observe status to hide loading spinner
        self.observer = playerItem.observe(\.status) { item, _ in
            DispatchQueue.main.async {
                switch item.status {
                case .readyToPlay:
                    self.isReadyToPlay = true
                    self.loadError = false
                case .failed:
                    self.loadError = true
                    print("Player item failed for \(video.filename): \(String(describing: item.error))")
                default:
                    break
                }
            }
        }
        
        let queuePlayer = AVQueuePlayer(playerItem: playerItem)
        queuePlayer.preventsDisplaySleepDuringVideoPlayback = true
        
        self.looper = AVPlayerLooper(player: queuePlayer, templateItem: playerItem)
        self.player = queuePlayer
        
        if isActive {
            player?.play()
        }
    }
    
    private func cleanupPlayer() {
        player?.pause()
        player = nil
        looper = nil
        isReadyToPlay = false
        loadError = false
        // The observer should be removed automatically when playerItem is deallocated,
        // but it's good practice to clear references.
        observer = nil
    }
}
