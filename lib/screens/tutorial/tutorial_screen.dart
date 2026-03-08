// lib/screens/tutorial/tutorial_screen.dart
// ═══════════════════════════════════════════════════════════════════════════════
// ÉCRAN TUTORIEL - MODE D'EMPLOI VIDÉO
// ═══════════════════════════════════════════════════════════════════════════════

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:video_player/video_player.dart';

class TutorialScreen extends StatefulWidget {
  const TutorialScreen({super.key});

  @override
  State<TutorialScreen> createState() => _TutorialScreenState();
}

class _TutorialScreenState extends State<TutorialScreen> {
  late VideoPlayerController _controller;
  bool _isInitialized = false;
  bool _hasError = false;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _initializeVideo();
  }

  Future<void> _initializeVideo() async {
    try {
      _controller = VideoPlayerController.asset('assets/video/tutorial.mp4');

      await _controller.initialize();

      setState(() {
        _isInitialized = true;
      });

      // Démarrer automatiquement la lecture
      _controller.play();

      // Écouter la fin de la vidéo
      _controller.addListener(() {
        if (_controller.value.position >= _controller.value.duration) {
          // Vidéo terminée
          setState(() {});
        }
      });
    } catch (e) {
      setState(() {
        _hasError = true;
        _errorMessage = e.toString();
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'User Guide',
          style: GoogleFonts.inter(
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
      ),
      body: _hasError
          ? _buildErrorView()
          : _isInitialized
              ? _buildVideoPlayer()
              : _buildLoadingView(),
    );
  }

  Widget _buildLoadingView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
          ),
          const SizedBox(height: 20),
          Text(
            'Loading tutorial...',
            style: GoogleFonts.inter(
              color: Colors.white70,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              color: Colors.red,
              size: 64,
            ),
            const SizedBox(height: 20),
            Text(
              'Loading Error',
              style: GoogleFonts.inter(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              _errorMessage,
              style: GoogleFonts.inter(
                color: Colors.white54,
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                setState(() {
                  _hasError = false;
                  _isInitialized = false;
                });
                _initializeVideo();
              },
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6366F1),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVideoPlayer() {
    return Column(
      children: [
        // Vidéo
        Expanded(
          child: Center(
            child: AspectRatio(
              aspectRatio: _controller.value.aspectRatio,
              child: VideoPlayer(_controller),
            ),
          ),
        ),

        // Contrôles
        Container(
          padding: const EdgeInsets.all(16),
          color: Colors.black,
          child: Column(
            children: [
              // Barre de progression
              ValueListenableBuilder(
                valueListenable: _controller,
                builder: (context, VideoPlayerValue value, child) {
                  return Column(
                    children: [
                      SliderTheme(
                        data: SliderTheme.of(context).copyWith(
                          activeTrackColor: const Color(0xFF6366F1),
                          inactiveTrackColor: Colors.white24,
                          thumbColor: const Color(0xFF6366F1),
                          overlayColor: const Color(0xFF6366F1).withOpacity(0.3),
                          trackHeight: 4,
                          thumbShape: const RoundSliderThumbShape(
                            enabledThumbRadius: 8,
                          ),
                        ),
                        child: Slider(
                          value: value.position.inMilliseconds.toDouble(),
                          min: 0,
                          max: value.duration.inMilliseconds.toDouble(),
                          onChanged: (newValue) {
                            _controller.seekTo(
                              Duration(milliseconds: newValue.toInt()),
                            );
                          },
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              _formatDuration(value.position),
                              style: GoogleFonts.inter(
                                color: Colors.white70,
                                fontSize: 12,
                              ),
                            ),
                            Text(
                              _formatDuration(value.duration),
                              style: GoogleFonts.inter(
                                color: Colors.white70,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                },
              ),

              const SizedBox(height: 8),

              // Boutons de contrôle
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Reculer 10s
                  IconButton(
                    onPressed: () {
                      final newPosition = _controller.value.position -
                          const Duration(seconds: 10);
                      _controller.seekTo(
                        newPosition < Duration.zero ? Duration.zero : newPosition,
                      );
                    },
                    icon: const Icon(Icons.replay_10),
                    color: Colors.white,
                    iconSize: 32,
                  ),

                  const SizedBox(width: 24),

                  // Play/Pause
                  ValueListenableBuilder(
                    valueListenable: _controller,
                    builder: (context, VideoPlayerValue value, child) {
                      return Container(
                        decoration: const BoxDecoration(
                          color: Color(0xFF6366F1),
                          shape: BoxShape.circle,
                        ),
                        child: IconButton(
                          onPressed: () {
                            if (value.isPlaying) {
                              _controller.pause();
                            } else {
                              _controller.play();
                            }
                          },
                          icon: Icon(
                            value.isPlaying ? Icons.pause : Icons.play_arrow,
                          ),
                          color: Colors.white,
                          iconSize: 40,
                          padding: const EdgeInsets.all(12),
                        ),
                      );
                    },
                  ),

                  const SizedBox(width: 24),

                  // Avancer 10s
                  IconButton(
                    onPressed: () {
                      final newPosition = _controller.value.position +
                          const Duration(seconds: 10);
                      final maxPosition = _controller.value.duration;
                      _controller.seekTo(
                        newPosition > maxPosition ? maxPosition : newPosition,
                      );
                    },
                    icon: const Icon(Icons.forward_10),
                    color: Colors.white,
                    iconSize: 32,
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}
