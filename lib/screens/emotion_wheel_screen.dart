// lib/screens/emotion_wheel_screen.dart
// Écran roue des émotions Plutchik — multi-émotions avec accumulation
// Deux modes d'entrée : "Partage ce que tu ressens" (→ sauvegarder → radar)
//                       "Exprime" (→ regarde autrement → génération IA)

import 'dart:math' show pi;
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart' show Clipboard, ClipboardData;
import 'package:google_fonts/google_fonts.dart';
import 'package:path_provider/path_provider.dart';
import '../services/background_music_service.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:io';
import '../config/approach_config.dart';
import '../config/emotion_config.dart';
import '../models/reflection.dart';
import '../models/mood_entry.dart';
import '../models/emotional_state.dart';
import '../services/ai_service.dart';
import '../services/emotional_tracking_service.dart';
import '../services/persistent_storage_service.dart';
import '../widgets/interactive_plutchik_wheel.dart';
import '../widgets/nav_cartouche.dart';
import '../widgets/brain_gestation_widget.dart';
import 'eclairages_carousel_screen.dart';
import 'perspective_room_screen.dart';

/// Mode d'entrée dans l'écran des émotions
enum EmotionWheelEntryMode {
  /// Depuis "Partage ce que tu ressens" — bouton Sauvegarder → radar + partage
  partage,
  /// Depuis "Exprime" / saisie pensée — bouton "Regarde autrement" → génération IA
  exprime,
}

/// Données d'une émotion confirmée (ombrée sur le mandala)
class _ConfirmedEmotion {
  final int index; // index dans _allEmotions (neg + pos)
  final EmotionConfig config;
  final int intensity;
  final Set<String> nuances;

  _ConfirmedEmotion({
    required this.index,
    required this.config,
    required this.intensity,
    required this.nuances,
  });
}

class EmotionWheelScreen extends StatefulWidget {
  final ApproachConfig? preselectedSource;
  final EmotionWheelEntryMode entryMode;

  // Paramètres pour le mode "exprime" (génération IA)
  final String? thoughtText;
  final ReflectionType? reflectionType;

  const EmotionWheelScreen({
    super.key,
    this.preselectedSource,
    this.entryMode = EmotionWheelEntryMode.partage,
    this.thoughtText,
    this.reflectionType,
  });

  @override
  State<EmotionWheelScreen> createState() => _EmotionWheelScreenState();
}

class _EmotionWheelScreenState extends State<EmotionWheelScreen>
    with SingleTickerProviderStateMixin {
  static final List<EmotionConfig> _allEmotions = [
    ...EmotionCategories.negativeEmotions,
    ...EmotionCategories.positiveEmotions,
  ];

  // Émotion actuellement sélectionnée (en cours d'édition)
  int? _selectedIndex;
  int _intensity = 0; // Démarre à 0 (écran 24)
  final Set<String> _selectedNuances = {};

  // Émotions confirmées (ombrées sur le mandala)
  final List<_ConfirmedEmotion> _confirmedEmotions = [];

  // Mode camembert (après sauvegarde)
  bool _pieChartMode = false;
  final GlobalKey _mandalaRepaintKey = GlobalKey();

  // Génération IA en cours
  bool _isGenerating = false;

  // Animation du panel du bas
  late AnimationController _panelController;
  late Animation<double> _panelSlide;

  @override
  void initState() {
    super.initState();
    _panelController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _panelSlide = CurvedAnimation(
      parent: _panelController,
      curve: Curves.easeOutCubic,
    );
    // Musique gérée par BackgroundMusicService (NavigatorObserver)
    BackgroundMusicService.instance.play('sounds/soulmusic-hare-krishna-relaxing-theme-4-114482.mp3');
  }

  @override
  void dispose() {
    _panelController.dispose();
    super.dispose();
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // GESTION DES ÉMOTIONS
  // ═══════════════════════════════════════════════════════════════════════════

  void _onEmotionTapped(int index) {
    setState(() {
      if (_selectedIndex == index) return; // déjà sélectionné

      // Si une émotion était sélectionnée avec intensité > 0, la confirmer
      if (_selectedIndex != null && _intensity > 0) {
        _confirmCurrentEmotion();
      }

      _selectedIndex = index;
      _intensity = 0; // Intensité démarre à 0
      _selectedNuances.clear();
    });
    _panelController.forward(from: 0);
  }

  /// Confirme l'émotion courante et l'ajoute à la liste des confirmées
  void _confirmCurrentEmotion() {
    if (_selectedIndex == null || _intensity == 0) return;

    // Retirer si déjà confirmée (pour mise à jour)
    _confirmedEmotions.removeWhere((e) => e.index == _selectedIndex);

    _confirmedEmotions.add(_ConfirmedEmotion(
      index: _selectedIndex!,
      config: _allEmotions[_selectedIndex!],
      intensity: _intensity,
      nuances: Set<String>.from(_selectedNuances),
    ));
  }

  EmotionConfig? get _selectedEmotion =>
      _selectedIndex != null ? _allEmotions[_selectedIndex!] : null;

  /// Vérifie s'il y a au moins une émotion avec intensité > 0
  bool get _hasEmotions {
    // Émotion courante avec intensité > 0 OU émotions confirmées
    return (_selectedIndex != null && _intensity > 0) ||
        _confirmedEmotions.isNotEmpty;
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // ACTIONS
  // ═══════════════════════════════════════════════════════════════════════════

  void _showPositiveThought() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => _PositiveThoughtDialog(),
    );
  }

  /// Sauvegarder les émotions → afficher le radar + partage (mode Partage)
  Future<void> _saveAndShowRadar() async {
    // Confirmer l'émotion courante si nécessaire
    if (_selectedIndex != null && _intensity > 0) {
      _confirmCurrentEmotion();
    }

    if (_confirmedEmotions.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Select at least one emotion with an intensity',
            style: GoogleFonts.inter(),
          ),
        ),
      );
      return;
    }

    // Construire le Map<String, EmotionDetail> pour MoodEntry
    // Le mandala utilise 0-10, MoodEntry attend 0-100 → multiplier par 10
    final emotionsMap = <String, EmotionDetail>{};
    for (final confirmed in _confirmedEmotions) {
      emotionsMap[confirmed.config.key] = EmotionDetail(
        intensity: confirmed.intensity * 10,
        nuances: confirmed.nuances.toList(),
      );
    }

    // Sauvegarder via EmotionalTrackingService
    final entry = MoodEntry.forToday(emotionsMap);
    await EmotionalTrackingService.instance.saveMoodEntry(entry);

    // Basculer en mode camembert (rester sur le même écran)
    if (mounted) {
      setState(() {
        _pieChartMode = true;
        _selectedIndex = null; // Désélectionner pour masquer le panel
      });
    }
  }

  /// Générer les éclairages IA (mode Exprime)
  Future<void> _generateEclairages() async {
    // Confirmer l'émotion courante si nécessaire
    if (_selectedIndex != null && _intensity > 0) {
      _confirmCurrentEmotion();
    }

    final text = widget.thoughtText ?? '';
    if (text.isEmpty) {
      // Si pas de texte, retourner à la saisie
      Navigator.of(context).pop();
      return;
    }

    setState(() {
      _isGenerating = true;
    });

    try {
      // Construire l'état émotionnel pour la génération
      // Le mandala utilise 0-10, EmotionLevel attend 0-100 → multiplier par 10
      final emotionLevels = <String, EmotionLevel>{};
      for (final confirmed in _confirmedEmotions) {
        emotionLevels[confirmed.config.key] = EmotionLevel(
          level: confirmed.intensity * 10,
          nuances: confirmed.nuances.toList(),
        );
      }
      final emotionalState = EmotionalState(
        emotions: emotionLevels,
        timestamp: DateTime.now(),
      );

      // Calculer l'intensité moyenne
      int avgIntensity = 5;
      if (_confirmedEmotions.isNotEmpty) {
        avgIntensity = (_confirmedEmotions.fold<int>(
                    0, (sum, e) => sum + e.intensity) /
                _confirmedEmotions.length)
            .round();
      }

      final userProfile = PersistentStorageService.instance.getUserProfile();

      if (widget.preselectedSource != null) {
        final response =
            await AIService.instance.generateApproachSpecificResponse(
          approach: widget.preselectedSource!.key,
          reflectionText: text,
          reflectionType: widget.reflectionType ?? ReflectionType.thought,
          emotionalState: emotionalState,
          userProfile: userProfile,
          intensiteEmotionnelle: avgIntensity,
        );

        if (mounted) {
          final meta = AIService.instance.lastFigureMeta;
          final perspective = PerspectiveData(
            approachKey: widget.preselectedSource!.key,
            approachName: widget.preselectedSource!.name,
            responseText: response,
            figureName: meta?['nom'],
            figureReference: meta?['reference'],
          );

          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (_) => EclairagesCarouselScreen(
                thoughtText: text,
                perspectives: [perspective],
                emotionalState: emotionalState,
                intensiteEmotionnelle: avgIntensity,
              ),
            ),
          );
        }
      } else {
        // Utiliser TOUTES les sources de l'utilisateur (plus de limite)
        if (AIService.instance.userApproches.isEmpty) {
          await AIService.instance.loadUserApproaches();
        }
        final userKeys = AIService.instance.userApproches;
        final List<ApproachConfig> resolved = [];
        for (final key in userKeys) {
          final config = ApproachCategories.findByKey(key);
          if (config != null) resolved.add(config);
        }
        // Fallback sur toutes les sources si résolution échoue
        final pool = resolved.isNotEmpty
            ? resolved
            : ApproachCategories.allApproaches.toList();
        final sources = List<ApproachConfig>.from(pool);

        // Ecart 1: Generer la premiere source, naviguer immediatement,
        // passer les restantes pour generation progressive
        final firstSource = sources.first;
        final response =
            await AIService.instance.generateApproachSpecificResponse(
          approach: firstSource.key,
          reflectionText: text,
          reflectionType: widget.reflectionType ?? ReflectionType.thought,
          emotionalState: emotionalState,
          userProfile: userProfile,
          intensiteEmotionnelle: avgIntensity,
        );
        final meta = AIService.instance.lastFigureMeta;
        final firstPerspective = PerspectiveData(
          approachKey: firstSource.key,
          approachName: firstSource.name,
          responseText: response,
          figureName: meta?['nom'],
          figureReference: meta?['reference'],
        );

        if (mounted) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (_) => EclairagesCarouselScreen(
                thoughtText: text,
                perspectives: [firstPerspective],
                emotionalState: emotionalState,
                intensiteEmotionnelle: avgIntensity,
                pendingSources: sources.length > 1 ? sources.sublist(1) : null,
                reflectionType: widget.reflectionType ?? ReflectionType.thought,
              ),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isGenerating = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Error during generation. Please try again.',
              style: GoogleFonts.inter(),
            ),
          ),
        );
      }
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // BUILD
  // ═══════════════════════════════════════════════════════════════════════════

  @override
  Widget build(BuildContext context) {
    // Si en cours de génération, afficher le cerveau
    if (_isGenerating) {
      return Scaffold(
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFF1B2838), Color(0xFF0F1E35), Color(0xFF0A1628)],
            ),
          ),
          child: Center(
            child: BrainGestationWidget(
              isComplete: false,
              size: 220,
            ),
          ),
        ),
      );
    }

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF1B2838),
              Color(0xFF0F1E35),
              Color(0xFF0A1628),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // ── Barre du haut ──────────────────────────────────────────
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.arrow_back_ios,
                          color: Colors.white),
                    ),
                    Expanded(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.asset(
                              'assets/univers_visuel/partage_ce_que_tu_ressens.png',
                              width: 36,
                              height: 36,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Flexible(
                            child: Text(
                              'Share how\nyou feel',
                              style: GoogleFonts.playfairDisplay(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ],
                      ),
                    ),
                    NavCartouche(
                      assetPath: 'assets/univers_visuel/pensee_positive.png',
                      fallbackIcon: Icons.lightbulb_outline,
                      tooltip: 'Positive thought',
                      onTap: _showPositiveThought,
                    ),
                    const SizedBox(width: 8),
                    NavCartouche(
                      assetPath: 'assets/univers_visuel/menu_principal.png',
                      fallbackIcon: Icons.grid_view_rounded,
                      tooltip: 'Main menu',
                      onTap: () => Navigator.pushNamedAndRemoveUntil(
                        context, '/menu', (route) => false,
                      ),
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
              ),

              // ── Contenu scrollable ─────────────────────────────────────
              Expanded(
                child: LayoutBuilder(
                  builder: (context, outerConstraints) {
                    // Calculer la taille optimale du mandala :
                    // - Prend toute la largeur disponible (padding 8px de chaque côté)
                    // - Limite la hauteur à 78% de l'espace vertical disponible
                    //   pour maximiser la taille du mandala
                    final availableWidth = outerConstraints.maxWidth - 16; // padding 8px chaque côté
                    final maxWheelHeight = outerConstraints.maxHeight * 0.78;
                    final wheelSize = availableWidth.clamp(300.0, maxWheelHeight);

                    return SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Column(
                        children: [
                          // ── Roue Plutchik — taille responsive maximisée ──
                          // Scénarios masques : MaskStyle.terracotta / .pastel / .glyph
                          RepaintBoundary(
                            key: _mandalaRepaintKey,
                            child: Stack(
                            children: [
                            Transform.rotate(
                            angle: _pieChartMode ? (15 * pi / 180) : 0,
                            child: SizedBox(
                            width: wheelSize,
                            height: wheelSize,
                            child: InteractivePlutchikWheel(
                              maskStyle: MaskStyle.pastel,
                              selectedIndex: _pieChartMode ? null : _selectedIndex,
                              confirmedIndices: _confirmedEmotions.map((e) => e.index).toSet(),
                              selectedNuances: _pieChartMode ? const {} : _selectedNuances,
                              intensity: _intensity,
                              pieChartMode: _pieChartMode,
                              confirmedIntensities: {
                                for (final e in _confirmedEmotions)
                                  e.index: e.intensity,
                              },
                              confirmedNuances: {
                                for (final e in _confirmedEmotions)
                                  if (e.nuances.isNotEmpty) e.index: e.nuances,
                              },
                              onEmotionTapped: _pieChartMode ? (_) {} : _onEmotionTapped,
                              onNuanceTapped: _pieChartMode ? (_) {} : (nuance) {
                                setState(() {
                                  if (_selectedNuances.contains(nuance)) {
                                    _selectedNuances.remove(nuance);
                                  } else {
                                    _selectedNuances.add(nuance);
                                  }
                                });
                              },
                              onIntensityChanged: _pieChartMode ? null : (val) {
                                setState(() {
                                  _intensity = val;
                                  if (val == 0) _selectedNuances.clear();
                                });
                              },
                            ),
                          ),
                          ),
                          if (_pieChartMode)
                            Positioned(
                              bottom: 8,
                              left: 0,
                              right: 0,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: Image.asset(
                                      'assets/univers_visuel/iconeapplication.png',
                                      width: 28,
                                      height: 28,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'An Other Perspective',
                                    style: GoogleFonts.inter(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white.withValues(alpha: 0.9),
                                      shadows: [
                                        Shadow(color: Colors.black.withValues(alpha: 0.6), blurRadius: 4),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                          ),
                          ),

                          const SizedBox(height: 12),

                          // ── Panel émotion courante (slide up) ──────────────
                          if (_selectedEmotion != null)
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 8),
                              child: SlideTransition(
                                position: Tween<Offset>(
                                  begin: const Offset(0, 0.3),
                                  end: Offset.zero,
                                ).animate(_panelSlide),
                                child: FadeTransition(
                                  opacity: _panelSlide,
                                  child: _buildCurrentEmotionPanel(),
                                ),
                              ),
                            ),

                          // ── Liste des émotions confirmées ──────────────────
                          if (_confirmedEmotions.isNotEmpty) ...[
                            const SizedBox(height: 12),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 8),
                              child: _buildConfirmedEmotionsPanel(),
                            ),
                          ],

                          const SizedBox(height: 16),

                          // ── Boutons action ─────────────────────────────────
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            child: _buildActionButtons(),
                          ),

                          const SizedBox(height: 24),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // PANEL ÉMOTION COURANTE
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildCurrentEmotionPanel() {
    final emotion = _selectedEmotion!;
    final isNeg = _selectedIndex! < EmotionCategories.negativeEmotions.length;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF152440),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: emotion.color.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: emotion.color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.asset(
                _maskPathForEmotion(emotion.key),
                width: 36, height: 36,
                fit: BoxFit.cover,
                color: emotion.color,
                colorBlendMode: BlendMode.modulate,
                errorBuilder: (_, __, ___) => Center(
                  child: Image.asset(
                    emotion.iconPath,
                    width: 22, height: 22,
                    errorBuilder: (_, __, ___) =>
                        Icon(emotion.icon, color: emotion.color, size: 20),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  emotion.name,
                  style: GoogleFonts.playfairDisplay(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: emotion.color,
                  ),
                ),
                Text(
                  '${isNeg ? "Tension" : "Support"} · Intensity $_intensity/10',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: const Color(0xFFADB5C7),
                  ),
                ),
              ],
            ),
          ),
          // Indication : cliquer au centre pour intensité
          if (_intensity == 0)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: emotion.color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'Tap the center\nfor intensity',
                style: GoogleFonts.inter(
                  fontSize: 9,
                  color: emotion.color.withValues(alpha: 0.8),
                ),
                textAlign: TextAlign.center,
              ),
            ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // PANEL ÉMOTIONS CONFIRMÉES (accumulées)
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildConfirmedEmotionsPanel() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF152440),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.1),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Selected emotions',
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.white.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: 8),
          ..._confirmedEmotions.map((confirmed) {
            final isNeg = confirmed.index <
                EmotionCategories.negativeEmotions.length;
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Icône masque visage
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: confirmed.config.color.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: ClipOval(
                      child: Image.asset(
                        _maskPathForEmotion(confirmed.config.key),
                        width: 32, height: 32,
                        fit: BoxFit.cover,
                        color: confirmed.config.color,
                        colorBlendMode: BlendMode.modulate,
                        errorBuilder: (_, __, ___) => Image.asset(
                          confirmed.config.iconPath,
                          width: 20, height: 20,
                          errorBuilder: (_, __, ___) => Icon(
                            confirmed.config.icon,
                            color: confirmed.config.color,
                            size: 18,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Nom + intensité
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              confirmed.config.name,
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: confirmed.config.color,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              '${isNeg ? "Tension" : "Support"} · ${confirmed.intensity}/10',
                              style: GoogleFonts.inter(
                                fontSize: 10,
                                color: const Color(0xFFADB5C7),
                              ),
                            ),
                          ],
                        ),
                        // Nuances
                        if (confirmed.nuances.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Wrap(
                            spacing: 4,
                            runSpacing: 3,
                            children: confirmed.nuances.map((nuance) {
                              return Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 7, vertical: 2),
                                decoration: BoxDecoration(
                                  color: confirmed.config.color
                                      .withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  nuance,
                                  style: GoogleFonts.inter(
                                    fontSize: 9,
                                    color:
                                        Colors.white.withValues(alpha: 0.8),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ],
                      ],
                    ),
                  ),
                  // Bouton supprimer
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        _confirmedEmotions
                            .removeWhere((e) => e.index == confirmed.index);
                      });
                    },
                    child: Icon(
                      Icons.close_rounded,
                      size: 16,
                      color: Colors.white.withValues(alpha: 0.4),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  // ── Helper : chemin masque pastel pour une clé d'émotion ──────────────────
  static const Map<String, String> _emotionToMaskFile = {
    'HEUREUX': 'heureux', 'AIMANT': 'aimant', 'PAISIBLE': 'paisible',
    'DETENDU': 'detendu', 'VIVANT': 'vivant', 'OUVERT': 'ouvert',
    'POSITIF': 'positif', 'INTERESSE': 'interesse', 'FORT': 'fort',
    'TRISTE': 'triste', 'BLESSE': 'blesse', 'EFFRAYE': 'effraye',
    'EN_COLERE': 'colere', 'DEPRIME': 'deprime', 'IMPUISSANT': 'impuissant',
    'CONFUS': 'confus', 'INDIFFERENT': 'indifferent', 'CRITIQUE': 'critique',
  };

  String _maskPathForEmotion(String emotionKey) {
    final maskFile = _emotionToMaskFile[emotionKey] ?? emotionKey.toLowerCase();
    return 'assets/masks/pastel/pastel_$maskFile.png';
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // BOUTONS D'ACTION (contextuels selon le mode)
  // ═══════════════════════════════════════════════════════════════════════════

  /// Construire un résumé texte des émotions pour le partage
  String _buildShareText() {
    final buffer = StringBuffer();
    buffer.writeln('I\'m sharing my mood today with An Other Perspective');
    buffer.writeln('');
    for (final e in _confirmedEmotions) {
      final name = e.config.name;
      buffer.writeln('• $name — intensity ${e.intensity}/10');
      if (e.nuances.isNotEmpty) {
        buffer.writeln('  Nuances: ${e.nuances.join(', ')}');
      }
    }
    buffer.writeln('');
    buffer.writeln('— An Other Perspective');
    return buffer.toString();
  }

  /// Déterminer si on est sur mobile (Android/iOS)
  bool get _isMobilePlatform {
    if (kIsWeb) return false;
    try {
      return Platform.isAndroid || Platform.isIOS;
    } catch (_) {
      return false;
    }
  }

  /// Capturer le mandala en mode pieChart et partager
  /// Sur mobile (Android/iOS) : partage image via Share.shareXFiles
  /// Sur web/desktop (Windows/Mac/Linux) : partage texte via Share.share, fallback clipboard
  Future<void> _shareMandalaPieChart() async {
    final shareText = _buildShareText();

    // Sur mobile : essayer le partage image, fallback vers texte
    if (_isMobilePlatform) {
      try {
        await Future.delayed(const Duration(milliseconds: 300));

        final boundary = _mandalaRepaintKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
        if (boundary == null) {
          throw Exception('Widget not available for capture');
        }

        final image = await boundary.toImage(pixelRatio: 3.0);
        final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
        if (byteData == null) {
          throw Exception('Unable to convert image');
        }

        final pngBytes = byteData.buffer.asUint8List();
        final tempDir = await getTemporaryDirectory();
        final now = DateTime.now();
        final fileName = 'mon_mandala_${now.day}_${now.month}_${now.year}.png';
        final file = File('${tempDir.path}/$fileName');
        await file.writeAsBytes(pngBytes);

        await Share.shareXFiles(
          [XFile(file.path)],
          text: shareText,
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.white, size: 20),
                  const SizedBox(width: 10),
                  Text('Mandala shared successfully!', style: GoogleFonts.inter(fontSize: 13)),
                ],
              ),
              backgroundColor: const Color(0xFF10B981),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              duration: const Duration(seconds: 3),
            ),
          );
        }
        return;
      } catch (e) {
        debugPrint('⚠️ Partage image échoué, fallback texte: $e');
        // Fallback vers partage texte ci-dessous
      }
    }

    // Web / Desktop / Fallback mobile : partage texte
    try {
      await Share.share(shareText);
    } catch (e) {
      // Dernier recours : copie dans le presse-papiers
      try {
        await Clipboard.setData(ClipboardData(text: shareText));
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Copied to clipboard', style: GoogleFonts.inter(fontSize: 12)),
              backgroundColor: const Color(0xFF2E8B7B),
            ),
          );
        }
      } catch (_) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Sharing error: $e', style: GoogleFonts.inter(fontSize: 12)),
              backgroundColor: Colors.red[700],
            ),
          );
        }
      }
    }
  }

  Widget _buildActionButtons() {
    // Mode pieChart : 3 boutons empilés (Share + Back to mandala + Main menu)
    if (_pieChartMode) {
      return Column(
        children: [
          // Share button
          GestureDetector(
            onTap: _shareMandalaPieChart,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                color: const Color(0xFF2E8B7B),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.asset(
                    'assets/univers_visuel/partage.png',
                    width: 22, height: 22,
                    errorBuilder: (_, __, ___) => const Icon(Icons.share, size: 20, color: Colors.white),
                  ),
                  const SizedBox(width: 10),
                  Text('Share',
                      style: GoogleFonts.inter(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Colors.white)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
          // Back to mandala button
          GestureDetector(
            onTap: () => setState(() => _pieChartMode = false),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                color: const Color(0xFF2E8B7B),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.arrow_back_rounded, size: 18, color: Colors.white),
                  const SizedBox(width: 10),
                  Text('Back to mandala',
                      style: GoogleFonts.inter(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Colors.white)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
          // Main menu button
          GestureDetector(
            onTap: () {
              Navigator.of(context).popUntil((route) => route.isFirst);
              Navigator.of(context).pushReplacementNamed('/menu');
            },
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF2E8B7B), width: 1.5),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.home_rounded, size: 18, color: Color(0xFF2E8B7B)),
                  const SizedBox(width: 10),
                  Text('Main menu',
                      style: GoogleFonts.inter(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF2E8B7B))),
                ],
              ),
            ),
          ),
        ],
      );
    }

    // Mode normal : deux boutons Retour + Sauvegarder/Regarde
    return Row(
      children: [
        // Bouton Retour
        Expanded(
          child: GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                color: const Color(0xFF2E8B7B),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.arrow_back_rounded,
                      size: 18, color: Colors.white),
                  const SizedBox(width: 6),
                  Text('Back',
                      style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.white)),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        // Bouton contextuel
        Expanded(
          child: GestureDetector(
            onTap: _hasEmotions
                ? (widget.entryMode == EmotionWheelEntryMode.partage
                    ? _saveAndShowRadar
                    : _generateEclairages)
                : null,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                color: _hasEmotions
                    ? const Color(0xFF2E8B7B)
                    : const Color(0xFF2E8B7B).withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    widget.entryMode == EmotionWheelEntryMode.partage
                        ? 'Save'
                        : 'See it\ndifferently',
                    style: GoogleFonts.inter(
                      fontSize: widget.entryMode ==
                              EmotionWheelEntryMode.partage
                          ? 14
                          : 12,
                      fontWeight: FontWeight.w600,
                      color: _hasEmotions
                          ? Colors.white
                          : Colors.white.withValues(alpha: 0.4),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(width: 6),
                  Image.asset(
                    widget.entryMode == EmotionWheelEntryMode.partage
                        ? 'assets/univers_visuel/sauvegarder.png'
                        : 'assets/univers_visuel/regardeautrement.png',
                    width: 22, height: 22,
                    fit: BoxFit.contain,
                    color: _hasEmotions
                        ? null
                        : Colors.white.withValues(alpha: 0.4),
                    colorBlendMode: BlendMode.modulate,
                    errorBuilder: (_, __, ___) => Icon(
                      widget.entryMode == EmotionWheelEntryMode.partage
                          ? Icons.save_rounded
                          : Icons.auto_awesome,
                      size: 18,
                      color: _hasEmotions
                          ? Colors.white
                          : Colors.white.withValues(alpha: 0.4),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
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
              width: 64,
              height: 64,
              errorBuilder: (_, __, ___) =>
                  const Icon(Icons.lightbulb, color: Color(0xFFFBBF24), size: 48),
            ),
            const SizedBox(height: 20),
            Text(
              'Thought of the moment',
              style: GoogleFonts.cormorantGaramond(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF92400E),
              ),
            ),
            const SizedBox(height: 16),
            if (_isLoading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: SizedBox(
                  width: 32,
                  height: 32,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFBBF24)),
                  ),
                ),
              )
            else if (_isError)
              Text(
                'Unable to generate a thought at this time.',
                style: GoogleFonts.inter(
                  fontSize: 15,
                  color: const Color(0xFF78350F),
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              )
            else
              Text(
                _thought ?? '',
                style: GoogleFonts.inter(
                  fontSize: 15,
                  color: const Color(0xFF78350F),
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFBBF24),
                foregroundColor: const Color(0xFF78350F),
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                'Thanks!',
                style: GoogleFonts.inter(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
