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

  // Playback phase
  bool _isReversing = false;
  bool _isSwitching = false;

  // Reverse playback
  Timer? _reverseTimer;
  static const Duration _reverseStep = Duration(milliseconds: 33); // ~30fps

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
      _isReversing = false;
      _initCurrent();
      return;
    }

    // Pause / resume
    if (widget.isPaused != oldWidget.isPaused) {
      if (widget.isPaused) {
        _currentController?.pause();
        _reverseTimer?.cancel();
      } else if (_isInitialized) {
        if (_isReversing) {
          _startReverseTimer();
        } else {
          _currentController?.play();
        }
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
    await ctrl.setLooping(false); // Never native loop — we control all phases
    return ctrl;
  }

  // ── Initial Load ───────────────────────────────────────────────────────────

  Future<void> _initCurrent() async {
    if (widget.videos.isEmpty) return;

    _reverseTimer?.cancel();
    _reverseTimer = null;

    if (mounted) {
      setState(() {
        _isInitialized = false;
        _error = null;
        _isSwitching = false;
        _isReversing = false;
      });
    }

    try {
      final ctrl = await _buildController(_currentVideoIndex);

      if (!mounted || _isDisposed) {
        await ctrl.dispose();
        return;
      }

      _currentController?.removeListener(_onForwardProgress);
      await _currentController?.dispose();

      _currentController = ctrl;
      _currentController!.addListener(_onForwardProgress);

      await _currentController!.seekTo(Duration.zero);
      if (!widget.isPaused) {
        await _currentController!.play();
      }

      if (mounted) {
        setState(() {
          _isInitialized = true;
          _retryCount = 0;
        });
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

  // ── Phase 1: Forward playback listener ────────────────────────────────────

  void _onForwardProgress() {
    final ctrl = _currentController;
    if (ctrl == null || !ctrl.value.isInitialized) return;
    if (_isSwitching || _isReversing) return;

    final pos = ctrl.value.position;
    final dur = ctrl.value.duration;
    if (dur == Duration.zero) return;

    final exactEnd = pos >= dur;
    final nearEnd = pos >= dur - const Duration(milliseconds: 300);
    final stopped = !ctrl.value.isPlaying && !ctrl.value.isBuffering;

    if (exactEnd || (nearEnd && stopped)) {
      _logger.i('Forward end: [${widget.videos[_currentVideoIndex].filename}]. Starting reverse...');
      _startReverse();
    }
  }

  // ── Phase 2: Start reverse playback ───────────────────────────────────────

  void _startReverse() async {
    if (_isReversing || _isSwitching || _isDisposed || !mounted) return;
    _isReversing = true;

    final ctrl = _currentController;
    if (ctrl == null) return;

    // Pause the player — we drive position manually
    await ctrl.pause();
    ctrl.removeListener(_onForwardProgress);

    // Seek to the exact end to begin reversing from there
    final dur = ctrl.value.duration;
    await ctrl.seekTo(dur);

    if (!widget.isPaused) {
      _startReverseTimer();
    }
  }

  void _startReverseTimer() {
    _reverseTimer?.cancel();
    _reverseTimer = Timer.periodic(_reverseStep, _onReverseTick);
  }

  void _onReverseTick(Timer timer) async {
    if (_isDisposed || !mounted) {
      timer.cancel();
      return;
    }

    final ctrl = _currentController;
    if (ctrl == null || !ctrl.value.isInitialized) {
      timer.cancel();
      return;
    }

    final pos = ctrl.value.position;

    if (pos <= Duration.zero) {
      timer.cancel();
      _reverseTimer = null;
      _logger.i('Reverse end: [${widget.videos[_currentVideoIndex].filename}]. Switching to next...');
      _switchToNext();
      return;
    }

    final newPos = pos - _reverseStep;
    await ctrl.seekTo(newPos < Duration.zero ? Duration.zero : newPos);
  }

  // ── Switch to Next ─────────────────────────────────────────────────────────

  void _switchToNext() async {
    if (_isSwitching || _isDisposed || !mounted) return;
    _isSwitching = true;

    _reverseTimer?.cancel();
    _reverseTimer = null;

    final prevCtrl = _currentController;
    prevCtrl?.removeListener(_onForwardProgress);

    final nextIndex = (_currentVideoIndex + 1) % widget.videos.length;
    _logger.i('Switching to index: $nextIndex');

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
        // Restart current video from beginning as fallback
        _isReversing = false;
        _isSwitching = false;
        _currentController?.addListener(_onForwardProgress);
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

    await newCtrl!.seekTo(Duration.zero);
    if (!widget.isPaused) {
      await newCtrl.play();
    }

    _currentController = newCtrl;
    _currentVideoIndex = nextIndex;
    _isReversing = false;
    _currentController!.addListener(_onForwardProgress);

    if (mounted) {
      setState(() {
        _isSwitching = false;
      });
    }

    Future.delayed(const Duration(milliseconds: 200), () {
      prevCtrl?.dispose();
    });

    _preloadNext();
  }

  // ── Cleanup ────────────────────────────────────────────────────────────────

  void _disposeAll() {
    _reverseTimer?.cancel();
    _reverseTimer = null;
    _currentController?.removeListener(_onForwardProgress);
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
            Text(_error!,
                style:
                    const TextStyle(color: Colors.redAccent, fontSize: 12)),
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
