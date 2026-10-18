class PracticeSession {
  final int? id;
  final DateTime dateTime;
  final String category;
  final int shotsMade;
  final int shotsMissed;

  PracticeSession({
    this.id,
    required this.dateTime,
    required this.category,
    required this.shotsMade,
    required this.shotsMissed,
  });

  int get totalAttempts => shotsMade + shotsMissed;

  double get shootingPercentage =>
      totalAttempts == 0 ? 0.0 : (shotsMade / totalAttempts) * 100;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'dateTime': dateTime.toIso8601String(),
      'category': category,
      'shotsMade': shotsMade,
      'shotsMissed': shotsMissed,
    };
  }

  factory PracticeSession.fromMap(Map<String, dynamic> map) {
    return PracticeSession(
      id: map['id'] as int?,
      dateTime: DateTime.parse(map['dateTime'] as String),
      category: map['category'] as String,
      shotsMade: map['shotsMade'] as int,
      shotsMissed: map['shotsMissed'] as int,
    );
  }
}