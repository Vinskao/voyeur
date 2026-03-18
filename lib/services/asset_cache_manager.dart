import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:logger/logger.dart';

class AssetCacheManager {
  static final AssetCacheManager shared = AssetCacheManager._();
  final Logger _logger = Logger();
  
  // Specific CacheManager for videos (different stale period/max objects usually)
  static const String _videoCacheKey = "dance_videos_cache";
  static final CacheManager _videoCache = CacheManager(
    Config(
      _videoCacheKey,
      stalePeriod: const Duration(days: 7),
      maxNrOfCacheObjects: 100,
      repo: JsonCacheInfoRepository(databaseName: _videoCacheKey),
      fileService: HttpFileService(),
    ),
  );

  // Default cache manager (usually for images/cached_network_image)
  static final CacheManager _imageCache = DefaultCacheManager();

  CacheManager get imageCache => _imageCache;

  Future<void> removeCachedVideo(String url) async {
    _logger.i("Removing cached video for $url");
    await _videoCache.removeFile(url);
  }

  AssetCacheManager._();

  // Generic methods
  Future<String?> getCachedVideoPath(String url) async {
    final FileInfo? fileInfo = await _videoCache.getFileFromCache(url);
    if (fileInfo != null && await fileInfo.file.exists()) {
      final length = await fileInfo.file.length();
      if (length > 0) {
        return fileInfo.file.path;
      } else {
        _logger.w("Empty cached file found for $url. Deleting...");
        await _videoCache.removeFile(url);
      }
    }
    return null;
  }

  Future<bool> isVideoCached(String url) async {
    return (await getCachedVideoPath(url)) != null;
  }

  Future<void> cacheVideo(String url) async {
    try {
      await _videoCache.downloadFile(url);
      _logger.i("Video cached: $url");
    } catch (e) {
      _logger.e("Error caching video $url: $e");
      rethrow;
    }
  }

  // Image caching (via DefaultCacheManager)
  Future<void> cacheImage(String url) async {
    try {
      await _imageCache.downloadFile(url);
      _logger.i("Image cached: $url");
    } catch (e) {
      _logger.e("Error caching image $url: $e");
    }
  }

  Future<void> clearAllCache() async {
    await _videoCache.emptyCache();
    await _imageCache.emptyCache();
    _logger.i("All caches cleared successfully.");
  }

  Stream<FileResponse> getVideoFileStream(String url) {
    return _videoCache.getFileStream(url, withProgress: true);
  }
}
