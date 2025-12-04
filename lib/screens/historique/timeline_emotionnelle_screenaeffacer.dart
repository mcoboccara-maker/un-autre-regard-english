import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../../services/historique_eclairages_service.dart';
import '../../models/daily_entry.dart';
import '../../widgets/global_app_bar.dart';

class TimelineEmotionnelleScreen extends StatefulWidget {
  const TimelineEmotionnelleScreen({super.key});

  @override
  State<TimelineEmotionnelleScreen> createState() => _TimelineEmotionnelleScreenState();
}

class _TimelineEmotionnelleScreenState extends State<TimelineEmotionnelleScreen> {
  List<DailyEntry> _entries = [];
  bool _isLoading = true;
  String _selectedPeriod = '7j'; // 7j, 30j, 6m
  String _selectedEmotion = 'all'; // all, specific emotion

  @override
  void initState() {
    super.initState();
    timeago.setLocaleMessages('fr', timeago.FrMessages());
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    
    try {
      final service = HistoriqueEclairagesService.instance;
      
      final days = _selectedPeriod == '7j' ? 7 : _selectedPeriod == '30j' ? 30 : 180;
      _entries = await service.getDailyEntriesLastDays(days);
      
    } catch (e) {
      print('Erreur chargement timeline: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: const GlobalAppBar(
        title: 'Timeline Émotionnelle',
        showBackButton: true,
      ),
      body: Column(
        children: [
          _buildPeriodSelector(),
          _buildEmotionSelector(),
          Expanded(
            child: _isLoading ? _buildLoading() : _buildTimeline(),
          ),
        ],
      ),
    );
  }

  Widget _buildPeriodSelector() {
    return Container(
      margin: const EdgeInsets.all(16),
      child: Row(
        children: [
          Text(
            'Période :',
            style: GoogleFonts.inter(
              fontWeight: FontWeight.w500,
              color: const Color(0xFF374151),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Row(
              children: [
                _buildPeriodChip('7j', '7 jours'),
                const SizedBox(width: 8),
                _buildPeriodChip('30j', '30 jours'),
                const SizedBox(width: 8),
                _buildPeriodChip('6m', '6 mois'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPeriodChip(String value, String label) {
    final isSelected = _selectedPeriod == value;
    
    return GestureDetector(
      onTap: () {
        setState(() => _selectedPeriod = value);
        _loadData();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF6366F1) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? const Color(0xFF6366F1) : const Color(0xFFE5E7EB),
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: isSelected ? Colors.white : const Color(0xFF6B7280),
          ),
        ),
      ),
    );
  }

  Widget _buildEmotionSelector() {
    final emotions = ['all', 'OUVERT', 'AIMANT', 'HEUREUX', 'VIVANT', 'POSITIF', 'PAISIBLE', 'FORT', 'DETENDU'];
    
    return Container(
      height: 50,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: emotions.length,
        itemBuilder: (context, index) {
          final emotion = emotions[index];
          final isSelected = _selectedEmotion == emotion;
          
          return Container(
            margin: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () => setState(() => _selectedEmotion = emotion),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected ? const Color(0xFF10B981) : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isSelected ? const Color(0xFF10B981) : const Color(0xFFE5E7EB),
                  ),
                ),
                child: Text(
                  emotion == 'all' ? 'Toutes' : emotion,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: isSelected ? Colors.white : const Color(0xFF6B7280),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildLoading() {
    return const Center(
      child: CircularProgressIndicator(
        color: Color(0xFF6366F1),
      ),
    );
  }

  Widget _buildTimeline() {
    if (_entries.isEmpty) {
      return _buildEmptyState();
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildEmotionChart(),
          const SizedBox(height: 24),
          _buildIntensityChart(),
          const SizedBox(height: 24),
          _buildEntriesList(),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.timeline,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'Aucune donnée pour cette période',
            style: GoogleFonts.inter(
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Commencez à utiliser l\'app pour voir votre évolution émotionnelle',
            style: GoogleFonts.inter(
              fontSize: 14,
              color: Colors.grey[500],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildEmotionChart() {
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
            'Évolution Émotionnelle',
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF111827),
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 200,
            child: LineChart(
              LineChartData(
                gridData: const FlGridData(show: true),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      interval: 2,
                      getTitlesWidget: (value, meta) => Text(
                        value.toInt().toString(),
                        style: GoogleFonts.inter(fontSize: 12),
                      ),
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        final index = value.toInt();
                        if (index >= 0 && index < _entries.length) {
                          return Text(
                            timeago.format(_entries[index].timestamp, locale: 'fr'),
                            style: GoogleFonts.inter(fontSize: 10),
                          );
                        }
                        return const Text('');
                      },
                    ),
                  ),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                borderData: FlBorderData(
                  show: true,
                  border: Border.all(color: const Color(0xFFE5E7EB)),
                ),
                minX: 0,
                maxX: _entries.length.toDouble() - 1,
                minY: 0,
                maxY: 10,
                lineBarsData: _buildEmotionLines(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<LineChartBarData> _buildEmotionLines() {
    final emotionColors = {
      'OUVERT': const Color(0xFF3B82F6),
      'AIMANT': const Color(0xFFEC4899),
      'HEUREUX': const Color(0xFFF59E0B),
      'VIVANT': const Color(0xFF10B981),
      'POSITIF': const Color(0xFF8B5CF6),
      'PAISIBLE': const Color(0xFF06B6D4),
      'FORT': const Color(0xFFEF4444),
      'DETENDU': const Color(0xFF84CC16),
    };

    if (_selectedEmotion == 'all') {
      // Afficher l'intensité émotionnelle moyenne
      return [
        LineChartBarData(
          spots: _entries.asMap().entries.map((entry) {
            return FlSpot(entry.key.toDouble(), entry.value.intensiteEmotionnelle.toDouble());
          }).toList(),
          isCurved: true,
          color: const Color(0xFF6366F1),
          barWidth: 3,
          dotData: const FlDotData(show: true),
        ),
      ];
    } else {
      // Afficher l'émotion sélectionnée
      return [
        LineChartBarData(
          spots: _entries.asMap().entries.map((entry) {
            final level = entry.value.emotionalState.emotions[_selectedEmotion]?.level ?? 0;
            return FlSpot(entry.key.toDouble(), level.toDouble());
          }).toList(),
          isCurved: true,
          color: emotionColors[_selectedEmotion] ?? const Color(0xFF6366F1),
          barWidth: 3,
          dotData: const FlDotData(show: true),
        ),
      ];
    }
  }

  Widget _buildIntensityChart() {
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
            'Répartition des Intensités',
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF111827),
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 200,
            child: PieChart(
              PieChartData(
                sectionsSpace: 2,
                centerSpaceRadius: 40,
                sections: _buildIntensitySections(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<PieChartSectionData> _buildIntensitySections() {
    final intensityCounts = <String, int>{
      'Faible (1-3)': 0,
      'Modérée (4-6)': 0,
      'Élevée (7-8)': 0,
      'Très élevée (9-10)': 0,
    };

    for (final entry in _entries) {
      final intensity = entry.intensiteEmotionnelle;
      if (intensity <= 3) intensityCounts['Faible (1-3)'] = intensityCounts['Faible (1-3)']! + 1;
      else if (intensity <= 6) intensityCounts['Modérée (4-6)'] = intensityCounts['Modérée (4-6)']! + 1;
      else if (intensity <= 8) intensityCounts['Élevée (7-8)'] = intensityCounts['Élevée (7-8)']! + 1;
      else intensityCounts['Très élevée (9-10)'] = intensityCounts['Très élevée (9-10)']! + 1;
    }

    final colors = [
      const Color(0xFF10B981),
      const Color(0xFF3B82F6),
      const Color(0xFFF59E0B),
      const Color(0xFFEF4444),
    ];

    return intensityCounts.entries.map((entry) {
      final index = intensityCounts.keys.toList().indexOf(entry.key);
      return PieChartSectionData(
        color: colors[index],
        value: entry.value.toDouble(),
        title: '${entry.value}',
        radius: 60,
        titleStyle: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      );
    }).toList();
  }

  Widget _buildEntriesList() {
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
            'Historique des Entrées',
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF111827),
            ),
          ),
          const SizedBox(height: 16),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _entries.length,
            separatorBuilder: (context, index) => const Divider(),
            itemBuilder: (context, index) {
              final entry = _entries[index];
              return ListTile(
                contentPadding: EdgeInsets.zero,
                leading: CircleAvatar(
                  backgroundColor: _getIntensityColor(entry.intensiteEmotionnelle),
                  child: Text(
                    entry.intensiteEmotionnelle.toString(),
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
                title: Text(
                  entry.summary,
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                subtitle: Text(
                  '${entry.formattedDate} • ${entry.emotionPrincipale ?? "Émotions mixtes"}',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
                trailing: Text(
                  entry.formattedTime,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: Colors.grey[500],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Color _getIntensityColor(int intensity) {
    if (intensity <= 3) return const Color(0xFF10B981); // Vert
    if (intensity <= 6) return const Color(0xFF3B82F6); // Bleu
    if (intensity <= 8) return const Color(0xFFF59E0B); // Orange
    return const Color(0xFFEF4444); // Rouge
  }
}
