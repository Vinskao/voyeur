import SwiftUI

struct CardSwipeView: View {
    @ObservedObject var viewModel: DanceViewModel
    
    var body: some View {
        GeometryReader { fullGeometry in
            ZStack(alignment: .bottom) {
                #if os(iOS)
                // Standard Horizontal TabView (Swipe Left/Right)
                TabView {
                    ForEach(viewModel.videos) { (video: VideoResult) in
                        VideoCardView(video: video)
                            .frame(width: fullGeometry.size.width, height: fullGeometry.size.height)
                            // No rotation needed for standard horizontal swipe
                    }
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
                .frame(width: fullGeometry.size.width, height: fullGeometry.size.height)
                .background(Color.black)
                .ignoresSafeArea()
                #else
                // macOS fallback: Horizontal ScrollView? Or stick to vertical?
                // Let's use Horizontal ScrollView for consistency if requested, but vertical flow is common on desktop.
                // Keeping vertical for macOS native, unless user insists.
                ScrollView(.vertical, showsIndicators: false) {
                    VStack(spacing: 0) {
                        ForEach(viewModel.videos) { video in
                            VideoCardView(video: video)
                                .frame(width: fullGeometry.size.width, height: fullGeometry.size.height)
                        }
                    }
                }
                .background(Color.black)
                #endif
                
                // Reload Button Overlay
                // Placing it in a separate ZStack layer to ensure it floats above
                VStack {
                    Spacer()
                    Button(action: {
                        viewModel.reload()
                    }) {
                        Image(systemName: "arrow.clockwise.circle.fill")
                            .resizable()
                            .frame(width: 50, height: 50)
                            .foregroundStyle(.white.opacity(0.8))
                            .shadow(radius: 5)
                            .background(Color.black.opacity(0.3).clipShape(Circle())) // Add backing for visibility
                    }
                    .padding(.bottom, 60) // Lift up from bottom edge
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
            }
        }
        .edgesIgnoringSafeArea(.all)
    }
}
