import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'main.dart'; // To get HomeScreen
import 'prayer_times_screen.dart';
import 'dhikr_screen.dart';
import 'calendar_screen.dart';
import 'settings_screen.dart';

class MainScreen extends StatefulWidget {
  static const double navBarHeight = 120.0;
  const MainScreen({Key? key}) : super(key: key);

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const HomeScreen(isTab: true),
    const PrayerTimesScreen(isTab: true),
    const DhikrScreen(isTab: true),
    const CalendarScreen(),
    const SettingsScreen(isTab: true),
  ];

  void _onTabSelected(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0C0E12),
      body: Stack(
        children: [
          IndexedStack(
            index: _currentIndex,
            children: _screens,
          ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: AnimatedBottomNavBar(
              currentIndex: _currentIndex,
              onTabSelected: _onTabSelected,
            ),
          ),
        ],
      ),
    );
  }
}

class AnimatedBottomNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTabSelected;

  const AnimatedBottomNavBar({
    Key? key,
    required this.currentIndex,
    required this.onTabSelected,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
      child: Container(
        height: 74,
        decoration: BoxDecoration(
          color: const Color(0xFF1A1C1F).withValues(alpha: 0.8),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
          boxShadow: const [
            BoxShadow(
              color: Colors.black87,
              blurRadius: 40,
              offset: Offset(0, 20),
            )
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final tabWidth = constraints.maxWidth / 5;
                final isRtl = Directionality.of(context) == TextDirection.rtl;
                
                return Stack(
                  children: [
                    // Sliding Active Indicator
                    AnimatedPositioned(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeOutBack,
                      left: isRtl ? tabWidth * (4 - currentIndex) : tabWidth * currentIndex,
                      top: 0,
                      bottom: 0,
                      width: tabWidth,
                      child: Center(
                        child: Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: const Color(0xFF007542).withValues(alpha: 0.15),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF007542).withValues(alpha: 0.2),
                                blurRadius: 20,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    
                    // Nav Icons
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildNavItem(0, CupertinoIcons.home, tabWidth),
                        _buildNavItem(1, CupertinoIcons.moon, tabWidth),
                        _buildCenterNavItem(2, CupertinoIcons.book, tabWidth),
                        _buildNavItem(3, CupertinoIcons.calendar, tabWidth),
                        _buildNavItem(4, CupertinoIcons.settings, tabWidth),
                      ],
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, double width) {
    final isActive = currentIndex == index;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => onTabSelected(index),
      child: SizedBox(
        width: width,
        height: 74,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOutCubic,
                transform: Matrix4.diagonal3Values(isActive ? 1.15 : 1.0, isActive ? 1.15 : 1.0, 1.0),
                transformAlignment: Alignment.center,
                child: Icon(
                  icon,
                  size: 22,
                  color: isActive
                      ? const Color(0xFF97f7b7)
                      : Colors.white.withValues(alpha: 0.4),
                ),
              ),
              const SizedBox(height: 6),
              AnimatedOpacity(
                opacity: isActive ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 200),
                child: Container(
                  width: 4,
                  height: 4,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Color(0xFF97f7b7),
                    boxShadow: [
                      BoxShadow(color: Color(0xCC7bda9c), blurRadius: 8)
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCenterNavItem(int index, IconData icon, double width) {
    final isActive = currentIndex == index;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => onTabSelected(index),
      child: SizedBox(
        width: width,
        height: 74,
        child: Center(
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOutCubic,
            transform: Matrix4.diagonal3Values(isActive ? 1.05 : 1.0, isActive ? 1.05 : 1.0, 1.0),
            transformAlignment: Alignment.center,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isActive 
                      ? [const Color(0xFF007542), const Color(0xFF009e5a)]
                      : [const Color(0xFF00522d), const Color(0xFF007542)],
                  begin: Alignment.topRight,
                  end: Alignment.bottomLeft,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                      color: isActive 
                          ? const Color(0x99007542)
                          : const Color(0x66007542),
                      blurRadius: isActive ? 25 : 20,
                      offset: const Offset(0, 8))
                ]),
            child: Icon(icon,
                color: const Color(0xFFe2e2e7), size: 24),
          ),
        ),
      ),
    );
  }
}
