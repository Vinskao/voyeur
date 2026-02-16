import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodels/dance_viewmodel.dart';
import '../models/person.dart';
import '../services/people_service.dart';

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
            top: 40,
            left: 16,
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
    this.fit = BoxFit.cover,
    this.showLoading = false,
  });

  @override
  State<RotatingCharacterImage> createState() => _RotatingCharacterImageState();
}

class _RotatingCharacterImageState extends State<RotatingCharacterImage> {
  final List<String> _suffixes = ["", "Ruined", "Fighting"];
  final Set<int> _invalidIndices = {};
  int _currentIndex = 0;
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

    setState(() {
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
    final suffix = _suffixes[_currentIndex];
    final url =
        "https://peoplesystem.tatdvsonorth.com/images/people/${widget.personName}$suffix.png";

    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: Image.network(
        url,
        height: widget.height,
        cacheWidth: widget.cacheWidth,
        fit: widget.fit,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null || !widget.showLoading) return child;
          return const Center(
            child: CircularProgressIndicator(color: Colors.white),
          );
        },
        errorBuilder: (context, error, stackTrace) {
          // If the image fails to load, mark it as invalid and show next one
          if (!_invalidIndices.contains(_currentIndex)) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) {
                setState(() {
                  _invalidIndices.add(_currentIndex);
                  _nextImage();
                });
              }
            });
          }

          if (_invalidIndices.length == _suffixes.length) {
            return const SizedBox.shrink();
          }

          return const SizedBox.shrink(); // Will show next one on next frame
        },
      ),
    );
  }
}
