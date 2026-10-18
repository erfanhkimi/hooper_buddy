import 'dart:math';
import 'package:flutter/foundation.dart'; // Provides kIsWeb platform check
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/session.dart';
import '../models/shot.dart';
import '../models/drill.dart';

class DatabaseService {
  static final DatabaseService instance = DatabaseService._init();
  static Database? _database;

  // In-memory web fallback state
  final List<PracticeSession> _webSessions = [];
  final List<Shot> _webShots = [];
  final List<CustomDrill> _webDrills = [];
  int _webSessionCounter = 1;
  int _webDrillCounter = 1;

  DatabaseService._init();

  Future<Database?> get database async {
    if (kIsWeb) return null; // Bypass native C-library calls on Web
    if (_database != null) return _database!;
    _database = await _initDB('hooper_buddy.db');
    return _database;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 3,
      onCreate: _createDB,
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await db.execute('''
            CREATE TABLE shots (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              sessionId INTEGER,
              x REAL,
              y REAL,
              isMade INTEGER,
              category TEXT,
              zoneName TEXT
            )
          ''');
        }
        if (oldVersion < 3) {
          await db.execute('''
            CREATE TABLE custom_drills (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              name TEXT NOT NULL,
              description TEXT NOT NULL
            )
          ''');

          await db.execute('''
            CREATE TABLE drill_spots (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              drillId INTEGER NOT NULL,
              x REAL NOT NULL,
              y REAL NOT NULL,
              zoneName TEXT NOT NULL,
              category TEXT NOT NULL,
              targetShots INTEGER NOT NULL,
              FOREIGN KEY (drillId) REFERENCES custom_drills (id) ON DELETE CASCADE
            )
          ''');
        }
      },
    );
  }

  Future<void> _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE sessions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        dateTime TEXT,
        category TEXT,
        shotsMade INTEGER,
        shotsMissed INTEGER
      )
    ''');

    await db.execute('''
      CREATE TABLE shots (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        sessionId INTEGER,
        x REAL,
        y REAL,
        isMade INTEGER,
        category TEXT,
        zoneName TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE custom_drills (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        description TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE drill_spots (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        drillId INTEGER NOT NULL,
        x REAL NOT NULL,
        y REAL NOT NULL,
        zoneName TEXT NOT NULL,
        category TEXT NOT NULL,
        targetShots INTEGER NOT NULL,
        FOREIGN KEY (drillId) REFERENCES custom_drills (id) ON DELETE CASCADE
      )
    ''');
  }

  // --- SESSIONS & SHOTS ---

  Future<int> insertSessionWithShots(PracticeSession session, List<Shot> shots) async {
    if (kIsWeb) {
      final newId = _webSessionCounter++;
      final savedSession = PracticeSession(
        id: newId,
        dateTime: session.dateTime,
        category: session.category,
        shotsMade: session.shotsMade,
        shotsMissed: session.shotsMissed,
      );
      _webSessions.insert(0, savedSession);

      for (var s in shots) {
        _webShots.add(Shot(
          id: _webShots.length + 1,
          sessionId: newId,
          x: s.x,
          y: s.y,
          isMade: s.isMade,
          category: s.category,
          zoneName: s.zoneName,
        ));
      }
      return newId;
    }

    final db = await database;
    final sessionId = await db!.insert('sessions', session.toMap());

    final batch = db.batch();
    for (var shot in shots) {
      batch.insert('shots', shot.toMap(sessionId));
    }
    await batch.commit(noResult: true);

    return sessionId;
  }

  Future<List<PracticeSession>> getSessions() async {
    if (kIsWeb) {
      return List.from(_webSessions);
    }

    final db = await database;
    final maps = await db!.query('sessions', orderBy: 'dateTime DESC');
    return maps.map((map) => PracticeSession.fromMap(map)).toList();
  }

  Future<List<Shot>> getShotsForSession(int sessionId) async {
    if (kIsWeb) {
      return _webShots.where((s) => s.sessionId == sessionId).toList();
    }

    final db = await database;
    final maps = await db!.query(
      'shots',
      where: 'sessionId = ?',
      whereArgs: [sessionId],
    );
    return maps.map((map) => Shot.fromMap(map)).toList();
  }

  Future<List<Shot>> getAllShots() async {
    if (kIsWeb) {
      return List.from(_webShots);
    }

    final db = await database;
    final maps = await db!.query('shots');
    return maps.map((map) => Shot.fromMap(map)).toList();
  }

  // --- CUSTOM DRILLS ---

  Future<int> insertCustomDrill(CustomDrill drill) async {
    if (kIsWeb) {
      final newId = _webDrillCounter++;
      final savedDrill = CustomDrill(
        id: newId,
        name: drill.name,
        description: drill.description,
        spots: drill.spots,
      );
      _webDrills.add(savedDrill);
      return newId;
    }

    final db = await database;
    final drillId = await db!.insert('custom_drills', drill.toMap());

    final batch = db.batch();
    for (var spot in drill.spots) {
      final spotMap = spot.toMap();
      spotMap['drillId'] = drillId;
      batch.insert('drill_spots', spotMap);
    }
    await batch.commit(noResult: true);

    return drillId;
  }

  Future<List<CustomDrill>> getCustomDrills() async {
    if (kIsWeb) {
      return List.from(_webDrills);
    }

    final db = await database;
    final drillMaps = await db!.query('custom_drills');

    List<CustomDrill> drills = [];
    for (var map in drillMaps) {
      final drillId = map['id'] as int;
      final spotMaps = await db.query(
        'drill_spots',
        where: 'drillId = ?',
        whereArgs: [drillId],
      );
      final spots = spotMaps.map((s) => DrillSpot.fromMap(s)).toList();

      drills.add(CustomDrill(
        id: drillId,
        name: map['name'] as String,
        description: map['description'] as String,
        spots: spots,
      ));
    }
    return drills;
  }

  Future<void> deleteCustomDrill(int id) async {
    if (kIsWeb) {
      _webDrills.removeWhere((d) => d.id == id);
      return;
    }

    final db = await database;
    await db!.delete('drill_spots', where: 'drillId = ?', whereArgs: [id]);
    await db.delete('custom_drills', where: 'id = ?', whereArgs: [id]);
  }
  
  Future<void> deleteSession(int sessionId) async {
    if (kIsWeb) {
      _webSessions.removeWhere((s) => s.id == sessionId);
      _webShots.removeWhere((s) => s.sessionId == sessionId);
      return;
    }

  final db = await database;
  await db!.delete('shots', where: 'sessionId = ?', whereArgs: [sessionId]);
  await db.delete('sessions', where: 'id = ?', whereArgs: [sessionId]);
}
  // Optional coordinate zone utility
  String getZoneName(double x, double y) {
    final dx = x - 0.5;
    final dy = y - 0.15;
    final dist = sqrt(dx * dx + dy * dy);

    if (dist > 0.38 || y > 0.55) {
      if (x < 0.25) return 'Left Corner 3';
      if (x > 0.75) return 'Right Corner 3';
      if (x < 0.40) return 'Left Wing 3';
      if (x > 0.60) return 'Right Wing 3';
      return 'Center 3';
    } else if (dist > 0.22) {
      if (x < 0.35) return 'Left Mid-range';
      if (x > 0.65) return 'Right Mid-range';
      return 'Center Mid-range';
    } else {
      return 'Paint / Rim';
    }

    
  }
}