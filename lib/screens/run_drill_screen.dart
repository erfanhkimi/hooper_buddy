import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import '../models/drill.dart';
import '../models/session.dart';
import '../models/shot.dart';
import '../services/database_service.dart';
import '../widgets/half_court.dart';

class RunDrillScreen extends StatefulWidget {
  final CustomDrill drill;

  const RunDrillScreen({super.key, required this.drill});

  @override
  State<RunDrillScreen> createState() => _RunDrillScreenState();
}

class _RunDrillScreenState extends State<RunDrillScreen> {
  int _currentSpotIndex = 0;
  int _shotsAttemptedAtSpot = 0;
  final List<Shot> _recordedShots = [];

  AudioPlayer? _audioPlayer;

  @override
  void initState() {
    super.initState();
    try {
      _audioPlayer = AudioPlayer();
    } catch (_) {}
  }

  @override
  void dispose() {
    _audioPlayer?.dispose();
    super.dispose();
  }

  Future<void> _playSound(bool isMade) async {
    if (_audioPlayer == null) return;
    try {
      await _audioPlayer!.stop();
      if (isMade) {
        await _audioPlayer!.play(AssetSource('sounds/swish.mp3'));
      } else {
        await _audioPlayer!.play(AssetSource('sounds/miss.mp3'));
      }
    } catch (_) {}
  }

  void _recordDrillShot(bool isMade) {
    _playSound(isMade);

    final spot = widget.drill.spots[_currentSpotIndex];

    setState(() {
      _recordedShots.add(Shot(
        x: spot.x,
        y: spot.y,
        isMade: isMade,
        category: spot.category,
        zoneName: spot.zoneName,
      ));
      _shotsAttemptedAtSpot++;

      // Advance spot when target reached
      if (_shotsAttemptedAtSpot >= spot.targetShots) {
        if (_currentSpotIndex < widget.drill.spots.length - 1) {
          _currentSpotIndex++;
          _shotsAttemptedAtSpot = 0;
        } else {
          _finishDrill();
        }
      }
    });
  }

  Future<void> _finishDrill() async {
    final makes = _recordedShots.where((s) => s.isMade).length;
    final misses = _recordedShots.length - makes;

    final session = PracticeSession(
      dateTime: DateTime.now(),
      category: widget.drill.name,
      shotsMade: makes,
      shotsMissed: misses,
    );

    await DatabaseService.instance.insertSessionWithShots(session, _recordedShots);

    if (mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) {
          final pct = ((makes / _recordedShots.length) * 100).toStringAsFixed(1);
          return AlertDialog(
            title: const Text('🏆 Drill Completed!'),
            content: Text('Drill: ${widget.drill.name}\nScore: $makes / ${_recordedShots.length} ($pct%)'),
            actions: [
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context); // Close dialog
                  Navigator.pop(context, true); // Return to workouts
                },
                child: const Text('Finish'),
              ),
            ],
          );
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final spot = widget.drill.spots[_currentSpotIndex];
    final activeOffset = Offset(spot.x, spot.y);

    return Scaffold(
      appBar: AppBar(title: Text(widget.drill.name)),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Current Target Spot Banner
            Card(
              color: Colors.deepOrange.shade50,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Spot ${_currentSpotIndex + 1} of ${widget.drill.spots.length}',
                            style: const TextStyle(color: Colors.deepOrange, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        Text(spot.zoneName, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    Text(
                      '$_shotsAttemptedAtSpot / ${spot.targetShots}',
                      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Half Court Highlighting Target Location
            Expanded(
              child: HalfCourtWidget(
                shots: _recordedShots,
                selectedPosition: activeOffset,
              ),
            ),
            const SizedBox(height: 16),

            // Quick Shot Input Bar
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red.shade700,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () => _recordDrillShot(false),
                    icon: const Icon(Icons.close, color: Colors.white),
                    label: const Text('MISS', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green.shade700,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () => _recordDrillShot(true),
                    icon: const Icon(Icons.check, color: Colors.white),
                    label: const Text('MAKE', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}