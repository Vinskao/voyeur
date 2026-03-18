import 'dart:io';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:logger/logger.dart';
import '../models/video_result.dart';
import '../services/asset_cache_manager.dart';

class VideoPlayerView extends StatefulWidget {
  final List<VideoResult> videos;
  final bool isPaused;

  const VideoPlayerView({
    super.key,
    required this.videos,
    this.isPaused = false,
  });

  @override
  State<VideoPlayerView> createState() => _VideoPlayerViewState();
}

class _VideoPlayerViewState extends State<VideoPlayerView> {
  final Logger _logger = Logger();
  
  // Controller pool to limit memory usage
  final Map<int, VideoPlayerController> _controllerPool = {};
  static const int _maxControllers = 3;

  int _currentVideoIndex = 0;
  bool _isInitialized = false;
  String? _error;
  bool _isPlayingForward = true;
  bool _isDisposed = false;
  
  // Retry logic
  int _retryCount = 0;
  static const int _maxAutoRetries = 3;

  @override
  void initState() {
    super.initState();
    _isDisposed = false;
    _initializeCurrentAndNext();
  }

  @override
  void didUpdateWidget(VideoPlayerView oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    // Check if playlist changed
    if (widget.videos.isNotEmpty &&
        oldWidget.videos.isNotEmpty &&
        widget.videos.first.url != oldWidget.videos.first.url) {
      _disposeAllControllers();
      _currentVideoIndex = 0;
      _initializeCurrentAndNext();
      return;
    }

    // Check if pause state changed
    if (widget.isPaused != oldWidget.isPaused) {
      _handlePauseStateChange();
    }
  }

  void _handlePauseStateChange() async {
    final controller = _controllerPool[_currentVideoIndex];
    if (controller == null || !controller.value.isInitialized) return;

    if (widget.isPaused) {
      await controller.pause();
    } else {
      if (_isPlayingForward) {
        await controller.play();
      } else {
        // If it was in reverse playback when paused, it might be tricky.
        // For simplicity, if we resume and we were in reverse, 
        // let's just keep the reverse logic going if it was running.
        // Actually, _reversePlayback uses _isPlayingForward in its while loop.
        // If we were reversed and it's still !_isPlayingForward, the loop is already running or will be triggered.
      }
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
      final controller = await _getControllerAtIndex(_currentVideoIndex);

      if (mounted && !_isDisposed && controller != null) {
        setState(() {
          _isInitialized = true;
          _isPlayingForward = true;
        });

        controller.addListener(_boomerangListener);
        
        // Final check for state errors
        if (controller.value.hasError) {
          throw Exception("Initialization error: ${controller.value.errorDescription}");
        }

        if (!widget.isPaused) {
          await controller.play();
        }

        setState(() {
          _retryCount = 0; // Reset on success
        });

        _preloadNext();
      }
    } catch (e) {
      final video = widget.videos[_currentVideoIndex];
      final errorMsg = "Failed to load ${video.filename}: $e";
      _logger.e(errorMsg);
      
      // Proactively clear cache for the failing video
      AssetCacheManager.shared.removeCachedVideo(video.url);

      if (_retryCount < _maxAutoRetries) {
        _logger.w("Auto-retry attempt ${_retryCount + 1} for ${video.filename}");
        _retryCount++;
        // Small delay before retry to let system resources settle
        Future.delayed(const Duration(milliseconds: 1000), () {
          if (mounted && !_isDisposed) {
            _initializeCurrentAndNext();
          }
        });
        return;
      }

      if (mounted) {
        setState(() {
          _error = errorMsg;
        });
      }
    }
  }

  Future<VideoPlayerController?> _getControllerAtIndex(int index) async {
    if (_isDisposed) return null;
    if (_controllerPool.containsKey(index)) return _controllerPool[index];

    // Maintain pool size
    if (_controllerPool.length >= _maxControllers) {
      _evictOldestController(index);
    }

    final video = widget.videos[index];
    final cachedPath = await AssetCacheManager.shared.getCachedVideoPath(video.url);

    VideoPlayerController controller;
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
    await controller.setVolume(0.0);

    if (_isDisposed) {
      await controller.dispose();
      return null;
    }
    
    _controllerPool[index] = controller;
    return controller;
  }

  void _evictOldestController(int currentIndex) {
    // Evict index furthest from currentIndex
    int? furthestIndex;
    int maxDistance = -1;

    _controllerPool.keys.forEach((key) {
      final distance = (key - currentIndex).abs();
      if (distance > maxDistance) {
        maxDistance = distance;
        furthestIndex = key;
      }
    });

    if (furthestIndex != null) {
      final controller = _controllerPool.remove(furthestIndex);
      controller?.removeListener(_boomerangListener);
      controller?.dispose();
      _logger.d("Evicted controller at index $furthestIndex from pool.");
    }
  }

  void _preloadNext() {
    if (widget.videos.length <= 1) return;
    final nextIndex = (_currentVideoIndex + 1) % widget.videos.length;
    _getControllerAtIndex(nextIndex).catchError((e) {
      _logger.w("Preload failed: $e");
      return null;
    });
  }

  void _boomerangListener() {
    final controller = _controllerPool[_currentVideoIndex];
    if (controller == null || !controller.value.isInitialized) return;

    final position = controller.value.position;
    final duration = controller.value.duration;

    if (_isPlayingForward) {
      if (position >= duration - const Duration(milliseconds: 50)) {
        _isPlayingForward = false;
        _playBackward();
      }
    }
  }

  void _playBackward() async {
    final controller = _controllerPool[_currentVideoIndex];
    if (controller == null) return;

    await controller.pause();
    _reversePlayback(controller.value.duration);
  }

  void _reversePlayback(Duration duration) async {
    final controller = _controllerPool[_currentVideoIndex];
    if (controller == null || !mounted || _isDisposed) return;

    const frameInterval = Duration(milliseconds: 40); // Slightly slower for stability
    Duration currentPosition = duration;

    while (currentPosition > Duration.zero && !_isPlayingForward && mounted && !_isDisposed) {
      if (_controllerPool[_currentVideoIndex] != controller) return;

      currentPosition -= const Duration(milliseconds: 100); // Larger steps for "speedy" reverse
      if (currentPosition < Duration.zero) currentPosition = Duration.zero;

      await controller.seekTo(currentPosition);
      await Future.delayed(frameInterval);
    }

    if (!_isPlayingForward && mounted && !_isDisposed) {
      _switchToNextVideo();
    }
  }

  void _switchToNextVideo() async {
    final prevIndex = _currentVideoIndex;
    final nextIndex = (prevIndex + 1) % widget.videos.length;

    final oldController = _controllerPool[prevIndex];
    oldController?.removeListener(_boomerangListener);
    // Keep in pool, but pause
    oldController?.pause();

    setState(() {
      _currentVideoIndex = nextIndex;
      _isPlayingForward = true;
      _retryCount = 0; // Reset for new video
    });

    final newController = await _getControllerAtIndex(nextIndex);
    if (newController != null && mounted && !_isDisposed) {
      newController.addListener(_boomerangListener);
      newController.play();
      _preloadNext();
    }
  }

  void _disposeAllControllers() {
    _controllerPool.forEach((key, controller) {
      controller.removeListener(_boomerangListener);
      controller.dispose();
    });
    _controllerPool.clear();
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
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, color: Colors.redAccent, size: 30),
              const SizedBox(height: 10),
              Text(
                "Video Error:\n$_error",
                style: const TextStyle(color: Colors.redAccent, fontSize: 11),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                onPressed: () {
                  _retryCount = 0; // Reset on manual click
                  _disposeAllControllers();
                  _initializeCurrentAndNext();
                },
                icon: const Icon(Icons.refresh, size: 14),
                label: const Text("Retry", style: TextStyle(fontSize: 11)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white10,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                ),
              ),
            ],
          ),
        ),
      );
    }

    final controller = _controllerPool[_currentVideoIndex];

    if (!_isInitialized || controller == null || !controller.value.isInitialized) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(strokeWidth: 2),
            SizedBox(height: 8),
            Text("Loading...", style: TextStyle(color: Colors.white54, fontSize: 12)),
          ],
        ),
      );
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
