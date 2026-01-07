import 'package:flutter/material.dart';
import 'dart:math' as math;

class NeuroFlowScoreWidget extends StatelessWidget {
  final double score;
  final String level;
  final int distractions;
  final int focusStreak;
  final List<String> suggestions;
  final VoidCallback? onTap;

  const NeuroFlowScoreWidget({
    super.key,
    required this.score,
    required this.level,
    this.distractions = 0,
    this.focusStreak = 0,
    this.suggestions = const [],
    this.onTap,
  });

  Color get _scoreColor {
    if (score >= 85) return const Color(0xFF10B981);
    if (score >= 70) return const Color(0xFF22D3EE);
    if (score >= 50) return const Color(0xFFF59E0B);
    if (score >= 30) return const Color(0xFFF97316);
    return const Color(0xFFEF4444);
  }

  String get _levelIcon {
    switch (level) {
      case 'Deep Focus':
        return '🧘';
      case 'Good Flow':
        return '🎯';
      case 'Moderate':
        return '💭';
      case 'Scattered':
        return '🌀';
      case 'Distracted':
        return '😵';
      default:
        return '🧠';
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final screenWidth = MediaQuery.of(context).size.width;
        final isNarrow = constraints.maxWidth < 320 || screenWidth < 350;
        final isCompact = constraints.maxWidth < 500;

        return InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(24),
          child: Ink(
            padding: EdgeInsets.all(isNarrow ? 12 : (isCompact ? 16 : 24)),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  _scoreColor.withOpacity(0.15),
                  _scoreColor.withOpacity(0.05),
                ],
              ),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: _scoreColor.withOpacity(0.3)),
            ),
            child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(_levelIcon, style: TextStyle(fontSize: isNarrow ? 22 : 28)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          'Neuro-Flow Score',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (isNarrow)
                          _buildLevelTag(small: true),
                      ],
                    ),
                  ),
                  if (!isNarrow) ...[
                    const SizedBox(width: 8),
                    _buildLevelTag(),
                  ],
                ],
              ),
              SizedBox(height: isNarrow ? 16 : 24),
              isCompact 
                ? Column(
                    children: [
                      _buildScoreRing(size: isNarrow ? 90 : 100),
                      SizedBox(height: isNarrow ? 12 : 20),
                      _buildMetrics(isCompact: true),
                    ],
                  )
                : Row(
                    children: [
                      _buildScoreRing(size: 120),
                      const SizedBox(width: 24),
                      Expanded(child: _buildMetrics(isCompact: false)),
                    ],
                  ),
              if (suggestions.isNotEmpty) ...[
                SizedBox(height: isNarrow ? 12 : 20),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.lightbulb_outline, color: Color(0xFFF59E0B), size: 16),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          suggestions.first,
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.8),
                            fontSize: 11,
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
        ); // Close InkWell
      }
    );
  }

  Widget _buildLevelTag({bool small = false}) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: small ? 8 : 10, 
        vertical: small ? 2 : 4
      ),
      decoration: BoxDecoration(
        color: _scoreColor.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        level,
        style: TextStyle(
          color: _scoreColor,
          fontWeight: FontWeight.w600,
          fontSize: small ? 9 : 11,
        ),
      ),
    );
  }

  Widget _buildScoreRing({required double size}) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _ScoreRingPainter(
          score: score,
          color: _scoreColor,
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '${score.round()}',
                style: TextStyle(
                  color: _scoreColor,
                  fontSize: size * 0.3,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                'SCORE',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.5),
                  fontSize: size * 0.08,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMetrics({required bool isCompact}) {
    return Column(
      children: [
        _buildMetricRow(
          icon: Icons.flash_on,
          label: 'Focus Streak',
          value: '$focusStreak days',
          color: const Color(0xFF10B981),
          isCompact: isCompact,
        ),
        const SizedBox(height: 12),
        _buildMetricRow(
          icon: Icons.warning_amber_outlined,
          label: 'Distractions',
          value: distractions.toString(),
          color: const Color(0xFFF59E0B),
          isCompact: isCompact,
        ),
      ],
    );
  }

  Widget _buildMetricRow({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
    required bool isCompact,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10, vertical: isCompact ? 8 : 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.03),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withOpacity(0.6),
              fontSize: 11,
            ),
          ),
          const Spacer(),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}

class _ScoreRingPainter extends CustomPainter {
  final double score;
  final Color color;

  _ScoreRingPainter({required this.score, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 8;

    // Background ring
    final bgPaint = Paint()
      ..color = Colors.white.withOpacity(0.1)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 10
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, bgPaint);

    // Score ring
    final scorePaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 10
      ..strokeCap = StrokeCap.round;

    final sweepAngle = (score / 100) * 2 * math.pi;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      sweepAngle,
      false,
      scorePaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
