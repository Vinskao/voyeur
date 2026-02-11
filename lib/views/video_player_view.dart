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
  VideoPlayerController? _controller;
  int _currentVideoIndex = 0;
  bool _isInitialized = false;
  String? _error;
  bool _isPlayingForward = true;

  // Track if we are currently switching videos to prevent race conditions
  bool _isSwitching = false;

  @override
  void initState() {
    super.initState();
    _initializePlayer();
  }

  @override
  void didUpdateWidget(VideoPlayerView oldWidget) {
    super.didUpdateWidget(oldWidget);
    // If the playlist changes significantly (e.g. different person), reset.
    // Simple check: if the first video is different.
    if (widget.videos.isNotEmpty &&
        oldWidget.videos.isNotEmpty &&
        widget.videos.first.url != oldWidget.videos.first.url) {
      _currentVideoIndex = 0;
      _initializePlayer();
    }
  }

  Future<void> _initializePlayer() async {
    if (widget.videos.isEmpty) return;

    _isSwitching = true;
    setState(() {
      _isInitialized = false;
      _error = null;
    });

    // Dispose previous controller safely
    final oldController = _controller;
    if (oldController != null) {
      _controller = null; // Detach immediately
      oldController.removeListener(_boomerangListener);
      await oldController.dispose();
    }

    try {
      final currentVideo = widget.videos[_currentVideoIndex];
      final cachedPath = await VideoCacheManager.shared.getCachedFilePath(
        currentVideo.filename,
      );

      VideoPlayerController newController;
      if (cachedPath != null) {
        newController = VideoPlayerController.file(File(cachedPath));
      } else {
        newController = VideoPlayerController.networkUrl(
          Uri.parse(currentVideo.url),
        );
      }

      await newController.initialize();
      newController.addListener(_boomerangListener);
      await newController.play();

      if (mounted) {
        setState(() {
          _controller = newController;
          _isInitialized = true;
          _isPlayingForward = true;
          _isSwitching = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isSwitching = false;
        });
      }
    }
  }

  void _boomerangListener() {
    if (_isSwitching ||
        _controller == null ||
        !_controller!.value.isInitialized) {
      return;
    }

    final position = _controller!.value.position;
    final duration = _controller!.value.duration;

    if (_isPlayingForward) {
      // Check if reached the end
      if (position >= duration - const Duration(milliseconds: 100)) {
        _isPlayingForward = false;
        _playBackward();
      }
    }
    // Backward direction is handled by _reversePlayback loop, not this listener
  }

  void _playBackward() async {
    if (_controller == null) return;

    await _controller!.pause();
    final duration = _controller!.value.duration;

    // Manually step backward frame by frame
    _reversePlayback(duration);
  }

  void _reversePlayback(Duration duration) async {
    if (_controller == null || !mounted) return;

    const frameInterval = Duration(milliseconds: 33); // ~30fps
    Duration currentPosition = duration;

    while (currentPosition > Duration.zero && !_isPlayingForward && mounted) {
      // Double check controller availability
      if (_controller == null) return;

      currentPosition -= frameInterval;
      if (currentPosition < Duration.zero) {
        currentPosition = Duration.zero;
      }

      await _controller!.seekTo(currentPosition);
      await Future.delayed(frameInterval);
    }

    // Finished reversing
    if (!_isPlayingForward && mounted) {
      _playNextVideo();
    }
  }

  void _playNextVideo() {
    setState(() {
      _currentVideoIndex = (_currentVideoIndex + 1) % widget.videos.length;
    });
    _initializePlayer();
  }

  @override
  void dispose() {
    _controller?.removeListener(_boomerangListener);
    _controller?.dispose();
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

    if (!_isInitialized || _controller == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return SizedBox.expand(
      child: FittedBox(
        fit: BoxFit.cover,
        child: SizedBox(
          width: _controller!.value.size.width,
          height: _controller!.value.size.height,
          child: VideoPlayer(_controller!),
        ),
      ),
    );
  }
}
