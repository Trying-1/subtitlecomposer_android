import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'dart:math' as math;
import '../home/home_screen.dart';
import '../onboarding/onboarding_screen.dart';
import '../main_navigation.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with TickerProviderStateMixin {
  late AnimationController _mainController;
  late AnimationController _wordController;
  
  final List<String> _kineticWords = ["CREATE.", "ANIMATE.", "VOICE."];
  int _currentWordIndex = 0;

  late Animation<double> _logoScale;
  late Animation<double> _logoOpacity;
  late Animation<double> _taglineOpacity;
  late Animation<double> _glitchAnimation;
  
  bool _showFinalLogo = false;

  @override
  void initState() {
    super.initState();
    
    _mainController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );

    _wordController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _glitchAnimation = TweenSequence([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 5.0), weight: 1),
      TweenSequenceItem(tween: Tween(begin: 5.0, end: -5.0), weight: 1),
      TweenSequenceItem(tween: Tween(begin: -5.0, end: 0.0), weight: 1),
    ]).animate(CurvedAnimation(parent: _wordController, curve: const Interval(0.0, 0.3)));

    _logoScale = Tween<double>(begin: 0.7, end: 1.0).animate(
      CurvedAnimation(parent: _mainController, curve: Curves.easeOutExpo),
    );
    _logoOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _mainController, curve: const Interval(0.0, 0.6, curve: Curves.easeIn)),
    );
    _taglineOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _mainController, curve: const Interval(0.4, 1.0, curve: Curves.easeIn)),
    );

    _startAdvancedSequence();
  }

  Future<void> _startAdvancedSequence() async {
    for (int i = 0; i < _kineticWords.length; i++) {
      if (!mounted) return;
      setState(() {
        _currentWordIndex = i;
      });
      
      // Smash in
      await _wordController.forward(from: 0.0);
      await Future.delayed(const Duration(milliseconds: 600));
      
      if (i < _kineticWords.length - 1) {
        // High speed exit
        await _wordController.animateTo(0.0, duration: const Duration(milliseconds: 200), curve: Curves.easeInBack);
      }
    }
    
    // Final Glitch and Reveal
    await _wordController.animateTo(0.0, duration: const Duration(milliseconds: 300), curve: Curves.easeIn);
    if (!mounted) return;
    
    setState(() {
      _showFinalLogo = true;
    });
    _mainController.forward();
    
    _navigateToNext();
  }

  Future<void> _navigateToNext() async {
    await Future.delayed(const Duration(milliseconds: 3000));
    if (!mounted) return;

    final settingsBox = Hive.box('settings_box');
    final bool onboardingShown = settingsBox.get('onboarding_shown', defaultValue: false);

    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => 
            onboardingShown ? const MainNavigation() : const OnboardingScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: const Duration(milliseconds: 1000),
      ),
    );
  }

  @override
  void dispose() {
    _mainController.dispose();
    _wordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Background with Motion Graphics Noise/Scanlines
          Positioned.fill(child: _buildBackground()),
          
          Center(
            child: _showFinalLogo 
              ? _buildFinalLogo()
              : _buildAdvancedKineticText(),
          ),
          
          // Technical Overlay
          if (!_showFinalLogo)
            _buildTechnicalOverlay(),
        ],
      ),
    );
  }

  Widget _buildBackground() {
    return AnimatedBuilder(
      animation: _mainController,
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: Alignment.center,
              radius: 1.5,
              colors: [
                const Color(0xFF001A33).withOpacity(0.6),
                Colors.black,
              ],
            ),
          ),
          child: Stack(
            children: [
              // Subtle Scanlines
              Positioned.fill(
                child: Opacity(
                  opacity: 0.05,
                  child: ListView.builder(
                    physics: const NeverScrollableScrollPhysics(),
                    itemBuilder: (context, index) => Container(
                      height: 2,
                      color: Colors.white,
                      margin: const EdgeInsets.only(bottom: 2),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAdvancedKineticText() {
    final word = _kineticWords[_currentWordIndex];
    return AnimatedBuilder(
      animation: _wordController,
      builder: (context, child) {
        return Stack(
          alignment: Alignment.center,
          children: [
            // Ghosting / Motion Blur Effect
            if (_wordController.value > 0.1 && _wordController.value < 0.9)
              ...List.generate(3, (index) {
                final offset = (index + 1) * 10.0 * (1.0 - _wordController.value);
                return Opacity(
                  opacity: (0.3 / (index + 1)) * _wordController.value,
                  child: Transform.translate(
                    offset: Offset(offset, 0),
                    child: _buildWordRow(word, isGhost: true),
                  ),
                );
              }),
            
            // Primary Text with Glitch/Shake
            Transform.translate(
              offset: Offset(_glitchAnimation.value, 0),
              child: _buildWordRow(word),
            ),
          ],
        );
      },
    );
  }

  Widget _buildWordRow(String word, {bool isGhost = false}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(word.length, (index) {
        final char = word[index];
        
        // Staggered reveal per letter
        final double start = index * 0.05;
        final double end = (index * 0.05) + 0.4;
        final animValue = CurvedAnimation(
          parent: _wordController,
          curve: Interval(start.clamp(0.0, 1.0), end.clamp(0.0, 1.0), curve: Curves.elasticOut),
        ).value;

        return Opacity(
          opacity: isGhost ? 1.0 : animValue.clamp(0.0, 1.0),
          child: Transform.scale(
            scale: isGhost ? 1.0 : 0.5 + (animValue * 0.5),
            child: Transform.rotate(
              angle: isGhost ? 0 : (1.0 - animValue) * 0.2,
              child: Text(
                char,
                style: TextStyle(
                  color: isGhost ? Colors.amberAccent : Colors.white,
                  fontSize: 64,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -2.0,
                  fontStyle: FontStyle.italic,
                  shadows: isGhost ? [] : [
                    Shadow(
                      color: Colors.amberAccent.withOpacity(0.3 * animValue),
                      blurRadius: 20 * animValue,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      }),
    );
  }

  Widget _buildFinalLogo() {
    return AnimatedBuilder(
      animation: _mainController,
      builder: (context, child) {
        return Opacity(
          opacity: _logoOpacity.value,
          child: Transform.scale(
            scale: _logoScale.value,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Logo Container with Cinematic Glow
                Container(
                  width: 160,
                  height: 160,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.amberAccent.withOpacity(0.15 * _mainController.value),
                        blurRadius: 100,
                        spreadRadius: 30,
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(40),
                    child: Image.asset(
                      'assets/images/app_logo.png',
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                const SizedBox(height: 40),
                const Text(
                  'TYPO EDIT',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 40,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 12.0,
                  ),
                ),
                const SizedBox(height: 16),
                Opacity(
                  opacity: _taglineOpacity.value,
                  child: Text(
                    'ANIMATE YOUR VOICE',
                    style: TextStyle(
                      color: Colors.amberAccent,
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 4.0,
                      shadows: [
                        Shadow(
                          color: Colors.amberAccent.withOpacity(0.5),
                          blurRadius: 10,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildTechnicalOverlay() {
    return Positioned.fill(
      child: IgnorePointer(
        child: CustomPaint(
          painter: TechnicalPainter(progress: _wordController.value),
        ),
      ),
    );
  }
}

class TechnicalPainter extends CustomPainter {
  final double progress;
  TechnicalPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.1)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    // Drawing small technical corners
    const length = 20.0;
    const margin = 40.0;

    // Top Left
    canvas.drawLine(const Offset(margin, margin), const Offset(margin + length, margin), paint);
    canvas.drawLine(const Offset(margin, margin), const Offset(margin, margin + length), paint);

    // Top Right
    canvas.drawLine(Offset(size.width - margin, margin), Offset(size.width - margin - length, margin), paint);
    canvas.drawLine(Offset(size.width - margin, margin), Offset(size.width - margin, margin + length), paint);

    // Bottom Left
    canvas.drawLine(Offset(margin, size.height - margin), Offset(margin + length, size.height - margin), paint);
    canvas.drawLine(Offset(margin, size.height - margin), Offset(margin, size.height - margin - length), paint);

    // Bottom Right
    canvas.drawLine(Offset(size.width - margin, size.height - margin), Offset(size.width - margin - length, size.height - margin), paint);
    canvas.drawLine(Offset(size.width - margin, size.height - margin), Offset(size.width - margin, size.height - margin - length), paint);
  }

  @override
  bool shouldRepaint(TechnicalPainter oldDelegate) => oldDelegate.progress != progress;
}
