
import Foundation

enum AppEnvironment: String {
    case dev
    case prod
}

enum AppConfig {
    // Current Environment Setting (Persisted)
    static var environment: AppEnvironment {
        get {
            if let stored = UserDefaults.standard.string(forKey: "app_environment"),
               let env = AppEnvironment(rawValue: stored) {
                return env
            }
            return .dev // Default
        }
        set {
            UserDefaults.standard.set(newValue.rawValue, forKey: "app_environment")
        }
    }
    
    // API Base URL (Gateway)
    static var apiBaseURL: String {
        // Priority 1: UserDefaults override
        if let stored = UserDefaults.standard.string(forKey: "api_base_url_v2"), !stored.isEmpty {
            return stored
        }
        
        return "https://peoplesystem.tatdvsonorth.com/tymg"
    }
    
    // Resource Base URL (Media/Images)
    static var resourceBaseURL: String {
        // Priority 1: UserDefaults override
        if let stored = UserDefaults.standard.string(forKey: "resource_base_url_v2"), !stored.isEmpty {
            return stored
        }
        
        // Both envs use the remote S3/Web server for heavy assets
        return "https://peoplesystem.tatdvsonorth.com"
    }
}
