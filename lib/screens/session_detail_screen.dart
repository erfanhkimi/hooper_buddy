import 'dart:io' as io;
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../models/session.dart';
import '../models/shot.dart';
import '../services/database_service.dart';
import '../widgets/half_court.dart';

class SessionDetailScreen extends StatefulWidget {
  final PracticeSession session;

  const SessionDetailScreen({super.key, required this.session});

  @override
  State<SessionDetailScreen> createState() => _SessionDetailScreenState();
}

class _SessionDetailScreenState extends State<SessionDetailScreen> {
  final GlobalKey _shareKey = GlobalKey();
  List<Shot> _shots = [];
  bool _isLoading = true;
  bool _showHeatmap = false;
  bool _isSharing = false;

  @override
  void initState() {
    super.initState();
    _loadSessionShots();
  }

  Future<void> _loadSessionShots() async {
    if (widget.session.id == null) {
      setState(() => _isLoading = false);
      return;
    }

    final shots = await DatabaseService.instance.getShotsForSession(widget.session.id!);
    setState(() {
      _shots = shots;
      _isLoading = false;
    });
  }

  Future<void> _shareWorkoutCard() async {
    setState(() => _isSharing = true);
    try {
      // Find the RepaintBoundary render object
      final boundary =
          _shareKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) return;

      // Capture high-res screenshot (pixelRatio: 3.0 for crisp detail)
      final ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) return;

      final Uint8List pngBytes = byteData.buffer.asUint8List();

      final totalShots = widget.session.shotsMade + widget.session.shotsMissed;
      final pct = totalShots == 0
          ? 0
          : ((widget.session.shotsMade / totalShots) * 100).round();

      final shareText =
          '🔥 Just finished a ${widget.session.category} session on Hooper Buddy! '
          '${widget.session.shotsMade}/$totalShots Made ($pct%) 🏀';

      if (kIsWeb) {
        final xFile = XFile.fromData(
          pngBytes,
          name: 'hooper_buddy_workout.png',
          mimeType: 'image/png',
        );
        await Share.shareXFiles([xFile], text: shareText);
      } else {
        final tempDir = await getTemporaryDirectory();
        final filePath =
            '${tempDir.path}/hooper_buddy_${DateTime.now().millisecondsSinceEpoch}.png';
        final file = io.File(filePath);
        await file.writeAsBytes(pngBytes);

        await Share.shareXFiles([XFile(filePath)], text: shareText);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to share card: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSharing = false);
    }
  }

  Future<void> _confirmDelete() async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Session?'),
        content: const Text(
          'Are you sure you want to delete this session? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('CANCEL'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('DELETE', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true && widget.session.id != null) {
      await DatabaseService.instance.deleteSession(widget.session.id!);
      if (mounted) {
        Navigator.pop(context, true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final totalShots = widget.session.shotsMade + widget.session.shotsMissed;
    final pct = totalShots == 0
        ? 0
        : ((widget.session.shotsMade / totalShots) * 100).round();

    final formattedDate = widget.session.dateTime
        .toString()
        .split('.')[0]
        .replaceAll('T', ' ');

    final Map<String, List<Shot>> zoneMap = {};
    for (var shot in _shots) {
      zoneMap.putIfAbsent(shot.zoneName, () => []).add(shot);
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.session.category),
        actions: [
          IconButton(
            icon: _isSharing
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.share_rounded),
            tooltip: 'Share Workout Card',
            onPressed: _isSharing ? null : _shareWorkoutCard,
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.red),
            tooltip: 'Delete Workout',
            onPressed: _confirmDelete,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // --- EXPORTABLE WORKOUT CARD BOUNDARY ---
                  RepaintBoundary(
                    key: _shareKey,
                    child: Container(
                      padding: const EdgeInsets.all(16.0),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 10,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Header Branding & Date
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: const [
                                  Icon(Icons.sports_basketball,
                                      color: Colors.deepOrange, size: 24),
                                  SizedBox(width: 6),
                                  Text(
                                    'HOOPER BUDDY',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                      letterSpacing: 1.2,
                                      color: Colors.deepOrange,
                                    ),
                                  ),
                                ],
                              ),
                              Text(
                                formattedDate,
                                style: const TextStyle(
                                  color: Colors.grey,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                          const Divider(height: 20),

                          // Session Performance Stats Banner
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    widget.session.category,
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '${widget.session.shotsMade} / $totalShots Shots Made',
                                    style: TextStyle(
                                      color: Colors.grey.shade700,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: pct >= 50
                                      ? Colors.green.shade700
                                      : (pct >= 35
                                          ? Colors.amber.shade800
                                          : Colors.red.shade700),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  '$pct%',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),

                          // Embedded Half Court Shot Map
                          HalfCourtWidget(
                            shots: _shots,
                            showHeatmap: _showHeatmap,
                          ),
                        ],
                      ),
                    ),
                  ),
                  // --- END EXPORTABLE CARD ---

                  const SizedBox(height: 16),

                  // Interactive Map Controls & Heatmap Toggle
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Shot Visualization',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      FilterChip(
                        label: const Text('Heatmap Mode'),
                        selected: _showHeatmap,
                        onSelected: (val) => setState(() => _showHeatmap = val),
                        selectedColor: Colors.orange.shade100,
                        checkmarkColor: Colors.deepOrange,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Share Button CTA
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.deepOrange,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: _isSharing ? null : _shareWorkoutCard,
                    icon: const Icon(Icons.share_rounded, color: Colors.white),
                    label: const Text(
                      'Share Workout Card',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Zone Performance Stats List
                  const Text(
                    'Zone Performance Breakdown',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),

                  if (zoneMap.isEmpty)
                    const Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Text(
                        'No individual shot locations recorded for this session.',
                        style: TextStyle(color: Colors.grey),
                      ),
                    )
                  else
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: zoneMap.length,
                      itemBuilder: (context, index) {
                        final zoneName = zoneMap.keys.elementAt(index);
                        final zoneShots = zoneMap[zoneName]!;
                        final makes = zoneShots.where((s) => s.isMade).length;
                        final total = zoneShots.length;
                        final zonePct = ((makes / total) * 100).round();

                        return Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: ListTile(
                            title: Text(
                              zoneName,
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            subtitle: Text('$makes / $total Made'),
                            trailing: Text(
                              '$zonePct%',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: zonePct >= 50
                                    ? Colors.green.shade700
                                    : (zonePct >= 35
                                        ? Colors.amber.shade800
                                        : Colors.red.shade700),
                              ),
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