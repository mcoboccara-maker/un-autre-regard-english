// lib/models/history_day_entry.dart
// Modèle pour regrouper les données d'un jour dans l'historique "Ton chemin parcouru"

import 'reflection.dart';
import 'saved_eclairage.dart';
import 'mood_entry.dart';

/// Regroupe toutes les données d'un jour : réflexions, éclairages, émotions
class HistoryDayEntry {
  final DateTime date; // Normalisé à minuit
  final List<Reflection> reflections;
  final List<SavedEclairage> eclairages;
  final MoodEntry? moodEntry;

  HistoryDayEntry({
    required this.date,
    this.reflections = const [],
    this.eclairages = const [],
    this.moodEntry,
  });

  /// Label lisible : "Aujourd'hui", "Hier", ou "JJ/MM/AAAA"
  String get dateLabel {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));

    if (date == today) return "Aujourd'hui";
    if (date == yesterday) return 'Hier';
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  /// Résumé court pour le sommaire (première pensée tronquée)
  String get summaryText {
    // Priorité : réflexion > éclairage > émotion
    if (reflections.isNotEmpty) {
      final text = reflections.first.text;
      return text.length > 50 ? '${text.substring(0, 50)}...' : text;
    }
    if (eclairages.isNotEmpty) {
      final text = eclairages.first.thoughtText;
      return text.length > 50 ? '${text.substring(0, 50)}...' : text;
    }
    if (moodEntry != null && moodEntry!.emotions.isNotEmpty) {
      return 'Émotions : ${moodEntry!.emotions.keys.take(3).join(', ')}';
    }
    return '';
  }

  /// Vrai si le jour contient au moins un élément
  bool get hasContent =>
      reflections.isNotEmpty ||
      eclairages.isNotEmpty ||
      (moodEntry != null && moodEntry!.emotions.isNotEmpty);

  /// Nombre total d'éléments dans la journée
  int get itemCount =>
      reflections.length +
      eclairages.length +
      (moodEntry != null ? 1 : 0);

  /// Normalise un DateTime à minuit pour le regroupement par jour
  static DateTime normalizeDate(DateTime dt) =>
      DateTime(dt.year, dt.month, dt.day);

  /// Construit la liste groupée par jour à partir des 3 sources de données
  static List<HistoryDayEntry> buildFromData({
    required List<Reflection> reflections,
    required List<SavedEclairage> eclairages,
    required List<MoodEntry> moodEntries,
  }) {
    final Map<DateTime, HistoryDayEntry> dayMap = {};

    // Helper : obtenir ou créer l'entrée pour un jour
    HistoryDayEntry getOrCreate(DateTime date) {
      final normalized = normalizeDate(date);
      return dayMap.putIfAbsent(
        normalized,
        () => HistoryDayEntry(
          date: normalized,
          reflections: [],
          eclairages: [],
        ),
      );
    }

    // Ajouter les réflexions
    for (final r in reflections) {
      final entry = getOrCreate(r.createdAt);
      // Les listes sont const par défaut dans le constructeur,
      // mais putIfAbsent crée des listes mutables []
      (entry.reflections as List<Reflection>).add(r);
    }

    // Ajouter les éclairages
    for (final e in eclairages) {
      final entry = getOrCreate(e.savedAt);
      (entry.eclairages as List<SavedEclairage>).add(e);
    }

    // Ajouter les mood entries (une par jour max)
    for (final m in moodEntries) {
      final normalized = normalizeDate(m.date);
      final existing = dayMap[normalized];
      if (existing != null) {
        // Remplacer l'entrée avec le moodEntry ajouté
        dayMap[normalized] = HistoryDayEntry(
          date: normalized,
          reflections: existing.reflections,
          eclairages: existing.eclairages,
          moodEntry: m,
        );
      } else {
        dayMap[normalized] = HistoryDayEntry(
          date: normalized,
          moodEntry: m,
        );
      }
    }

    // Trier par date décroissante (plus récent en premier)
    final entries = dayMap.values.where((e) => e.hasContent).toList()
      ..sort((a, b) => b.date.compareTo(a.date));

    return entries;
  }
}
