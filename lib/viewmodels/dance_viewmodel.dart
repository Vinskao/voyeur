import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';
import '../models/person.dart';
import '../models/video_result.dart';
import '../models/character_videos.dart';
import '../services/people_service.dart';
import '../services/video_prober.dart';
import '../services/asset_cache_manager.dart';
import '../services/app_config.dart';

enum AppState { welcome, loading, browsing, gallery, error }

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
  final Logger _logger = Logger();
  
  AppState _appState = AppState.welcome;
  List<CharacterVideos> _characters = [];
  int _currentIndex = 0;
  String _errorMessage = "";
  String _statusMessage = "";
  bool _isLoading = false;
  SortFilter _currentSort = SortFilter.none;

  AppState get appState => _appState;
  List<CharacterVideos> get characters => _characters;
  int get currentIndex => _currentIndex;
  String get errorMessage => _errorMessage;
  String get statusMessage => _statusMessage;
  bool get isLoading => _isLoading;
  SortFilter get currentSort => _currentSort;

  final PeopleService _peopleService = PeopleService.shared;
  final VideoProber _videoProber = VideoProber.shared;
  final AssetCacheManager _cacheManager = AssetCacheManager.shared;

  List<String> get gangVideoUrls => AppConfig.gangVideoUrls;

  void enterGallery() {
    _appState = AppState.gallery;
    notifyListeners();
  }

  void exitGallery() {
    _appState = AppState.welcome;
    notifyListeners();
  }

  void reload() {
    _logger.i("Reloading data and clearing cache...");
    _characters = [];
    _currentIndex = 0;
    _currentSort = SortFilter.none;
    _cacheManager.clearAllCache();
    scanForVideos();
  }

  /// Clears ALL disk caches (videos, images, probe results) without
  /// changing appState — the UI stays on whatever screen it's on.
  Future<void> clearCacheOnly() async {
    _logger.i("Clearing all caches (no navigation)...");
    _characters = [];
    _currentIndex = 0;
    await _cacheManager.clearAllCache();
    await _videoProber.clearProbeCache();
    _logger.i("All caches cleared.");
  }

  Future<void> scanForVideos() async {
    _setLoading(true, message: "Fetching character details...");
    _appState = AppState.loading;

    try {
      // 1. Fetch and enrich people
      final enrichedPeople = await _getEnrichedPeople();
      
      _setStatus("Found ${enrichedPeople.length} characters. Probing videos...");

      // 2. Discover videos
      final allFoundVideos = await _probeAllCharacters(enrichedPeople);

      // 3. Group and finalize
      _finalizeCharacters(allFoundVideos);
      
    } catch (e, stack) {
      _logger.e("Error during scan: $e", stackTrace: stack);
      _appState = AppState.error;
      _errorMessage = e.toString();
    } finally {
      _setLoading(false);
    }
  }

  Future<List<Person>> _getEnrichedPeople() async {
    final people = await _peopleService.fetchPeople();
    
    _setStatus("Calculating total power...");
    final damageResults = await _peopleService.fetchBatchDamage(
      people.map((p) => p.name).toList(),
    );

    return people.map((p) {
      return p.copyWith(totalPower: damageResults[p.name]);
    }).toList();
  }

  Future<List<VideoResult>> _probeAllCharacters(List<Person> people) async {
    List<VideoResult> allFoundVideos = [];
    const int chunkSize = 5;

    for (int i = 0; i < people.length; i += chunkSize) {
      int end = (i + chunkSize < people.length) ? i + chunkSize : people.length;
      final chunk = people.sublist(i, end);

      final chunkResults = await Future.wait(
        chunk.map((person) async {
          final results = await _videoProber.probeCharacter(person);
          return results.map((res) => res.copyWith(person: person)).toList();
        }),
      );

      for (var res in chunkResults) {
        allFoundVideos.addAll(res);
      }

      _setStatus("Scanned $end/${people.length} characters...");
    }
    return allFoundVideos;
  }

  void _finalizeCharacters(List<VideoResult> allFoundVideos) {
    final Map<String, List<VideoResult>> grouped = {};
    final Map<String, Person> personMap = {};

    for (var video in allFoundVideos) {
      if (!grouped.containsKey(video.personName)) {
        grouped[video.personName] = [];
        if (video.person != null) {
          personMap[video.personName] = video.person!;
        }
      }
      grouped[video.personName]!.add(video);
    }

    _characters = grouped.entries.map((entry) {
      final person = personMap[entry.key] ?? Person(name: entry.key);
      return CharacterVideos(person: person, videos: entry.value);
    }).toList();

    if (_characters.isEmpty) {
      _appState = AppState.error;
      _errorMessage = "No videos found.";
      _logger.w("Discovery finished with 0 characters.");
    } else {
      _appState = AppState.browsing;
      _setStatus("Found ${_characters.length} characters.");
      _autoCacheVideos();
    }
  }

  void _setStatus(String message) {
    _statusMessage = message;
    notifyListeners();
  }

  void _setLoading(bool loading, {String? message}) {
    _isLoading = loading;
    if (message != null) _statusMessage = message;
    notifyListeners();
  }

  void sortVideos(SortFilter filter) {
    if (_characters.isEmpty) return;
    _currentSort = filter;

    _characters.sort((a, b) {
      switch (filter) {
        case SortFilter.heightAsc:
          return (a.person.heightCm ?? 0).compareTo(b.person.heightCm ?? 0);
        case SortFilter.heightDesc:
          return (b.person.heightCm ?? 0).compareTo(a.person.heightCm ?? 0);
        case SortFilter.weightAsc:
          return (a.person.weightKg ?? 0).compareTo(b.person.weightKg ?? 0);
        case SortFilter.weightDesc:
          return (b.person.weightKg ?? 0).compareTo(a.person.weightKg ?? 0);
        case SortFilter.physicPowerAsc:
          return (a.person.physicPower ?? 0).compareTo(b.person.physicPower ?? 0);
        case SortFilter.physicPowerDesc:
          return (b.person.physicPower ?? 0).compareTo(a.person.physicPower ?? 0);
        case SortFilter.magicPowerAsc:
          return (a.person.magicPower ?? 0).compareTo(b.person.magicPower ?? 0);
        case SortFilter.magicPowerDesc:
          return (b.person.magicPower ?? 0).compareTo(a.person.magicPower ?? 0);
        case SortFilter.utilityPowerAsc:
          return (a.person.utilityPower ?? 0).compareTo(b.person.utilityPower ?? 0);
        case SortFilter.utilityPowerDesc:
          return (b.person.utilityPower ?? 0).compareTo(a.person.utilityPower ?? 0);
        case SortFilter.totalPowerAsc:
          return (a.person.totalPower ?? 0).compareTo(b.person.totalPower ?? 0);
        case SortFilter.totalPowerDesc:
          return (b.person.totalPower ?? 0).compareTo(a.person.totalPower ?? 0);
        case SortFilter.none:
          return 0;
      }
    });

    _currentIndex = 0;
    notifyListeners();
  }

  Future<void> _autoCacheVideos() async {
    _logger.d("Starting auto-cache...");
    
    // Gang videos
    for (var url in AppConfig.gangVideoUrls) {
      if (!await _cacheManager.isVideoCached(url)) {
        _cacheManager.cacheVideo(url).catchError((e) {
          _logger.w("Failed to cache gang video $url: $e");
        });
      }
    }

    // Character videos
    for (var char in _characters) {
      for (var video in char.videos) {
        if (!await _cacheManager.isVideoCached(video.url)) {
          _cacheManager.cacheVideo(video.url).catchError((e) {
             _logger.w("Failed to cache video ${video.url}: $e");
          });
        }
      }
    }
    
    _setStatus("All videos ready.");
  }

  void setCurrentIndex(int index) {
    if (index >= 0 && index < _characters.length) {
      _currentIndex = index;
      notifyListeners();
    }
  }

  bool get canNavigateNext => _currentIndex < _characters.length - 1;
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

  Future<String?> getCachedVideoPath(String url) async {
    return await _cacheManager.getCachedVideoPath(url);
  }
}
