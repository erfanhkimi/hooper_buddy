import 'package:flutter/material.dart';
import 'models/session.dart';
import 'models/drill.dart';
import 'services/database_service.dart';
import 'services/audio_service.dart';
import 'widgets/brand_bar.dart';
import 'screens/session_screen.dart';
import 'screens/session_detail_screen.dart';
import 'screens/analytics_screen.dart';
import 'screens/create_drill_screen.dart';
import 'screens/run_drill_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AudioService.instance.init();
  runApp(const HooperBuddyApp());
}

class HooperBuddyApp extends StatelessWidget {
  const HooperBuddyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Hooper Buddy',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFFFF5500)),
        useMaterial3: true,
      ),
      home: const MainNavigationScreen(),
    );
  }
}

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const HooperBuddyHeader(),
      body: Column(
        children: [
          Expanded(
            child: _currentIndex == 0
                ? const HomeScreen()
                : const AnalyticsScreen(),
          ),
          const TrademarkFooter(authorName: 'Your Name'),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        selectedItemColor: const Color(0xFFFF5500),
        unselectedItemColor: Colors.grey,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.fitness_center),
            label: 'Workouts',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.bar_chart),
            label: 'Analytics',
          ),
        ],
      ),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<PracticeSession> _sessions = [];
  List<CustomDrill> _customDrills = [];
  bool _isLoading = true;

  // Preset Featured Drill
  final CustomDrill _fiveSpot3pt = CustomDrill(
    name: '5-Spot 3PT Challenge',
    description: '25 shots • 5 spots around the arc',
    spots: [
      DrillSpot(x: 0.035, y: 0.14, zoneName: 'Left Corner 3', category: 'Three-point', targetShots: 5),
      DrillSpot(x: 0.20, y: 0.45, zoneName: 'Left Wing 3', category: 'Three-point', targetShots: 5),
      DrillSpot(x: 0.50, y: 0.60, zoneName: 'Center 3', category: 'Three-point', targetShots: 5),
      DrillSpot(x: 0.80, y: 0.45, zoneName: 'Right Wing 3', category: 'Three-point', targetShots: 5),
      DrillSpot(x: 0.965, y: 0.14, zoneName: 'Right Corner 3', category: 'Three-point', targetShots: 5),
    ],
  );

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final sessions = await DatabaseService.instance.getSessions();
    final drills = await DatabaseService.instance.getCustomDrills();
    setState(() {
      _sessions = sessions;
      _customDrills = drills;
      _isLoading = false;
    });
  }

  void _runDrill(CustomDrill drill) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => RunDrillScreen(drill: drill)),
    );
    if (result == true) {
      _loadData();
    }
  }

  void _openCreateDrill() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const CreateDrillScreen()),
    );
    if (result == true) {
      _loadData();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _loadData,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Featured Drill Card
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
                child: Card(
                  color: Colors.orange.shade50,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: ListTile(
                    leading: const Icon(Icons.fitness_center, color: Color(0xFFFF5500), size: 30),
                    title: Text(_fiveSpot3pt.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text(_fiveSpot3pt.description),
                    trailing: ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFF5500)),
                      onPressed: () => _runDrill(_fiveSpot3pt),
                      child: const Text('Start', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ),
              ),

              // 2. Custom Drills List
              Padding(
                padding: const EdgeInsets.only(left: 16.0, right: 16.0, top: 12.0, bottom: 4.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('My Custom Drills', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    TextButton.icon(
                      onPressed: _openCreateDrill,
                      icon: const Icon(Icons.add, size: 18),
                      label: const Text('New Drill'),
                    ),
                  ],
                ),
              ),

              if (_customDrills.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                  child: Text(
                    'No custom drills created yet. Tap "+ New Drill" to design one!',
                    style: TextStyle(color: Colors.grey, fontSize: 13),
                  ),
                )
              else
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _customDrills.length,
                  itemBuilder: (context, index) {
                    final drill = _customDrills[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      child: ListTile(
                        title: Text(drill.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text('${drill.spots.length} spots • ${drill.totalShots} total shots'),
                        trailing: ElevatedButton(
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.green.shade700),
                          onPressed: () => _runDrill(drill),
                          child: const Text('Run', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        ),
                      ),
                    );
                  },
                ),

              // 3. Session History List
              const Padding(
                padding: EdgeInsets.only(left: 16.0, right: 16.0, top: 16.0, bottom: 8.0),
                child: Text('Recent Sessions', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),

              if (_sessions.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(32.0),
                  child: Center(
                    child: Text(
                      'No shooting sessions saved yet.\nTap "+ Free Shoot" below to start!',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey, fontSize: 15),
                    ),
                  ),
                )
              else
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _sessions.length,
                  itemBuilder: (context, index) {
                    final session = _sessions[index];
                    final total = session.shotsMade + session.shotsMissed;
                    final pct = total == 0 ? 0 : ((session.shotsMade / total) * 100).round();
                    final dateFormatted = session.dateTime.toString().split('.')[0].replaceAll('T', ' ');

                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      child: ListTile(
                        title: Text(session.category, style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text(dateFormatted),
                        trailing: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text('${session.shotsMade}/$total Made', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                            Text(
                              '$pct%',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: pct >= 50
                                    ? Colors.green.shade800
                                    : (pct >= 35 ? Colors.amber.shade900 : Colors.red.shade800),
                              ),
                            ),
                          ],
                        ),
                        onTap: () async {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => SessionDetailScreen(session: session),
                            ),
                          );
                          _loadData();
                        },
                      ),
                    );
                  },
                ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color(0xFFFF5500),
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const SessionScreen()),
          );
          if (result == true) {
            _loadData();
          }
        },
        icon: const Icon(Icons.sports_basketball, color: Colors.white),
        label: const Text('Free Shoot', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
    );
  }
}