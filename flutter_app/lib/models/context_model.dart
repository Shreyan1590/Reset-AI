import 'package:cloud_firestore/cloud_firestore.dart';

class ContextModel {
  final String id;
  final String userId;
  final String? sessionId;
  final DateTime capturedAt;
  final String type;
  final Map<String, dynamic> data;
  final String summary;
  final List<String> keyPoints;
  final List<String> nextSteps;
  final bool isRecovered;
  final List<String> tags;
  final int visitCount;
  final int totalDuration;
  final DateTime? lastVisited;
  // AI Intelligence fields
  final String intentCategory;
  final String aiReasoning;
  final double productivityImpact;

  ContextModel({
    required this.id,
    required this.userId,
    this.sessionId,
    required this.capturedAt,
    required this.type,
    required this.data,
    this.summary = '',
    this.keyPoints = const [],
    this.nextSteps = const [],
    this.isRecovered = false,
    this.tags = const [],
    this.visitCount = 1,
    this.totalDuration = 0,
    this.lastVisited,
    this.intentCategory = 'unknown',
    this.aiReasoning = '',
    this.productivityImpact = 0.0,
  });

  factory ContextModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ContextModel(
      id: doc.id,
      userId: data['userId'] ?? '',
      sessionId: data['sessionId'],
      capturedAt: (data['capturedAt'] as Timestamp?)?.toDate() ?? 
                  (data['lastVisited'] as Timestamp?)?.toDate() ??
                  (data['firstVisited'] as Timestamp?)?.toDate() ??
                  DateTime.now(),
      type: data['type'] ?? 'tab',
      data: data['data'] ?? {
        'url': data['url'] ?? '',
        'title': data['title'] ?? data['domain'] ?? 'Untitled',
        'domain': data['domain'] ?? '',
      },
      summary: data['summary'] ?? '',
      keyPoints: List<String>.from(data['keyPoints'] ?? []),
      nextSteps: List<String>.from(data['nextSteps'] ?? []),
      isRecovered: data['isRecovered'] ?? false,
      tags: List<String>.from(data['tags'] ?? []),
      visitCount: data['visitCount'] ?? 1,
      totalDuration: data['totalDuration'] ?? data['totalTimeSpent'] ?? 0,
      lastVisited: (data['lastVisited'] as Timestamp?)?.toDate(),
      intentCategory: data['intentCategory'] ?? 'unknown',
      aiReasoning: data['aiReasoning'] ?? '',
      productivityImpact: (data['productivityImpact'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'sessionId': sessionId,
      'capturedAt': Timestamp.fromDate(capturedAt),
      'type': type,
      'data': data,
      'summary': summary,
      'keyPoints': keyPoints,
      'nextSteps': nextSteps,
      'isRecovered': isRecovered,
      'tags': tags,
      'visitCount': visitCount,
      'totalDuration': totalDuration,
      'lastVisited': lastVisited != null ? Timestamp.fromDate(lastVisited!) : null,
      'intentCategory': intentCategory,
      'aiReasoning': aiReasoning,
      'productivityImpact': productivityImpact,
    };
  }

  ContextModel copyWith({
    String? id,
    String? userId,
    String? sessionId,
    DateTime? capturedAt,
    String? type,
    Map<String, dynamic>? data,
    String? summary,
    List<String>? keyPoints,
    List<String>? nextSteps,
    bool? isRecovered,
    List<String>? tags,
    int? visitCount,
    int? totalDuration,
    DateTime? lastVisited,
    String? intentCategory,
    String? aiReasoning,
    double? productivityImpact,
  }) {
    return ContextModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      sessionId: sessionId ?? this.sessionId,
      capturedAt: capturedAt ?? this.capturedAt,
      type: type ?? this.type,
      data: data ?? this.data,
      summary: summary ?? this.summary,
      keyPoints: keyPoints ?? this.keyPoints,
      nextSteps: nextSteps ?? this.nextSteps,
      isRecovered: isRecovered ?? this.isRecovered,
      tags: tags ?? this.tags,
      visitCount: visitCount ?? this.visitCount,
      totalDuration: totalDuration ?? this.totalDuration,
      lastVisited: lastVisited ?? this.lastVisited,
      intentCategory: intentCategory ?? this.intentCategory,
      aiReasoning: aiReasoning ?? this.aiReasoning,
      productivityImpact: productivityImpact ?? this.productivityImpact,
    );
  }

  // Helper getters
  String get url => data['url'] ?? '';
  String get title => data['title'] ?? 'Untitled';
  int get scrollPosition => data['scrollPosition'] ?? 0;
  String get selectedText => data['selectedText'] ?? '';
  
  // URL normalization for deduplication
  String get normalizedUrl {
    if (url.isEmpty) return '';
    try {
      final uri = Uri.parse(url);
      // Remove trailing slashes and normalize
      String normalized = '${uri.scheme}://${uri.host}${uri.path}';
      if (normalized.endsWith('/')) {
        normalized = normalized.substring(0, normalized.length - 1);
      }
      return normalized.toLowerCase();
    } catch (e) {
      return url.toLowerCase();
    }
  }

  // Domain extraction
  String get domain {
    if (url.isEmpty) return '';
    try {
      return Uri.parse(url).host.replaceFirst('www.', '');
    } catch (e) {
      return '';
    }
  }

  // Duration formatted
  String get durationFormatted {
    if (totalDuration < 60) return '${totalDuration}s';
    if (totalDuration < 3600) return '${totalDuration ~/ 60}m';
    return '${totalDuration ~/ 3600}h ${(totalDuration % 3600) ~/ 60}m';
  }

  // Type-based icon
  String get typeIcon {
    switch (type) {
      case 'tab':
        return '🌐';
      case 'document':
        return '📄';
      case 'code':
        return '💻';
      case 'note':
        return '📝';
      case 'video':
        return '🎬';
      case 'email':
        return '📧';
      default:
        return '📌';
    }
  }

  // Check if this is the same workspace as another context
  bool isSameWorkspace(ContextModel other) {
    return normalizedUrl == other.normalizedUrl;
  }
}
