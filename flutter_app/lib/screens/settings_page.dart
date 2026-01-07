import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:convert';
import 'dart:html' as html;
import '../services/auth_service.dart';
import '../services/context_service.dart';
import '../services/theme_service.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  double _aiSensitivity = 5;
  String _privacyLevel = 'balanced';
  bool _backupEnabled = true;
  bool _syncEnabled = true;
  bool _notificationsEnabled = true;
  bool _isExporting = false;
  // ignore: unused_field
  bool _isClearing = false;

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
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildAppBar(),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildAISection(),
                      const SizedBox(height: 24),
                      _buildPrivacySection(),
                      const SizedBox(height: 24),
                      _buildSyncSection(),
                      const SizedBox(height: 24),
                      _buildAppearanceSection(),
                      const SizedBox(height: 24),
                      _buildAccountSection(),
                      const SizedBox(height: 24),
                      _buildDangerZone(),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar() {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Row(
        children: [
          IconButton(
            onPressed: () => context.pop(),
            icon: const Icon(Icons.arrow_back, color: Colors.white),
          ),
          const SizedBox(width: 16),
          const Text(
            'Settings',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required Color color,
    required List<Widget> children,
  }) {
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
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          ...children,
        ],
      ),
    ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.1);
  }

  Widget _buildAISection() {
    return _buildSectionCard(
      title: 'AI Detection',
      icon: Icons.psychology,
      color: const Color(0xFF6366F1),
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'AI Sensitivity',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 4),
                Text(
                  _getSensitivityDescription(),
                  style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 12),
                ),
              ],
            ),
            Text(
              _aiSensitivity.round().toString(),
              style: const TextStyle(
                color: Color(0xFF6366F1),
                fontWeight: FontWeight.bold,
                fontSize: 24,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SliderTheme(
          data: SliderThemeData(
            activeTrackColor: const Color(0xFF6366F1),
            inactiveTrackColor: Colors.white.withOpacity(0.1),
            thumbColor: const Color(0xFF6366F1),
            overlayColor: const Color(0xFF6366F1).withOpacity(0.2),
          ),
          child: Slider(
            value: _aiSensitivity,
            min: 1,
            max: 10,
            divisions: 9,
            onChanged: (value) => setState(() => _aiSensitivity = value),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Low', style: TextStyle(color: Colors.white.withOpacity(0.3))),
            Text('High', style: TextStyle(color: Colors.white.withOpacity(0.3))),
          ],
        ),
      ],
    );
  }

  String _getSensitivityDescription() {
    if (_aiSensitivity <= 3) {
      return 'Only detect major context switches';
    } else if (_aiSensitivity <= 7) {
      return 'Balanced detection for most users';
    } else {
      return 'Detect subtle context changes';
    }
  }

  Widget _buildPrivacySection() {
    return _buildSectionCard(
      title: 'Privacy & Security',
      icon: Icons.shield_outlined,
      color: const Color(0xFF10B981),
      children: [
        _buildDropdownSetting(
          title: 'Privacy Level',
          subtitle: 'Control how much data is captured',
          value: _privacyLevel,
          items: const [
            {'value': 'minimal', 'label': 'Minimal - Basic tracking only'},
            {'value': 'balanced', 'label': 'Balanced - Recommended'},
            {'value': 'full', 'label': 'Full - Detailed context capture'},
          ],
          onChanged: (value) => setState(() => _privacyLevel = value!),
        ),
        const SizedBox(height: 20),
        _buildSwitchSetting(
          title: 'End-to-End Encryption',
          subtitle: 'Encrypt all stored data locally',
          value: true,
          onChanged: null,
          enabled: false,
        ),
        const SizedBox(height: 20),
        _isExporting
            ? const Center(child: CircularProgressIndicator())
            : OutlinedButton.icon(
                onPressed: _exportUserData,
                icon: const Icon(Icons.download_outlined),
                label: const Text('Export My Data'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white70,
                  side: BorderSide(color: Colors.white.withOpacity(0.2)),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                ),
              ),
      ],
    );
  }

  Widget _buildSyncSection() {
    return _buildSectionCard(
      title: 'Backup & Sync',
      icon: Icons.cloud_outlined,
      color: const Color(0xFF22D3EE),
      children: [
        _buildSwitchSetting(
          title: 'Cloud Backup',
          subtitle: 'Automatically backup your data',
          value: _backupEnabled,
          onChanged: (value) => setState(() => _backupEnabled = value),
        ),
        const SizedBox(height: 16),
        _buildSwitchSetting(
          title: 'Cross-Device Sync',
          subtitle: 'Sync contexts across all devices',
          value: _syncEnabled,
          onChanged: (value) => setState(() => _syncEnabled = value),
        ),
      ],
    );
  }

  Widget _buildAppearanceSection() {
    final themeService = context.watch<ThemeService>();
    
    return _buildSectionCard(
      title: 'Appearance',
      icon: Icons.palette_outlined,
      color: const Color(0xFFF59E0B),
      children: [
        _buildSwitchSetting(
          title: 'Dark Mode',
          subtitle: 'Use dark theme interface',
          value: themeService.isDarkMode,
          onChanged: (value) => themeService.setDarkMode(value),
        ),
        const SizedBox(height: 16),
        _buildSwitchSetting(
          title: 'Notifications',
          subtitle: 'Show recovery prompts',
          value: _notificationsEnabled,
          onChanged: (value) => setState(() => _notificationsEnabled = value),
        ),
      ],
    );
  }

  Widget _buildAccountSection() {
    return Consumer<AuthService>(
      builder: (context, authService, child) {
        return _buildSectionCard(
          title: 'Account',
          icon: Icons.person_outline,
          color: const Color(0xFF8B5CF6),
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: const Color(0xFF6366F1),
                  child: Text(
                    (authService.user?.displayName ?? 'U')[0].toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 24,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        authService.user?.displayName ?? 'User',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        authService.user?.email ?? '',
                        style: TextStyle(color: Colors.white.withOpacity(0.6)),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () {},
                  icon: Icon(Icons.edit_outlined, color: Colors.white.withOpacity(0.5)),
                ),
              ],
            ),
            const SizedBox(height: 20),
            OutlinedButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.key_outlined),
              label: const Text('Change Password'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.white70,
                side: BorderSide(color: Colors.white.withOpacity(0.2)),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildDangerZone() {
    return _buildSectionCard(
      title: 'Danger Zone',
      icon: Icons.warning_outlined,
      color: Colors.red,
      children: [
        OutlinedButton.icon(
          onPressed: () => _showClearDataDialog(),
          icon: const Icon(Icons.delete_outline),
          label: const Text('Clear All Data'),
          style: OutlinedButton.styleFrom(
            foregroundColor: Colors.red,
            side: const BorderSide(color: Colors.red),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          ),
        ),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: () => _showDeleteAccountDialog(),
          icon: const Icon(Icons.person_remove_outlined),
          label: const Text('Delete Account'),
          style: OutlinedButton.styleFrom(
            foregroundColor: Colors.red,
            side: const BorderSide(color: Colors.red),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          ),
        ),
      ],
    );
  }

  Widget _buildSwitchSetting({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool>? onChanged,
    bool enabled = true,
  }) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  color: enabled ? Colors.white : Colors.white54,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: TextStyle(
                  color: Colors.white.withOpacity(enabled ? 0.5 : 0.3),
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
        Switch(
          value: value,
          onChanged: enabled ? onChanged : null,
          activeColor: const Color(0xFF6366F1),
        ),
      ],
    );
  }

  Widget _buildDropdownSetting({
    required String title,
    required String subtitle,
    required String value,
    required List<Map<String, String>> items,
    required ValueChanged<String?> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 12),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white.withOpacity(0.1)),
          ),
          child: DropdownButton<String>(
            value: value,
            onChanged: onChanged,
            isExpanded: true,
            dropdownColor: const Color(0xFF1A1A2E),
            underline: const SizedBox(),
            icon: Icon(Icons.keyboard_arrow_down, color: Colors.white.withOpacity(0.5)),
            items: items.map((item) {
              return DropdownMenuItem(
                value: item['value'],
                child: Text(
                  item['label']!,
                  style: const TextStyle(color: Colors.white),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  void _showClearDataDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Clear All Data?', style: TextStyle(color: Colors.white)),
        content: Text(
          'This will permanently delete all your sessions, contexts, and activity logs. This action cannot be undone.',
          style: TextStyle(color: Colors.white.withOpacity(0.7)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _clearAllData();
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Clear All'),
          ),
        ],
      ),
    );
  }

  void _showDeleteAccountDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete Account?', style: TextStyle(color: Colors.white)),
        content: Text(
          'This will permanently delete your account and all associated data. This action cannot be undone.',
          style: TextStyle(color: Colors.white.withOpacity(0.7)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteAccount();
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete Account'),
          ),
        ],
      ),
    );
  }

  // ========================================
  // FUNCTIONAL IMPLEMENTATIONS
  // ========================================

  Future<void> _exportUserData() async {
    setState(() => _isExporting = true);

    try {
      final authService = context.read<AuthService>();
      final userId = authService.user?.uid;
      if (userId == null) return;

      final firestore = FirebaseFirestore.instance;

      // Fetch all user data
      final sessionsSnap = await firestore
          .collection('sessions')
          .where('userId', isEqualTo: userId)
          .get();

      final contextsSnap = await firestore
          .collection('contexts')
          .where('userId', isEqualTo: userId)
          .get();

      final exportData = {
        'exportDate': DateTime.now().toIso8601String(),
        'userEmail': authService.user?.email,
        'sessions': sessionsSnap.docs.map((d) => d.data()).toList(),
        'contexts': contextsSnap.docs.map((d) => d.data()).toList(),
        'settings': {
          'aiSensitivity': _aiSensitivity,
          'privacyLevel': _privacyLevel,
          'backupEnabled': _backupEnabled,
          'syncEnabled': _syncEnabled,
          'notificationsEnabled': _notificationsEnabled,
          'darkMode': context.read<ThemeService>().isDarkMode,
        },
      };

      // Create download
      final jsonStr = const JsonEncoder.withIndent('  ').convert(exportData);
      final bytes = utf8.encode(jsonStr);
      final blob = html.Blob([bytes], 'application/json');
      final url = html.Url.createObjectUrlFromBlob(blob);
      html.AnchorElement(href: url)
        ..setAttribute('download', 'reset_ai_export_${DateTime.now().millisecondsSinceEpoch}.json')
        ..click();
      html.Url.revokeObjectUrl(url);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Data exported successfully!'),
            backgroundColor: Color(0xFF10B981),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Export failed: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }

  Future<void> _clearAllData() async {
    setState(() => _isClearing = true);

    try {
      final authService = context.read<AuthService>();
      final userId = authService.user?.uid;
      if (userId == null) return;

      final firestore = FirebaseFirestore.instance;
      final batch = firestore.batch();

      // Delete sessions
      final sessionsSnap = await firestore
          .collection('sessions')
          .where('userId', isEqualTo: userId)
          .get();
      for (var doc in sessionsSnap.docs) {
        batch.delete(doc.reference);
      }

      // Delete contexts
      final contextsSnap = await firestore
          .collection('contexts')
          .where('userId', isEqualTo: userId)
          .get();
      for (var doc in contextsSnap.docs) {
        batch.delete(doc.reference);
      }

      await batch.commit();

      // Refresh local data
      if (mounted) {
        context.read<ContextService>().fetchContexts();
        context.read<ContextService>().fetchSessions();
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('All data cleared successfully'),
            backgroundColor: Color(0xFF10B981),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to clear data: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isClearing = false);
    }
  }

  Future<void> _deleteAccount() async {
    try {
      final authService = context.read<AuthService>();
      
      // Clear all data first
      await _clearAllData();
      
      // Delete user profile
      final userId = authService.user?.uid;
      if (userId != null) {
        await FirebaseFirestore.instance.collection('users').doc(userId).delete();
      }
      
      // Sign out and redirect
      await authService.signOut();
      
      if (mounted) {
        context.go('/login');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to delete account: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }
}
