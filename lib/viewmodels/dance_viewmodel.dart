import 'package:flutter/foundation.dart';
import '../models/person.dart';
import '../models/video_result.dart';
import '../services/people_service.dart';
import '../services/video_prober.dart';
import '../services/video_cache_manager.dart';

enum AppState { welcome, loading, browsing, error }

enum SortFilter {
  none,
  heightAsc,
  heightDesc,
  weightAsc,
  weightDesc,
  physicPowerAsc,
  physicPowerDesc,
  magicPowerAsc,
  magicPowerDesc,
  utilityPowerAsc,
  utilityPowerDesc,
  totalPowerAsc,
  totalPowerDesc,
}

class DanceViewModel extends ChangeNotifier {
  AppState _appState = AppState.welcome;
  List<VideoResult> _videos = [];
  int _currentIndex = 0;
  String _errorMessage = "";
  String _statusMessage = "";
  bool _isLoading = false;
  SortFilter _currentSort = SortFilter.none;

  AppState get appState => _appState;
  List<VideoResult> get videos => _videos;
  int get currentIndex => _currentIndex;
  String get errorMessage => _errorMessage;
  String get statusMessage => _statusMessage;
  bool get isLoading => _isLoading;
  SortFilter get currentSort => _currentSort;

  final PeopleService _peopleService = PeopleService.shared;
  final VideoProber _videoProber = VideoProber.shared;
  final VideoCacheManager _cacheManager = VideoCacheManager.shared;

  void reload() {
    _videos = [];
    _currentIndex = 0;
    _currentSort = SortFilter.none;
    _cacheManager.clearAllCache();
    scanForVideos();
  }

  Future<void> scanForVideos() async {
    _appState = AppState.loading;
    _statusMessage = "Fetching character details...";
    _isLoading = true;
    notifyListeners();

    try {
      // 1. Fetch detailed people data
      final people = await _peopleService.fetchPeople();

      // 2. Fetch batch damage (totalPower)
      _statusMessage = "Calculating total power...";
      notifyListeners();
      final damageResults = await _peopleService.fetchBatchDamage(
        people.map((p) => p.name).toList(),
      );

      // Map damage results back to people
      final enrichedPeople = people.map((p) {
        return p.copyWith(totalPower: damageResults[p.name]);
      }).toList();

      _statusMessage =
          "Found ${enrichedPeople.length} characters. Probing videos...";
      notifyListeners();

      List<VideoResult> foundVideos = [];

      const int chunkSize = 5;
      for (int i = 0; i < enrichedPeople.length; i += chunkSize) {
        int end = (i + chunkSize < enrichedPeople.length)
            ? i + chunkSize
            : enrichedPeople.length;
        final chunk = enrichedPeople.sublist(i, end);

        final chunkResults = await Future.wait(
          chunk.map((person) async {
            final results = await _videoProber.probeCharacter(person);
            // Attach person data to results for sorting later
            return results.map((res) => res.copyWith(person: person)).toList();
          }),
        );

        for (var res in chunkResults) {
          foundVideos.addAll(res);
        }

        _statusMessage = "Scanned $end/${enrichedPeople.length} characters...";
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

  void sortVideos(SortFilter filter) {
    if (_videos.isEmpty) return;

    _currentSort = filter;

    switch (filter) {
      case SortFilter.heightAsc:
        _videos.sort(
          (a, b) =>
              (a.person?.heightCm ?? 0).compareTo(b.person?.heightCm ?? 0),
        );
        break;
      case SortFilter.heightDesc:
        _videos.sort(
          (a, b) =>
              (b.person?.heightCm ?? 0).compareTo(a.person?.heightCm ?? 0),
        );
        break;
      case SortFilter.weightAsc:
        _videos.sort(
          (a, b) =>
              (a.person?.weightKg ?? 0).compareTo(b.person?.weightKg ?? 0),
        );
        break;
      case SortFilter.weightDesc:
        _videos.sort(
          (a, b) =>
              (b.person?.weightKg ?? 0).compareTo(a.person?.weightKg ?? 0),
        );
        break;
      case SortFilter.physicPowerAsc:
        _videos.sort(
          (a, b) => (a.person?.physicPower ?? 0).compareTo(
            b.person?.physicPower ?? 0,
          ),
        );
        break;
      case SortFilter.physicPowerDesc:
        _videos.sort(
          (a, b) => (b.person?.physicPower ?? 0).compareTo(
            a.person?.physicPower ?? 0,
          ),
        );
        break;
      case SortFilter.magicPowerAsc:
        _videos.sort(
          (a, b) =>
              (a.person?.magicPower ?? 0).compareTo(b.person?.magicPower ?? 0),
        );
        break;
      case SortFilter.magicPowerDesc:
        _videos.sort(
          (a, b) =>
              (b.person?.magicPower ?? 0).compareTo(a.person?.magicPower ?? 0),
        );
        break;
      case SortFilter.utilityPowerAsc:
        _videos.sort(
          (a, b) => (a.person?.utilityPower ?? 0).compareTo(
            b.person?.utilityPower ?? 0,
          ),
        );
        break;
      case SortFilter.utilityPowerDesc:
        _videos.sort(
          (a, b) => (b.person?.utilityPower ?? 0).compareTo(
            a.person?.utilityPower ?? 0,
          ),
        );
        break;
      case SortFilter.totalPowerAsc:
        _videos.sort(
          (a, b) =>
              (a.person?.totalPower ?? 0).compareTo(b.person?.totalPower ?? 0),
        );
        break;
      case SortFilter.totalPowerDesc:
        _videos.sort(
          (a, b) =>
              (b.person?.totalPower ?? 0).compareTo(a.person?.totalPower ?? 0),
        );
        break;
      case SortFilter.none:
        // Original order is not preserved unless we stored it, but usually "none" is the initial probed order.
        break;
    }

    // Reset to the first card to show the new sort order clearly
    _currentIndex = 0;

    notifyListeners();
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
