import 'dart:async';
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

  VideoPlayerController? _currentController;
  VideoPlayerController? _nextController;

  int _currentVideoIndex = 0;
  bool _isInitialized = false;
  String? _error;
  bool _isDisposed = false;

  // Boomerang state
  bool _isPlayingForward = true;
  bool _isSwitching = false;
  bool _endDetected = false;

  int _retryCount = 0;
  static const int _maxAutoRetries = 3;

  @override
  void initState() {
    super.initState();
    _isDisposed = false;
    _initCurrent();
  }

  @override
  void didUpdateWidget(VideoPlayerView oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Playlist changed → full reset
    if (widget.videos.isNotEmpty &&
        oldWidget.videos.isNotEmpty &&
        (widget.videos.length != oldWidget.videos.length ||
            widget.videos.first.url != oldWidget.videos.first.url)) {
      _logger.i('Playlist changed. Resetting player...');
      _disposeAll();
      _currentVideoIndex = 0;
      _isSwitching = false;
      _endDetected = false;
      _isPlayingForward = true;
      _initCurrent();
      return;
    }

    // Pause / resume
    if (widget.isPaused != oldWidget.isPaused) {
      if (widget.isPaused) {
        _currentController?.pause();
      } else if (_isInitialized && _isPlayingForward) {
        _currentController?.play();
      }
    }
  }

  // ── Build a VideoPlayerController ──────────────────────────────────────────

  Future<VideoPlayerController> _buildController(int index) async {
    if (index >= widget.videos.length) throw 'Index out of bounds';
    
    final video = widget.videos[index];
    final cachedPath =
        await AssetCacheManager.shared.getCachedVideoPath(video.url);
    final options = VideoPlayerOptions(mixWithOthers: true);

    final ctrl = cachedPath != null
        ? VideoPlayerController.file(File(cachedPath),
            videoPlayerOptions: options)
        : VideoPlayerController.networkUrl(Uri.parse(video.url),
            videoPlayerOptions: options);

    await ctrl.initialize();
    await ctrl.setVolume(0.0);
    await ctrl.setLooping(false); 
    return ctrl;
  }

  // ── Initial Load ───────────────────────────────────────────────────────────

  Future<void> _initCurrent() async {
    if (widget.videos.isEmpty) return;

    if (mounted) {
      setState(() {
        _isInitialized = false;
        _error = null;
        _isSwitching = false;
        _endDetected = false;
        _isPlayingForward = true;
      });
    }

    try {
      final ctrl = await _buildController(_currentVideoIndex);

      if (!mounted || _isDisposed) {
        await ctrl.dispose();
        return;
      }

      _currentController?.removeListener(_onProgress);
      await _currentController?.dispose();

      _currentController = ctrl;
      _currentController!.addListener(_onProgress);

      if (mounted) {
        setState(() {
          _isInitialized = true;
          _retryCount = 0;
        });
      }

      if (!widget.isPaused) {
        await _currentController!.play();
      }

      _preloadNext();
    } catch (e) {
      final video = widget.videos[_currentVideoIndex];
      _logger.e('Failed to load ${video.filename}: $e');
      AssetCacheManager.shared.removeCachedVideo(video.url);

      if (_retryCount < _maxAutoRetries) {
        _retryCount++;
        Future.delayed(const Duration(milliseconds: 1500), () {
          if (mounted && !_isDisposed) _initCurrent();
        });
        return;
      }

      if (mounted) {
        setState(() => _error = 'Failed to load video.');
      }
    }
  }

  void _preloadNext() async {
    if (widget.videos.length <= 1) return;
    if (_nextController != null) return;

    final nextIndex = (_currentVideoIndex + 1) % widget.videos.length;
    try {
      final ctrl = await _buildController(nextIndex);
      if (_isDisposed || !mounted) {
        await ctrl.dispose();
        return;
      }
      _nextController = ctrl;
    } catch (e) {
      _logger.w('Preload failed for index $nextIndex: $e');
    }
  }

  // ── Listener: Forward Progress ─────────────────────────────────────────────

  void _onProgress() {
    final ctrl = _currentController;
    if (ctrl == null || !ctrl.value.isInitialized) return;
    if (_isSwitching || _endDetected || !_isPlayingForward) return;

    final pos = ctrl.value.position;
    final dur = ctrl.value.duration;
    if (dur == Duration.zero) return;

    // Detect end of forward playback
    final exactEnd = pos >= dur;
    final nearEnd = pos >= dur - const Duration(milliseconds: 300);
    final stopped = !ctrl.value.isPlaying && !ctrl.value.isBuffering;

    if (exactEnd || (nearEnd && stopped)) {
      _endDetected = true;
      _logger.i('End of forward: [${widget.videos[_currentVideoIndex].filename}]. Starting reverse...');
      _startReverse();
    }
  }

  // ── Reverse Playback (Boomerang) ───────────────────────────────────────────

  void _startReverse() async {
    final ctrl = _currentController;
    if (ctrl == null || _isDisposed || !mounted) return;

    await ctrl.pause();
    
    if (_isDisposed || !mounted) return;

    setState(() {
      _isPlayingForward = false;
    });

    // Manual reverse loop - seek backwards by frames
    const step = Duration(milliseconds: 100);
    const interval = Duration(milliseconds: 40);
    Duration pos = ctrl.value.duration;

    while (!_isPlayingForward && !_isDisposed && mounted && pos > Duration.zero) {
      // If widget is currently paused, wait before seeking
      if (widget.isPaused) {
        await Future.delayed(const Duration(milliseconds: 200));
        continue;
      }

      pos -= step;
      if (pos < Duration.zero) pos = Duration.zero;
      
      await ctrl.seekTo(pos);
      await Future.delayed(interval);
      
      // Safety check: if controller changed, abort
      if (_currentController != ctrl) return;
    }

    // Finished reverse loop naturally?
    if (!_isPlayingForward && !_isDisposed && mounted && _currentController == ctrl) {
      _logger.i('End of reverse: [${widget.videos[_currentVideoIndex].filename}]. Switching...');
      _switchToNext();
    }
  }

  // ── Switch to Next ─────────────────────────────────────────────────────────

  void _switchToNext() async {
    if (_isSwitching || _isDisposed || !mounted) return;
    _isSwitching = true;

    final prevCtrl = _currentController;
    prevCtrl?.removeListener(_onProgress);
    
    final nextIndex = (_currentVideoIndex + 1) % widget.videos.length;
    _logger.i('Next index: $nextIndex');

    VideoPlayerController? newCtrl;

    if (_nextController != null && _nextController!.value.isInitialized) {
      newCtrl = _nextController;
      _nextController = null;
    } else {
      await _nextController?.dispose();
      _nextController = null;
      try {
        newCtrl = await _buildController(nextIndex);
      } catch (e) {
        _logger.e('Failed next load: $e');
        _currentController?.addListener(_onProgress);
        _endDetected = false;
        _isSwitching = false;
        _isPlayingForward = true;
        await _currentController?.seekTo(Duration.zero);
        if (!widget.isPaused) await _currentController?.play();
        return;
      }
    }

    if (!mounted || _isDisposed) {
      await newCtrl?.dispose();
      await prevCtrl?.dispose();
      return;
    }

    _currentController = newCtrl;
    _currentVideoIndex = nextIndex;
    _endDetected = false;
    _isPlayingForward = true;
    _currentController!.addListener(_onProgress);

    if (mounted) {
      setState(() {
        _isSwitching = false;
      });
    }

    await _currentController!.seekTo(Duration.zero);
    if (!widget.isPaused) {
      await _currentController!.play();
    }

    Future.delayed(const Duration(milliseconds: 200), () {
      prevCtrl?.dispose();
    });

    _preloadNext();
  }

  // ── Cleanup ───────────────────────────────────────────────────────────────

  void _disposeAll() {
    _isPlayingForward = true; // stop loops
    _currentController?.removeListener(_onProgress);
    _currentController?.dispose();
    _currentController = null;
    _nextController?.dispose();
    _nextController = null;
  }

  @override
  void dispose() {
    _isDisposed = true;
    _disposeAll();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, color: Colors.redAccent, size: 30),
            const SizedBox(height: 10),
            Text(_error!, style: const TextStyle(color: Colors.redAccent, fontSize: 12)),
            const SizedBox(height: 12),
            TextButton.icon(
              onPressed: _initCurrent,
              icon: const Icon(Icons.refresh, size: 16),
              label: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    final ctrl = _currentController;
    if (!_isInitialized || ctrl == null || !ctrl.value.isInitialized) {
      return const Center(child: CircularProgressIndicator(strokeWidth: 2));
    }

    return SizedBox.expand(
      child: FittedBox(
        fit: BoxFit.cover,
        child: SizedBox(
          width: ctrl.value.size.width,
          height: ctrl.value.size.height,
          child: VideoPlayer(ctrl),
        ),
      ),
    );
  }
}
