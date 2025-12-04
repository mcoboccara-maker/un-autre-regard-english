// lib/screens/orientation/orientation_validation_screen.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../config/orientation_config.dart';
import '../../services/complete_auth_service.dart';
import '../../models/user_profile.dart';

class OrientationValidationScreen extends StatefulWidget {
  final Map<String, int> scores;

  const OrientationValidationScreen({
    super.key,
    required this.scores,
  });

  @override
  State<OrientationValidationScreen> createState() => _OrientationValidationScreenState();
}

class _OrientationValidationScreenState extends State<OrientationValidationScreen> {
  // Sources suggérées (calculées)
  late List<SourceInfo> _suggestedPhilosophes;
  late List<SourceInfo> _suggestedCourantsPhilo;
  late List<SourceInfo> _suggestedLitteraires;
  late List<SourceInfo> _suggestedPsychologiques;

  // Sources sélectionnées par l'utilisateur (modifiables)
  late Set<String> _selectedPhilosophes;
  late Set<String> _selectedCourantsPhilo;
  late Set<String> _selectedLitteraires;
  late Set<String> _selectedPsychologiques;

  bool _isSaving = false;
  bool _saved = false;

  @override
  void initState() {
    super.initState();
    _calculateSuggestions();
  }

  void _calculateSuggestions() {
    // Trier les scores
    final sortedScores = widget.scores.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    // Séparer par catégorie
    _suggestedPhilosophes = _getTopByCategory(sortedScores, 'philosophe', 5);
    _suggestedCourantsPhilo = _getTopByCategory(sortedScores, 'philosophique', 4);
    _suggestedLitteraires = _getTopByCategory(sortedScores, 'litteraire', 4);
    _suggestedPsychologiques = _getTopByCategory(sortedScores, 'psychologique', 4);

    // Par défaut, toutes les suggestions sont sélectionnées
    _selectedPhilosophes = _suggestedPhilosophes.map((s) => s.id).toSet();
    _selectedCourantsPhilo = _suggestedCourantsPhilo.map((s) => s.id).toSet();
    _selectedLitteraires = _suggestedLitteraires.map((s) => s.id).toSet();
    _selectedPsychologiques = _suggestedPsychologiques.map((s) => s.id).toSet();
  }

  List<SourceInfo> _getTopByCategory(
    List<MapEntry<String, int>> sortedScores,
    String category,
    int count,
  ) {
    return sortedScores
        .where((entry) {
          final source = OrientationConfig.allSources[entry.key];
          return source != null && source.category == category;
        })
        .take(count)
        .map((entry) => OrientationConfig.allSources[entry.key]!)
        .toList();
  }

  Future<void> _saveToProfile() async {
    setState(() => _isSaving = true);

    try {
      // Récupérer le profil actuel
      final profileData = await CompleteAuthService.instance.getProfile();
      
      // Construire le profil mis à jour
      final currentEmail = await CompleteAuthService.instance.getCurrentUser();
      
      final updates = {
        ...?profileData,
        'email': currentEmail,
        'philosophesSelectionnes': _selectedPhilosophes.toList(),
        'courantsPhilosophiques': _selectedCourantsPhilo.toList(),
        'courantsLitteraires': _selectedLitteraires.toList(),
        'approchesPsychologiques': _selectedPsychologiques.toList(),
        'orientationCompleted': true,
        'orientationDate': DateTime.now().toIso8601String(),
        'lastUpdated': DateTime.now().toIso8601String(),
      };

      await CompleteAuthService.instance.saveProfile(updates);

      setState(() {
        _isSaving = false;
        _saved = true;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Sources d\'inspiration enregistrées !',
                    style: GoogleFonts.poppins(),
                  ),
                ),
              ],
            ),
            backgroundColor: const Color(0xFF10B981),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );

        // Retour au menu après 1.5 secondes
        Future.delayed(const Duration(milliseconds: 1500), () {
          if (mounted) {
            Navigator.of(context).pushNamedAndRemoveUntil(
              '/home',
              (route) => false,
            );
          }
        });
      }
    } catch (e) {
      setState(() => _isSaving = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  int get _totalSelected =>
      _selectedPhilosophes.length +
      _selectedCourantsPhilo.length +
      _selectedLitteraires.length +
      _selectedPsychologiques.length;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFF8FBFE),
              Color(0xFFF5F9FD),
              Color(0xFFF8FBFE),
            ],
            stops: [0.0, 0.5, 1.0],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header
              _buildHeader(),

              // Message explicatif
              _buildExplanation(),

              // Liste des sources
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    children: [
                      _buildCategorySection(
                        icon: '👤',
                        title: 'Philosophes suggérés',
                        sources: _suggestedPhilosophes,
                        selectedIds: _selectedPhilosophes,
                        onToggle: (id) => _toggleSelection(_selectedPhilosophes, id),
                        color: const Color(0xFF6366F1),
                      ),
                      
                      _buildCategorySection(
                        icon: '🏛️',
                        title: 'Courants philosophiques',
                        sources: _suggestedCourantsPhilo,
                        selectedIds: _selectedCourantsPhilo,
                        onToggle: (id) => _toggleSelection(_selectedCourantsPhilo, id),
                        color: const Color(0xFF8B5CF6),
                      ),
                      
                      _buildCategorySection(
                        icon: '📚',
                        title: 'Courants littéraires',
                        sources: _suggestedLitteraires,
                        selectedIds: _selectedLitteraires,
                        onToggle: (id) => _toggleSelection(_selectedLitteraires, id),
                        color: const Color(0xFFEC4899),
                      ),
                      
                      _buildCategorySection(
                        icon: '🧠',
                        title: 'Approches psychologiques',
                        sources: _suggestedPsychologiques,
                        selectedIds: _selectedPsychologiques,
                        onToggle: (id) => _toggleSelection(_selectedPsychologiques, id),
                        color: const Color(0xFF10B981),
                      ),

                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),

              // Boutons d'action
              _buildActionButtons(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF6366F1).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.arrow_back,
                color: Color(0xFF6366F1),
                size: 20,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              'Valide tes sources',
              style: GoogleFonts.poppins(
                color: const Color(0xFF1E293B),
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFF6366F1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '$_totalSelected',
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 300.ms);
  }

  Widget _buildExplanation() {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF6366F1).withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFF6366F1).withOpacity(0.1),
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.info_outline,
            color: Color(0xFF6366F1),
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Voici les sources qui correspondent à tes choix. Tu peux les modifier avant d\'enregistrer.',
              style: GoogleFonts.poppins(
                color: const Color(0xFF64748B),
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 100.ms, duration: 300.ms);
  }

  Widget _buildCategorySection({
    required String icon,
    required String title,
    required List<SourceInfo> sources,
    required Set<String> selectedIds,
    required Function(String) onToggle,
    required Color color,
  }) {
    if (sources.isEmpty) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(icon, style: const TextStyle(fontSize: 18)),
              const SizedBox(width: 8),
              Text(
                title,
                style: GoogleFonts.poppins(
                  color: const Color(0xFF1E293B),
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              Text(
                '${selectedIds.length}/${sources.length}',
                style: GoogleFonts.poppins(
                  color: const Color(0xFF64748B),
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: sources.map((source) {
              final isSelected = selectedIds.contains(source.id);
              final score = widget.scores[source.id] ?? 0;
              
              return GestureDetector(
                onTap: () => onToggle(source.id),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: isSelected ? color.withOpacity(0.15) : Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected ? color : const Color(0xFFE2E8F0),
                      width: isSelected ? 2 : 1,
                    ),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: color.withOpacity(0.2),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ]
                        : null,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Checkbox
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: 20,
                        height: 20,
                        decoration: BoxDecoration(
                          color: isSelected ? color : Colors.transparent,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: isSelected ? color : const Color(0xFFCBD5E1),
                            width: 2,
                          ),
                        ),
                        child: isSelected
                            ? const Icon(
                                Icons.check,
                                size: 14,
                                color: Colors.white,
                              )
                            : null,
                      ),
                      const SizedBox(width: 10),
                      // Nom
                      Text(
                        source.name,
                        style: GoogleFonts.poppins(
                          color: isSelected
                              ? const Color(0xFF1E293B)
                              : const Color(0xFF64748B),
                          fontSize: 13,
                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Score
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: isSelected ? color : const Color(0xFFE2E8F0),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '$score',
                          style: GoogleFonts.poppins(
                            color: isSelected ? Colors.white : const Color(0xFF64748B),
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 200.ms, duration: 300.ms);
  }

  void _toggleSelection(Set<String> set, String id) {
    setState(() {
      if (set.contains(id)) {
        set.remove(id);
      } else {
        set.add(id);
      }
    });
  }

  Widget _buildActionButtons() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Bouton principal
          ElevatedButton.icon(
            onPressed: _totalSelected == 0
                ? null
                : (_saved ? null : (_isSaving ? null : _saveToProfile)),
            icon: _isSaving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : Icon(_saved ? Icons.check : Icons.save),
            label: Text(
              _saved
                  ? 'Enregistré !'
                  : _totalSelected == 0
                      ? 'Sélectionne au moins une source'
                      : 'Enregistrer $_totalSelected sources',
              style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: _saved
                  ? const Color(0xFF10B981)
                  : const Color(0xFF6366F1),
              foregroundColor: Colors.white,
              disabledBackgroundColor: const Color(0xFFE2E8F0),
              disabledForegroundColor: const Color(0xFF94A3B8),
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              minimumSize: const Size(double.infinity, 56),
            ),
          ),

          const SizedBox(height: 12),

          // Bouton secondaire
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'Revenir aux résultats',
              style: GoogleFonts.poppins(
                color: const Color(0xFF64748B),
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 400.ms, duration: 300.ms);
  }
}
