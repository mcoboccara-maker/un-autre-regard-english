import 'package:hive/hive.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

/// Service de suivi des personnages utilises dans les reponses IA
/// Stocke les personnages avec leur date d'utilisation pour eviter les repetitions
/// sur une periode de 30 jours glissants

class CharacterTrackingService {
  static CharacterTrackingService? _instance;
  static CharacterTrackingService get instance => _instance ??= CharacterTrackingService._();
  CharacterTrackingService._();

  static const String _boxName = 'used_characters';
  Box<Map>? _box;
  bool _isHiveInitialized = false;

  /// Initialiser le service (appeler au demarrage de l'app)
  Future<void> init() async {
    if (_box == null || !_box!.isOpen) {
      // ═══════════════════════════════════════════════════════════════════════
      // CORRECTION: Initialiser Hive avec le bon chemin sur Android/iOS
      // ═══════════════════════════════════════════════════════════════════════
      if (!_isHiveInitialized && !kIsWeb) {
        try {
          final appDocDir = await getApplicationDocumentsDirectory();
          Hive.init(appDocDir.path);
          _isHiveInitialized = true;
          print('CharacterTracking: Hive initialisé avec chemin: ${appDocDir.path}');
        } catch (e) {
          print('CharacterTracking: Erreur initialisation Hive: $e');
          // Si déjà initialisé ailleurs, continuer
          _isHiveInitialized = true;
        }
      }
      
      try {
        _box = await Hive.openBox<Map>(_boxName);
        // Nettoyer les personnages de plus de 30 jours au demarrage
        await _purgeOldCharacters();
      } catch (e) {
        print('CharacterTracking: Erreur ouverture box: $e');
        rethrow;
      }
    }
  }

  /// Modele d'un personnage utilise
  /// {
  ///   "nom": "Job",
  ///   "source": "judaisme_rabbinique",
  ///   "reference": "Livre de Job, chapitres 1-2",
  ///   "motifUniversel": "perte",
  ///   "dateUtilisation": "2025-12-13T14:30:00Z"
  /// }

  /// Sauvegarder un personnage utilise
  Future<void> saveUsedCharacter({
    required String nom,
    required String source,
    required String reference,
    required String motifUniversel,
  }) async {
    await init();
    
    final character = {
      'nom': nom,
      'source': source,
      'reference': reference,
      'motifUniversel': motifUniversel,
      'dateUtilisation': DateTime.now().toIso8601String(),
    };
    
    // Utiliser nom+source comme cle unique
    final key = '${nom.toLowerCase()}_${source.toLowerCase()}';
    await _box!.put(key, character);
    
    print('CharacterTracking: Personnage sauvegarde - $nom ($source)');
  }

  /// Sauvegarder plusieurs personnages (extrait du controle)
  Future<void> saveMultipleCharacters(List<Map<String, dynamic>> characters) async {
    await init();
    
    for (final char in characters) {
      await saveUsedCharacter(
        nom: char['nom'] ?? '',
        source: char['source'] ?? '',
        reference: char['reference'] ?? '',
        motifUniversel: char['motifUniversel'] ?? '',
      );
    }
  }

  /// Recuperer tous les personnages utilises dans les 30 derniers jours
  Future<List<Map<String, dynamic>>> getUsedCharacters() async {
    await init();
    
    final now = DateTime.now();
    final thirtyDaysAgo = now.subtract(const Duration(days: 30));
    final result = <Map<String, dynamic>>[];
    
    for (final key in _box!.keys) {
      final data = _box!.get(key);
      if (data != null) {
        final dateStr = data['dateUtilisation'] as String?;
        if (dateStr != null) {
          final date = DateTime.tryParse(dateStr);
          if (date != null && date.isAfter(thirtyDaysAgo)) {
            result.add(Map<String, dynamic>.from(data));
          }
        }
      }
    }
    
    // Trier par date decroissante (plus recent en premier)
    result.sort((a, b) {
      final dateA = DateTime.tryParse(a['dateUtilisation'] ?? '') ?? DateTime(1970);
      final dateB = DateTime.tryParse(b['dateUtilisation'] ?? '') ?? DateTime(1970);
      return dateB.compareTo(dateA);
    });
    
    return result;
  }

  /// Recuperer la liste des noms de personnages interdits (format texte pour le prompt)
  Future<String> getForbiddenCharactersText() async {
    try {
      final characters = await getUsedCharacters();
      
      if (characters.isEmpty) {
        return '';
      }
      
      final buffer = StringBuffer();
      for (final char in characters) {
        final nom = char['nom'] ?? 'Inconnu';
        final source = char['source'] ?? '';
        final date = char['dateUtilisation'] ?? '';
        
        // Formater la date pour affichage
        String dateFormatted = '';
        if (date.isNotEmpty) {
          final d = DateTime.tryParse(date);
          if (d != null) {
            dateFormatted = '${d.day}/${d.month}/${d.year}';
          }
        }
        
        buffer.writeln('- $nom ($source) - utilise le $dateFormatted');
      }
      
      return buffer.toString();
    } catch (e) {
      print('CharacterTracking: Erreur getForbiddenCharactersText: $e');
      return ''; // Retourner vide en cas d'erreur pour ne pas bloquer la génération
    }
  }

  /// Verifier si un personnage a deja ete utilise dans les 30 derniers jours
  Future<bool> isCharacterUsedRecently(String nom, String source) async {
    await init();
    
    final key = '${nom.toLowerCase()}_${source.toLowerCase()}';
    final data = _box!.get(key);
    
    if (data == null) return false;
    
    final dateStr = data['dateUtilisation'] as String?;
    if (dateStr == null) return false;
    
    final date = DateTime.tryParse(dateStr);
    if (date == null) return false;
    
    final thirtyDaysAgo = DateTime.now().subtract(const Duration(days: 30));
    return date.isAfter(thirtyDaysAgo);
  }

  /// Supprimer les personnages de plus de 30 jours
  Future<void> _purgeOldCharacters() async {
    if (_box == null) return;
    
    final now = DateTime.now();
    final thirtyDaysAgo = now.subtract(const Duration(days: 30));
    final keysToDelete = <dynamic>[];
    
    for (final key in _box!.keys) {
      final data = _box!.get(key);
      if (data != null) {
        final dateStr = data['dateUtilisation'] as String?;
        if (dateStr != null) {
          final date = DateTime.tryParse(dateStr);
          if (date != null && date.isBefore(thirtyDaysAgo)) {
            keysToDelete.add(key);
          }
        }
      }
    }
    
    for (final key in keysToDelete) {
      await _box!.delete(key);
    }
    
    if (keysToDelete.isNotEmpty) {
      print('CharacterTracking: ${keysToDelete.length} personnages purges (> 30 jours)');
    }
  }

  /// Forcer le nettoyage des personnages anciens
  Future<void> purgeOldCharacters() async {
    await init();
    await _purgeOldCharacters();
  }

  /// Obtenir le nombre de personnages stockes
  Future<int> getCharacterCount() async {
    await init();
    return _box!.length;
  }

  /// Vider completement l'historique (pour debug/reset)
  Future<void> clearAll() async {
    await init();
    await _box!.clear();
    print('CharacterTracking: Historique completement efface');
  }

  /// Fermer la box (appeler a la fermeture de l'app)
  Future<void> close() async {
    if (_box != null && _box!.isOpen) {
      await _box!.close();
    }
  }
}
