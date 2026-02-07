import SwiftUI
import AVKit

struct VideoCardView: View {
    let video: VideoResult
    @Binding var isActive: Bool
    @State private var player: AVPlayer?
    
    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            GeometryReader { geometry in
                if isActive {
                    // Active: Show playing video
                    if let player = player {
                        VideoPlayerView(player: player)
                            .edgesIgnoringSafeArea(.all)
                            .frame(width: geometry.size.width, height: geometry.size.height)
                    } else {
                        Color.black.edgesIgnoringSafeArea(.all)
                        ProgressView()
                            .tint(.white)
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
                .font(.title2)
                .bold()
                .foregroundStyle(.white)
                .shadow(radius: 2)
                .padding()
                .background(
                    LinearGradient(
                        colors: [.black.opacity(0.6), .clear],
                        startPoint: .bottomTrailing,
                        endPoint: .topLeading
                    )
                )
                .cornerRadius(8)
                .padding(20)
        }
        .onAppear {
            setupPlayer()
        }
        .onChange(of: isActive) { oldValue, newValue in
            if newValue {
                player?.play()
            } else {
                player?.pause()
            }
        }
        .onDisappear {
            player?.pause()
        }
    }
    
    private func setupPlayer() {
        // Use cached file if available, otherwise remote URL
        let finalURL: URL
        if let cacheURL = VideoCacheManager.shared.getCachedFileURL(filename: video.filename),
           FileManager.default.fileExists(atPath: cacheURL.path) {
            finalURL = cacheURL
        } else {
            finalURL = video.url
        }
        
        let playerItem = AVPlayerItem(url: finalURL)
        self.player = AVPlayer(playerItem: playerItem)
        self.player?.actionAtItemEnd = .none // Prevent pause on end
        
        // Boomerang Logic (Forward <-> Backward)
        // 1. When video ends (Forward)
        // Capture 'player' (class type) instead of 'self' (struct type)
        NotificationCenter.default.addObserver(
            forName: .AVPlayerItemDidPlayToEndTime,
            object: playerItem,
            queue: .main
        ) { [weak player] _ in
            guard let player = player else { return }
            // Seek to barely before the end so reverse works reliably
            let duration = player.currentItem?.duration ?? .zero
            player.seek(to: duration, toleranceBefore: .zero, toleranceAfter: .zero)
            player.rate = -1.0 // Reverse playback
        }
        
        // 2. When video hits start (Backward)
        let timeZero = CMTime(value: 0, timescale: 1)
        let timeStart = NSValue(time: timeZero)
        
        self.player?.addBoundaryTimeObserver(forTimes: [timeStart], queue: .main) { [weak player] in
            guard let player = player else { return }
            if player.rate == -1.0 || player.rate == 0.0 {
                player.rate = 1.0 // Forward playback
            }
        }
        
        // Start playing if active
        if isActive {
            player?.play()
        }
    }
}
