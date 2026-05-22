import 'package:flutter/material.dart';
import '../../tools/image_sequence/image_sequence_maker.dart';
import '../../tools/font_sequence/font_sequence_maker.dart';

class MoreToolsScreen extends StatelessWidget {
  const MoreToolsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final tools = [
      {
        'title': 'Image Sequence Studio',
        'desc': 'Compile multiple images and audio into custom sequence loops',
        'icon': Icons.video_library_rounded,
        'color': Colors.pinkAccent,
        'action': () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ImageSequenceMaker())),
      },
      {
        'title': 'Font Sequence Studio',
        'desc': 'Compile kinetic text flashing loops with premium font sequences',
        'icon': Icons.font_download_rounded,
        'color': Colors.deepPurpleAccent,
        'action': () => Navigator.push(context, MaterialPageRoute(builder: (_) => const FontSequenceMaker())),
      },
    ];

    return Scaffold(
      backgroundColor: const Color(0xFF0F0F13),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Navigator.canPop(context)
            ? IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
                onPressed: () => Navigator.pop(context),
              )
            : null,
        title: const Text(
          'More Typography Tools',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18, fontFamily: 'KleeOne'),
        ),
      ),
      body: GridView.builder(
        padding: const EdgeInsets.all(20),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 1,
          mainAxisSpacing: 16,
          childAspectRatio: 2.8,
         ),
        itemCount: tools.length,
        itemBuilder: (context, index) {
          final t = tools[index];
          final Color accent = t['color'] as Color;
          return Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.01),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withOpacity(0.04)),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: t['action'] as VoidCallback,
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Row(
                      children: [
                        Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            color: accent.withOpacity(0.05),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: accent.withOpacity(0.2)),
                          ),
                          child: Icon(t['icon'] as IconData, color: accent, size: 28),
                        ),
                        const SizedBox(width: 20),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                t['title'] as String,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  fontFamily: 'KleeOne',
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                t['desc'] as String,
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.4),
                                  fontSize: 12,
                                  height: 1.4,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Icon(Icons.arrow_forward_ios_rounded, color: Colors.white.withOpacity(0.1), size: 14),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
