import SwiftUI
import SwiftData

struct SettingsView: View {
    @AppStorage("dance_video_base_url") private var baseURL: String = ""
    @State private var isTesting: Bool = false
    @State private var testResult: String?
    
    var body: some View {
        Form {
            Section(header: Text("Configuration")) {
                Picker("Environment", selection: Binding(
                    get: { AppConfig.environment },
                    set: { AppConfig.environment = $0 }
                )) {
                    Text("Development (Local)").tag(AppEnvironment.dev)
                    Text("Production (Remote)").tag(AppEnvironment.prod)
                }
                .pickerStyle(.segmented)
                
                VStack(alignment: .leading) {
                    Text("API URL (Gateway):")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(AppConfig.apiBaseURL)
                        .font(.caption2)
                        .monospaced()
                        .foregroundStyle(.blue)
                    
                    Divider()
                    
                    Text("Resource URL (Media):")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(AppConfig.resourceBaseURL)
                        .font(.caption2)
                        .monospaced()
                        .foregroundStyle(.green)
                }
                .padding(.vertical, 4)
                
                TextField("Override API URL", text: $baseURL)
                    .autocorrectionDisabled()
#if os(iOS)
                    .textInputAutocapitalization(.never)
                    .keyboardType(.URL)
#endif
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
