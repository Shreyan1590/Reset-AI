import 'package:google_generative_ai/google_generative_ai.dart';
import '../models/context_model.dart';

/// Intent categories for activity classification
enum IntentCategory {
  work,
  learning,
  research,
  entertainment,
  distraction,
  communication,
  unknown,
}

/// AI-generated insight with explainable reasoning
class AIInsight {
  final String summary;
  final String reasoning;
  final List<String> suggestions;
  final double confidenceScore;

  AIInsight({
    required this.summary,
    required this.reasoning,
    required this.suggestions,
    this.confidenceScore = 0.8,
  });
}

/// Detailed session analysis result
class SessionAnalysis {
  final String whatUserWasDoing;
  final String whatDistractedThem;
  final List<String> keyPagesVisited;
  final List<String> suggestedNextActions;
  final double focusScore;
  final double distractionScore;
  final String overallSummary;

  SessionAnalysis({
    required this.whatUserWasDoing,
    required this.whatDistractedThem,
    required this.keyPagesVisited,
    required this.suggestedNextActions,
    required this.focusScore,
    required this.distractionScore,
    required this.overallSummary,
  });
}

class GeminiService {
  // TODO: Replace with your actual Gemini API key
  // For production, use environment variables or secure storage
  static const String _apiKey = 'YOUR_API_KEY_HERE';

  late final GenerativeModel _model;
  bool _isConfigured = false;

  GeminiService() {
    if (_apiKey != 'YOUR_API_KEY_HERE' && _apiKey.isNotEmpty) {
      _model = GenerativeModel(
        model: 'gemini-pro',
        apiKey: _apiKey,
      );
      _isConfigured = true;
    }
  }

  bool get isConfigured => _isConfigured;

  // ========================================
  // INTENT CLASSIFICATION (Explainable AI)
  // ========================================
  
  /// Classify the intent of a browsing context with reasoning
  Future<Map<String, dynamic>> classifyIntent(ContextModel context) async {
    if (!_isConfigured) {
      return _fallbackIntentClassification(context);
    }

    final prompt = '''
Analyze this browsing activity and classify the user's intent.

Title: ${context.title}
URL: ${context.url}
Domain: ${context.domain}
Type: ${context.type}

Respond in this exact JSON format:
{
  "category": "work|learning|research|entertainment|distraction|communication",
  "confidence": 0.0-1.0,
  "reasoning": "Brief explanation of why this was classified this way",
  "productivityImpact": -1.0 to 1.0 (negative for distractions, positive for productive)
}
''';

    try {
      final content = [Content.text(prompt)];
      final response = await _model.generateContent(content);
      final text = response.text ?? '';
      
      // Parse JSON response
      final jsonMatch = RegExp(r'\{[\s\S]*\}').firstMatch(text);
      if (jsonMatch != null) {
        // Note: In production, use dart:convert json.decode
        // Simplified parsing for demo
        return _parseIntentJson(jsonMatch.group(0)!);
      }
      return _fallbackIntentClassification(context);
    } catch (e) {
      print('Gemini Intent Error: $e');
      return _fallbackIntentClassification(context);
    }
  }

  Map<String, dynamic> _fallbackIntentClassification(ContextModel context) {
    // Smart heuristic-based fallback
    final domain = context.domain.toLowerCase();
    final title = context.title.toLowerCase();

    String category = 'unknown';
    double productivityImpact = 0.0;
    String reasoning = '';

    if (_isWorkDomain(domain, title)) {
      category = 'work';
      productivityImpact = 0.8;
      reasoning = 'Domain/title suggests professional work activity';
    } else if (_isLearningDomain(domain, title)) {
      category = 'learning';
      productivityImpact = 0.7;
      reasoning = 'Educational content detected';
    } else if (_isResearchDomain(domain, title)) {
      category = 'research';
      productivityImpact = 0.6;
      reasoning = 'Research or documentation activity';
    } else if (_isEntertainmentDomain(domain)) {
      category = 'entertainment';
      productivityImpact = -0.3;
      reasoning = 'Entertainment platform detected';
    } else if (_isDistractionDomain(domain)) {
      category = 'distraction';
      productivityImpact = -0.7;
      reasoning = 'Known distraction source identified';
    } else if (_isCommunicationDomain(domain)) {
      category = 'communication';
      productivityImpact = 0.2;
      reasoning = 'Communication or collaboration tool';
    }

    return {
      'category': category,
      'confidence': 0.7,
      'reasoning': reasoning.isEmpty ? 'Classified based on domain patterns' : reasoning,
      'productivityImpact': productivityImpact,
    };
  }

  bool _isWorkDomain(String domain, String title) {
    final workPatterns = ['github', 'gitlab', 'jira', 'confluence', 'slack', 'notion', 'figma', 'linear', 'asana', 'trello'];
    return workPatterns.any((p) => domain.contains(p) || title.contains(p));
  }

  bool _isLearningDomain(String domain, String title) {
    final learnPatterns = ['coursera', 'udemy', 'youtube.com/watch', 'medium', 'dev.to', 'stackoverflow', 'tutorial', 'learn', 'course'];
    return learnPatterns.any((p) => domain.contains(p) || title.contains(p));
  }

  bool _isResearchDomain(String domain, String title) {
    final researchPatterns = ['docs.', 'documentation', 'api.', 'developer.', 'wiki', 'reference'];
    return researchPatterns.any((p) => domain.contains(p) || title.contains(p));
  }

  bool _isEntertainmentDomain(String domain) {
    final entertainmentPatterns = ['netflix', 'twitch', 'spotify', 'primevideo', 'hulu', 'disney'];
    return entertainmentPatterns.any((p) => domain.contains(p));
  }

  bool _isDistractionDomain(String domain) {
    final distractionPatterns = ['facebook', 'twitter', 'x.com', 'instagram', 'tiktok', 'reddit', 'news.ycombinator'];
    return distractionPatterns.any((p) => domain.contains(p));
  }

  bool _isCommunicationDomain(String domain) {
    final commPatterns = ['mail.google', 'outlook', 'teams.microsoft', 'zoom', 'meet.google', 'discord'];
    return commPatterns.any((p) => domain.contains(p));
  }

  Map<String, dynamic> _parseIntentJson(String json) {
    // Simple JSON parsing (for demo - use dart:convert in production)
    try {
      final categoryMatch = RegExp(r'"category":\s*"(\w+)"').firstMatch(json);
      final confidenceMatch = RegExp(r'"confidence":\s*([\d.]+)').firstMatch(json);
      final reasoningMatch = RegExp(r'"reasoning":\s*"([^"]+)"').firstMatch(json);
      final impactMatch = RegExp(r'"productivityImpact":\s*([-\d.]+)').firstMatch(json);

      return {
        'category': categoryMatch?.group(1) ?? 'unknown',
        'confidence': double.tryParse(confidenceMatch?.group(1) ?? '0.5') ?? 0.5,
        'reasoning': reasoningMatch?.group(1) ?? 'AI classification',
        'productivityImpact': double.tryParse(impactMatch?.group(1) ?? '0') ?? 0,
      };
    } catch (e) {
      return {'category': 'unknown', 'confidence': 0.5, 'reasoning': 'Parse error', 'productivityImpact': 0};
    }
  }

  // ========================================
  // DETAILED SESSION ANALYSIS
  // ========================================

  /// Generate comprehensive session analysis
  Future<SessionAnalysis> analyzeSession(List<ContextModel> contexts) async {
    if (contexts.isEmpty) {
      return SessionAnalysis(
        whatUserWasDoing: 'No activity recorded',
        whatDistractedThem: 'N/A',
        keyPagesVisited: [],
        suggestedNextActions: ['Start a new focus session'],
        focusScore: 0,
        distractionScore: 0,
        overallSummary: 'No session data available.',
      );
    }

    if (!_isConfigured) {
      return _fallbackSessionAnalysis(contexts);
    }

    final prompt = StringBuffer();
    prompt.writeln('Analyze this browsing session and provide detailed insights.');
    prompt.writeln('');
    prompt.writeln('Session Data:');
    
    for (var ctx in contexts.take(25)) {
      prompt.writeln('- [${ctx.capturedAt}] ${ctx.type}: "${ctx.title}" (${ctx.domain})');
    }

    prompt.writeln('');
    prompt.writeln('Respond in this exact JSON format:');
    prompt.writeln('{');
    prompt.writeln('  "whatUserWasDoing": "Main productive goal/task",');
    prompt.writeln('  "whatDistractedThem": "Key distractions if any",');
    prompt.writeln('  "keyPagesVisited": ["page1", "page2"],');
    prompt.writeln('  "suggestedNextActions": ["action1", "action2"],');
    prompt.writeln('  "focusScore": 0-100,');
    prompt.writeln('  "distractionScore": 0-100,');
    prompt.writeln('  "overallSummary": "2-3 sentence summary"');
    prompt.writeln('}');

    try {
      final content = [Content.text(prompt.toString())];
      final response = await _model.generateContent(content);
      final text = response.text ?? '';
      
      return _parseSessionAnalysis(text, contexts);
    } catch (e) {
      print('Gemini Session Analysis Error: $e');
      return _fallbackSessionAnalysis(contexts);
    }
  }

  SessionAnalysis _fallbackSessionAnalysis(List<ContextModel> contexts) {
    // Calculate scores from existing data
    int productiveCount = 0;
    int distractionCount = 0;
    final uniqueDomains = <String>{};
    final keyPages = <String>[];

    for (var ctx in contexts) {
      uniqueDomains.add(ctx.domain);
      if (_isWorkDomain(ctx.domain, ctx.title) || _isLearningDomain(ctx.domain, ctx.title)) {
        productiveCount++;
        if (keyPages.length < 5) keyPages.add(ctx.title);
      } else if (_isDistractionDomain(ctx.domain) || _isEntertainmentDomain(ctx.domain)) {
        distractionCount++;
      }
    }

    final total = contexts.length;
    final focusScore = total > 0 ? (productiveCount / total * 100) : 50.0;
    final distractionScore = total > 0 ? (distractionCount / total * 100) : 0.0;

    String mainActivity = 'General browsing';
    if (keyPages.isNotEmpty) {
      mainActivity = 'Working on: ${keyPages.first}';
    }

    return SessionAnalysis(
      whatUserWasDoing: mainActivity,
      whatDistractedThem: distractionCount > 0 ? 'Social media and entertainment sites' : 'Minimal distractions detected',
      keyPagesVisited: keyPages.take(5).toList(),
      suggestedNextActions: [
        'Continue where you left off',
        if (distractionCount > 3) 'Consider enabling focus mode',
        'Review completed work before ending session',
      ],
      focusScore: focusScore,
      distractionScore: distractionScore,
      overallSummary: 'Session included ${contexts.length} activities across ${uniqueDomains.length} domains. '
          'Focus score: ${focusScore.round()}%.',
    );
  }

  SessionAnalysis _parseSessionAnalysis(String text, List<ContextModel> contexts) {
    // Parse JSON or fall back
    try {
      final jsonMatch = RegExp(r'\{[\s\S]*\}').firstMatch(text);
      if (jsonMatch == null) return _fallbackSessionAnalysis(contexts);

      final json = jsonMatch.group(0)!;
      
      final doingMatch = RegExp(r'"whatUserWasDoing":\s*"([^"]+)"').firstMatch(json);
      final distractedMatch = RegExp(r'"whatDistractedThem":\s*"([^"]+)"').firstMatch(json);
      final focusMatch = RegExp(r'"focusScore":\s*([\d.]+)').firstMatch(json);
      final distractionMatch = RegExp(r'"distractionScore":\s*([\d.]+)').firstMatch(json);
      final summaryMatch = RegExp(r'"overallSummary":\s*"([^"]+)"').firstMatch(json);

      return SessionAnalysis(
        whatUserWasDoing: doingMatch?.group(1) ?? 'Analyzing...',
        whatDistractedThem: distractedMatch?.group(1) ?? 'Unknown',
        keyPagesVisited: contexts.take(5).map((c) => c.title).toList(),
        suggestedNextActions: ['Continue your work', 'Review progress'],
        focusScore: double.tryParse(focusMatch?.group(1) ?? '50') ?? 50,
        distractionScore: double.tryParse(distractionMatch?.group(1) ?? '0') ?? 0,
        overallSummary: summaryMatch?.group(1) ?? 'Session analyzed.',
      );
    } catch (e) {
      return _fallbackSessionAnalysis(contexts);
    }
  }

  // ========================================
  // SESSION SUMMARY (Original + Enhanced)
  // ========================================

  Future<String> generateSessionSummary(List<ContextModel> contexts) async {
    if (contexts.isEmpty) {
      return "No contexts available to summarize.";
    }

    if (!_isConfigured) {
      // Fallback summary
      final domains = contexts.map((c) => c.domain).toSet();
      return "Session included ${contexts.length} activities across ${domains.length} unique domains. "
          "Key sites: ${domains.take(3).join(', ')}.";
    }

    final prompt = StringBuffer();
    prompt.writeln("Analyze the following browsing session and provide a concise summary (max 3 sentences).");
    prompt.writeln("Key focus: What was the legitimate work/learning goal vs distractions?");
    prompt.writeln("Data:");

    for (var ctx in contexts.take(30)) {
      prompt.writeln("- Time: ${ctx.capturedAt}, Type: ${ctx.type}, Title: ${ctx.title}, Domain: ${ctx.domain}");
    }

    try {
      final content = [Content.text(prompt.toString())];
      final response = await _model.generateContent(content);
      return response.text ?? "Unable to generate summary.";
    } catch (e) {
      print('Gemini Error: $e');
      return "Error generating summary. Please check API configuration.";
    }
  }

  // ========================================
  // PRODUCTIVITY SCORE
  // ========================================

  Future<double> calculateProductivityScore(List<ContextModel> contexts) async {
    if (contexts.isEmpty) return 50.0;

    int productiveScore = 0;
    int distractionScore = 0;

    for (var ctx in contexts) {
      final classification = await classifyIntent(ctx);
      final impact = classification['productivityImpact'] as double? ?? 0;
      
      if (impact > 0) {
        productiveScore += (impact * 10).round();
      } else {
        distractionScore += (impact.abs() * 10).round();
      }
    }

    final total = productiveScore + distractionScore;
    if (total == 0) return 50.0;

    return (productiveScore / total * 100).clamp(0, 100);
  }

  // ========================================
  // CONTEXT TAGS
  // ========================================

  Future<List<String>> suggestContextTags(ContextModel context) async {
    if (!_isConfigured) {
      // Fallback tags based on heuristics
      final tags = <String>[];
      final classification = await classifyIntent(context);
      tags.add(classification['category'] as String? ?? 'browsing');
      
      if (context.domain.contains('github')) tags.add('Coding');
      if (context.domain.contains('docs')) tags.add('Documentation');
      if (context.title.toLowerCase().contains('tutorial')) tags.add('Learning');
      
      return tags.take(3).toList();
    }

    final prompt = "Analyze this browsing context and suggest 3 short, relevant tags (e.g., 'Research', 'Coding', 'Social', 'News'). Output ONLY a comma-separated list of tags.\n\n"
        "Title: ${context.title}\n"
        "URL: ${context.url}\n"
        "Domain: ${context.domain}";

    try {
      final content = [Content.text(prompt)];
      final response = await _model.generateContent(content);
      final text = response.text;
      if (text == null) return [];
      
      return text.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).take(3).toList();
    } catch (e) {
      print('Gemini Tag Error: $e');
      return [];
    }
  }

  // ========================================
  // AI RECOMMENDATIONS
  // ========================================

  /// Generate contextual recommendations based on user patterns
  Future<List<String>> generateRecommendations(List<ContextModel> contexts) async {
    if (contexts.isEmpty) {
      return ['Start a new focus session to build momentum'];
    }

    // Analyze patterns
    int socialCount = 0;
    int workCount = 0;
    int uniqueDomains = <String>{}.length;

    for (var ctx in contexts) {
      if (_isDistractionDomain(ctx.domain)) socialCount++;
      if (_isWorkDomain(ctx.domain, ctx.title)) workCount++;
    }

    final recommendations = <String>[];

    if (socialCount > contexts.length * 0.3) {
      recommendations.add('🎯 Consider a 25-minute focus block without social media');
    }

    if (contexts.length > 15 && uniqueDomains > 8) {
      recommendations.add('🔄 High context switching detected. Try working in longer blocks');
    }

    if (workCount > contexts.length * 0.7) {
      recommendations.add('⭐ Great focus today! Keep up the productive momentum');
    }

    if (contexts.length < 5) {
      recommendations.add('📝 Starting slow? Set a clear goal for your next work session');
    }

    if (recommendations.isEmpty) {
      recommendations.add('✅ Your focus patterns look balanced today');
    }

    return recommendations;
  }
}

