import 'dart:io';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';

class VideoCacheManager {
  static final VideoCacheManager shared = VideoCacheManager._();
  final Dio _dio = Dio();
  final String _cacheDirectoryName = "DanceVideos";

  VideoCacheManager._();

  Future<String> _getCacheDirectoryPath() async {
    final Directory cacheDir = await getTemporaryDirectory();
    final String path = "${cacheDir.path}/$_cacheDirectoryName";
    final Directory dir = Directory(path);
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return path;
  }

  Future<String?> getCachedFilePath(String filename) async {
    final String cacheDirPath = await _getCacheDirectoryPath();
    final File file = File("$cacheDirPath/$filename");
    if (await file.exists()) {
      return file.path;
    }
    return null;
  }

  Future<bool> isVideoCached(String filename) async {
    return (await getCachedFilePath(filename)) != null;
  }

  Future<void> cacheVideo(String url, String filename) async {
    final String cacheDirPath = await _getCacheDirectoryPath();
    final String savePath = "$cacheDirPath/$filename";

    if (await File(savePath).exists()) return;

    try {
      await _dio.download(url, savePath);
      print("Downloaded and cached: $filename");
    } catch (e) {
      print("Error caching video $filename: $e");
      rethrow;
    }
  }

  Future<void> clearAllCache() async {
    final String path = await _getCacheDirectoryPath();
    final Directory dir = Directory(path);
    if (await dir.exists()) {
      await dir.delete(recursive: true);
      print("Cache cleared successfully.");
    }
  }
}
