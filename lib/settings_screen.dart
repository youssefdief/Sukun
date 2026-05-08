import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'localization_service.dart';
import 'notification_service.dart';
import 'location_service.dart';
import 'location_selection_screen.dart';
import 'main_screen.dart';

class SettingsScreen extends StatefulWidget {
  final bool isTab;
  const SettingsScreen({Key? key, this.isTab = false}) : super(key: key);

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _dhikrNotificationsEnabled = true;
  bool _splashEnabled = true;
  double _splashDuration = 2.5;
  String _currentCity = '...';

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final location = await LocationService().getSavedLocation();
    setState(() {
      _dhikrNotificationsEnabled = prefs.getBool('dhikr_notifications') ?? true;
      _splashEnabled = prefs.getBool('splash_enabled') ?? true;
      _splashDuration = prefs.getDouble('splash_duration') ?? 2.5;
      _currentCity = location.cityName;
    });
  }

  Future<void> _toggleDhikrNotifications(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('dhikr_notifications', value);
    setState(() {
      _dhikrNotificationsEnabled = value;
    });

    if (value) {
      await NotificationService().requestPermissions();
      await NotificationService().rescheduleAllDhikrNotifications();
    } else {
      await NotificationService().cancelAllDhikrNotifications();
    }
  }

  Future<void> _toggleSplash(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('splash_enabled', value);
    setState(() {
      _splashEnabled = value;
    });
  }

  Future<void> _updateSplashDuration(double value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('splash_duration', value);
    setState(() {
      _splashDuration = value;
    });
  }

  @override
  Widget build(BuildContext context) {
    final loc = LocalizationService();
    return Scaffold(
      backgroundColor: const Color(0xFF0C0E12),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: widget.isTab ? null : IconButton(
          icon: const Icon(CupertinoIcons.back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          loc.translate('settings'),
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _SectionTitle(title: loc.translate('preferences')),
              const SizedBox(height: 16),
              _SettingsPanel(
                children: [
                  _SettingsTile(
                    icon: CupertinoIcons.bell,
                    title: loc.translate('dhikr_notifications'),
                    subtitle: loc.translate('dhikr_notifications_subtitle'),
                    hasSwitch: true,
                    switchValue: _dhikrNotificationsEnabled,
                    onChanged: _toggleDhikrNotifications,
                  ),
                  _SettingsTile(
                    icon: CupertinoIcons.paperplane,
                    title: loc.translate('send_test_notification'),
                    hasArrow: true,
                    onTap: () async {
                      await NotificationService().showTestNotification();
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              loc.translate('test_notification_sent'),
                              style: const TextStyle(color: Colors.white),
                            ),
                            behavior: SnackBarBehavior.floating,
                            backgroundColor: const Color(0xFF007542),
                            duration: const Duration(seconds: 2),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        );
                      }
                    },
                  ),
                  _SettingsTile(
                    icon: CupertinoIcons.globe,
                    title: loc.translate('language'),
                    subtitle: loc.isArabic ? loc.translate('arabic') : loc.translate('english'),
                    hasArrow: true,
                    onTap: () async {
                      await loc.toggleLanguage();
                    },
                  ),
                  _SettingsTile(
                    icon: CupertinoIcons.location,
                    title: loc.translate('location_services'),
                    subtitle: _currentCity,
                    hasArrow: true,
                    onTap: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const LocationSelectionScreen()),
                      );
                      _loadSettings(); // Reload when coming back
                    },
                  ),
                  _SettingsTile(
                    icon: CupertinoIcons.moon_stars,
                    title: loc.translate('theme'),
                    subtitle: 'Dark Mode',
                    hasArrow: true,
                  ),
                ],
              ),
              const SizedBox(height: 32),
              _SectionTitle(title: loc.translate('splash_screen_settings')),
              const SizedBox(height: 16),
              _SettingsPanel(
                children: [
                  _SettingsTile(
                    icon: CupertinoIcons.sparkles,
                    title: loc.translate('enable_splash'),
                    hasSwitch: true,
                    switchValue: _splashEnabled,
                    onChanged: _toggleSplash,
                    isLast: !_splashEnabled,
                  ),
                  if (_splashEnabled)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                loc.translate('splash_duration'),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              Text(
                                '${_splashDuration.toStringAsFixed(1)} ${loc.translate('seconds')}',
                                style: TextStyle(
                                  color: const Color(0xFF007542).withValues(alpha: 0.8),
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          SliderTheme(
                            data: SliderTheme.of(context).copyWith(
                              activeTrackColor: const Color(0xFF007542),
                              inactiveTrackColor: Colors.white.withValues(alpha: 0.1),
                              thumbColor: Colors.white,
                              overlayColor: const Color(0xFF007542).withValues(alpha: 0.2),
                              trackHeight: 4,
                            ),
                            child: Slider(
                              value: _splashDuration,
                              min: 0,
                              max: 5,
                              divisions: 50,
                              onChanged: _updateSplashDuration,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 32),
              _SectionTitle(title: loc.translate('calculation_method')),
              const SizedBox(height: 16),
              _SettingsPanel(
                children: [
                  _SettingsTile(
                    icon: CupertinoIcons.settings_solid,
                    title: loc.translate('prayer_authority'),
                    subtitle: 'Egyptian General Authority of Survey',
                    hasArrow: true,
                  ),
                  _SettingsTile(
                    icon: CupertinoIcons.clock,
                    title: loc.translate('asr_calculation'),
                    subtitle: 'Shafi',
                    hasArrow: true,
                  ),
                ],
              ),
              const SizedBox(height: 32),
              _SectionTitle(title: loc.translate('about')),
              const SizedBox(height: 16),
              _SettingsPanel(
                children: [
                  _SettingsTile(
                    icon: CupertinoIcons.info_circle,
                    title: loc.translate('about_sukun'),
                    hasArrow: true,
                  ),
                  _SettingsTile(
                    icon: CupertinoIcons.lock_shield,
                    title: loc.translate('privacy_policy'),
                    hasArrow: true,
                  ),
                  _SettingsTile(
                    icon: CupertinoIcons.star,
                    title: loc.translate('rate_app'),
                    hasArrow: true,
                    isLast: true,
                  ),
                ],
              ),
              const SizedBox(height: 48),
              Center(
                child: Text(
                  'Sukun v1.0.0\n${loc.translate('made_with_peace')}',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.3),
                    fontSize: 12,
                    height: 1.5,
                  ),
                ),
              ),
              SizedBox(height: widget.isTab ? MainScreen.navBarHeight : 48),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;

  const _SectionTitle({Key? key, required this.title}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: TextStyle(
        color: Colors.white.withValues(alpha: 0.5),
        fontSize: 11,
        fontWeight: FontWeight.bold,
        letterSpacing: 1.5,
      ),
    );
  }
}

class _SettingsPanel extends StatelessWidget {
  final List<Widget> children;

  const _SettingsPanel({Key? key, required this.children}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF111317).withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.03)),
        boxShadow: const [
          BoxShadow(
            color: Colors.black45,
            blurRadius: 32,
            offset: Offset(0, 8),
          )
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Column(
            children: children,
          ),
        ),
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final bool hasArrow;
  final bool hasSwitch;
  final bool switchValue;
  final bool isLast;
  final VoidCallback? onTap;
  final ValueChanged<bool>? onChanged;

  const _SettingsTile({
    Key? key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.hasArrow = false,
    this.hasSwitch = false,
    this.switchValue = false,
    this.isLast = false,
    this.onTap,
    this.onChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
                  ),
                  child: Icon(
                    icon,
                    color: Colors.white.withValues(alpha: 0.8),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      if (subtitle != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          subtitle!,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.4),
                            fontSize: 12,
                          ),
                        ),
                      ]
                    ],
                  ),
                ),
                if (hasArrow)
                  Icon(
                    CupertinoIcons.chevron_right,
                    color: Colors.white.withValues(alpha: 0.2),
                    size: 18,
                  ),
                if (hasSwitch)
                  CupertinoSwitch(
                    value: switchValue,
                    onChanged: onChanged ?? (val) {},
                    activeTrackColor: const Color(0xFF007542),
                    inactiveTrackColor: Colors.white.withValues(alpha: 0.1),
                  ),
              ],
            ),
          ),
        ),
        if (!isLast)
          Padding(
            padding: const EdgeInsets.only(left: 76),
            child: Container(
              height: 1,
              color: Colors.white.withValues(alpha: 0.05),
            ),
          )
      ],
    );
  }
}
