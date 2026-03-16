# Agent Project Instructions

## Target Environment
- **Device**: iPhone 17 Pro Max
- **OS**: iOS 26.2
- **Aesthetics**: Modern, premium, optimized for high-refresh-rate large displays and the latest Apple silicon.

## Configuration Principles
1. **Modern SwiftUI**: Always use the latest SwiftUI APIs. Avoid deprecated modifiers like `.autocapitalization`.
2. **Platform Checks**: Use `#if os(iOS)` or `#if os(macOS)` to ensure multiplatform compatibility while optimizing for the primary target (iPhone 17 Pro Max).
3. **High-Performance Defaults**: Since the target is a Pro Max device, prioritize high-quality assets, smooth animations, and generous layouts.
4. **Resilient Configurations**: Ensure configurations (like `AppConfig`) follow a clear hierarchy (UserDefaults > Environment Variables > Defaults).

## Specific Values Style
- Use descriptive, namespaced keys for configuration (e.g., `dance_video_base_url`).
- Ensure all input fields are optimized for mobile (DNS/URL keyboard types, text input autocapitalization disabled for technical fields).

## Troubleshooting & Maintenance

### Xcode Build Issues (DerivedData)
If you encounter errors like "failed to save attachment" or "unable to write manifest.json", it usually indicates a corrupted build cache.
**Clean Command:**
```bash
rm -rf ~/Library/Developer/Xcode/DerivedData/voyeur-*
```
Then in Xcode: `Shift + Command + K` (Clean Build Folder).

### Dependency Issues
If Swift Package Manager (SPM) or CocoaPods acts up:
- **SPM**: `File` > `Packages` > `Reset Package Caches`.
- **General Cache**: `rm -rf ~/Library/Caches/org.swift.swiftpm`

### Data Synchronization (Backend & Articles)
If the `articles` table is empty or needs a manual refresh:
1. **Frontend Sync**: Trigger from the frontend API which reads local markdown files and pushes to backend.
   ```bash
   curl -X POST http://localhost:4321/api/sync-articles
   ```
2. **Backend Direct**: If the frontend endpoint is unavailable, use the provided Python initialization script.
   ```bash
   cd maya-sawa
   poetry run python scripts/init_articles.py
   ```
3. **Verify**: Check article count via the Paprika API.
   ```bash
   curl -s http://localhost:8000/maya-sawa/paprika/articles | jq '.total'
   ```
