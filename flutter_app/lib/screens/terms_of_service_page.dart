import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';

class TermsOfServicePage extends StatelessWidget {
  const TermsOfServicePage({super.key});

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
          const Icon(Icons.description_outlined, color: Color(0xFF6366F1)),
          const SizedBox(width: 12),
          const Text(
            'Terms of Service',
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
          
          _buildSection('1. Acceptance of Terms', '''
By accessing or using RESET AI ("Service"), you agree to be bound by these Terms of Service ("Terms"). If you disagree with any part of these terms, you may not access the Service.

These Terms apply to all visitors, users, and others who access or use the Service.
'''),
          
          _buildSection('2. Description of Service', '''
RESET AI is a cognitive recovery and context loss detection system that helps users:
• Track and analyze focus patterns
• Recover from context switching and interruptions
• Improve productivity through AI-assisted insights
• Sync data across web and browser extension platforms

The Service is provided "as is" and "as available" without warranties of any kind.
'''),
          
          _buildSection('3. User Accounts', '''
When you create an account with us, you must provide accurate and complete information. You are responsible for:
• Safeguarding your password
• All activities that occur under your account
• Notifying us immediately of any unauthorized access

We reserve the right to suspend or terminate accounts that violate these Terms.
'''),
          
          _buildSection('4. Acceptable Use', '''
You agree NOT to:
• Use the Service for any unlawful purpose
• Attempt to gain unauthorized access to our systems
• Interfere with or disrupt the Service
• Transmit viruses or malicious code
• Collect user information without consent
• Impersonate others or misrepresent your affiliation
• Use automated systems to access the Service excessively
'''),
          
          _buildSection('5. Intellectual Property', '''
The Service and its original content, features, and functionality are owned by RESET AI and are protected by international copyright, trademark, and other intellectual property laws.

You retain ownership of any data you provide to the Service. By submitting data, you grant us a license to use it solely for providing and improving the Service.
'''),
          
          _buildSection('6. User Content', '''
You are responsible for any content you submit to the Service. You represent that:
• You own or have rights to the content
• The content does not violate any third-party rights
• The content is not illegal, harmful, or offensive

We may remove content that violates these Terms without notice.
'''),
          
          _buildSection('7. Privacy', '''
Your use of the Service is also governed by our Privacy Policy. Please review our Privacy Policy to understand our practices regarding your personal data.
'''),
          
          _buildSection('8. Termination', '''
We may terminate or suspend your access immediately, without prior notice, for any reason, including breach of these Terms.

Upon termination:
• Your right to use the Service ceases immediately
• We may delete your account and data
• Provisions that should survive termination will remain in effect
'''),
          
          _buildSection('9. Limitation of Liability', '''
To the maximum extent permitted by law, RESET AI shall not be liable for:
• Any indirect, incidental, special, or consequential damages
• Loss of profits, data, or business opportunities
• Damages arising from your use or inability to use the Service

Our total liability shall not exceed the amount you paid for the Service in the past 12 months.
'''),
          
          _buildSection('10. Disclaimer', '''
The Service is provided "AS IS" without warranty of any kind. We disclaim all warranties, express or implied, including:
• Merchantability and fitness for a particular purpose
• Non-infringement
• Accuracy or reliability of any content
• Uninterrupted or error-free operation
'''),
          
          _buildSection('11. Changes to Terms', '''
We reserve the right to modify these Terms at any time. We will provide notice of significant changes through:
• Email notification
• In-app notification
• Updating the "Last Updated" date

Continued use after changes constitutes acceptance of the new Terms.
'''),
          
          _buildSection('12. Governing Law', '''
These Terms shall be governed by the laws of the jurisdiction where RESET AI operates, without regard to conflict of law provisions.

Any disputes shall be resolved through binding arbitration or in the courts of the applicable jurisdiction.
'''),
          
          _buildSection('13. Contact Us', '''
For questions about these Terms of Service, contact us at:
• Email: legal@resetai.app
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
