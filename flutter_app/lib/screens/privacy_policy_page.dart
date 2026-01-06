import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';

class PrivacyPolicyPage extends StatelessWidget {
  const PrivacyPolicyPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
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
          child: Column(
            children: [
              _buildHeader(context),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: _buildContent(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        border: Border(
          bottom: BorderSide(color: Colors.white.withOpacity(0.1)),
        ),
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => context.go('/login'),
          ),
          const SizedBox(width: 8),
          const Icon(Icons.privacy_tip_outlined, color: Color(0xFF6366F1)),
          const SizedBox(width: 12),
          const Text(
            'Privacy Policy',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms);
  }

  Widget _buildContent() {
    return Container(
      constraints: const BoxConstraints(maxWidth: 800),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSection('Last Updated', 'January 1, 2026'),
          const SizedBox(height: 24),
          
          _buildSection('1. Introduction', '''
RESET AI ("we," "our," or "us") is committed to protecting your privacy. This Privacy Policy explains how we collect, use, disclose, and safeguard your information when you use our cognitive recovery and context loss detection application.

By using RESET AI, you agree to the collection and use of information in accordance with this policy.
'''),
          
          _buildSection('2. Information We Collect', '''
We collect information you provide directly:
• Account information (name, email address)
• Authentication data (encrypted passwords)
• Focus and productivity metrics you choose to track
• Recovery session data and context snapshots

Automatically collected information:
• Device information and browser type
• Usage patterns and feature interactions
• Session timestamps and duration
'''),
          
          _buildSection('3. How We Use Your Information', '''
We use the collected information to:
• Provide and maintain the RESET AI service
• Personalize your cognitive recovery experience
• Analyze focus patterns and provide insights
• Improve our algorithms and features
• Send important service notifications
• Ensure security and prevent fraud
'''),
          
          _buildSection('4. Data Storage and Security', '''
• Your data is stored securely using Firebase/Google Cloud infrastructure
• We use industry-standard encryption for data in transit and at rest
• Access to personal data is strictly limited to authorized personnel
• We implement regular security audits and monitoring
• Your focus data is processed locally when possible
'''),
          
          _buildSection('5. Data Sharing', '''
We do NOT sell your personal information. We may share data only:
• With your explicit consent
• To comply with legal obligations
• To protect our rights and safety
• With service providers who assist our operations (under strict confidentiality)
'''),
          
          _buildSection('6. Your Rights', '''
You have the right to:
• Access your personal data
• Request correction of inaccurate data
• Delete your account and associated data
• Export your data in a portable format
• Opt-out of non-essential communications
'''),
          
          _buildSection('7. Cookies and Tracking', '''
We use essential cookies and local storage to:
• Maintain your login session
• Remember your preferences
• Enable core functionality

We do not use third-party advertising trackers.
'''),
          
          _buildSection('8. Children\'s Privacy', '''
RESET AI is not intended for users under 13 years of age. We do not knowingly collect personal information from children under 13.
'''),
          
          _buildSection('9. Changes to This Policy', '''
We may update this Privacy Policy from time to time. We will notify you of significant changes via email or in-app notification.
'''),
          
          _buildSection('10. Contact Us', '''
For questions about this Privacy Policy or your data, contact us at:
• Email: privacy@resetai.app
• Project: RESET AI - GDG Hackathon 2026
'''),
        ],
      ),
    ).animate().fadeIn(duration: 600.ms, delay: 200.ms).slideY(begin: 0.1);
  }

  Widget _buildSection(String title, String content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFF22D3EE),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          content.trim(),
          style: TextStyle(
            fontSize: 14,
            color: Colors.white.withOpacity(0.8),
            height: 1.6,
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}
