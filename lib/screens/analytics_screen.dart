import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/session.dart';
import '../models/shot.dart';
import '../services/database_service.dart';
import '../widgets/half_court.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  List<Shot> _allShots = [];
  List<PracticeSession> _sessions = [];
  bool _isLoading = true;
  bool _showHeatmap = true;

  @override
  void initState() {
    super.initState();
    _loadAnalyticsData();
  }

  Future<void> _loadAnalyticsData() async {
    setState(() => _isLoading = true);
    try {
      final shots = await DatabaseService.instance.getAllShots();
      final sessions = await DatabaseService.instance.getSessions();
      setState(() {
        _allShots = shots;
        _sessions = sessions.reversed.toList(); // Chronological order for graph
        _isLoading = false;
      });
    } catch (_) {
      setState(() => _isLoading = false);
    }
  }

  double _calculatePct(int makes, int total) {
    if (total == 0) return 0.0;
    return (makes / total) * 100;
  }

  Color _getAccuracyColor(double pct, int total) {
    if (total == 0) return Colors.grey;
    if (pct >= 50.0) return Colors.green.shade700;
    if (pct >= 35.0) return Colors.amber.shade800;
    return Colors.red.shade700;
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_allShots.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Analytics')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.bar_chart_rounded, size: 72, color: Colors.grey.shade400),
              const SizedBox(height: 12),
              const Text(
                'No shot data recorded yet.',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 6),
              const Text('Complete a shooting session to unlock charts.'),
            ],
          ),
        ),
      );
    }

    // Calculations
    final totalShots = _allShots.length;
    final totalMakes = _allShots.where((s) => s.isMade).length;
    final overallPct = _calculatePct(totalMakes, totalShots);

    final threeShots = _allShots.where((s) => s.category == 'Three-point').toList();
    final midShots = _allShots.where((s) => s.category == 'Mid-range').toList();
    final finishingShots = _allShots.where((s) => s.category == 'Finishing').toList();

    // Map spots for zone breakdown
    final Map<String, List<Shot>> zoneMap = {};
    for (var shot in _allShots) {
      zoneMap.putIfAbsent(shot.zoneName, () => []).add(shot);
    }
    final sortedZones = zoneMap.keys.toList()
      ..sort((a, b) => zoneMap[b]!.length.compareTo(zoneMap[a]!.length));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Analytics & Trends'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadAnalyticsData,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Overall Accuracy Card
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              color: Colors.deepOrange.shade50,
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  children: [
                    const Text(
                      'CAREER FIELD GOAL ACCURACY',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.1,
                        color: Colors.deepOrange,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '${overallPct.toStringAsFixed(1)}%',
                      style: TextStyle(
                        fontSize: 42,
                        fontWeight: FontWeight.bold,
                        color: _getAccuracyColor(overallPct, totalShots),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$totalMakes Made / ${totalShots - totalMakes} Missed ($totalShots Total)',
                      style: TextStyle(color: Colors.grey.shade700, fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // FG% Trend Line Graph
            if (_sessions.length >= 2) ...[
              const Text(
                'FG% Progress Over Time',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              Card(
                elevation: 1,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.only(right: 20, left: 10, top: 20, bottom: 12),
                  child: SizedBox(
                    height: 200,
                    child: LineChart(
                      LineChartData(
                        gridData: FlGridData(
                          show: true,
                          drawVerticalLine: false,
                          getDrawingHorizontalLine: (value) => FlLine(
                            color: Colors.grey.shade200,
                            strokeWidth: 1,
                          ),
                        ),
                        titlesData: FlTitlesData(
                          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                          leftTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 35,
                              getTitlesWidget: (val, meta) => Text(
                                '${val.toInt()}%',
                                style: const TextStyle(fontSize: 10, color: Colors.grey),
                              ),
                            ),
                          ),
                          bottomTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                        ),
                        borderData: FlBorderData(show: false),
                        minY: 0,
                        maxY: 100,
                        lineBarsData: [
                          LineChartBarData(
                            spots: _sessions.asMap().entries.map((entry) {
                              final idx = entry.key.toDouble();
                              final sess = entry.value;
                              final tot = sess.shotsMade + sess.shotsMissed;
                              final pct = tot == 0 ? 0.0 : (sess.shotsMade / tot) * 100;
                              return FlSpot(idx, pct);
                            }).toList(),
                            isCurved: true,
                            color: Colors.deepOrange,
                            barWidth: 3,
                            isStrokeCapRound: true,
                            dotData: const FlDotData(show: true),
                            belowBarData: BarAreaData(
                              show: true,
                              color: Colors.deepOrange.withOpacity(0.15),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],

            // Shot Category Volume Comparison
            const Text(
              'Shot Volume by Category',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Card(
              elevation: 1,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: SizedBox(
                  height: 160,
                  child: BarChart(
                    BarChartData(
                      borderData: FlBorderData(show: false),
                      titlesData: FlTitlesData(
                        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            getTitlesWidget: (val, meta) {
                              switch (val.toInt()) {
                                case 0:
                                  return const Text('3PT', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12));
                                case 1:
                                  return const Text('Mid-Range', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12));
                                case 2:
                                  return const Text('Finishing', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12));
                                default:
                                  return const Text('');
                              }
                            },
                          ),
                        ),
                      ),
                      barGroups: [
                        BarChartGroupData(
                          x: 0,
                          barRods: [
                            BarChartRodData(
                              toY: threeShots.length.toDouble(),
                              color: Colors.deepOrange,
                              width: 22,
                              borderRadius: BorderRadius.circular(6),
                            ),
                          ],
                        ),
                        BarChartGroupData(
                          x: 1,
                          barRods: [
                            BarChartRodData(
                              toY: midShots.length.toDouble(),
                              color: Colors.blue.shade700,
                              width: 22,
                              borderRadius: BorderRadius.circular(6),
                            ),
                          ],
                        ),
                        BarChartGroupData(
                          x: 2,
                          barRods: [
                            BarChartRodData(
                              toY: finishingShots.length.toDouble(),
                              color: Colors.green.shade700,
                              width: 22,
                              borderRadius: BorderRadius.circular(6),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Heatmap View
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Overall Shot Heatmap',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                FilterChip(
                  label: const Text('Heatmap'),
                  selected: _showHeatmap,
                  onSelected: (val) => setState(() => _showHeatmap = val),
                  selectedColor: Colors.orange.shade100,
                  checkmarkColor: Colors.deepOrange,
                ),
              ],
            ),
            const SizedBox(height: 8),

            HalfCourtWidget(
              shots: _allShots,
              showHeatmap: _showHeatmap,
            ),
            const SizedBox(height: 24),

            // Zone Breakdown List
            const Text(
              'Zone Breakdown',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),

            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: sortedZones.length,
              itemBuilder: (context, index) {
                final zoneName = sortedZones[index];
                final zoneShots = zoneMap[zoneName]!;
                final makes = zoneShots.where((s) => s.isMade).length;
                final total = zoneShots.length;
                final zonePct = _calculatePct(makes, total);
                final color = _getAccuracyColor(zonePct, total);

                return Card(
                  margin: const EdgeInsets.only(bottom: 8.0),
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(zoneName, style: const TextStyle(fontWeight: FontWeight.bold)),
                            Text('$makes / $total (${zonePct.toStringAsFixed(1)}%)',
                                style: TextStyle(fontWeight: FontWeight.bold, color: color)),
                          ],
                        ),
                        const SizedBox(height: 6),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: zonePct / 100,
                            minHeight: 6,
                            backgroundColor: Colors.grey.shade200,
                            valueColor: AlwaysStoppedAnimation<Color>(color),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}