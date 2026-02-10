import 'dart:io';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import '../models/video_result.dart';
import '../services/video_cache_manager.dart';

class VideoPlayerView extends StatefulWidget {
  final VideoResult video;

  const VideoPlayerView({super.key, required this.video});

  @override
  State<VideoPlayerView> createState() => _VideoPlayerViewState();
}

class _VideoPlayerViewState extends State<VideoPlayerView> {
  VideoPlayerController? _controller;
  bool _isInitialized = false;
  String? _error;
  bool _isPlayingForward = true;
  bool _isBoomerangEnabled = true;

  @override
  void initState() {
    super.initState();
    _initializePlayer();
  }

  Future<void> _initializePlayer() async {
    try {
      final cachedPath = await VideoCacheManager.shared.getCachedFilePath(
        widget.video.filename,
      );

      if (cachedPath != null) {
        _controller = VideoPlayerController.file(File(cachedPath));
      } else {
        _controller = VideoPlayerController.networkUrl(
          Uri.parse(widget.video.url),
        );
      }

      await _controller!.initialize();

      // Setup boomerang effect listener
      if (_isBoomerangEnabled) {
        _controller!.addListener(_boomerangListener);
      } else {
        await _controller!.setLooping(true);
      }

      await _controller!.play();

      if (mounted) {
        setState(() {
          _isInitialized = true;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
        });
      }
    }
  }

  void _boomerangListener() {
    if (_controller == null || !_controller!.value.isInitialized) return;

    final position = _controller!.value.position;
    final duration = _controller!.value.duration;

    if (_isPlayingForward) {
      // Check if reached the end
      if (position >= duration - const Duration(milliseconds: 100)) {
        _isPlayingForward = false;
        _playBackward();
      }
    } else {
      // Check if reached the beginning
      if (position <= const Duration(milliseconds: 100)) {
        _isPlayingForward = true;
        _controller!.play();
      }
    }
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
      currentPosition -= frameInterval;
      if (currentPosition < Duration.zero) {
        currentPosition = Duration.zero;
      }

      await _controller!.seekTo(currentPosition);
      await Future.delayed(frameInterval);
    }

    if (!_isPlayingForward && mounted && _controller != null) {
      _isPlayingForward = true;
      if (_controller!.value.isInitialized) {
        _controller!.play();
      }
    }
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
        ),
      );
    }

    if (!_isInitialized) {
      return const Center(child: CircularProgressIndicator());
    }

    return Center(
      child: SizedBox.expand(
        child: FittedBox(
          fit: BoxFit.cover,
          child: SizedBox(
            width: _controller!.value.size.width,
            height: _controller!.value.size.height,
            child: VideoPlayer(_controller!),
          ),
        ),
      ),
    );
  }
}
