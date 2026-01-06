import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../services/context_service.dart';
import '../models/context_model.dart';

class ContextHistory extends StatefulWidget {
  const ContextHistory({super.key});

  @override
  State<ContextHistory> createState() => _ContextHistoryState();
}

class _ContextHistoryState extends State<ContextHistory> {
  String _filterType = 'all';

  @override
  void initState() {
    super.initState();
    context.read<ContextService>().fetchContexts(limit: 50);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF0F0F23), Color(0xFF1A1A2E)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(),
              _buildFilters(),
              Expanded(child: _buildContextList()),
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
            onPressed: () => context.pop(),
            icon: const Icon(Icons.arrow_back, color: Colors.white),
          ),
          const SizedBox(width: 16),
          const Text('Context History',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
        ],
      ),
    );
  }

  Widget _buildFilters() {
    final filters = [
      {'value': 'all', 'label': 'All'},
      {'value': 'tab', 'label': 'Tabs'},
      {'value': 'document', 'label': 'Documents'},
      {'value': 'code', 'label': 'Code'},
      {'value': 'video', 'label': 'Video'},
      {'value': 'email', 'label': 'Email'},
      {'value': 'social', 'label': 'Social'},
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        children: filters.map((f) {
          final isSelected = _filterType == f['value'];
          return Padding(
            padding: const EdgeInsets.only(right: 12),
            child: FilterChip(
              selected: isSelected,
              onSelected: (_) => setState(() => _filterType = f['value']!),
              label: Text(f['label']!),
              labelStyle: TextStyle(color: isSelected ? Colors.white : Colors.white70),
              backgroundColor: Colors.white.withOpacity(0.05),
              selectedColor: const Color(0xFF6366F1),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildContextList() {
    return Consumer<ContextService>(
      builder: (context, service, _) {
        final contexts = service.contexts.where((c) => 
          _filterType == 'all' || c.type == _filterType).toList();
        
        if (contexts.isEmpty) {
          return Center(
            child: Text('No contexts found', 
              style: TextStyle(color: Colors.white.withOpacity(0.5))),
          );
        }

        return LayoutBuilder(
          builder: (context, constraints) {
            final crossAxisCount = constraints.maxWidth > 900 ? 3 : (constraints.maxWidth > 600 ? 2 : 1);
            
            if (crossAxisCount > 1) {
              return GridView.builder(
                padding: const EdgeInsets.all(24),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: crossAxisCount,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  mainAxisExtent: 80,
                ),
                itemCount: contexts.length,
                itemBuilder: (_, i) => _buildContextCard(contexts[i], isGrid: true),
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.all(24),
              itemCount: contexts.length,
              itemBuilder: (_, i) => _buildContextCard(contexts[i], isGrid: false),
            );
          }
        );
      },
    );
  }

  Widget _buildContextCard(ContextModel ctx, {required bool isGrid}) {
    return Container(
      margin: EdgeInsets.only(bottom: isGrid ? 0 : 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.03),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Row(
        children: [
          Text(ctx.typeIcon, style: const TextStyle(fontSize: 24)),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  ctx.title, 
                  style: const TextStyle(
                    color: Colors.white, 
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  DateFormat('MMM d, HH:mm').format(ctx.capturedAt),
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.5), 
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          if (ctx.isRecovered)
            const Padding(
              padding: EdgeInsets.only(left: 8.0),
              child: Icon(Icons.check_circle, color: Color(0xFF10B981), size: 18),
            ),
        ],
      ),
    );
  }
}
