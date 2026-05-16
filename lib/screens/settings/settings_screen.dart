import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/editor_provider.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF000000),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Settings', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader('General'),
            _buildSettingTile(
              icon: Icons.language_rounded,
              title: 'Language',
              subtitle: 'System Default (English)',
              onTap: () {},
            ),
            _buildSettingTile(
              icon: Icons.dark_mode_rounded,
              title: 'Appearance',
              subtitle: 'Dark Mode',
              onTap: () {},
            ),
            const SizedBox(height: 32),
            _buildSectionHeader('Editor'),
            _buildSettingTile(
              icon: Icons.save_rounded,
              title: 'Auto-save Interval',
              subtitle: '5 Minutes',
              onTap: () {},
            ),
            _buildSettingTile(
              icon: Icons.grid_4x4_rounded,
              title: 'Snap to Grid',
              subtitle: 'Enabled',
              trailing: Switch(
                value: true,
                onChanged: (v) {},
                activeColor: Colors.blueAccent,
              ),
              onTap: () {},
            ),
            _buildSettingTile(
              icon: Icons.text_fields_rounded,
              title: 'Default Font',
              subtitle: 'Poppins',
              onTap: () {},
            ),
            const SizedBox(height: 32),
            _buildSectionHeader('Export'),
            _buildSettingTile(
              icon: Icons.high_quality_rounded,
              title: 'Default Resolution',
              subtitle: '1080p (Full HD)',
              onTap: () {},
            ),
            _buildSettingTile(
              icon: Icons.speed_rounded,
              title: 'Frame Rate',
              subtitle: '30 FPS',
              onTap: () {},
            ),
            _buildSettingTile(
              icon: Icons.folder_rounded,
              title: 'Export Path',
              subtitle: '/Movies/TypoEdit',
              onTap: () {},
            ),
            const SizedBox(height: 32),
            _buildSectionHeader('About'),
            _buildSettingTile(
              icon: Icons.info_outline_rounded,
              title: 'Version',
              subtitle: '1.0.1 (Build 3)',
              onTap: () {},
            ),
            _buildSettingTile(
              icon: Icons.description_outlined,
              title: 'Terms of Service',
              onTap: () {},
            ),
            _buildSettingTile(
              icon: Icons.privacy_tip_outlined,
              title: 'Privacy Policy',
              onTap: () {},
            ),
            const SizedBox(height: 48),
            Center(
              child: Text(
                'MADE WITH LOVE FOR CREATORS',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.1),
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.5,
                ),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 16),
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(
          color: Colors.blueAccent,
          fontSize: 11,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildSettingTile({
    required IconData icon,
    required String title,
    String? subtitle,
    Widget? trailing,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.03),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.blueAccent.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: Colors.blueAccent, size: 20),
        ),
        title: Text(title, style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w500)),
        subtitle: subtitle != null ? Text(subtitle, style: TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 13)) : null,
        trailing: trailing ?? const Icon(Icons.chevron_right_rounded, color: Colors.white12),
      ),
    );
  }
}
