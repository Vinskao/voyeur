import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:video_player/video_player.dart';
import '../viewmodels/dance_viewmodel.dart';

class WelcomeView extends StatefulWidget {
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

  // Gang video URLs are now managed by the viewmodel for consistent caching

  List<VideoPlayerController> _videoControllers = [];
  List<bool> _videoInitialized = [];

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
    _rippleOpacity =
        TweenSequence<double>([
          TweenSequenceItem(tween: Tween(begin: 0.0, end: 1.0), weight: 20),
          TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.0), weight: 80),
        ]).animate(
          CurvedAnimation(parent: _rippleController, curve: Curves.easeOut),
        );

    _dropController.forward();

    final viewModel = Provider.of<DanceViewModel>(context, listen: false);
    final urls = viewModel.gangVideoUrls;

    // Initialize video controllers
    _videoInitialized = List.filled(urls.length, false);
    for (int i = 0; i < urls.length; i++) {
      final url = urls[i];
      _initializeController(i, url, viewModel);
    }
  }

  Future<void> _initializeController(
    int index,
    String url,
    DanceViewModel viewModel,
  ) async {
    final cachedPath = await viewModel.getCachedVideoPath(url);
    final controller =
        cachedPath != null
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

    _videoControllers.add(controller);

    try {
      await controller.initialize();
      if (mounted) {
        setState(() {
          _videoInitialized[index] = true;
        });
        await controller.setLooping(true);
        await controller.setVolume(0.0); // Muted
        await controller.play();
      }
    } catch (error) {
      print("Error initializing video $url: $error");
      if (mounted) {
        setState(() {
          _videoInitialized[index] = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _dropController.dispose();
    _rippleController.dispose();
    for (var controller in _videoControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  void _startLoadingSequence(DanceViewModel viewModel) {
    _rippleController.forward(from: 0);

    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        viewModel.scanForVideos();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = Provider.of<DanceViewModel>(context);

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Center(
            child: SingleChildScrollView(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Gang Video Container (matching palais.astro)
                  Container(
                    height: 540,
                    margin: const EdgeInsets.only(bottom: 40),
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 40),
                      itemCount: viewModel.gangVideoUrls.length,
                      itemBuilder: (context, index) {
                        if (index >= _videoInitialized.length ||
                            !_videoInitialized[index]) {
                          return const SizedBox.shrink(); // Loading or Hide on error
                        }

                        return Container(
                          margin: EdgeInsets.only(
                            right:
                                index < viewModel.gangVideoUrls.length - 1
                                    ? -10
                                    : 0,
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: AspectRatio(
                              aspectRatio:
                                  _videoControllers[index].value.aspectRatio,
                              child: VideoPlayer(_videoControllers[index]),
                            ),
                          ),
                        );
                      },
                    ),
                  ),

                  // Rapeum Branding
                  ShaderMask(
                    shaderCallback:
                        (bounds) => const LinearGradient(
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

                  // Interactive Water Drop Area
                  GestureDetector(
                    onTap: () => _startLoadingSequence(viewModel),
                    child: SizedBox(
                      width: 200,
                      height: 200,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          // Ripple Effect
                          AnimatedBuilder(
                            animation: _rippleController,
                            builder: (context, child) {
                              return Opacity(
                                opacity: _rippleOpacity.value,
                                child: Transform.scale(
                                  scale: _rippleScale.value,
                                  child: Container(
                                    width: 100,
                                    height: 100,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: Colors.blue.withValues(
                                          alpha: 0.5,
                                        ),
                                        width: 2,
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),

                          // Water Drop
                          AnimatedBuilder(
                            animation: _dropController,
                            builder: (context, child) {
                              return Opacity(
                                opacity: _dropOpacity.value,
                                child: Transform.translate(
                                  offset: Offset(0, _dropOffset.value),
                                  child: const Icon(
                                    Icons.water_drop,
                                    size: 40,
                                    color: Colors.blue,
                                  ),
                                ),
                              );
                            },
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
                    onPressed: () {
                      viewModel.enterGallery();
                    },
                  ),
                ],
              ),
            ),
          ),
          // Reload Button in Top Right with SafeArea
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
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Clearing storage and reloading...'),
                        ),
                      );
                      viewModel.reload();
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
