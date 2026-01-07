import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/context_service.dart';
import '../services/gemini_service.dart';
import '../models/session_model.dart';


class SessionDetail extends StatelessWidget {
  final String sessionId;
  const SessionDetail({super.key, required this.sessionId});

  @override
  Widget build(BuildContext context) {
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
              _buildHeader(context),
              Expanded(child: _buildContent(context)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back, color: Colors.white),
          ),
          const SizedBox(width: 16),
          const Flexible(
            child: Text('Session Details',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    return Consumer<ContextService>(
      builder: (context, service, _) {
        final session = service.sessions.firstWhere(
          (s) => s.id == sessionId,
          orElse: () => service.sessions.first,
        );

        return LayoutBuilder(
          builder: (context, constraints) {
            final isMobile = constraints.maxWidth < 700;
            
            return SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (isMobile) ...[
                    _buildInfoCard('Duration', session.durationFormatted, Icons.timer),
                    const SizedBox(height: 16),
                    _buildInfoCard('Interruptions', '${session.interruptions}', Icons.warning_amber),
                    const SizedBox(height: 16),
                    _buildInfoCard('Time Recovered', '${session.timeRecovered ~/ 60}m', Icons.restore),
                    const SizedBox(height: 16),
                    _buildInfoCard('Status', session.status.toUpperCase(), Icons.info_outline),
                  ] else 
                    GridView.count(
                      crossAxisCount: 2,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      shrinkWrap: true,
                      childAspectRatio: 3,
                      physics: const NeverScrollableScrollPhysics(),
                      children: [
                        _buildInfoCard('Duration', session.durationFormatted, Icons.timer),
                        _buildInfoCard('Interruptions', '${session.interruptions}', Icons.warning_amber),
                        _buildInfoCard('Time Recovered', '${session.timeRecovered ~/ 60}m', Icons.restore),
                        _buildInfoCard('Status', session.status.toUpperCase(), Icons.info_outline),
                      ],
                    ),
                  const SizedBox(height: 24),
                  _buildAISummaryCard(context, session),
                  const SizedBox(height: 24),
                  _buildContextList(context, session),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildInfoCard(String title, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.03),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFF6366F1), size: 28),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: TextStyle(color: Colors.white.withOpacity(0.5))),
              const SizedBox(height: 4),
              Text(value, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAISummaryCard(BuildContext context, SessionModel session) {
    if (session.aiSummary != null && session.aiSummary!.isNotEmpty) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [const Color(0xFF6366F1).withOpacity(0.1), const Color(0xFF8B5CF6).withOpacity(0.1)],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFF6366F1).withOpacity(0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.auto_awesome, color: Color(0xFF6366F1), size: 24),
                const SizedBox(width: 12),
                const Text('AI Session Summary',
                    style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              session.aiSummary!,
              style: TextStyle(color: Colors.white.withOpacity(0.9), height: 1.5, fontSize: 15),
            ),
          ],
        ),
      );
    }

    return Center(
      child: ElevatedButton.icon(
        onPressed: () => _generateSummary(context, session),
        icon: const Icon(Icons.auto_awesome),
        label: const Text('Generate AI Summary'),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF6366F1),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        ),
      ),
    );
  }

  Future<void> _generateSummary(BuildContext context, SessionModel session) async {
    // 1. Fetch contexts for this session (mocking fetch for now or using service)
    final contextService = Provider.of<ContextService>(context, listen: false);
    // Assuming contextService has contexts loaded or we can filter them locally/fetch them
    // For specific session context fetching, we might need a new method in ContextService.
    // For now, let's use the current contexts if they match or just fetch logic.
    // But better: let's assume we pass the session ID to the backend/service.

    // Using GeminiService directly here for Hackathon speed
    // Ideally, this should be in ContextService or SessionService
    
    showDialog(context: context, barrierDismissible: false, builder: (_) => const Center(child: CircularProgressIndicator()));

    try {
      final geminiService = GeminiService();
      // Temporary: Use all contexts for now as we don't have session-specific fetch readily exposed in provider
      // TODO: Implement getContextsBySession in ContextService
      final contexts = contextService.contexts.where((c) => c.sessionId == session.id).toList(); 
      
      // Fallback if no specific session ID contexts found (e.g. testing)
      final contextsToUse = contexts.isNotEmpty ? contexts : contextService.contexts;

      if (contextsToUse.isEmpty) {
        if (context.mounted) Navigator.pop(context);
        return;
      }
      
      final summary = await geminiService.generateSessionSummary(contextsToUse);
      
      // Update session locally and in Firestore
      await contextService.updateSessionSummary(session.id, summary);
      
      if (context.mounted) {
         Navigator.pop(context); // Close loading
         
         // Show error if summary failed
         if (summary.startsWith("Error")) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(summary)));
         }
      }
    } catch (e) {
      if (context.mounted) Navigator.pop(context);
    }
  }

  Widget _buildContextList(BuildContext context, SessionModel session) {
    return Consumer<ContextService>(
      builder: (context, service, _) {
        final contexts = service.contexts.where((c) => c.sessionId == session.id).toList();
        
        if (contexts.isEmpty) {
           return const SizedBox.shrink();
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Activity Log & Tags', 
              style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            ...contexts.map((ctx) => Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.03),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white.withOpacity(0.05)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(ctx.typeIcon, style: const TextStyle(fontSize: 20)),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(ctx.title.isNotEmpty ? ctx.title : ctx.url,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500)),
                      ),
                      if (ctx.tags.isEmpty)
                        IconButton(
                          icon: const Icon(Icons.auto_awesome, color: Colors.white24, size: 16),
                          tooltip: 'Auto-tag',
                          onPressed: () => service.autoTagContext(ctx.id),
                        ),
                    ],
                  ),
                  if (ctx.tags.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: ctx.tags.map((tag) => Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFF6366F1).withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(tag, style: const TextStyle(color: Color(0xFF818CF8), fontSize: 10)),
                      )).toList(),
                    ),
                  ]
                ],
              ),
            )),
          ],
        );
      },
    );
  }
}

