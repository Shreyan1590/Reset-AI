import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../services/context_service.dart';
import '../services/gemini_service.dart';
import '../widgets/neuro_flow_score_widget.dart';
import '../widgets/focus_widgets.dart';
import '../widgets/ai_insight_card.dart';

class AnalyticsPage extends StatefulWidget {
  const AnalyticsPage({super.key});

  @override
  State<AnalyticsPage> createState() => _AnalyticsPageState();
}

class _AnalyticsPageState extends State<AnalyticsPage> {
  String _selectedPeriod = 'week';
  bool _isCheckingPassword = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkPasswordAndLoad();
    });
  }

  Future<void> _checkPasswordAndLoad() async {
    if (!mounted) return;
    
    final authService = context.read<AuthService>();
    final contextService = context.read<ContextService>();

    // Wait for auth to settle
    await Future.delayed(const Duration(milliseconds: 500));
    if (!mounted) return;

    if (!authService.hasPassword) {
      if (mounted) context.go('/set-password');
      return;
    }

    if (mounted) {
      setState(() => _isCheckingPassword = false);
      await _loadData();
    }
  }

  Future<void> _loadData() async {
    if (!mounted) return;
    final service = context.read<ContextService>();
    await Future.wait([
      service.fetchContexts(),
      service.fetchSessions(),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    if (_isCheckingPassword) {
      return Scaffold(
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF0F0F23), Color(0xFF1A1A2E)],
            ),
          ),
          child: const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(color: Color(0xFF6366F1)),
                SizedBox(height: 16),
                Text(
                  'Verifying account...',
                  style: TextStyle(color: Colors.white70),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF0F0F23), Color(0xFF1A1A2E)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(),
              Expanded(child: _buildContent()),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back, color: Colors.white),
          ),
          const SizedBox(width: 16),
          const Text(
            'Cognitive Analytics',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const Spacer(),
          _buildPeriodSelector(),
        ],
      ),
    );
  }

  Widget _buildPeriodSelector() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: ['day', 'week', 'month'].map((period) {
          final isSelected = _selectedPeriod == period;
          return GestureDetector(
            onTap: () => setState(() => _selectedPeriod = period),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected ? const Color(0xFF6366F1) : Colors.transparent,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                period[0].toUpperCase() + period.substring(1),
                style: TextStyle(
                  color: isSelected ? Colors.white : Colors.white54,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  fontSize: 12,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildContent() {
    return Consumer<ContextService>(
      builder: (context, service, _) {
        return SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Neuro-Flow Score
              NeuroFlowScoreWidget(
                score: service.focusScore,
                level: service.neuroFlowScore?.level ?? 'Good Flow',
                distractions: service.distractionCount,
                focusStreak: service.neuroFlowScore?.focusStreak ?? 1,
                suggestions: service.neuroFlowScore?.suggestions ?? [],
              ).animate().fadeIn(duration: 500.ms),
              
              const SizedBox(height: 24),
              
              // Flow State Meter
              FlowStateMeter(
                state: 'flow',
                intensity: service.focusScore / 100,
                durationMinutes: 45,
              ).animate().fadeIn(duration: 500.ms, delay: 100.ms),
              
              const SizedBox(height: 24),
              
              // Stats Row
              _buildStatsRow(service),
              
              const SizedBox(height: 24),
              
              // Focus Timeline Chart
              _buildFocusTimeline(),
              
              const SizedBox(height: 24),
              
              // Top Workspaces
              _buildTopWorkspaces(service),
              
              const SizedBox(height: 24),
              
              // Distraction Prediction
              DistractionAlert(
                probability: service.distractionCount > 5 ? 0.7 : 0.3,
                triggers: service.distractionCount > 5 
                    ? ['High context switching', 'Many unique domains']
                    : [],
                recommendation: service.distractionCount > 5
                    ? 'Consider entering focus mode'
                    : 'Your focus looks good today!',
              ).animate().fadeIn(duration: 500.ms, delay: 400.ms),
              
              const SizedBox(height: 24),
              
              // Intent Distribution Chart (NEW)
              _buildIntentDistribution(service),
              
              const SizedBox(height: 24),
              
              // AI Recommendations Panel (NEW)
              _buildAIRecommendations(service),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatsRow(ContextService service) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 500;
        final isMid = constraints.maxWidth < 800;
        
        if (isMobile) {
          return Column(
            children: [
              Row(
                children: [
                   Expanded(child: _buildStatCard(
                    'Workspaces',
                    service.uniqueActiveContexts.length.toString(),
                    Icons.workspaces_outlined,
                    const Color(0xFF6366F1),
                  )),
                  const SizedBox(width: 12),
                  Expanded(child: _buildStatCard(
                    'Time Saved',
                    '${service.totalTimeRecovered ~/ 60}m',
                    Icons.timer_outlined,
                    const Color(0xFF10B981),
                  )),
                ],
              ),
              const SizedBox(height: 12),
              _buildStatCard(
                'Recoveries',
                service.contexts.where((c) => c.isRecovered).length.toString(),
                Icons.restore,
                const Color(0xFF22D3EE),
              ),
            ],
          ).animate().fadeIn(duration: 500.ms, delay: 200.ms);
        }

        if (isMid) {
           return Column(
            children: [
              Row(
                children: [
                  Expanded(child: _buildStatCard(
                    'Workspaces',
                    service.uniqueActiveContexts.length.toString(),
                    Icons.workspaces_outlined,
                    const Color(0xFF6366F1),
                  )),
                  const SizedBox(width: 12),
                  Expanded(child: _buildStatCard(
                    'Time Saved',
                    '${service.totalTimeRecovered ~/ 60}m',
                    Icons.timer_outlined,
                    const Color(0xFF10B981),
                  )),
                  const SizedBox(width: 12),
                  Expanded(child: _buildStatCard(
                    'Recoveries',
                    service.contexts.where((c) => c.isRecovered).length.toString(),
                    Icons.restore,
                    const Color(0xFF22D3EE),
                  )),
                ],
              ),
            ],
          ).animate().fadeIn(duration: 500.ms, delay: 200.ms);
        }

        return Row(
          children: [
            Expanded(child: _buildStatCard(
              'Total Workspaces',
              service.uniqueActiveContexts.length.toString(),
              Icons.workspaces_outlined,
              const Color(0xFF6366F1),
            )),
            const SizedBox(width: 12),
            Expanded(child: _buildStatCard(
              'Productive Time',
              '${service.totalTimeRecovered ~/ 60}m',
              Icons.timer_outlined,
              const Color(0xFF10B981),
            )),
            const SizedBox(width: 12),
            Expanded(child: _buildStatCard(
              'Context Recoveries',
              service.contexts.where((c) => c.isRecovered).length.toString(),
              Icons.restore,
              const Color(0xFF22D3EE),
            )),
          ],
        ).animate().fadeIn(duration: 500.ms, delay: 200.ms);
      },
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.03),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 12),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              style: TextStyle(
                color: color,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withOpacity(0.5),
              fontSize: 11,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildFocusTimeline() {
    return Consumer<ContextService>(
      builder: (context, service, _) {
        // Calculate spots from sessions
        final now = DateTime.now();
        final todaySessions = service.sessions.where((s) => 
          s.startTime.year == now.year && 
          s.startTime.month == now.month && 
          s.startTime.day == now.day
        ).toList();

        // Sort by time
        todaySessions.sort((a, b) => a.startTime.compareTo(b.startTime));

        List<FlSpot> spots = [];
        if (todaySessions.isEmpty) {
          // Default baseline if no sessions
           spots = [const FlSpot(9, 50), const FlSpot(12, 50), const FlSpot(15, 50)];
        } else {
          spots = todaySessions.map((s) {
            final hour = s.startTime.hour + (s.startTime.minute / 60);
            // Simple heuristic: Base 100 - (interruptions * 10) - (contextLoss * 15)
            double score = 100.0 - (s.interruptions * 10) - (s.contextLossEvents * 15);
            return FlSpot(hour, score.clamp(0, 100));
          }).toList();
        }

        return Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.03),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withOpacity(0.05)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Focus Timeline (Today)',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 24),
              AspectRatio(
                aspectRatio: MediaQuery.of(context).size.width < 500 ? 1.5 : 2.5,
                child: LineChart(
                  LineChartData(
                    gridData: FlGridData(
                      show: true,
                      drawVerticalLine: false,
                      getDrawingHorizontalLine: (value) => FlLine(
                        color: Colors.white.withOpacity(0.05),
                        strokeWidth: 1,
                      ),
                    ),
                    titlesData: FlTitlesData(
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          interval: 3, // Every 3 hours
                          getTitlesWidget: (value, meta) {
                            if (value >= 0 && value <= 24) {
                              final hour = value.toInt();
                              final label = hour > 12 ? '${hour - 12}P' : (hour == 12 ? '12P' : '${hour}A');
                              return Padding(
                                padding: const EdgeInsets.only(top: 8),
                                child: Text(
                                  label,
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.4),
                                    fontSize: 9,
                                  ),
                                ),
                              );
                            }
                            return const SizedBox.shrink();
                          },
                        ),
                      ),
                      leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    ),
                    borderData: FlBorderData(show: false),
                    minX: 8, // Start axis at 8 AM for better view usually
                    maxX: 20, // End at 8 PM
                    minY: 0,
                    maxY: 100,
                    lineBarsData: [
                      LineChartBarData(
                        spots: spots,
                        isCurved: true,
                        color: const Color(0xFF6366F1),
                        barWidth: 3,
                        belowBarData: BarAreaData(
                          show: true,
                          color: const Color(0xFF6366F1).withOpacity(0.1),
                        ),
                        dotData: const FlDotData(show: true),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      }
    ).animate().fadeIn(duration: 500.ms, delay: 300.ms);
  }

  Widget _buildTopWorkspaces(ContextService service) {
    final domains = <String, int>{};
    for (final ctx in service.uniqueActiveContexts) {
      final domain = ctx.domain;
      if (domain.isNotEmpty) {
        domains[domain] = (domains[domain] ?? 0) + ctx.visitCount;
      }
    }

    final sorted = domains.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.03),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Top Workspaces',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          ...sorted.take(5).map((entry) {
            final maxVisits = sorted.first.value;
            final percentage = entry.value / maxVisits;
            
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                   Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          entry.key,
                          style: const TextStyle(color: Colors.white, fontSize: 13),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        '${entry.value} visits',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.5),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: percentage,
                      backgroundColor: Colors.white.withOpacity(0.1),
                      valueColor: const AlwaysStoppedAnimation(Color(0xFF6366F1)),
                      minHeight: 6,
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    ).animate().fadeIn(duration: 500.ms, delay: 350.ms);
  }

  // ========================================
  // INTENT DISTRIBUTION CHART (Phase 5)
  // ========================================
  Widget _buildIntentDistribution(ContextService service) {
    // Calculate intent distribution from contexts
    final Map<String, int> intentCounts = {
      'Work': 0,
      'Learning': 0,
      'Research': 0,
      'Entertainment': 0,
      'Distraction': 0,
      'Communication': 0,
      'Other': 0,
    };

    for (var ctx in service.contexts) {
      final category = ctx.intentCategory.isNotEmpty 
          ? ctx.intentCategory[0].toUpperCase() + ctx.intentCategory.substring(1)
          : 'Other';
      if (intentCounts.containsKey(category)) {
        intentCounts[category] = intentCounts[category]! + 1;
      } else {
        intentCounts['Other'] = intentCounts['Other']! + 1;
      }
    }

    // Remove zero counts for cleaner chart
    intentCounts.removeWhere((key, value) => value == 0);

    // If no data, show placeholder
    if (intentCounts.isEmpty) {
      intentCounts['No Data'] = 1;
    }

    final colors = {
      'Work': const Color(0xFF6366F1),
      'Learning': const Color(0xFF10B981),
      'Research': const Color(0xFF22D3EE),
      'Entertainment': const Color(0xFFF59E0B),
      'Distraction': const Color(0xFFEF4444),
      'Communication': const Color(0xFF8B5CF6),
      'Other': Colors.grey,
      'No Data': Colors.grey.withOpacity(0.3),
    };

    final total = intentCounts.values.fold(0, (a, b) => a + b);

    return LayoutBuilder(
      builder: (context, constraints) {
        final isNarrow = constraints.maxWidth < 450;
        
        return Container(
          padding: const EdgeInsets.all(24),
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
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF6366F1).withOpacity(0.2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.pie_chart_outline, color: Color(0xFF6366F1), size: 18),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Intent Distribution',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              isNarrow 
                ? Column(
                    children: [
                      SizedBox(
                        height: 180,
                        child: _buildPieChart(intentCounts, colors, total),
                      ),
                      const SizedBox(height: 24),
                      _buildLegend(intentCounts, colors),
                    ],
                  )
                : Row(
                    children: [
                      Expanded(
                        child: SizedBox(
                          height: 180,
                          child: _buildPieChart(intentCounts, colors, total),
                        ),
                      ),
                      const SizedBox(width: 24),
                      _buildLegend(intentCounts, colors),
                    ],
                  ),
            ],
          ),
        );
      }
    ).animate().fadeIn(duration: 500.ms, delay: 450.ms);
  }

  Widget _buildPieChart(Map<String, int> intentCounts, Map<String, Color> colors, int total) {
    return PieChart(
      PieChartData(
        sections: intentCounts.entries.map((e) {
          final percentage = total > 0 ? (e.value / total * 100) : 0;
          return PieChartSectionData(
            value: e.value.toDouble(),
            title: percentage > 10 ? '${percentage.round()}%' : '',
            color: colors[e.key] ?? Colors.grey,
            radius: 50,
            titleStyle: const TextStyle(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          );
        }).toList(),
        sectionsSpace: 2,
        centerSpaceRadius: 40,
      ),
    );
  }

  Widget _buildLegend(Map<String, int> intentCounts, Map<String, Color> colors) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: intentCounts.entries.map((e) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: colors[e.key] ?? Colors.grey,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${e.key} (${e.value})',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.7),
                  fontSize: 11,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  // ========================================
  // AI RECOMMENDATIONS PANEL (Phase 5)
  // ========================================
  Widget _buildAIRecommendations(ContextService service) {
    final geminiService = GeminiService();
    
    return FutureBuilder<List<String>>(
      future: geminiService.generateRecommendations(service.contexts),
      builder: (context, snapshot) {
        final recommendations = snapshot.data ?? ['Analyzing your patterns...'];
        
        // Calculate productivity metrics for insight
        final productiveCount = service.contexts.where((c) => 
          c.intentCategory == 'work' || 
          c.intentCategory == 'learning' ||
          c.intentCategory == 'research'
        ).length;
        
        final distractionCount = service.contexts.where((c) => 
          c.intentCategory == 'distraction' ||
          c.intentCategory == 'entertainment'
        ).length;
        
        final total = service.contexts.length;
        final focusRatio = total > 0 ? (productiveCount / total * 100) : 50;

        String insight = '';
        String reasoning = '';
        
        if (focusRatio >= 70) {
          insight = 'Excellent focus today! Your productive activities significantly outweigh distractions.';
          reasoning = 'Analysis shows ${productiveCount} productive activities vs ${distractionCount} distractions. This ${focusRatio.round()}% focus rate indicates deep work habits.';
        } else if (focusRatio >= 50) {
          insight = 'Good balance, but there\'s room for improvement in reducing distractions.';
          reasoning = 'Your session shows a mix of ${productiveCount} productive and ${distractionCount} distraction activities. Consider scheduling focused blocks.';
        } else {
          insight = 'High distraction patterns detected. Consider using focus mode for better productivity.';
          reasoning = 'With ${distractionCount} distractions vs ${productiveCount} productive activities, your session may benefit from structured focus intervals.';
        }

        return AIInsightCard(
          title: 'Productivity Analysis',
          insight: insight,
          reasoning: reasoning,
          suggestions: recommendations,
          confidenceScore: 0.85,
          icon: Icons.psychology_outlined,
          accentColor: focusRatio >= 70 
              ? const Color(0xFF10B981) 
              : focusRatio >= 50 
                  ? const Color(0xFFF59E0B)
                  : const Color(0xFFEF4444),
          actionLabel: 'Start Focus Session',
          onAction: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Focus session feature coming soon!')),
            );
          },
        ).animate().fadeIn(duration: 500.ms, delay: 500.ms);
      },
    );
  }
}
