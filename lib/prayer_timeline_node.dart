import 'package:flutter/material.dart';
import 'localization_service.dart';

enum PrayerState {
  past,
  current,
  upcoming,
}

class PrayerTimelineNode extends StatefulWidget {
  final String label;
  final String time;
  final PrayerState state;
  final bool isFirst;
  final bool isLast;

  const PrayerTimelineNode({
    Key? key,
    required this.label,
    required this.time,
    required this.state,
    this.isFirst = false,
    this.isLast = false,
  }) : super(key: key);

  @override
  State<PrayerTimelineNode> createState() => _PrayerTimelineNodeState();
}

class _PrayerTimelineNodeState extends State<PrayerTimelineNode> with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );
    _pulseAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    if (widget.state == PrayerState.current) {
      _pulseController.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(PrayerTimelineNode oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.state == PrayerState.current && oldWidget.state != PrayerState.current) {
      _pulseController.repeat(reverse: true);
    } else if (widget.state != PrayerState.current && oldWidget.state == PrayerState.current) {
      _pulseController.stop();
      _pulseController.reset();
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Content Box roughly 56px height. Center is 28.
    const double indicatorY = 28.0;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Timeline Indicator
          SizedBox(
            width: 40,
            child: CustomPaint(
              painter: TimelinePainter(
                state: widget.state,
                isFirst: widget.isFirst,
                isLast: widget.isLast,
                indicatorY: indicatorY,
              ),
              child: Stack(
                alignment: Alignment.topCenter,
                clipBehavior: Clip.none,
                children: [
                  Positioned(
                    top: indicatorY - 14, // Assuming max indicator size is 28 (radius 14)
                    child: _buildIndicator(),
                  ),
                ],
              ),
            ),
          ),
          // Content
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 24.0, right: 8.0, left: 8.0),
              child: _buildContent(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIndicator() {
    if (widget.state == PrayerState.past) {
      return Container(
        width: 24,
        height: 24,
        margin: const EdgeInsets.only(top: 2), // To align center with 28 box
        decoration: BoxDecoration(
          color: const Color(0xFF007542).withValues(alpha: 0.3),
          shape: BoxShape.circle,
          border: Border.all(color: const Color(0xFF007542).withValues(alpha: 0.5)),
        ),
        child: const Icon(Icons.check, size: 14, color: Color(0xFF97f7b7)),
      );
    } else if (widget.state == PrayerState.current) {
      return AnimatedBuilder(
        animation: _pulseAnimation,
        builder: (context, child) {
          return Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFF007542).withValues(alpha: 0.2 + (_pulseAnimation.value * 0.2)),
              border: Border.all(
                color: const Color(0xFF97f7b7).withValues(alpha: 0.5 + (_pulseAnimation.value * 0.5)),
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF97f7b7).withValues(alpha: 0.2 + (_pulseAnimation.value * 0.4)),
                  blurRadius: 10 + (_pulseAnimation.value * 10),
                  spreadRadius: _pulseAnimation.value * 5,
                ),
              ],
            ),
            child: Center(
              child: Container(
                width: 10,
                height: 10,
                decoration: const BoxDecoration(
                  color: Color(0xFF97f7b7),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(color: Color(0xFF97f7b7), blurRadius: 8)
                  ]
                ),
              ),
            ),
          );
        },
      );
    } else {
      return Container(
        width: 16,
        height: 16,
        margin: const EdgeInsets.only(top: 6), // To align center with 28 box
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white.withValues(alpha: 0.05),
          border: Border.all(color: Colors.white.withValues(alpha: 0.2), width: 2),
        ),
      );
    }
  }

  Widget _buildContent() {
    final isActive = widget.state == PrayerState.current;
    final isPast = widget.state == PrayerState.past;
    final loc = LocalizationService();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: isActive
            ? const Color(0xFF007542).withValues(alpha: 0.15)
            : (isPast ? Colors.transparent : Colors.white.withValues(alpha: 0.03)),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isActive
              ? const Color(0xFF007542).withValues(alpha: 0.4)
              : (isPast ? Colors.white.withValues(alpha: 0.02) : Colors.white.withValues(alpha: 0.05)),
        ),
        boxShadow: isActive ? [
          BoxShadow(
            color: const Color(0xFF007542).withValues(alpha: 0.2),
            blurRadius: 15,
            spreadRadius: -5,
          )
        ] : null,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            widget.label,
            style: TextStyle(
              color: isActive
                  ? Colors.white
                  : (isPast ? Colors.white.withValues(alpha: 0.3) : Colors.white.withValues(alpha: 0.8)),
              fontSize: 18,
              fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
              letterSpacing: 0.5,
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                widget.time,
                style: TextStyle(
                  color: isActive
                      ? const Color(0xFF97f7b7)
                      : (isPast ? Colors.white.withValues(alpha: 0.3) : Colors.white.withValues(alpha: 0.9)),
                  fontSize: 16,
                  fontWeight: isActive ? FontWeight.bold : FontWeight.w600,
                  letterSpacing: 0.5,
                ),
              ),
              if (isActive)
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Text(
                    loc.translate('current'),
                    style: TextStyle(
                      color: const Color(0xFF97f7b7).withValues(alpha: 0.8),
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.0,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class TimelinePainter extends CustomPainter {
  final PrayerState state;
  final bool isFirst;
  final bool isLast;
  final double indicatorY;

  TimelinePainter({
    required this.state,
    required this.isFirst,
    required this.isLast,
    required this.indicatorY,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round;

    final centerX = size.width / 2;
    final topPoint = Offset(centerX, 0);
    final centerPoint = Offset(centerX, indicatorY);
    final bottomPoint = Offset(centerX, size.height);

    // Draw top line
    if (!isFirst) {
      if (state == PrayerState.past || state == PrayerState.current) {
        paint.color = const Color(0xFF007542).withValues(alpha: 0.5);
      } else {
        paint.color = Colors.white.withValues(alpha: 0.1);
      }
      canvas.drawLine(topPoint, centerPoint, paint);
    }

    // Draw bottom line
    if (!isLast) {
      if (state == PrayerState.past) {
        paint.color = const Color(0xFF007542).withValues(alpha: 0.5);
      } else {
        paint.color = Colors.white.withValues(alpha: 0.1);
        paint.style = PaintingStyle.stroke;
        // Optionally make dashed for upcoming if desired, but solid dim is cleaner
      }
      canvas.drawLine(centerPoint, bottomPoint, paint);
    }
  }

  @override
  bool shouldRepaint(covariant TimelinePainter oldDelegate) {
    return oldDelegate.state != state ||
        oldDelegate.isFirst != isFirst ||
        oldDelegate.isLast != isLast ||
        oldDelegate.indicatorY != indicatorY;
  }
}
