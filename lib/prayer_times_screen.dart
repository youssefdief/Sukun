import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:intl/intl.dart';
import 'location_service.dart';
import 'prayer_service.dart';
import 'prayer_timeline_node.dart';
import 'main_screen.dart';
import 'localization_service.dart';

class PrayerTimesScreen extends StatefulWidget {
  final bool isTab;
  const PrayerTimesScreen({Key? key, this.isTab = false}) : super(key: key);

  @override
  State<PrayerTimesScreen> createState() => _PrayerTimesScreenState();
}

class _PrayerTimesScreenState extends State<PrayerTimesScreen> {
  final PrayerService _prayerService = PrayerService();
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
      if (mounted) {
        setState(() {
          _now = DateTime.now();
        });
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    LocationService().removeListener(_loadPrayerTimes);
    super.dispose();
  }

  Future<void> _loadPrayerTimes() async {
    final data = await _prayerService.fetchPrayerTimes();
    if (data != null && mounted) {
      setState(() {
        _prayerData = data;
      });
    }
  }

  String _formatTime(DateTime dateTime, String locale) {
    final loc = LocalizationService();
    String timeStr = DateFormat('hh:mm', locale).format(dateTime);
    String amPm = DateFormat('a', 'en').format(dateTime).toLowerCase();
    return '$timeStr ${loc.translate(amPm)}';
  }

  Map<String, dynamic> _getPrayerStatus() {
    if (_prayerData == null) return {};
    final data = _prayerData!;
    final times = [
      {'name': 'Fajr', 'time': data.fajr},
      {'name': 'Dhuhr', 'time': data.dhuhr},
      {'name': 'Asr', 'time': data.asr},
      {'name': 'Maghrib', 'time': data.maghrib},
      {'name': 'Isha', 'time': data.isha},
    ];

    Map<String, dynamic>? current;
    Map<String, dynamic>? next;

    for (int i = 0; i < times.length; i++) {
      if (_now.isBefore(times[i]['time'] as DateTime)) {
        current = i == 0 ? times.last : times[i - 1];
        next = times[i];
        break;
      }
    }

    if (current == null) {
      current = times.last;
      next = {
        'name': 'Fajr',
        'time': (times.first['time'] as DateTime).add(const Duration(days: 1))
      };
    }

    final diff = (next!['time'] as DateTime).difference(_now);
    final hours = diff.inHours;
    final minutes = diff.inMinutes % 60;
    final seconds = diff.inSeconds % 60;

    final countdown =
        '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';

    final passedDiff = _now.difference(current['time'] as DateTime);
    final passedMinutes = passedDiff.inMinutes;

    return {
      'current': current['name'],
      'next': next['name'],
      'countdown': countdown,
      'passed_minutes': passedMinutes,
      'times': times,
    };
  }

  @override
  Widget build(BuildContext context) {
    final loc = LocalizationService();
    final status = _getPrayerStatus();
    final hijriDate = _prayerData?.hijriDate ?? '...';
    final gregorianDate =
        DateFormat('EEEE, d MMMM', loc.currentLocale.languageCode).format(_now);

    return Scaffold(
      backgroundColor: const Color(0xFF111317),
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 250,
            pinned: true,
            backgroundColor: const Color(0xFF111317),
            elevation: 0,
            leading: widget.isTab
                ? null
                : IconButton(
                    icon: const Icon(CupertinoIcons.back, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      const Color(0xFF007542).withValues(alpha: 0.2),
                      const Color(0xFF111317),
                    ],
                  ),
                ),
                child: SafeArea(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: 20),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFF007542).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                              color: const Color(0xFF007542)
                                  .withValues(alpha: 0.3)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                color: Color(0xFF97f7b7),
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                      color: Color(0xFF97f7b7), blurRadius: 8)
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              loc.isArabic
                                  ? '${loc.translate('now')}: ${loc.translate(status['current']?.toString().toLowerCase() ?? '...')}'
                                  : '${loc.translate('now')}: ${loc.translate(status['current']?.toString().toLowerCase() ?? '...')}',
                              style: const TextStyle(
                                color: Color(0xFF97f7b7),
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        status['countdown'] ?? '--:--:--',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 56,
                          fontWeight: FontWeight.w300,
                          letterSpacing: 2.0,
                          fontFeatures: [FontFeature.tabularFigures()],
                          shadows: [
                            Shadow(color: Color(0x80007542), blurRadius: 30)
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${loc.translate('until')} ${loc.translate(status['next']?.toString().toLowerCase() ?? '...')}',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.6),
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          letterSpacing: 1.0,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            gregorianDate,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            hijriDate,
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.5),
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      if (_prayerData?.isOffline ?? false)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.05),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            children: [
                              Icon(CupertinoIcons.wifi_slash,
                                  size: 12,
                                  color: Colors.white.withValues(alpha: 0.4)),
                              const SizedBox(width: 6),
                              Text(
                                loc.translate('offline'),
                                style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.4),
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 32),
                  _GlassPanel(
                    child: Column(
                      children: (status['times'] as List<dynamic>?)?.asMap().entries.map((entry) {
                            final index = entry.key;
                            final p = entry.value;
                            final name = p['name'] as String;
                            final time = p['time'] as DateTime;
                            
                            PrayerState nodeState = PrayerState.upcoming;
                            if (time.isBefore(_now) || time.isAtSameMomentAs(_now)) {
                              if (status['current'] == name) {
                                nodeState = PrayerState.current;
                              } else {
                                nodeState = PrayerState.past;
                              }
                            } else {
                              if (status['current'] == name && (status['times'] as List<dynamic>).last['name'] == name) {
                                // Edge case for Isha when current time is after midnight
                                nodeState = PrayerState.current;
                              }
                            }

                            return PrayerTimelineNode(
                              label: loc.translate(name.toLowerCase()),
                              time: _formatTime(
                                  time, loc.currentLocale.languageCode),
                              state: nodeState,
                              isFirst: index == 0,
                              isLast: index == (status['times'] as List<dynamic>).length - 1,
                            );
                          }).toList() ??
                          [
                            const Center(
                                child: CircularProgressIndicator(
                                    color: Color(0xFF007542))),
                          ],
                    ),
                  ),
                  if (_prayerData != null &&
                      _prayerData!.upcomingDays.isNotEmpty) ...[
                    const SizedBox(height: 40),
                    Row(
                      children: [
                        Icon(CupertinoIcons.calendar,
                            size: 16,
                            color: Colors.white.withValues(alpha: 0.6)),
                        const SizedBox(width: 8),
                        Text(
                          loc.translate('upcoming_days').toUpperCase(),
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.6),
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.5,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      height: 120,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        physics: const BouncingScrollPhysics(),
                        itemCount: _prayerData!.upcomingDays.length,
                        itemBuilder: (context, index) {
                          final day = _prayerData!.upcomingDays[index];
                          final dayName =
                              DateFormat('E', loc.currentLocale.languageCode)
                                  .format(day.date);
                          final dayNum = day.date.day.toString();

                          return Container(
                            width: 80,
                            margin: const EdgeInsets.only(right: 12),
                            decoration: BoxDecoration(
                              color: const Color(0xFF1A1C1F)
                                  .withValues(alpha: 0.4),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.05)),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  dayName,
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.5),
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  dayNum,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  _formatTime(
                                      day.fajr, loc.currentLocale.languageCode),
                                  style: const TextStyle(
                                    color: Color(0xFF97f7b7),
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                  SizedBox(height: widget.isTab ? MainScreen.navBarHeight : 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _GlassPanel extends StatelessWidget {
  final Widget child;
  const _GlassPanel({Key? key, required this.child}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1A1C1F).withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: child,
          ),
        ),
      ),
    );
  }
}
