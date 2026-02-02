import SwiftUI

struct CardSwipeView: View {
    @ObservedObject var viewModel: DanceViewModel
    
    var body: some View {
        GeometryReader { fullGeometry in
            ZStack(alignment: .bottom) {
                TabView {
                    ForEach(viewModel.videos, id: \.id) { video in
                        VideoCardView(video: video)
                            .frame(width: fullGeometry.size.width, height: fullGeometry.size.height)
                            .rotationEffect(.degrees(-90))
                    }
                }
                .frame(width: fullGeometry.size.height, height: fullGeometry.size.width)
                .rotationEffect(.degrees(90), anchor: .topLeading)
                .offset(x: fullGeometry.size.width)
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
                .background(Color.black)
                .edgesIgnoringSafeArea(.all)
                
                // Reload Button Overlay
                Button(action: {
                    viewModel.reload()
                }) {
                    Image(systemName: "arrow.clockwise.circle.fill")
                        .resizable()
                        .frame(width: 50, height: 50)
                        .foregroundStyle(.white.opacity(0.8))
                        .shadow(radius: 5)
                }
                .padding(.bottom, 50)
            }
        }
    }
}
