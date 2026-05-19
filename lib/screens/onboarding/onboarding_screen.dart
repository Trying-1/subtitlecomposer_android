import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'onboarding_slide.dart';
import '../home/home_screen.dart';

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
      'title': 'TYPO EDIT',
      'tagline': 'ANIMATE YOUR VOICE',
      'description': 'The ultimate tool for creators to turn text into high-impact visual stories.',
      'icon': Icons.auto_awesome_rounded,
    },
    {
      'title': 'Kinetic Power',
      'tagline': 'MOTION THAT SPEAKS',
      'description': 'Bring your words to life with fluid, physics-based motion and cinematic transitions.',
      'icon': Icons.animation_rounded,
    },
    {
      'title': 'Studio Quality',
      'tagline': 'EXPORT WITH CONFIDENCE',
      'description': 'Render 4K cinematic typography videos in seconds, ready for any platform.',
      'icon': Icons.videocam_rounded,
    },
  ];

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
          // Background subtle gradient
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    const Color(0xFF001529).withOpacity(0.5),
                    Colors.black,
                  ],
                ),
              ),
            ),
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
                icon: slide['icon'],
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
                // Indicators
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    _slides.length,
                    (index) => AnimatedContainer(
                      duration: const Duration(milliseconds: 400),
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      height: 4,
                      width: _currentPage == index ? 32 : 8,
                      decoration: BoxDecoration(
                        color: _currentPage == index ? Colors.amberAccent : Colors.white24,
                        borderRadius: BorderRadius.circular(2),
                        boxShadow: [
                          if (_currentPage == index)
                            BoxShadow(
                              color: Colors.amberAccent.withOpacity(0.3),
                              blurRadius: 10,
                              spreadRadius: 1,
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 48),
                
                // Button
                SizedBox(
                  width: double.infinity,
                  height: 64,
                  child: ElevatedButton(
                    onPressed: () {
                      if (_currentPage < _slides.length - 1) {
                        _pageController.nextPage(
                          duration: const Duration(milliseconds: 600),
                          curve: Curves.easeOutQuart,
                        );
                      } else {
                        _finishOnboarding();
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.amberAccent,
                      foregroundColor: Colors.black,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: Text(
                      _currentPage == _slides.length - 1 ? 'START CREATING' : 'CONTINUE',
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        letterSpacing: 2.0,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ),
                
                const SizedBox(height: 12),
                if (_currentPage < _slides.length - 1)
                  TextButton(
                    onPressed: _finishOnboarding,
                    child: Text(
                      'SKIP TOUR',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.3),
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.5,
                      ),
                    ),
                  )
                else
                  const SizedBox(height: 48), // Spacer for consistency
              ],
            ),
          ),
        ],
      ),
    );
  }
}
