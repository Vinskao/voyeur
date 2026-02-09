import 'package:flutter/foundation.dart';
import '../models/person.dart';
import '../models/video_result.dart';
import '../services/people_service.dart';
import '../services/video_prober.dart';
import '../services/video_cache_manager.dart';

enum AppState { welcome, loading, browsing, error }

class DanceViewModel extends ChangeNotifier {
  AppState _appState = AppState.welcome;
  List<VideoResult> _videos = [];
  int _currentIndex = 0;
  String _errorMessage = "";
  String _statusMessage = "";
  bool _isLoading = false;

  AppState get appState => _appState;
  List<VideoResult> get videos => _videos;
  int get currentIndex => _currentIndex;
  String get errorMessage => _errorMessage;
  String get statusMessage => _statusMessage;
  bool get isLoading => _isLoading;

  final PeopleService _peopleService = PeopleService.shared;
  final VideoProber _videoProber = VideoProber.shared;
  final VideoCacheManager _cacheManager = VideoCacheManager.shared;

  void reload() {
    _videos = [];
    _currentIndex = 0;
    _cacheManager.clearAllCache();
    scanForVideos();
  }

  Future<void> scanForVideos() async {
    _appState = AppState.loading;
    _statusMessage = "Fetching character list...";
    _isLoading = true;
    notifyListeners();

    try {
      final people = await _peopleService.fetchPeople();
      _statusMessage = "Found ${people.count} characters. Probing videos...";
      notifyListeners();

      List<VideoResult> foundVideos = [];

      // Probing in chunks to match Swift logic if needed,
      // but Dart's Future.wait with limited concurrency is also fine.
      // For simplicity, we'll do them in batches.
      const int chunkSize = 5;
      for (int i = 0; i < people.length; i += chunkSize) {
        int end = (i + chunkSize < people.length)
            ? i + chunkSize
            : people.length;
        final chunk = people.sublist(i, end);

        final chunkResults = await Future.wait(
          chunk.map((person) => _videoProber.probeCharacter(person)),
        );

        for (var res in chunkResults) {
          foundVideos.addAll(res);
        }

        _statusMessage = "Scanned $end/${people.length} characters...";
        notifyListeners();
      }

      _videos = foundVideos;

      if (_videos.isEmpty) {
        _appState = AppState.error;
        _errorMessage = "No videos found.";
      } else {
        _appState = AppState.browsing;
        _statusMessage = "Found ${_videos.length} videos.";

        // Background caching
        _autoCacheVideos();
      }
    } catch (e) {
      _appState = AppState.error;
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _autoCacheVideos() async {
    for (var video in _videos) {
      if (!await _cacheManager.isVideoCached(video.filename)) {
        try {
          await _cacheManager.cacheVideo(video.url, video.filename);
        } catch (e) {
          print("Auto-cache failed for ${video.filename}: $e");
        }
      }
    }
    _statusMessage = "All videos ready.";
    notifyListeners();
  }

  void setCurrentIndex(int index) {
    if (index >= 0 && index < _videos.length) {
      _currentIndex = index;
      notifyListeners();
    }
  }

  bool get canNavigateNext => _currentIndex < _videos.length - 1;
  bool get canNavigatePrevious => _currentIndex > 0;

  void navigateToNext() {
    if (canNavigateNext) {
      _currentIndex++;
      notifyListeners();
    }
  }

  void navigateToPrevious() {
    if (canNavigatePrevious) {
      _currentIndex--;
      notifyListeners();
    }
  }
}

extension on List {
  int get count => length;
}
