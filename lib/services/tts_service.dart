// lib/services/tts_service.dart
// Service de synthèse vocale (Text-to-Speech)
// Utilise le moteur TTS natif du téléphone (gratuit, hors-ligne)

import 'package:flutter_tts/flutter_tts.dart';

/// Service singleton pour la lecture vocale
class TtsService {
  static TtsService? _instance;
  static TtsService get instance => _instance ??= TtsService._();
  
  TtsService._();
  
  final FlutterTts _tts = FlutterTts();
  bool _isInitialized = false;
  bool _isSpeaking = false;
  String? _currentApproachKey;  // Pour savoir quelle carte est en lecture
  
  // Callback pour notifier les changements d'état
  Function(String? approachKey, bool isSpeaking)? onStateChanged;
  
  // ═══════════════════════════════════════════════════════════════════════════
  // INITIALISATION
  // ═══════════════════════════════════════════════════════════════════════════
  
  Future<void> init() async {
    if (_isInitialized) return;
    
    try {
      // Configuration de la langue française
      await _tts.setLanguage('fr-FR');
      
      // Vitesse de lecture (0.0 à 1.0) - 0.45 = calme et posé
      await _tts.setSpeechRate(0.45);
      
      // Hauteur de voix (0.5 à 2.0) - 1.0 = normale
      await _tts.setPitch(1.0);
      
      // Volume (0.0 à 1.0)
      await _tts.setVolume(1.0);
      
      // Écouter les événements de fin de lecture
      _tts.setCompletionHandler(() {
        _isSpeaking = false;
        final key = _currentApproachKey;
        _currentApproachKey = null;
        onStateChanged?.call(key, false);
      });
      
      // Écouter les erreurs
      _tts.setErrorHandler((msg) {
        print('❌ TTS Error: $msg');
        _isSpeaking = false;
        _currentApproachKey = null;
        onStateChanged?.call(null, false);
      });
      
      _isInitialized = true;
      print('✅ TTS Service initialisé (fr-FR)');
    } catch (e) {
      print('❌ Erreur initialisation TTS: $e');
    }
  }
  
  // ═══════════════════════════════════════════════════════════════════════════
  // LECTURE
  // ═══════════════════════════════════════════════════════════════════════════
  
  /// Lire un texte à voix haute
  /// [approachKey] : identifiant de la source (pour l'UI)
  /// [text] : texte à lire
  Future<void> speak(String text, {String? approachKey}) async {
    if (!_isInitialized) await init();
    
    // Si on clique sur le même bouton, arrêter la lecture
    if (_isSpeaking && _currentApproachKey == approachKey) {
      await stop();
      return;
    }
    
    // Arrêter toute lecture en cours
    if (_isSpeaking) {
      await stop();
    }
    
    _isSpeaking = true;
    _currentApproachKey = approachKey;
    onStateChanged?.call(approachKey, true);
    
    print('🔊 TTS: Lecture de ${text.length} caractères');
    await _tts.speak(text);
  }
  
  /// Arrêter la lecture en cours
  Future<void> stop() async {
    if (_isSpeaking) {
      await _tts.stop();
      _isSpeaking = false;
      final key = _currentApproachKey;
      _currentApproachKey = null;
      onStateChanged?.call(key, false);
      print('⏹️ TTS: Lecture arrêtée');
    }
  }
  
  /// Mettre en pause (si supporté)
  Future<void> pause() async {
    await _tts.pause();
  }
  
  // ═══════════════════════════════════════════════════════════════════════════
  // GETTERS
  // ═══════════════════════════════════════════════════════════════════════════
  
  bool get isSpeaking => _isSpeaking;
  String? get currentApproachKey => _currentApproachKey;
  
  /// Vérifie si une source spécifique est en cours de lecture
  bool isSpeakingApproach(String approachKey) {
    return _isSpeaking && _currentApproachKey == approachKey;
  }
  
  // ═══════════════════════════════════════════════════════════════════════════
  // CONFIGURATION
  // ═══════════════════════════════════════════════════════════════════════════
  
  /// Changer la vitesse de lecture
  Future<void> setSpeechRate(double rate) async {
    await _tts.setSpeechRate(rate.clamp(0.1, 1.0));
  }
  
  /// Obtenir les voix disponibles
  Future<List<dynamic>> getAvailableVoices() async {
    return await _tts.getVoices;
  }
  
  /// Obtenir les langues disponibles
  Future<List<dynamic>> getAvailableLanguages() async {
    return await _tts.getLanguages;
  }
  
  // ═══════════════════════════════════════════════════════════════════════════
  // NETTOYAGE
  // ═══════════════════════════════════════════════════════════════════════════
  
  void dispose() {
    stop();
    _tts.stop();
  }
}
