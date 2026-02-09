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
      await _controller!.setLooping(true);
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

  @override
  void dispose() {
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
      child: AspectRatio(
        aspectRatio: _controller!.value.aspectRatio,
        child: VideoPlayer(_controller!),
      ),
    );
  }
}
