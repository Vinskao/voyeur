import SwiftUI

struct CardSwipeView: View {
    @ObservedObject var viewModel: DanceViewModel
    
    var body: some View {
        GeometryReader { fullGeometry in
            ZStack(alignment: .bottom) {
                #if os(iOS)
                // Custom Carousel with TabView (more reliable than ScrollView for paging)
                TabView(selection: $viewModel.currentIndex) {
                    ForEach(Array(viewModel.videos.enumerated()), id: \.element.id) { index, video in
                        let isActive = index == viewModel.currentIndex
                        
                        VideoCardView(
                            video: video,
                            isActive: .constant(isActive)
                        )
                        .frame(width: fullGeometry.size.width, height: fullGeometry.size.height)
                        .tag(index)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .background(Color.black)
                .ignoresSafeArea()
                
                // Side Preview Overlay (show adjacent videos as previews)
                HStack(spacing: 0) {
                    // Left preview
                    if viewModel.currentIndex > 0 {
                        VideoThumbnailView(video: viewModel.videos[viewModel.currentIndex - 1])
                            .frame(width: fullGeometry.size.width * 0.15, height: fullGeometry.size.height * 0.3)
                            .opacity(0.6)
                            .scaleEffect(0.85)
                            .padding(.leading, 10)
                    }
                    
                    Spacer()
                    
                    // Right preview
                    if viewModel.currentIndex < viewModel.videos.count - 1 {
                        VideoThumbnailView(video: viewModel.videos[viewModel.currentIndex + 1])
                            .frame(width: fullGeometry.size.width * 0.15, height: fullGeometry.size.height * 0.3)
                            .opacity(0.6)
                            .scaleEffect(0.85)
                            .padding(.trailing, 10)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                .allowsHitTesting(false) // Don't intercept touches
                
                // Navigation Buttons Overlay
                HStack {
                    // Left Arrow Button
                    if viewModel.canNavigatePrevious {
                        Button(action: {
                            withAnimation(.easeInOut(duration: 0.3)) {
                                viewModel.navigateToPrevious()
                            }
                        }) {
                            Image(systemName: "chevron.left.circle.fill")
                                .resizable()
                                .frame(width: 50, height: 50)
                                .foregroundStyle(.white.opacity(0.7))
                                .shadow(radius: 5)
                        }
                        .padding(.leading, 20)
                    }
                    
                    Spacer()
                    
                    // Right Arrow Button
                    if viewModel.canNavigateNext {
                        Button(action: {
                            withAnimation(.easeInOut(duration: 0.3)) {
                                viewModel.navigateToNext()
                            }
                        }) {
                            Image(systemName: "chevron.right.circle.fill")
                                .resizable()
                                .frame(width: 50, height: 50)
                                .foregroundStyle(.white.opacity(0.7))
                                .shadow(radius: 5)
                        }
                        .padding(.trailing, 20)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                .padding(.bottom, 100) // Position in middle, not at bottom
                
                #else
                // macOS fallback: Horizontal ScrollView
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 0) {
                        ForEach(Array(viewModel.videos.enumerated()), id: \.element.id) { index, video in
                            let isActive = index == viewModel.currentIndex
                            
                            VideoCardView(
                                video: video,
                                isActive: .constant(isActive)
                            )
                            .frame(width: fullGeometry.size.width, height: fullGeometry.size.height)
                        }
                    }
                }
                .background(Color.black)
                #endif
                
                // Reload Button Overlay
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
                            .background(Color.black.opacity(0.3).clipShape(Circle()))
                    }
                    .padding(.bottom, 60)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
            }
        }
        .edgesIgnoringSafeArea(.all)
    }
}
