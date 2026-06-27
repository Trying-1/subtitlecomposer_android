import 'package:flutter/material.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import 'faq_page.dart';

class TutorialItem {
  final String title;
  final String description;
  final String duration;
  final String youtubeId;

  const TutorialItem({
    required this.title,
    required this.description,
    required this.duration,
    required this.youtubeId,
  });
}

class TutorialsPage extends StatefulWidget {
  const TutorialsPage({super.key});

  @override
  State<TutorialsPage> createState() => _TutorialsPageState();
}

class _TutorialsPageState extends State<TutorialsPage> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  final Map<String, List<TutorialItem>> _allTutorials = {
    'GETTING STARTED': [
      const TutorialItem(
        title: 'Editor Walkthrough & First Project',
        description: 'Get familiar with the workspace, understand tracks, learn how to navigate the timeline, playhead controls, and create your very first typography sequence from scratch.',
        duration: '3:45',
        youtubeId: '3U6W6DqR3fA', // Typography guidelines & workflow
      ),
      const TutorialItem(
        title: 'Background Media & Color Canvas',
        description: 'Learn how to customize your scene background. Add solid flat canvas colors, premium curated asset images, or dynamic moving video clips, and utilize the full duration sweep button.',
        duration: '2:20',
        youtubeId: 'y83x7MgzWOA', // AE background & kinetic overview
      ),
      const TutorialItem(
        title: 'Typography Layout & Kinetic Presets',
        description: 'Understand style presets, select gorgeous visual themes, customize fonts, and leverage the auto kinetic sheet to automatically lay out dynamic words in sync with the scene timeline.',
        duration: '4:15',
        youtubeId: 'L_LUpnjgPso', // Motion typography template
      ),
    ],
    'STYLING & EFFECTS': [
      const TutorialItem(
        title: 'Advanced Outer Shadow & Glow',
        description: 'Add premium dark shadows or vibrant glowing neon borders to your texts. Learn how to adjust glow intensity, blur distance, and colors to make your typography stand out on any background.',
        duration: '5:20',
        youtubeId: 'dQw4w9WgXcQ', // Classic test ID
      ),
      const TutorialItem(
        title: 'Horizontal Track Heights & Settings',
        description: 'Optimize your editing space. Access the preview settings tab to adjust individual track heights dynamically, allowing for spacious keyframing or dense, compact timeline views.',
        duration: '2:50',
        youtubeId: '3U6W6DqR3fA',
      ),
      const TutorialItem(
        title: 'Semantic Color Palettes & Custom Roles',
        description: 'Discover the power of scene color palettes. Swap background, main, sub-main, and normal text role swatches instantly, and use the custom color picker for real-time scene-wide updates.',
        duration: '4:40',
        youtubeId: 'y83x7MgzWOA',
      ),
    ],
    'ADVANCED KEYFRAMING': [
      const TutorialItem(
        title: 'Mastering Timeline Keyframes',
        description: 'Unleash absolute visual control. Learn how to add translation (X, Y), rotation, scaling, and opacity keyframe points to overlays and texts to create custom motion paths.',
        duration: '12:30',
        youtubeId: 'L_LUpnjgPso',
      ),
      const TutorialItem(
        title: 'Custom Easing Curves & Speed Graphs',
        description: 'Smooth out your transitions. Use built-in easing modes like linear, ease-in, ease-out, bounce, or use custom graph bezier curves to craft highly dynamic kinetic movement.',
        duration: '8:15',
        youtubeId: 'dQw4w9WgXcQ',
      ),
      const TutorialItem(
        title: 'Real-time Adjustments & Shader Filters',
        description: 'Apply non-destructive visual improvements to background clips and overlay assets. Adjust brightness, contrast, saturation, or apply real-time GPU box blurs to create gorgeous lens effects.',
        duration: '7:05',
        youtubeId: '3U6W6DqR3fA',
      ),
    ],
    'AUDIO & BEAT SYNC': [
      const TutorialItem(
        title: 'Importing & Editing Audio Tracks',
        description: 'Add depth to your stories. Learn how to load background music, select audio segments, trim tracks, adjust volumes, and structure your audio layer sequence.',
        duration: '3:50',
        youtubeId: 'y83x7MgzWOA',
      ),
      const TutorialItem(
        title: 'Precise Beat Snapping & Slicing',
        description: 'Align your typography flawlessly with beats. Slice long subtitle blocks, snap segment start/end handles directly to audio wave spikes, and build punchy, syncopated kinetic reveals.',
        duration: '5:10',
        youtubeId: 'L_LUpnjgPso',
      ),
      const TutorialItem(
        title: 'Voiceover Timing Realignment',
        description: 'Align speech frames with exact timing constraints. Utilize playhead tracking and track segment stretching to match rapid narration structures with the visual typography canvas.',
        duration: '4:15',
        youtubeId: 'dQw4w9WgXcQ',
      ),
    ],
    'RENDERING & EXPORT': [
      const TutorialItem(
        title: 'Project Resolutions & Ratios',
        description: 'Prepare your video for standard formats. Set portrait 9:16 aspect ratios for Reels/Shorts, landscape 16:9 for YouTube feeds, or 1:1 square feeds for visual layouts.',
        duration: '2:15',
        youtubeId: '3U6W6DqR3fA',
      ),
      const TutorialItem(
        title: 'GPU Accelerated Render Pipeline',
        description: 'Understand export mechanics. Learn how the native GLSL shader engine synthesizes active keyframes, filters, animations, and high-performance overlays into a seamless 60fps MP4 export.',
        duration: '6:30',
        youtubeId: 'dQw4w9WgXcQ',
      ),
      const TutorialItem(
        title: 'Seamless Social Publishing',
        description: 'Package your creation! Discover workflows for one-click publishing, direct asset exports to standard media storage, and sharing directly to Instagram, TikTok, and YouTube.',
        duration: '3:05',
        youtubeId: 'L_LUpnjgPso',
      ),
    ],
  };

  Future<void> _launchYouTubeChannel() async {
    final Uri url = Uri.parse('https://www.youtube.com/@typoedit-app');
    try {
      if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Could not open YouTube channel link.'),
              backgroundColor: Colors.redAccent,
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('Error launching YouTube: $e');
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F13),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Video Tutorials',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18, fontFamily: 'KleeOne'),
        ),
        leading: Navigator.canPop(context)
            ? IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
                onPressed: () => Navigator.pop(context),
              )
            : null,
        actions: [
          IconButton(
            icon: Image.asset(
              'assets/images/youtube.png',
              width: 24,
              height: 24,
            ),
            tooltip: 'YouTube Channel',
            onPressed: _launchYouTubeChannel,
          ),
          const SizedBox(width: 12),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: _buildSearchBar(),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_searchQuery.isEmpty) _buildFaqBanner(context),
                  if (_searchQuery.isEmpty) const SizedBox(height: 16),
                  if (_searchQuery.isEmpty) _buildQuickStartGuide(),
                  if (_searchQuery.isEmpty) const SizedBox(height: 32),
                  ..._buildFilteredSections(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFaqBanner(BuildContext context) {
    return InkWell(
      onTap: () {
        Navigator.push(context, MaterialPageRoute(builder: (_) => const FaqPage()));
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.03),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withOpacity(0.08)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.deepPurpleAccent.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.help_outline_rounded, color: Colors.deepPurpleAccent, size: 24),
            ),
            const SizedBox(width: 16),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'FAQ & Interface Guide',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'KleeOne',
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'What does this button do? Read the UI breakdown.',
                    style: TextStyle(
                      color: Colors.white54,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white24, size: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickStartGuide() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.deepPurpleAccent.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.deepPurpleAccent.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.rocket_launch_rounded, size: 20, color: Colors.deepPurpleAccent),
              SizedBox(width: 12),
              Text(
                'QUICK START GUIDE',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                  fontFamily: 'KleeOne',
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildGuideStep('1', 'Import your audio (select an audio file or extract from a video).'),
          _buildGuideStep('2', 'Click the "Paste Text" button to add your script. Make sure to use newlines properly for each sentence or phrase.'),
          _buildGuideStep('3', 'Adjust those sentence segments properly in the timeline to match the audio.'),
          _buildGuideStep('4', 'Use the Auto AI button to automatically generate typography and animations!'),
        ],
      ),
    );
  }

  Widget _buildGuideStep(String number, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: Colors.deepPurpleAccent.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                number,
                style: const TextStyle(
                  color: Colors.deepPurpleAccent,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: Colors.white.withOpacity(0.8),
                fontSize: 13,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.03),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Row(
        children: [
          const Icon(Icons.search_rounded, color: Colors.white24, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              controller: _searchController,
              onChanged: (val) {
                setState(() {
                  _searchQuery = val.trim().toLowerCase();
                });
              },
              style: const TextStyle(color: Colors.white, fontSize: 13, fontFamily: 'KleeOne'),
              decoration: const InputDecoration(
                hintText: 'Search video lessons...',
                hintStyle: TextStyle(color: Colors.white12, fontSize: 13, fontFamily: 'KleeOne'),
                border: InputBorder.none,
                isDense: true,
              ),
            ),
          ),
          if (_searchQuery.isNotEmpty)
            GestureDetector(
              onTap: () {
                _searchController.clear();
                setState(() {
                  _searchQuery = '';
                });
              },
              child: const Icon(Icons.close_rounded, color: Colors.white38, size: 18),
            ),
        ],
      ),
    );
  }

  List<Widget> _buildFilteredSections() {
    List<Widget> sections = [];
    bool hasAnyMatches = false;

    _allTutorials.forEach((category, items) {
      final filteredItems = items.where((tut) {
        return tut.title.toLowerCase().contains(_searchQuery) ||
               tut.description.toLowerCase().contains(_searchQuery);
      }).toList();

      if (filteredItems.isNotEmpty) {
        hasAnyMatches = true;
        sections.add(
          _buildCategorySection(category, filteredItems),
        );
        sections.add(const SizedBox(height: 32));
      }
    });

    if (!hasAnyMatches) {
      return [
        Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 80),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.video_library_outlined, size: 48, color: Colors.white.withOpacity(0.05)),
                const SizedBox(height: 16),
                Text(
                  'No tutorials found matching "$_searchQuery"',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.3),
                    fontSize: 12,
                    fontFamily: 'KleeOne',
                  ),
                ),
              ],
            ),
          ),
        )
      ];
    }

    // Remove the last spacing element for clean alignment
    if (sections.isNotEmpty) {
      sections.removeLast();
    }

    return sections;
  }

  Widget _buildCategorySection(String title, List<TutorialItem> tutorials) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 3,
              height: 12,
              decoration: BoxDecoration(
                color: Colors.deepPurpleAccent,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              title,
              style: const TextStyle(
                color: Colors.white38,
                fontSize: 9,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.2,
                fontFamily: 'KleeOne',
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        ...tutorials.map((tut) => _buildTutorialItem(tut)),
      ],
    );
  }

  Widget _buildTutorialItem(TutorialItem tut) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
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
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => EmbeddedVideoPlayerScreen(tutorial: tut),
                ),
              );
            },
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  // Play Thumbnail Simulator
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      Container(
                        width: 72,
                        height: 52,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.deepPurple.withOpacity(0.3),
                              Colors.purple.withOpacity(0.08),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.white.withOpacity(0.06)),
                        ),
                        child: Center(
                          child: Icon(
                            Icons.video_library_rounded,
                            size: 16,
                            color: Colors.deepPurpleAccent.withOpacity(0.7),
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: Colors.deepPurpleAccent,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 16),
                      ),
                    ],
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          tut.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            fontFamily: 'KleeOne',
                          ),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            const Icon(Icons.access_time_rounded, size: 11, color: Colors.white38),
                            const SizedBox(width: 4),
                            Text(
                              tut.duration,
                              style: const TextStyle(color: Colors.white38, fontSize: 10),
                            ),
                            const SizedBox(width: 12),
                            const Icon(Icons.tv_rounded, size: 11, color: Colors.white38),
                            const SizedBox(width: 4),
                            const Text(
                              'YouTube Lesson',
                              style: TextStyle(color: Colors.white38, fontSize: 10),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white12, size: 12),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class EmbeddedVideoPlayerScreen extends StatefulWidget {
  final TutorialItem tutorial;

  const EmbeddedVideoPlayerScreen({
    super.key,
    required this.tutorial,
  });

  @override
  State<EmbeddedVideoPlayerScreen> createState() => _EmbeddedVideoPlayerScreenState();
}

class _EmbeddedVideoPlayerScreenState extends State<EmbeddedVideoPlayerScreen> {
  late YoutubePlayerController _controller;

  @override
  void initState() {
    super.initState();
    _controller = YoutubePlayerController(
      initialVideoId: widget.tutorial.youtubeId,
      flags: const YoutubePlayerFlags(
        autoPlay: true,
        mute: false,
        disableDragSeek: false,
        loop: false,
        isLive: false,
        forceHD: false,
        enableCaption: false,
      ),
    );
  }

  @override
  void deactivate() {
    // Pauses video when navigating away
    _controller.pause();
    super.deactivate();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return YoutubePlayerBuilder(
      player: YoutubePlayer(
        controller: _controller,
        showVideoProgressIndicator: true,
        progressIndicatorColor: Colors.deepPurpleAccent,
        progressColors: const ProgressBarColors(
          playedColor: Colors.deepPurpleAccent,
          handleColor: Colors.deepPurpleAccent,
        ),
      ),
      builder: (context, player) {
        return Scaffold(
          backgroundColor: const Color(0xFF0F0F13),
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.close_rounded, color: Colors.white, size: 24),
              onPressed: () => Navigator.pop(context),
            ),
            title: Text(
              widget.tutorial.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.bold,
                fontFamily: 'KleeOne',
              ),
            ),
          ),
          body: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Embed Player Frame
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  clipBehavior: Clip.antiAlias,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white.withOpacity(0.08)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.deepPurpleAccent.withOpacity(0.15),
                        blurRadius: 20,
                        spreadRadius: -5,
                      ),
                    ],
                  ),
                  child: player,
                ),
                const SizedBox(height: 24),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.tutorial.title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'KleeOne',
                        ),
                      ),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.02),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.white.withOpacity(0.05)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Row(
                              children: [
                                Icon(Icons.auto_awesome_rounded, size: 14, color: Colors.amberAccent),
                                SizedBox(width: 8),
                                Text(
                                  'LESSON OUTLINE',
                                  style: TextStyle(
                                    fontSize: 9,
                                    color: Colors.amberAccent,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 1.2,
                                    fontFamily: 'KleeOne',
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Text(
                              widget.tutorial.description,
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.6),
                                fontSize: 12,
                                height: 1.6,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
