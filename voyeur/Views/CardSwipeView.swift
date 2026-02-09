import SwiftUI

struct CardSwipeView: View {
    @ObservedObject var viewModel: DanceViewModel
    
    var body: some View {
        GeometryReader { fullGeometry in
            ZStack(alignment: .bottom) {
                #if os(iOS)
                // Continuous Horizontal Scroll for Smooth Browsing
                ScrollViewReader { proxy in
                    ScrollView(.horizontal, showsIndicators: false) {
                        LazyHStack(spacing: 25) {
                            ForEach(Array(viewModel.videos.enumerated()), id: \.element.id) { index, video in
                                VideoCardView(
                                    video: video,
                                    isActive: .init(get: {
                                        abs(index - viewModel.currentIndex) <= 1
                                    }, set: { _ in })
                                )
                                .frame(width: fullGeometry.size.width * 0.82, height: fullGeometry.size.height * 0.85)
                                .clipShape(RoundedRectangle(cornerRadius: 30))
                                .shadow(color: .black.opacity(0.4), radius: 15, x: 0, y: 10)
                                .scrollTransition(axis: .horizontal) { content, phase in
                                    content
                                        .scaleEffect(phase.isIdentity ? 1.0 : 0.85)
                                        .opacity(phase.isIdentity ? 1.0 : 0.5)
                                        .rotation3DEffect(.degrees(phase.value * -10), axis: (x: 0, y: 1, z: 0))
                                        .offset(y: phase.isIdentity ? 0 : 20)
                                }
                                .id(index)
                            }
                        }
                        .padding(.horizontal, fullGeometry.size.width * 0.09)
                        .padding(.top, 20)
                        .scrollTargetLayout()
                    }
                    .scrollTargetBehavior(.viewAligned) // Snaps to cards but allows sweeping past them
                    .background(
                        ZStack {
                            Color.black.ignoresSafeArea()
                            // Dynamic background if needed, or just black
                        }
                    )
                    .onChange(of: viewModel.currentIndex) { oldValue, newValue in
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                            proxy.scrollTo(newValue, anchor: .center)
                        }
                    }
                }
                
                // Navigation Overlay (Arrows and Info)
                VStack {
                    HStack {
                        if viewModel.currentIndex > 0 {
                            Button(action: { viewModel.navigateToPrevious() }) {
                                Image(systemName: "chevron.left.circle.fill")
                                    .font(.system(size: 40))
                                    .foregroundStyle(.white.opacity(0.6))
                            }
                        }
                        Spacer()
                        if viewModel.currentIndex < viewModel.videos.count - 1 {
                            Button(action: { viewModel.navigateToNext() }) {
                                Image(systemName: "chevron.right.circle.fill")
                                    .font(.system(size: 40))
                                    .foregroundStyle(.white.opacity(0.6))
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, fullGeometry.size.height * 0.4) // Middle of cards
                    .allowsHitTesting(true)
                }
                .allowsHitTesting(false) // Don't block scroll interactions except for buttons
                
                #else
                // macOS fallback: Horizontal ScrollView
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 20) {
                        ForEach(viewModel.videos) { video in
                            VideoCardView(
                                video: video,
                                isActive: .constant(true)
                            )
                            .frame(width: 400, height: 600)
                            .clipShape(RoundedRectangle(cornerRadius: 20))
                        }
                    }
                    .padding()
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
