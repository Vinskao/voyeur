import SwiftUI

struct PeopleGalleryView: View {
    @ObservedObject var viewModel: DanceViewModel
    @State private var people: [Person] = []
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var selectedPerson: Person?
    
    var groupedPeople: [String: [Person]] {
        Dictionary(grouping: people, by: { $0.originArmyName ?? "Unknown" })
    }
    
    var sortedArmyNames: [String] {
        groupedPeople.keys.sorted()
    }
    
    var body: some View {
        ZStack { // Root ZStack
            ZStack {
                Color.black.edgesIgnoringSafeArea(.all)
                
                if isLoading {
                    ProgressView()
                        .tint(.white)
                } else if let error = errorMessage {
                    Text(error)
                        .foregroundStyle(.red)
                } else {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 20) {
                            ForEach(sortedArmyNames, id: \.self) { armyName in
                                VStack(alignment: .leading) {
                                    Text(armyName)
                                        .font(.title2)
                                        .bold()
                                        .foregroundStyle(.white)
                                        .padding(.leading)
                                    
                                    ScrollView(.horizontal, showsIndicators: false) {
                                        HStack(spacing: -20) { // Negative spacing for overlap effect
                                            ForEach(groupedPeople[armyName] ?? []) { person in
                                                Button(action: {
                                                    withAnimation {
                                                        selectedPerson = person
                                                    }
                                                }) {
                                                    if let url = URL(string: "https://peoplesystem.tatdvsonorth.com/images/people/\(person.name).png") {
                                                        DownsampledAsyncImage(
                                                            url: url,
                                                            targetSize: CGSize(width: 300, height: 450),
                                                            content: { image in
                                                                image
                                                                    .resizable()
                                                                    .scaledToFit()
                                                                    .frame(height: 150)
                                                                    .clipShape(RoundedRectangle(cornerRadius: 10))
                                                            },
                                                            placeholder: {
                                                                ProgressView()
                                                                    .frame(width: 100, height: 150)
                                                            },
                                                            failure: {
                                                                EmptyView()
                                                            }
                                                        )
                                                    }
                                                }
                                            }
                                        }
                                        .padding(.horizontal)
                                    }
                                }
                            }
                        }
                        .padding(.vertical)
                        // Add extra padding at bottom to ensure last row is visible
                        .padding(.bottom, 50) 
                    }
                }
                
                // Full Screen Overlay
                if let selected = selectedPerson {
                    ZStack {
                        Color.black.opacity(0.9).edgesIgnoringSafeArea(.all)
                            .onTapGesture {
                                withAnimation {
                                    selectedPerson = nil
                                }
                            }
                        
                        if let url = URL(string: "https://peoplesystem.tatdvsonorth.com/images/people/\(selected.name).png") {
                            DownsampledAsyncImage(
                                url: url,
                                targetSize: CGSize(width: 1080, height: 1920),
                                content: { image in
                                    image
                                        .resizable()
                                        .scaledToFit()
                                },
                                placeholder: {
                                    ProgressView()
                                        .tint(.white)
                                },
                                failure: {
                                    VStack {
                                        Image(systemName: "exclamationmark.triangle")
                                            .foregroundStyle(.white)
                                        Text("Image Unavailable")
                                            .foregroundStyle(.white)
                                            .font(.caption)
                                    }
                                }
                            )
                        }
                        .onTapGesture {
                            withAnimation {
                                selectedPerson = nil
                            }
                        }
                    }
                    .transition(.opacity)
                    .zIndex(1) // Ensure it's on top
                }
            }
            .onAppear {
                loadPeople()
            }
            
            // Add back button overlay
            VStack {
                HStack {
                    Button(action: {
                        withAnimation {
                            viewModel.appState = .welcome
                        }
                    }) {
                        Image(systemName: "chevron.left")
                            .foregroundStyle(.white)
                            .padding()
                            .background(Color.black.opacity(0.5))
                            .clipShape(Circle())
                    }
                    .padding()
                    Spacer()
                }
                Spacer()
            }
        }
    }
    
    private func loadPeople() {
        isLoading = true
        Task {
            do {
                people = try await PeopleService.shared.fetchPeople()
                isLoading = false
            } catch {
                errorMessage = "Failed to load people: \(error.localizedDescription)"
                isLoading = false
            }
        }
    }
}

#Preview {
    PeopleGalleryView(viewModel: DanceViewModel())
}
