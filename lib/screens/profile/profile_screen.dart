import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../providers/font_provider.dart';
import '../settings/settings_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String _appVersion = 'v1.0.0';

  @override
  void initState() {
    super.initState();
    _loadVersionInfo();
  }

  Future<void> _loadVersionInfo() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      setState(() {
        _appVersion = 'v${packageInfo.version} (${packageInfo.buildNumber})';
      });
    } catch (e) {
      debugPrint('Error loading package info: $e');
    }
  }

  Future<void> _launchPlayStore() async {
    String packageName = 'com.typography';
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      if (packageInfo.packageName.isNotEmpty) {
        packageName = packageInfo.packageName;
      }
    } catch (e) {
      debugPrint('Error getting package name: $e');
    }
    
    final marketUri = Uri.parse('market://details?id=$packageName');
    final webUri = Uri.parse('https://play.google.com/store/apps/details?id=$packageName');
    
    try {
      await launchUrl(marketUri, mode: LaunchMode.externalApplication);
    } catch (e) {
      debugPrint('Could not launch market URI, trying browser: $e');
      try {
        await launchUrl(webUri, mode: LaunchMode.externalApplication);
      } catch (err) {
        debugPrint('Failed to launch browser: $err');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      body: SafeArea(
        child: SingleChildScrollView(
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
            _buildListTile('Rate Us', Icons.star_rate_rounded, null, onTap: _launchPlayStore),
            _buildListTile('Feedback', Icons.feedback_outlined, null, onTap: _launchPlayStore),
            _buildListTile('Help Center', Icons.help_outline_rounded, null),
            _buildListTile('About', Icons.info_outline_rounded, _appVersion),
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
