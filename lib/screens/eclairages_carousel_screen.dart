// lib/screens/eclairages_carousel_screen.dart
// CDC §3.6 - Eclairages en mode FACE avec swipe save/reject

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../config/approach_config.dart';
import '../models/emotional_state.dart';
import '../models/saved_eclairage.dart';
import '../services/ai_service.dart';
import '../services/persistent_storage_service.dart';
import '../services/tts_service.dart';
import '../widgets/carousel_3d/card_carousel_3d.dart';
import '../widgets/nav_cartouche.dart';
import 'perspective_room_screen.dart';

class EclairagesCarouselScreen extends StatefulWidget {
  final String thoughtText;
  final List<PerspectiveData> perspectives;
  /// Mode lecture seule (depuis home_carousel, non connecté)
  /// - Pas de swipe Passer/Garder
  /// - Pas de questions d'approfondissement
  /// - Icône connexion au lieu des 3 NavCartouche
  final bool readOnly;
  /// État émotionnel de l'utilisateur (transmis depuis le mandala)
  final EmotionalState? emotionalState;
  /// Intensité émotionnelle globale (1-10)
  final int? intensiteEmotionnelle;

  const EclairagesCarouselScreen({
    super.key,
    required this.thoughtText,
    required this.perspectives,
    this.readOnly = false,
    this.emotionalState,
    this.intensiteEmotionnelle,
  });

  @override
  State<EclairagesCarouselScreen> createState() =>
      _EclairagesCarouselScreenState();
}

class _EclairagesCarouselScreenState extends State<EclairagesCarouselScreen> {
  late List<PerspectiveData> _perspectives;
  final Map<int, bool> _savedMap = {}; // true=saved, false=rejected
  bool _showFinalPage = false;
  int _currentIndex = 0;

  /// Controllers pour les réponses utilisateur aux questions (1 par éclairage)
  final Map<int, TextEditingController> _responseControllers = {};

  /// Textes d'approfondissement générés par l'IA (1 par éclairage)
  final Map<int, String> _deepeningTexts = {};
  /// État de chargement de l'approfondissement (1 par éclairage)
  final Map<int, DeepeningState> _deepeningStates = {};

  @override
  void initState() {
    super.initState();
    _perspectives = List.from(widget.perspectives);
    // Initialiser les controllers pour chaque éclairage
    for (int i = 0; i < _perspectives.length; i++) {
      _responseControllers[i] = TextEditingController();
    }
  }

  @override
  void dispose() {
    TtsService.instance.stop();
    // Nettoyer les controllers
    for (final controller in _responseControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  ApproachConfig? _getApproachConfig(String key) {
    return ApproachCategories.findByKey(key);
  }

  List<CarouselCardData> _buildCards() {
    return _perspectives.asMap().entries.map((entry) {
      final i = entry.key;
      final p = entry.value;
      final config = _getApproachConfig(p.approachKey);
      final color = config?.color ?? const Color(0xFF4A90A4);
      final isSaved = _savedMap[i];

      return CarouselCardData(
        id: p.approachKey,
        backgroundColor: color,
        label: p.approachName,
        child: _buildEclairageCard(p, config, color, isSaved),
      );
    }).toList();
  }

  /// Génère un fond clair lumineux à partir de la couleur de la source
  Color _lightBg(Color color) {
    // Mélange la couleur source avec du blanc pour un fond pastel lumineux
    final hsl = HSLColor.fromColor(color);
    return hsl.withLightness(0.94).withSaturation(hsl.saturation * 0.4).toColor();
  }

  /// Couleur de texte sombre adaptée à la source
  Color _darkText(Color color) {
    final hsl = HSLColor.fromColor(color);
    return hsl.withLightness(0.15).withSaturation(hsl.saturation * 0.7).toColor();
  }

  Widget _buildEclairageCard(
    PerspectiveData perspective,
    ApproachConfig? config,
    Color color,
    bool? savedState,
  ) {
    final bgLight = _lightBg(color);
    final bgLight2 = HSLColor.fromColor(color)
        .withLightness(0.88)
        .withSaturation(HSLColor.fromColor(color).saturation * 0.3)
        .toColor();
    final textDark = _darkText(color);
    final textSecondary = textDark.withValues(alpha: 0.6);

    return Stack(
      children: [
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [bgLight, bgLight2],
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Source header
              Row(
                children: [
                  Icon(config?.icon ?? Icons.auto_awesome,
                      color: color, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      perspective.approachName,
                      style: GoogleFonts.playfairDisplay(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: textDark,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              if (config != null)
                Text(
                  config.credo,
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    color: textSecondary,
                    fontStyle: FontStyle.italic,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              Divider(height: 16, color: color.withValues(alpha: 0.2)),
              // Response text (scrollable)
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Text(
                    perspective.responseText,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: const Color(0xFF1A2A3A),
                      height: 1.7,
                    ),
                  ),
                ),
              ),
              // Bas de carte : hints contextuels
              if (widget.readOnly) ...[
                // Mode lecture : bouton écouter + hint approfondissement
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    GestureDetector(
                      onTap: () {
                        TtsService.instance.speak(
                          perspective.responseText,
                          approachKey: perspective.approachKey,
                        );
                      },
                      child: Row(
                        children: [
                          Icon(Icons.volume_up, size: 16, color: color),
                          const SizedBox(width: 4),
                          Text('Écouter',
                              style: GoogleFonts.inter(
                                  fontSize: 10, color: color)),
                        ],
                      ),
                    ),
                    Text('Tap pour approfondir',
                        style: GoogleFonts.inter(
                            fontSize: 10,
                            color: textSecondary,
                            fontStyle: FontStyle.italic)),
                  ],
                ),
              ] else ...[
                // Mode complet : swipe hints
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.arrow_back,
                            size: 14, color: Colors.red[700]),
                        const SizedBox(width: 4),
                        Text('Passer',
                            style: GoogleFonts.inter(
                                fontSize: 10, color: Colors.red[700])),
                      ],
                    ),
                    Text('Tap pour approfondir',
                        style: GoogleFonts.inter(
                            fontSize: 10,
                            color: textSecondary,
                            fontStyle: FontStyle.italic)),
                    Row(
                      children: [
                        Text('Garder',
                            style: GoogleFonts.inter(
                                fontSize: 10, color: Colors.green[700])),
                        const SizedBox(width: 4),
                        Icon(Icons.arrow_forward,
                            size: 14, color: Colors.green[700]),
                      ],
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
        // Save/reject overlay (masqué en mode lecture seule)
        if (savedState != null && !widget.readOnly)
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                color: savedState
                    ? Colors.green.withValues(alpha: 0.3)
                    : Colors.red.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Center(
                child: Icon(
                  savedState ? Icons.bookmark : Icons.close,
                  color: savedState ? Colors.green : Colors.red,
                  size: 64,
                ),
              ),
            ),
          ),
      ],
    );
  }

  void _onCardSwipe(int index, CarouselCardData card, SwipeDirection direction) {
    final isSaved = direction == SwipeDirection.right;
    setState(() {
      _savedMap[index] = isSaved;
    });

    // Sauvegarder si swipe à droite (Garder)
    if (isSaved) {
      _saveEclairageComplet(index);
    }

    // Check if all cards processed
    if (_savedMap.length == _perspectives.length) {
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) {
          setState(() {
            _showFinalPage = true;
          });
        }
      });
    }
  }

  void _onCardTap(int index, CarouselCardData card) {
    final perspective = _perspectives[index];
    _showDeepeningSheet(perspective, index);
  }

  void _onCardChanged(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  void _showDeepeningSheet(PerspectiveData perspective, int index) {
    final config = _getApproachConfig(perspective.approachKey);
    final color = config?.color ?? const Color(0xFF4A90A4);
    final sheetBg = _lightBg(color);
    final sheetBg2 = HSLColor.fromColor(color)
        .withLightness(0.90)
        .withSaturation(HSLColor.fromColor(color).saturation * 0.35)
        .toColor();
    final textDark = _darkText(color);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        // Déclencher la génération si pas encore fait
        if (_deepeningStates[index] != DeepeningState.loading &&
            _deepeningStates[index] != DeepeningState.ready) {
          _deepeningStates[index] = DeepeningState.loading;
          final figureName = perspective.figureName ?? 'Figure non identifiée';
          AIService.instance.generateDeepening(
            penseeOriginale: widget.thoughtText,
            reponseCourte: perspective.responseText,
            sourceNom: perspective.approachName,
            figureNom: figureName,
          ).then((response) {
            if (mounted) {
              setState(() {
                _deepeningTexts[index] = response;
                _deepeningStates[index] = DeepeningState.ready;
              });
              // Rebuild le bottom sheet via Navigator
              if (Navigator.of(ctx).canPop()) {
                Navigator.of(ctx).pop();
                _showDeepeningSheet(perspective, index);
              }
            }
          }).catchError((e) {
            print('❌ Erreur approfondissement: $e');
            if (mounted) {
              setState(() {
                _deepeningStates[index] = DeepeningState.failed;
              });
              if (Navigator.of(ctx).canPop()) {
                Navigator.of(ctx).pop();
                _showDeepeningSheet(perspective, index);
              }
            }
          });
        }

        return DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.4,
        maxChildSize: 0.9,
        builder: (_, scrollController) => Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [sheetBg, sheetBg2],
            ),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: ListView(
            controller: scrollController,
            padding: const EdgeInsets.all(24),
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Icon(config?.icon ?? Icons.auto_awesome,
                      color: color, size: 24),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Approfondissement',
                      style: GoogleFonts.playfairDisplay(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: textDark,
                      ),
                    ),
                  ),
                  // Bouton lecture vocale (lit l'approfondissement si disponible)
                  IconButton(
                    onPressed: () {
                      final textToSpeak = _deepeningTexts[index] ?? perspective.responseText;
                      TtsService.instance.speak(
                        textToSpeak,
                        approachKey: perspective.approachKey,
                      );
                    },
                    icon: Icon(Icons.volume_up, color: color, size: 22),
                    tooltip: 'Écouter',
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Texte approfondi ou éclairage original avec loader
              Builder(builder: (_) {
                final state = _deepeningStates[index];
                final deepText = _deepeningTexts[index];

                if (state == DeepeningState.ready && deepText != null) {
                  // Approfondissement prêt → afficher
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        deepText,
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          color: const Color(0xFF1A2A3A),
                          height: 1.7,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: color.withValues(alpha: 0.2)),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.short_text, color: color, size: 16),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Éclairage initial',
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: color,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        perspective.responseText,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: textDark.withValues(alpha: 0.45),
                          height: 1.5,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  );
                } else if (state == DeepeningState.failed) {
                  // Échec → afficher l'éclairage original + message d'erreur
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.red.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.red.withValues(alpha: 0.2)),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.error_outline, color: Colors.red[700], size: 18),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Approfondissement indisponible. Voici l\'éclairage initial.',
                                style: GoogleFonts.inter(fontSize: 12, color: Colors.red[800]),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        perspective.responseText,
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          color: const Color(0xFF1A2A3A),
                          height: 1.7,
                        ),
                      ),
                    ],
                  );
                } else {
                  // En cours de chargement → éclairage original + loader
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        perspective.responseText,
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          color: const Color(0xFF1A2A3A),
                          height: 1.7,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: color.withValues(alpha: 0.2)),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(
                              width: 18, height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: color,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              'Approfondissement en cours...',
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                color: color,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                }
              }),

              // Zone de saisie pour les réflexions de l'utilisateur
              if (!widget.readOnly) ...[
                const SizedBox(height: 24),
                Text(
                  'Tes réflexions',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: textDark,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.7),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: color.withValues(alpha: 0.25)),
                  ),
                  child: TextField(
                    controller: _responseControllers[index],
                    maxLines: 5,
                    minLines: 3,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: const Color(0xFF1A2A3A),
                      height: 1.5,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Ce que cet éclairage t\'inspire, tes réponses aux questions...',
                      hintStyle: GoogleFonts.inter(
                        fontSize: 13,
                        color: const Color(0xFF1A2A3A).withValues(alpha: 0.35),
                      ),
                      filled: true,
                      fillColor: Colors.transparent,
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.all(14),
                    ),
                  ),
                ),
              ],

              const SizedBox(height: 20),

              // Action buttons : Passer/Garder en mode complet, Fermer en readOnly
              if (widget.readOnly)
                Center(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      TtsService.instance.stop();
                      Navigator.pop(ctx);
                    },
                    icon: const Icon(Icons.close, size: 18),
                    label: const Text('Fermer'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2E8B7B),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 32),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                )
              else
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.pop(ctx);
                          setState(() {
                            _savedMap[index] = false;
                          });
                          _checkAllProcessed();
                        },
                        icon: const Icon(Icons.close, size: 18),
                        label: const Text('Passer'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red[700],
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.pop(ctx);
                          setState(() {
                            _savedMap[index] = true;
                          });
                          _saveEclairageComplet(index);
                          _checkAllProcessed();
                        },
                        icon: const Icon(Icons.bookmark, size: 18),
                        label: const Text('Garder'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green[700],
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      );
    },
    );
  }

  /// Extraire le nom de la figure depuis FIGURE_META dans le texte de l'éclairage
  String? _extractFigureName(String responseText) {
    final regex = RegExp(r'FIGURE_META\s*\{[^}]*nom\s*:\s*"?([^"\n,}]+)"?');
    final match = regex.firstMatch(responseText);
    return match?.group(1)?.trim();
  }

  /// Extraire la référence depuis FIGURE_META
  String? _extractFigureReference(String responseText) {
    final regex = RegExp(r'FIGURE_META\s*\{[^}]*reference\s*:\s*"?([^"\n,}]+)"?');
    final match = regex.firstMatch(responseText);
    return match?.group(1)?.trim();
  }

  /// Sauvegarder un éclairage complet (tout le contexte)
  Future<void> _saveEclairageComplet(int index) async {
    final perspective = _perspectives[index];
    final userResponse = _responseControllers[index]?.text.trim();

    final deepText = _deepeningTexts[index];

    final savedEclairage = SavedEclairage(
      eclairageText: perspective.responseText,
      deepeningText: (deepText != null && deepText.isNotEmpty) ? deepText : null,
      userResponse: (userResponse != null && userResponse.isNotEmpty) ? userResponse : null,
      thoughtText: widget.thoughtText,
      sourceKey: perspective.approachKey,
      sourceName: perspective.approachName,
      figureName: perspective.figureName ?? _extractFigureName(perspective.responseText),
      figureReference: perspective.figureReference ?? _extractFigureReference(perspective.responseText),
      emotionalState: widget.emotionalState?.toJson(),
      intensiteEmotionnelle: widget.intensiteEmotionnelle,
      savedAt: DateTime.now(),
    );

    try {
      await PersistentStorageService.instance.saveEclairage(savedEclairage.toJson());
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                Expanded(child: Text('${perspective.approachName} sauvegardé')),
              ],
            ),
            backgroundColor: const Color(0xFF10B981),
            duration: const Duration(seconds: 2),
          ),
        );
      }
      print('✅ Éclairage sauvegardé: ${perspective.approachName}');
    } catch (e) {
      print('❌ Erreur sauvegarde éclairage: $e');
    }
  }

  void _checkAllProcessed() {
    if (_savedMap.length == _perspectives.length) {
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) {
          setState(() {
            _showFinalPage = true;
          });
        }
      });
    }
  }

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

  @override
  Widget build(BuildContext context) {
    // Page finale uniquement en mode complet (connecté)
    if (_showFinalPage && !widget.readOnly) {
      return _buildFinalPage();
    }

    final cards = _buildCards();

    return Scaffold(
      body: Stack(
        children: [
          CardCarousel3D(
            cards: cards,
            mode: CarouselMode.face,
            angleSpacing: 35,
            cardHeight: 480,
            cardWidth: 300,
            // Swipe désactivé en mode lecture seule
            enableSwipeActions: !widget.readOnly,
            onCardSwipe: widget.readOnly ? null : _onCardSwipe,
            onCardTap: _onCardTap,
            onCardChanged: _onCardChanged,
          ),

          // Back button
          Positioned(
            top: MediaQuery.of(context).padding.top + 8,
            left: 8,
            child: IconButton(
              onPressed: () {
                TtsService.instance.stop();
                Navigator.of(context).pop();
              },
              icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
            ),
          ),

          // Haut-droite : icône connexion (readOnly) ou 3 NavCartouche (connecté)
          if (widget.readOnly)
            Positioned(
              top: MediaQuery.of(context).padding.top + 8,
              right: 12,
              child: IconButton(
                onPressed: () {
                  TtsService.instance.stop();
                  Navigator.pushNamed(context, '/login');
                },
                icon: Image.asset(
                  'assets/univers_visuel/connexion.png',
                  width: 28,
                  height: 28,
                  errorBuilder: (_, __, ___) => const Icon(
                    Icons.person_outline,
                    color: Colors.white,
                    size: 26,
                  ),
                ),
                tooltip: 'Connexion',
              ),
            )
          else
            Positioned(
              top: MediaQuery.of(context).padding.top + 8,
              right: 8,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  NavCartouche(
                    assetPath: 'assets/univers_visuel/menu_principal.png',
                    fallbackIcon: Icons.grid_view_rounded,
                    tooltip: 'Menu principal',
                    onTap: () => Navigator.pushNamedAndRemoveUntil(
                      context, '/menu', (route) => false,
                    ),
                  ),
                  const SizedBox(width: 8),
                  NavCartouche(
                    assetPath: 'assets/univers_visuel/pensee_positive.png',
                    fallbackIcon: Icons.lightbulb_outline,
                    tooltip: 'Pensée positive',
                    onTap: _showPositiveThought,
                  ),
                  const SizedBox(width: 8),
                  NavCartouche(
                    assetPath: 'assets/univers_visuel/profil.png',
                    fallbackIcon: Icons.person_rounded,
                    tooltip: 'Mon profil',
                    onTap: () => Navigator.pushNamed(context, '/profile'),
                  ),
                ],
              ),
            ),

          // Bouton retour écran précédent en bas — cartouche vert
          Positioned(
            bottom: MediaQuery.of(context).padding.bottom + 16,
            left: 0,
            right: 0,
            child: Center(
              child: GestureDetector(
                onTap: () {
                  TtsService.instance.stop();
                  Navigator.of(context).pop();
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2E8B7B),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF2E8B7B).withValues(alpha: 0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.arrow_back_rounded, size: 18, color: Colors.white),
                      const SizedBox(width: 8),
                      Text(
                        'Retour',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Title & progress
          Positioned(
            top: MediaQuery.of(context).padding.top + 12,
            left: 56,
            right: 56,
            child: Column(
              children: [
                Text(
                  'Eclairages',
                  style: GoogleFonts.playfairDisplay(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    shadows: [
                      Shadow(
                        color: Colors.black.withValues(alpha: 0.5),
                        blurRadius: 10,
                      ),
                    ],
                  ),
                  textAlign: TextAlign.center,
                ),
                // Compteur de progression uniquement en mode complet
                if (!widget.readOnly) ...[
                  const SizedBox(height: 4),
                  Text(
                    '${_savedMap.length}/${_perspectives.length} traités',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: Colors.white.withValues(alpha: 0.6),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFinalPage() {
    final savedCount = _savedMap.values.where((v) => v).length;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment.center,
            radius: 1.5,
            colors: [Color(0xFF102A43), Color(0xFF0B1C2D)],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.visibility,
                  color: Colors.white.withValues(alpha: 0.3),
                  size: 64,
                ),
                const SizedBox(height: 32),
                Text(
                  'Ton regard a-t-il bougé ?',
                  style: GoogleFonts.playfairDisplay(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  '$savedCount éclairage${savedCount > 1 ? 's' : ''} gardé${savedCount > 1 ? 's' : ''}',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: Colors.white.withValues(alpha: 0.6),
                  ),
                ),
                const SizedBox(height: 48),

                // 3 options
                _buildFinalOption(
                  icon: Icons.refresh,
                  label: 'Nouvelle réflexion',
                  subtitle: 'Recommencer avec une autre pensée',
                  onTap: () {
                    // Go back to home
                    Navigator.of(context)
                        .popUntil((route) => route.isFirst);
                  },
                ),
                const SizedBox(height: 12),
                _buildFinalOption(
                  icon: Icons.auto_awesome,
                  label: 'Autres éclairages',
                  subtitle: 'Explorer d\'autres perspectives',
                  onTap: () {
                    setState(() {
                      _savedMap.clear();
                      _showFinalPage = false;
                    });
                  },
                ),
                const SizedBox(height: 12),
                _buildFinalOption(
                  icon: Icons.home,
                  label: 'Retour à l\'accueil',
                  subtitle: 'Revenir au manège des sources',
                  onTap: () {
                    Navigator.of(context)
                        .popUntil((route) => route.isFirst);
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFinalOption({
    required IconData icon,
    required String label,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
        ),
        child: Row(
          children: [
            Icon(icon, color: Colors.white.withValues(alpha: 0.8), size: 24),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: Colors.white.withValues(alpha: 0.5),
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios,
                color: Colors.white.withValues(alpha: 0.3), size: 16),
          ],
        ),
      ),
    );
  }
}
