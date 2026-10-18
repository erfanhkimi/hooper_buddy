import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import '../models/session.dart';
import '../models/shot.dart';
import '../services/database_service.dart';
import '../widgets/half_court.dart';
import '../services/audio_service.dart';

class SessionScreen extends StatefulWidget {
  const SessionScreen({super.key});

  @override
  State<SessionScreen> createState() => _SessionScreenState();
}

class _SessionScreenState extends State<SessionScreen> {
  final List<Shot> _shots = [];
  AudioPlayer? _audioPlayer;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _initAudioPlayer();
  }

  void _initAudioPlayer() {
    try {
      _audioPlayer = AudioPlayer();
    } catch (e) {
      debugPrint('AudioPlayer init skipped: $e');
    }
  }

  @override
  void dispose() {
    _audioPlayer?.dispose();
    super.dispose();
  }

  Future<void> _playSound(bool isMade) async {
  // Check if sound feature is globally toggled on
  if (!AudioService.instance.isSoundEnabled.value || _audioPlayer == null) {
    return;
  }

  try {
    await _audioPlayer!.stop();
    if (isMade) {
      await _audioPlayer!.play(AssetSource('sounds/swish.mp3'));
    } else {
      await _audioPlayer!.play(AssetSource('sounds/miss.mp3'));
    }
  } catch (e) {
    debugPrint('Audio playback error: $e');
  }
}

  void _recordShot(double x, double y, bool isMade, String category, String zoneName) {
    _playSound(isMade);
    setState(() {
      _shots.add(Shot(
        x: x,
        y: y,
        isMade: isMade,
        category: category,
        zoneName: zoneName,
      ));
    });
  }

  Map<String, String> _getShotInfo(double x, double y) {
    final Offset hoopCenter = const Offset(0.5, 0.105);
    final double dx = x - hoopCenter.dx;
    final double dy = y - hoopCenter.dy;
    final double dist = math.sqrt(dx * dx + dy * dy);

    // 1. Restricted Area & Paint / Key
    if (dist <= 0.08) {
      return {'zone': 'Restricted Area', 'category': 'Finishing'};
    }
    if (x >= 0.34 && x <= 0.66 && y <= 0.38) {
      return {'zone': 'In The Paint', 'category': 'Finishing'};
    }

    // 2. Corner 3s
    if (x <= 0.07 && y <= 0.28) {
      return {'zone': 'Left Corner 3', 'category': 'Three-point'};
    }
    if (x >= 0.93 && y <= 0.28) {
      return {'zone': 'Right Corner 3', 'category': 'Three-point'};
    }

    // 3. Baseline Mid-Ranges
    if (y <= 0.28) {
      if (x < 0.34) {
        return {'zone': 'Left Baseline Mid-Range', 'category': 'Mid-range'};
      } else {
        return {'zone': 'Right Baseline Mid-Range', 'category': 'Mid-range'};
      }
    }

    // 4. Deep 3-Pointers (dist >= 0.58)
    if (dist >= 0.58) {
      final double leftDividerX = 0.30 - ((y - 0.525) * (0.10 / 0.475));
      final double rightDividerX = 0.70 + ((y - 0.525) * (0.10 / 0.475));

      if (x < leftDividerX) {
        return {'zone': 'Left Wing Deep 3', 'category': 'Three-point'};
      } else if (x > rightDividerX) {
        return {'zone': 'Right Wing Deep 3', 'category': 'Three-point'};
      } else {
        return {'zone': 'Center Deep 3', 'category': 'Three-point'};
      }
    }

    // 5. Standard 3-Pointers (0.464 <= dist < 0.58)
    if (dist >= 0.464) {
      final double leftDividerX = 0.30 - ((y - 0.525) * (0.10 / 0.475));
      final double rightDividerX = 0.70 + ((y - 0.525) * (0.10 / 0.475));

      if (x < leftDividerX) {
        return {'zone': 'Left Wing 3', 'category': 'Three-point'};
      } else if (x > rightDividerX) {
        return {'zone': 'Right Wing 3', 'category': 'Three-point'};
      } else {
        return {'zone': 'Center 3', 'category': 'Three-point'};
      }
    }

    // 6. Mid-Range Zones
    final double leftMidX = 0.34 - ((y - 0.38) * (0.16 / 0.09));
    final double rightMidX = 0.66 + ((y - 0.38) * (0.16 / 0.09));

    if (x < leftMidX) {
      return {'zone': 'Left Wing Mid-Range', 'category': 'Mid-range'};
    } else if (x > rightMidX) {
      return {'zone': 'Right Wing Mid-Range', 'category': 'Mid-range'};
    } else {
      return {'zone': 'Center Mid-Range', 'category': 'Mid-range'};
    }
  }

  void _showShotDialog(double x, double y) {
    final info = _getShotInfo(x, y);
    final String zoneName = info['zone']!;
    final String category = info['category']!;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Column(
            children: [
              const Icon(Icons.location_on, color: Colors.deepOrange, size: 36),
              const SizedBox(height: 8),
              Text(
                zoneName,
                textAlign: TextAlign.center,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
              ),
              const SizedBox(height: 6),
              Chip(
                label: Text(
                  category,
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
                backgroundColor: category == 'Three-point'
                    ? Colors.deepOrange
                    : (category == 'Mid-range' ? Colors.blue.shade700 : Colors.green.shade700),
              ),
            ],
          ),
          content: const Text(
            'Record shot result:',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 15, color: Colors.grey),
          ),
          actionsAlignment: MainAxisAlignment.spaceEvenly,
          actions: [
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.shade700,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () {
                _recordShot(x, y, false, category, zoneName);
                Navigator.pop(context);
              },
              icon: const Icon(Icons.close, color: Colors.white),
              label: const Text('MISS', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
            ),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green.shade700,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () {
                _recordShot(x, y, true, category, zoneName);
                Navigator.pop(context);
              },
              icon: const Icon(Icons.check, color: Colors.white),
              label: const Text('MAKE', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
            ),
          ],
        );
      },
    );
  }

  void _undoLastShot() {
    if (_shots.isNotEmpty) {
      setState(() {
        _shots.removeLast();
      });
    }
  }

  String _determineSessionCategory() {
    if (_shots.isEmpty) return 'Practice Session';
    final categories = _shots.map((s) => s.category).toSet();
    if (categories.length == 1) {
      return categories.first;
    }
    return 'Mixed Practice';
  }

  Future<void> _saveSession() async {
    if (_shots.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Record at least 1 shot before saving!')),
      );
      return;
    }

    setState(() => _isSaving = true);

    final makes = _shots.where((s) => s.isMade).length;
    final misses = _shots.length - makes;
    final sessionCategory = _determineSessionCategory();

    final session = PracticeSession(
      dateTime: DateTime.now(),
      category: sessionCategory,
      shotsMade: makes,
      shotsMissed: misses,
    );

    await DatabaseService.instance.insertSessionWithShots(session, _shots);

    if (mounted) {
      Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final makes = _shots.where((s) => s.isMade).length;
    final total = _shots.length;
    final pct = total == 0 ? 0 : ((makes / total) * 100).round();
    final currentCategoryLabel = _determineSessionCategory();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Free Shooting Session'),
        actions: [
          if (_shots.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.undo),
              tooltip: 'Undo Last Shot',
              onPressed: _undoLastShot,
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              color: Colors.orange.shade50,
              elevation: 1,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          currentCategoryLabel,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.deepOrange),
                        ),
                        const SizedBox(height: 2),
                        Text('Total Shots: $total', style: const TextStyle(color: Colors.grey, fontSize: 12)),
                      ],
                    ),
                    Text(
                      '$makes / $total ($pct%)',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),

            Container(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
              decoration: BoxDecoration(
                color: Colors.amber.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                '👇 Tap anywhere on the court to open shot input pop-up',
                textAlign: TextAlign.center,
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Colors.amber),
              ),
            ),
            const SizedBox(height: 12),

            HalfCourtWidget(
              shots: _shots,
              showHeatmap: false,
              onCourtTapped: (x, y) => _showShotDialog(x, y),
            ),
            const SizedBox(height: 20),

            SizedBox(
              height: 52,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: _isSaving ? null : _saveSession,
                child: _isSaving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(color: Colors.white),
                      )
                    : const Text(
                        'Finish & Save Workout',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}