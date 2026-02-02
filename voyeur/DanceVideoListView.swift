import SwiftUI

struct DanceVideoListView: View {
    @StateObject private var viewModel = DanceViewModel()
    
    var body: some View {
        List {
            Section(header: Text("Actions")) {
                Button(action: {
                    Task {
                        await viewModel.scanForVideos()
                    }
                }) {
                    Label("Scan for Videos", systemImage: "arrow.counterclockwise")
                }
                .disabled(viewModel.isLoading)
                
                Button(action: {
                    Task {
                        await viewModel.downloadAll()
                    }
                }) {
                    Label("Download All", systemImage: "square.and.arrow.down")
                }
                .disabled(viewModel.videos.isEmpty || viewModel.isLoading)
                
                if !viewModel.statusMessage.isEmpty {
                    Text(viewModel.statusMessage)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            
            Section(header: Text("Videos")) {
                if viewModel.videos.isEmpty {
                    Text("No videos found. Configure Base URL in Settings and Scan.")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(viewModel.videos, id: \._id) { video in
                        HStack {
                            VStack(alignment: .leading) {
                                Text(video.displayName)
                                    .font(.headline)
                                Text(video.filename)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            
                            Spacer()
                            
                            if viewModel.isCached(video) {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(.green)
                            } else {
                                Image(systemName: "icloud.and.arrow.down")
                                    .foregroundStyle(.gray)
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle("Dance Videos")
        .toolbar {
             ToolbarItem(placement: .primaryAction) {
                 NavigationLink(destination: SettingsView()) {
                     Label("Settings", systemImage: "gear")
                 }
             }
        }
    }
}

#Preview {
    DanceVideoListView()
}
