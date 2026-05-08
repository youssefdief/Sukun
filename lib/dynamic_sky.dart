import 'dart:math';
import 'dart:async';
import 'package:flutter/material.dart';

class DynamicSky extends StatefulWidget {
  final DateTime? currentTime;
  final String? currentPrayerKey;
  final double scrollOffset;

  const DynamicSky({
    Key? key,
    this.currentTime,
    this.currentPrayerKey,
    this.scrollOffset = 0.0,
  }) : super(key: key);

  @override
  State<DynamicSky> createState() => _DynamicSkyState();
}

class _DynamicSkyState extends State<DynamicSky> with SingleTickerProviderStateMixin {
  late DateTime _now;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _now = widget.currentTime ?? DateTime.now();
    if (widget.currentTime == null) {
      _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (mounted) {
          setState(() {
            _now = DateTime.now();
          });
        }
      });
    }
  }

  @override
  void didUpdateWidget(DynamicSky oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.currentTime != null) {
      _now = widget.currentTime!;
      _timer?.cancel();
      _timer = null;
    } else if (_timer == null) {
      _now = DateTime.now();
      _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (mounted) {
          setState(() {
            _now = DateTime.now();
          });
        }
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  double get _timeProgress {
    return (_now.hour * 3600 + _now.minute * 60 + _now.second) / 86400.0;
  }

  List<Color> _getGradientColors(double progress) {
    final night = [
      const Color(0xFF070B14),
      const Color(0xFF0C0E12),
      const Color(0xFF131821),
    ];
    final dawn = [
      const Color(0xFF1B2735),
      const Color(0xFF2B4C6A),
      const Color(0xFF5A7B8E),
    ];
    final day = [
      const Color(0xFF4A90E2),
      const Color(0xFF8BB9E8),
      const Color(0xFFC4E0E5),
    ];
    final sunset = [
      const Color(0xFF2C1B35),
      const Color(0xFF8A3D5B),
      const Color(0xFFD67B54),
    ];

    if (progress >= 0.0 && progress < 0.20) return night;
    if (progress >= 0.20 && progress < 0.25) return _lerpList(night, dawn, (progress - 0.20) / 0.05);
    if (progress >= 0.25 && progress < 0.30) return _lerpList(dawn, day, (progress - 0.25) / 0.05);
    if (progress >= 0.30 && progress < 0.70) return day;
    if (progress >= 0.70 && progress < 0.75) return _lerpList(day, sunset, (progress - 0.70) / 0.05);
    if (progress >= 0.75 && progress < 0.80) return _lerpList(sunset, night, (progress - 0.75) / 0.05);
    return night;
  }

  List<Color> _lerpList(List<Color> a, List<Color> b, double t) {
    return [
      Color.lerp(a[0], b[0], t)!,
      Color.lerp(a[1], b[1], t)!,
      Color.lerp(a[2], b[2], t)!,
    ];
  }

  @override
  Widget build(BuildContext context) {
    final progress = _timeProgress;
    final gradientColors = _getGradientColors(progress);
    
    double starsOpacity = 0.0;
    if (progress < 0.20 || progress > 0.80) {
      starsOpacity = 1.0;
    } else if (progress >= 0.20 && progress < 0.25) {
      starsOpacity = 1.0 - ((progress - 0.20) / 0.05);
    } else if (progress >= 0.75 && progress < 0.80) {
      starsOpacity = (progress - 0.75) / 0.05;
    }

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: gradientColors,
          stops: const [0.0, 0.5, 1.0],
        ),
      ),
      child: Stack(
        children: [
          if (starsOpacity > 0)
            Positioned.fill(
              child: Opacity(
                opacity: starsOpacity,
                child: StarLayer(scrollOffset: widget.scrollOffset),
              ),
            ),
            
          Positioned.fill(
            child: CelestialBodies(
              progress: progress,
              scrollOffset: widget.scrollOffset,
            ),
          ),

          Positioned.fill(
            child: Opacity(
              opacity: 0.8,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: const Alignment(0, -1),
                    radius: 1.5,
                    colors: [
                      const Color(0xFF007542).withValues(alpha: 0.1),
                      Colors.transparent,
                    ],
                    stops: const [0.0, 0.8],
                  ),
                ),
              ),
            ),
          ),
          
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            height: MediaQuery.of(context).size.height * 0.4,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [
                    const Color(0xFF0C0E12),
                    const Color(0xFF0C0E12).withValues(alpha: 0.8),
                    Colors.transparent
                  ],
                ),
              ),
            ),
          )
        ],
      ),
    );
  }
}

class CelestialBodies extends StatelessWidget {
  final double progress; 
  final double scrollOffset;
  const CelestialBodies({Key? key, required this.progress, required this.scrollOffset}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;
        final h = constraints.maxHeight;

        Widget? sun;
        if (progress > 0.20 && progress < 0.80) {
          double sunP = (progress - 0.20) / 0.60;
          double sunX = w * sunP;
          double sunY = h * 0.6 - (h * 0.4 * sin(sunP * pi)) - (scrollOffset * 0.3);
          
          double sunOpacity = 1.0;
          if (sunP < 0.1) sunOpacity = sunP / 0.1;
          if (sunP > 0.9) sunOpacity = (1.0 - sunP) / 0.1;

          sun = Positioned(
            left: sunX - 40,
            top: sunY - 40,
            child: Opacity(
              opacity: sunOpacity,
              child: const SunWidget(),
            ),
          );
        }

        Widget? moon;
        double moonP;
        if (progress >= 0.70) {
          moonP = (progress - 0.70) / 0.60;
        } else if (progress <= 0.30) {
          moonP = (progress + 0.30) / 0.60;
        } else {
          moonP = -1;
        }

        if (moonP >= 0) {
          double moonX = w * moonP;
          double moonY = h * 0.6 - (h * 0.4 * sin(moonP * pi)) - (scrollOffset * 0.3);

          double moonOpacity = 1.0;
          if (moonP < 0.1) moonOpacity = moonP / 0.1;
          if (moonP > 0.9) moonOpacity = (1.0 - moonP) / 0.1;

          moon = Positioned(
            left: moonX - 36,
            top: moonY - 36,
            child: Opacity(
              opacity: moonOpacity,
              child: const MoonWidget(hijriDate: "15"),
            ),
          );
        }

        return Stack(
          clipBehavior: Clip.none,
          children: [
            if (sun != null) sun,
            if (moon != null) moon,
          ],
        );
      },
    );
  }
}

class SunWidget extends StatelessWidget {
  const SunWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 80,
      height: 80,
      child: CustomPaint(
        painter: _SunPainter(),
      ),
    );
  }
}

class _SunPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    final glowPaint = Paint()
      ..color = const Color(0xFFFFD54F).withValues(alpha: 0.3)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 20);
    canvas.drawCircle(center, radius, glowPaint);

    final glowPaint2 = Paint()
      ..color = const Color(0xFFFFF59D).withValues(alpha: 0.5)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);
    canvas.drawCircle(center, radius * 0.7, glowPaint2);

    final corePaint = Paint()
      ..color = Colors.white
      ..maskFilter = const MaskFilter.blur(BlurStyle.solid, 2);
    canvas.drawCircle(center, radius * 0.4, corePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class StarLayer extends StatefulWidget {
  final double scrollOffset;
  const StarLayer({Key? key, required this.scrollOffset}) : super(key: key);

  @override
  State<StarLayer> createState() => _StarLayerState();
}

class _StarLayerState extends State<StarLayer>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final Random _random = Random(42);
  late List<_Star> _stars;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);

    _stars = List.generate(50, (index) {
      return _Star(
        x: _random.nextDouble(),
        y: _random.nextDouble(),
        size: _random.nextDouble() * 2 + 1,
        twinkleSpeed: _random.nextDouble() * 2 + 0.5,
        twinklePhase: _random.nextDouble() * 2 * pi,
      );
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return CustomPaint(
          painter: _StarPainter(
            stars: _stars,
            animationValue: _controller.value,
            scrollOffset: widget.scrollOffset,
          ),
        );
      },
    );
  }
}

class _Star {
  final double x;
  final double y;
  final double size;
  final double twinkleSpeed;
  final double twinklePhase;

  _Star({
    required this.x,
    required this.y,
    required this.size,
    required this.twinkleSpeed,
    required this.twinklePhase,
  });
}

class _StarPainter extends CustomPainter {
  final List<_Star> stars;
  final double animationValue;
  final double scrollOffset;

  _StarPainter({
    required this.stars,
    required this.animationValue,
    required this.scrollOffset,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.white;
    final time = DateTime.now().millisecondsSinceEpoch / 1000.0;

    for (var star in stars) {
      double parallaxY = (star.y * size.height) - (scrollOffset * 0.1 * star.size);
      
      if (parallaxY < 0) {
        parallaxY = size.height + (parallaxY % size.height);
      } else if (parallaxY > size.height) {
        parallaxY = parallaxY % size.height;
      }

      double x = star.x * size.width;

      double opacity = 0.3 + 0.7 * (0.5 * (1 + sin(time * star.twinkleSpeed + star.twinklePhase)));
      paint.color = Colors.white.withValues(alpha: opacity);
      
      if (star.size > 2.0) {
        canvas.drawCircle(Offset(x, parallaxY), star.size / 2, paint);
        canvas.drawCircle(
            Offset(x, parallaxY),
            star.size,
            Paint()
              ..color = Colors.white.withValues(alpha: opacity * 0.3)
              ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2));
      } else {
        canvas.drawCircle(Offset(x, parallaxY), star.size / 2, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _StarPainter oldDelegate) {
    return true; 
  }
}

class MoonWidget extends StatelessWidget {
  final String hijriDate;
  
  const MoonWidget({Key? key, required this.hijriDate}) : super(key: key);

  int _parseHijriDay(String dateStr) {
    if (dateStr.isEmpty) return 15;
    try {
      final parts = dateStr.split(' ');
      if (parts.isNotEmpty) {
        return int.parse(parts[0]);
      }
    } catch (e) {
      // Return default if parsing fails
    }
    return 15;
  }

  @override
  Widget build(BuildContext context) {
    final int day = _parseHijriDay(hijriDate);

    return SizedBox(
      width: 72,
      height: 72,
      child: CustomPaint(
        painter: _MoonPainter(day: day),
      ),
    );
  }
}

class _MoonPainter extends CustomPainter {
  final int day;

  _MoonPainter({required this.day});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    int normalizedDay = (day % 30);
    if (normalizedDay == 0) normalizedDay = 30;

    final glowPaint = Paint()
      ..color = const Color(0xFFDCE2F7).withValues(alpha: 0.3)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 15);
    canvas.drawCircle(center, radius, glowPaint);

    final basePaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topRight,
        end: Alignment.bottomLeft,
        colors: [Color(0xFFE8EDF9), Color(0xFFB0B9D6)],
      ).createShader(Rect.fromCircle(center: center, radius: radius));
    
    canvas.drawCircle(center, radius, basePaint);

    if (normalizedDay != 15) {
      final shadowPaint = Paint()
        ..color = const Color(0xFF070B14).withValues(alpha: 0.95); 
      
      double offsetFactor;
      if (normalizedDay < 15) {
        offsetFactor = 1.0 - (normalizedDay / 15.0);
        canvas.drawCircle(
            Offset(center.dx - (radius * 0.8 * offsetFactor), center.dy),
            radius,
            shadowPaint);
      } else {
        offsetFactor = ((normalizedDay - 15) / 15.0);
        canvas.drawCircle(
            Offset(center.dx + (radius * 0.8 * offsetFactor), center.dy),
            radius,
            shadowPaint);
      }
    }
    
    if (normalizedDay > 10 && normalizedDay < 20) {
      final craterPaint = Paint()
        ..color = const Color(0xFF909BBF).withValues(alpha: 0.2)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);
      canvas.drawCircle(Offset(center.dx - radius * 0.2, center.dy - radius * 0.3), radius * 0.15, craterPaint);
      canvas.drawCircle(Offset(center.dx + radius * 0.3, center.dy + radius * 0.1), radius * 0.25, craterPaint);
      canvas.drawCircle(Offset(center.dx - radius * 0.1, center.dy + radius * 0.3), radius * 0.1, craterPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _MoonPainter oldDelegate) {
    return oldDelegate.day != day;
  }
}
