// lib/screens/orientation/orientation_result_screen.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:share_plus/share_plus.dart';
import '../../config/orientation_config.dart';
import '../../services/complete_auth_service.dart';
import 'orientation_validation_screen.dart';

class OrientationResultScreen extends StatefulWidget {
  final Map<String, int> scores;

  const OrientationResultScreen({
    super.key,
    required this.scores,
  });

  @override
  State<OrientationResultScreen> createState() => _OrientationResultScreenState();
}

class _OrientationResultScreenState extends State<OrientationResultScreen> {
  late List<MapEntry<String, int>> _sortedScores;
  late List<SourceInfo> _topPhilosophes;
  late List<SourceInfo> _topCourantsPhilo;
  late List<SourceInfo> _topLitteraires;
  late List<SourceInfo> _topPsychologiques;
  
  bool _isSaving = false;
  bool _saved = false;

  @override
  void initState() {
    super.initState();
    _calculateResults();
  }

  void _calculateResults() {
    // Trier tous les scores
    _sortedScores = widget.scores.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    // Séparer par catégorie
    _topPhilosophes = _getTopByCategory('philosophe', 3);
    _topCourantsPhilo = _getTopByCategory('philosophique', 2);
    _topLitteraires = _getTopByCategory('litteraire', 2);
    _topPsychologiques = _getTopByCategory('psychologique', 2);
  }

  List<SourceInfo> _getTopByCategory(String category, int count) {
    return _sortedScores
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
      final currentProfile = await CompleteAuthService.instance.getProfile() ?? {};

      // Ajouter les sources recommandées
      final updates = {
        ...currentProfile,
        'philosophesSelectionnes': _topPhilosophes.map((s) => s.id).toList(),
        'courantsPhilosophiques': _topCourantsPhilo.map((s) => s.id).toList(),
        'courantsLitteraires': _topLitteraires.map((s) => s.id).toList(),
        'approchesPsychologiques': _topPsychologiques.map((s) => s.id).toList(),
        'orientationCompleted': true,
        'orientationDate': DateTime.now().toIso8601String(),
      };

      await CompleteAuthService.instance.saveProfile(updates);

      setState(() {
        _isSaving = false;
        _saved = true;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '✓ Sources d\'inspiration enregistrées !',
              style: GoogleFonts.poppins(),
            ),
            backgroundColor: const Color(0xFF10B981),
          ),
        );
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

  void _shareResults() {
    final philosophe = _topPhilosophes.isNotEmpty ? _topPhilosophes.first.name : 'Inconnu';
    final courant = _topCourantsPhilo.isNotEmpty ? _topCourantsPhilo.first.name : 'Inconnu';
    
    final text = '''
🎭 Mon profil philosophique - Un Autre Regard

👤 Philosophe dominant : $philosophe
🏛️ Courant : $courant
📚 Style littéraire : ${_topLitteraires.isNotEmpty ? _topLitteraires.first.name : '-'}
🧠 Approche psy : ${_topPsychologiques.isNotEmpty ? _topPsychologiques.first.name : '-'}

Découvre ton profil sur l'app Un Autre Regard ✨
''';

    Share.share(text);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        // Fond bleu pastel comme le reste de l'application
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
          child: SingleChildScrollView(
            child: Column(
              children: [
                // Header
                _buildHeader(),

                // Carte principale
                _buildMainCard(),

                // Détails par catégorie
                _buildCategorySection(
                  icon: '👤',
                  title: 'Tes philosophes',
                  sources: _topPhilosophes,
                  color: const Color(0xFF6366F1),
                ),

                _buildCategorySection(
                  icon: '🏛️',
                  title: 'Tes courants philosophiques',
                  sources: _topCourantsPhilo,
                  color: const Color(0xFF8B5CF6),
                ),

                _buildCategorySection(
                  icon: '📚',
                  title: 'Tes courants littéraires',
                  sources: _topLitteraires,
                  color: const Color(0xFFEC4899),
                ),

                _buildCategorySection(
                  icon: '🧠',
                  title: 'Tes approches psychologiques',
                  sources: _topPsychologiques,
                  color: const Color(0xFF10B981),
                ),

                const SizedBox(height: 24),

                // Boutons d'action
                _buildActionButtons(),

                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                    Icons.close,
                    color: Color(0xFF6366F1),
                    size: 20,
                  ),
                ),
              ),
              IconButton(
                onPressed: _shareResults,
                icon: const Icon(Icons.share, color: Color(0xFF64748B)),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            '✨ Ton univers philosophique',
            style: GoogleFonts.poppins(
              color: const Color(0xFF1E293B),
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ).animate().fadeIn(duration: 500.ms).slideY(begin: -0.3, end: 0),
        ],
      ),
    );
  }

  Widget _buildMainCard() {
    final mainPhilosophe = _topPhilosophes.isNotEmpty ? _topPhilosophes.first : null;
    final mainCourant = _topCourantsPhilo.isNotEmpty ? _topCourantsPhilo.first : null;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF6366F1),
            Color(0xFF8B5CF6),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6366F1).withOpacity(0.4),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          // Icône principale
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                '🎭',
                style: const TextStyle(fontSize: 40),
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          if (mainPhilosophe != null) ...[
            Text(
              mainPhilosophe.name,
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Ton philosophe dominant',
              style: GoogleFonts.poppins(
                color: Colors.white70,
                fontSize: 14,
              ),
            ),
          ],
          
          const SizedBox(height: 16),
          
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              mainCourant?.name ?? 'Éclectique',
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    ).animate()
      .fadeIn(delay: 200.ms, duration: 500.ms)
      .scale(begin: const Offset(0.8, 0.8), end: const Offset(1, 1));
  }

  Widget _buildCategorySection({
    required String icon,
    required String title,
    required List<SourceInfo> sources,
    required Color color,
  }) {
    if (sources.isEmpty) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.fromLTRB(24, 24, 24, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(icon, style: const TextStyle(fontSize: 20)),
              const SizedBox(width: 8),
              Text(
                title,
                style: GoogleFonts.poppins(
                  color: const Color(0xFF1E293B),
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: sources.map((source) {
              final score = widget.scores[source.id] ?? 0;
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: color.withOpacity(0.2)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      source.name,
                      style: GoogleFonts.poppins(
                        color: const Color(0xFF1E293B),
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: color,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '$score',
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    ).animate()
      .fadeIn(delay: 400.ms, duration: 400.ms)
      .slideX(begin: 0.2, end: 0);
  }

  Widget _buildActionButtons() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          // Bouton principal : Valider et personnaliser
          ElevatedButton.icon(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => OrientationValidationScreen(scores: widget.scores),
                ),
              );
            },
            icon: const Icon(Icons.tune),
            label: Text(
              'Valider et personnaliser',
              style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6366F1),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              minimumSize: const Size(double.infinity, 56),
            ),
          ),

          const SizedBox(height: 12),

          // Bouton secondaire : Retour au menu
          OutlinedButton.icon(
            onPressed: () {
              Navigator.of(context).pushNamedAndRemoveUntil(
                '/home',
                (route) => false,
              );
            },
            icon: const Icon(Icons.home),
            label: Text(
              'Retour au menu',
              style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
            ),
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF64748B),
              side: const BorderSide(color: Color(0xFFE2E8F0)),
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              minimumSize: const Size(double.infinity, 56),
            ),
          ),

          const SizedBox(height: 12),

          // Bouton tertiaire : Recommencer
          TextButton.icon(
            onPressed: () {
              Navigator.of(context).pushReplacementNamed('/orientation');
            },
            icon: const Icon(Icons.refresh, size: 18),
            label: Text(
              'Recommencer le quiz',
              style: GoogleFonts.poppins(fontSize: 13),
            ),
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFF64748B),
            ),
          ),
        ],
      ),
    ).animate()
      .fadeIn(delay: 600.ms, duration: 400.ms);
  }
}
