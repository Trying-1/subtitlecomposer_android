import 'package:flutter/material.dart';
import 'dart:ui';
import 'dart:math' as math;

class OnboardingSlide extends StatefulWidget {
  final String title;
  final String tagline;
  final String description;
  final bool isVisible;
  final Color accentColor;
  final String layoutType;

  const OnboardingSlide({
    super.key,
    required this.title,
    required this.tagline,
    required this.description,
    required this.isVisible,
    required this.accentColor,
    required this.layoutType,
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
      duration: const Duration(milliseconds: 1600),
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

  Widget _buildMasonryShowcase() {
    final words = [
      {'text': 'Create', 'x': -0.6, 'y': -0.4, 'size': 26.0, 'color': const Color(0xFFF5F5F7), 'font': 'Poppins', 'weight': FontWeight.w900, 'style': FontStyle.normal},
      {'text': 'trending', 'x': 0.4, 'y': -0.3, 'size': 18.0, 'color': const Color(0xFFC5B8AC), 'font': 'KleeOne', 'weight': FontWeight.normal, 'style': FontStyle.italic},
      {'text': 'typography', 'x': -0.3, 'y': 0.2, 'size': 28.0, 'color': const Color(0xFFC5B8AC), 'font': 'Poppins', 'weight': FontWeight.w900, 'style': FontStyle.normal},
      {'text': 'Edits', 'x': 0.5, 'y': 0.6, 'size': 22.0, 'color': const Color(0xFFF5F5F7), 'font': 'Michroma', 'weight': FontWeight.w300, 'style': FontStyle.normal},
    ];

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final val = _controller.value;
        return Container(
          width: double.infinity,
          height: 190,
          decoration: BoxDecoration(
            color: const Color(0xFF0A0A0C),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withValues(alpha: 0.05), width: 1),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Stack(
              children: [
                Positioned.fill(
                  child: CustomPaint(
                    painter: GridPainter(color: Colors.white.withValues(alpha: 0.008)),
                  ),
                ),
                ...List.generate(words.length, (index) {
                  final item = words[index];
                  final delayVal = ((val - (index * 0.08)).clamp(0.0, 1.0));
                  final animVal = Curves.easeOutQuart.transform(delayVal);
                  final floatVal = math.sin(val * math.pi * 2 + index) * 3;

                  return Align(
                    alignment: Alignment(item['x'] as double, (item['y'] as double)),
                    child: Transform.translate(
                      offset: Offset(0, floatVal + 15 * (1 - animVal)),
                      child: Opacity(
                        opacity: animVal,
                        child: Text(
                          item['text'] as String,
                          style: TextStyle(
                            color: item['color'] as Color,
                            fontSize: item['size'] as double,
                            fontWeight: item['weight'] as FontWeight,
                            fontFamily: item['font'] as String,
                            fontStyle: item['style'] as FontStyle,
                            letterSpacing: item['font'] == 'Michroma' ? 3.0 : 0.5,
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildBlockyShowcase() {
    final blocks = [
      {'text': 'Grow', 'size': 28.0, 'color': const Color(0xFFF5F5F7), 'font': 'Poppins', 'weight': FontWeight.w900, 'style': FontStyle.normal, 'padding': 4.0},
      {'text': 'your', 'size': 14.0, 'color': const Color(0xFFC5B8AC), 'font': 'KleeOne', 'weight': FontWeight.normal, 'style': FontStyle.italic, 'padding': 2.0},
      {'text': 'social media', 'size': 24.0, 'color': const Color(0xFF9EAFBE), 'font': 'Michroma', 'weight': FontWeight.w700, 'style': FontStyle.normal, 'padding': 6.0},
      {'text': 'page', 'size': 32.0, 'color': const Color(0xFFF5F5F7), 'font': 'Poppins', 'weight': FontWeight.w900, 'style': FontStyle.normal, 'padding': 4.0},
    ];

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final val = _controller.value;
        return Container(
          width: double.infinity,
          height: 190,
          decoration: BoxDecoration(
            color: const Color(0xFF0A0A0C),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withValues(alpha: 0.05), width: 1),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Stack(
              children: [
                Positioned.fill(
                  child: CustomPaint(
                    painter: GridPainter(color: Colors.white.withValues(alpha: 0.008)),
                  ),
                ),
                Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: List.generate(blocks.length, (index) {
                      final item = blocks[index];
                      final delayVal = ((val - (index * 0.12)).clamp(0.0, 1.0));
                      final animVal = Curves.easeOutBack.transform(delayVal);

                      return Transform.translate(
                        offset: Offset(0, 15 * (1 - animVal)),
                        child: Opacity(
                          opacity: animVal.clamp(0.0, 1.0),
                          child: Padding(
                            padding: EdgeInsets.symmetric(vertical: item['padding'] as double),
                            child: Text(
                              item['text'] as String,
                              style: TextStyle(
                                color: item['color'] as Color,
                                fontSize: item['size'] as double,
                                fontWeight: item['weight'] as FontWeight,
                                fontFamily: item['font'] as String,
                                fontStyle: item['style'] as FontStyle,
                                letterSpacing: item['font'] == 'Michroma' ? 4.0 : 0.5,
                              ),
                            ),
                          ),
                        ),
                      );
                    }),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStairShowcase() {
    final steps = [
      {'text': 'Seamless', 'x': -0.6, 'y': -0.5, 'size': 16.0, 'color': const Color(0xFFC5B8AC), 'font': 'KleeOne', 'weight': FontWeight.normal, 'style': FontStyle.italic},
      {'text': 'typography', 'x': 0.0, 'y': 0.1, 'size': 22.0, 'color': const Color(0xFF9EAFBE), 'font': 'Poppins', 'weight': FontWeight.bold, 'style': FontStyle.normal},
      {'text': 'editor', 'x': 0.6, 'y': 0.7, 'size': 26.0, 'color': const Color(0xFFF5F5F7), 'font': 'Michroma', 'weight': FontWeight.w900, 'style': FontStyle.normal},
    ];

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final val = _controller.value;
        return Container(
          width: double.infinity,
          height: 190,
          decoration: BoxDecoration(
            color: const Color(0xFF0A0A0C),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withValues(alpha: 0.05), width: 1),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Stack(
              children: [
                Positioned.fill(
                  child: CustomPaint(
                    painter: GridPainter(color: Colors.white.withValues(alpha: 0.008)),
                  ),
                ),
                ...List.generate(steps.length - 1, (index) {
                  final start = steps[index];
                  final end = steps[index + 1];
                  final startAlign = Alignment(start['x'] as double, start['y'] as double);
                  final endAlign = Alignment(end['x'] as double, end['y'] as double);

                  return Positioned.fill(
                    child: Opacity(
                      opacity: val.clamp(0.0, 0.15),
                      child: CustomPaint(
                        painter: StairLinePainter(
                          start: startAlign,
                          end: endAlign,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  );
                }),
                ...List.generate(steps.length, (index) {
                  final item = steps[index];
                  final delayVal = ((val - (index * 0.12)).clamp(0.0, 1.0));
                  final animVal = Curves.easeOutBack.transform(delayVal);

                  return Align(
                    alignment: Alignment(item['x'] as double, item['y'] as double),
                    child: Transform.scale(
                      scale: animVal,
                      child: Opacity(
                        opacity: animVal,
                        child: Text(
                          item['text'] as String,
                          style: TextStyle(
                            color: item['color'] as Color,
                            fontSize: item['size'] as double,
                            fontWeight: item['weight'] as FontWeight,
                            fontFamily: item['font'] as String,
                            fontStyle: item['style'] as FontStyle,
                            letterSpacing: item['font'] == 'Michroma' ? 3.0 : 0.5,
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            height: 190,
            alignment: Alignment.center,
            child: widget.layoutType == 'masonry'
                ? _buildMasonryShowcase()
                : widget.layoutType == 'blocky'
                    ? _buildBlockyShowcase()
                    : _buildStairShowcase(),
          ),
          const SizedBox(height: 48),

          // Pure cardless typography text layout
          AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              final slideUp = Curves.easeOutQuart.transform(_controller.value);
              final opacity = Curves.easeIn.transform(_controller.value);
              return Transform.translate(
                offset: Offset(0, 30 * (1 - slideUp)),
                child: Opacity(
                  opacity: opacity,
                  child: Column(
                    children: [
                      Text(
                        widget.tagline,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: widget.accentColor,
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 4.0,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        widget.title,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.5,
                          height: 1.15,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Text(
                          widget.description,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.45),
                            fontSize: 13.5,
                            height: 1.6,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }
}

class GridPainter extends CustomPainter {
  final Color color;
  GridPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 0.5;

    const step = 25.0;
    for (double x = 0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant GridPainter oldDelegate) => false;
}

class StairLinePainter extends CustomPainter {
  final Alignment start;
  final Alignment end;
  final Color color;

  StairLinePainter({required this.start, required this.end, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withValues(alpha: 0.08)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    final p1 = Offset(
      (start.x + 1) * size.width / 2,
      (start.y + 1) * size.height / 2,
    );
    final p2 = Offset(
      (end.x + 1) * size.width / 2,
      (end.y + 1) * size.height / 2,
    );

    final path = Path()
      ..moveTo(p1.dx, p1.dy)
      ..lineTo(p2.dx, p1.dy)
      ..lineTo(p2.dx, p2.dy);

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant StairLinePainter oldDelegate) => false;
}
