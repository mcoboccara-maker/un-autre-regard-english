import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../services/complete_auth_service.dart';
import '../../models/reflection.dart';
import '../../models/emotional_state.dart';
import '../../config/emotion_config.dart';
import '../../widgets/app_scaffold.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  List<Reflection> _reflections = [];
  bool _isLoading = true;
  String _searchQuery = '';
  String _selectedFilter = 'Toutes';

  final List<String> _filterOptions = [
    'Toutes',
    'Cette semaine',
    'Ce mois',
    'Cette annee',
  ];

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    try {
      print('🔍 DEBUG: Chargement historique avec CompleteAuthService...');
    
      final reflectionsData = await CompleteAuthService.instance.getAllReflections();
      print('📊 DEBUG: ${reflectionsData.length} reflexions trouvees');
    
      final reflections = <Reflection>[];
      for (final data in reflectionsData) {
        try {
          print('🔑 DEBUG: Cles disponibles dans data: ${data.keys.toList()}');
          print('📊 DEBUG: emotionalState dans data: ${data['emotionalState']}');
          
          // Creer un EmotionalState vide par defaut
          final emotionalState = EmotionalState.fromJson(data['emotionalState'] ?? {});
          
          // CORRIGÉ: Récupérer le type sauvegardé correctement
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
        
          final reflection = Reflection(
            id: data['id']?.toString() ?? DateTime.now().millisecondsSinceEpoch.toString(),
            text: data['text']?.toString() ?? 'Aucun contenu',
            type: reflectionType,  // CORRIGÉ: utiliser le type parsé
            emotionalState: emotionalState,
            selectedApproaches: List<String>.from(data['selectedApproaches'] ?? []),
            createdAt: DateTime.tryParse(data['createdAt']?.toString() ?? '') ?? DateTime.now(),
            aiResponses: Map<String, String>.from(data['aiResponses'] ?? {}),
            isFavorite: false,
            declencheur: data['declencheur']?.toString(),
            souhait: data['souhait']?.toString(),
            petitPas: data['petitPas']?.toString(),
            intensiteEmotionnelle: data['intensiteEmotionnelle']?.toInt() ?? 5,
            emotionPrincipale: data['emotionPrincipale']?.toString(),
          );
          reflections.add(reflection);
        } catch (e) {
          print('⚠️ Erreur conversion reflexion: $e');
        }
      }
    
      print('✅ DEBUG: ${reflections.length} reflexions converties avec succes');
      print('📋 DEBUG DETAILLE HISTORIQUE:');
      for (int i = 0; i < reflections.length; i++) {
        final r = reflections[i];
        print('   Reflexion $i:');
        print('     - Text: "${r.text}"');
        print('     - Type: ${r.type}');
        print('     - Approches: ${r.selectedApproaches.length}');
        print('     - Reponses IA: ${r.aiResponses.length}');
        print('     - Declencheur: "${r.declencheur}"');
      }
      print('📊 DEBUG RAW DATA:');
      for (int i = 0; i < reflectionsData.length; i++) {
        final data = reflectionsData[i];
        print('   Raw $i: userInput="${data['userInput']}", text="${data['text']}"');
      }
    
      setState(() {
        _reflections = reflections;
        _isLoading = false;
      });
    } catch (e) {
      print('❌ DEBUG: Erreur chargement historique: $e');
      setState(() => _isLoading = false);
    }
  }

  // NOUVEAU: Obtenir le chemin de l'icône PNG selon le type
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

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return AppScaffold(
      title: 'Historique',
      headerIconPath: 'assets/univers_visuel/historique des pensees.png',  // AJOUTÉ: icône dans le header
      showMenuButton: true,
      showPositiveButton: true,
      showBackButton: true,
      body: Column(
        children: [
          _buildSearchAndFilter(),
          Expanded(
            child: _buildHistoryList(),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
        ),
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back, color: Colors.white),
          ),
          Expanded(
            child: Text(
              'Historique de vos reflexions',
              style: GoogleFonts.inter(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '${_filteredReflections.length}',
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    ).animate().slideY(begin: -0.3, end: 0);
  }

  Widget _buildSearchAndFilter() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Barre de recherche
          TextField(
            onChanged: (value) => setState(() => _searchQuery = value),
            decoration: InputDecoration(
              hintText: 'Rechercher dans vos reflexions...',
              prefixIcon: const Icon(Icons.search, color: Color(0xFF6366F1)),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFF6366F1), width: 2),
              ),
              filled: true,
              fillColor: Colors.white,
            ),
          ),
          
          const SizedBox(height: 12),
          
          // Filtres
          SizedBox(
            height: 40,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _filterOptions.length,
              itemBuilder: (context, index) {
                final option = _filterOptions[index];
                final isSelected = _selectedFilter == option;
                
                return Container(
                  margin: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(option),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() => _selectedFilter = option);
                    },
                    backgroundColor: Colors.white,
                    selectedColor: const Color(0xFF6366F1).withOpacity(0.1),
                    checkmarkColor: const Color(0xFF6366F1),
                    labelStyle: GoogleFonts.inter(
                      color: isSelected ? const Color(0xFF6366F1) : const Color(0xFF64748B),
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                    ),
                    side: BorderSide(
                      color: isSelected ? const Color(0xFF6366F1) : const Color(0xFFE2E8F0),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 200.ms);
  }

  Widget _buildHistoryList() {
    final filteredReflections = _filteredReflections;
    
    if (filteredReflections.isEmpty) {
      return _buildEmptyState();
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: filteredReflections.length,
      itemBuilder: (context, index) {
        final reflection = filteredReflections[index];
        return _buildReflectionCard(reflection, index);
      },
    );
  }

  Widget _buildReflectionCard(Reflection reflection, int index) {
    final emotionalState = reflection.emotionalState;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: InkWell(
          onTap: () => _showReflectionDetail(reflection, emotionalState),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header avec date et type - CORRIGÉ: ICÔNE PNG AU LIEU DE TEXTE
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // CORRIGÉ: Afficher l'icône PNG du type au lieu du texte
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: _getTypeColor(reflection.type).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Image.asset(
                        _getTypeIconPath(reflection.type),
                        width: 28,
                        height: 28,
                        errorBuilder: (context, error, stackTrace) {
                          // Fallback: afficher le texte si l'icône n'existe pas
                          return Text(
                            reflection.type.displayName,
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: _getTypeColor(reflection.type),
                            ),
                          );
                        },
                      ),
                    ),
                    Text(
                      '${reflection.createdAt.day}/${reflection.createdAt.month}/${reflection.createdAt.year}',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: const Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 12),
                
                // Contenu de la reflexion
                Text(
                  reflection.text.length > 120 
                    ? '${reflection.text.substring(0, 120)}...'
                    : reflection.text,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: const Color(0xFF0F172A),
                    height: 1.4,
                  ),
                ),
                
                if (emotionalState != null) ...[
                  const SizedBox(height: 12),
                  _buildEmotionChips(reflection.emotionalState),
                ],
                
                const SizedBox(height: 12),
                
                // Footer avec actions
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${reflection.selectedApproaches.length} approche(s)',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: const Color(0xFF64748B),
                      ),
                    ),
                    Row(
                      children: [
                        IconButton(
                          onPressed: () => _shareReflection(reflection),
                          icon: const Icon(Icons.share, size: 18),
                          style: IconButton.styleFrom(
                            backgroundColor: const Color(0xFF6366F1).withOpacity(0.1),
                            foregroundColor: const Color(0xFF6366F1),
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          onPressed: () => _deleteReflection(reflection),
                          icon: const Icon(Icons.delete_outline, size: 18),
                          style: IconButton.styleFrom(
                            backgroundColor: Colors.red.withOpacity(0.1),
                            foregroundColor: Colors.red,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    ).animate().fadeIn(delay: (index * 100).ms).slideX(begin: 0.3, end: 0);
  }

  Widget _buildEmotionChips(EmotionalState emotionalState) {
    // TRIER PAR NIVEAU (les plus fortes en premier) + filtrer niveau > 3
    final mainEmotions = emotionalState.emotions.entries
        .where((entry) => entry.value.level > 3)
        .toList()
      ..sort((a, b) => b.value.level.compareTo(a.value.level));

    if (mainEmotions.isEmpty) return const SizedBox.shrink();

    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: mainEmotions.take(5).map((emotion) {
        // Chercher l'emotion (negative OU positive)
        final emotionConfig = EmotionCategories.findByKey(emotion.key);
        final displayText = emotionConfig?.name ?? emotion.key;
        final emotionColor = emotionConfig?.color ?? const Color(0xFF10B981);
        
        // Determiner si c'est une emotion negative ou positive
        final isNegative = EmotionCategories.negativeEmotions
            .any((e) => e.key == emotion.key);
        final emotionBadge = isNegative ? '😔' : '😊';
        
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: emotionColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: emotionColor.withOpacity(0.3),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Badge emoji
              Text(
                emotionBadge,
                style: const TextStyle(fontSize: 10),
              ),
              const SizedBox(width: 4),
              // Icône de l'emotion
              if (emotionConfig != null) ...[
                Icon(
                  emotionConfig.icon,
                  size: 12,
                  color: emotionColor,
                ),
                const SizedBox(width: 4),
              ],
              // Nom + niveau
              Text(
                '$displayText ${emotion.value.level}%',
                style: GoogleFonts.inter(
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                  color: emotionColor,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  /// Afficher TOUTES les emotions avec separation negatif/positif
  Widget _buildDetailedEmotionsList(EmotionalState emotionalState) {
    // Separer les emotions negatives et positives
    final negativeEmotions = <MapEntry<String, EmotionLevel>>[];
    final positiveEmotions = <MapEntry<String, EmotionLevel>>[];
    
    for (final entry in emotionalState.emotions.entries) {
      if (entry.value.level > 0) {
        final isNegative = EmotionCategories.negativeEmotions
            .any((e) => e.key == entry.key);
        
        if (isNegative) {
          negativeEmotions.add(entry);
        } else {
          positiveEmotions.add(entry);
        }
      }
    }
    
    // Trier par niveau decroissant
    negativeEmotions.sort((a, b) => b.value.level.compareTo(a.value.level));
    positiveEmotions.sort((a, b) => b.value.level.compareTo(a.value.level));
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Emotions negatives
        if (negativeEmotions.isNotEmpty) ...[
          Row(
            children: [
              const Text('😔', style: TextStyle(fontSize: 14)),
              const SizedBox(width: 6),
              Text(
                'Emotions difficiles (${negativeEmotions.length})',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF64748B),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: negativeEmotions.map((emotion) {
              final emotionConfig = EmotionCategories.findByKey(emotion.key);
              final displayText = emotionConfig?.name ?? emotion.key;
              final emotionColor = emotionConfig?.color ?? const Color(0xFF10B981);
              final nuances = emotion.value.nuances;
              
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: emotionColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: emotionColor.withOpacity(0.3),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (emotionConfig != null) ...[
                          Icon(
                            emotionConfig.icon,
                            size: 14,
                            color: emotionColor,
                          ),
                          const SizedBox(width: 6),
                        ],
                        Text(
                          '$displayText ${emotion.value.level}%',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: emotionColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Affichage des nuances
                  if (nuances.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Padding(
                      padding: const EdgeInsets.only(left: 12),
                      child: Text(
                        '└─ ${nuances.join(', ')}',
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          fontStyle: FontStyle.italic,
                          color: emotionColor.withOpacity(0.7),
                        ),
                      ),
                    ),
                  ],
                ],
              );
            }).toList(),
          ),
        ],
        
        // Espacement entre les deux types
        if (negativeEmotions.isNotEmpty && positiveEmotions.isNotEmpty)
          const SizedBox(height: 16),
        
        // Emotions positives
        if (positiveEmotions.isNotEmpty) ...[
          Row(
            children: [
              const Text('😊', style: TextStyle(fontSize: 14)),
              const SizedBox(width: 6),
              Text(
                'Emotions ressources (${positiveEmotions.length})',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF64748B),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: positiveEmotions.map((emotion) {
              final emotionConfig = EmotionCategories.findByKey(emotion.key);
              final displayText = emotionConfig?.name ?? emotion.key;
              final emotionColor = emotionConfig?.color ?? const Color(0xFF10B981);
              final nuances = emotion.value.nuances;
              
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: emotionColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: emotionColor.withOpacity(0.3),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (emotionConfig != null) ...[
                          Icon(
                            emotionConfig.icon,
                            size: 14,
                            color: emotionColor,
                          ),
                          const SizedBox(width: 6),
                        ],
                        Text(
                          '$displayText ${emotion.value.level}%',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: emotionColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Affichage des nuances
                  if (nuances.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Padding(
                      padding: const EdgeInsets.only(left: 12),
                      child: Text(
                        '└─ ${nuances.join(', ')}',
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          fontStyle: FontStyle.italic,
                          color: emotionColor.withOpacity(0.7),
                        ),
                      ),
                    ),
                  ],
                ],
              );
            }).toList(),
          ),
        ],
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.psychology_outlined,
            size: 64,
            color: const Color(0xFF94A3B8),
          ),
          const SizedBox(height: 16),
          Text(
            _searchQuery.isNotEmpty 
              ? 'Aucune reflexion trouvee'
              : 'Aucune reflexion encore',
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _searchQuery.isNotEmpty
              ? 'Essayez d\'autres termes de recherche'
              : 'Commencez votre premiere reflexion !',
            style: GoogleFonts.inter(
              fontSize: 14,
              color: const Color(0xFF94A3B8),
            ),
          ),
          if (_searchQuery.isEmpty) ...[
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => Navigator.pushReplacementNamed(context, '/main'),
              child: const Text('Commencer une reflexion'),
            ),
          ],
        ],
      ),
    );
  }

  List<Reflection> get _filteredReflections {
    var filtered = _reflections;

    // Filtrer par recherche
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((reflection) =>
        reflection.text.toLowerCase().contains(_searchQuery.toLowerCase())
      ).toList();
    }

    // Filtrer par periode
    final now = DateTime.now();
    switch (_selectedFilter) {
      case 'Cette semaine':
        final weekAgo = now.subtract(const Duration(days: 7));
        filtered = filtered.where((r) => r.createdAt.isAfter(weekAgo)).toList();
        break;
      case 'Ce mois':
        final monthAgo = DateTime(now.year, now.month - 1, now.day);
        filtered = filtered.where((r) => r.createdAt.isAfter(monthAgo)).toList();
        break;
      case 'Cette annee':
        final yearAgo = DateTime(now.year - 1, now.month, now.day);
        filtered = filtered.where((r) => r.createdAt.isAfter(yearAgo)).toList();
        break;
    }

    return filtered;
  }

  Color _getTypeColor(ReflectionType type) {
    switch (type) {
      case ReflectionType.thought:
        return const Color(0xFF6366F1);
      case ReflectionType.situation:
        return const Color(0xFFEF4444);
      case ReflectionType.existential:
        return const Color(0xFFF59E0B);
      case ReflectionType.dilemma:
        return const Color(0xFF8B5CF6);
    }
  }

  void _showReflectionDetail(Reflection reflection, EmotionalState? emotionalState) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.9,
        minChildSize: 0.5,
        builder: (context, scrollController) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: SingleChildScrollView(
            controller: scrollController,
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Handle
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE2E8F0),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                
                const SizedBox(height: 24),
                
                // Header - CORRIGÉ: ICÔNE PNG AU LIEU DE TEXTE
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: _getTypeColor(reflection.type).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Image.asset(
                        _getTypeIconPath(reflection.type),
                        width: 32,
                        height: 32,
                        errorBuilder: (context, error, stackTrace) {
                          return Text(
                            reflection.type.displayName,
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: _getTypeColor(reflection.type),
                            ),
                          );
                        },
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '${reflection.createdAt.day}/${reflection.createdAt.month}/${reflection.createdAt.year}',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: const Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 24),
                
                // Contenu
                Text(
                  'Votre reflexion',
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  reflection.text,
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    color: const Color(0xFF0F172A),
                    height: 1.5,
                  ),
                ),
                
                if (emotionalState != null) ...[
                  const SizedBox(height: 24),
                  Text(
                    'Etat emotionnel',
                    style: GoogleFonts.inter(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildDetailedEmotionsList(emotionalState),
                ],
                
                const SizedBox(height: 24),
                
                // Approches utilisees
                Text(
                  'Approches utilisees',
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: reflection.selectedApproaches.map((approach) {
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFF6366F1).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        approach,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: const Color(0xFF6366F1),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                
                if (reflection.aiResponses.isNotEmpty) ...[
                  const SizedBox(height: 24),
                  Text(
                    'Perspectives generees',
                    style: GoogleFonts.inter(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 12),
                  ...reflection.aiResponses.entries.map((entry) {
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            entry.key,
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF6366F1),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            entry.value,
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              color: const Color(0xFF0F172A),
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _shareReflection(Reflection reflection) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Fonctionnalite de partage en cours de developpement'),
      ),
    );
  }

  void _deleteReflection(Reflection reflection) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer la reflexion'),
        content: const Text('Etes-vous sur de vouloir supprimer cette reflexion ? Cette action est irreversible.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                await CompleteAuthService.instance.deleteReflection(reflection.id);
                setState(() {
                  _reflections.removeWhere((r) => r.id == reflection.id);
                });
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Reflexion supprimee'),
                    backgroundColor: Colors.green,
                  ),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Erreur: $e'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
  }
}
