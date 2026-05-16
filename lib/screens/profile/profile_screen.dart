import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/font_provider.dart';
import '../settings/settings_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Profile', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            _buildProfileCard(),
            const SizedBox(height: 32),
            _buildSection('Application'),
            _buildListTile('Settings', Icons.settings_rounded, null, onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen()));
            }),
            _buildListTile('Custom Fonts', Icons.font_download_outlined, context.watch<FontProvider>().customFonts.length.toString()),
            _buildListTile('Export Quality', Icons.high_quality_outlined, '4K'),
            _buildListTile('Language', Icons.language_outlined, 'English'),
            const SizedBox(height: 32),
            _buildSection('Account'),
            _buildListTile('Subscription', Icons.star_outline_rounded, 'Premium'),
            _buildListTile('Cloud Backup', Icons.cloud_outlined, 'Active'),
            const SizedBox(height: 32),
            _buildSection('Other'),
            _buildListTile('Help Center', Icons.help_outline_rounded, null),
            _buildListTile('About', Icons.info_outline_rounded, 'v1.0.0'),
            const SizedBox(height: 48),
            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: () {},
                child: const Text('Log Out', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.03),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: Colors.white10,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white10),
            ),
            child: const Icon(Icons.person_rounded, color: Colors.white38, size: 32),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'John Doe',
                  style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                ),
                Text(
                  'john.doe@example.com',
                  style: TextStyle(color: Colors.white38, fontSize: 13),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, left: 4),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          title.toUpperCase(),
          style: const TextStyle(color: Colors.white24, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.0),
        ),
      ),
    );
  }

  Widget _buildListTile(String title, IconData icon, String? trailing, {VoidCallback? onTap}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.02),
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        onTap: onTap,
        leading: Icon(icon, color: Colors.white54, size: 20),
        title: Text(title, style: const TextStyle(color: Colors.white, fontSize: 15)),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (trailing != null)
              Text(trailing, style: const TextStyle(color: Colors.white24, fontSize: 13)),
            const SizedBox(width: 8),
            const Icon(Icons.chevron_right_rounded, color: Colors.white12),
          ],
        ),
      ),
    );
  }
}
