import 'dart:async';
import 'package:flutter/material.dart';
import '../models/session.dart';
import '../models/shot.dart';
import '../services/database_service.dart';
import '../widgets/half_court.dart';
import '../services/audio_service.dart';

class SpotConfig {
  final String name;
  final double defaultX;
  final double defaultY;

  const SpotConfig({
    required this.name,
    required this.defaultX,
    required this.defaultY,
  });
}

class DrillScreen extends StatefulWidget {
  const DrillScreen({super.key});

  @override
  State<DrillScreen> createState() => _DrillScreenState();
}

class _DrillScreenState extends State<DrillScreen> {
  // 5 standard 3PT challenge spots (5 shots per spot = 25 total shots)
  final List<SpotConfig> _spots = const [
    SpotConfig(name: 'Left Corner 3', defaultX: 0.035, defaultY: 0.14),
    SpotConfig(name: 'Left Wing 3', defaultX: 0.15, defaultY: 0.65),
    SpotConfig(name: 'Center 3', defaultX: 0.50, defaultY: 0.85),
    SpotConfig(name: 'Right Wing 3', defaultX: 0.85, defaultY: 0.65),
    SpotConfig(name: 'Right Corner 3', defaultX: 0.965, defaultY: 0.14),
  ];

  static const int _shotsPerSpot = 5;
  int _currentSpotIndex = 0;
  int _shotCountInSpot = 0;

  final List<Shot> _shots = [];
  bool _isSaving = false;

  // Timer state
  final Stopwatch _stopwatch = Stopwatch();
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _stopwatch.start();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _stopwatch.stop();
    super.dispose();
  }

  String _formatElapsedTime() {
    final seconds = _stopwatch.elapsed.inSeconds;
    final mins = (seconds ~/ 60).toString().padLeft(2, '0');
    final secs = (seconds % 60).toString().padLeft(2, '0');
    return '$mins:$secs';
  }

  void _recordShot(bool isMade) {
    if (_currentSpotIndex >= _spots.length) return;

    // Trigger Audio & Haptic Feedback
    if (isMade) {
      AudioService.playMake();
    } else {
      AudioService.playMiss();
    }

    final currentSpot = _spots[_currentSpotIndex];

    final newShot = Shot(
      x: currentSpot.defaultX,
      y: currentSpot.defaultY,
      isMade: isMade,
      category: 'Three-point',
      zoneName: currentSpot.name,
    );

    setState(() {
      _shots.add(newShot);
      _shotCountInSpot++;

      if (_shotCountInSpot >= _shotsPerSpot) {
        _shotCountInSpot = 0;
        _currentSpotIndex++;
      }
    });

    if (_currentSpotIndex >= _spots.length) {
      _stopwatch.stop();
      _showCompletionDialog();
    }
  }

  Future<void> _saveDrillSession() async {
    setState(() => _isSaving = true);

    final makes = _shots.where((s) => s.isMade).length;
    final misses = _shots.length - makes;

    final session = PracticeSession(
      dateTime: DateTime.now(),
      category: '5-Spot 3PT Challenge',
      shotsMade: makes,
      shotsMissed: misses,
    );

    await DatabaseService.instance.insertSessionWithShots(session, _shots);

    if (mounted) {
      Navigator.pop(context); // Close dialog
      Navigator.pop(context, true); // Return to home with refresh signal
    }
  }

  void _showCompletionDialog() {
    final makes = _shots.where((s) => s.isMade).length;
    final pct = ((makes / _shots.length) * 100).round();
    final elapsed = _formatElapsedTime();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('🏆 Drill Complete!'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Score: $makes / ${_shots.length} ($pct%)',
                style:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text('Time Elapsed: $elapsed'),
            Text(
                'Pace: ${(_shots.length / (_stopwatch.elapsed.inSeconds / 60)).toStringAsFixed(1)} shots/min'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Review Shots'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            onPressed: _isSaving ? null : _saveDrillSession,
            child: _isSaving
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(color: Colors.white),
                  )
                : const Text('Save Workout',
                    style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isFinished = _currentSpotIndex >= _spots.length;
    final currentSpot =
        isFinished ? null : _spots[_currentSpotIndex];

    final makes = _shots.where((s) => s.isMade).length;
    final totalShots = _shots.length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('5-Spot 3PT Challenge'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: Center(
              child: Row(
                children: [
                  const Icon(Icons.timer, size: 18),
                  const SizedBox(width: 4),
                  Text(
                    _formatElapsedTime(),
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Current Target Spot Card
            Card(
              color: isFinished ? Colors.green.shade50 : Colors.orange.shade50,
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Text(
                      isFinished
                          ? 'DRILL COMPLETED'
                          : 'SPOT ${_currentSpotIndex + 1} OF ${_spots.length}',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: isFinished
                            ? Colors.green.shade800
                            : Colors.orange.shade900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      isFinished ? 'Great Hustle!' : currentSpot!.name,
                      style: const TextStyle(
                          fontSize: 22, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      isFinished
                          ? 'Total Makes: $makes / $totalShots'
                          : 'Shot ${_shotCountInSpot + 1} of $_shotsPerSpot at this spot',
                      style: const TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Court Diagram with Recorded Shots
            HalfCourtWidget(
              shots: _shots,
              showHeatmap: false,
              onCourtTapped: null,
            ),
            const SizedBox(height: 16),

            // Rapid Action Buttons (Make / Miss)
            if (!isFinished)
              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 60,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red.shade700,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: () => _recordShot(false),
                        icon: const Icon(Icons.close, color: Colors.white),
                        label: const Text(
                          'MISS',
                          style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: SizedBox(
                      height: 60,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green.shade700,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: () => _recordShot(true),
                        icon: const Icon(Icons.check, color: Colors.white),
                        label: const Text(
                          'MAKE',
                          style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white),
                        ),
                      ),
                    ),
                  ),
                ],
              )
            else
              SizedBox(
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: _showCompletionDialog,
                  child: const Text(
                    'Save Session Summary',
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}