import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:video_player/video_player.dart';
import '../viewmodels/dance_viewmodel.dart';

class WelcomeView extends StatefulWidget {
  const WelcomeView({super.key});
  @override
  State<WelcomeView> createState() => _WelcomeViewState();
}

class _WelcomeViewState extends State<WelcomeView>
    with TickerProviderStateMixin {
  late AnimationController _dropController;
  late Animation<double> _dropOffset;
  late Animation<double> _dropOpacity;

  late AnimationController _rippleController;
  late Animation<double> _rippleScale;
  late Animation<double> _rippleOpacity;

  // Map ensures index→controller is always correct regardless of async order
  final Map<int, VideoPlayerController> _videoControllers = {};
  // Track which indices are fully initialized and ready to show
  final Map<int, bool> _videoReady = {};

  @override
  void initState() {
    super.initState();

    _dropController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _dropOffset = Tween<double>(begin: -150, end: 0).animate(
      CurvedAnimation(parent: _dropController, curve: Curves.easeInOut),
    );
    _dropOpacity = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _dropController, curve: Curves.easeInOut),
    );

    _rippleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _rippleScale = Tween<double>(begin: 0.5, end: 2.0).animate(
      CurvedAnimation(parent: _rippleController, curve: Curves.easeOut),
    );
    _rippleOpacity = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 1.0), weight: 20),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.0), weight: 80),
    ]).animate(
      CurvedAnimation(parent: _rippleController, curve: Curves.easeOut),
    );

    _dropController.forward();

    final viewModel = Provider.of<DanceViewModel>(context, listen: false);
    final urls = viewModel.gangVideoUrls;
    for (int i = 0; i < urls.length; i++) {
      _videoReady[i] = false;
      _initVideo(i, urls[i], viewModel);
    }
  }

  Future<void> _initVideo(
    int index,
    String url,
    DanceViewModel viewModel,
  ) async {
    try {
      final cachedPath = await viewModel.getCachedVideoPath(url);
      final controller = cachedPath != null
          ? VideoPlayerController.file(
              File(cachedPath),
              videoPlayerOptions: VideoPlayerOptions(mixWithOthers: true),
            )
          : VideoPlayerController.networkUrl(
              Uri.parse(url),
              videoPlayerOptions: VideoPlayerOptions(mixWithOthers: true),
            );

      if (!mounted) {
        await controller.dispose();
        return;
      }

      // Store BEFORE initialize so the map slot is reserved
      _videoControllers[index] = controller;

      await controller.initialize();

      if (!mounted) return;

      setState(() {
        _videoReady[index] = true;
      });

      await controller.setLooping(true);
      await controller.setVolume(0.0);
      await controller.play();
    } catch (e) {
      debugPrint('Error initializing gang video $url: $e');
      if (mounted) {
        setState(() {
          _videoReady[index] = false;
        });
      }
    }
  }

  /// Dispose all controllers and re-initialize (clears disk cache first).
  /// appState is NOT changed — user stays on the welcome page.
  Future<void> _reloadAll(DanceViewModel viewModel) async {
    // Dispose current controllers
    for (final c in _videoControllers.values) {
      await c.dispose();
    }
    _videoControllers.clear();
    _videoReady.clear();

    // Clear ALL disk caches (videos + images + probe results)
    // Does NOT call scanForVideos() — appState stays AppState.welcome
    await viewModel.clearCacheOnly();

    // Re-init gang videos (fresh download because cache was cleared)
    final urls = viewModel.gangVideoUrls;
    for (int i = 0; i < urls.length; i++) {
      _videoReady[i] = false;
    }
    if (mounted) setState(() {});

    for (int i = 0; i < urls.length; i++) {
      _initVideo(i, urls[i], viewModel);
    }
  }

  @override
  void dispose() {
    _dropController.dispose();
    _rippleController.dispose();
    for (final c in _videoControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  void _startLoadingSequence(DanceViewModel viewModel) {
    _rippleController.forward(from: 0);
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) viewModel.scanForVideos();
    });
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = Provider.of<DanceViewModel>(context);
    final totalVideos = viewModel.gangVideoUrls.length;
    final readyCount = _videoReady.values.where((v) => v).length;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Center(
            child: SingleChildScrollView(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // ── Gang Video Row ─────────────────────────────────────
                  Container(
                    height: 540,
                    margin: const EdgeInsets.only(bottom: 40),
                    child: readyCount == 0
                        // Nothing loaded yet: show centred progress indicator
                        ? const Center(
                            child: CircularProgressIndicator(
                              color: Colors.white38,
                              strokeWidth: 2,
                            ),
                          )
                        : ListView.builder(
                            scrollDirection: Axis.horizontal,
                            padding:
                                const EdgeInsets.symmetric(horizontal: 40),
                            itemCount: totalVideos,
                            itemBuilder: (context, index) {
                              final ready = _videoReady[index] ?? false;
                              final controller =
                                  _videoControllers[index];

                              // Still loading this slot: empty gap
                              if (!ready || controller == null) {
                                return const SizedBox.shrink();
                              }

                              return Container(
                                margin: EdgeInsets.only(
                                  right: index < totalVideos - 1 ? -10 : 0,
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: AspectRatio(
                                    aspectRatio:
                                        controller.value.aspectRatio,
                                    child: VideoPlayer(controller),
                                  ),
                                ),
                              );
                            },
                          ),
                  ),

                  // ── Rapeum Branding ────────────────────────────────────
                  ShaderMask(
                    shaderCallback: (bounds) => const LinearGradient(
                      colors: [Colors.blue, Colors.cyan],
                    ).createShader(bounds),
                    child: const Text(
                      'Rapeum',
                      style: TextStyle(
                        fontSize: 48,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Serif',
                        color: Colors.white,
                        letterSpacing: 2.0,
                        shadows: [
                          Shadow(color: Colors.blueAccent, blurRadius: 10),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),

                  // ── Water Drop Enter Button ────────────────────────────
                  GestureDetector(
                    onTap: () => _startLoadingSequence(viewModel),
                    child: SizedBox(
                      width: 200,
                      height: 200,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          AnimatedBuilder(
                            animation: _rippleController,
                            builder: (context, child) => Opacity(
                              opacity: _rippleOpacity.value,
                              child: Transform.scale(
                                scale: _rippleScale.value,
                                child: Container(
                                  width: 100,
                                  height: 100,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: Colors.blue.withValues(alpha: 0.5),
                                      width: 2,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          AnimatedBuilder(
                            animation: _dropController,
                            builder: (context, child) => Opacity(
                              opacity: _dropOpacity.value,
                              child: Transform.translate(
                                offset: Offset(0, _dropOffset.value),
                                child: const Icon(
                                  Icons.water_drop,
                                  size: 40,
                                  color: Colors.blue,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),
                  const Text(
                    'Tap to Enter',
                    style: TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                  const SizedBox(height: 30),
                  IconButton(
                    icon: const Icon(
                      Icons.local_fire_department,
                      size: 40,
                      color: Colors.orange,
                    ),
                    onPressed: () => viewModel.enterGallery(),
                  ),
                ],
              ),
            ),
          ),

          // ── Reload Button (top-right) ─────────────────────────────────
          // Clears ALL disk cache (videos + images) and re-downloads everything
          SafeArea(
            child: Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: const EdgeInsets.only(top: 10, right: 10),
                child: Container(
                  decoration: const BoxDecoration(
                    color: Colors.black26,
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: const Icon(
                      Icons.refresh,
                      color: Colors.white70,
                      size: 30,
                    ),
                    onPressed: () async {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Clearing all cache and re-downloading...',
                          ),
                          duration: Duration(seconds: 3),
                        ),
                      );
                      await _reloadAll(viewModel);
                    },
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
