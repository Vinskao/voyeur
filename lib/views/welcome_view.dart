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

  // Gang video URLs matching palais.astro
  final List<String> _gangVideoUrls = [
    'https://peoplesystem.tatdvsonorth.com/images/people/gangHagisun.mp4',
    'https://peoplesystem.tatdvsonorth.com/images/people/gangHagishi.mp4',
    'https://peoplesystem.tatdvsonorth.com/images/people/gangPhoenix.mp4',
    'https://peoplesystem.tatdvsonorth.com/images/people/gangRegalos.mp4',
    'https://peoplesystem.tatdvsonorth.com/images/people/gangRapeum.mp4',
  ];

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

    // Initialize video controllers
    _videoInitialized = List.filled(_gangVideoUrls.length, false);
    for (int i = 0; i < _gangVideoUrls.length; i++) {
      final controller = VideoPlayerController.networkUrl(
        Uri.parse(_gangVideoUrls[i]),
      );
      _videoControllers.add(controller);

      controller
          .initialize()
          .then((_) {
            if (mounted) {
              setState(() {
                _videoInitialized[i] = true;
              });
              controller.setLooping(true);
              controller.setVolume(0.0); // Muted
              controller.play();
            }
          })
          .catchError((error) {
            // Hide video on error (matching palais.astro behavior)
            if (mounted) {
              setState(() {
                _videoInitialized[i] = false;
              });
            }
          });
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
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Gang Video Container (matching palais.astro)
            Container(
              height: 450,
              margin: const EdgeInsets.only(bottom: 40),
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 40),
                itemCount: _gangVideoUrls.length,
                itemBuilder: (context, index) {
                  if (!_videoInitialized[index]) {
                    return const SizedBox.shrink(); // Hide on error
                  }

                  return Container(
                    margin: EdgeInsets.only(
                      right: index < _gangVideoUrls.length - 1 ? -10 : 0,
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: AspectRatio(
                        aspectRatio: _videoControllers[index].value.aspectRatio,
                        child: VideoPlayer(_videoControllers[index]),
                      ),
                    ),
                  );
                },
              ),
            ),

            // Rapeum Branding
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
                  shadows: [Shadow(color: Colors.blueAccent, blurRadius: 10)],
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
                                  color: Colors.blue.withValues(alpha: 0.5),
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
    );
  }
}
