import 'package:flutter/material.dart';

class TutorialsPage extends StatelessWidget {
  const TutorialsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Tutorials',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSearchBar(),
            const SizedBox(height: 32),
            _buildCategorySection('GETTING STARTED', [
              {'title': 'Editor Overview', 'duration': '3:45'},
              {'title': 'Importing Assets', 'duration': '2:20'},
            ]),
            const SizedBox(height: 32),
            _buildCategorySection('ADVANCED', [
              {'title': 'Mastering Keyframes', 'duration': '12:30'},
              {'title': 'Motion Paths', 'duration': '8:15'},
            ]),
            const SizedBox(height: 32),
            _buildCategorySection('EFFECTS', [
              {'title': 'Shadows & Glow', 'duration': '6:20'},
              {'title': '3D Transforms', 'duration': '9:40'},
            ]),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.03),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white10),
      ),
      child: const Row(
        children: [
          Icon(Icons.search_rounded, color: Colors.white24, size: 20),
          SizedBox(width: 12),
          Expanded(
            child: TextField(
              style: TextStyle(color: Colors.white, fontSize: 14),
              decoration: InputDecoration(
                hintText: 'Search tutorials...',
                hintStyle: TextStyle(color: Colors.white10),
                border: InputBorder.none,
                isDense: true,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategorySection(String title, List<Map<String, String>> tutorials) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: Colors.white24,
            fontSize: 10,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.0,
          ),
        ),
        const SizedBox(height: 16),
        ...tutorials.map((tut) => _buildTutorialItem(tut)),
      ],
    );
  }

  Widget _buildTutorialItem(Map<String, String> tut) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.02),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(Icons.play_arrow_rounded, color: Colors.white24),
        ),
        title: Text(
          tut['title']!,
          style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w500),
        ),
        subtitle: Text(
          tut['duration']!,
          style: const TextStyle(color: Colors.white24, fontSize: 12),
        ),
        trailing: const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white10, size: 14),
      ),
    );
  }
}
