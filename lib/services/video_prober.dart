import 'dart:async';
import 'package:dio/dio.dart';
import '../models/person.dart';
import '../models/video_result.dart';
import 'app_config.dart';

class VideoProber {
  static final VideoProber shared = VideoProber._();
  final Dio _dio = Dio();

  VideoProber._();

  final int maxIndex = 50;
  final int maxConsecutiveMisses = 3;

  String _constructBaseVideoURL() {
    String baseURL = AppConfig.resourceBaseURL;
    String cleanBase = baseURL.endsWith("/")
        ? baseURL.substring(0, baseURL.length - 1)
        : baseURL;
    return "$cleanBase/images/people";
  }

  Future<List<VideoResult>> probeCharacter(Person person) async {
    final String baseVideoPath = _constructBaseVideoURL();
    List<VideoResult> results = [];

    // 1. Check Main Video
    final mainVideo = await _checkVideoExists(baseVideoPath, person.name, "");
    if (mainVideo != null) {
      results.add(mainVideo);
    }

    // 2. Check Numbered Videos
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
}
