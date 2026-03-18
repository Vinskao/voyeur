import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodels/dance_viewmodel.dart';
import '../models/person.dart';
import '../services/people_service.dart';
import '../services/asset_cache_manager.dart';
import '../services/app_config.dart';
import 'package:cached_network_image/cached_network_image.dart';

class PeopleGalleryView extends StatefulWidget {
  const PeopleGalleryView({super.key});

  @override
  State<PeopleGalleryView> createState() => _PeopleGalleryViewState();
}

class _PeopleGalleryViewState extends State<PeopleGalleryView> {
  List<Person> _people = [];
  bool _isLoading = false;
  String? _errorMessage;
  Person? _selectedPerson;

  @override
  void initState() {
    super.initState();
    _loadPeople();
  }

  Future<void> _loadPeople() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final people = await PeopleService.shared.fetchPeople();

      final damageResults = await PeopleService.shared.fetchBatchDamage(
        people.map((p) => p.name).toList(),
      );

      final enrichedPeople = people.map((p) {
        return p.copyWith(totalPower: damageResults[p.name]);
      }).toList();

      if (mounted) {
        setState(() {
          _people = enrichedPeople;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = "Failed to load people: $e";
          _isLoading = false;
        });
      }
    }
  }

  Map<String, List<Person>> get _groupedPeople {
    final Map<String, List<Person>> grouped = {};
    for (var p in _people) {
      final key = p.originArmyName ?? "Unknown";
      if (!grouped.containsKey(key)) {
        grouped[key] = [];
      }
      grouped[key]!.add(p);
    }

    for (var key in grouped.keys) {
      grouped[key]!.sort(
        (a, b) => (a.totalPower ?? 0).compareTo(b.totalPower ?? 0),
      );
    }

    return grouped;
  }

  @override
  Widget build(BuildContext context) {
    final groups = _groupedPeople;

    final sortedKeys = groups.keys.toList()
      ..sort((a, b) {
        final sumA = groups[a]!.fold(0, (sum, p) => sum + (p.totalPower ?? 0));
        final sumB = groups[b]!.fold(0, (sum, p) => sum + (p.totalPower ?? 0));
        return sumB.compareTo(sumA);
      });

    final viewModel = Provider.of<DanceViewModel>(context, listen: false);

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Main Content
          if (_isLoading)
            const Center(child: CircularProgressIndicator(color: Colors.white))
          else if (_errorMessage != null)
            Center(
              child: Text(
                _errorMessage!,
                style: const TextStyle(color: Colors.red),
              ),
            )
          else
            ListView.builder(
              padding: const EdgeInsets.fromLTRB(0, 80, 0, 50),
              itemCount: sortedKeys.length,
              itemBuilder: (context, index) {
                final armyName = sortedKeys[index];
                final peopleInArmy = groups[armyName] ?? [];

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      child: Text(
                        armyName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    SizedBox(
                      height: 300,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: peopleInArmy.length,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemBuilder: (context, personIndex) {
                          final person = peopleInArmy[personIndex];

                          return Align(
                            widthFactor: 0.8,
                            child: GestureDetector(
                              onTap: () {
                                setState(() {
                                  _selectedPerson = person;
                                });
                              },
                              child: RotatingCharacterImage(
                                key: ValueKey(person.name),
                                personName: person.name,
                                height: 300,
                                cacheWidth: 600,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                );
              },
            ),

          // Fullscreen Overlay
          if (_selectedPerson != null)
            Positioned.fill(
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedPerson = null;
                  });
                },
                child: Container(
                  color: Colors.black.withValues(alpha: 0.9),
                  child: Center(
                    child: RotatingCharacterImage(
                      personName: _selectedPerson!.name,
                      height: MediaQuery.of(context).size.height,
                      cacheWidth: 1080,
                      fit: BoxFit.contain,
                      showLoading: true,
                    ),
                  ),
                ),
              ),
            ),

          // Back Button
          Positioned(
            top: 50,
            left: 20,
            child: CircleAvatar(
              backgroundColor: Colors.black.withValues(alpha: 0.5),
              child: IconButton(
                icon: const Icon(Icons.chevron_left, color: Colors.white),
                onPressed: () {
                  if (_selectedPerson != null) {
                    setState(() {
                      _selectedPerson = null;
                    });
                  } else {
                    viewModel.exitGallery();
                  }
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── RotatingCharacterImage ──────────────────────────────────────────────────
//
// Uses IndexedStack so all 3 image variants are always in the widget tree.
// Switching is just changing the index — no placeholder re-trigger, no flicker.
//
class RotatingCharacterImage extends StatefulWidget {
  final String personName;
  final double height;
  final int cacheWidth;
  final BoxFit fit;
  final bool showLoading;

  const RotatingCharacterImage({
    super.key,
    required this.personName,
    required this.height,
    required this.cacheWidth,
    this.fit = BoxFit.fitHeight,
    this.showLoading = false,
  });

  @override
  State<RotatingCharacterImage> createState() => _RotatingCharacterImageState();
}

class _RotatingCharacterImageState extends State<RotatingCharacterImage> {
  // Suffixes for each image variant
  static const List<String> _suffixes = ['', 'Ruined', 'Fighting'];

  // Which indices have confirmed 404 / error
  final Set<int> _failedIndices = {};

  // Index currently shown in the IndexedStack
  int _visibleIndex = 0;

  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 3), (_) {
      if (mounted) _rotate();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _rotate() {
    final valid = [
      for (int i = 0; i < _suffixes.length; i++)
        if (!_failedIndices.contains(i)) i,
    ];
    if (valid.length <= 1) return; // Nothing to rotate to

    final currentPos = valid.indexOf(_visibleIndex);
    final nextPos =
        currentPos == -1 ? 0 : (currentPos + 1) % valid.length;

    setState(() {
      _visibleIndex = valid[nextPos];
    });
  }

  void _markFailed(int index) {
    if (_failedIndices.contains(index)) return;
    // Must schedule outside build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      setState(() {
        _failedIndices.add(index);
        // If current index just failed, jump to next valid
        if (_visibleIndex == index) _rotate();
      });
    });
  }

  String _url(int index) =>
      '${AppConfig.peopleImageBaseURL}/${widget.personName}${_suffixes[index]}.png';

  @override
  Widget build(BuildContext context) {
    // If ALL images failed, show nothing
    if (_failedIndices.length >= _suffixes.length) {
      return const SizedBox.shrink();
    }

    return SizedBox(
      height: widget.height,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        // IndexedStack keeps all children alive — only renders the one at [index]
        child: IndexedStack(
          index: _visibleIndex,
          children: List.generate(_suffixes.length, (i) {
            // Slot that is known-bad: invisible placeholder to keep layout
            if (_failedIndices.contains(i)) {
              return const SizedBox.shrink();
            }

            return CachedNetworkImage(
              cacheManager: AssetCacheManager.shared.imageCache,
              imageUrl: _url(i),
              height: widget.height,
              memCacheWidth: widget.cacheWidth,
              fit: widget.fit,
              // No fade: images are pre-loaded in-tree; fade = flicker
              fadeInDuration: Duration.zero,
              fadeOutDuration: Duration.zero,
              placeholder: (context, url) => widget.showLoading
                  ? const Center(
                      child: CircularProgressIndicator(color: Colors.white),
                    )
                  : const SizedBox.shrink(),
              errorWidget: (context, url, error) {
                _markFailed(i);
                return const SizedBox.shrink();
              },
            );
          }),
        ),
      ),
    );
  }
}
