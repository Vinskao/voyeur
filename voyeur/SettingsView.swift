import SwiftUI
import SwiftData

struct SettingsView: View {
    @AppStorage("dance_video_base_url") private var baseURL: String = ""
    @State private var isTesting: Bool = false
    @State private var testResult: String?
    
    var body: some View {
        Form {
            Section(header: Text("Configuration")) {
                VStack(alignment: .leading) {
                    Text("Environment Default:")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(AppConfig.defaultBaseURL)
                        .font(.footnote)
                        .monospaced()
                }
                
                TextField("Override Base URL", text: $baseURL)
                    .autocorrectionDisabled()
#if os(iOS)
                    .textInputAutocapitalization(.never)
                    .keyboardType(.URL)
#endif
                
                Button("Test Connection") {
                    testConnection()
                }
                .disabled(baseURL.isEmpty || isTesting)
                
                if let result = testResult {
                    Text(result)
                        .font(.caption)
                        .foregroundStyle(result.contains("Success") ? .green : .red)
                }
            }
            
            Section(header: Text("Cache Management")) {
                Button("Clear All Cache") {
                    VideoCacheManager.shared.clearAllCache()
                }
                .foregroundStyle(.red)
            }
        }
        .navigationTitle("Settings")
    }
    
    private func testConnection() {
        guard let url = URL(string: baseURL) else {
            testResult = "Invalid URL"
            return
        }
        
        isTesting = true
        testResult = "Testing..."
        
        var request = URLRequest(url: url)
        request.httpMethod = "HEAD"
        request.timeoutInterval = 5
        
        URLSession.shared.dataTask(with: request) { _, response, error in
            DispatchQueue.main.async {
                isTesting = false
                if let _ = error {
                    testResult = "Connection Failed"
                } else if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 {
                    testResult = "Success (200 OK)"
                } else {
                    testResult = "Success (Server Reachable)"
                }
            }
        }.resume()
    }
}

#Preview {
    SettingsView()
        .modelContainer(for: Item.self, inMemory: true)
}
