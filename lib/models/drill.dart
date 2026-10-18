class DrillSpot {
  final double x;
  final double y;
  final String zoneName;
  final String category;
  final int targetShots;

  DrillSpot({
    required this.x,
    required this.y,
    required this.zoneName,
    required this.category,
    required this.targetShots,
  });

  Map<String, dynamic> toMap() {
    return {
      'x': x,
      'y': y,
      'zoneName': zoneName,
      'category': category,
      'targetShots': targetShots,
    };
  }

  factory DrillSpot.fromMap(Map<String, dynamic> map) {
    return DrillSpot(
      x: (map['x'] as num).toDouble(),
      y: (map['y'] as num).toDouble(),
      zoneName: map['zoneName'] as String? ?? 'Custom Spot',
      category: map['category'] as String? ?? 'Mixed Practice',
      targetShots: map['targetShots'] as int? ?? 5,
    );
  }
}

class CustomDrill {
  final int? id;
  final String name;
  final String description;
  final List<DrillSpot> spots;

  CustomDrill({
    this.id,
    required this.name,
    required this.description,
    required this.spots,
  });

  // Alias getter for screens expecting title
  String get title => name;

  int get totalShots => spots.fold(0, (sum, spot) => sum + spot.targetShots);

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'name': name,
      'description': description,
    };
  }

  factory CustomDrill.fromMap(Map<String, dynamic> map, List<DrillSpot> spots) {
    return CustomDrill(
      id: map['id'] as int?,
      name: (map['name'] ?? map['title'] ?? '') as String,
      description: (map['description'] ?? '') as String,
      spots: spots,
    );
  }
}