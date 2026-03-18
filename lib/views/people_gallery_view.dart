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

      // Fetch batch damage (total power) and update people
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

    // Sort each group by totalPower (Ascending: Weak to Strong)
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

    // Sort army groups by the sum of totalPower (Highest to Lowest)
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
                  color: Colors.black.withOpacity(0.9),
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
              backgroundColor: Colors.black.withOpacity(0.5),
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
  final List<String> _suffixes = ["", "Ruined", "Fighting"];
  final Set<int> _invalidIndices = {};
  int _currentIndex = 0;
  String? _previousUrl; // Track previous URL for seamless transitions
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startRotation();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startRotation() {
    _timer = Timer.periodic(const Duration(seconds: 3), (timer) {
      if (!mounted) return;
      _nextImage();
    });
  }

  void _nextImage() {
    final validIndices = [
      for (int i = 0; i < _suffixes.length; i++)
        if (!_invalidIndices.contains(i)) i,
    ];

    if (validIndices.isEmpty) return;

    final currentSuffix = _suffixes[_currentIndex];
    final currentUrl =
        "${AppConfig.peopleImageBaseURL}/${widget.personName}$currentSuffix.png";

    setState(() {
      _previousUrl = currentUrl; // Save current as previous
      final currentPos = validIndices.indexOf(_currentIndex);
      if (currentPos == -1) {
        _currentIndex = validIndices[0];
      } else {
        _currentIndex = validIndices[(currentPos + 1) % validIndices.length];
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_invalidIndices.length == _suffixes.length) {
      return const SizedBox.shrink();
    }

    // Always use the "Base" image (index 0) to define the layout width.
    // If the base image is not current, we overlay the current one on top.
    final baseImageUrl =
        "${AppConfig.peopleImageBaseURL}/${widget.personName}.png";
    final currentUrl =
        "${AppConfig.peopleImageBaseURL}/${widget.personName}${_suffixes[_currentIndex]}.png";

    return _buildFrame(
      Stack(
        children: [
          // Base Anchor: Defines the card's width in the horizontal list.
          // We use fitHeight so width is dynamic based on image ratio.
          Opacity(
            opacity: _currentIndex == 0 ? 1.0 : 0.0,
            child: CachedNetworkImage(
              cacheManager: AssetCacheManager.shared.imageCache,
              imageUrl: baseImageUrl,
              height: widget.height,
              memCacheWidth: widget.cacheWidth,
              fit: BoxFit.fitHeight,
              placeholder: (context, url) => const SizedBox.shrink(),
              errorWidget: (context, url, error) => const SizedBox.shrink(),
            ),
          ),
          // Current Overlay: Matches the base anchor's dimensions.
          if (_currentIndex != 0)
            Positioned.fill(
              child: CachedNetworkImage(
                cacheManager: AssetCacheManager.shared.imageCache,
                imageUrl: currentUrl,
                memCacheWidth: widget.cacheWidth,
                fit: BoxFit.cover, // Cover the base anchor's area
                placeholder:
                    (context, url) =>
                        _previousUrl != null
                            ? CachedNetworkImage(
                              cacheManager: AssetCacheManager.shared.imageCache,
                              imageUrl: _previousUrl!,
                              memCacheWidth: widget.cacheWidth,
                              fit: BoxFit.cover,
                            )
                            : const SizedBox.shrink(),
                errorWidget:
                    (context, url, error) => _handleImageError(_currentIndex),
              ),
            ),
          // Initial Loading / Error Handling for the Base Image itself
          if (_currentIndex == 0)
            _buildCurrentLoader(currentUrl),
        ],
      ),
    );
  }

  Widget _buildCurrentLoader(String url) {
    return CachedNetworkImage(
      cacheManager: AssetCacheManager.shared.imageCache,
      imageUrl: url,
      height: widget.height,
      memCacheWidth: widget.cacheWidth,
      fit: BoxFit.fitHeight,
      placeholder:
          (context, url) =>
              _previousUrl != null
                  ? CachedNetworkImage(
                    cacheManager: AssetCacheManager.shared.imageCache,
                    imageUrl: _previousUrl!,
                    height: widget.height,
                    memCacheWidth: widget.cacheWidth,
                    fit: BoxFit.fitHeight,
                  )
                  : (widget.showLoading
                      ? const Center(
                        child: CircularProgressIndicator(color: Colors.white),
                      )
                      : const SizedBox.shrink()),
      errorWidget: (context, url, error) => _handleImageError(_currentIndex),
      fadeInDuration: const Duration(milliseconds: 500),
      fadeOutDuration: const Duration(milliseconds: 500),
    );
  }

  Widget _handleImageError(int index) {
    if (!_invalidIndices.contains(index)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() {
            _invalidIndices.add(index);
            _nextImage();
          });
        }
      });
    }
    return const SizedBox.shrink();
  }

  Widget _buildFrame(Widget child) {
    return SizedBox(
      height: widget.height,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: child,
      ),
    );
  }
}
