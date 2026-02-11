import 'package:flutter/foundation.dart';
import '../models/person.dart';
import '../models/video_result.dart';
import '../models/character_videos.dart';
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
  final VideoCacheManager _cacheManager = VideoCacheManager.shared;

  void reload() {
    _characters = [];
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

      List<VideoResult> allFoundVideos = [];

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
          allFoundVideos.addAll(res);
        }

        _statusMessage = "Scanned $end/${enrichedPeople.length} characters...";
        notifyListeners();
      }

      // Group videos by person
      final Map<String, List<VideoResult>> grouped = {};
      // Also keep track of the person object for each name
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

      // Convert to CharacterVideos list
      _characters = grouped.entries.map((entry) {
        // Fallback to a basic Person if not found (shouldn't happen with correct logic)
        final person = personMap[entry.key] ?? Person(name: entry.key);
        return CharacterVideos(person: person, videos: entry.value);
      }).toList();

      if (_characters.isEmpty) {
        _appState = AppState.error;
        _errorMessage = "No videos found.";
      } else {
        _appState = AppState.browsing;
        _statusMessage = "Found ${_characters.length} characters.";

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
    if (_characters.isEmpty) return;

    _currentSort = filter;

    switch (filter) {
      case SortFilter.heightAsc:
        _characters.sort(
          (a, b) => (a.person.heightCm ?? 0).compareTo(b.person.heightCm ?? 0),
        );
        break;
      case SortFilter.heightDesc:
        _characters.sort(
          (a, b) => (b.person.heightCm ?? 0).compareTo(a.person.heightCm ?? 0),
        );
        break;
      case SortFilter.weightAsc:
        _characters.sort(
          (a, b) => (a.person.weightKg ?? 0).compareTo(b.person.weightKg ?? 0),
        );
        break;
      case SortFilter.weightDesc:
        _characters.sort(
          (a, b) => (b.person.weightKg ?? 0).compareTo(a.person.weightKg ?? 0),
        );
        break;
      case SortFilter.physicPowerAsc:
        _characters.sort(
          (a, b) =>
              (a.person.physicPower ?? 0).compareTo(b.person.physicPower ?? 0),
        );
        break;
      case SortFilter.physicPowerDesc:
        _characters.sort(
          (a, b) =>
              (b.person.physicPower ?? 0).compareTo(a.person.physicPower ?? 0),
        );
        break;
      case SortFilter.magicPowerAsc:
        _characters.sort(
          (a, b) =>
              (a.person.magicPower ?? 0).compareTo(b.person.magicPower ?? 0),
        );
        break;
      case SortFilter.magicPowerDesc:
        _characters.sort(
          (a, b) =>
              (b.person.magicPower ?? 0).compareTo(a.person.magicPower ?? 0),
        );
        break;
      case SortFilter.utilityPowerAsc:
        _characters.sort(
          (a, b) => (a.person.utilityPower ?? 0).compareTo(
            b.person.utilityPower ?? 0,
          ),
        );
        break;
      case SortFilter.utilityPowerDesc:
        _characters.sort(
          (a, b) => (b.person.utilityPower ?? 0).compareTo(
            a.person.utilityPower ?? 0,
          ),
        );
        break;
      case SortFilter.totalPowerAsc:
        _characters.sort(
          (a, b) =>
              (a.person.totalPower ?? 0).compareTo(b.person.totalPower ?? 0),
        );
        break;
      case SortFilter.totalPowerDesc:
        _characters.sort(
          (a, b) =>
              (b.person.totalPower ?? 0).compareTo(a.person.totalPower ?? 0),
        );
        break;
      case SortFilter.none:
        break;
    }

    // Reset to the first card to show the new sort order clearly
    _currentIndex = 0;

    notifyListeners();
  }

  Future<void> _autoCacheVideos() async {
    for (var char in _characters) {
      for (var video in char.videos) {
        if (!await _cacheManager.isVideoCached(video.filename)) {
          try {
            await _cacheManager.cacheVideo(video.url, video.filename);
          } catch (e) {
            print("Auto-cache failed for ${video.filename}: $e");
          }
        }
      }
    }
    _statusMessage = "All videos ready.";
    notifyListeners();
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
}
