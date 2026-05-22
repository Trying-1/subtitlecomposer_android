import 'package:flutter/material.dart';
import 'dart:ui';

class OnboardingSlide extends StatefulWidget {
  final String title;
  final String tagline;
  final String description;
  final bool isVisible;
  final Color accentColor;

  const OnboardingSlide({
    super.key,
    required this.title,
    required this.tagline,
    required this.description,
    required this.isVisible,
    required this.accentColor,
  });

  @override
  State<OnboardingSlide> createState() => _OnboardingSlideState();
}

class _OnboardingSlideState extends State<OnboardingSlide> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    if (widget.isVisible) {
      _controller.forward();
    }
  }

  @override
  void didUpdateWidget(OnboardingSlide oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isVisible && !oldWidget.isVisible) {
      _controller.forward(from: 0.0);
    } else if (!widget.isVisible && oldWidget.isVisible) {
      _controller.reverse();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Animated Graphic / Abstract Shape instead of static icon
          Center(
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                final scale = Curves.easeOutBack.transform(_controller.value);
                final rotation = _controller.value * 2 * 3.14159;
                return Transform.scale(
                  scale: scale,
                  child: Transform.rotate(
                    angle: rotation,
                    child: Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(40),
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            widget.accentColor,
                            widget.accentColor.withValues(alpha: 0.2),
                          ]
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: widget.accentColor.withValues(alpha: 0.3),
                            blurRadius: 30,
                            spreadRadius: 5,
                          )
                        ]
                      ),
                      child: const Center(
                        child: Icon(Icons.auto_awesome, color: Colors.white, size: 48),
                      ),
                    ),
                  ),
                );
              }
            ),
          ),
          const SizedBox(height: 60),
          
          // Glassmorphic Content Card
          AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              final slideUp = Curves.easeOutQuart.transform(_controller.value);
              final opacity = Curves.easeIn.transform(_controller.value);
              return Transform.translate(
                offset: Offset(0, 50 * (1 - slideUp)),
                child: Opacity(
                  opacity: opacity,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(30),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                      child: Container(
                        padding: const EdgeInsets.all(32),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(30),
                          border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                        ),
                        child: Column(
                          children: [
                            Text(
                              widget.tagline,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: widget.accentColor,
                                fontSize: 11,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 2.5,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              widget.title,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 36,
                                fontWeight: FontWeight.w900,
                                letterSpacing: -1.0,
                                height: 1.1,
                              ),
                            ),
                            const SizedBox(height: 20),
                            Text(
                              widget.description,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.6),
                                fontSize: 15,
                                height: 1.6,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }
          ),
          const SizedBox(height: 40), // spacer for bottom nav
        ],
      ),
    );
  }
}
