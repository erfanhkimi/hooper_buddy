import 'package:flutter/material.dart';
import '../widgets/brand_bar.dart';

class AboutScreen extends StatelessWidget {
  final String authorName;

  const AboutScreen({
    super.key,
    this.authorName = 'Erfan Hakimi', 
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('About Hooper Buddy'),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 10),

            // App Logo Badge
            Container(
              padding: const EdgeInsets.all(18),
              decoration: const BoxDecoration(
                color: Color(0xFFFF5500),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 12,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: const Icon(
                Icons.sports_basketball,
                color: Colors.white,
                size: 56,
              ),
            ),
            const SizedBox(height: 16),

            // App Name & Version
            const Text(
              'HOOPER BUDDY',
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.5,
                color: Color(0xFFFF5500),
              ),
            ),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                'Version 1.2.0',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey,
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Mission Statement Card
            Card(
              elevation: 1,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              color: Colors.orange.shade50,
              child: const Padding(
                padding: EdgeInsets.all(16.0),
                child: Text(
                  'Hooper Buddy is your personal basketball shot tracking and performance analytics companion. Track field goal percentages across interactive court zones, design custom drill routines, and analyze shooting trends over time.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14, height: 1.4, color: Colors.black87),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Key Features Section
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Key Features',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 10),

            _buildFeatureTile(
              icon: Icons.map_rounded,
              title: 'Interactive Half-Court Heatmap',
              subtitle: 'Multi-zone shot tracking including Deep 3s, Mid-range, and Finishing.',
            ),
            _buildFeatureTile(
              icon: Icons.fitness_center_rounded,
              title: 'Custom Drill Builder',
              subtitle: 'Design step-by-step shooting workouts with target attempt limits.',
            ),
            _buildFeatureTile(
              icon: Icons.show_chart_rounded,
              title: 'Performance Analytics',
              subtitle: 'Track FG% progression over time and shot category volume.',
            ),
            _buildFeatureTile(
              icon: Icons.volume_up_rounded,
              title: 'Audio SFX & Haptics',
              subtitle: 'Real-time swish sound effects and tactile feedback on makes and misses.',
            ),
            _buildFeatureTile(
              icon: Icons.share_rounded,
              title: 'Workout Card Sharing',
              subtitle: 'Export high-res PNG workout summary cards to share with coaches or friends.',
            ),

            const SizedBox(height: 24),

            // Built With Tech Stack Chips
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Built With',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: const [
                Chip(label: Text('Flutter & Dart')),
                Chip(label: Text('SQLite / sqflite')),
                Chip(label: Text('FL Chart')),
                Chip(label: Text('AudioPlayers')),
                Chip(label: Text('Share Plus')),
              ],
            ),

            const SizedBox(height: 24),
            TrademarkFooter(authorName: authorName),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureTile({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: const Color(0xFFFF5500).withOpacity(0.12),
          child: Icon(icon, color: const Color(0xFFFF5500)),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        subtitle: Text(subtitle, style: const TextStyle(fontSize: 12, color: Colors.grey)),
      ),
    );
  }
}