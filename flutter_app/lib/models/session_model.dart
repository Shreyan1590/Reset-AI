import 'package:cloud_firestore/cloud_firestore.dart';

class SessionModel {
  final String id;
  final String userId;
  final DateTime startTime;
  final DateTime? endTime;
  final String status;
  final int interruptions;
  final int contextLossEvents;
  final int timeRecovered;
  final String? aiSummary;

  SessionModel({
    required this.id,
    required this.userId,
    required this.startTime,
    this.endTime,
    required this.status,
    this.interruptions = 0,
    this.contextLossEvents = 0,
    this.timeRecovered = 0,
    this.aiSummary,
  });

  factory SessionModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return SessionModel(
      id: doc.id,
      userId: data['userId'] ?? '',
      startTime: (data['timestampStart'] as Timestamp?)?.toDate() ?? 
                 (data['startTime'] as Timestamp?)?.toDate() ?? 
                 DateTime.now(),
      endTime: (data['timestampEnd'] as Timestamp?)?.toDate() ??
               (data['endTime'] as Timestamp?)?.toDate(),
      status: data['status'] ?? 'unknown',
      interruptions: data['interruptions'] ?? 0,
      contextLossEvents: data['contextLossEvents'] ?? 0,
      timeRecovered: data['timeRecovered'] ?? 0,
      aiSummary: data['aiSummary'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'timestampStart': Timestamp.fromDate(startTime),
      'timestampEnd': endTime != null ? Timestamp.fromDate(endTime!) : null,
      'status': status,
      'interruptions': interruptions,
      'contextLossEvents': contextLossEvents,
      'timeRecovered': timeRecovered,
      'aiSummary': aiSummary,
    };
  }

  Duration get duration {
    final end = endTime ?? DateTime.now();
    return end.difference(startTime);
  }

  String get durationFormatted {
    final d = duration;
    if (d.inHours > 0) {
      return '${d.inHours}h ${d.inMinutes.remainder(60)}m';
    }
    return '${d.inMinutes}m';
  }

  bool get isActive => status == 'active';
  bool get isPaused => status == 'paused';
  bool get isCompleted => status == 'completed';

  String get statusIcon {
    switch (status) {
      case 'active':
        return '🟢';
      case 'paused':
        return '🟡';
      case 'completed':
        return '🔵';
      default:
        return '⚪';
    }
  }
}
