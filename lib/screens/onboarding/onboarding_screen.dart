import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'onboarding_slide.dart';
import '../home/home_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> with TickerProviderStateMixin {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  
  late AnimationController _bgAnimController;

  final List<Map<String, dynamic>> _slides = [
    {
      'title': 'TYPO EDIT',
      'tagline': 'ANIMATE YOUR VOICE',
      'description': 'The ultimate tool for creators to turn text into high-impact visual stories.',
      'colors': [Colors.amberAccent, Colors.deepOrange],
    },
    {
      'title': 'Kinetic Power',
      'tagline': 'MOTION THAT SPEAKS',
      'description': 'Bring your words to life with fluid, physics-based motion and cinematic transitions.',
      'colors': [Colors.cyanAccent, Colors.blueAccent],
    },
    {
      'title': 'Studio Quality',
      'tagline': 'EXPORT WITH CONFIDENCE',
      'description': 'Render 4K cinematic typography videos in seconds, ready for any platform.',
      'colors': [Colors.pinkAccent, Colors.deepPurpleAccent],
    },
  ];

  @override
  void initState() {
    super.initState();
    _bgAnimController = AnimationController(vsync: this, duration: const Duration(seconds: 10))..repeat(reverse: true);
  }
  
  @override
  void dispose() {
    _bgAnimController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _finishOnboarding() async {
    final box = Hive.box('settings_box');
    await box.put('onboarding_shown', true);
    if (mounted) {
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (_, __, ___) => const HomeScreen(),
          transitionsBuilder: (_, anim, __, child) => FadeTransition(opacity: anim, child: child),
          transitionDuration: const Duration(milliseconds: 800),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Animated Background Mesh
          AnimatedBuilder(
            animation: _bgAnimController,
            builder: (context, child) {
              final val = _bgAnimController.value;
              final currentColors = _slides[_currentPage]['colors'] as List<Color>;
              
              return Stack(
                children: [
                  Positioned.fill(
                    child: Container(color: Colors.black),
                  ),
                  // Orb 1
                  Align(
                    alignment: Alignment(math.cos(val * math.pi * 2) * 0.8, math.sin(val * math.pi * 2) * 0.8),
                    child: Container(
                      width: 350,
                      height: 350,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: currentColors[0].withValues(alpha: 0.15),
                      ),
                    ),
                  ),
                  // Orb 2
                  Align(
                    alignment: Alignment(math.sin(val * math.pi) * 0.9, math.cos(val * math.pi) * 0.9),
                    child: Container(
                      width: 300,
                      height: 300,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: currentColors[1].withValues(alpha: 0.15),
                      ),
                    ),
                  ),
                  // Blur Overlay
                  Positioned.fill(
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 100, sigmaY: 100),
                      child: Container(color: Colors.transparent),
                    ),
                  ),
                ],
              );
            }
          ),
          
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
                accentColor: slide['colors'][0],
              );
            },
          ),
          
          // Bottom Navigation
          Positioned(
            bottom: 60,
            left: 30,
            right: 30,
            child: Column(
              children: [
                // Glassmorphic Indicator
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: List.generate(
                      _slides.length,
                      (index) => AnimatedContainer(
                        duration: const Duration(milliseconds: 400),
                        curve: Curves.easeOutCubic,
                        margin: const EdgeInsets.symmetric(horizontal: 6),
                        height: 6,
                        width: _currentPage == index ? 24 : 6,
                        decoration: BoxDecoration(
                          color: _currentPage == index ? Colors.white : Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(3),
                          boxShadow: [
                            if (_currentPage == index)
                              BoxShadow(
                                color: Colors.white.withValues(alpha: 0.5),
                                blurRadius: 8,
                                spreadRadius: 1,
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 48),
                
                // Get Started Button
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  width: double.infinity,
                  height: 64,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: (_slides[_currentPage]['colors'][0] as Color).withValues(alpha: 0.3),
                        blurRadius: 20,
                        spreadRadius: 2,
                        offset: const Offset(0, 8),
                      )
                    ],
                  ),
                  child: ElevatedButton(
                    onPressed: () {
                      if (_currentPage < _slides.length - 1) {
                        _pageController.nextPage(
                          duration: const Duration(milliseconds: 800),
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
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    child: Text(
                      _currentPage == _slides.length - 1 ? 'START CREATING' : 'CONTINUE',
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        letterSpacing: 2.0,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
                
                const SizedBox(height: 16),
                if (_currentPage < _slides.length - 1)
                  TextButton(
                    onPressed: _finishOnboarding,
                    child: Text(
                      'SKIP TOUR',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.5),
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.5,
                      ),
                    ),
                  )
                else
                  const SizedBox(height: 48), 
              ],
            ),
          ),
        ],
      ),
    );
  }
}
