// lib/screens/timeline/emotion_timeline_screen.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../services/emotional_tracking_service.dart';
import '../../config/emotion_config.dart';
import '../../widgets/app_scaffold.dart';

class EmotionTimelineScreen extends StatefulWidget {
  const EmotionTimelineScreen({super.key});

  @override
  State<EmotionTimelineScreen> createState() => _EmotionTimelineScreenState();
}

class _EmotionTimelineScreenState extends State<EmotionTimelineScreen> {
  Map<String, List<EmotionDataPoint>> _emotionTimelines = {};
  bool _isLoading = true;
  int _selectedDays = 30;
  Set<String> _visibleEmotions = {};

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    
    print('🔍 Timeline: Chargement des données pour $_selectedDays jours...');
    
    final timelines = await EmotionalTrackingService.instance
        .getCompleteEmotionTimeline(_selectedDays);
    
    print('📊 Timeline: ${timelines.length} émotions différentes trouvées');
    for (final entry in timelines.entries) {
      print('   - ${entry.key}: ${entry.value.length} points de données');
    }
    
    print('🎯 Timeline: Toutes les émotions seront affichées par défaut');

    setState(() {
      _emotionTimelines = timelines;
      // Par défaut, afficher TOUTES les émotions de la période
      _visibleEmotions = timelines.keys.toSet();
      _isLoading = false;
    });

    print('📈 Timeline: visibleEmotions = $_visibleEmotions');
    print('📈 Timeline: emotionTimelines isEmpty? ${_emotionTimelines.isEmpty}');
  }

  Set<String> _getTopEmotions(int count) {
    final emotionFrequency = <String, int>{};
    
    for (final entry in _emotionTimelines.entries) {
      emotionFrequency[entry.key] = entry.value.length;
    }
    
    final sorted = emotionFrequency.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    
    return sorted.take(count).map((e) => e.key).toSet();
  }

  // Trouver l'émotion (chercher dans négatives ET positives)
  EmotionConfig? _findEmotion(String key) {
    try {
      return EmotionCategories.negativeEmotions.firstWhere((e) => e.key == key);
    } catch (e) {
      try {
        return EmotionCategories.positiveEmotions.firstWhere((e) => e.key == key);
      } catch (e) {
        return null;
      }
    }
  }

  // Afficher le dialogue des détails d'une émotion
  void _showEmotionDetailsDialog(String emotionKey) {
    final emotion = _findEmotion(emotionKey);
    if (emotion == null) return;

    final dataPoints = _emotionTimelines[emotionKey] ?? [];
    if (dataPoints.isEmpty) return;

    // Calculer les statistiques
    final intensities = dataPoints.map((p) => p.intensity).toList();
    final avgIntensity = intensities.reduce((a, b) => a + b) / intensities.length;
    final maxIntensity = intensities.reduce((a, b) => a > b ? a : b);
    final minIntensity = intensities.reduce((a, b) => a < b ? a : b);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Image.asset(
              emotion.iconPath,
              width: 28,
              height: 28,
              errorBuilder: (_, __, ___) => Icon(emotion.icon, color: emotion.color, size: 28),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                emotion.name,
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w600,
                  color: emotion.color,
                ),
              ),
            ),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Statistiques
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: emotion.color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    children: [
                      _buildStatRow('📊 Average', '${avgIntensity.toStringAsFixed(0)}%'),
                      _buildStatRow('⬆️ Maximum', '$maxIntensity%'),
                      _buildStatRow('⬇️ Minimum', '$minIntensity%'),
                      _buildStatRow('📅 Occurrences', '${dataPoints.length}'),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Liste des dates
                Text(
                  '📅 Recorded dates:',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),

                // Liste des points avec dates
                ...dataPoints.reversed.take(20).map((point) {
                  final dateStr = '${point.date.day}/${point.date.month}/${point.date.year}';
                  String timeStr = '';
                  if (point.timestamp != null) {
                    timeStr = ' at ${point.timestamp!.hour.toString().padLeft(2, '0')}:${point.timestamp!.minute.toString().padLeft(2, '0')}';
                  }

                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey[300]!),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '$dateStr$timeStr',
                              style: GoogleFonts.poppins(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: emotion.color,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                '${point.intensity}%',
                                style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ),
                        if (point.nuances.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            '💭 ${point.nuances.join(", ")}',
                            style: GoogleFonts.poppins(
                              fontSize: 11,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                        if (point.note != null && point.note!.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            '📝 ${point.note}',
                            style: GoogleFonts.poppins(
                              fontSize: 11,
                              color: Colors.grey[700],
                              fontStyle: FontStyle.italic,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ],
                    ),
                  );
                }),

                if (dataPoints.length > 20)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      '... and ${dataPoints.length - 20} more entries',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: Colors.grey[500],
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Close',
              style: GoogleFonts.poppins(color: emotion.color),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.poppins(fontSize: 13),
          ),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
	  title: 'Emotional Tracking',
	  headerIconPath: 'assets/univers_visuel/suivi_emotions.png',  // Calendrier à gauche
	  showMenuButton: true,
	  showPositiveButton: true,
	  showBackButton: true,
	  additionalActions: [
		PopupMenuButton<int>(
		  icon: Image.asset(
			'assets/univers_visuel/calendrier.png',  // Icône période à droite
			width: 32,
			height: 32,
			errorBuilder: (context, error, stackTrace) {
			  return Icon(Icons.date_range, color: Colors.grey[700]);
			},
		  ),
		  onSelected: (days) {
			setState(() => _selectedDays = days);
			_loadData();
		  },
		  itemBuilder: (context) => [
			const PopupMenuItem(value: 7, child: Text('7 days')),
			const PopupMenuItem(value: 14, child: Text('14 days')),
			const PopupMenuItem(value: 30, child: Text('30 days')),
			const PopupMenuItem(value: 90, child: Text('90 days')),
		  ],
        ),
      ],
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _emotionTimelines.isEmpty
              ? _buildEmptyState()
              : SingleChildScrollView(
                  child: Column(
                    children: [
                      _buildPeriodSelector(),
                      _buildEmotionLegend(),
                      SizedBox(
                        height: 300,  // Hauteur fixe pour le graphique
                        child: _buildChart(),
                      ),
                      _buildStatistics(),
                    ],
                  ),
                ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.trending_up, size: 80, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(
            'No emotional data',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Start by recording your daily emotions',
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPeriodSelector() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.white,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.info_outline, size: 16, color: Colors.grey[600]),
          const SizedBox(width: 8),
          Text(
            'Showing last $_selectedDays days',
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmotionLegend() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '🎨 Emotions (tap = show/hide, long press = details)',
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _emotionTimelines.keys.map((emotionKey) {
              final emotion = _findEmotion(emotionKey);
              if (emotion == null) return const SizedBox.shrink();

              final isVisible = _visibleEmotions.contains(emotionKey);

              return GestureDetector(
                onLongPress: () => _showEmotionDetailsDialog(emotionKey),
                child: FilterChip(
                  label: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Image.asset(
                        emotion.iconPath,
                        width: 16,
                        height: 16,
                        color: isVisible ? null : Colors.grey,
                        errorBuilder: (_, __, ___) => Icon(emotion.icon, size: 16, color: isVisible ? emotion.color : Colors.grey),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        emotion.name,
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          color: isVisible ? emotion.color : Colors.grey[600],
                          fontWeight: isVisible ? FontWeight.w600 : FontWeight.normal,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '(${_emotionTimelines[emotionKey]!.length})',
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          color: Colors.grey[500],
                        ),
                      ),
                    ],
                  ),
                  selected: isVisible,
                  onSelected: (selected) {
                    setState(() {
                      if (selected) {
                        _visibleEmotions.add(emotionKey);
                      } else {
                        _visibleEmotions.remove(emotionKey);
                      }
                    });
                  },
                  backgroundColor: Colors.grey[100],
                  selectedColor: emotion.color.withOpacity(0.2),
                  checkmarkColor: emotion.color,
                  side: BorderSide(
                    color: isVisible ? emotion.color : Colors.grey[300]!,
                    width: isVisible ? 2 : 1,
                  ),
                ),
              );
            }).toList(),
          ),
          if (_visibleEmotions.isEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                '⚠️ Select at least one emotion',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: Colors.orange[700],
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildChart() {
    if (_visibleEmotions.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.show_chart, size: 80, color: Colors.grey[300]),
            const SizedBox(height: 16),
            Text(
              'Select at least one emotion',
              style: GoogleFonts.poppins(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(16),
      child: LineChart(
        LineChartData(
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: 20,
            getDrawingHorizontalLine: (value) {
              return FlLine(
                color: Colors.grey[200]!,
                strokeWidth: 1,
              );
            },
          ),
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 40,
                interval: 20,
                getTitlesWidget: (value, meta) {
                  return Text(
                    '${value.toInt()}%',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  );
                },
              ),
            ),
            rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 30,
                interval: _selectedDays / 5,
                getTitlesWidget: (value, meta) {
                  final date = DateTime.now().subtract(
                    Duration(days: _selectedDays - value.toInt()),
                  );
                  return Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      '${date.day}/${date.month}',
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        color: Colors.grey[600],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          borderData: FlBorderData(
            show: true,
            border: Border(
              left: BorderSide(color: Colors.grey[300]!),
              bottom: BorderSide(color: Colors.grey[300]!),
            ),
          ),
          minY: 0,
          maxY: 100,
          lineBarsData: _buildLineChartData(),
          lineTouchData: LineTouchData(
            touchTooltipData: LineTouchTooltipData(
              tooltipBgColor: Colors.white,
              tooltipBorder: BorderSide(color: Colors.grey[300]!, width: 1),
              getTooltipItems: (touchedSpots) {
                return touchedSpots.map((spot) {
                  final emotionKey = _visibleEmotions.elementAt(spot.barIndex);
                  final emotion = _findEmotion(emotionKey);
                  if (emotion == null) return null;
                  
                  final dataPoints = _emotionTimelines[emotionKey] ?? [];
                  
                  // Trouver le point exact à cette date
                  final now = DateTime.now();
                  final date = now.subtract(Duration(days: _selectedDays - spot.x.toInt()));
                  final exactPoint = dataPoints.firstWhere(
                    (p) => p.date.year == date.year &&
                         p.date.month == date.month &&
                         p.date.day == date.day,
                    orElse: () => dataPoints.first,
                  );
                  
                  // Construire le texte du tooltip
                  String tooltipText = '${emotion.name}\n';
                  tooltipText += '${spot.y.toInt()}%\n';
                  tooltipText += '${date.day}/${date.month}/${date.year}';
                  
                  // Ajouter l'heure si disponible
                  if (exactPoint.timestamp != null) {
                    final time = exactPoint.timestamp!;
                    tooltipText += '\n⏰ ${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
                  }
                  
                  // Ajouter les nuances si disponibles
                  if (exactPoint.nuances.isNotEmpty) {
                    tooltipText += '\n\n💭 Nuances:';
                    for (final nuance in exactPoint.nuances.take(3)) {
                      tooltipText += '\n• $nuance';
                    }
                    if (exactPoint.nuances.length > 3) {
                      tooltipText += '\n• +${exactPoint.nuances.length - 3} autres...';
                    }
                  }

                  // Ajouter la note si disponible
                  if (exactPoint.note != null && exactPoint.note!.isNotEmpty) {
                    tooltipText += '\n\n📝 Note: ${exactPoint.note!.length > 50 ? '${exactPoint.note!.substring(0, 50)}...' : exactPoint.note}';
                  }

                  return LineTooltipItem(
                    tooltipText,
                    GoogleFonts.poppins(
                      color: emotion.color,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                      height: 1.4,
                    ),
                  );
                }).toList();
              },
            ),
          ),
        ),
      ),
    );
  }

  List<LineChartBarData> _buildLineChartData() {
    final now = DateTime.now();
    
    return _visibleEmotions.map((emotionKey) {
      final emotion = _findEmotion(emotionKey);
      if (emotion == null) return null;
      
      final dataPoints = _emotionTimelines[emotionKey] ?? [];
      
      // Créer un map date -> liste des points (pour gérer plusieurs points par jour)
      final Map<String, List<EmotionDataPoint>> datePointsMap = {};
      for (final point in dataPoints) {
        final dateKey = '${point.date.year}-${point.date.month}-${point.date.day}';
        datePointsMap.putIfAbsent(dateKey, () => []);
        datePointsMap[dateKey]!.add(point);
      }
      
      // Convertir en FlSpots avec moyennes
      final List<FlSpot> spots = [];
      for (int i = 0; i <= _selectedDays; i++) {
        final date = now.subtract(Duration(days: _selectedDays - i));
        final dateKey = '${date.year}-${date.month}-${date.day}';
        
        if (datePointsMap.containsKey(dateKey)) {
          final points = datePointsMap[dateKey]!;
          final avgIntensity = points.map((p) => p.intensity).reduce((a, b) => a + b) / points.length;
          spots.add(FlSpot(i.toDouble(), avgIntensity));
        }
      }
      
      return LineChartBarData(
        spots: spots,
        isCurved: true,
        curveSmoothness: 0.35,
        color: emotion.color,
        barWidth: 3,
        isStrokeCapRound: true,
        dotData: FlDotData(
          show: true,
          getDotPainter: (spot, percent, barData, index) {
            return FlDotCirclePainter(
              radius: 5,
              color: emotion.color,
              strokeWidth: 2,
              strokeColor: Colors.white,
            );
          },
        ),
        belowBarData: BarAreaData(
          show: true,
          gradient: LinearGradient(
            colors: [
              emotion.color.withOpacity(0.3),
              emotion.color.withOpacity(0.05),
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
      );
    }).whereType<LineChartBarData>().toList();
  }

  Widget _buildStatistics() {
    return Container(
      padding: const EdgeInsets.all(16),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                '📊 Statistics',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              Text(
                'over $_selectedDays days',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: Colors.grey[500],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ..._visibleEmotions.map((emotionKey) {
            final emotion = _findEmotion(emotionKey);
            if (emotion == null) return const SizedBox.shrink();
            
            final dataPoints = _emotionTimelines[emotionKey] ?? [];
            
            if (dataPoints.isEmpty) return const SizedBox.shrink();
            
            final intensities = dataPoints.map((p) => p.intensity).toList();
            final avgIntensity = intensities.reduce((a, b) => a + b) / intensities.length;
            final maxIntensity = intensities.reduce((a, b) => a > b ? a : b);
            final minIntensity = intensities.reduce((a, b) => a < b ? a : b);
            
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: emotion.color.withOpacity(0.05),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: emotion.color.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Image.asset(
                    emotion.iconPath,
                    width: 24,
                    height: 24,
                    errorBuilder: (_, __, ___) => Icon(emotion.icon, size: 24, color: emotion.color),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          emotion.name,
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: emotion.color,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            _buildStatChip('Avg', avgIntensity.toStringAsFixed(0), emotion.color),
                            const SizedBox(width: 8),
                            _buildStatChip('Max', maxIntensity.toString(), emotion.color),
                            const SizedBox(width: 8),
                            _buildStatChip('Min', minIntensity.toString(), emotion.color),
                            const SizedBox(width: 8),
                            _buildStatChip('Pts', dataPoints.length.toString(), emotion.color),
                          ],
                        ),
                      ],
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

  Widget _buildStatChip(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 10,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(width: 4),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
