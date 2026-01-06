import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

class FocusBubbleOverlay extends StatefulWidget {
  final String message;
  final VoidCallback onDismiss;
  final VoidCallback? onAction;
  final String? actionLabel;

  const FocusBubbleOverlay({
    super.key,
    required this.message,
    required this.onDismiss,
    this.onAction,
    this.actionLabel,
  });

  @override
  State<FocusBubbleOverlay> createState() => _FocusBubbleOverlayState();
}

class _FocusBubbleOverlayState extends State<FocusBubbleOverlay> {
  @override
  void initState() {
    super.initState();
    // Auto dismiss after 10 seconds
    Future.delayed(const Duration(seconds: 10), () {
      if (mounted) widget.onDismiss();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 20,
      right: 20,
      child: Material(
        color: Colors.transparent,
        child: Container(
          constraints: const BoxConstraints(maxWidth: 320),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                const Color(0xFF1A1A2E).withOpacity(0.98),
                const Color(0xFF0F0F23).withOpacity(0.98),
              ],
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: const Color(0xFF6366F1).withOpacity(0.3),
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF6366F1).withOpacity(0.2),
                blurRadius: 30,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFF22D3EE).withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.psychology,
                      color: Color(0xFF22D3EE),
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    '🧠 Focus Check',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: widget.onDismiss,
                    icon: Icon(
                      Icons.close,
                      color: Colors.white.withOpacity(0.5),
                      size: 20,
                    ),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                widget.message,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.8),
                  fontSize: 14,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  if (widget.onAction != null && widget.actionLabel != null)
                    Expanded(
                      child: ElevatedButton(
                        onPressed: widget.onAction,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF10B981),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: Text(widget.actionLabel!),
                      ),
                    ),
                  if (widget.onAction != null) const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: widget.onDismiss,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white70,
                        side: BorderSide(color: Colors.white.withOpacity(0.2)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: const Text('Got it'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ).animate().fadeIn(duration: 300.ms).slideX(begin: 0.3),
      ),
    );
  }
}

// Focus State Meter Widget
class FlowStateMeter extends StatelessWidget {
  final String state;
  final double intensity;
  final int durationMinutes;

  const FlowStateMeter({
    super.key,
    required this.state,
    this.intensity = 0.5,
    this.durationMinutes = 0,
  });

  String get _stateLabel {
    switch (state) {
      case 'deep_work':
        return 'Deep Work';
      case 'flow':
        return 'In Flow';
      case 'shallow':
        return 'Shallow Work';
      case 'break':
        return 'On Break';
      default:
        return 'Idle';
    }
  }

  String get _stateIcon {
    switch (state) {
      case 'deep_work':
        return '🔥';
      case 'flow':
        return '🌊';
      case 'shallow':
        return '💨';
      case 'break':
        return '☕';
      default:
        return '⏸️';
    }
  }

  Color get _stateColor {
    switch (state) {
      case 'deep_work':
        return const Color(0xFFEF4444);
      case 'flow':
        return const Color(0xFF6366F1);
      case 'shallow':
        return const Color(0xFFF59E0B);
      case 'break':
        return const Color(0xFF10B981);
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.03),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(_stateIcon, style: const TextStyle(fontSize: 24)),
              const SizedBox(width: 10),
              const Text(
                'Flow State',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _stateLabel,
                      style: TextStyle(
                        color: _stateColor,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$durationMinutes min this session',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.5),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              // Intensity indicator
              SizedBox(
                width: 60,
                height: 60,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    CircularProgressIndicator(
                      value: intensity,
                      backgroundColor: Colors.white.withOpacity(0.1),
                      valueColor: AlwaysStoppedAnimation(_stateColor),
                      strokeWidth: 6,
                    ),
                    Text(
                      '${(intensity * 100).round()}%',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Flow indicator bar
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: intensity,
              backgroundColor: Colors.white.withOpacity(0.1),
              valueColor: AlwaysStoppedAnimation(_stateColor),
              minHeight: 6,
            ),
          ),
        ],
      ),
    );
  }
}

// Distraction Alert Widget
class DistractionAlert extends StatelessWidget {
  final double probability;
  final List<String> triggers;
  final String recommendation;
  final VoidCallback? onTakeFocus;

  const DistractionAlert({
    super.key,
    required this.probability,
    this.triggers = const [],
    required this.recommendation,
    this.onTakeFocus,
  });

  String get _riskLevel {
    if (probability > 0.7) return 'High Risk';
    if (probability > 0.4) return 'Medium Risk';
    return 'Low Risk';
  }

  Color get _riskColor {
    if (probability > 0.7) return const Color(0xFFEF4444);
    if (probability > 0.4) return const Color(0xFFF59E0B);
    return const Color(0xFF10B981);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _riskColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _riskColor.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                probability > 0.5 ? Icons.warning_amber : Icons.check_circle,
                color: _riskColor,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Distraction Prediction',
                style: TextStyle(
                  color: _riskColor,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: _riskColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  _riskLevel,
                  style: TextStyle(
                    color: _riskColor,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            recommendation,
            style: TextStyle(
              color: Colors.white.withOpacity(0.8),
              fontSize: 13,
            ),
          ),
          if (onTakeFocus != null && probability > 0.5) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: onTakeFocus,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _riskColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text('Enter Focus Mode'),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
