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
      'title': 'Animate Text',
      'description': 'Create stunning typography animations with ease and precision.',
      'icon': Icons.auto_awesome_motion_rounded,
    },
    {
      'title': 'Native Precision',
      'description': 'Frame-perfect editing powered by a high-performance native engine.',
      'icon': Icons.high_quality_rounded,
    },
    {
      'title': 'Fast Export',
      'description': 'Export your projects in 4K resolution within seconds.',
      'icon': Icons.bolt_rounded,
    },
  ];

  Future<void> _finishOnboarding() async {
    final box = Hive.box('settings_box');
    await box.put('onboarding_shown', true);
    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const HomeScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      body: Stack(
        children: [
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
                description: slide['description'],
                icon: slide['icon'],
              );
            },
          ),
          
          // Bottom Navigation
          Positioned(
            bottom: 60,
            left: 40,
            right: 40,
            child: Column(
              children: [
                // Indicators
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    _slides.length,
                    (index) => AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      height: 4,
                      width: _currentPage == index ? 24 : 8,
                      decoration: BoxDecoration(
                        color: _currentPage == index ? Colors.white : Colors.white24,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 48),
                
                // Button
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: () {
                      if (_currentPage < _slides.length - 1) {
                        _pageController.nextPage(
                          duration: const Duration(milliseconds: 500),
                          curve: Curves.easeInOutCubic,
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
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      _currentPage == _slides.length - 1 ? 'GET STARTED' : 'NEXT',
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.2,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
                
                if (_currentPage < _slides.length - 1)
                  TextButton(
                    onPressed: _finishOnboarding,
                    child: Text(
                      'SKIP',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.3),
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.0,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
