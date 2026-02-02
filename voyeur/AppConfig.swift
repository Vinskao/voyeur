
import Foundation

enum AppConfig {
    static let defaultBaseURL = "http://peoplesystem.tatdvsonorth.com"
    
    static var baseURL: String {
        // Priority 1: UserDefaults override (Settings UI)
        if let stored = UserDefaults.standard.string(forKey: "dance_video_base_url"), !stored.isEmpty {
            return stored
        }
        
        // Priority 2: Environment Variable (Set in Xcode Scheme -> Arguments -> Environment Variables)
        if let env = ProcessInfo.processInfo.environment["DANCE_VIDEO_BASE_URL"], !env.isEmpty {
            return env
        }
        
        // Priority 3: Hardcoded Default
        return defaultBaseURL
    }
}
