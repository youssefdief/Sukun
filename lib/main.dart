import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'prayer_service.dart';
import 'dhikr_service.dart';
import 'localization_service.dart';
import 'dynamic_sky.dart';
import 'dhikr_screen.dart';
import 'location_service.dart';
import 'splash_screen.dart';
import 'main_screen.dart';
import 'daily_quote_card.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await LocalizationService().init();

  runApp(const SukunApp());
}

class SukunApp extends StatelessWidget {
  const SukunApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: LocalizationService(),
      builder: (context, _) {
        final loc = LocalizationService();
        return MaterialApp(
          title: 'Sukun',
          debugShowCheckedModeBanner: false,
          locale: loc.currentLocale,
          supportedLocales: const [
            Locale('en'),
            Locale('ar'),
          ],
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          theme: ThemeData(
            brightness: Brightness.dark,
            scaffoldBackgroundColor: const Color(0xFF0C0E12),
            fontFamily: loc.isArabic ? 'Thamanyah' : 'Manrope',
            primaryColor: const Color(0xFF007542),
          ),
          home: const SplashScreen(),
        );
      },
    );
  }
}

class HomeScreen extends StatefulWidget {
  final bool isTab;
  const HomeScreen({Key? key, this.isTab = false}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final PrayerService _prayerService = PrayerService();
  final ScrollController _scrollController = ScrollController();
  PrayerData? _prayerData;
  Timer? _timer;
  DateTime _now = DateTime.now();

  @override
  void initState() {
    super.initState();
    _prayerData = _prayerService.currentData;
    _loadPrayerTimes();
    LocationService().addListener(_loadPrayerTimes);
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _now = DateTime.now();
      });
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _timer?.cancel();
    LocationService().removeListener(_loadPrayerTimes);
    super.dispose();
  }

  Future<void> _loadPrayerTimes() async {
    final data = await _prayerService.fetchPrayerTimes();
    if (data != null) {
      if (mounted) {
        setState(() {
          _prayerData = data;
        });
      }
    }
  }

  Map<String, dynamic> _getPrayerInfo() {
    final loc = LocalizationService();
    if (_prayerData == null) {
      return {
        'currentPrayer': '...',
        'timeString':
            '${_now.hour.toString().padLeft(2, '0')}:${_now.minute.toString().padLeft(2, '0')} ${loc.translate(_now.hour >= 12 ? 'pm' : 'am')}',
        'infoText': loc.translate('loading'),
        'hijriDate': '...',
        'currentPrayerKey': '',
        'isOffline': false,
      };
    }

    final data = _prayerData!;
    final times = [
      {'key': 'F', 'name': 'Fajr', 'time': data.fajr},
      {'key': 'D', 'name': 'Dhuhr', 'time': data.dhuhr},
      {'key': 'A', 'name': 'Asr', 'time': data.asr},
      {'key': 'M', 'name': 'Maghrib', 'time': data.maghrib},
      {'key': 'I', 'name': 'Isha', 'time': data.isha},
    ];

    // Find current and next prayer
    Map<String, dynamic> current = times.last;
    Map<String, dynamic> next = times.first;

    for (int i = 0; i < times.length; i++) {
      if (_now.isBefore(times[i]['time'] as DateTime)) {
        current = i == 0 ? times.last : times[i - 1];
        next = times[i];
        break;
      }
      if (i == times.length - 1 && _now.isAfter(times[i]['time'] as DateTime)) {
        current = times.last;
        next = times.first; // Next day Fajr
        // Adjust next day Fajr for distance calculation
        next = {
          'key': 'F',
          'name': 'Fajr',
          'time': (times.first['time'] as DateTime).add(const Duration(days: 1))
        };
      }
    }

    // Default formatting for current time
    final timeStr = _now.hour > 12
        ? '${_now.hour - 12}:${_now.minute.toString().padLeft(2, '0')} ${loc.translate('pm')}'
        : '${_now.hour == 0 ? 12 : _now.hour}:${_now.minute.toString().padLeft(2, '0')} ${loc.translate('am')}';

    // Calculate time remaining / since
    final diffToNext = (next['time'] as DateTime).difference(_now);
    final minutesToNext = diffToNext.inMinutes;

    String infoText = '';
    if (minutesToNext < 60) {
      infoText =
          '$minutesToNext ${loc.translate('min_until')} ${loc.translate(next['name'].toString().toLowerCase())}';
    } else {
      final hours = minutesToNext ~/ 60;
      final mins = minutesToNext % 60;
      infoText =
          '$hours${loc.translate('h')} $mins${loc.translate('m')} ${loc.translate('until')} ${loc.translate(next['name'].toString().toLowerCase())}';
    }

    return {
      'currentPrayer': loc.translate(current['name'].toString().toLowerCase()),
      'timeString': timeStr,
      'infoText': infoText,
      'hijriDate': _prayerData!.hijriDate,
      'currentPrayerKey': current['key'],
      'isOffline': _prayerData!.isOffline,
    };
  }

  @override
  Widget build(BuildContext context) {
    final info = _getPrayerInfo();

    return Scaffold(
      backgroundColor: const Color(0xFF0C0E12),
      body: Stack(
        children: [
          // Background Effects
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _scrollController,
              builder: (context, child) {
                final offset = _scrollController.hasClients ? _scrollController.offset : 0.0;
                return DynamicSky(
                  currentTime: _now,
                  currentPrayerKey: info['currentPrayerKey']?.toString() ?? '',
                  scrollOffset: offset,
                );
              },
            ),
          ),

          // Main Scrollable Content
          SafeArea(
            bottom: false,
            child: CustomScrollView(
              controller: _scrollController,
              physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
              slivers: [
                SliverAppBar(
                  pinned: true,
                  expandedHeight: 420.0,
                  backgroundColor: Colors.transparent,
                  surfaceTintColor: Colors.transparent,
                  elevation: 0,
                  flexibleSpace: ClipRRect(
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final top = constraints.biggest.height;
                        final safeAreaTop = MediaQuery.of(context).padding.top;
                        final minExtent = safeAreaTop +
                            kToolbarHeight +
                            40; // minimum header size
                        const maxExtent = 420.0;

                        // t = 0 (expanded), t = 1 (fully collapsed)
                        final t = ((maxExtent - top) / (maxExtent - minExtent))
                            .clamp(0.0, 1.0);

                        return BackdropFilter(
                          filter:
                              ImageFilter.blur(sigmaX: t * 10, sigmaY: t * 10),
                          child: Container(
                            color: const Color(0xFF0C0E12)
                                .withValues(alpha: t * 0.7),
                            child: Stack(
                              children: [


                                // SUKUN Title (Fades out)
                                Positioned(
                                  top: 32,
                                  left: 0,
                                  right: 0,
                                  child: Opacity(
                                    opacity: (1 - t * 2).clamp(0.0, 1.0),
                                    child: Text(
                                      LocalizationService()
                                          .translate('app_title'),
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                        letterSpacing: LocalizationService().isArabic ? 0.0 : 4.0,
                                      ),
                                    ),
                                  ),
                                ),

                                // Collapsed Prayer name (Fades in)
                                Positioned(
                                  top: safeAreaTop + 10,
                                  left: 24,
                                  right: 24,
                                  child: Opacity(
                                    opacity: t > 0.9 ? 1.0 : 0.0,
                                    child: Center(
                                      child: FittedBox(
                                        fit: BoxFit.scaleDown,
                                        child: Text(
                                          info['currentPrayer']
                                              .toString()
                                              .toUpperCase(),
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                            color: const Color(0xFF97f7b7),
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                            letterSpacing: LocalizationService().isArabic ? 0.0 : 2.0,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),

                                // Main Time & Info
                                Positioned(
                                  left: 0,
                                  right: 0,
                                  top: Tween<double>(
                                          begin: 140, end: safeAreaTop + 24)
                                      .transform(t),
                                  child: Column(
                                    children: [
                                      // Current Badge (Fades out and scales down)
                                      if (t <= 0.9)
                                        Opacity(
                                          opacity: (1 - t * 2).clamp(0.0, 1.0),
                                          child: Transform.scale(
                                            scale:
                                                (1 - t * 0.5).clamp(0.0, 1.0),
                                            child: AnimatedSize(
                                              duration: const Duration(milliseconds: 300),
                                              curve: Curves.easeOutCubic,
                                              child: ClipRRect(
                                                borderRadius: BorderRadius.circular(30),
                                                child: BackdropFilter(
                                                  filter: ImageFilter.blur(sigmaX: 4, sigmaY: 4),
                                                  child: Container(
                                                    constraints: BoxConstraints(
                                                      minWidth: 140,
                                                      maxWidth: MediaQuery.of(context).size.width * 0.85,
                                                    ),
                                                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                                                    decoration: BoxDecoration(
                                                      color: Colors.white.withValues(alpha: 0.05),
                                                      borderRadius: BorderRadius.circular(30),
                                                      border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
                                                    ),
                                                    child: Column(
                                                      mainAxisSize: MainAxisSize.min,
                                                      children: [
                                                        FittedBox(
                                                          fit: BoxFit.scaleDown,
                                                          child: Text(
                                                            LocalizationService().translate('current'),
                                                            style: TextStyle(
                                                              color: const Color(0xFF97f7b7),
                                                              fontSize: 10,
                                                              fontWeight: FontWeight.bold,
                                                              letterSpacing: LocalizationService().isArabic ? 0.0 : 2.0,
                                                            ),
                                                          ),
                                                        ),
                                                        const SizedBox(height: 2),
                                                        FittedBox(
                                                          fit: BoxFit.scaleDown,
                                                          child: Text(
                                                            info['currentPrayer'].toString().toUpperCase(),
                                                            style: TextStyle(
                                                              color: Colors.white.withValues(alpha: 0.8),
                                                              fontSize: 20,
                                                              fontWeight: FontWeight.w500,
                                                              letterSpacing: LocalizationService().isArabic ? 0.0 : 2.0,
                                                            ),
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),

                                      SizedBox(
                                          height:
                                              Tween<double>(begin: 24, end: 0)
                                                  .transform(t)),

                                      // Big Time
                                      Text(
                                        info['timeString'],
                                        style: TextStyle(
                                            color: Colors.white,
                                            fontSize: Tween<double>(
                                                    begin: 64, end: 32)
                                                .transform(t),
                                            fontWeight: FontWeight.bold,
                                            letterSpacing: -1.5,
                                            height: 1.0,
                                            shadows: const [
                                              Shadow(
                                                  color: Color(0x2697F7B7),
                                                  blurRadius: 20)
                                            ]),
                                      ),

                                      SizedBox(
                                          height:
                                              Tween<double>(begin: 16, end: 0)
                                                  .transform(t)),

                                      // Secondary Info (Fades out)
                                      Opacity(
                                        opacity: (1 - t * 1.5).clamp(0.0, 1.0),
                                        child: Column(
                                          children: [
                                            Text(
                                              info['infoText'],
                                              style: const TextStyle(
                                                color: Color(0xFF97F7B7),
                                                fontSize: 14,
                                                fontWeight: FontWeight.w600,
                                                letterSpacing: 0.5,
                                              ),
                                            ),
                                            const SizedBox(height: 16),
                                            Text(
                                              info['hijriDate'],
                                              style: TextStyle(
                                                color: Colors.white
                                                    .withValues(alpha: 0.6),
                                                fontSize: 14,
                                                fontWeight: FontWeight.w500,
                                                letterSpacing: 0.5,
                                              ),
                                            ),
                                            if (info['isOffline'] == true) ...[
                                              const SizedBox(height: 8),
                                              Text(
                                                LocalizationService().translate(
                                                    'using_saved_times'),
                                                style: TextStyle(
                                                  color: Colors.white
                                                      .withValues(alpha: 0.4),
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.w400,
                                                  fontStyle: FontStyle.italic,
                                                ),
                                              ),
                                            ]
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  bottom: PreferredSize(
                    preferredSize: const Size.fromHeight(1.0),
                    child: Builder(builder: (context) {
                      // A trick to get collapse ratio to show border
                      return Container(
                          color: Colors.white.withValues(alpha: 0.05),
                          height: 1.0);
                    }),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        const SizedBox(height: 40),
                        _AnimatedEntrance(
                          delay: const Duration(milliseconds: 100),
                          child: PrayerTrackerCard(
                              currentPrayerKey: info['currentPrayerKey']),
                        ),
                        const SizedBox(height: 24),
                        _AnimatedEntrance(
                          delay: const Duration(milliseconds: 250),
                          child: GestureDetector(
                            onTap: () {
                              final type = DhikrService().getCurrentDhikrType(_now);
                              Navigator.push(context, MaterialPageRoute(builder: (context) => DhikrScreen(initialCategory: type)));
                            },
                            child: SmartDhikrCard(now: _now),
                          ),
                        ),
                        const SizedBox(height: 24),
                        _AnimatedEntrance(
                          delay: const Duration(milliseconds: 400),
                          child: DailyQuoteCard(now: _now),
                        ),
                        SizedBox(height: widget.isTab ? MainScreen.navBarHeight : 40), // Bottom nav padding
                      ],
                    ),
                  ),
                )
              ],
            ),
          ),
        ],
      ),
    );
  }
}



// Obsolete widgets removed.

class GlassPanel extends StatelessWidget {
  final Widget child;
  final EdgeInsets padding;

  const GlassPanel({
    Key? key,
    required this.child,
    this.padding = const EdgeInsets.all(28),
  }) : super(key: key);

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
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Padding(
            padding: padding,
            child: child,
          ),
        ),
      ),
    );
  }
}

class PrayerTrackerCard extends StatelessWidget {
  final String currentPrayerKey;
  const PrayerTrackerCard({Key? key, required this.currentPrayerKey})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GlassPanel(
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Ambient light
          Positioned(
            top: -40,
            right: -40,
            child: Container(
              width: 160,
              height: 160,
              decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF007542).withValues(alpha: 0.05),
                  boxShadow: [
                    BoxShadow(
                        color: const Color(0xFF007542).withValues(alpha: 0.05),
                        blurRadius: 40)
                  ]),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        LocalizationService().translate('prayer_tracker'),
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.9),
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        LocalizationService().translate('daily_observance'),
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.5),
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 1.0,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF007542).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                          color:
                              const Color(0xFF007542).withValues(alpha: 0.2)),
                    ),
                    child: const Text(
                      '4/5',
                      style: TextStyle(
                        color: Color(0xFF97f7b7),
                        fontSize: 11,
                        fontWeight: String.fromEnvironment('test') == 'true'
                            ? FontWeight.w700
                            : FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                  )
                ],
              ),
              const SizedBox(height: 32),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _PrayerDot(label: 'F', isActive: currentPrayerKey == 'F'),
                  _buildDivider(),
                  _PrayerDot(label: 'D', isActive: currentPrayerKey == 'D'),
                  _buildDivider(),
                  _PrayerDot(label: 'A', isActive: currentPrayerKey == 'A'),
                  _buildDivider(),
                  _PrayerDot(label: 'M', isActive: currentPrayerKey == 'M'),
                  _buildDivider(),
                  _PrayerDot(label: 'I', isActive: currentPrayerKey == 'I'),
                ],
              )
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return Expanded(
      child: Container(
        height: 1,
        decoration: BoxDecoration(
            gradient: LinearGradient(colors: [
          Colors.transparent,
          Colors.white.withValues(alpha: 0.1),
          Colors.transparent,
        ])),
      ),
    );
  }
}

class _PrayerDot extends StatelessWidget {
  final String label;
  final bool isActive;

  const _PrayerDot({Key? key, required this.label, required this.isActive})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (isActive) {
      return Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          Positioned(
            left: -8,
            right: -8,
            top: -8,
            bottom: -8,
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF007542).withValues(alpha: 0.2),
                boxShadow: [
                  BoxShadow(
                      color: const Color(0xFF007542).withValues(alpha: 0.3),
                      blurRadius: 10)
                ],
              ),
            ),
          ),
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF004020),
                border: Border.all(
                    color: const Color(0xFF007542).withValues(alpha: 0.4)),
                boxShadow: const [
                  BoxShadow(color: Color(0x66007542), blurRadius: 20)
                ]),
            alignment: Alignment.center,
            child: Text(
              label,
              style: const TextStyle(
                color: Color(0xFF97f7b7),
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          )
        ],
      );
    }

    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white.withValues(alpha: 0.05),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      alignment: Alignment.center,
      child: Text(
        label,
        style: TextStyle(
          color: Colors.white.withValues(alpha: 0.7),
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

// LastReadCard removed as requested

// Removed CustomBottomNavBar and _NavIcon

class _AnimatedEntrance extends StatefulWidget {
  final Widget child;
  final Duration delay;
  const _AnimatedEntrance({Key? key, required this.child, required this.delay})
      : super(key: key);

  @override
  State<_AnimatedEntrance> createState() => _AnimatedEntranceState();
}

class _AnimatedEntranceState extends State<_AnimatedEntrance>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fade;
  late Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 900));
    _fade = Tween<double>(begin: 0.0, end: 1.0)
        .animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
    _slide = Tween<Offset>(begin: const Offset(0, 0.05), end: Offset.zero)
        .animate(
            CurvedAnimation(parent: _controller, curve: Curves.easeOutQuart));

    Future.delayed(widget.delay, () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fade,
      child: SlideTransition(
        position: _slide,
        child: widget.child,
      ),
    );
  }
}


class SmartDhikrCard extends StatelessWidget {
  final DateTime now;
  final DhikrService _dhikrService = DhikrService();

  SmartDhikrCard({Key? key, required this.now}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    String type = _dhikrService.getCurrentDhikrType(now);
    List<DhikrItem> adhkar = _dhikrService.getDhikrList(type);

    return GlassPanel(
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            top: -40,
            right: -40,
            child: Container(
              width: 128,
              height: 128,
              decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF007542).withValues(alpha: 0.05),
                  boxShadow: [
                    BoxShadow(
                        color: const Color(0xFF007542).withValues(alpha: 0.05),
                        blurRadius: 40)
                  ]),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        LocalizationService().translate('daily_dhikr'),
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.9),
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${LocalizationService().translate(type.toLowerCase())} ${LocalizationService().translate('adhkar')}',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.5),
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 1.0,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: const Color(0xFF007542).withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                          color: Colors.white.withValues(alpha: 0.1)),
                    ),
                    child: const Icon(
                      CupertinoIcons.clock,
                      color: Color(0xFF97f7b7),
                      size: 20,
                    ),
                  )
                ],
              ),
              const SizedBox(height: 24),
              ...adhkar.map((dhikr) => _buildDhikrItem(dhikr)).toList(),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDhikrItem(DhikrItem dhikr) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Directionality(
            textDirection: TextDirection.rtl,
            child: Text(
              dhikr.text,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.9),
                fontSize: 18,
                height: 1.8,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  dhikr.translation,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.4),
                    fontSize: 11,
                    height: 1.5,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF007542).withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  'x${dhikr.count}',
                  style: const TextStyle(
                    color: Color(0xFF97f7b7),
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          )
        ],
      ),
    );
  }
}
