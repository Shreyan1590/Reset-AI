import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Privacy-first banner widget for RESET AI
/// Demonstrates responsible data handling aligned with Google's AI principles
class PrivacyBanner extends StatelessWidget {
  final bool compact;
  final VoidCallback? onLearnMore;

  const PrivacyBanner({
    super.key,
    this.compact = false,
    this.onLearnMore,
  });

  @override
  Widget build(BuildContext context) {
    if (compact) {
      return _buildCompactBanner(context);
    }
    return _buildFullBanner(context);
  }

  Widget _buildCompactBanner(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF10B981).withOpacity(0.1),
            const Color(0xFF22D3EE).withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF10B981).withOpacity(0.2)),
      ),
      child: Row(
        children: [
          const Icon(Icons.shield_outlined, color: Color(0xFF10B981), size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Your data is private & never sold',
              style: TextStyle(
                color: Colors.white.withOpacity(0.8),
                fontSize: 12,
              ),
            ),
          ),
          TextButton(
            onPressed: onLearnMore ?? () => context.push('/privacy-policy'),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: const Text(
              'Learn more',
              style: TextStyle(color: Color(0xFF22D3EE), fontSize: 11),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFullBanner(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF10B981).withOpacity(0.1),
            const Color(0xFF22D3EE).withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF10B981).withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.shield_outlined, color: Color(0xFF10B981), size: 24),
              ),
              const SizedBox(width: 14),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Privacy-First Design',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Your data stays yours',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.6),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Privacy promises
          _buildPrivacyItem(Icons.lock_outline, 'End-to-end encrypted storage'),
          const SizedBox(height: 10),
          _buildPrivacyItem(Icons.visibility_off_outlined, 'Data is never sold or shared'),
          const SizedBox(height: 10),
          _buildPrivacyItem(Icons.person_outline, 'User-controlled deletion'),
          const SizedBox(height: 10),
          _buildPrivacyItem(Icons.psychology_outlined, 'Explainable AI decisions'),
          
          const SizedBox(height: 16),
          
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => context.push('/privacy-policy'),
                  icon: const Icon(Icons.article_outlined, size: 16),
                  label: const Text('Privacy Policy'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white70,
                    side: BorderSide(color: Colors.white.withOpacity(0.2)),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    // TODO: Implement data export
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Data export coming soon')),
                    );
                  },
                  icon: const Icon(Icons.download_outlined, size: 16),
                  label: const Text('Export Data'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white70,
                    side: BorderSide(color: Colors.white.withOpacity(0.2)),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPrivacyItem(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, color: const Color(0xFF10B981), size: 16),
        const SizedBox(width: 10),
        Text(
          text,
          style: TextStyle(
            color: Colors.white.withOpacity(0.8),
            fontSize: 13,
          ),
        ),
      ],
    );
  }
}
