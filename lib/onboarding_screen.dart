import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'localization_service.dart';
import 'location_service.dart';
import 'notification_service.dart';
import 'dynamic_sky.dart';
import 'main_screen.dart';
import 'location_selection_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({Key? key}) : super(key: key);

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  bool _isLoadingLocation = false;
  bool _notificationsEnabled = true;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _nextPage() {
    _pageController.nextPage(
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeOutCubic,
    );
  }

  Future<void> _finishOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('has_completed_onboarding', true);
    await prefs.setBool('dhikr_notifications', _notificationsEnabled);

    if (_notificationsEnabled) {
      await NotificationService().rescheduleAllDhikrNotifications();
    }

    if (mounted) {
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) => const MainScreen(),
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
    // Set a fixed peaceful night time for the background
    final DateTime nightTime = DateTime(2024, 1, 1, 2, 0);

    return Scaffold(
      backgroundColor: const Color(0xFF0C0E12),
      body: Stack(
        children: [
          // Shared Cinematic Background
          Positioned.fill(
            child: DynamicSky(
              currentTime: nightTime,
              scrollOffset: 0,
            ),
          ),
          
          // Pages
          SafeArea(
            child: PageView(
              controller: _pageController,
              physics: const BouncingScrollPhysics(),
              children: [
                _buildWelcomePage(),
                _buildLanguagePage(),
                _buildLocationPage(),
                _buildNotificationsPage(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWelcomePage() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Spacer(flex: 2),
        // App Logo / Moon
        Container(
          width: 120,
          height: 120,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white.withValues(alpha: 0.05),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF007542).withValues(alpha: 0.2),
                blurRadius: 40,
                spreadRadius: 10,
              ),
            ],
          ),
          child: const MoonWidget(hijriDate: "15"), // Full moon
        ),
        const SizedBox(height: 40),
        Text(
          LocalizationService().translate('app_title'),
          style: TextStyle(
            color: Colors.white,
            fontSize: 32,
            fontWeight: FontWeight.bold,
            letterSpacing: LocalizationService().isArabic ? 0.0 : 8.0,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          LocalizationService().translate('onboarding_subtitle'),
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.6),
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
          textAlign: TextAlign.center,
        ),
        const Spacer(flex: 2),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40),
          child: _PrimaryButton(
            text: LocalizationService().translate('start'),
            onPressed: _nextPage,
          ),
        ),
        const SizedBox(height: 40),
      ],
    );
  }

  Widget _buildLanguagePage() {
    return Padding(
      padding: const EdgeInsets.all(32.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            LocalizationService().translate('select_language'),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 40),
          _GlassCardButton(
            title: 'العربية',
            icon: CupertinoIcons.globe,
            onTap: () async {
              if (!LocalizationService().isArabic) {
                await LocalizationService().toggleLanguage();
              }
              _nextPage();
            },
          ),
          const SizedBox(height: 16),
          _GlassCardButton(
            title: 'English',
            icon: CupertinoIcons.globe,
            onTap: () async {
              if (LocalizationService().isArabic) {
                await LocalizationService().toggleLanguage();
              }
              _nextPage();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildLocationPage() {
    final loc = LocalizationService();
    return Padding(
      padding: const EdgeInsets.all(32.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            loc.translate('location_services'),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            loc.translate('location_desc'),
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.6),
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 40),
          _isLoadingLocation
              ? const Center(child: CupertinoActivityIndicator(color: Color(0xFF97f7b7)))
              : _GlassCardButton(
                  title: loc.translate('automatic_location'),
                  icon: CupertinoIcons.location_fill,
                  onTap: () async {
                    setState(() => _isLoadingLocation = true);
                    final location = await LocationService().determinePosition();
                    setState(() => _isLoadingLocation = false);
                    if (location != null) {
                       _nextPage();
                    }
                  },
                ),
          const SizedBox(height: 16),
          _GlassCardButton(
            title: loc.translate('manual_location'),
            icon: CupertinoIcons.map_pin_ellipse,
            onTap: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const LocationSelectionScreen()),
              );
              // Wait for user to pop back and continue
            },
          ),
          const Spacer(),
          Center(
            child: TextButton(
              onPressed: _nextPage,
              child: Text(
                loc.translate('swipe_to_continue'),
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.5),
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildNotificationsPage() {
    final loc = LocalizationService();
    return Padding(
      padding: const EdgeInsets.all(32.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            loc.translate('notifications'),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            loc.translate('notifications_desc'),
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.6),
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 40),
          _buildGlassCard(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: _notificationsEnabled 
                        ? const Color(0xFF007542).withValues(alpha: 0.2)
                        : Colors.white.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(
                      CupertinoIcons.bell_fill,
                      color: _notificationsEnabled ? const Color(0xFF97f7b7) : Colors.white.withValues(alpha: 0.5),
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      loc.translate('enable_notifications'),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  CupertinoSwitch(
                    value: _notificationsEnabled,
                    onChanged: (val) {
                      setState(() {
                        _notificationsEnabled = val;
                      });
                    },
                    activeTrackColor: const Color(0xFF007542),
                  ),
                ],
              ),
            ),
          ),
          const Spacer(),
          _PrimaryButton(
            text: loc.translate('finish'),
            onPressed: _finishOnboarding,
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildGlassCard({required Widget child}) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF111317).withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
        boxShadow: const [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 20,
            offset: Offset(0, 8),
          )
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
          child: child,
        ),
      ),
    );
  }
}

class _PrimaryButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;

  const _PrimaryButton({Key? key, required this.text, required this.onPressed}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 56,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF007542), Color(0xFF005A32)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF007542).withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(16),
          child: Center(
            child: Text(
              text,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _GlassCardButton extends StatelessWidget {
  final String title;
  final IconData icon;
  final VoidCallback onTap;

  const _GlassCardButton({
    Key? key,
    required this.title,
    required this.icon,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF111317).withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
        boxShadow: const [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 20,
            offset: Offset(0, 8),
          )
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onTap,
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Icon(icon, color: Colors.white, size: 24),
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: Text(
                        title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    Icon(
                      LocalizationService().isArabic ? CupertinoIcons.chevron_back : CupertinoIcons.chevron_forward,
                      color: Colors.white.withValues(alpha: 0.3),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
