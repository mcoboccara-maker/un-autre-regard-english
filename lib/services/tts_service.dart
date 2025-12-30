// lib/services/tts_service.dart
// Service de synthèse vocale (Text-to-Speech)
// Utilise le moteur TTS natif du téléphone (gratuit, hors-ligne)
// 
// VERSION 2.1 : Logs détaillés pour debug + amélioration détection

import 'package:flutter_tts/flutter_tts.dart';
import 'dart:math' show min;

/// Service singleton pour la lecture vocale
/// Détecte automatiquement la langue du texte pour adapter la voix
class TtsService {
  static TtsService? _instance;
  static TtsService get instance => _instance ??= TtsService._();
  
  TtsService._();
  
  final FlutterTts _tts = FlutterTts();
  bool _isInitialized = false;
  bool _isSpeaking = false;
  String? _currentApproachKey;  // Pour savoir quelle carte est en lecture
  String _currentLanguage = 'fr-FR';  // Langue actuelle du TTS
  
  // Callback pour notifier les changements d'état
  Function(String? approachKey, bool isSpeaking)? onStateChanged;
  
  // ═══════════════════════════════════════════════════════════════════════════
  // MAPPING DES LANGUES DÉTECTÉES VERS LES CODES TTS
  // ═══════════════════════════════════════════════════════════════════════════
  
  static const Map<String, String> _languageMap = {
    'fr': 'fr-FR',    // Français
    'en': 'en-US',    // Anglais
    'he': 'he-IL',    // Hébreu
    'ar': 'ar-SA',    // Arabe
    'es': 'es-ES',    // Espagnol
    'de': 'de-DE',    // Allemand
    'it': 'it-IT',    // Italien
    'pt': 'pt-PT',    // Portugais
    'ru': 'ru-RU',    // Russe
    'zh': 'zh-CN',    // Chinois
    'ja': 'ja-JP',    // Japonais
    'ko': 'ko-KR',    // Coréen
    'yi': 'yi-001',   // Yiddish (si disponible, sinon fallback)
  };
  
  // ═══════════════════════════════════════════════════════════════════════════
  // INITIALISATION
  // ═══════════════════════════════════════════════════════════════════════════
  
  Future<void> init() async {
    if (_isInitialized) return;
    
    try {
      // Lister les langues disponibles pour debug
      final availableLangs = await _tts.getLanguages;
      print('🌐 TTS: Langues disponibles sur cet appareil:');
      print('   $availableLangs');
      
      // Configuration par défaut en français
      final setResult = await _tts.setLanguage('fr-FR');
      print('🌐 TTS: setLanguage(fr-FR) result = $setResult');
      _currentLanguage = 'fr-FR';
      
      // Vitesse de lecture (0.0 à 1.0) - 0.45 = calme et posé
      await _tts.setSpeechRate(0.45);
      
      // Hauteur de voix (0.5 à 2.0) - 1.0 = normale
      await _tts.setPitch(1.0);
      
      // Volume (0.0 à 1.0)
      await _tts.setVolume(1.0);
      
      // Écouter les événements de fin de lecture
      _tts.setCompletionHandler(() {
        print('✅ TTS: Lecture terminée');
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
      
      // Écouter le début de lecture
      _tts.setStartHandler(() {
        print('▶️ TTS: Lecture démarrée en $_currentLanguage');
      });
      
      _isInitialized = true;
      print('✅ TTS Service initialisé (détection automatique de langue)');
    } catch (e) {
      print('❌ Erreur initialisation TTS: $e');
    }
  }
  
  // ═══════════════════════════════════════════════════════════════════════════
  // DÉTECTION DE LANGUE
  // ═══════════════════════════════════════════════════════════════════════════
  
  /// Détecte la langue du texte basé sur les caractères et patterns
  /// Retourne le code langue (fr, en, he, ar, etc.)
  String _detectLanguage(String text) {
    if (text.isEmpty) {
      print('🔍 TTS: Texte vide, défaut FR');
      return 'fr';
    }
    
    // Prendre un échantillon du texte (premiers 500 caractères)
    final sample = text.length > 500 ? text.substring(0, 500) : text;
    
    // Compteurs pour chaque type de caractère
    int hebrewCount = 0;
    int arabicCount = 0;
    int cyrillicCount = 0;
    int chineseCount = 0;
    int japaneseCount = 0;
    int koreanCount = 0;
    int latinCount = 0;
    
    for (int i = 0; i < sample.length; i++) {
      final char = sample.codeUnitAt(i);
      
      // Hébreu : U+0590 à U+05FF
      if (char >= 0x0590 && char <= 0x05FF) {
        hebrewCount++;
      }
      // Arabe : U+0600 à U+06FF
      else if (char >= 0x0600 && char <= 0x06FF) {
        arabicCount++;
      }
      // Cyrillique : U+0400 à U+04FF
      else if (char >= 0x0400 && char <= 0x04FF) {
        cyrillicCount++;
      }
      // Chinois : U+4E00 à U+9FFF
      else if (char >= 0x4E00 && char <= 0x9FFF) {
        chineseCount++;
      }
      // Japonais Hiragana : U+3040 à U+309F
      // Japonais Katakana : U+30A0 à U+30FF
      else if ((char >= 0x3040 && char <= 0x309F) || 
               (char >= 0x30A0 && char <= 0x30FF)) {
        japaneseCount++;
      }
      // Coréen Hangul : U+AC00 à U+D7AF
      else if (char >= 0xAC00 && char <= 0xD7AF) {
        koreanCount++;
      }
      // Latin : A-Z, a-z, et caractères accentués
      else if ((char >= 0x0041 && char <= 0x005A) ||  // A-Z
               (char >= 0x0061 && char <= 0x007A) ||  // a-z
               (char >= 0x00C0 && char <= 0x00FF)) {  // Accentués latins
        latinCount++;
      }
    }
    
    print('🔍 TTS: Analyse caractères - HE:$hebrewCount AR:$arabicCount RU:$cyrillicCount ZH:$chineseCount JA:$japaneseCount KO:$koreanCount LAT:$latinCount');
    
    // Déterminer la langue dominante par caractères non-latins
    if (hebrewCount > 10) {
      print('🔍 TTS: Hébreu détecté (${hebrewCount} caractères)');
      return 'he';
    }
    if (arabicCount > 10) {
      print('🔍 TTS: Arabe détecté (${arabicCount} caractères)');
      return 'ar';
    }
    if (cyrillicCount > 10) {
      print('🔍 TTS: Russe détecté (${cyrillicCount} caractères)');
      return 'ru';
    }
    if (chineseCount > 5) {
      print('🔍 TTS: Chinois détecté (${chineseCount} caractères)');
      return 'zh';
    }
    if (japaneseCount > 5) {
      print('🔍 TTS: Japonais détecté (${japaneseCount} caractères)');
      return 'ja';
    }
    if (koreanCount > 5) {
      print('🔍 TTS: Coréen détecté (${koreanCount} caractères)');
      return 'ko';
    }
    
    // Pour les langues latines, analyser les patterns de mots
    if (latinCount > 10) {
      final latinLang = _detectLatinLanguage(sample.toLowerCase());
      print('🔍 TTS: Langue latine détectée = $latinLang');
      return latinLang;
    }
    
    // Défaut : français
    print('🔍 TTS: Aucune langue détectée, défaut FR');
    return 'fr';
  }
  
  /// Détecte la langue parmi les langues utilisant l'alphabet latin
  String _detectLatinLanguage(String text) {
    // Mots et patterns caractéristiques par langue
    
    // Français : articles, prépositions, accents typiques
    final frenchPatterns = [
      // Articles et déterminants
      RegExp(r'\b(le|la|les|un|une|des|du|de la|au|aux)\b'),
      // Prépositions
      RegExp(r'\b(dans|pour|avec|sur|sous|vers|chez|entre)\b'),
      // Pronoms
      RegExp(r'\b(je|tu|il|elle|nous|vous|ils|elles|ce|cette|ces)\b'),
      // Verbes communs
      RegExp(r'\b(est|sont|être|avoir|faire|peut|doit|veut)\b'),
      // Mots typiques
      RegExp(r'\b(mais|donc|car|ni|or|que|qui|quoi|comment|pourquoi)\b'),
      // Caractères accentués français
      RegExp(r'[éèêëàâäùûüôöîïç]'),
    ];
    
    // Anglais
    final englishPatterns = [
      RegExp(r'\b(the|a|an|is|are|was|were|been|being)\b'),
      RegExp(r'\b(have|has|had|do|does|did|will|would|could|should)\b'),
      RegExp(r'\b(this|that|these|those|what|which|who|whom)\b'),
      RegExp(r'\b(and|but|or|nor|for|yet|so|because|although)\b'),
      RegExp(r'\b(with|from|into|through|during|before|after)\b'),
    ];
    
    // Espagnol
    final spanishPatterns = [
      RegExp(r'\b(el|la|los|las|un|una|unos|unas)\b'),
      RegExp(r'\b(es|son|está|están|ser|estar|tener|hacer)\b'),
      RegExp(r'\b(que|qué|como|cómo|donde|dónde|cuando|cuándo)\b'),
      RegExp(r'\b(pero|porque|aunque|sin|con|para|por)\b'),
      RegExp(r'[ñáéíóúü¿¡]'),
    ];
    
    // Allemand
    final germanPatterns = [
      RegExp(r'\b(der|die|das|ein|eine|einer|eines)\b'),
      RegExp(r'\b(ist|sind|war|waren|sein|haben|werden)\b'),
      RegExp(r'\b(und|oder|aber|weil|dass|wenn|als|ob)\b'),
      RegExp(r'\b(mit|für|auf|an|in|von|zu|bei|nach)\b'),
      RegExp(r'[äöüß]'),
    ];
    
    // Italien
    final italianPatterns = [
      RegExp(r'\b(il|lo|la|i|gli|le|un|uno|una)\b'),
      RegExp(r'\b(è|sono|essere|avere|fare|potere|dovere)\b'),
      RegExp(r'\b(che|chi|come|dove|quando|perché|quale)\b'),
      RegExp(r'\b(ma|però|perché|anche|ancora|già|sempre)\b'),
      RegExp(r'\b(con|per|tra|fra|su|in|da|di|a)\b'),
    ];
    
    // Portugais
    final portuguesePatterns = [
      RegExp(r'\b(o|a|os|as|um|uma|uns|umas)\b'),
      RegExp(r'\b(é|são|ser|estar|ter|fazer|poder)\b'),
      RegExp(r'\b(que|quem|como|onde|quando|porque|qual)\b'),
      RegExp(r'\b(mas|porém|porque|também|ainda|já|sempre)\b'),
      RegExp(r'[ãõçáéíóúâêô]'),
    ];
    
    // Compter les matches pour chaque langue
    int frenchScore = _countMatches(text, frenchPatterns);
    int englishScore = _countMatches(text, englishPatterns);
    int spanishScore = _countMatches(text, spanishPatterns);
    int germanScore = _countMatches(text, germanPatterns);
    int italianScore = _countMatches(text, italianPatterns);
    int portugueseScore = _countMatches(text, portuguesePatterns);
    
    print('🔍 TTS: Scores - FR:$frenchScore EN:$englishScore ES:$spanishScore DE:$germanScore IT:$italianScore PT:$portugueseScore');
    
    // Trouver le score maximum
    final scores = {
      'fr': frenchScore,
      'en': englishScore,
      'es': spanishScore,
      'de': germanScore,
      'it': italianScore,
      'pt': portugueseScore,
    };
    
    String detectedLang = 'fr';
    int maxScore = 0;
    
    scores.forEach((lang, score) {
      if (score > maxScore) {
        maxScore = score;
        detectedLang = lang;
      }
    });
    
    // Si aucun score significatif, défaut français
    if (maxScore < 3) {
      print('🔍 TTS: Score trop faible ($maxScore < 3), défaut FR');
      return 'fr';
    }
    
    return detectedLang;
  }
  
  /// Compte le nombre de matches pour une liste de patterns
  int _countMatches(String text, List<RegExp> patterns) {
    int count = 0;
    for (final pattern in patterns) {
      count += pattern.allMatches(text).length;
    }
    return count;
  }
  
  /// Change la langue du TTS si nécessaire
  Future<void> _setLanguageIfNeeded(String langCode) async {
    final ttsLang = _languageMap[langCode] ?? 'fr-FR';
    
    print('🌐 TTS: Demande langue $langCode → $ttsLang (actuelle: $_currentLanguage)');
    
    if (ttsLang != _currentLanguage) {
      try {
        // Vérifier si la langue est disponible
        final result = await _tts.setLanguage(ttsLang);
        print('🌐 TTS: setLanguage($ttsLang) result = $result');
        
        if (result == 1) {
          _currentLanguage = ttsLang;
          print('✅ TTS: Langue changée vers $ttsLang');
        } else {
          // Fallback sur français si langue non disponible
          print('⚠️ TTS: Langue $ttsLang non disponible (result=$result), fallback fr-FR');
          await _tts.setLanguage('fr-FR');
          _currentLanguage = 'fr-FR';
        }
      } catch (e) {
        print('⚠️ TTS: Erreur changement langue: $e');
        // Garder la langue actuelle
      }
    } else {
      print('🌐 TTS: Langue déjà configurée sur $_currentLanguage');
    }
  }
  
  // ═══════════════════════════════════════════════════════════════════════════
  // LECTURE
  // ═══════════════════════════════════════════════════════════════════════════
  
  /// Lire un texte à voix haute
  /// [approachKey] : identifiant de la source (pour l'UI)
  /// [text] : texte à lire
  /// La langue est détectée automatiquement
  Future<void> speak(String text, {String? approachKey}) async {
    if (!_isInitialized) await init();
    
    print('');
    print('════════════════════════════════════════════════════════════════');
    print('🔊 TTS: NOUVELLE DEMANDE DE LECTURE');
    print('════════════════════════════════════════════════════════════════');
    print('📝 Texte (${text.length} chars): "${text.substring(0, min(100, text.length))}..."');
    print('🔑 ApproachKey: $approachKey');
    print('🎯 État actuel: isSpeaking=$_isSpeaking, currentKey=$_currentApproachKey');
    
    // Si on clique sur le même bouton, arrêter la lecture
    if (_isSpeaking && _currentApproachKey == approachKey) {
      print('⏹️ TTS: Même bouton cliqué, arrêt');
      await stop();
      return;
    }
    
    // Arrêter toute lecture en cours
    if (_isSpeaking) {
      print('⏹️ TTS: Arrêt lecture précédente');
      await stop();
    }
    
    // Détecter la langue et configurer le TTS
    final detectedLang = _detectLanguage(text);
    print('🌐 TTS: Langue détectée = $detectedLang');
    
    await _setLanguageIfNeeded(detectedLang);
    
    _isSpeaking = true;
    _currentApproachKey = approachKey;
    onStateChanged?.call(approachKey, true);
    
    print('▶️ TTS: Lancement lecture en $_currentLanguage');
    print('════════════════════════════════════════════════════════════════');
    print('');
    
    await _tts.speak(text);
  }
  
  /// Lire un texte avec une langue forcée (sans détection automatique)
  /// Utile si on connaît déjà la langue
  Future<void> speakWithLanguage(String text, String langCode, {String? approachKey}) async {
    if (!_isInitialized) await init();
    
    print('');
    print('════════════════════════════════════════════════════════════════');
    print('🔊 TTS: LECTURE FORCÉE EN $langCode');
    print('════════════════════════════════════════════════════════════════');
    
    if (_isSpeaking && _currentApproachKey == approachKey) {
      await stop();
      return;
    }
    
    if (_isSpeaking) {
      await stop();
    }
    
    await _setLanguageIfNeeded(langCode);
    
    _isSpeaking = true;
    _currentApproachKey = approachKey;
    onStateChanged?.call(approachKey, true);
    
    print('▶️ TTS: Lecture forcée en $_currentLanguage');
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
  String get currentLanguage => _currentLanguage;
  
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
  
  /// Tester la détection de langue (utile pour debug)
  String testLanguageDetection(String text) {
    print('');
    print('🧪 TEST DÉTECTION LANGUE');
    print('========================');
    final result = _detectLanguage(text);
    print('🏁 Résultat final: $result');
    return result;
  }
  
  // ═══════════════════════════════════════════════════════════════════════════
  // NETTOYAGE
  // ═══════════════════════════════════════════════════════════════════════════
  
  void dispose() {
    stop();
    _tts.stop();
  }
}
