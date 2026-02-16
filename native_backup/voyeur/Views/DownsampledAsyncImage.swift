import SwiftUI

enum ImageLoadingState {
    case loading
    case success(UIImage)
    case failure
}

struct DownsampledAsyncImage<Content: View, Placeholder: View, Failure: View>: View {
    let url: URL
    let targetSize: CGSize
    let content: (Image) -> Content
    let placeholder: () -> Placeholder
    let failure: () -> Failure
    
    @StateObject private var loader = ImageLoader()
    
    init(
        url: URL,
        targetSize: CGSize = CGSize(width: 300, height: 300),
        @ViewBuilder content: @escaping (Image) -> Content,
        @ViewBuilder placeholder: @escaping () -> Placeholder,
        @ViewBuilder failure: @escaping () -> Failure
    ) {
        self.url = url
        self.targetSize = targetSize
        self.content = content
        self.placeholder = placeholder
        self.failure = failure
    }
    
    var body: some View {
        Group {
            switch loader.state {
            case .loading:
                placeholder()
            case .success(let uiImage):
                content(Image(uiImage: uiImage))
            case .failure:
                failure()
            }
        }
        .onAppear {
            loader.loadImage(from: url, targetSize: targetSize)
        }
        .onDisappear {
            loader.cancel()
        }
    }
}

class ImageLoader: ObservableObject {
    @Published var state: ImageLoadingState = .loading
    private var task: URLSessionDataTask?
    
    func loadImage(from url: URL, targetSize: CGSize) {
        // Simple cache check could be added here
        
        state = .loading
        
        let config = URLSessionConfiguration.default
        config.urlCache = URLCache.shared
        config.requestCachePolicy = .returnCacheDataElseLoad
        let session = URLSession(configuration: config)
        
        task = session.dataTask(with: url) { [weak self] data, response, error in
            guard let self = self else { return }
            
            if let error = error {
                print("Image load error: \(error)")
                DispatchQueue.main.async { self.state = .failure }
                return
            }
            
            guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200, let data = data else {
                DispatchQueue.main.async { self.state = .failure }
                return
            }
            
            // Downsample on background thread
            DispatchQueue.global(qos: .userInitiated).async {
                if let downsampled = self.downsample(imageData: data, to: targetSize) {
                    DispatchQueue.main.async {
                        self.state = .success(downsampled)
                    }
                } else {
                    DispatchQueue.main.async {
                        self.state = .failure
                    }
                }
            }
        }
        task?.resume()
    }
    
    func cancel() {
        task?.cancel()
    }
    
    private func downsample(imageData: Data, to pointSize: CGSize) -> UIImage? {
        let options = [kCGImageSourceShouldCache: false] as CFDictionary
        guard let source = CGImageSourceCreateWithData(imageData as CFData, options) else { return nil }
        
        let maxDimensionInPixels = max(pointSize.width, pointSize.height) * UIScreen.main.scale
        let downsampleOptions = [
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceShouldCacheImmediately: true,
            kCGImageSourceCreateThumbnailWithTransform: true,
            kCGImageSourceThumbnailMaxPixelSize: maxDimensionInPixels
        ] as CFDictionary
        
        guard let downsampledImage = CGImageSourceCreateThumbnailAtIndex(source, 0, downsampleOptions) else { return nil }
        return UIImage(cgImage: downsampledImage)
    }
}
