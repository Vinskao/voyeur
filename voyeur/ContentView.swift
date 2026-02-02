//
//  ContentView.swift
//  voyeur
//
//  Created by Vins Kao on 2026/2/2.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @StateObject private var viewModel = DanceViewModel()
    
    var body: some View {
        Group {
            switch viewModel.appState {
            case .welcome:
                WelcomeView(viewModel: viewModel)
            case .loading(let message):
                ZStack {
                    Color.black.edgesIgnoringSafeArea(.all)
                    VStack(spacing: 20) {
                        ProgressView()
                            .scaleEffect(1.5)
                            .tint(.blue)
                        Text(message)
                            .foregroundStyle(.white)
                            .font(.headline)
                        
                        // Show detailed status if available
                        if !viewModel.statusMessage.isEmpty {
                            Text(viewModel.statusMessage)
                                .font(.caption)
                                .foregroundStyle(.gray)
                        }
                    }
                }
            case .browsing:
                CardSwipeView(viewModel: viewModel)
            case .error(let message):
                VStack(spacing: 20) {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.system(size: 50))
                        .foregroundStyle(.yellow)
                    Text("Error Occurred")
                        .font(.title)
                    Text(message)
                        .multilineTextAlignment(.center)
                        .padding()
                    
                    Button("Try Again") {
                        viewModel.reload()
                    }
                    .buttonStyle(.borderedProminent)
                }
            }
        }
#if os(macOS)
        .frame(minWidth: 400, minHeight: 600)
#endif
    }
}

#Preview {
    ContentView()
        .modelContainer(for: Item.self, inMemory: true)
}
