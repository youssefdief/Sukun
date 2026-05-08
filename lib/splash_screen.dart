import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'main_screen.dart';
import 'onboarding_screen.dart';
import 'notification_service.dart';
import 'location_service.dart';
import 'prayer_service.dart';
import 'localization_service.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  bool _isSplashEnabled = true;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    
    _initializeApp();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _initializeApp() async {
    final prefs = await SharedPreferences.getInstance();
    final splashEnabled = prefs.getBool('splash_enabled') ?? true;
    final splashDuration = prefs.getDouble('splash_duration') ?? 2.5;

    setState(() {
      _isSplashEnabled = splashEnabled;
    });

    if (splashEnabled) {
      _animationController.forward();
    }

    try {
      await NotificationService().initializeNotifications();
      final dhikrNotificationsEnabled = prefs.getBool('dhikr_notifications') ?? true;
      if (dhikrNotificationsEnabled) {
        await NotificationService().rescheduleAllDhikrNotifications();
      }
      
      final locationService = LocationService();
      if (await locationService.isFirstLaunch()) {
        await locationService.determinePosition();
      }

      await PrayerService().fetchPrayerTimes();
    } catch (e) {
      debugPrint('Error initializing app: $e');
    }

    if (splashEnabled) {
      final waitMs = (splashDuration * 1000).toInt();
      if (waitMs > 0) {
        await Future.delayed(Duration(milliseconds: waitMs));
      }
    }

    final hasCompletedOnboarding = prefs.getBool('has_completed_onboarding') ?? false;

    if (mounted) {
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) => 
              hasCompletedOnboarding ? const MainScreen() : const OnboardingScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
          transitionDuration: const Duration(milliseconds: 800),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final loc = LocalizationService();

    return Scaffold(
      backgroundColor: const Color(0xFF0C0E12),
      body: !_isSplashEnabled 
        ? const SizedBox.shrink() 
        : Stack(
            children: [
          // 1. Atmospheric Deep Gradient Background
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment.topCenter,
                  radius: 1.2,
                  colors: [
                    Color(0x4037393D), // surface-bright with opacity
                    Color(0xFF0C0E12),
                    Color(0xFF0C0E12),
                  ],
                  stops: [0.0, 0.7, 1.0],
                ),
              ),
            ),
          ),

          // 2. Central Emerald Glows
          Center(
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Larger soft glow
                CustomPaint(
                  size: Size(size.width * 0.9, size.width * 0.9),
                  painter: GlowPainter(
                    color: const Color(0xFF007542).withValues(alpha: 0.15),
                    blurSigma: 60,
                  ),
                ),
                // Smaller brighter glow
                CustomPaint(
                  size: const Size(200, 200),
                  painter: GlowPainter(
                    color: const Color(0xFF7BDA9C).withValues(alpha: 0.2),
                    blurSigma: 40,
                  ),
                ),
              ],
            ),
          ),

          // 3. Ambient Particles
          const _PositionedParticle(top: 0.2, left: 0.3, size: 4, color: Color(0x667BDA9C), blur: 1),
          const _PositionedParticle(top: 0.35, left: 0.7, size: 6, color: Color(0x4D7BDA9C), blur: 2),
          const _PositionedParticle(top: 0.6, left: 0.25, size: 3, color: Color(0x66FFFFFF), blur: 0),
          const _PositionedParticle(top: 0.75, left: 0.65, size: 5, color: Color(0x807BDA9C), blur: 1),

          // 4. Central Logo
          Center(
            child: AnimatedBuilder(
              animation: _animationController,
              builder: (context, child) {
                return Opacity(
                  opacity: _animationController.value,
                  child: Transform.scale(
                    scale: 0.8 + (0.2 * Curves.easeOutCubic.transform(_animationController.value)),
                    child: child,
                  ),
                );
              },
              child: Image.asset(
                'assets/images/logo.png',
                width: 160,
                height: 160,
                fit: BoxFit.contain,
              ),
            ),
          ),

          // 5. Bottom Typography
          Positioned(
            bottom: 100,
            left: 0,
            right: 0,
            child: FadeTransition(
              opacity: _animationController,
              child: Column(
                children: [
                  Text(
                    loc.translate('app_title').toUpperCase(),
                    style: TextStyle(
                      fontFamily: loc.isArabic ? 'Thamanyah' : 'Manrope',
                      fontSize: 40,
                      fontWeight: FontWeight.w700,
                      letterSpacing: loc.isArabic ? 0.0 : 6.0,
                      color: const Color(0xFFE2E2E7).withValues(alpha: 0.9),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    loc.isArabic ? 'سكينة داخلية' : 'PEACE WITHIN',
                    style: TextStyle(
                      fontFamily: loc.isArabic ? 'Thamanyah' : 'Manrope',
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      letterSpacing: loc.isArabic ? 0.0 : 4.0,
                      color: const Color(0xFF7BDA9C).withValues(alpha: 0.8),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class GlowPainter extends CustomPainter {
  final Color color;
  final double blurSigma;

  GlowPainter({required this.color, required this.blurSigma});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, blurSigma);

    canvas.drawCircle(
      Offset(size.width / 2, size.height / 2),
      size.width / 2,
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}


class _PositionedParticle extends StatelessWidget {
  final double top;
  final double left;
  final double size;
  final Color color;
  final double blur;

  const _PositionedParticle({
    required this.top,
    required this.left,
    required this.size,
    required this.color,
    required this.blur,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: MediaQuery.of(context).size.height * top,
      left: MediaQuery.of(context).size.width * left,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          boxShadow: blur > 0
              ? [
                  BoxShadow(
                    color: color,
                    blurRadius: blur,
                    spreadRadius: blur / 2,
                  )
                ]
              : null,
        ),
      ),
    );
  }
}
