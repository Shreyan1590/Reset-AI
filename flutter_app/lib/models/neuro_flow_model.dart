/// Neuro-Flow Score Model
/// Represents user's cognitive focus state and productivity metrics

class NeuroFlowScore {
  final double score;
  final String level;
  final int distractions;
  final int focusStreak;
  final List<String> suggestions;
  final DateTime? calculatedAt;

  NeuroFlowScore({
    required this.score,
    required this.level,
    this.distractions = 0,
    this.focusStreak = 0,
    this.suggestions = const [],
    this.calculatedAt,
  });

  // Color based on score
  String get colorHex {
    if (score >= 85) return '#10B981'; // Green - Deep Focus
    if (score >= 70) return '#22D3EE'; // Cyan - Good Flow
    if (score >= 50) return '#F59E0B'; // Amber - Moderate
    if (score >= 30) return '#F97316'; // Orange - Scattered
    return '#EF4444'; // Red - Distracted
  }

  // Icon based on level
  String get icon {
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

  // Score breakdown for visualization
  Map<String, double> get breakdown {
    return {
      'Focus': score * 0.4,
      'Continuity': score * 0.3,
      'Recovery': score * 0.3,
    };
  }

  factory NeuroFlowScore.empty() {
    return NeuroFlowScore(
      score: 0,
      level: 'Unknown',
      suggestions: ['Start working to see your focus metrics'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'score': score,
      'level': level,
      'distractions': distractions,
      'focusStreak': focusStreak,
      'suggestions': suggestions,
      'calculatedAt': calculatedAt?.toIso8601String(),
    };
  }
}

/// Distraction Prediction Model
class DistractionPrediction {
  final double probability;
  final String timeframe;
  final List<String> triggers;
  final String recommendation;

  DistractionPrediction({
    required this.probability,
    required this.timeframe,
    this.triggers = const [],
    required this.recommendation,
  });

  bool get isHighRisk => probability > 0.7;
  bool get isMediumRisk => probability > 0.4 && probability <= 0.7;
  bool get isLowRisk => probability <= 0.4;

  String get riskLevel {
    if (isHighRisk) return 'High';
    if (isMediumRisk) return 'Medium';
    return 'Low';
  }

  String get riskIcon {
    if (isHighRisk) return '🔴';
    if (isMediumRisk) return '🟡';
    return '🟢';
  }
}

/// Focus Session State
class FocusState {
  final String state;
  final DateTime startedAt;
  final int durationMinutes;
  final double intensity;

  FocusState({
    required this.state,
    required this.startedAt,
    this.durationMinutes = 0,
    this.intensity = 1.0,
  });

  bool get isInFlow => state == 'flow' && durationMinutes > 15;
  bool get isDeepWork => state == 'deep_work' && durationMinutes > 30;

  String get stateIcon {
    switch (state) {
      case 'flow':
        return '🌊';
      case 'deep_work':
        return '🔥';
      case 'shallow':
        return '💨';
      case 'break':
        return '☕';
      default:
        return '⏸️';
    }
  }
}

/// Cognitive Report
class CognitiveReport {
  final DateTime periodStart;
  final DateTime periodEnd;
  final double avgFocusScore;
  final int totalFocusMinutes;
  final int totalDistractions;
  final int contextsRecovered;
  final int timeSavedMinutes;
  final Map<String, int> topDomains;
  final List<String> insights;

  CognitiveReport({
    required this.periodStart,
    required this.periodEnd,
    required this.avgFocusScore,
    required this.totalFocusMinutes,
    required this.totalDistractions,
    required this.contextsRecovered,
    required this.timeSavedMinutes,
    this.topDomains = const {},
    this.insights = const [],
  });

  String get periodLabel {
    final days = periodEnd.difference(periodStart).inDays;
    if (days <= 1) return 'Today';
    if (days <= 7) return 'This Week';
    if (days <= 30) return 'This Month';
    return 'Custom Period';
  }
}
