import 'dart:async';
import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:logger/logger.dart';
import '../models/person.dart';
import '../models/video_result.dart';
import 'app_config.dart';

class VideoProber {
  static final VideoProber shared = VideoProber._();
  final Dio _dio = Dio();
  final Logger _logger = Logger();

  VideoProber._();

  final int maxIndex = 50;
  final int maxConsecutiveMisses = 3;
  static const String _cachePrefix = "video_probe_";
  static const Duration _cacheExpiration = Duration(hours: 24);

  String _constructBaseVideoURL() {
    return AppConfig.peopleImageBaseURL;
  }

  Future<List<VideoResult>> probeCharacter(Person person) async {
    // 1. Check local cache first
    final cached = await _getCachedResults(person.name);
    if (cached != null) {
      _logger.d("Using cached probe results for ${person.name}");
      return cached;
    }

    _logger.i("Probing videos for ${person.name}...");
    final String baseVideoPath = _constructBaseVideoURL();
    List<VideoResult> results = [];

    // 2. Check Main Video
    final mainVideo = await _checkVideoExists(baseVideoPath, person.name, "");
    if (mainVideo != null) {
      results.add(mainVideo);
    }

    // 3. Check Numbered Videos
    int currentIndex = 2;
    int consecutiveMisses = 0;
    const int batchSize = 5;

    while (currentIndex <= maxIndex &&
        consecutiveMisses < maxConsecutiveMisses) {
      int endIndex = (currentIndex + batchSize - 1 < maxIndex)
          ? currentIndex + batchSize - 1
          : maxIndex;

      List<Future<VideoResult?>> batchFutures = [];
      for (int i = currentIndex; i <= endIndex; i++) {
        batchFutures.add(
          _checkVideoExists(baseVideoPath, person.name, i.toString()),
        );
      }

      final batchResults = await Future.wait(batchFutures);

      for (var res in batchResults) {
        if (res != null) {
          results.add(res);
          consecutiveMisses = 0;
        } else {
          consecutiveMisses++;
        }

        if (consecutiveMisses >= maxConsecutiveMisses) break;
      }

      currentIndex += batchSize;
    }

    // 4. Save to cache
    await _cacheResults(person.name, results);

    return results;
  }

  Future<VideoResult?> _checkVideoExists(
    String basePath,
    String name,
    String suffix,
  ) async {
    final String filename = "$name$suffix.mp4";
    final String sep = basePath.endsWith("/") ? "" : "/";
    final String url = "$basePath$sep$filename";

    try {
      final response = await _dio.head(url);
      if (response.statusCode == 200) {
        return VideoResult(personName: name, url: url, filename: filename);
      }
    } catch (e) {
      // Ignore head errors
    }
    return null;
  }

  Future<void> _cacheResults(String name, List<VideoResult> results) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String key = "$_cachePrefix$name";
      final Map<String, dynamic> data = {
        'timestamp': DateTime.now().millisecondsSinceEpoch,
        'results': results.map((r) => r.toJson()).toList(),
      };
      await prefs.setString(key, jsonEncode(data));
    } catch (e) {
      _logger.e("Error caching probe results for $name: $e");
    }
  }

  Future<List<VideoResult>?> _getCachedResults(String name) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String key = "$_cachePrefix$name";
      final String? jsonStr = prefs.getString(key);
      if (jsonStr == null) return null;

      final Map<String, dynamic> data = jsonDecode(jsonStr);
      final int timestamp = data['timestamp'] as int;
      final cachedTime = DateTime.fromMillisecondsSinceEpoch(timestamp);

      if (DateTime.now().difference(cachedTime) > _cacheExpiration) {
        _logger.d("Cache expired for $name");
        return null; // Expired
      }

      final List<dynamic> resultsJson = data['results'] as List<dynamic>;
      return resultsJson.map((j) => VideoResult.fromJson(j)).toList();
    } catch (e) {
      _logger.e("Error reading cached probe results for $name: $e");
      return null;
    }
  }
}
