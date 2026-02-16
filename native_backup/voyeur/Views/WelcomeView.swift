import SwiftUI

struct WelcomeView: View {
    @ObservedObject var viewModel: DanceViewModel
    
    // Animation states
    @State private var waterDropOffset: CGFloat = -150
    @State private var waterDropOpacity: Double = 0.0
    @State private var rippleScale: CGFloat = 0.5
    @State private var rippleOpacity: Double = 0.0
    
    var body: some View {
        ZStack {
            Color.black.edgesIgnoringSafeArea(.all)
            
            VStack(spacing: 40) {
                // Rapeum Branding
                Text("Rapeum")
                    .font(.system(size: 48, weight: .bold, design: .serif))
                    .foregroundStyle(.white)
                    .tracking(2.0)
                    .shadow(color: .blue.opacity(0.5), radius: 10, x: 0, y: 0)
                
                // Interactive Water Drop Area
                ZStack {
                    // Ripple Effect (appears after tap/autostart)
                    Circle()
                        .stroke(Color.blue.opacity(0.5), lineWidth: 2)
                        .scaleEffect(rippleScale)
                        .opacity(rippleOpacity)
                        .frame(width: 100, height: 100)
                    
                    // Water Drop
                    Image(systemName: "drop.fill")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 40, height: 40)
                        .foregroundStyle(LinearGradient(
                            colors: [.blue, .cyan],
                            startPoint: .top,
                            endPoint: .bottom
                        ))
                        .offset(y: waterDropOffset)
                        .opacity(waterDropOpacity)
                }
                .contentShape(Rectangle()) // Make area tappable
                .onTapGesture {
                    startLoadingSequence()
                }
                
                Text("Tap to Enter")
                    .font(.caption)
                    .foregroundStyle(.gray)
                    .opacity(0.8)
                
                // Fire Button for Gallery
                Button(action: {
                    viewModel.enterGallery()
                }) {
                    Image(systemName: "flame.fill")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 30, height: 30)
                        .foregroundStyle(.orange)
                        .padding()
                        .background(
                            Circle()
                                .fill(Color.black)
                                .shadow(color: .orange.opacity(0.6), radius: 8, x: 0, y: 0)
                        )
                }
                .padding(.top, 20)
            }
        }
        .onAppear {
            animateEntrance()
        }
    }
    
    private func animateEntrance() {
        // Drop falls down
        withAnimation(.easeInOut(duration: 1.5)) {
            waterDropOpacity = 1.0
            waterDropOffset = 0
        }
    }
    
    private func startLoadingSequence() {
        // Ripple expansion
        withAnimation(.easeOut(duration: 0.8)) {
            rippleScale = 2.0
            rippleOpacity = 1.0
        }
        
        withAnimation(.easeOut(duration: 0.8).delay(0.2)) {
            rippleOpacity = 0.0
        }
        
        // Trigger ViewModel loading
        Task {
            // Slight delay for animation to feel "reacted"
            try? await Task.sleep(for: .seconds(0.5))
            await viewModel.scanForVideos()
        }
    }
}

#Preview {
    WelcomeView(viewModel: DanceViewModel())
}
