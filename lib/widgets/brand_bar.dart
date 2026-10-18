import 'package:flutter/material.dart';
import '../services/audio_service.dart';
import '../screens/about_screen.dart';

class HooperBuddyHeader extends StatelessWidget implements PreferredSizeWidget {
  final List<Widget>? actions;
  final bool showSoundToggle;
  final bool showAboutButton;

  const HooperBuddyHeader({
    super.key,
    this.actions,
    this.showSoundToggle = true,
    this.showAboutButton = true,
  });

  @override
  Size get preferredSize => const Size.fromHeight(60.0);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 1,
      shadowColor: Colors.black12,
      surfaceTintColor: Colors.white,
      centerTitle: false,
      title: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: const BoxDecoration(
              color: Color(0xFFFF5500),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.sports_basketball,
              color: Colors.white,
              size: 20,
            ),
          ),
          const SizedBox(width: 10),
          const Text(
            'HOOPER BUDDY',
            style: TextStyle(
              color: Color(0xFFFF5500),
              fontSize: 22,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.5,
            ),
          ),
        ],
      ),
      actions: [
        if (showSoundToggle)
          ValueListenableBuilder<bool>(
            valueListenable: AudioService.instance.isSoundEnabled,
            builder: (context, enabled, child) {
              return IconButton(
                icon: Icon(
                  enabled ? Icons.volume_up_rounded : Icons.volume_off_rounded,
                  color: enabled ? const Color(0xFFFF5500) : Colors.grey,
                ),
                tooltip: enabled ? 'Mute Sound' : 'Enable Sound',
                onPressed: () {
                  AudioService.instance.toggleSound();
                  ScaffoldMessenger.of(context).hideCurrentSnackBar();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      duration: const Duration(seconds: 1),
                      content: Text(enabled ? '🔇 Sound Muted' : '🔊 Sound Enabled'),
                    ),
                  );
                },
              );
            },
          ),
        if (showAboutButton)
          IconButton(
            icon: const Icon(Icons.info_outline_rounded, color: Color(0xFFFF5500)),
            tooltip: 'About Hooper Buddy',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const AboutScreen()),
              );
            },
          ),
        if (actions != null) ...actions!,
        const SizedBox(width: 6),
      ],
    );
  }
}

class TrademarkFooter extends StatelessWidget {
  final String authorName;

  const TrademarkFooter({
    super.key,
    this.authorName = 'Erfan Hakimi',
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 8.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Divider(height: 1, color: Colors.black12),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.sports_basketball,
                size: 14,
                color: Color(0xFFFF5500),
              ),
              const SizedBox(width: 6),
              Text(
                'HOOPER BUDDY™ • Created by Erfan Hakimi',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade600,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            '© ${DateTime.now().year} All Rights Reserved.',
            style: TextStyle(
              fontSize: 10,
              color: Colors.grey.shade400,
            ),
          ),
        ],
      ),
    );
  }
}