// lib/screens/history/history_screen.dart
// "Your journey so far" — Carousel vertical de cartes datées

import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:share_plus/share_plus.dart';
import '../../services/background_music_service.dart';
import '../../services/complete_auth_service.dart';
import '../../services/persistent_storage_service.dart';
import '../../services/emotional_tracking_service.dart';
import '../../services/ai_service.dart';
import '../../models/reflection.dart';
import '../../models/saved_eclairage.dart';
import '../../models/emotional_state.dart';
import '../../models/mood_entry.dart';
import '../../models/history_day_entry.dart';
import '../../config/emotion_config.dart';
import '../../config/approach_config.dart';
import '../../widgets/carousel_3d/card_carousel_3d.dart';
import '../../widgets/interactive_plutchik_wheel.dart';
import '../../widgets/nav_cartouche.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  List<HistoryDayEntry> _dayEntries = [];
  bool _isLoading = true;
  final Carousel3DController _carouselController = Carousel3DController();

  // Couleurs CDC
  static const Color _fondBleuNuit = Color(0xFF0D1B3E);
  static const Color _fondCarte = Color(0xFF132A44);
  static const Color _dateJauneOr = Color(0xFFFFD54F);
  static const Color _texteClair = Color(0xFFE2E8F0);
  static const Color _texteSecondaire = Color(0xFF94A3B8);

  @override
  void initState() {
    super.initState();
    // Musique gérée par BackgroundMusicService (NavigatorObserver)
    BackgroundMusicService.instance.play('sounds/4379051-big-bad-wolf-on-a-stroll-119184.mp3');
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    try {
      // 1. Charger les réflexions
      final reflections = <Reflection>[];
      try {
        final reflectionsData =
            await CompleteAuthService.instance.getAllReflections();
        for (final data in reflectionsData) {
          try {
            final emotionalState = data['emotionalState'] != null
                ? EmotionalState.fromJson(data['emotionalState'])
                : EmotionalState.empty();
            ReflectionType reflectionType = ReflectionType.thought;
            final typeStr = data['type']?.toString();
            if (typeStr != null) {
              if (typeStr.contains('situation')) {
                reflectionType = ReflectionType.situation;
              } else if (typeStr.contains('existential')) {
                reflectionType = ReflectionType.existential;
              } else if (typeStr.contains('dilemma')) {
                reflectionType = ReflectionType.dilemma;
              }
            }
            reflections.add(Reflection(
              id: data['id']?.toString() ??
                  DateTime.now().millisecondsSinceEpoch.toString(),
              text: data['text']?.toString() ?? 'No content',
              type: reflectionType,
              emotionalState: emotionalState,
              selectedApproaches:
                  List<String>.from(data['selectedApproaches'] ?? []),
              createdAt:
                  DateTime.tryParse(data['createdAt']?.toString() ?? '') ??
                      DateTime.now(),
              aiResponses:
                  Map<String, String>.from(data['aiResponses'] ?? {}),
              isFavorite: false,
              declencheur: data['declencheur']?.toString(),
              souhait: data['souhait']?.toString(),
              petitPas: data['petitPas']?.toString(),
              intensiteEmotionnelle:
                  data['intensiteEmotionnelle']?.toInt() ?? 5,
              emotionPrincipale: data['emotionPrincipale']?.toString(),
            ));
          } catch (e) {
            debugPrint('⚠️ Erreur conversion reflexion: $e');
          }
        }
      } catch (e) {
        debugPrint('⚠️ Erreur chargement reflexions: $e');
      }

      // 2. Charger les éclairages sauvegardés
      final eclairages = <SavedEclairage>[];
      try {
        final eclairagesData =
            PersistentStorageService.instance.getAllSavedEclairages();
        for (final data in eclairagesData) {
          try {
            eclairages.add(SavedEclairage.fromJson(data));
          } catch (e) {
            debugPrint('⚠️ Erreur conversion eclairage: $e');
          }
        }
      } catch (e) {
        debugPrint('⚠️ Erreur chargement eclairages: $e');
      }

      // 3. Charger les mood entries
      final moodEntries = <MoodEntry>[];
      try {
        moodEntries.addAll(
            await EmotionalTrackingService.instance.getMoodEntries());
      } catch (e) {
        debugPrint('⚠️ Erreur chargement mood entries: $e');
      }

      // 4. Construire les entrées groupées par jour
      final dayEntries = HistoryDayEntry.buildFromData(
        reflections: reflections,
        eclairages: eclairages,
        moodEntries: moodEntries,
      );

      setState(() {
        _dayEntries = dayEntries;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('❌ Erreur chargement historique: $e');
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _fondBleuNuit,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            _buildHeader(),
            // Corps : carousel ou état vide
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(color: _dateJauneOr))
                  : _dayEntries.isEmpty
                      ? _buildEmptyState()
                      : _buildCarousel(),
            ),
            // Bouton retour en bas
            _buildRetourButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          // Icône + titre
          Image.asset(
            'assets/univers_visuel/mon_chemin_parcouru.png',
            width: 36,
            height: 36,
            errorBuilder: (_, __, ___) => const Icon(
              Icons.route,
              color: _dateJauneOr,
              size: 32,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Your journey so far',
              style: GoogleFonts.cormorantGaramond(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
          // NavCartouche pensée positive
          NavCartouche(
            assetPath: 'assets/univers_visuel/pensee_positive.png',
            fallbackIcon: Icons.lightbulb_outline,
            tooltip: 'Positive thought',
            onTap: () => _showPositiveThought(context),
          ),
          const SizedBox(width: 8),
          // NavCartouche menu principal
          NavCartouche(
            assetPath: 'assets/univers_visuel/menu_principal.png',
            fallbackIcon: Icons.home_outlined,
            tooltip: 'Main menu',
            onTap: () => Navigator.pushNamedAndRemoveUntil(
                context, '/menu', (route) => false),
          ),
          const SizedBox(width: 8),
          ValueListenableBuilder<bool>(
            valueListenable: BackgroundMusicService.instance.isMutedNotifier,
            builder: (context, isMuted, _) => NavCartouche(
              assetPath: isMuted
                  ? 'assets/univers_visuel/sonoff.png'
                  : 'assets/univers_visuel/sonon.png',
              fallbackIcon: isMuted ? Icons.volume_off : Icons.volume_up,
              tooltip: isMuted ? 'Enable music' : 'Mute music',
              onTap: () => BackgroundMusicService.instance.toggleMute(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCarousel() {
    // Carte 0 = sommaire, cartes 1+ = jours
    final cards = <CarouselCardData>[
      // Sommaire (TOC)
      CarouselCardData(
        id: 'toc',
        backgroundColor: _fondCarte,
        child: _buildTocCard(),
      ),
      // Une carte par jour
      ..._dayEntries.asMap().entries.map((entry) {
        final dayEntry = entry.value;
        return CarouselCardData(
          id: 'day_${dayEntry.date.millisecondsSinceEpoch}',
          backgroundColor: _fondCarte,
          child: _buildDayCard(dayEntry),
        );
      }),
    ];

    return CardCarousel3D(
      cards: cards,
      mode: CarouselMode.vertical,
      initialIndex: 0,
      controller: _carouselController,
      cardHeight: MediaQuery.of(context).size.height * 0.65,
      cardWidth: MediaQuery.of(context).size.width * 0.88,
      angleSpacing: 40,
      verticalOffset: -10,
      onCardChanged: (index) {
        // Optionnel : feedback
      },
    );
  }

  // ──────────────────── CARTE SOMMAIRE (TOC) ────────────────────

  Widget _buildTocCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Titre sommaire
          Row(
            children: [
              Image.asset(
                'assets/univers_visuel/sommaire.png',
                width: 24,
                height: 24,
                errorBuilder: (_, __, ___) =>
                    const Icon(Icons.list_alt, color: _dateJauneOr, size: 24),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Table of Contents',
                  style: GoogleFonts.cormorantGaramond(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: _dateJauneOr,
                  ),
                ),
              ),
              Text(
                '${_dayEntries.length} day${_dayEntries.length > 1 ? 's' : ''}',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: _texteSecondaire,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Divider(color: _dateJauneOr.withValues(alpha: 0.3)),
          const SizedBox(height: 8),
          // Liste scrollable : une ligne par pensée/éclairage (pas par jour)
          Expanded(
            child: Scrollbar(
              thumbVisibility: true,
              child: ListView(
                children: _buildTocEntries(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Construit la liste du sommaire : une ligne par pensée unique + émotions
  List<Widget> _buildTocEntries() {
    final entries = <Widget>[];
    for (int dayIndex = 0; dayIndex < _dayEntries.length; dayIndex++) {
      final day = _dayEntries[dayIndex];
      final seenTexts = <String>{};

      // Chaque réflexion = une ligne (avec émotions liées si présentes)
      for (final reflection in day.reflections) {
        final text = reflection.text.trim();
        if (seenTexts.contains(text)) continue; // corr3: dédupliquer
        seenTexts.add(text);

        // corr4: ajouter les émotions liées à la pensée dans le sommaire
        String displayText = text.length > 60 ? '${text.substring(0, 60)}...' : text;
        final emotionEntries = reflection.emotionalState.emotions.entries
            .where((e) => e.value.level > 0);
        if (emotionEntries.isNotEmpty) {
          final emotionNames = emotionEntries.take(3).map((e) {
            final config = EmotionCategories.findByKey(e.key);
            return config?.name ?? e.key;
          }).join(', ');
          displayText += ' — $emotionNames';
        }

        entries.add(_buildTocLine(
          dateLabel: day.dateLabel,
          text: displayText,
          dayIndex: dayIndex,
        ));
      }
      // Éclairages sauvegardés : seulement si la pensée n'est pas déjà listée
      for (final eclairage in day.eclairages) {
        final text = eclairage.thoughtText.trim();
        if (seenTexts.contains(text)) continue; // corr3: dédupliquer
        seenTexts.add(text);
        final truncated = text.length > 60 ? '${text.substring(0, 60)}...' : text;
        entries.add(_buildTocLine(
          dateLabel: day.dateLabel,
          text: truncated,
          dayIndex: dayIndex,
          isEclairage: true,
        ));
      }
      // Mood entry = une ligne (émotions saisies indépendamment)
      if (day.moodEntry != null && day.moodEntry!.emotions.isNotEmpty) {
        final emotionNames = day.moodEntry!.emotions.entries
            .where((e) => e.value.intensity > 0)
            .take(3)
            .map((e) {
          final config = EmotionCategories.findByKey(e.key);
          return config?.name ?? e.key;
        }).join(', ');
        entries.add(_buildTocLine(
          dateLabel: day.dateLabel,
          text: 'Emotions: $emotionNames',
          dayIndex: dayIndex,
          isMood: true,
        ));
      }
    }
    return entries;
  }

  Widget _buildTocLine({
    required String dateLabel,
    required String text,
    required int dayIndex,
    bool isEclairage = false,
    bool isMood = false,
  }) {
    return InkWell(
      onTap: () => _carouselController.animateToIndex(dayIndex + 1),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
        margin: const EdgeInsets.only(bottom: 2),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(color: Colors.white.withValues(alpha: 0.06)),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Icône calendrier
            Image.asset(
              'assets/univers_visuel/calendrier.png',
              width: 18,
              height: 18,
              errorBuilder: (_, __, ___) => const Icon(
                Icons.calendar_today,
                color: _dateJauneOr,
                size: 16,
              ),
            ),
            const SizedBox(width: 6),
            // Date
            SizedBox(
              width: 80,
              child: Text(
                dateLabel,
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: _dateJauneOr,
                ),
              ),
            ),
            const SizedBox(width: 6),
            // Pensée
            Expanded(
              child: Text(
                text,
                style: GoogleFonts.poppins(
                  fontSize: 11,
                  color: _texteClair,
                  fontStyle: isMood ? FontStyle.italic : FontStyle.normal,
                  height: 1.3,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const Icon(Icons.chevron_right, color: _texteSecondaire, size: 16),
          ],
        ),
      ),
    );
  }

  // ──────────────────── CARTE JOUR ────────────────────

  Widget _buildDayCard(HistoryDayEntry dayEntry) {
    // Extraire le titre (première pensée ou description)
    String? titleText;
    if (dayEntry.reflections.isNotEmpty) {
      final t = dayEntry.reflections.first.text;
      titleText = t.length > 80 ? '${t.substring(0, 80)}...' : t;
    } else if (dayEntry.eclairages.isNotEmpty) {
      final t = dayEntry.eclairages.first.thoughtText;
      titleText = t.length > 80 ? '${t.substring(0, 80)}...' : t;
    }

    // Émotions liées (de la première réflexion)
    final firstReflectionEmotions = dayEntry.reflections.isNotEmpty
        ? dayEntry.reflections.first.emotionalState
        : null;

    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header : date + icônes sommaire/partage ──
          Row(
            children: [
              Image.asset(
                'assets/univers_visuel/calendrier.png',
                width: 22,
                height: 22,
                errorBuilder: (_, __, ___) =>
                    const Icon(Icons.calendar_today, color: _dateJauneOr, size: 18),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  dayEntry.dateLabel,
                  style: GoogleFonts.cormorantGaramond(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: _dateJauneOr,
                  ),
                ),
              ),
              // Icône Sommaire (retour au sommaire)
              _buildCardIcon(
                assetPath: 'assets/univers_visuel/sommaire.png',
                fallbackIcon: Icons.list_alt,
                tooltip: 'Table of Contents',
                onTap: () => _carouselController.animateToIndex(0),
              ),
              const SizedBox(width: 6),
              // Icône Partager
              _buildCardIcon(
                assetPath: 'assets/univers_visuel/partage.png',
                fallbackIcon: Icons.share,
                tooltip: 'Share',
                onTap: () => _shareDayEntry(dayEntry),
              ),
            ],
          ),
          // ── Titre : pensée/situation soumise ──
          if (titleText != null) ...[
            const SizedBox(height: 6),
            Text(
              titleText,
              style: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: _texteClair,
                height: 1.3,
              ),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ],
          // ── Émotions liées (juste sous le titre) ──
          if (firstReflectionEmotions != null &&
              firstReflectionEmotions.emotions.entries.any((e) => e.value.level > 0)) ...[
            const SizedBox(height: 6),
            _buildEmotionChips(firstReflectionEmotions),
          ],
          const SizedBox(height: 4),
          Divider(color: _dateJauneOr.withValues(alpha: 0.3)),
          const SizedBox(height: 4),
          // ── Contenu scrollable ──
          Expanded(
            child: Scrollbar(
              thumbVisibility: true,
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Réflexions (la pensée complète + éclairages inline)
                    for (final reflection in dayEntry.reflections)
                      _buildReflectionSection(reflection),
                    // Éclairages sauvegardés
                    for (final eclairage in dayEntry.eclairages)
                      _buildEclairageSection(eclairage),
                    // Émotions du jour (MoodEntry) — avec mini pie chart
                    if (dayEntry.moodEntry != null)
                      _buildMoodSection(dayEntry.moodEntry!),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Mini icône cliquable dans l'en-tête d'une carte (32x32)
  Widget _buildCardIcon({
    required String assetPath,
    required IconData fallbackIcon,
    required String tooltip,
    required VoidCallback onTap,
  }) {
    return Tooltip(
      message: tooltip,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: _dateJauneOr.withValues(alpha: 0.3),
              width: 1,
            ),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(5),
            child: Image.asset(
              assetPath,
              width: 30,
              height: 30,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Icon(
                fallbackIcon,
                color: _dateJauneOr.withValues(alpha: 0.7),
                size: 18,
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Partager le contenu d'une carte jour
  void _shareDayEntry(HistoryDayEntry dayEntry) {
    final buffer = StringBuffer();
    buffer.writeln('My journey so far — ${dayEntry.dateLabel}');
    buffer.writeln('');
    for (final r in dayEntry.reflections) {
      buffer.writeln('💭 ${r.text}');
      if (r.emotionalState.emotions.entries.any((e) => e.value.level > 0)) {
        final emotions = r.emotionalState.emotions.entries
            .where((e) => e.value.level > 0)
            .map((e) {
          final config = EmotionCategories.findByKey(e.key);
          return config?.name ?? e.key;
        });
        buffer.writeln('   Emotions: ${emotions.join(', ')}');
      }
    }
    for (final e in dayEntry.eclairages) {
      buffer.writeln('✨ Source: ${e.sourceName}');
      if (e.figureName != null) buffer.writeln('   Figure: ${e.figureName}');
      buffer.writeln('   ${e.eclairageText}');
    }
    if (dayEntry.moodEntry != null) {
      final emotions = dayEntry.moodEntry!.emotions.entries
          .where((e) => e.value.intensity > 0)
          .map((e) {
        final config = EmotionCategories.findByKey(e.key);
        return '${config?.name ?? e.key} (${e.value.intensity}%)';
      });
      buffer.writeln('🎭 Today\'s emotions: ${emotions.join(', ')}');
    }
    buffer.writeln('');
    buffer.writeln('— Another Perspective');
    Share.share(buffer.toString());
  }

  // ──────────────────── SECTION RÉFLEXION ────────────────────

  Widget _buildReflectionSection(Reflection reflection) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Type + heure
          Row(
            children: [
              Image.asset(
                _getTypeIconPath(reflection.type),
                width: 20,
                height: 20,
                errorBuilder: (_, __, ___) => Icon(
                  Icons.edit_note,
                  color: _dateJauneOr.withValues(alpha: 0.7),
                  size: 20,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                reflection.type.displayName,
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: _dateJauneOr,
                ),
              ),
              const Spacer(),
              Text(
                '${reflection.createdAt.hour.toString().padLeft(2, '0')}:${reflection.createdAt.minute.toString().padLeft(2, '0')}',
                style: GoogleFonts.poppins(
                  fontSize: 11,
                  color: _texteSecondaire,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          // Texte de la pensée
          Text(
            reflection.text,
            style: GoogleFonts.poppins(
              fontSize: 13,
              color: _texteClair,
              height: 1.5,
            ),
          ),
          // Émotions liées
          if (reflection.emotionalState.emotions.entries
              .any((e) => e.value.level > 0)) ...[
            const SizedBox(height: 10),
            _buildEmotionChips(reflection.emotionalState),
          ],
          // Éclairages IA
          if (reflection.aiResponses.isNotEmpty) ...[
            const SizedBox(height: 10),
            ...reflection.aiResponses.entries.map((entry) {
              final approachConfig = ApproachCategories.findByKey(entry.key);
              final sourceName = approachConfig?.name ?? entry.key;
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.04),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                      color: _dateJauneOr.withValues(alpha: 0.15)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      sourceName,
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: _dateJauneOr.withValues(alpha: 0.8),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      entry.value,
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: _texteClair.withValues(alpha: 0.9),
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ],
      ),
    );
  }

  // ──────────────────── SECTION ÉCLAIRAGE SAUVEGARDÉ ────────────────────

  Widget _buildEclairageSection(SavedEclairage eclairage) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _dateJauneOr.withValues(alpha: 0.12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Source + figure
          Row(
            children: [
              const Icon(Icons.auto_awesome, color: _dateJauneOr, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  eclairage.sourceName,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: _dateJauneOr,
                  ),
                ),
              ),
              Text(
                '${eclairage.savedAt.hour.toString().padLeft(2, '0')}:${eclairage.savedAt.minute.toString().padLeft(2, '0')}',
                style: GoogleFonts.poppins(
                  fontSize: 11,
                  color: _texteSecondaire,
                ),
              ),
            ],
          ),
          if (eclairage.figureName != null) ...[
            const SizedBox(height: 4),
            Text(
              'Figure: ${eclairage.figureName}',
              style: GoogleFonts.poppins(
                fontSize: 11,
                fontStyle: FontStyle.italic,
                color: _texteSecondaire,
              ),
            ),
          ],
          const SizedBox(height: 8),
          // Pensée originale
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.03),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.format_quote,
                    color: _texteSecondaire, size: 14),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    eclairage.thoughtText,
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      color: _texteSecondaire,
                      fontStyle: FontStyle.italic,
                      height: 1.3,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          // Texte de l'éclairage
          Text(
            eclairage.eclairageText,
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: _texteClair.withValues(alpha: 0.9),
              height: 1.4,
            ),
          ),
          // Approfondissement
          if (eclairage.deepeningText != null &&
              eclairage.deepeningText!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: _dateJauneOr.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Deepening',
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: _dateJauneOr.withValues(alpha: 0.8),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    eclairage.deepeningText!,
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: _texteClair.withValues(alpha: 0.85),
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ],
          // Réponse utilisateur
          if (eclairage.userResponse != null &&
              eclairage.userResponse!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF10B981).withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'My response',
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF10B981),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    eclairage.userResponse!,
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: _texteClair,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ──────────────────── SECTION MOOD ENTRY ────────────────────

  Widget _buildMoodSection(MoodEntry moodEntry) {
    if (moodEntry.emotions.isEmpty) return const SizedBox.shrink();

    // Collecter les émotions actives avec config
    final activeEmotions = <_MoodEmotionData>[];
    for (final entry in moodEntry.emotions.entries) {
      if (entry.value.intensity > 0) {
        final config = EmotionCategories.findByKey(entry.key);
        activeEmotions.add(_MoodEmotionData(
          key: entry.key,
          name: config?.name ?? entry.key,
          intensity: entry.value.intensity,
          nuances: entry.value.nuances,
          color: config?.color ?? const Color(0xFF94A3B8),
        ));
      }
    }
    activeEmotions.sort((a, b) => b.intensity.compareTo(a.intensity));

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Image.asset(
                'assets/univers_visuel/emotionsdujour.png',
                width: 20,
                height: 20,
                errorBuilder: (_, __, ___) => const Icon(
                  Icons.mood,
                  color: _dateJauneOr,
                  size: 20,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'Today\'s emotions',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: _dateJauneOr,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // ── Mandala complet en mode pieChart ──
          Center(
            child: SizedBox(
              width: 260,
              height: 260,
              child: InteractivePlutchikWheel(
                pieChartMode: true,
                maskStyle: MaskStyle.pastel,
                confirmedIndices: _moodToConfirmedIndices(moodEntry),
                confirmedIntensities: _moodToConfirmedIntensities(moodEntry),
                onEmotionTapped: (_) {},
                onNuanceTapped: (_) {},
              ),
            ),
          ),
          const SizedBox(height: 10),
          // ── Nuances écrites en bas ──
          for (final e in activeEmotions) ...[
            if (e.nuances.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      margin: const EdgeInsets.only(top: 4),
                      decoration: BoxDecoration(
                        color: e.color,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        '${e.name}: ${e.nuances.join(', ')}',
                        style: GoogleFonts.poppins(
                          fontSize: 10,
                          fontStyle: FontStyle.italic,
                          color: _texteSecondaire,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
          // Note du jour
          if (moodEntry.hasNote) ...[
            const SizedBox(height: 6),
            Text(
              'Note: ${moodEntry.note}',
              style: GoogleFonts.poppins(
                fontSize: 11,
                color: _texteClair,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ],
      ),
    );
  }


  // ──────────────────── CHIPS ÉMOTIONS (réflexions) ────────────────────

  Widget _buildEmotionChips(EmotionalState emotionalState) {
    final mainEmotions = emotionalState.emotions.entries
        .where((entry) => entry.value.level > 3)
        .toList()
      ..sort((a, b) => b.value.level.compareTo(a.value.level));

    if (mainEmotions.isEmpty) return const SizedBox.shrink();

    return Wrap(
      spacing: 6,
      runSpacing: 4,
      children: mainEmotions.take(5).map((emotion) {
        final config = EmotionCategories.findByKey(emotion.key);
        final color = config?.color ?? const Color(0xFF10B981);
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            '${config?.name ?? emotion.key} ${emotion.value.level}%',
            style: GoogleFonts.poppins(
              fontSize: 10,
              fontWeight: FontWeight.w500,
              color: color,
            ),
          ),
        );
      }).toList(),
    );
  }

  // ──────────────────── UTILITAIRES ────────────────────

  /// Convertir MoodEntry → confirmedIndices (Set<int> d'indices externes)
  Set<int> _moodToConfirmedIndices(MoodEntry moodEntry) {
    final indices = <int>{};
    final negList = EmotionCategories.negativeEmotions;
    final posList = EmotionCategories.positiveEmotions;
    for (final key in moodEntry.emotions.keys) {
      final negIdx = negList.indexWhere((e) => e.key == key);
      if (negIdx >= 0) {
        indices.add(negIdx); // externe 0-8 = negative
      } else {
        final posIdx = posList.indexWhere((e) => e.key == key);
        if (posIdx >= 0) {
          indices.add(9 + posIdx); // externe 9-17 = positive
        }
      }
    }
    return indices;
  }

  /// Convertir MoodEntry → confirmedIntensities (Map<int,int> externe → 0-10)
  Map<int, int> _moodToConfirmedIntensities(MoodEntry moodEntry) {
    final result = <int, int>{};
    final negList = EmotionCategories.negativeEmotions;
    final posList = EmotionCategories.positiveEmotions;
    for (final entry in moodEntry.emotions.entries) {
      if (entry.value.intensity <= 0) continue;
      final negIdx = negList.indexWhere((e) => e.key == entry.key);
      int externalIdx;
      if (negIdx >= 0) {
        externalIdx = negIdx;
      } else {
        final posIdx = posList.indexWhere((e) => e.key == entry.key);
        if (posIdx >= 0) {
          externalIdx = 9 + posIdx;
        } else {
          continue;
        }
      }
      // Convertir intensité 0-100 → 0-10
      result[externalIdx] = (entry.value.intensity / 10).round().clamp(1, 10);
    }
    return result;
  }

  String _getTypeIconPath(ReflectionType type) {
    switch (type) {
      case ReflectionType.thought:
        return 'assets/univers_visuel/pensee.png';
      case ReflectionType.situation:
        return 'assets/univers_visuel/situation.png';
      case ReflectionType.existential:
        return 'assets/univers_visuel/question_existentielle.png';
      case ReflectionType.dilemma:
        return 'assets/univers_visuel/dilemme.png';
    }
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset(
            'assets/univers_visuel/mon_chemin_parcouru.png',
            width: 64,
            height: 64,
            errorBuilder: (_, __, ___) => const Icon(
              Icons.route,
              size: 64,
              color: _texteSecondaire,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'No reflections yet',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: _texteClair,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Your saved insights will appear here',
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: _texteSecondaire,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRetourButton() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      child: NavCartoucheRetour(
        onTap: () => Navigator.pop(context),
      ),
    );
  }

  void _showPositiveThought(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => _PositiveThoughtDialog(),
    );
  }
}

// ============================================================================
// DIALOG PENSEE POSITIVE (générée par l'IA)
// ============================================================================

class _PositiveThoughtDialog extends StatefulWidget {
  @override
  State<_PositiveThoughtDialog> createState() => _PositiveThoughtDialogState();
}

class _PositiveThoughtDialogState extends State<_PositiveThoughtDialog> {
  String? _thought;
  bool _isLoading = true;
  bool _isError = false;

  @override
  void initState() {
    super.initState();
    _generate();
  }

  Future<void> _generate() async {
    try {
      final userProfile = PersistentStorageService.instance.getUserProfile();

      String? historique7Jours;
      try {
        final entries = await EmotionalTrackingService.instance.getEntriesForLastDays(7);
        if (entries.isNotEmpty) {
          final buffer = StringBuffer();
          for (final entry in entries) {
            final dateStr = '${entry.date.day}/${entry.date.month}/${entry.date.year}';
            final emotionsStr = entry.emotions.entries
                .map((e) => '${e.key} ${e.value.intensity}/100')
                .join(', ');
            buffer.writeln('$dateStr : $emotionsStr');
          }
          historique7Jours = buffer.toString().trim();
        }
      } catch (_) {}

      final result = await AIService.instance.generatePositiveThought(
        userProfile: userProfile,
        historique7Jours: historique7Jours,
      );

      if (mounted) {
        final isErr = result.startsWith('❌');
        setState(() {
          _thought = isErr ? null : result;
          _isLoading = false;
          _isError = isErr;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _isError = true;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFFEF3C7), Color(0xFFFDE68A)],
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(
              'assets/univers_visuel/pensee_positive.png',
              width: 64, height: 64,
              errorBuilder: (_, __, ___) =>
                  const Icon(Icons.lightbulb, color: Color(0xFFFBBF24), size: 48),
            ),
            const SizedBox(height: 20),
            Text(
              'Thought of the moment',
              style: GoogleFonts.cormorantGaramond(
                fontSize: 20, fontWeight: FontWeight.bold,
                color: const Color(0xFF92400E),
              ),
            ),
            const SizedBox(height: 16),
            if (_isLoading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: SizedBox(
                  width: 32, height: 32,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFBBF24)),
                  ),
                ),
              )
            else if (_isError)
              Text(
                'Unable to generate a thought at the moment.',
                style: GoogleFonts.inter(fontSize: 15, color: const Color(0xFF78350F), height: 1.5),
                textAlign: TextAlign.center,
              )
            else
              Text(
                _thought ?? '',
                style: GoogleFonts.inter(fontSize: 15, color: const Color(0xFF78350F), height: 1.5),
                textAlign: TextAlign.center,
              ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFBBF24),
                foregroundColor: const Color(0xFF78350F),
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: Text('Thank you!', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
            ),
          ],
        ),
      ),
    );
  }
}

// ──────────────────── MODÈLE HELPER ────────────────────

class _MoodEmotionData {
  final String key;
  final String name;
  final int intensity;
  final List<String> nuances;
  final Color color;
  const _MoodEmotionData({
    required this.key,
    required this.name,
    required this.intensity,
    required this.nuances,
    required this.color,
  });
}

// ──────────────────── MINI PIE CHART PAINTER ────────────────────

class _MiniPieChartPainter extends CustomPainter {
  final List<_MoodEmotionData> emotions;
  const _MiniPieChartPainter({required this.emotions});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final outerRadius = size.width / 2 - 4;
    final innerRadius = outerRadius * 0.35;

    if (emotions.isEmpty) return;

    // Calculer le total des intensités
    final total = emotions.fold<int>(0, (sum, e) => sum + e.intensity);
    if (total == 0) return;

    double startAngle = -math.pi / 2; // Commencer en haut

    for (final emotion in emotions) {
      final sweepAngle = (emotion.intensity / total) * 2 * math.pi;

      // Arc extérieur (donut)
      final paint = Paint()
        ..color = emotion.color.withValues(alpha: 0.85)
        ..style = PaintingStyle.fill;

      final path = Path();
      path.arcTo(
        Rect.fromCircle(center: center, radius: outerRadius),
        startAngle,
        sweepAngle,
        false,
      );
      path.arcTo(
        Rect.fromCircle(center: center, radius: innerRadius),
        startAngle + sweepAngle,
        -sweepAngle,
        false,
      );
      path.close();
      canvas.drawPath(path, paint);

      // Séparation entre portions
      final sepPaint = Paint()
        ..color = const Color(0xFF132A44)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2;
      canvas.drawPath(path, sepPaint);

      // Texte : intensité au milieu de la portion
      final midAngle = startAngle + sweepAngle / 2;
      final textRadius = (outerRadius + innerRadius) / 2;
      final textX = center.dx + textRadius * math.cos(midAngle);
      final textY = center.dy + textRadius * math.sin(midAngle);

      final textPainter = TextPainter(
        text: TextSpan(
          text: '${emotion.intensity}%',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 10,
            fontWeight: FontWeight.bold,
            shadows: [Shadow(color: Colors.black54, blurRadius: 2)],
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();

      // Ne dessiner le texte que si la portion est assez grande
      if (sweepAngle > 0.4) {
        textPainter.paint(
          canvas,
          Offset(textX - textPainter.width / 2, textY - textPainter.height / 2),
        );
      }

      startAngle += sweepAngle;
    }

    // Cercle central (fond)
    final centerPaint = Paint()
      ..color = const Color(0xFF132A44)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, innerRadius, centerPaint);

    // Cercle central doré
    final borderPaint = Paint()
      ..color = const Color(0xFFFFD54F).withValues(alpha: 0.4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    canvas.drawCircle(center, innerRadius, borderPaint);
  }

  @override
  bool shouldRepaint(covariant _MiniPieChartPainter oldDelegate) {
    return oldDelegate.emotions != emotions;
  }
}
