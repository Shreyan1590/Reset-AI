import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Demo Data Service for RESET AI
/// Generates realistic sample data for hackathon demo purposes
class DemoDataService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? get _userId => _auth.currentUser?.uid;

  /// Generate demo contexts with varied intents
  Future<void> generateDemoContexts() async {
    if (_userId == null) return;

    final demoContexts = [
      // Work contexts
      {
        'type': 'tab',
        'data': {
          'url': 'https://github.com/flutter/flutter/pull/123456',
          'title': 'Feature: Implement new animation API by user',
          'normalizedUrl': 'https://github.com/flutter/flutter/pull/123456',
        },
        'intentCategory': 'work',
        'aiReasoning': 'GitHub pull request indicates active development work',
        'productivityImpact': 0.9,
      },
      {
        'type': 'tab',
        'data': {
          'url': 'https://www.figma.com/file/abc123/app-design',
          'title': 'App Design - Figma',
          'normalizedUrl': 'https://figma.com/file/abc123/app-design',
        },
        'intentCategory': 'work',
        'aiReasoning': 'Figma design file suggests UI/UX design work',
        'productivityImpact': 0.85,
      },
      // Learning contexts
      {
        'type': 'tab',
        'data': {
          'url': 'https://flutter.dev/docs/cookbook/animation/physics',
          'title': 'Physics-based animations | Flutter',
          'normalizedUrl': 'https://flutter.dev/docs/cookbook/animation/physics',
        },
        'intentCategory': 'learning',
        'aiReasoning': 'Flutter documentation indicates skill development',
        'productivityImpact': 0.75,
      },
      {
        'type': 'tab',
        'data': {
          'url': 'https://www.youtube.com/watch?v=abc123',
          'title': 'Firebase Authentication Tutorial - YouTube',
          'normalizedUrl': 'https://youtube.com/watch',
        },
        'intentCategory': 'learning',
        'aiReasoning': 'Educational tutorial content detected',
        'productivityImpact': 0.7,
      },
      // Research contexts
      {
        'type': 'tab',
        'data': {
          'url': 'https://stackoverflow.com/questions/12345',
          'title': 'How to implement real-time sync in Flutter?',
          'normalizedUrl': 'https://stackoverflow.com/questions/12345',
        },
        'intentCategory': 'research',
        'aiReasoning': 'Stack Overflow indicates technical research',
        'productivityImpact': 0.6,
      },
      // Communication
      {
        'type': 'tab',
        'data': {
          'url': 'https://mail.google.com/mail/u/0/#inbox',
          'title': 'Inbox - Gmail',
          'normalizedUrl': 'https://mail.google.com/mail',
        },
        'intentCategory': 'communication',
        'aiReasoning': 'Email client for work communication',
        'productivityImpact': 0.3,
      },
      // Distractions (for demo contrast)
      {
        'type': 'tab',
        'data': {
          'url': 'https://twitter.com/home',
          'title': 'Home / X',
          'normalizedUrl': 'https://twitter.com/home',
        },
        'intentCategory': 'distraction',
        'aiReasoning': 'Social media platform - common distraction source',
        'productivityImpact': -0.7,
      },
      {
        'type': 'tab',
        'data': {
          'url': 'https://www.reddit.com/r/programming',
          'title': 'r/programming - Reddit',
          'normalizedUrl': 'https://reddit.com/r/programming',
        },
        'intentCategory': 'distraction',
        'aiReasoning': 'Social news site - high engagement risk',
        'productivityImpact': -0.5,
      },
    ];

    final batch = _firestore.batch();
    final now = DateTime.now();

    for (int i = 0; i < demoContexts.length; i++) {
      final ctx = demoContexts[i];
      final docRef = _firestore.collection('contexts').doc();
      
      batch.set(docRef, {
        'userId': _userId,
        'sessionId': 'demo-session-001',
        'capturedAt': Timestamp.fromDate(now.subtract(Duration(minutes: i * 15))),
        'lastVisited': Timestamp.fromDate(now.subtract(Duration(minutes: i * 10))),
        'type': ctx['type'],
        'data': ctx['data'],
        'summary': '',
        'keyPoints': <String>[],
        'nextSteps': <String>[],
        'isRecovered': i % 3 == 0, // Some recovered
        'isArchived': false,
        'visitCount': (i % 3) + 1,
        'tags': <String>[],
        'intentCategory': ctx['intentCategory'],
        'aiReasoning': ctx['aiReasoning'],
        'productivityImpact': ctx['productivityImpact'],
      });
    }

    await batch.commit();
  }

  /// Generate demo sessions with varied patterns
  Future<void> generateDemoSessions() async {
    if (_userId == null) return;

    final now = DateTime.now();
    
    final demoSessions = [
      {
        'startTime': now.subtract(const Duration(hours: 2)),
        'endTime': now.subtract(const Duration(hours: 1)),
        'status': 'completed',
        'interruptions': 3,
        'contextLossEvents': 1,
        'timeRecovered': 300, // 5 minutes
        'aiSummary': 'Productive session focused on Flutter development. Minor distractions from social media mid-session, but recovered well. Completed review of animation implementation.',
      },
      {
        'startTime': now.subtract(const Duration(hours: 5)),
        'endTime': now.subtract(const Duration(hours: 3)),
        'status': 'completed',
        'interruptions': 7,
        'contextLossEvents': 4,
        'timeRecovered': 180,
        'aiSummary': 'Session started strong with design work but had multiple context switches. Recommend longer focus blocks for tomorrow.',
      },
      {
        'startTime': now.subtract(const Duration(days: 1, hours: 3)),
        'endTime': now.subtract(const Duration(days: 1)),
        'status': 'completed',
        'interruptions': 1,
        'contextLossEvents': 0,
        'timeRecovered': 600,
        'aiSummary': 'Excellent deep work session! Minimal interruptions, high focus on learning resources. Pattern suggests morning sessions are most productive.',
      },
    ];

    final batch = _firestore.batch();

    for (final session in demoSessions) {
      final docRef = _firestore.collection('sessions').doc();
      
      batch.set(docRef, {
        'userId': _userId,
        'timestampStart': Timestamp.fromDate(session['startTime'] as DateTime),
        'timestampEnd': Timestamp.fromDate(session['endTime'] as DateTime),
        'status': session['status'],
        'interruptions': session['interruptions'],
        'contextLossEvents': session['contextLossEvents'],
        'timeRecovered': session['timeRecovered'],
        'aiSummary': session['aiSummary'],
      });
    }

    await batch.commit();
  }

  /// Clear all demo data
  Future<void> clearDemoData() async {
    if (_userId == null) return;

    // Clear contexts
    final contextsSnap = await _firestore
        .collection('contexts')
        .where('userId', isEqualTo: _userId)
        .get();
    
    for (final doc in contextsSnap.docs) {
      await doc.reference.delete();
    }

    // Clear sessions
    final sessionsSnap = await _firestore
        .collection('sessions')
        .where('userId', isEqualTo: _userId)
        .get();
    
    for (final doc in sessionsSnap.docs) {
      await doc.reference.delete();
    }
  }

  /// Generate complete demo data package
  Future<void> generateFullDemoData() async {
    await clearDemoData();
    await generateDemoSessions();
    await generateDemoContexts();
  }
}
