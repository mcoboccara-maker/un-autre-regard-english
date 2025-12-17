import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../services/persistent_storage_service.dart'; // ✅ SEUL SERVICE NÉCESSAIRE
import '../../widgets/app_scaffold.dart'; // ✅ AJOUT IMPORT APPSCAFFOLD
// ❌ SUPPRIMÉS - Services redondants :
// import '../../services/historique_eclairages_service.dart';
// import '../../services/dynamic_approach_service_zero_hardcoded.dart';
// import '../../models/daily_entry.dart';
// import '../../models/eclairage_entry.dart';
// import '../../models/micro_action_status.dart';

class ProgressionScreen extends StatefulWidget {
  const ProgressionScreen({super.key});

  @override
  State<ProgressionScreen> createState() => _ProgressionScreenState();
}

class _ProgressionScreenState extends State<ProgressionScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  
  // ✅ UTILISE LES DONNÉES UNIFIÉES
  bool _isLoading = true;
  Map<String, dynamic> _progressData = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadProgressData();
  }

  // ✅ CHARGEMENT UNIFIÉ DES DONNÉES
  Future<void> _loadProgressData() async {
    setState(() => _isLoading = true);
    
    try {
      // 🔄 UTILISE LE SERVICE UNIFIÉ ÉTENDU
      final progressData = PersistentStorageService.instance.getProgressDashboard();
      
      setState(() {
        _progressData = progressData;
        _isLoading = false;
      });
      
      print('📊 Données de progression chargées: ${progressData['overview']['totalReflections']} réflexions');
    } catch (e) {
      print('❌ Erreur chargement données de progression: $e');
      setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return AppScaffold(
        title: 'Ma Progression',
        headerIconPath: 'assets/univers_visuel/historique.png',
        showTitle: false,
        showBackButton: true,
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    // ✅ UTILISATION DE APPSCAFFOLD avec TabBar dans le body
    return AppScaffold(
      title: 'Ma Progression',
      headerIconPath: 'assets/univers_visuel/historique.png',
      showTitle: false,
      showBackButton: true,
      body: Column(
        children: [
          // TabBar personnalisé dans le body
          Container(
            color: Colors.white,
            child: TabBar(
              controller: _tabController,
              labelColor: const Color(0xFF6366F1),
              unselectedLabelColor: Colors.grey[600],
              indicatorColor: const Color(0xFF6366F1),
              tabs: const [
                Tab(text: 'Vue d\'ensemble'),
                Tab(text: 'Émotions'),
                Tab(text: 'Approches'),
              ],
            ),
          ),
          
          // Contenu des onglets
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildOverviewTab(),
                _buildEmotionsTab(),
                _buildApproachesTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOverviewTab() {
    final overview = _progressData['overview'] ?? {};
    final totalReflections = overview['totalReflections'] ?? 0;
    final averageIntensity = overview['averageEmotionalIntensity'] ?? 0;
    final lastActivity = overview['lastActivity'];
    final approachesConfigured = overview['approachesConfigured'] ?? false;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          _buildStatsCards(totalReflections, averageIntensity, approachesConfigured),
          const SizedBox(height: 24),
          _buildWeeklyChart(),
          const SizedBox(height: 24),
          _buildRecentActivity(lastActivity),
        ],
      ),
    );
  }

  Widget _buildStatsCards(int totalReflections, int averageIntensity, bool approachesConfigured) {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            'Réflexions',
            totalReflections.toString(),
            Icons.psychology,
            const Color(0xFF6366F1),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildStatCard(
            'Intensité moy.',
            '$averageIntensity/10',
            Icons.sentiment_satisfied,
            averageIntensity > 7 ? Colors.orange : 
            averageIntensity > 4 ? const Color(0xFF10B981) : Colors.blue,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 24),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: GoogleFonts.inter(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWeeklyChart() {
    final recentTrends = _progressData['recentTrends'] ?? {};
    final dailyAverages = recentTrends['dailyAverages'] ?? [];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Activité des 14 derniers jours',
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF111827),
            ),
          ),
          const SizedBox(height: 20),
          if (dailyAverages.isEmpty)
            SizedBox(
              height: 150,
              child: Center(
                child: Text(
                  'Pas encore de données',
                  style: GoogleFonts.inter(color: Colors.grey[600]),
                ),
              ),
            )
          else
            SizedBox(
              height: 150,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: _buildWeeklyBars(dailyAverages),
              ),
            ),
        ],
      ),
    );
  }

  List<Widget> _buildWeeklyBars(List<dynamic> dailyAverages) {
    if (dailyAverages.isEmpty) return [];
    
    // Prendre les 7 derniers jours
    final recentDays = dailyAverages.take(7).toList();
    final maxValue = recentDays.fold<double>(1.0, (max, day) {
      final intensity = day['averageIntensity'] ?? 0;
      return intensity > max ? intensity.toDouble() : max;
    });

    return recentDays.map<Widget>((day) {
      final intensity = day['averageIntensity'] ?? 0;
      final date = day['date'] ?? '';
      final height = maxValue > 0 ? (intensity / maxValue) * 120 : 10.0;

      // Extraire le jour du mois depuis la date
      String dayLabel = '';
      try {
        final parts = date.split('-');
        if (parts.length >= 3) {
          dayLabel = parts[2]; // Jour du mois
        }
      } catch (e) {
        dayLabel = '?';
      }

      return Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Container(
            width: 24,
            height: height + 10, // Minimum height
            decoration: BoxDecoration(
              color: intensity > 0 ? const Color(0xFF6366F1) : Colors.grey[300],
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            dayLabel,
            style: GoogleFonts.inter(
              fontSize: 12,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      );
    }).toList();
  }

  Widget _buildRecentActivity(String? lastActivity) {
    // ✅ UTILISE LES RÉFLEXIONS DU SERVICE UNIFIÉ
    final recentReflections = PersistentStorageService.instance.getAllReflections().take(5).toList();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Activité récente',
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF111827),
            ),
          ),
          const SizedBox(height: 16),
          if (recentReflections.isEmpty)
            Padding(
              padding: const EdgeInsets.all(20),
              child: Center(
                child: Text(
                  'Aucune réflexion enregistrée',
                  style: GoogleFonts.inter(color: Colors.grey[600]),
                ),
              ),
            )
          else
            ...recentReflections.map((reflection) => _buildActivityItem(reflection)),
        ],
      ),
    );
  }

  Widget _buildActivityItem(dynamic reflection) {
    final formattedDate = _formatDate(reflection.createdAt);
    final approachesCount = reflection.selectedApproaches?.length ?? 0;
    
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Colors.grey[200]!),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: const Color(0xFF6366F1),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Réflexion · $approachesCount perspective(s)',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF111827),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  formattedDate,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          Icon(
            Icons.arrow_forward_ios,
            size: 16,
            color: Colors.grey[400],
          ),
        ],
      ),
    );
  }

  Widget _buildEmotionsTab() {
    final emotionalTrends = _progressData['recentTrends']?['topEmotions'] ?? [];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          _buildEmotionalTrendsChart(emotionalTrends),
          const SizedBox(height: 24),
          _buildTopEmotions(emotionalTrends),
        ],
      ),
    );
  }

  Widget _buildEmotionalTrendsChart(List<dynamic> trends) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Tendances émotionnelles',
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF111827),
            ),
          ),
          const SizedBox(height: 16),
          if (trends.isEmpty)
            Padding(
              padding: const EdgeInsets.all(20),
              child: Center(
                child: Text(
                  'Pas encore de données',
                  style: GoogleFonts.inter(color: Colors.grey[600]),
                ),
              ),
            )
          else
            SizedBox(
              height: 200,
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.trending_up,
                      size: 48,
                      color: Colors.grey[400],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Graphique des tendances\n(À venir prochainement)',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTopEmotions(List<dynamic> emotionalTrends) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Émotions principales',
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF111827),
            ),
          ),
          const SizedBox(height: 16),
          if (emotionalTrends.isEmpty)
            Padding(
              padding: const EdgeInsets.all(20),
              child: Center(
                child: Text(
                  'Pas encore de données émotionnelles',
                  style: GoogleFonts.inter(color: Colors.grey[600]),
                ),
              ),
            )
          else
            ...emotionalTrends.take(5).map((trend) => _buildEmotionItem(trend)),
        ],
      ),
    );
  }

  Widget _buildEmotionItem(Map<String, dynamic> trend) {
    final emotion = trend['emotion'] as String? ?? 'Inconnu';
    final average = trend['averageIntensity'] as int? ?? 0;
    final count = trend['totalOccurrences'] as int? ?? 0;
    final intensity = average / 10.0; // Normaliser pour la barre

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  emotion,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              Text(
                '$count fois',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: intensity.clamp(0.0, 1.0),
            backgroundColor: Colors.grey[200],
            valueColor: AlwaysStoppedAnimation<Color>(
              intensity > 0.7 ? Colors.red :
              intensity > 0.4 ? Colors.orange :
              const Color(0xFF10B981),
            ),
            minHeight: 8,
          ),
        ],
      ),
    );
  }

  Widget _buildApproachesTab() {
    final approachInsights = _progressData['approachInsights'] ?? {};
    final currentConfig = _progressData['currentConfiguration'] ?? {};

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          _buildUserApproachesInfo(currentConfig),
          const SizedBox(height: 24),
          _buildApproachesUsageChart(approachInsights),
        ],
      ),
    );
  }

  Widget _buildUserApproachesInfo(Map<String, dynamic> currentConfig) {
    final selectedApproaches = currentConfig['selectedApproaches'] ?? [];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Vos approches configurées',
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF111827),
            ),
          ),
          const SizedBox(height: 20),
          if (selectedApproaches.isEmpty)
            Text(
              'Aucune approche sélectionnée dans votre profil',
              style: GoogleFonts.inter(color: Colors.grey[600]),
            )
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: selectedApproaches.map<Widget>((name) {
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF6366F1).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: const Color(0xFF6366F1).withOpacity(0.3),
                    ),
                  ),
                  child: Text(
                    name.toString(),
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: const Color(0xFF6366F1),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                );
              }).toList(),
            ),
        ],
      ),
    );
  }

  Widget _buildApproachesUsageChart(Map<String, dynamic> approachInsights) {
    final effectiveness = approachInsights['approachEffectiveness'] ?? [];
    final recommended = approachInsights['recommendedApproaches'] ?? [];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Efficacité des approches',
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF111827),
            ),
          ),
          const SizedBox(height: 16),
          if (effectiveness.isEmpty)
            Padding(
              padding: const EdgeInsets.all(20),
              child: Center(
                child: Text(
                  'Pas encore assez de données pour analyser l\'efficacité',
                  style: GoogleFonts.inter(color: Colors.grey[600]),
                  textAlign: TextAlign.center,
                ),
              ),
            )
          else
            Column(
              children: [
                if (recommended.isNotEmpty) ...[
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF10B981).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.recommend,
                              color: const Color(0xFF10B981),
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Approches recommandées',
                              style: GoogleFonts.inter(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF10B981),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          recommended.join(', '),
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            color: const Color(0xFF10B981),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                SizedBox(
                  height: 200,
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.analytics,
                          size: 48,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Analyse détaillée de l\'efficacité\n(À venir prochainement)',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.inter(color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date).inDays;
    
    if (difference == 0) {
      return 'Aujourd\'hui';
    } else if (difference == 1) {
      return 'Hier';
    } else if (difference < 7) {
      return 'Il y a $difference jours';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}
