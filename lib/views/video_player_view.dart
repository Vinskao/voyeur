import 'dart:io';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import '../models/video_result.dart';
import '../services/video_cache_manager.dart';

class VideoPlayerView extends StatefulWidget {
  final List<VideoResult> videos;

  const VideoPlayerView({super.key, required this.videos});

  @override
  State<VideoPlayerView> createState() => _VideoPlayerViewState();
}

class _VideoPlayerViewState extends State<VideoPlayerView> {
  // Map to hold initialized controllers for seamless playback
  final Map<int, VideoPlayerController> _controllers = {};

  int _currentVideoIndex = 0;
  bool _isInitialized = false;
  String? _error;
  bool _isPlayingForward = true;
  bool _isDisposed = false;

  @override
  void initState() {
    super.initState();
    _isDisposed = false;
    _initializeCurrentAndNext();
  }

  @override
  void didUpdateWidget(VideoPlayerView oldWidget) {
    super.didUpdateWidget(oldWidget);
    // If the playlist changes significantly (e.g. different person), reset.
    if (widget.videos.isNotEmpty &&
        oldWidget.videos.isNotEmpty &&
        widget.videos.first.url != oldWidget.videos.first.url) {
      _disposeAllControllers();
      _currentVideoIndex = 0;
      _initializeCurrentAndNext();
    }
  }

  Future<void> _initializeCurrentAndNext() async {
    if (widget.videos.isEmpty) return;

    if (mounted) {
      setState(() {
        _isInitialized = false;
        _error = null;
      });
    }

    try {
      // 1. Initialize current video
      await _initializeControllerAtIndex(_currentVideoIndex);

      if (mounted && !_isDisposed) {
        setState(() {
          _isInitialized = true;
          _isPlayingForward = true;
        });

        final controller = _controllers[_currentVideoIndex];
        if (controller != null) {
          controller.addListener(_boomerangListener);
          await controller.play();
        }

        // 2. Preload next video in background
        _preloadNextVideo();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
        });
      }
    }
  }

  Future<void> _initializeControllerAtIndex(int index) async {
    if (_isDisposed) return;
    if (_controllers.containsKey(index)) return; // Already initialized

    final video = widget.videos[index];
    final cachedPath = await VideoCacheManager.shared.getCachedFilePath(
      video.filename,
    );

    VideoPlayerController controller;
    // CRITICAL: Mix with other apps (podcasts)
    final options = VideoPlayerOptions(mixWithOthers: true);

    if (cachedPath != null) {
      controller = VideoPlayerController.file(
        File(cachedPath),
        videoPlayerOptions: options,
      );
    } else {
      controller = VideoPlayerController.networkUrl(
        Uri.parse(video.url),
        videoPlayerOptions: options,
      );
    }

    await controller.initialize();
    if (_isDisposed) {
      await controller.dispose();
      return;
    }
    _controllers[index] = controller;
  }

  void _preloadNextVideo() {
    if (widget.videos.length <= 1) return;

    // Preload next 2 videos to be safe? Or just next.
    // If seamless is key, let's preload all for small lists (< 5).
    // Otherwise just next + nextNext.

    final nextIndex = (_currentVideoIndex + 1) % widget.videos.length;
    _initializeControllerAtIndex(nextIndex)
        .then((_) {
          // Also loop if needed
          if (widget.videos.length > 2) {
            final nextNext = (nextIndex + 1) % widget.videos.length;
            _initializeControllerAtIndex(nextNext);
          }
        })
        .catchError((e) {
          print("Preload error: $e");
        });
  }

  void _boomerangListener() {
    final controller = _controllers[_currentVideoIndex];
    if (controller == null || !controller.value.isInitialized) return;

    final position = controller.value.position;
    final duration = controller.value.duration;

    if (_isPlayingForward) {
      // Check if reached the end
      if (position >= duration - const Duration(milliseconds: 100)) {
        _isPlayingForward = false;
        _playBackward();
      }
    }
  }

  void _playBackward() async {
    final controller = _controllers[_currentVideoIndex];
    if (controller == null) return;

    await controller.pause();
    final duration = controller.value.duration;

    // Manually step backward frame by frame
    _reversePlayback(duration);
  }

  void _reversePlayback(Duration duration) async {
    final controller = _controllers[_currentVideoIndex];
    if (controller == null || !mounted || _isDisposed) return;

    const frameInterval = Duration(milliseconds: 33); // ~30fps
    Duration currentPosition = duration;

    while (currentPosition > Duration.zero &&
        !_isPlayingForward &&
        mounted &&
        !_isDisposed) {
      // Check if logic switched while we were waiting
      if (_currentVideoIndex !=
          widget.videos.indexOf(widget.videos[_currentVideoIndex])) {
        // Index might be stale if updatedWidget happened?
        // Actually _currentVideoIndex is local state.
      }

      // Ensure controller is still valid
      if (_controllers[_currentVideoIndex] != controller) return;

      currentPosition -= frameInterval;
      if (currentPosition < Duration.zero) {
        currentPosition = Duration.zero;
      }

      await controller.seekTo(currentPosition);
      await Future.delayed(frameInterval);
    }

    // Finished reversing
    if (!_isPlayingForward && mounted && !_isDisposed) {
      _switchToNextVideo();
    }
  }

  void _switchToNextVideo() async {
    final prevIndex = _currentVideoIndex;
    final nextIndex = (prevIndex + 1) % widget.videos.length;

    // 1. Remove listener from old
    final oldController = _controllers[prevIndex];
    oldController?.removeListener(_boomerangListener);

    // 2. Ideally nextIndex is already in _controllers via preload.
    if (!_controllers.containsKey(nextIndex)) {
      // Panic load (should show loading if not ready)
      await _initializeControllerAtIndex(nextIndex);
    }

    if (!mounted || _isDisposed) return;

    setState(() {
      _currentVideoIndex = nextIndex;
      _isPlayingForward = true;
    });

    // 3. Play new
    final newController = _controllers[nextIndex];
    if (newController != null) {
      // Ensure audio mix is set (it is in init)
      newController.addListener(_boomerangListener);
      newController.play();
    }

    // 4. Trigger preload for subsequent
    final subsequentIndex = (nextIndex + 1) % widget.videos.length;
    _initializeControllerAtIndex(subsequentIndex);
  }

  void _disposeAllControllers() {
    _controllers.forEach((key, controller) {
      controller.removeListener(_boomerangListener);
      controller.dispose();
    });
    _controllers.clear();
  }

  @override
  void dispose() {
    _isDisposed = true;
    _disposeAllControllers();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      return Center(
        child: Text(
          "Error: $_error",
          style: const TextStyle(color: Colors.red),
          textAlign: TextAlign.center,
        ),
      );
    }

    final controller = _controllers[_currentVideoIndex];

    // If not ready, show spinner
    if (!_isInitialized ||
        controller == null ||
        !controller.value.isInitialized) {
      return const Center(child: CircularProgressIndicator());
    }

    return SizedBox.expand(
      child: FittedBox(
        fit: BoxFit.cover,
        child: SizedBox(
          width: controller.value.size.width,
          height: controller.value.size.height,
          child: VideoPlayer(controller),
        ),
      ),
    );
  }
}
