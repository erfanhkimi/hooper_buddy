import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../models/drill.dart';
import '../services/database_service.dart';
import '../widgets/half_court.dart';

class CreateDrillScreen extends StatefulWidget {
  const CreateDrillScreen({super.key});

  @override
  State<CreateDrillScreen> createState() => _CreateDrillScreenState();
}

class _CreateDrillScreenState extends State<CreateDrillScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();

  final List<DrillSpot> _spots = [];
  Offset? _tempSelectedPos;
  int _tempShots = 5;

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Map<String, String> _getShotInfo(double x, double y) {
    final Offset hoopCenter = const Offset(0.5, 0.105);
    final double dx = x - hoopCenter.dx;
    final double dy = y - hoopCenter.dy;
    final double dist = math.sqrt(dx * dx + dy * dy);

    if (dist <= 0.08) return {'zone': 'Restricted Area', 'category': 'Finishing'};
    if (x >= 0.34 && x <= 0.66 && y <= 0.38) return {'zone': 'In The Paint', 'category': 'Finishing'};

    if (x <= 0.07 && y <= 0.28) return {'zone': 'Left Corner 3', 'category': 'Three-point'};
    if (x >= 0.93 && y <= 0.28) return {'zone': 'Right Corner 3', 'category': 'Three-point'};

    if (y <= 0.28) {
      return x < 0.34
          ? {'zone': 'Left Baseline Mid-Range', 'category': 'Mid-range'}
          : {'zone': 'Right Baseline Mid-Range', 'category': 'Mid-range'};
    }

    if (dist >= 0.58) {
      final double leftDividerX = 0.30 - ((y - 0.525) * (0.10 / 0.475));
      final double rightDividerX = 0.70 + ((y - 0.525) * (0.10 / 0.475));
      if (x < leftDividerX) return {'zone': 'Left Wing Deep 3', 'category': 'Three-point'};
      if (x > rightDividerX) return {'zone': 'Right Wing Deep 3', 'category': 'Three-point'};
      return {'zone': 'Center Deep 3', 'category': 'Three-point'};
    }

    if (dist >= 0.464) {
      final double leftDividerX = 0.30 - ((y - 0.525) * (0.10 / 0.475));
      final double rightDividerX = 0.70 + ((y - 0.525) * (0.10 / 0.475));
      if (x < leftDividerX) return {'zone': 'Left Wing 3', 'category': 'Three-point'};
      if (x > rightDividerX) return {'zone': 'Right Wing 3', 'category': 'Three-point'};
      return {'zone': 'Center 3', 'category': 'Three-point'};
    }

    final double leftMidX = 0.34 - ((y - 0.38) * (0.16 / 0.09));
    final double rightMidX = 0.66 + ((y - 0.38) * (0.16 / 0.09));
    if (x < leftMidX) return {'zone': 'Left Wing Mid-Range', 'category': 'Mid-range'};
    if (x > rightMidX) return {'zone': 'Right Wing Mid-Range', 'category': 'Mid-range'};
    return {'zone': 'Center Mid-Range', 'category': 'Mid-range'};
  }

  void _onCourtTap(double x, double y) {
    final info = _getShotInfo(x, y);
    setState(() {
      _tempSelectedPos = Offset(x, y);
    });

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        int spotTarget = _tempShots;
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Add Spot: ${info['zone']}',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('Shots to attempt: ', style: TextStyle(fontSize: 16)),
                      IconButton(
                        icon: const Icon(Icons.remove_circle_outline),
                        onPressed: spotTarget > 1
                            ? () => setModalState(() => spotTarget--)
                            : null,
                      ),
                      Text('$spotTarget', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      IconButton(
                        icon: const Icon(Icons.add_circle_outline),
                        onPressed: () => setModalState(() => spotTarget++),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.deepOrange,
                      minimumSize: const Size.fromHeight(48),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    onPressed: () {
                      setState(() {
                        _spots.add(DrillSpot(
                          x: x,
                          y: y,
                          zoneName: info['zone']!,
                          category: info['category']!,
                          targetShots: spotTarget,
                        ));
                        _tempSelectedPos = null;
                      });
                      Navigator.pop(context);
                    },
                    child: const Text('Confirm Spot', style: TextStyle(color: Colors.white, fontSize: 16)),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _saveDrill() async {
    if (!_formKey.currentState!.validate()) return;
    if (_spots.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Add at least 1 spot on the court to build a drill!')),
      );
      return;
    }

    final drill = CustomDrill(
      name: _nameController.text.trim(),
      description: _descriptionController.text.trim().isEmpty
          ? '${_spots.length} spots • ${_spots.fold(0, (sum, s) => sum + s.targetShots)} total shots'
          : _descriptionController.text.trim(),
      spots: _spots,
    );

    await DatabaseService.instance.insertCustomDrill(drill);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Custom Drill Created!')),
      );
      Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Custom Drill Builder')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: 'Drill Name',
                  hintText: 'e.g. 3PT Wing & Corner Circuit',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Please enter a name' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _descriptionController,
                decoration: InputDecoration(
                  labelText: 'Description (Optional)',
                  hintText: 'e.g. 5 shots from each corner and wing',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Tap Court to Set Spot Order:',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),

              HalfCourtWidget(
                shots: const [],
                selectedPosition: _tempSelectedPos,
                onCourtTapped: _onCourtTap,
              ),
              const SizedBox(height: 16),

              if (_spots.isNotEmpty) ...[
                const Text('Drill Sequence:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 8),
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _spots.length,
                  itemBuilder: (context, index) {
                    final spot = _spots[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 6),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Colors.deepOrange,
                          child: Text('${index + 1}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        ),
                        title: Text(spot.zoneName, style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text('${spot.category} • ${spot.targetShots} attempts'),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete_outline, color: Colors.red),
                          onPressed: () {
                            setState(() {
                              _spots.removeAt(index);
                            });
                          },
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 16),
              ],

              SizedBox(
                height: 52,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepOrange,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: _saveDrill,
                  child: const Text('Save & Create Drill', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}