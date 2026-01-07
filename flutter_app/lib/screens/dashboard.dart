import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../services/auth_service.dart';
import '../services/context_service.dart';
import '../widgets/neuro_flow_score_widget.dart';
import '../widgets/focus_widgets.dart';
import '../widgets/active_workspace_card.dart';
import '../widgets/stat_card.dart';
import 'package:url_launcher/url_launcher.dart';

class Dashboard extends StatefulWidget {
  const Dashboard({super.key});

  @override
  State<Dashboard> createState() => _DashboardState();
}

class _DashboardState extends State<Dashboard> {
  int _selectedIndex = 0;
  bool _showFocusBubble = false;
  bool _isCheckingPassword = true;

  @override
  void initState() {
    super.initState();
    // Use addPostFrameCallback to ensure context is available
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkPasswordAndLoad();
    });
  }

  Future<void> _checkPasswordAndLoad() async {
    if (!mounted) return;
    
    final authService = context.read<AuthService>();
    
    // Wait for auth service to fully load
    await Future.delayed(const Duration(milliseconds: 500));
    
    if (!mounted) return;
    
    // Check if user has password set
    if (!authService.hasPassword) {
      // User needs to set password first
      context.go('/set-password');
      return;
    }
    
    if (mounted) {
      setState(() => _isCheckingPassword = false);
      
      // Initialize real-time listeners after password check
      final contextService = context.read<ContextService>();
      contextService.initRealTimeListeners();
      
      await _loadData();
    }
  }

  Future<void> _loadData() async {
    if (!mounted) return;
    final contextService = context.read<ContextService>();
    await Future.wait([
      contextService.fetchSessions(),
      contextService.fetchContexts(),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    // Show loading while checking password
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
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isMobile = constraints.maxWidth < 600;
          
          return Stack(
            children: [
              Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF0F0F23), Color(0xFF1A1A2E)],
                  ),
                ),
                child: SafeArea(
                  child: isMobile
                      ? Column(
                          children: [
                            _buildTopBar(isMobile: true),
                            Expanded(child: _buildMainContent(isMobile: true)),
                            _buildBottomNav(),
                          ],
                        )
                      : Row(
                          children: [
                            _buildSidebar(),
                            Expanded(
                              child: Column(
                                children: [
                                  _buildTopBar(isMobile: false),
                                  Expanded(child: _buildMainContent(isMobile: false)),
                                ],
                              ),
                            ),
                          ],
                        ),
                ),
              ),
              // AI Focus Bubble Overlay
              if (_showFocusBubble)
                FocusBubbleOverlay(
                  message: 'You seem distracted. Would you like to enter focus mode to stay on track?',
                  onDismiss: () => setState(() => _showFocusBubble = false),
                  onAction: () {
                    setState(() => _showFocusBubble = false);
                    // Enter focus mode
                  },
                  actionLabel: 'Focus Mode',
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSidebar() {
    final menuItems = [
      {'icon': Icons.dashboard_outlined, 'label': 'Dashboard'},
      {'icon': Icons.history, 'label': 'History'},
      {'icon': Icons.analytics_outlined, 'label': 'Analytics'},
      {'icon': Icons.settings_outlined, 'label': 'Settings'},
    ];

    return Container(
      width: 80,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.03),
        border: Border(right: BorderSide(color: Colors.white.withOpacity(0.05))),
      ),
      child: Column(
        children: [
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF6366F1), Color(0xFF22D3EE)],
              ),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.psychology, color: Colors.white, size: 24),
          ),
          const SizedBox(height: 40),
          ...menuItems.asMap().entries.map((entry) {
            final index = entry.key;
            final item = entry.value;
            final isSelected = _selectedIndex == index;

            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Tooltip(
                message: item['label'] as String,
                preferBelow: false,
                child: InkWell(
                  onTap: () {
                    if (index == 3) {
                      context.push('/settings');
                    } else if (index == 2) {
                      context.push('/analytics');
                    } else if (index == 1) {
                      context.push('/history');
                    } else {
                      setState(() => _selectedIndex = index);
                    }
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? const Color(0xFF6366F1).withOpacity(0.2)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                      border: isSelected
                          ? Border.all(color: const Color(0xFF6366F1).withOpacity(0.3))
                          : null,
                    ),
                    child: Icon(
                      item['icon'] as IconData,
                      color: isSelected ? const Color(0xFF6366F1) : Colors.white54,
                      size: 24,
                    ),
                  ),
                ),
              ),
            );
          }),
          const Spacer(),
          Consumer<AuthService>(
            builder: (context, authService, child) {
              return Padding(
                padding: const EdgeInsets.all(16),
                child: Tooltip(
                  message: 'Sign Out',
                  child: InkWell(
                    onTap: () async {
                      await authService.signOut();
                      if (context.mounted) context.go('/');
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      child: const Icon(Icons.logout, color: Colors.white54, size: 24),
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNav() {
    final menuItems = [
      {'icon': Icons.dashboard_outlined, 'label': 'Dash'},
      {'icon': Icons.history, 'label': 'History'},
      {'icon': Icons.analytics_outlined, 'label': 'Stats'},
      {'icon': Icons.settings_outlined, 'label': 'Settings'},
    ];

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A2E),
        border: Border(top: BorderSide(color: Colors.white.withOpacity(0.05))),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: menuItems.asMap().entries.map((entry) {
          final index = entry.key;
          final item = entry.value;
          final isSelected = _selectedIndex == index;

          return InkWell(
            onTap: () {
              if (index == 3) {
                 context.push('/settings');
              } else if (index == 2) {
                 context.push('/analytics');
              } else if (index == 1) {
                 context.push('/history');
              } else {
                setState(() => _selectedIndex = index);
              }
            },
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected ? const Color(0xFF6366F1).withOpacity(0.2) : Colors.transparent,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    item['icon'] as IconData,
                    color: isSelected ? const Color(0xFF6366F1) : Colors.white54,
                    size: 24,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item['label'] as String,
                    style: TextStyle(
                      color: isSelected ? const Color(0xFF6366F1) : Colors.white54,
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildTopBar({required bool isMobile}) {
    return Consumer<AuthService>(
      builder: (context, authService, child) {
        final screenWidth = MediaQuery.of(context).size.width;
        final isVerySmall = screenWidth < 360;

        return Container(
          padding: EdgeInsets.symmetric(
            horizontal: isMobile ? 12 : 24,
            vertical: isMobile ? 12 : 24,
          ),
          child: Row(
            children: [
              if (isMobile) 
                 Container(
                  margin: EdgeInsets.only(right: isVerySmall ? 8 : 12),
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF6366F1), Color(0xFF22D3EE)],
                    ),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(Icons.psychology, color: Colors.white, size: isVerySmall ? 16 : 18),
                ),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Hi, ${authService.user?.displayName?.split(' ')[0] ?? 'User'}!',
                      style: TextStyle(
                        fontSize: isVerySmall ? 18 : (isMobile ? 20 : 24),
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (!isMobile)
                      Padding(
                        padding: const EdgeInsets.only(top: 4.0),
                        child: Text(
                          DateFormat('EEEE, MMMM d, y').format(DateTime.now()),
                          style: TextStyle(color: Colors.white.withOpacity(0.6)),
                        ),
                      ),
                  ],
                ),
              ),
              
              if (!isMobile) const Spacer(),
              
              Consumer<ContextService>(
                builder: (context, contextService, _) {
                  final activeCount = contextService.uniqueActiveContexts
                      .where((c) => !c.isRecovered).length;
                  if (activeCount == 0) return const SizedBox.shrink();
                  
                  return Padding(
                    padding: EdgeInsets.only(right: isVerySmall ? 4 : 8),
                    child: QuickResumeButton(
                      activeContexts: activeCount,
                      onTap: () => _showQuickResumeDialog(context),
                      compact: isMobile,
                    ),
                  );
                },
              ),
              
              if (!isMobile) ...[
                IconButton(
                  onPressed: _loadData,
                  icon: const Icon(Icons.refresh, color: Colors.white54),
                  tooltip: 'Refresh',
                ),
                const SizedBox(width: 8),
              ],
              
              IconButton(
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                onPressed: () {},
                icon: Stack(
                  children: [
                    const Icon(Icons.notifications_outlined, color: Colors.white54, size: 22),
                    Positioned(
                      right: 0,
                      top: 0,
                      child: Container(
                        width: 6,
                        height: 6,
                        decoration: const BoxDecoration(
                          color: Color(0xFF22D3EE),
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                  ],
                ),
                tooltip: 'Notifications',
              ),
              if (!isMobile) ...[
                const SizedBox(width: 16),
                CircleAvatar(
                  radius: 20,
                  backgroundColor: const Color(0xFF6366F1),
                  child: Text(
                    (authService.user?.displayName ?? 'U')[0].toUpperCase(),
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  void _showQuickResumeDialog(BuildContext context) {
    final contextService = context.read<ContextService>();
    final unrecovered = contextService.uniqueActiveContexts
        .where((c) => !c.isRecovered)
        .toList();

    if (unrecovered.isEmpty) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        title: const Text('Resume Work Context?', style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'You have ${unrecovered.length} active workspaces. This will open them in new tabs.',
              style: const TextStyle(color: Colors.white70),
            ),
            const SizedBox(height: 16),
            Flexible(
              child: SingleChildScrollView(
                child: Column(
                  children: unrecovered.take(5).map((ctx) => Padding(
                    padding: const EdgeInsets.only(bottom: 8.0),
                    child: Row(
                      children: [
                        const Icon(Icons.link, color: Colors.white54, size: 16),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            ctx.title.isNotEmpty ? ctx.title : ctx.url,
                            style: const TextStyle(color: Colors.white, fontSize: 13),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  )).toList(),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Colors.white54)),
          ),
          FilledButton.icon(
            onPressed: () async {
              Navigator.pop(context);
              int count = 0;
              for (final ctx in unrecovered) {
                final url = Uri.parse(ctx.url);
                if (await canLaunchUrl(url)) {
                  await launchUrl(url, mode: LaunchMode.externalApplication);
                  await contextService.markContextRecovered(ctx.id);
                  count++;
                  // Small delay to prevent browser blocking indiscriminately
                  await Future.delayed(const Duration(milliseconds: 300));
                }
              }
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Resumed $count workspaces'),
                    backgroundColor: const Color(0xFF10B981),
                  ),
                );
              }
            },
            style: FilledButton.styleFrom(backgroundColor: const Color(0xFF6366F1)),
            icon: const Icon(Icons.open_in_browser),
            label: const Text('Resume All'),
          ),
        ],
      ),
    );
  }

  Widget _buildMainContent({required bool isMobile}) {
    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 12 : 24,
        vertical: 16,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Row 1: Neuro-Flow Score + Active Workspace
          if (isMobile) ...[
            _buildNeuroFlowCard(),
            const SizedBox(height: 16),
            _buildActiveWorkspace(),
          ] else ...[
            LayoutBuilder(
              builder: (context, lb) {
                if (lb.maxWidth < 900) {
                  return Column(
                    children: [
                      _buildNeuroFlowCard(),
                      const SizedBox(height: 20),
                      _buildActiveWorkspace(),
                    ],
                  );
                }
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: _buildNeuroFlowCard()),
                    const SizedBox(width: 24),
                    Expanded(child: _buildActiveWorkspace()),
                  ],
                );
              }
            ),
          ],
          const SizedBox(height: 24),

          // Row 2: Stats
          _buildStatsRow(isMobile: isMobile),
          const SizedBox(height: 24),

          // Row 3: Activity Chart + Unique Contexts
           if (isMobile) ...[
             _buildSessionActivity(),
             const SizedBox(height: 16),
             _buildUniqueContextsList(),
           ] else
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(flex: 2, child: _buildSessionActivity()),
                const SizedBox(width: 24),
                Expanded(child: _buildUniqueContextsList()),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildNeuroFlowCard() {
    return Consumer<ContextService>(
      builder: (context, service, _) {
        final score = service.neuroFlowScore;
        return NeuroFlowScoreWidget(
          score: score?.score ?? 100, // Default to 100 if no data (fresh start)
          level: score?.level ?? 'Fresh Start',
          distractions: score?.distractions ?? 0,
          focusStreak: score?.focusStreak ?? 1,
          suggestions: score?.suggestions ?? ['Keep up the great focus!'],
          onTap: () => context.push('/analytics'),
        ).animate().fadeIn(duration: 500.ms).slideY(begin: -0.1);
      },
    );
  }

  Widget _buildActiveWorkspace() {
    return Consumer<ContextService>(
      builder: (context, service, _) {
        final activeContext = service.currentActiveWorkspace;
        
        if (activeContext == null) {
          return Container(
            padding: const EdgeInsets.all(40),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.03),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withOpacity(0.05)),
            ),
            child: Column(
              children: [
                Icon(Icons.check_circle, color: Colors.white.withOpacity(0.2), size: 48),
                const SizedBox(height: 12),
                Text(
                  'All caught up!',
                  style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 16),
                ),
                const SizedBox(height: 4),
                Text(
                  'No active workspaces needing attention',
                  style: TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 12),
                ),
              ],
            ),
          ).animate().fadeIn(duration: 500.ms);
        }

        return ActiveWorkspaceCard(
          title: activeContext.title,
          url: activeContext.url,
          type: activeContext.type,
          summary: activeContext.summary,
          keyPoints: activeContext.keyPoints,
          nextSteps: activeContext.nextSteps,
          visitCount: activeContext.visitCount,
          onResume: () async {
            final url = Uri.parse(activeContext.url);
            if (await canLaunchUrl(url)) {
              await launchUrl(url, mode: LaunchMode.externalApplication);
              await service.markContextRecovered(activeContext.id);
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Could not launch ${activeContext.url}')),
              );
            }
          },
          onArchive: () async {
            await service.archiveContext(activeContext.id);
          },
        ).animate().fadeIn(duration: 500.ms).slideY(begin: -0.1);
      },
    );
  }

  Widget _buildStatsRow({required bool isMobile}) {
    return Consumer<ContextService>(
      builder: (context, service, _) {
        final cards = [
          StatCard(
            title: 'Workspaces',
            value: service.uniqueActiveContexts.length.toString(),
            icon: Icons.workspaces_outlined,
            color: const Color(0xFF6366F1),
            trend: 'Live',
            isPositive: true,
            onTap: () => context.push('/analytics'),
          ).animate().fadeIn(duration: 400.ms).slideX(begin: -0.2),
          StatCard(
            title: 'Focus Score',
            value: '${service.focusScore.round()}%',
            icon: Icons.psychology,
            color: const Color(0xFF22D3EE),
            trend: service.focusScore >= 70 ? '+Good' : 'Low',
            isPositive: service.focusScore >= 70,
            onTap: () => context.push('/analytics'),
          ).animate().fadeIn(duration: 400.ms, delay: 100.ms).slideX(begin: -0.2),
          StatCard(
            title: 'Time Saved',
            value: '${service.totalTimeRecovered ~/ 60}m',
            icon: Icons.timer_outlined,
            color: const Color(0xFF10B981),
            trend: '+${service.totalTimeRecovered ~/ 60}m',
            isPositive: true,
            onTap: () => context.push('/analytics'),
          ).animate().fadeIn(duration: 400.ms, delay: 200.ms).slideX(begin: -0.2),
          StatCard(
            title: 'Distractions',
            value: service.distractionCount.toString(),
            icon: Icons.warning_amber_outlined,
            color: const Color(0xFFF59E0B),
            trend: service.distractionCount < 5 ? 'Low' : 'High',
            isPositive: service.distractionCount < 5,
            onTap: () => context.push('/analytics'),
          ).animate().fadeIn(duration: 400.ms, delay: 300.ms).slideX(begin: -0.2),
        ];

        return LayoutBuilder(
          builder: (context, constraints) {
            // Mobile & Small Tablets: 2 columns
            if (constraints.maxWidth < 650) {
              return GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                childAspectRatio: (constraints.maxWidth / 2) / 135,
                children: cards,
              );
            }

            // Desktop Layout - distribute evenly
            return Row(
              children: [
                for (int i = 0; i < cards.length; i++) ...[
                  Expanded(child: cards[i]),
                  if (i < cards.length - 1) const SizedBox(width: 16),
                ]
              ],
            );
          }
        );
      },
    );
  }

  Widget _buildSessionActivity() {
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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Cognitive Flow Timeline',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'This Week',
                  style: TextStyle(color: Colors.white60, fontSize: 12),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 200,
            child: _buildActivityChart(),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildChartLegend('Focused', const Color(0xFF6366F1)),
              const SizedBox(width: 24),
              _buildChartLegend('Interrupted', const Color(0xFFF59E0B)),
            ],
          ),
        ],
      ),
    ).animate().fadeIn(duration: 600.ms, delay: 400.ms);
  }

  Widget _buildChartLegend(String label, Color color) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 8),
        Text(label, style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 12)),
      ],
    );
  }

  Widget _buildActivityChart() {
    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: 100,
        barTouchData: BarTouchData(
          touchTooltipData: BarTouchTooltipData(
            getTooltipColor: (group) => const Color(0xFF1A1A2E),
          ),
        ),
        titlesData: FlTitlesData(
          show: true,
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
                return Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    days[value.toInt() % 7],
                    style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 12),
                  ),
                );
              },
              reservedSize: 30,
            ),
          ),
          leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(show: false),
        gridData: const FlGridData(show: false),
        barGroups: [
          _buildBarGroup(0, 65, 25),
          _buildBarGroup(1, 80, 15),
          _buildBarGroup(2, 55, 30),
          _buildBarGroup(3, 70, 20),
          _buildBarGroup(4, 85, 10),
          _buildBarGroup(5, 45, 35),
          _buildBarGroup(6, 60, 25),
        ],
      ),
    );
  }

  BarChartGroupData _buildBarGroup(int x, double productive, double interrupted) {
    return BarChartGroupData(
      x: x,
      barRods: [
        BarChartRodData(
          toY: productive + interrupted,
          width: 20,
          borderRadius: BorderRadius.circular(6),
          rodStackItems: [
            BarChartRodStackItem(0, productive, const Color(0xFF6366F1)),
            BarChartRodStackItem(productive, productive + interrupted, const Color(0xFFF59E0B).withOpacity(0.6)),
          ],
        ),
      ],
    );
  }

  Widget _buildUniqueContextsList() {
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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Unique Workspaces',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              TextButton(
                onPressed: () => context.push('/history'),
                child: const Text('View All', style: TextStyle(color: Color(0xFF22D3EE))),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Only unique active work (no duplicates)',
            style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 11),
          ),
          const SizedBox(height: 16),
          Consumer<ContextService>(
            builder: (context, service, _) {
              if (service.uniqueActiveContexts.isEmpty) {
                return Container(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      Icon(Icons.hourglass_empty, color: Colors.white.withOpacity(0.3), size: 48),
                      const SizedBox(height: 12),
                      Text(
                        'No active workspaces',
                        style: TextStyle(color: Colors.white.withOpacity(0.5)),
                      ),
                    ],
                  ),
                );
              }

              return Column(
                children: service.uniqueActiveContexts.take(6).map((ctx) {
                  return Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.02),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white.withOpacity(0.05)),
                    ),
                    child: Row(
                      children: [
                        Text(ctx.typeIcon, style: const TextStyle(fontSize: 20)),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                ctx.title,
                                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500, fontSize: 13),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 2),
                              Row(
                                children: [
                                  Text(
                                    ctx.domain,
                                    style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 11),
                                  ),
                                  if (ctx.visitCount > 1) ...[
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF6366F1).withOpacity(0.2),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        '${ctx.visitCount} visits',
                                        style: const TextStyle(
                                          color: Color(0xFF6366F1),
                                          fontSize: 9,
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ],
                          ),
                        ),
                        if (ctx.isRecovered)
                          const Icon(Icons.check_circle, color: Color(0xFF10B981), size: 18),
                      ],
                    ),
                  );
                }).toList(),
              );
            },
          ),
        ],
      ),
    ).animate().fadeIn(duration: 600.ms, delay: 500.ms);
  }
}
