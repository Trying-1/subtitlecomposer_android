import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'onboarding_slide.dart';
import '../main_navigation.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<Map<String, dynamic>> _slides = [
    {
      'type': 'masonry',
      'title': 'Create trending typography Edits',
      'tagline': 'STAGGERED COMPOSITIONS',
      'description': 'Words self-arrange into gorgeous, high-retention typographic blocks. Text scales and stacks dynamically to optimize screen space and engage viewers.',
      'color': const Color(0xFFC5B8AC), // Muted Sand / Cream
    },
    {
      'type': 'blocky',
      'title': 'Grow your social media page',
      'tagline': 'HIGH CONTRAST CAPTIONS',
      'description': 'Bold, edge-to-edge phrases with raw streetwear styling. Perfect for high-tempo reels and statements that command absolute attention.',
      'color': const Color(0xFF9EAFBE), // Muted Slate Blue
    },
    {
      'type': 'stair',
      'title': 'Seamless typography editor',
      'tagline': 'RHYTHMIC SPEECH FLOW',
      'description': 'Captions step and flow diagonally down, matching the natural tempo of your speech. Structured, clean, and beautifully timed.',
      'color': const Color(0xFFC8B3C3), // Muted Mauve Rose
    },
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _finishOnboarding() async {
    final box = Hive.box('settings_box');
    await box.put('onboarding_shown', true);
    if (mounted) {
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (_, __, ___) => const MainNavigation(),
          transitionsBuilder: (_, anim, __, child) => FadeTransition(opacity: anim, child: child),
          transitionDuration: const Duration(milliseconds: 700),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF08080A),
      body: Stack(
        children: [
          // Minimalist Blueprint Background
          Positioned.fill(
            child: CustomPaint(
              painter: GridPainter(color: Colors.white.withValues(alpha: 0.006)),
            ),
          ),

          // Main Page Slider
          PageView.builder(
            controller: _pageController,
            itemCount: _slides.length,
            onPageChanged: (index) {
              setState(() {
                _currentPage = index;
              });
            },
            itemBuilder: (context, index) {
              final slide = _slides[index];
              return OnboardingSlide(
                title: slide['title'],
                tagline: slide['tagline'],
                description: slide['description'],
                isVisible: _currentPage == index,
                accentColor: slide['color'],
                layoutType: slide['type'],
              );
            },
          ),

          // Bottom Controls Layer
          Positioned(
            bottom: 50,
            left: 30,
            right: 30,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Minimalist Tiny Indicators
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    _slides.length,
                    (index) => AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      height: 4,
                      width: _currentPage == index ? 16 : 4,
                      decoration: BoxDecoration(
                        color: _currentPage == index ? Colors.white : Colors.white.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 36),

                // Pure Flat Minimalist Button
                Container(
                  width: double.infinity,
                  height: 56,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                  ),
                  child: ElevatedButton(
                    onPressed: () {
                      if (_currentPage < _slides.length - 1) {
                        _pageController.nextPage(
                          duration: const Duration(milliseconds: 600),
                          curve: Curves.fastOutSlowIn,
                        );
                      } else {
                        _finishOnboarding();
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.black,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                    ),
                    child: Text(
                      _currentPage == _slides.length - 1 ? 'START CREATING' : 'CONTINUE',
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        letterSpacing: 2.0,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 14),
                // Skip action
                if (_currentPage < _slides.length - 1)
                  TextButton(
                    onPressed: _finishOnboarding,
                    child: Text(
                      'SKIP TOUR',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.35),
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.5,
                      ),
                    ),
                  )
                else
                  const SizedBox(height: 40),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
