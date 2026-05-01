import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/editor_provider.dart';
import '../editor_screen.dart';
import 'tutorials_page.dart';
import '../profile/profile_screen.dart';
import '../video_player/video_player_screen.dart';
import '../../config/app_config.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Typo Edit',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          if (AppConfig.showHomeProfile)
            IconButton(
              icon: const Icon(Icons.person_outline_rounded, color: Colors.white70),
              onPressed: () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfileScreen()));
              },
            ),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (AppConfig.showHomeNewProject) ...[
              _buildActionCard(
                context,
                title: 'New Project',
                subtitle: 'Create a new typography video',
                icon: Icons.add_rounded,
                onTap: () {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const EditorScreen()));
                },
                primary: true,
              ),
              const SizedBox(height: 20),
            ],
            if (AppConfig.showHomeTutorials) ...[
              _buildActionCard(
                context,
                title: 'Tutorials',
                subtitle: 'Learn how to use the editor',
                icon: Icons.play_circle_outline_rounded,
                onTap: () {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const TutorialsPage()));
                },
              ),
              const SizedBox(height: 20),
            ],
            if (AppConfig.showHomeNativePlayer) ...[
              _buildActionCard(
                context,
                title: 'Native Player',
                subtitle: 'Play videos with native engine',
                icon: Icons.video_collection_rounded,
                onTap: () {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const VideoPlayerScreen()));
                },
              ),
            ],
            const SizedBox(height: 40),
            const Text(
              'RECENT PROJECTS',
              style: TextStyle(
                color: Colors.white38,
                fontSize: 11,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.0,
              ),
            ),
            const SizedBox(height: 16),
            _buildRecentProjectsList(),
          ],
        ),
      ),
    );
  }

  Widget _buildActionCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required VoidCallback onTap,
    bool primary = false,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: primary ? Colors.white : Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white10),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: primary ? Colors.black : Colors.white,
              size: 28,
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: primary ? Colors.black : Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: primary ? Colors.black.withOpacity(0.6) : Colors.white38,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: primary ? Colors.black.withOpacity(0.3) : Colors.white10,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentProjectsList() {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: 3,
      itemBuilder: (context, index) {
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.03),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.movie_outlined, color: Colors.white24, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Untitled Project ${index + 1}',
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Modified 2h ago',
                      style: TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 12),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.more_vert_rounded, color: Colors.white10),
            ],
          ),
        );
      },
    );
  }
}
