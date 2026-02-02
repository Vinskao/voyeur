import SwiftUI
import AVKit

struct VideoCardView: View {
    let video: VideoResult
    @State private var player: AVPlayer?
    
    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            GeometryReader { geometry in
                if let player = player {
                    VideoPlayer(player: player)
                        .edgesIgnoringSafeArea(.all)
                        .frame(width: geometry.size.width, height: geometry.size.height)
                        .onAppear {
                            player.play()
                        }
                } else {
                    Color.black.edgesIgnoringSafeArea(.all)
                    ProgressView()
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
        self.player?.actionAtItemEnd = .none
        
        // Loop Logic
        NotificationCenter.default.addObserver(
            forName: .AVPlayerItemDidPlayToEndTime,
            object: playerItem,
            queue: .main
        ) { _ in
            self.player?.seek(to: .zero)
            self.player?.play()
        }
    }
}
