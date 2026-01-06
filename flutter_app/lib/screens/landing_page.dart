import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';

class LandingPage extends StatelessWidget {
  const LandingPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isMobile = constraints.maxWidth < 700;
          return Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF0F0F23),
                  Color(0xFF1A1A2E),
                  Color(0xFF16213E),
                ],
              ),
            ),
            child: SafeArea(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    _buildNavBar(context, isMobile),
                    _buildHeroSection(context, isMobile),
                    _buildFeaturesSection(context, isMobile),
                    _buildHowItWorksSection(context, isMobile),
                    _buildUseCasesSection(context, isMobile),
                    _buildCTASection(context, isMobile),
                    _buildFooter(context, isMobile),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildNavBar(BuildContext context, bool isMobile) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: isMobile ? 16 : 24, vertical: 16),
      child: isMobile 
        ? Column(
            children: [
              // Mobile Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF6366F1), Color(0xFF22D3EE)],
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.psychology, color: Colors.white, size: 24),
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        'RESET AI',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.login, color: Colors.white),
                    onPressed: () => context.go('/login'),
                  ),
                ],
              ),
            ],
          )
        : Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF6366F1), Color(0xFF22D3EE)],
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.psychology, color: Colors.white, size: 28),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'RESET AI',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  TextButton(
                    onPressed: () => context.go('/login'),
                    child: const Text(
                      'Login',
                      style: TextStyle(color: Colors.white70),
                    ),
                  ),
                  const SizedBox(width: 16),
                  ElevatedButton(
                    onPressed: () => context.go('/signup'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF6366F1),
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    ),
                    child: const Text('Get Started'),
                  ),
                ],
              ),
            ],
          ),
    );
  }

  Widget _buildHeroSection(BuildContext context, bool isMobile) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 24, vertical: isMobile ? 40 : 80),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFF6366F1).withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFF6366F1).withOpacity(0.3)),
            ),
            child: const Text(
              '🧠 AI-Powered Cognitive Recovery',
              style: TextStyle(color: Color(0xFF22D3EE), fontSize: 14),
            ),
          ).animate().fadeIn(duration: 600.ms).slideY(begin: -0.3),
          const SizedBox(height: 24),
          Text(
            'Never Lose Your\nThought Flow Again',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: isMobile ? 36 : (MediaQuery.of(context).size.width > 600 ? 56 : 36),
              fontWeight: FontWeight.bold,
              color: Colors.white,
              height: 1.2,
            ),
          ).animate().fadeIn(duration: 800.ms, delay: 200.ms).slideY(begin: 0.3),
          const SizedBox(height: 24),
          Text(
            'RESET AI detects when you lose context and instantly\nrestores your thinking state. Stay in flow, always.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: isMobile ? 16 : 18,
              color: Colors.white.withOpacity(0.7),
              height: 1.6,
            ),
          ).animate().fadeIn(duration: 800.ms, delay: 400.ms),
          const SizedBox(height: 40),
          isMobile
            ? Column(
                children: [
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => context.go('/signup'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF6366F1),
                        padding: const EdgeInsets.symmetric(vertical: 20),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('Start Free Trial', style: TextStyle(fontSize: 16)),
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: () {},
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        side: BorderSide(color: Colors.white.withOpacity(0.3)),
                        padding: const EdgeInsets.symmetric(vertical: 20),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('Watch Demo'),
                    ),
                  ),
                ],
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton(
                    onPressed: () => context.go('/signup'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF6366F1),
                      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Row(
                      children: [
                        Text('Start Free Trial', style: TextStyle(fontSize: 16)),
                        SizedBox(width: 8),
                        Icon(Icons.arrow_forward, size: 18),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  OutlinedButton(
                    onPressed: () {},
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: BorderSide(color: Colors.white.withOpacity(0.3)),
                      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.play_circle_outline, size: 20),
                        SizedBox(width: 8),
                        Text('Watch Demo'),
                      ],
                    ),
                  ),
                ],
              ).animate().fadeIn(duration: 800.ms, delay: 600.ms),
          const SizedBox(height: 60),
          _buildMockupPreview(isMobile),
        ],
      ),
    );
  }

  Widget _buildMockupPreview(bool isMobile) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 900),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withOpacity(0.1),
            Colors.white.withOpacity(0.05),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6366F1).withOpacity(0.3),
            blurRadius: 60,
            offset: const Offset(0, 20),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: EdgeInsets.all(isMobile ? 12 : 20),
          child: Column(
            children: [
              _buildMockupHeader(),
              const SizedBox(height: 16),
              _buildMockupContent(isMobile),
            ],
          ),
        ),
      ),
    ).animate().fadeIn(duration: 1000.ms, delay: 800.ms).scale(begin: const Offset(0.9, 0.9));
  }

  Widget _buildMockupHeader() {
    return Row(
      children: [
        Container(width: 12, height: 12, decoration: const BoxDecoration(color: Color(0xFFFF5F57), shape: BoxShape.circle)),
        const SizedBox(width: 8),
        Container(width: 12, height: 12, decoration: const BoxDecoration(color: Color(0xFFFFBD2E), shape: BoxShape.circle)),
        const SizedBox(width: 8),
        Container(width: 12, height: 12, decoration: const BoxDecoration(color: Color(0xFF28CA42), shape: BoxShape.circle)),
      ],
    );
  }

  Widget _buildMockupContent(bool isMobile) {
    return Container(
      padding: EdgeInsets.all(isMobile ? 16 : 24),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A2E),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF22D3EE).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.lightbulb_outline, color: Color(0xFF22D3EE)),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Context Recovery Available',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'You were working on: Flutter authentication flow',
                      style: const TextStyle(color: Colors.white70, fontSize: 14),
                      maxLines: isMobile ? 2 : 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('📌 Key Points:', style: TextStyle(color: Color(0xFF22D3EE), fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                Text('• Implementing Firebase Auth service', style: TextStyle(color: Colors.white.withOpacity(0.8))),
                Text('• Setting up Google Sign-In', style: TextStyle(color: Colors.white.withOpacity(0.8))),
                Text('• Creating user model for Firestore', style: TextStyle(color: Colors.white.withOpacity(0.8))),
              ],
            ),
          ),
          const SizedBox(height: 16),
          if (isMobile)
             Column(
              children: [
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {},
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF10B981),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: const Text('Resume Work'),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () {},
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white70,
                      side: BorderSide(color: Colors.white.withOpacity(0.2)),
                      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
                    ),
                    child: const Text('Skip'),
                  ),
                ),
              ],
            )
          else
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {},
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF10B981),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: const Text('Resume Work'),
                  ),
                ),
                const SizedBox(width: 12),
                OutlinedButton(
                  onPressed: () {},
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white70,
                    side: BorderSide(color: Colors.white.withOpacity(0.2)),
                    padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
                  ),
                  child: const Text('Skip'),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildFeaturesSection(BuildContext context, bool isMobile) {
    final features = [
      {
        'icon': Icons.track_changes,
        'title': 'Smart Context Tracking',
        'description': 'Monitors tab switches, idle time, and behavior patterns to detect context loss moments.',
        'color': const Color(0xFF6366F1),
      },
      {
        'icon': Icons.psychology,
        'title': 'AI-Powered Detection',
        'description': 'ML model classifies when you\'ve lost context without being intrusive or annoying.',
        'color': const Color(0xFF22D3EE),
      },
      {
        'icon': Icons.restore,
        'title': 'Instant Recovery',
        'description': 'Generate summaries, key points, and next steps to get you back in flow immediately.',
        'color': const Color(0xFF10B981),
      },
      {
        'icon': Icons.analytics_outlined,
        'title': 'Productivity Analytics',
        'description': 'Track interruptions, time saved, and cognitive patterns with detailed dashboards.',
        'color': const Color(0xFFF59E0B),
      },
    ];

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 24, vertical: isMobile ? 60 : 80),
      child: Column(
        children: [
          Text(
            'Core Features',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: isMobile ? 28 : 36,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Everything you need to maintain cognitive flow',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: isMobile ? 16 : 18, color: Colors.white.withOpacity(0.7)),
          ),
          const SizedBox(height: 60),
          Wrap(
            spacing: 24,
            runSpacing: 24,
            children: features.asMap().entries.map((entry) {
              final index = entry.key;
              final feature = entry.value;
              return Container(
                width: MediaQuery.of(context).size.width > 800 ? 280 : double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white.withOpacity(0.1)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: (feature['color'] as Color).withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(feature['icon'] as IconData, color: feature['color'] as Color, size: 28),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      feature['title'] as String,
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      feature['description'] as String,
                      style: TextStyle(color: Colors.white.withOpacity(0.7), height: 1.5),
                    ),
                  ],
                ),
              ).animate().fadeIn(duration: 600.ms, delay: Duration(milliseconds: 200 * index)).slideY(begin: 0.3);
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildHowItWorksSection(BuildContext context, bool isMobile) {
    final steps = [
      {'number': '01', 'title': 'Monitor', 'description': 'Track your activity across tabs, documents, and apps'},
      {'number': '02', 'title': 'Detect', 'description': 'AI identifies when you\'ve lost your thought flow'},
      {'number': '03', 'title': 'Capture', 'description': 'Automatically save context snapshots of your work'},
      {'number': '04', 'title': 'Recover', 'description': 'Resume instantly with AI-generated summaries'},
    ];

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 24, vertical: isMobile ? 60 : 80),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF6366F1).withOpacity(0.1),
            Colors.transparent,
          ],
        ),
      ),
      child: Column(
        children: [
          Text(
            'How It Works',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: isMobile ? 28 : 36, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          const SizedBox(height: 60),
          Wrap(
            spacing: 40,
            runSpacing: 40,
            alignment: WrapAlignment.center,
            children: steps.asMap().entries.map((entry) {
              final step = entry.value;
              return SizedBox(
                width: 200,
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: const Color(0xFF6366F1), width: 2),
                      ),
                      child: Text(
                        step['number']!,
                        style: const TextStyle(
                          color: Color(0xFF6366F1),
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      step['title']!,
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      step['description']!,
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.white.withOpacity(0.7)),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildUseCasesSection(BuildContext context, bool isMobile) {
    final useCases = [
      {'emoji': '🎓', 'title': 'Students', 'description': 'Resume study materials and research exactly where you left off'},
      {'emoji': '💻', 'title': 'Developers', 'description': 'Restore code context, stack traces, and debugging sessions'},
      {'emoji': '📊', 'title': 'Professionals', 'description': 'Continue documents, emails, and meetings without missing a beat'},
      {'emoji': '📱', 'title': 'Daily Users', 'description': 'Switch between apps without losing your train of thought'},
    ];

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 24, vertical: isMobile ? 60 : 80),
      child: Column(
        children: [
          Text(
            'Built For Everyone',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: isMobile ? 28 : 36, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          const SizedBox(height: 60),
          Wrap(
            spacing: 24,
            runSpacing: 24,
            alignment: WrapAlignment.center,
            children: useCases.map((useCase) {
              return Container(
                width: isMobile ? double.infinity : 260,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.white.withOpacity(0.1),
                      Colors.white.withOpacity(0.05),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white.withOpacity(0.1)),
                ),
                child: Column(
                  children: [
                    Text(useCase['emoji']!, style: const TextStyle(fontSize: 48)),
                    const SizedBox(height: 16),
                    Text(
                      useCase['title']!,
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      useCase['description']!,
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.white.withOpacity(0.7)),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildCTASection(BuildContext context, bool isMobile) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF6366F1), Color(0xFF22D3EE)],
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        children: [
          Text(
            'Ready to Reclaim Your Focus?',
            style: TextStyle(fontSize: isMobile ? 24 : 32, fontWeight: FontWeight.bold, color: Colors.white),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Text(
            'Join thousands of users who have reduced their context switching fatigue by 70%',
            style: TextStyle(fontSize: isMobile ? 14 : 16, color: Colors.white.withOpacity(0.9)),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          ElevatedButton(
            onPressed: () => context.go('/signup'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: const Color(0xFF6366F1),
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            ),
            child: const Text('Get Started Free', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter(BuildContext context, bool isMobile) {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Divider(color: Colors.white.withOpacity(0.1)),
          const SizedBox(height: 24),
          if (isMobile)
            Column(
              children: [
                Text('© 2024 RESET AI', style: TextStyle(color: Colors.white.withOpacity(0.5))),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: () {},
                  child: Text('Privacy Policy', style: TextStyle(color: Colors.white.withOpacity(0.5))),
                ),
                TextButton(
                  onPressed: () {},
                  child: Text('Terms of Service', style: TextStyle(color: Colors.white.withOpacity(0.5))),
                ),
              ],
            )
          else
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('© 2024 RESET AI', style: TextStyle(color: Colors.white.withOpacity(0.5))),
                const SizedBox(width: 24),
                TextButton(
                  onPressed: () => context.go('/privacy-policy'),
                  child: Text('Privacy Policy', style: TextStyle(color: Colors.white.withOpacity(0.5))),
                ),
                TextButton(
                  onPressed: () => context.go('/terms-of-service'),
                  child: Text('Terms of Service', style: TextStyle(color: Colors.white.withOpacity(0.5))),
                ),
              ],
            ),
        ],
      ),
    );
  }
}
