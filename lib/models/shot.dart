// lib/models/shot.dart
class Shot {
  final int? id;
  final int? sessionId;
  final double x;
  final double y;
  final bool isMade;
  final String category;
  final String zoneName;

  Shot({
    this.id,
    this.sessionId,
    required this.x,
    required this.y,
    required this.isMade,
    required this.category,
    required this.zoneName,
  });

  Map<String, dynamic> toMap(int sessionDbId) {
    return {
      'sessionId': sessionDbId,
      'x': x,
      'y': y,
      'isMade': isMade ? 1 : 0,
      'category': category,
      'zoneName': zoneName,
    };
  }

  factory Shot.fromMap(Map<String, dynamic> map) {
    return Shot(
      id: map['id'],
      sessionId: map['sessionId'],
      x: map['x'],
      y: map['y'],
      isMade: map['isMade'] == 1,
      category: map['category'],
      zoneName: map['zoneName'],
    );
  }
}