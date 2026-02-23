// lib/screens/emotion_wheel_screen.dart
// Écran roue des émotions Plutchik — multi-émotions avec accumulation
// Deux modes d'entrée : "Partage ce que tu ressens" (→ sauvegarder → radar)
//                       "Exprime" (→ regarde autrement → génération IA)

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../config/approach_config.dart';
import '../config/emotion_config.dart';
import '../models/reflection.dart';
import '../models/mood_entry.dart';
import '../models/emotional_state.dart';
import '../services/ai_service.dart';
import '../services/emotional_tracking_service.dart';
import '../widgets/interactive_plutchik_wheel.dart';
import '../widgets/nav_cartouche.dart';
import '../widgets/brain_gestation_widget.dart';
import '../widgets/emotion_wheel_widget.dart';
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

  /// Indices des émotions confirmées pour le widget mandala
  Set<int> get _confirmedIndicesSet {
    return _confirmedEmotions.map((e) => e.index).toSet();
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
    final thoughts = [
      "Chaque jour est une nouvelle opportunité de grandir.",
      "Tu as déjà surmonté tant d'obstacles. Tu es plus fort(e) que tu ne le penses.",
      "Prends le temps de respirer. Ce moment difficile passera.",
      "Tu mérites d'être heureux(se) et en paix.",
      "Tes émotions sont valides. Accueille-les avec bienveillance.",
      "Un petit pas aujourd'hui peut mener à un grand changement demain.",
    ];
    final random = DateTime.now().millisecondsSinceEpoch % thoughts.length;
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
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
                errorBuilder: (_, __, ___) => const Icon(Icons.lightbulb, color: Color(0xFFFBBF24), size: 48),
              ),
              const SizedBox(height: 20),
              Text('Pensée du moment', style: GoogleFonts.cormorantGaramond(fontSize: 20, fontWeight: FontWeight.bold, color: const Color(0xFF92400E))),
              const SizedBox(height: 16),
              Text(thoughts[random], style: GoogleFonts.inter(fontSize: 15, color: const Color(0xFF78350F), height: 1.5), textAlign: TextAlign.center),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => Navigator.pop(ctx),
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFBBF24), foregroundColor: const Color(0xFF78350F), padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                child: Text('Merci !', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
              ),
            ],
          ),
        ),
      ),
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
            'Sélectionne au moins une émotion avec une intensité',
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

    if (mounted) {
      // Afficher le radar des émotions dans un dialog
      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.all(16),
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xFF0F1E35),
              borderRadius: BorderRadius.circular(20),
            ),
            padding: const EdgeInsets.all(20),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // ── Barre du haut : cartouche verte + icônes pensée positive & home ──
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Cartouche verte avec calendrier + titre + émotions du jour
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          decoration: BoxDecoration(
                            color: const Color(0xFF2E8B7B),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              Image.asset(
                                'assets/univers_visuel/calendrier.png',
                                width: 24, height: 24,
                                errorBuilder: (_, __, ___) => const Icon(Icons.calendar_today, color: Colors.white, size: 22),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  'Ton radar émotionnel',
                                  style: GoogleFonts.playfairDisplay(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Image.asset(
                                'assets/univers_visuel/emotionsdujour.png',
                                width: 24, height: 24,
                                errorBuilder: (_, __, ___) => const Icon(Icons.emoji_emotions, color: Colors.white, size: 22),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Icône pensée positive
                      NavCartouche(
                        assetPath: 'assets/univers_visuel/pensee_positive.png',
                        fallbackIcon: Icons.lightbulb_outline,
                        tooltip: 'Pensée positive',
                        onTap: () {
                          Navigator.pop(context); // Fermer le dialog d'abord
                          _showPositiveThought();
                        },
                      ),
                      const SizedBox(width: 4),
                      // Icône home (menu principal)
                      NavCartouche(
                        assetPath: 'assets/univers_visuel/menu_principal.png',
                        fallbackIcon: Icons.grid_view_rounded,
                        tooltip: 'Menu principal',
                        onTap: () {
                          Navigator.pop(context); // Fermer le dialog
                          Navigator.pushNamedAndRemoveUntil(
                            context, '/menu', (route) => false,
                          );
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  EmotionWheelWidget(
                    emotions: emotionsMap,
                    date: DateTime.now(),
                    showShareButton: true,
                  ),
                  const SizedBox(height: 16),
                  // ── Bouton Retour vert → retour au mandala (écran précédent) ──
                  SizedBox(
                    width: double.infinity,
                    child: GestureDetector(
                      onTap: () {
                        Navigator.pop(context); // Fermer le dialog → retour au mandala
                      },
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
                            Text('Retour',
                                style: GoogleFonts.inter(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white)),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
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

      if (widget.preselectedSource != null) {
        final response =
            await AIService.instance.generateApproachSpecificResponse(
          approach: widget.preselectedSource!.key,
          reflectionText: text,
          reflectionType: widget.reflectionType ?? ReflectionType.thought,
          emotionalState: emotionalState,
          userProfile: null,
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
        final List<PerspectiveData> perspectives = [];

        for (final source in sources) {
          final response =
              await AIService.instance.generateApproachSpecificResponse(
            approach: source.key,
            reflectionText: text,
            reflectionType: widget.reflectionType ?? ReflectionType.thought,
            emotionalState: emotionalState,
            userProfile: null,
            intensiteEmotionnelle: avgIntensity,
          );
          final meta = AIService.instance.lastFigureMeta;
          perspectives.add(PerspectiveData(
            approachKey: source.key,
            approachName: source.name,
            responseText: response,
            figureName: meta?['nom'],
            figureReference: meta?['reference'],
          ));
        }

        if (mounted) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (_) => EclairagesCarouselScreen(
                thoughtText: text,
                perspectives: perspectives,
                emotionalState: emotionalState,
                intensiteEmotionnelle: avgIntensity,
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
              'Erreur lors de la génération. Réessaie.',
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
                              'Partage ce que\ntu ressens',
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
                      tooltip: 'Pensée positive',
                      onTap: _showPositiveThought,
                    ),
                    const SizedBox(width: 8),
                    NavCartouche(
                      assetPath: 'assets/univers_visuel/menu_principal.png',
                      fallbackIcon: Icons.grid_view_rounded,
                      tooltip: 'Menu principal',
                      onTap: () => Navigator.pushNamedAndRemoveUntil(
                        context, '/menu', (route) => false,
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
                          SizedBox(
                            width: wheelSize,
                            height: wheelSize,
                            child: InteractivePlutchikWheel(
                              selectedIndex: _selectedIndex,
                              confirmedIndices: _confirmedIndicesSet,
                              selectedNuances: _selectedNuances,
                              intensity: _intensity,
                              onEmotionTapped: _onEmotionTapped,
                              onNuanceTapped: (nuance) {
                                setState(() {
                                  if (_selectedNuances.contains(nuance)) {
                                    _selectedNuances.remove(nuance);
                                  } else {
                                    _selectedNuances.add(nuance);
                                  }
                                });
                              },
                              onIntensityChanged: (val) =>
                                  setState(() => _intensity = val),
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
            child: Center(
              child: Image.asset(
                emotion.iconPath,
                width: 22, height: 22,
                errorBuilder: (_, __, ___) =>
                    Icon(emotion.icon, color: emotion.color, size: 20),
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
                  '${isNeg ? "Tension" : "Appui"} · Intensité $_intensity/10',
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
                'Clique au centre\npour l\'intensité',
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
            'Émotions sélectionnées',
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
                  // Icône
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: confirmed.config.color.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Center(
                      child: Image.asset(
                        confirmed.config.iconPath,
                        width: 18, height: 18,
                        errorBuilder: (_, __, ___) => Icon(
                          confirmed.config.icon,
                          color: confirmed.config.color,
                          size: 16,
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
                              '${isNeg ? "Tension" : "Appui"} · ${confirmed.intensity}/10',
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

  // ═══════════════════════════════════════════════════════════════════════════
  // BOUTONS D'ACTION (contextuels selon le mode)
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildActionButtons() {
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
                  Text('Retour',
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
                        ? 'Sauvegarder'
                        : 'Regarde\nautrement',
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
                  Icon(
                    widget.entryMode == EmotionWheelEntryMode.partage
                        ? Icons.save_rounded
                        : Icons.auto_awesome,
                    size: 18,
                    color: _hasEmotions
                        ? Colors.white
                        : Colors.white.withValues(alpha: 0.4),
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
