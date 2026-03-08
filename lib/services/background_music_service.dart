// lib/services/background_music_service.dart
// Service centralisé de musique d'ambiance — singleton + NavigatorObserver
// Gère un AudioPlayer unique, fade-in/fade-out, mute global,
// et transitions automatiques entre écrans.

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';

class BackgroundMusicService extends NavigatorObserver {
  static final BackgroundMusicService instance = BackgroundMusicService._();
  BackgroundMusicService._();

  final AudioPlayer _player = AudioPlayer();
  final ValueNotifier<bool> isMutedNotifier = ValueNotifier(false);

  String? _currentTrack;
  bool _isPlaying = false;
  int _fadeId = 0; // Anti-race-condition pour les fades

  // ── Mapping route → piste musicale ──────────────────────────────────────────
  static const Map<String, String> _routeTracks = {
    '/menu': 'sounds/the_journey_before_dawn.mp3',
    '/home-carousel': 'sounds/the_journey_before_dawn.mp3',
    '/emotions': 'sounds/soulmusic-hare-krishna-relaxing-theme-4-114482.mp3',
    '/history': 'sounds/4379051-big-bad-wolf-on-a-stroll-119184.mp3',
  };

  // ── NavigatorObserver ──────────────────────────────────────────────────────

  @override
  void didPush(Route route, Route? previousRoute) {
    super.didPush(route, previousRoute);
    if (route is PageRoute) _handleRouteChange(route);
  }

  @override
  void didPop(Route route, Route? previousRoute) {
    super.didPop(route, previousRoute);
    if (route is PageRoute && previousRoute is PageRoute) {
      _handleRouteChange(previousRoute);
    }
  }

  @override
  void didReplace({Route? newRoute, Route? oldRoute}) {
    super.didReplace(newRoute: newRoute, oldRoute: oldRoute);
    if (newRoute is PageRoute) _handleRouteChange(newRoute);
  }

  void _handleRouteChange(Route route) {
    final routeName = route.settings.name;
    final track = routeName != null ? _routeTracks[routeName] : null;

    if (track != null) {
      play(track);
    } else {
      // Écran sans musique → silence
      // Délai d'un frame pour laisser initState appeler play() si nécessaire
      _schedulePendingStop();
    }
  }

  bool _pendingStop = false;

  void _schedulePendingStop() {
    _pendingStop = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_pendingStop) {
        stop();
        _pendingStop = false;
      }
    });
  }

  // ── API publique ───────────────────────────────────────────────────────────

  /// Joue une piste (avec fade-out de l'ancienne si différente).
  /// No-op si la même piste est déjà en cours.
  Future<void> play(String assetPath) async {
    _pendingStop = false; // Annule tout stop en attente

    if (_currentTrack == assetPath && _isPlaying) return;

    _fadeId++;
    final myFadeId = _fadeId;

    try {
      // Fade-out de la piste en cours
      if (_isPlaying) {
        await _fadeOut(myFadeId);
        if (_fadeId != myFadeId) return; // Annulé par un autre appel
      }

      _currentTrack = assetPath;
      _isPlaying = true;

      // Démarrage immédiat à 15% puis montée rapide à 35%
      final startVolume = isMutedNotifier.value ? 0.0 : 0.15;
      await _player.setVolume(startVolume);
      await _player.setReleaseMode(ReleaseMode.loop);
      await _player.play(AssetSource(assetPath));

      // Montée rapide de 15% → 35% (sauf si muted)
      if (!isMutedNotifier.value) {
        await _fadeIn(myFadeId);
      }
    } catch (e) {
      debugPrint('BackgroundMusicService play error: $e');
    }
  }

  /// Arrête la musique avec fade-out.
  Future<void> stop() async {
    if (!_isPlaying) return;

    _fadeId++;
    final myFadeId = _fadeId;

    try {
      await _fadeOut(myFadeId);
      if (_fadeId != myFadeId) return;
      await _player.stop();
      _currentTrack = null;
      _isPlaying = false;
    } catch (e) {
      debugPrint('BackgroundMusicService stop error: $e');
    }
  }

  /// Bascule mute/unmute (état global persistant entre écrans).
  void toggleMute() {
    isMutedNotifier.value = !isMutedNotifier.value;
    if (isMutedNotifier.value) {
      _player.setVolume(0);
    } else if (_isPlaying) {
      _player.setVolume(0.35);
    }
  }

  // ── Fades ──────────────────────────────────────────────────────────────────

  Future<void> _fadeIn(int fadeId) async {
    // Montée rapide de 15% → 35% en 500ms
    for (int i = 1; i <= 10; i++) {
      if (_fadeId != fadeId) return;
      await Future.delayed(const Duration(milliseconds: 50));
      await _player.setVolume(0.15 + (i / 10 * 0.20));
    }
  }

  Future<void> _fadeOut(int fadeId) async {
    for (int i = 20; i >= 0; i--) {
      if (_fadeId != fadeId) return;
      await Future.delayed(const Duration(milliseconds: 30));
      await _player.setVolume(i / 20 * 0.35);
    }
  }
}
