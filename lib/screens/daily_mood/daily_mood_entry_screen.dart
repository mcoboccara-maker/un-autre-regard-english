// lib/screens/daily_mood/daily_mood_entry_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/mood_entry.dart';
import '../../services/emotional_tracking_service.dart';
import '../../config/emotion_config.dart';
import '../../widgets/emotion_wheel_widget.dart';
import '../../widgets/app_scaffold.dart';

class DailyMoodEntryScreen extends StatefulWidget {
  const DailyMoodEntryScreen({super.key});

  @override
  State<DailyMoodEntryScreen> createState() => _DailyMoodEntryScreenState();
}

class _DailyMoodEntryScreenState extends State<DailyMoodEntryScreen> {
  final Map<String, Map<String, dynamic>> _selectedEmotions = {};
  final TextEditingController _noteController = TextEditingController();
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadTodayEntry();
  }

  Future<void> _loadTodayEntry() async {
    final todayEntry = await EmotionalTrackingService.instance.getTodayEntry();

    if (todayEntry != null) {
      setState(() {
        for (final entry in todayEntry.emotions.entries) {
          _selectedEmotions[entry.key] = {
            'intensity': entry.value.intensity,
            'nuances': entry.value.nuances,
          };
        }
        _noteController.text = todayEntry.note ?? '';
      });
    }

    setState(() => _isLoading = false);
  }

  Future<void> _saveEntry() async {
    // Filtrer les émotions avec intensité > 0 uniquement
    final validEmotions = Map<String, Map<String, dynamic>>.from(_selectedEmotions)
      ..removeWhere((key, value) => (value['intensity'] as int) == 0);

    if (validEmotions.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Select at least one emotion with an intensity',
            style: GoogleFonts.poppins(),
          ),
        ),
      );
      return;
    }

    // Convertir les émotions sélectionnées en EmotionDetail
    final emotionsDetails = <String, EmotionDetail>{};
    for (final entry in validEmotions.entries) {
      emotionsDetails[entry.key] = EmotionDetail(
        intensity: entry.value['intensity'] as int,
        nuances: List<String>.from(entry.value['nuances'] as List),
      );
    }

    final entry = MoodEntry.forToday(
      emotionsDetails,
      note: _noteController.text.isNotEmpty ? _noteController.text : null,
    );

    await EmotionalTrackingService.instance.saveMoodEntry(entry);

    if (mounted) {
      // Afficher la roue émotionnelle
      await _showEmotionWheelDialog(entry);
    }
  }

  Future<void> _showEmotionWheelDialog(MoodEntry entry) async {
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(16),
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(20),
          ),
          padding: const EdgeInsets.all(24),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header de succès
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.green[50],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.green[200]!),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.check_circle, color: Colors.green[600], size: 32),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Emotions saved!',
                          style: GoogleFonts.poppins(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.green[800],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Roue émotionnelle RADAR
                EmotionWheelWidget(
                  emotions: entry.emotions,
                  date: entry.date,
                  showShareButton: true,
                ),

                const SizedBox(height: 24),

                // Bouton fermer
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context); // Fermer le dialog
                    Navigator.pop(context); // Retourner au menu principal
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey[600],
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    'Close',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
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

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return AppScaffold(
      title: '',  // MODIFIÉ: Pas de titre texte
      showTitle: false,  // MODIFIÉ: Désactiver le titre texte
      headerIconPath: 'assets/univers_visuel/penseejour.png',  // NOUVEAU: Icône centrée
      showMenuButton: true,
      showPositiveButton: true,
      showBackButton: true,
      bottomAction: _buildSaveButton(),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDateHeader(),
            const SizedBox(height: 24),
            _buildEmotionSelector(),
            const SizedBox(height: 24),
            _buildNoteField(),
          ],
        ),
      ),
    );
  }

  Widget _buildDateHeader() {
    final now = DateTime.now();
    final dateStr = '${_getDayName(now.weekday)} ${now.day} ${_getMonthName(now.month)}';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF6B9FBF), Color(0xFF87B5D0)],  // Bleu pastel cohérent
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          // Icône calendrier personnalisée
          Image.asset(
            'assets/univers_visuel/calendrier.png',
            width: 40,
            height: 40,
            errorBuilder: (_, __, ___) => Icon(Icons.calendar_today, color: Colors.white, size: 32),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                dateStr,
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                'Your mood today',
                style: GoogleFonts.poppins(
                  color: Colors.white70,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmotionSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Select your emotions',
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'Choose several emotions, adjust their intensity and specify the nuances',
          style: GoogleFonts.poppins(
            fontSize: 14,
            color: Colors.grey[600],
          ),
        ),
        const SizedBox(height: 16),

        // Liste des émotions négatives
        ...EmotionCategories.negativeEmotions.map((emotion) {
          final isSelected = _selectedEmotions.containsKey(emotion.key);
          final data = _selectedEmotions[emotion.key];
          final intensity = data?['intensity'] ?? 50;
          final nuances = List<String>.from(data?['nuances'] ?? []);

          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _buildEmotionCard(emotion, isSelected, intensity, nuances),
          );
        }),

        const SizedBox(height: 24),

        // Liste des émotions positives
        ...EmotionCategories.positiveEmotions.map((emotion) {
          final isSelected = _selectedEmotions.containsKey(emotion.key);
          final data = _selectedEmotions[emotion.key];
          final intensity = data?['intensity'] ?? 50;
          final nuances = List<String>.from(data?['nuances'] ?? []);

          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _buildEmotionCard(emotion, isSelected, intensity, nuances),
          );
        }),
      ],
    );
  }

  Widget _buildEmotionCard(
    EmotionConfig emotion,
    bool isSelected,
    int intensity,
    List<String> selectedNuances,
  ) {
    // Convertir l'intensité (0-100) en valeur 1-10
    final displayLevel = (intensity / 10).round().clamp(0, 10);

    return Column(
      children: [
        // Carte principale
        InkWell(
          onTap: () {
            setState(() {
              if (isSelected) {
                _selectedEmotions.remove(emotion.key);
              } else {
                _selectedEmotions[emotion.key] = {
                  'intensity': 0,
                  'nuances': <String>[],
                };
              }
            });
          },
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isSelected ? emotion.color.withOpacity(0.1) : Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected ? emotion.color : Colors.grey[300]!,
                width: isSelected ? 2 : 1,
              ),
            ),
            child: Row(
              children: [
                // Icône PNG de l'émotion
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: emotion.color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: emotion.iconPath != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.asset(
                            emotion.iconPath!,
                            width: 48,
                            height: 48,
                            fit: BoxFit.contain,
                            errorBuilder: (context, error, stackTrace) {
                              return Icon(emotion.icon, color: emotion.color, size: 28);
                            },
                          ),
                        )
                      : Icon(emotion.icon, color: emotion.color, size: 28),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    emotion.name,
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                      color: isSelected ? emotion.color : Colors.black87,
                    ),
                  ),
                ),
                if (isSelected)
                  Icon(Icons.check_circle, color: emotion.color, size: 24),
              ],
            ),
          ),
        ),

        // Section intensité avec boutons 1-10 (si sélectionné)
        if (isSelected) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: emotion.color.withOpacity(0.05),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // En-tête avec label et valeur
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Intensity:',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      '$displayLevel/10',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: emotion.color,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // ═══════════════════════════════════════════════════════════
                // MODIFIÉ: Boutons 1-10 au lieu du slider
                // ═══════════════════════════════════════════════════════════
                _buildIntensityButtons(emotion, intensity),

                const SizedBox(height: 12),

                // Bouton pour sélectionner les nuances
                OutlinedButton.icon(
                  onPressed: () => _showNuancesDialog(emotion, selectedNuances),
                  icon: Icon(Icons.tune, size: 16, color: emotion.color),
                  label: Text(
                    selectedNuances.isEmpty
                        ? 'Specify nuances'
                        : '${selectedNuances.length} nuance(s) selected',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: emotion.color,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: emotion.color),
                  ),
                ),

                // Afficher les nuances sélectionnées
                if (selectedNuances.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: selectedNuances.map((nuance) {
                      return Chip(
                        label: Text(
                          nuance,
                          style: GoogleFonts.poppins(fontSize: 11),
                        ),
                        backgroundColor: emotion.color.withOpacity(0.2),
                        deleteIcon: const Icon(Icons.close, size: 16),
                        onDeleted: () {
                          setState(() {
                            selectedNuances.remove(nuance);
                          });
                        },
                      );
                    }).toList(),
                  ),
                ],
              ],
            ),
          ),
        ],
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // SLIDER pour l'intensité avec couleurs VERT/BLEU des icônes
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildIntensityButtons(EmotionConfig emotion, int intensity) {
    // Convertir l'intensité (0-100) en niveau (0-10)
    final currentLevel = (intensity / 10).round().clamp(0, 10);

    // Couleurs des icônes
    const vertMenthe = Color(0xFF9FD5A1);  // Vert des icônes emotion
    const bleuPetrole = Color(0xFF2E7D8A); // Bleu des icônes evaluation

    return Column(
      children: [
        // Icône emotion qui change selon la valeur sélectionnée
        Image.asset(
          'assets/univers_visuel/evaluation/emotion$currentLevel.png',
          width: 44,
          height: 44,
          errorBuilder: (_, __, ___) => Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: vertMenthe.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                '$currentLevel',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: bleuPetrole,
                ),
              ),
            ),
          ),
        ),

        const SizedBox(height: 8),

        // SLIDER avec couleurs VERT (actif) / BLEU (inactif)
        Row(
          children: [
            Text(
              '0',
              style: GoogleFonts.inter(
                fontSize: 11,
                color: const Color(0xFF94A3B8),
                fontWeight: FontWeight.w500,
              ),
            ),
            Expanded(
              child: SliderTheme(
                data: SliderThemeData(
                  activeTrackColor: vertMenthe,
                  inactiveTrackColor: bleuPetrole.withOpacity(0.3),
                  thumbColor: vertMenthe,
                  overlayColor: vertMenthe.withOpacity(0.1),
                  trackHeight: 6,
                  thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 10),
                  overlayShape: const RoundSliderOverlayShape(overlayRadius: 18),
                ),
                child: Slider(
                  value: currentLevel.toDouble(),
                  min: 0,
                  max: 10,
                  divisions: 10,
                  onChanged: (value) {
                    HapticFeedback.selectionClick();
                    setState(() {
                      if (value.round() == 0) {
                        _selectedEmotions.remove(emotion.key);
                      } else {
                        _selectedEmotions[emotion.key]!['intensity'] = value.round() * 10;
                      }
                    });
                  },
                ),
              ),
            ),
            Text(
              '10',
              style: GoogleFonts.inter(
                fontSize: 11,
                color: const Color(0xFF94A3B8),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),

        // Raccourcis rapides 0, 5, 10
        const SizedBox(height: 6),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [0, 5, 10].map((quickValue) {
            final isSelected = currentLevel == quickValue;
            return GestureDetector(
              onTap: () {
                HapticFeedback.selectionClick();
                setState(() {
                  if (quickValue == 0) {
                    _selectedEmotions.remove(emotion.key);
                  } else {
                    _selectedEmotions[emotion.key]!['intensity'] = quickValue * 10;
                  }
                });
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                decoration: BoxDecoration(
                  color: isSelected ? vertMenthe : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isSelected ? vertMenthe : const Color(0xFFE2E8F0),
                  ),
                ),
                child: Text(
                  '$quickValue',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isSelected ? Colors.white : const Color(0xFF64748B),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Future<void> _showNuancesDialog(EmotionConfig emotion, List<String> selectedNuances) async {
    final result = await showDialog<List<String>>(
      context: context,
      builder: (context) => _NuancesDialog(
        emotion: emotion,
        initialSelected: selectedNuances,
      ),
    );

    if (result != null) {
      setState(() {
        _selectedEmotions[emotion.key]!['nuances'] = result;
      });
    }
  }

  Widget _buildNoteField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Optional note',
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _noteController,
          maxLines: 4,
          decoration: InputDecoration(
            hintText: 'Anything special today?',
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSaveButton() {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        onPressed: _saveEntry,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF10B981),  // Vert clair
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.only(bottom: 4),  // Remonter le texte
        ),
        child: Text(
          'Save and see my emotional wheel',
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  String _getDayName(int weekday) {
    const days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    return days[weekday - 1];
  }

  String _getMonthName(int month) {
    const months = ['January', 'February', 'March', 'April', 'May', 'June',
                   'July', 'August', 'September', 'October', 'November', 'December'];
    return months[month - 1];
  }
}

// Dialog pour sélectionner les nuances
class _NuancesDialog extends StatefulWidget {
  final EmotionConfig emotion;
  final List<String> initialSelected;

  const _NuancesDialog({
    required this.emotion,
    required this.initialSelected,
  });

  @override
  State<_NuancesDialog> createState() => _NuancesDialogState();
}

class _NuancesDialogState extends State<_NuancesDialog> {
  late List<String> _selected;

  @override
  void initState() {
    super.initState();
    _selected = List.from(widget.initialSelected);
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        padding: const EdgeInsets.all(24),
        constraints: const BoxConstraints(maxHeight: 600),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(widget.emotion.icon, color: widget.emotion.color, size: 28),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Nuances of ${widget.emotion.name}',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: widget.emotion.color,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Select the nuances that best match',
              style: GoogleFonts.poppins(
                fontSize: 13,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: SingleChildScrollView(
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: widget.emotion.nuances.map((nuance) {
                    final isSelected = _selected.contains(nuance);
                    return FilterChip(
                      label: Text(nuance),
                      selected: isSelected,
                      onSelected: (selected) {
                        setState(() {
                          if (selected) {
                            _selected.add(nuance);
                          } else {
                            _selected.remove(nuance);
                          }
                        });
                      },
                      selectedColor: widget.emotion.color.withOpacity(0.3),
                      checkmarkColor: widget.emotion.color,
                    );
                  }).toList(),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text('Cancel'),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context, _selected),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: widget.emotion.color,
                  ),
                  child: Text('Confirm (${_selected.length})'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
