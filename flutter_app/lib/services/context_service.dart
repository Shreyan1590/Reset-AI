import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/context_model.dart';
import '../models/session_model.dart';
import '../models/neuro_flow_model.dart';
import 'gemini_service.dart';

class ContextService extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  List<ContextModel> _contexts = [];
  List<ContextModel> _uniqueActiveContexts = [];
  List<SessionModel> _sessions = [];
  SessionModel? _currentSession;
  NeuroFlowScore? _neuroFlowScore;
  bool _isLoading = false;
  String? _error;

  // Real-time listeners
  StreamSubscription? _contextsSubscription;
  StreamSubscription? _sessionsSubscription;

  // Productivity stats
  int _totalInterruptions = 0;
  int _totalTimeRecovered = 0;
  int _contextLossEvents = 0;
  double _focusScore = 75.0;
  int _distractionCount = 0;

  // Auto-save timer
  Timer? _autoSaveTimer;

  // Getters
  List<ContextModel> get contexts => _contexts;
  List<ContextModel> get uniqueActiveContexts => _uniqueActiveContexts;
  List<SessionModel> get sessions => _sessions;
  SessionModel? get currentSession => _currentSession;
  NeuroFlowScore? get neuroFlowScore => _neuroFlowScore;
  bool get isLoading => _isLoading;
  String? get error => _error;
  int get totalInterruptions => _totalInterruptions;
  int get totalTimeRecovered => _totalTimeRecovered;
  int get contextLossEvents => _contextLossEvents;
  double get focusScore => _focusScore;
  int get distractionCount => _distractionCount;

  String? get _userId => _auth.currentUser?.uid;

  ContextService() {
    _init();
  }

  void _init() {
    // Start auto-save timer (every 30 seconds)
    _autoSaveTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      _autoSave();
    });
  }

  @override
  void dispose() {
    _contextsSubscription?.cancel();
    _sessionsSubscription?.cancel();
    _autoSaveTimer?.cancel();
    super.dispose();
  }

  // Auto-save function
  Future<void> _autoSave() async {
    if (_userId == null || _currentSession == null) return;
    
    try {
      // Update current session timestamp
      await _firestore
          .collection('userData')
          .doc(_userId)
          .collection('sessions')
          .doc(_currentSession!.id)
          .update({
        'lastActive': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      // Silent fail for auto-save
    }
  }

  // Initialize real-time listeners
  void initRealTimeListeners() {
    if (_userId == null) return;
    
    // Listen to activity in real-time (Populated by extension)
    _contextsSubscription = _firestore
        .collection('userData')
        .doc(_userId)
        .collection('activity')
        .orderBy('lastVisited', descending: true)
        .limit(50)
        .snapshots()
        .listen((snapshot) {
          _contexts = snapshot.docs
              .map((doc) => ContextModel.fromFirestore(doc))
              .toList();
          _uniqueActiveContexts = _deduplicateContexts(_contexts);
          _calculateNeuroFlowScore();
          notifyListeners();
        });
    
    // Listen to sessions in real-time
    _sessionsSubscription = _firestore
        .collection('userData')
        .doc(_userId)
        .collection('sessions')
        .where('userId', isEqualTo: _userId)
        .orderBy('timestampStart', descending: true)
        .limit(20)
        .snapshots()
        .listen((snapshot) {
          _sessions = snapshot.docs
              .map((doc) => SessionModel.fromFirestore(doc))
              .toList();
          _calculateStats();
          notifyListeners();
        });
  }

  // Fetch contexts with deduplication (fallback if no real-time)
  Future<void> fetchContexts({int limit = 50}) async {
    if (_userId == null) return;

    try {
      _isLoading = true;
      notifyListeners();

      final snapshot = await _firestore
          .collection('userData')
          .doc(_userId)
          .collection('activity') // Fetch from activity logged by extension
          .orderBy('lastVisited', descending: true)
          .limit(limit)
          .get();

      _contexts = snapshot.docs
          .map((doc) => ContextModel.fromFirestore(doc))
          .toList();

      _uniqueActiveContexts = _deduplicateContexts(_contexts);
      _calculateNeuroFlowScore();

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = 'Failed to fetch contexts';
      _isLoading = false;
      notifyListeners();
    }
  }

  // Intelligent deduplication - NO DUPLICATE URLs
  List<ContextModel> _deduplicateContexts(List<ContextModel> contexts) {
    final Map<String, ContextModel> uniqueMap = {};
    final Map<String, int> visitCounts = {};

    for (final ctx in contexts) {
      final key = ctx.normalizedUrl.isNotEmpty ? ctx.normalizedUrl : ctx.id;
      
      if (!uniqueMap.containsKey(key)) {
        uniqueMap[key] = ctx;
        visitCounts[key] = ctx.visitCount;
      } else {
        // Merge: keep latest, accumulate visits
        visitCounts[key] = (visitCounts[key] ?? 0) + ctx.visitCount;
        if (ctx.capturedAt.isAfter(uniqueMap[key]!.capturedAt)) {
          uniqueMap[key] = ctx;
        }
      }
    }

    // Apply merged visit counts
    return uniqueMap.entries.map((entry) {
      return entry.value.copyWith(
        visitCount: visitCounts[entry.key] ?? 1,
      );
    }).toList();
  }

  // Get current active workspace (most recent unrecovered)
  ContextModel? get currentActiveWorkspace {
    final unrecovered = _uniqueActiveContexts.where((c) => !c.isRecovered);
    return unrecovered.isNotEmpty ? unrecovered.first : null;
  }

  // Calculate Neuro-Flow Score
  void _calculateNeuroFlowScore() {
    if (_contexts.isEmpty) {
      _focusScore = 100.0;
      _distractionCount = 0;
      _neuroFlowScore = NeuroFlowScore(
        score: 100.0,
        level: 'Fresh Start',
        distractions: 0,
        focusStreak: _calculateFocusStreak(),
        suggestions: ['Start your first focused session!'],
      );
      return;
    }

    final now = DateTime.now();
    final todayContexts = _contexts.where((c) => 
      c.capturedAt.year == now.year &&
      c.capturedAt.month == now.month &&
      c.capturedAt.day == now.day
    ).toList();

    if (todayContexts.isEmpty) {
      _focusScore = 100.0;
      _distractionCount = 0;
      _neuroFlowScore = NeuroFlowScore(
        score: 100.0,
        level: 'Fresh Start',
        distractions: 0,
        focusStreak: _calculateFocusStreak(),
        suggestions: ['No activity yet today. Get started!'],
      );
      return;
    }

    final uniqueDomainsToday = todayContexts.map((c) => c.domain).toSet().length;
    final switchCount = todayContexts.length;
    final recoveredCount = todayContexts.where((c) => c.isRecovered).length;
    
    // Distraction detection
    final distractionDomains = ['twitter.com', 'facebook.com', 'instagram.com', 'youtube.com', 'netflix.com', 'amazon.com', 'flipkart.com', 'reddit.com'];
    final distractionTypes = ['social', 'video', 'shopping'];
    
    int internalDistractions = 0;
    for (final ctx in todayContexts) {
      bool isDistraction = false;
      if (distractionTypes.contains(ctx.type)) isDistraction = true;
      if (distractionDomains.any((d) => ctx.domain.contains(d))) isDistraction = true;
      
      if (isDistraction && !ctx.isRecovered) {
        internalDistractions++;
      }
    }

    // Calculate visit rate (distraction metric)
    final firstVisit = todayContexts.map((e) => e.capturedAt).reduce((a, b) => a.isBefore(b) ? a : b);
    final hoursActive = now.difference(firstVisit).inMinutes / 60.0;
    final visitRate = hoursActive > 0.1 ? switchCount / hoursActive : switchCount.toDouble();

    double score = 100.0;
    
    // Penalty for distractions (direct hits)
    score -= internalDistractions * 8.0;
    
    // Penalty for excessive context switching
    if (switchCount > 8) {
      score -= (switchCount - 8) * 1.5;
    }
    
    // Penalty for too many disparate domains (lack of focus)
    if (uniqueDomainsToday > 4) {
      score -= (uniqueDomainsToday - 4) * 4.0;
    }
    
    // Penalty for high visit rate (skimming/scattered browsing)
    if (visitRate > 15) {
      score -= (visitRate - 15) * 0.8;
    }

    // Bonus for recovering lost context
    score += recoveredCount * 6.0;
    
    _focusScore = score.clamp(0, 100);
    _distractionCount = internalDistractions + (switchCount > 10 ? (switchCount - 10) ~/ 2 : 0);

    _neuroFlowScore = NeuroFlowScore(
      score: _focusScore,
      level: _getFocusLevel(_focusScore),
      distractions: _distractionCount,
      focusStreak: _calculateFocusStreak(),
      suggestions: _generateFocusSuggestions(),
    );
  }

  String _getFocusLevel(double score) {
    if (score >= 90) return 'Deep Focus';
    if (score >= 75) return 'Good Flow';
    if (score >= 50) return 'Moderate';
    if (score >= 30) return 'Scattered';
    return 'Distracted';
  }

  int _calculateFocusStreak() {
    if (_focusScore >= 70) return 1;
    return 0;
  }

  List<String> _generateFocusSuggestions() {
    final suggestions = <String>[];
    
    if (_distractionCount > 5) {
      suggestions.add('Try closing unnecessary tabs to reduce distractions');
    }
    if (_focusScore < 50) {
      suggestions.add('Consider using focus mode for deep work sessions');
    }
    if (_uniqueActiveContexts.length > 8) {
      suggestions.add('You have many active contexts. Consider archiving some.');
    }
    if (suggestions.isEmpty) {
      suggestions.add('Great focus today! Keep up the momentum.');
    }
    
    return suggestions;
  }

  // Fetch sessions
  Future<void> fetchSessions({int limit = 10}) async {
    if (_userId == null) return;

    try {
      _isLoading = true;
      notifyListeners();

      final snapshot = await _firestore
          .collection('userData')
          .doc(_userId)
          .collection('sessions')
          .where('userId', isEqualTo: _userId)
          .orderBy('timestampStart', descending: true)
          .limit(limit)
          .get();

      _sessions = snapshot.docs
          .map((doc) => SessionModel.fromFirestore(doc))
          .toList();

      _calculateStats();

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = 'Failed to fetch sessions';
      _isLoading = false;
      notifyListeners();
    }
  }

  // Start session
  Future<String?> startSession() async {
    if (_userId == null) return null;

    try {
      final docRef = await _firestore
          .collection('userData')
          .doc(_userId)
          .collection('sessions')
          .add({
        'userId': _userId,
        'timestampStart': FieldValue.serverTimestamp(),
        'status': 'active',
        'interruptions': 0,
        'contextLossEvents': 0,
        'timeRecovered': 0,
      });

      _currentSession = SessionModel(
        id: docRef.id,
        userId: _userId!,
        startTime: DateTime.now(),
        status: 'active',
        interruptions: 0,
        contextLossEvents: 0,
        timeRecovered: 0,
      );

      notifyListeners();
      return docRef.id;
    } catch (e) {
      _error = 'Failed to start session';
      notifyListeners();
      return null;
    }
  }

  // Capture context with deduplication - NO DUPLICATES
  Future<String?> captureContext({
    required String type,
    required Map<String, dynamic> data,
    String? summary,
    List<String>? keyPoints,
    List<String>? nextSteps,
  }) async {
    if (_userId == null) return null;

    try {
      final url = data['url'] ?? '';
      final normalizedUrl = _normalizeUrl(url);
      
      // Check for existing activity with same URL - UPDATE instead of CREATE
      if (normalizedUrl.isNotEmpty) {
        final existing = await _firestore
            .collection('userData')
            .doc(_userId)
            .collection('activity') // Aligned with extension
            .where('data.normalizedUrl', isEqualTo: normalizedUrl)
            .limit(1)
            .get();

        if (existing.docs.isNotEmpty) {
          // UPDATE existing - no duplicate
          await existing.docs.first.reference.update({
            'lastVisited': FieldValue.serverTimestamp(),
            'capturedAt': FieldValue.serverTimestamp(), // web app field
            'timestampEnd': FieldValue.serverTimestamp(),
            'visitCount': FieldValue.increment(1),
            'data': data,
            'userId': _userId,
            'isRecovered': false,
          });
          return existing.docs.first.id;
        }
      }

      // Create new activity only if no existing
      final docRef = await _firestore
          .collection('userData')
          .doc(_userId)
          .collection('activity')
          .add({
        'userId': _userId,
        'sessionId': _currentSession?.id,
        'capturedAt': FieldValue.serverTimestamp(),
        'lastVisited': FieldValue.serverTimestamp(),
        'timestampStart': FieldValue.serverTimestamp(),
        'timestampEnd': FieldValue.serverTimestamp(),
        'type': type,
        'data': {
          ...data,
          'normalizedUrl': normalizedUrl,
        },
        'summary': summary ?? '',
        'keyPoints': keyPoints ?? [],
        'nextSteps': nextSteps ?? [],
        'isRecovered': false,
        'isArchived': false,
        'visitCount': 1,
        'status': 'active',
      });

      return docRef.id;
    } catch (e) {
      _error = 'Failed to capture context';
      notifyListeners();
      return null;
    }
  }

  String _normalizeUrl(String url) {
    if (url.isEmpty) return '';
    try {
      final uri = Uri.parse(url);
      String normalized = '${uri.scheme}://${uri.host}${uri.path}';
      if (normalized.endsWith('/')) {
        normalized = normalized.substring(0, normalized.length - 1);
      }
      return normalized.toLowerCase();
    } catch (e) {
      return url.toLowerCase();
    }
  }

  // Mark context as recovered
  Future<void> markContextRecovered(String contextId) async {
    try {
      await _firestore
          .collection('userData')
          .doc(_userId)
          .collection('activity')
          .doc(contextId)
          .update({
        'isRecovered': true,
        'recoveredAt': FieldValue.serverTimestamp(),
        'status': 'recovered',
      });

      final index = _contexts.indexWhere((c) => c.id == contextId);
      if (index != -1) {
        _contexts[index] = _contexts[index].copyWith(isRecovered: true);
        _uniqueActiveContexts = _deduplicateContexts(_contexts);
        _totalTimeRecovered += 60;
        notifyListeners();
      }
    } catch (e) {
      _error = 'Failed to update context';
      notifyListeners();
    }
  }

  // Archive context (hide from main view)
  Future<void> archiveContext(String contextId) async {
    try {
      await _firestore
          .collection('userData')
          .doc(_userId)
          .collection('activity')
          .doc(contextId)
          .update({
        'isArchived': true,
        'archivedAt': FieldValue.serverTimestamp(),
        'status': 'archived',
      });

      _contexts.removeWhere((c) => c.id == contextId);
      _uniqueActiveContexts = _deduplicateContexts(_contexts);
      notifyListeners();
    } catch (e) {
      _error = 'Failed to archive context';
      notifyListeners();
    }
  }

  // End session
  Future<void> endSession() async {
    if (_currentSession == null) return;

    try {
      await _firestore
          .collection('userData')
          .doc(_userId)
          .collection('sessions')
          .doc(_currentSession!.id)
          .update({
        'timestampEnd': FieldValue.serverTimestamp(),
        'status': 'completed',
      });

      _currentSession = null;
      notifyListeners();
    } catch (e) {
      _error = 'Failed to end session';
      notifyListeners();
    }
  }

  // Update session summary (AI)
  Future<void> updateSessionSummary(String sessionId, String summary) async {
    try {
      await _firestore
          .collection('userData')
          .doc(_userId)
          .collection('sessions')
          .doc(sessionId)
          .update({
        'aiSummary': summary,
      });

      // Update local state if needed
      final index = _sessions.indexWhere((s) => s.id == sessionId);
      if (index != -1) {
        // Create new session object with updated summary (since fields are final)
        // We need copyWith on SessionModel ideally, but for now re-instantiating or just relying on stream listener
        // The stream listener should handle the update automatically if we just wait, but for immediate UI feedback:
        // We can't easily modify the list item if it's immutable without copyWith. 
        // Let's rely on stream or just leave it to the UI to update from the returned value via fetch or stream.
        // Actually, since I did manual UI update in the view via stream consumer, the stream listener below should pick it up.
      }
    } catch (e) {
      print('Error updating session summary: $e');
      throw e;
    }
  }

  // Auto-tag context (AI)
  Future<void> autoTagContext(String contextId) async {
    try {
      final contextIndex = _contexts.indexWhere((c) => c.id == contextId);
      if (contextIndex == -1) return;
      
      final context = _contexts[contextIndex];
      final geminiService = GeminiService();
      final tags = await geminiService.suggestContextTags(context);
      
      if (tags.isNotEmpty) {
        await _firestore
            .collection('userData')
            .doc(_userId)
            .collection('contexts')
            .doc(contextId)
            .update({
          'tags': tags,
        });
        
        // Update local
        _contexts[contextIndex] = context.copyWith(tags: tags);
        notifyListeners();
      }
    } catch (e) {
      print('Auto-tag error: $e');
    }
  }

  // Get history - unique, merged, sorted
  Future<List<ContextModel>> getHistory({int limit = 50}) async {
    if (_userId == null) return [];
    
    try {
      final snapshot = await _firestore
          .collection('userData')
          .doc(_userId)
          .collection('activity') // Aligned with extension
          .orderBy('lastVisited', descending: true)
          .limit(limit)
          .get();
      
      return snapshot.docs
          .map((doc) => ContextModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      return _uniqueActiveContexts;
    }
  }

  // Deep cognitive resume
  Future<Map<String, dynamic>> getDeepCognitiveResume() async {
    final latestContexts = _uniqueActiveContexts.take(5).toList();
    
    return {
      'whatYouWereDoing': latestContexts.isNotEmpty 
          ? latestContexts.first.summary 
          : 'No recent activity',
      'whyYouWereDoingIt': 'Based on your workflow patterns',
      'nextLogicalStep': latestContexts.isNotEmpty 
          ? (latestContexts.first.nextSteps.isNotEmpty ? latestContexts.first.nextSteps.first : 'Continue your work')
          : 'Start a new task',
      'contexts': latestContexts,
    };
  }

  // Log activity
  Future<void> logActivity(String eventType, Map<String, dynamic> metadata) async {
    if (_userId == null) return;

    try {
      await _firestore
          .collection('userData')
          .doc(_userId)
          .collection('activityLogs')
          .add({
        'userId': _userId,
        'timestamp': FieldValue.serverTimestamp(),
        'eventType': eventType,
        'metadata': metadata,
      });
    } catch (e) {
      // Silent fail for logs
    }
  }

  void _calculateStats() {
    _totalInterruptions = 0;
    _totalTimeRecovered = 0;
    _contextLossEvents = 0;

    for (final session in _sessions) {
      _totalInterruptions += session.interruptions;
      _totalTimeRecovered += session.timeRecovered;
      _contextLossEvents += session.contextLossEvents;
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
