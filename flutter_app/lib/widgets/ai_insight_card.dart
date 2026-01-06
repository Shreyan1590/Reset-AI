import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

/// AI Insight Card with explainable reasoning
/// Demonstrates responsible AI by showing why decisions were made
class AIInsightCard extends StatefulWidget {
  final String title;
  final String insight;
  final String reasoning;
  final List<String> suggestions;
  final double confidenceScore;
  final IconData icon;
  final Color accentColor;
  final VoidCallback? onAction;
  final String? actionLabel;

  const AIInsightCard({
    super.key,
    required this.title,
    required this.insight,
    required this.reasoning,
    this.suggestions = const [],
    this.confidenceScore = 0.8,
    this.icon = Icons.auto_awesome,
    this.accentColor = const Color(0xFF6366F1),
    this.onAction,
    this.actionLabel,
  });

  @override
  State<AIInsightCard> createState() => _AIInsightCardState();
}

class _AIInsightCardState extends State<AIInsightCard> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            widget.accentColor.withOpacity(0.1),
            widget.accentColor.withOpacity(0.03),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: widget.accentColor.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: widget.accentColor.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(widget.icon, color: widget.accentColor, size: 22),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                widget.title,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(width: 8),
                              _buildConfidenceBadge(),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'AI-powered insight',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.5),
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 16),
                
                // Main insight
                Text(
                  widget.insight,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 14,
                    height: 1.5,
                  ),
                ),
                
                // Suggestions
                if (widget.suggestions.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  ...widget.suggestions.map((s) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('→ ', style: TextStyle(color: widget.accentColor)),
                        Expanded(
                          child: Text(
                            s,
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.8),
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ),
                  )),
                ],
              ],
            ),
          ),
          
          // Expandable reasoning section ("Why this insight?")
          InkWell(
            onTap: () => setState(() => _isExpanded = !_isExpanded),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.03),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(_isExpanded ? 0 : 20),
                  bottomRight: Radius.circular(_isExpanded ? 0 : 20),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.help_outline,
                    color: Colors.white.withOpacity(0.5),
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Why this insight?',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.6),
                      fontSize: 12,
                    ),
                  ),
                  const Spacer(),
                  Icon(
                    _isExpanded ? Icons.expand_less : Icons.expand_more,
                    color: Colors.white.withOpacity(0.5),
                    size: 20,
                  ),
                ],
              ),
            ),
          ),
          
          // Expanded reasoning
          if (_isExpanded)
            Container(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.02),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(20),
                  bottomRight: Radius.circular(20),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.psychology_outlined,
                        color: widget.accentColor.withOpacity(0.7),
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'AI Reasoning',
                        style: TextStyle(
                          color: widget.accentColor,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    widget.reasoning,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.7),
                      fontSize: 13,
                      height: 1.5,
                    ),
                  ),
                  if (widget.onAction != null && widget.actionLabel != null) ...[
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: widget.onAction,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: widget.accentColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(widget.actionLabel!),
                    ),
                  ],
                ],
              ),
            ).animate().fadeIn(duration: 200.ms),
        ],
      ),
    );
  }

  Widget _buildConfidenceBadge() {
    final percentage = (widget.confidenceScore * 100).round();
    Color badgeColor;
    
    if (percentage >= 80) {
      badgeColor = const Color(0xFF10B981);
    } else if (percentage >= 60) {
      badgeColor = const Color(0xFFF59E0B);
    } else {
      badgeColor = Colors.white54;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: badgeColor.withOpacity(0.2),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        '$percentage% confident',
        style: TextStyle(
          color: badgeColor,
          fontSize: 10,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

/// Quick AI insight chip for inline display
class AIInsightChip extends StatelessWidget {
  final String label;
  final String category;
  final double? productivityImpact;

  const AIInsightChip({
    super.key,
    required this.label,
    required this.category,
    this.productivityImpact,
  });

  @override
  Widget build(BuildContext context) {
    final isPositive = (productivityImpact ?? 0) > 0;
    final color = isPositive ? const Color(0xFF10B981) : const Color(0xFFF59E0B);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            _getCategoryIcon(category),
            color: color,
            size: 14,
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'work':
        return Icons.work_outline;
      case 'learning':
        return Icons.school_outlined;
      case 'research':
        return Icons.search;
      case 'entertainment':
        return Icons.movie_outlined;
      case 'distraction':
        return Icons.warning_amber_outlined;
      case 'communication':
        return Icons.chat_bubble_outline;
      default:
        return Icons.label_outline;
    }
  }
}
