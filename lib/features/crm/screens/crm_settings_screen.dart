import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import '../providers/crm_provider.dart';
import '../../dashboard/providers/dashboard_provider.dart';

const Color _primaryColor = Color(0xFF5a3d6a);
const _prefsPrefix = 'crm.settings.';

class CrmSettingsScreen extends StatefulWidget {
  const CrmSettingsScreen({super.key});

  @override
  State<CrmSettingsScreen> createState() => _CrmSettingsScreenState();
}

class _CrmSettingsScreenState extends State<CrmSettingsScreen> {
  bool _emailNotifications = true;
  bool _pushNotifications = true;
  bool _realTimeSync = true;
  bool _leadAssignment = false;
  bool _dealUpdates = true;
  String _currency = 'USD';
  String _dateFormat = 'MM/DD/YYYY';
  String _syncInterval = '30s';
  String _pipelineView = 'Kanban';

  @override
  void initState() {
    super.initState();
    _loadSettings();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<CrmProvider>().fetchStages();
    });
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _emailNotifications =
          prefs.getBool('${_prefsPrefix}email_notifications') ?? true;
      _pushNotifications =
          prefs.getBool('${_prefsPrefix}push_notifications') ?? true;
      _realTimeSync = prefs.getBool('${_prefsPrefix}real_time_sync') ?? true;
      _leadAssignment =
          prefs.getBool('${_prefsPrefix}lead_assignment') ?? false;
      _dealUpdates = prefs.getBool('${_prefsPrefix}deal_updates') ?? true;
      _currency = prefs.getString('${_prefsPrefix}currency') ?? 'USD';
      _dateFormat =
          prefs.getString('${_prefsPrefix}date_format') ?? 'MM/DD/YYYY';
      _syncInterval = prefs.getString('${_prefsPrefix}sync_interval') ?? '30s';
      _pipelineView =
          prefs.getString('${_prefsPrefix}pipeline_view') ?? 'Kanban';
    });
  }

  Future<void> _saveBool(String key, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('$_prefsPrefix$key', value);
  }

  Future<void> _saveString(String key, String value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('$_prefsPrefix$key', value);
  }

  Future<void> _exportCrmData() async {
    final crm = context.read<CrmProvider>();
    final dashboard = context.read<DashboardProvider>();

    final payload = {
      'generatedAt': DateTime.now().toIso8601String(),
      'settings': {
        'emailNotifications': _emailNotifications,
        'pushNotifications': _pushNotifications,
        'realTimeSync': _realTimeSync,
        'leadAssignment': _leadAssignment,
        'dealUpdates': _dealUpdates,
        'currency': _currency,
        'dateFormat': _dateFormat,
        'syncInterval': _syncInterval,
        'pipelineView': _pipelineView,
      },
      'analyticsSnapshot': {
        'leadCount': crm.leads.length,
        'totalRevenue': dashboard.totalRevenue,
        'openLeadCount': dashboard.newLeadsCount,
        'period': dashboard.selectedPeriod,
      },
    };

    await Clipboard.setData(
      ClipboardData(text: const JsonEncoder.withIndent('  ').convert(payload)),
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('CRM data snapshot copied to clipboard')),
    );
  }

  Future<void> _clearLocalCache() async {
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs
        .getKeys()
        .where((k) => k.startsWith(_prefsPrefix))
        .toList();
    for (final k in keys) {
      await prefs.remove(k);
    }
    await _loadSettings();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Local CRM settings cache cleared')),
    );
  }

  Future<void> _openPrivacyPolicy() async {
    final uri = Uri.parse('https://www.odoo.com/privacy');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
      return;
    }
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Unable to open privacy policy')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FB),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.only(bottom: 100),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              const SizedBox(height: 8),
              _buildSection(
                title: 'Notifications',
                icon: Icons.notifications_outlined,
                children: [
                  _ToggleTile(
                    label: 'Email Notifications',
                    subtitle: 'Receive updates via email',
                    value: _emailNotifications,
                    onChanged: (v) async {
                      setState(() => _emailNotifications = v);
                      await _saveBool('email_notifications', v);
                    },
                  ),
                  _ToggleTile(
                    label: 'Push Notifications',
                    subtitle: 'In-app push alerts',
                    value: _pushNotifications,
                    onChanged: (v) async {
                      setState(() => _pushNotifications = v);
                      await _saveBool('push_notifications', v);
                    },
                  ),
                  _ToggleTile(
                    label: 'Real-time Sync',
                    subtitle: 'Sync CRM data in the background',
                    value: _realTimeSync,
                    onChanged: (v) async {
                      setState(() => _realTimeSync = v);
                      await _saveBool('real_time_sync', v);
                    },
                  ),
                  _ToggleTile(
                    label: 'Lead Assignment',
                    subtitle: 'Notify on new lead assigned',
                    value: _leadAssignment,
                    onChanged: (v) async {
                      setState(() => _leadAssignment = v);
                      await _saveBool('lead_assignment', v);
                    },
                  ),
                  _ToggleTile(
                    label: 'Deal Updates',
                    subtitle: 'Track deal stage changes',
                    value: _dealUpdates,
                    onChanged: (v) async {
                      setState(() => _dealUpdates = v);
                      await _saveBool('deal_updates', v);
                    },
                  ),
                ],
              ),
              _buildSection(
                title: 'Display Preferences',
                icon: Icons.tune_rounded,
                children: [
                  _DropdownTile(
                    label: 'Pipeline View',
                    value: _pipelineView,
                    items: const ['Kanban', 'List'],
                    onChanged: (v) async {
                      if (v == null) return;
                      setState(() => _pipelineView = v);
                      await _saveString('pipeline_view', v);
                    },
                  ),
                  _DropdownTile(
                    label: 'Currency',
                    value: _currency,
                    items: const ['USD', 'EUR', 'GBP', 'VND', 'JPY'],
                    onChanged: (v) async {
                      if (v == null) return;
                      setState(() => _currency = v);
                      await _saveString('currency', v);
                    },
                  ),
                  _DropdownTile(
                    label: 'Date Format',
                    value: _dateFormat,
                    items: const ['MM/DD/YYYY', 'DD/MM/YYYY', 'YYYY-MM-DD'],
                    onChanged: (v) async {
                      if (v == null) return;
                      setState(() => _dateFormat = v);
                      await _saveString('date_format', v);
                    },
                  ),
                  _DropdownTile(
                    label: 'Sync Interval',
                    value: _syncInterval,
                    items: const ['15s', '30s', '1m', '5m'],
                    onChanged: (v) async {
                      if (v == null) return;
                      setState(() => _syncInterval = v);
                      await _saveString('sync_interval', v);
                    },
                  ),
                ],
              ),
              _buildSection(
                title: 'Pipeline Stages',
                icon: Icons.account_tree_outlined,
                children: [
                  Consumer<CrmProvider>(
                    builder: (context, crm, _) {
                      if (crm.stages.isEmpty) {
                        return const Padding(
                          padding: EdgeInsets.all(16),
                          child: Text(
                            'No stages loaded',
                            style: TextStyle(color: Color(0xFF9E9E9E)),
                          ),
                        );
                      }

                      final palette = <Color>[
                        const Color(0xFF9E9E9E),
                        const Color(0xFF2196F3),
                        const Color(0xFFF57C00),
                        const Color(0xFFE53935),
                        const Color(0xFF4CAF50),
                      ];

                      return Column(
                        children: crm.stages.asMap().entries.map((entry) {
                          final color = palette[entry.key % palette.length];
                          return _StageTile(
                            label: entry.value.name,
                            color: color,
                          );
                        }).toList(),
                      );
                    },
                  ),
                ],
              ),
              _buildSection(
                title: 'Data & Privacy',
                icon: Icons.lock_outline_rounded,
                children: [
                  _ActionTile(
                    label: 'Export CRM Data',
                    icon: Icons.download_rounded,
                    onTap: _exportCrmData,
                  ),
                  _ActionTile(
                    label: 'Clear Local Cache',
                    icon: Icons.delete_sweep_outlined,
                    onTap: _clearLocalCache,
                  ),
                  _ActionTile(
                    label: 'Privacy Policy',
                    icon: Icons.privacy_tip_outlined,
                    onTap: _openPrivacyPolicy,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return const Padding(
      padding: EdgeInsets.fromLTRB(20, 16, 16, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Settings',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1D1B20),
            ),
          ),
          SizedBox(height: 2),
          Text(
            'Customize your CRM experience',
            style: TextStyle(fontSize: 13, color: Color(0xFF79747E)),
          ),
        ],
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: _primaryColor),
              const SizedBox(width: 6),
              Text(
                title.toUpperCase(),
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF5a3d6a),
                  letterSpacing: 0.8,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(children: children),
          ),
          const SizedBox(height: 4),
        ],
      ),
    );
  }
}

class _ToggleTile extends StatelessWidget {
  final String label;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _ToggleTile({
    required this.label,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SwitchListTile.adaptive(
      title: Text(
        label,
        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(fontSize: 12, color: Color(0xFF9E9E9E)),
      ),
      value: value,
      onChanged: onChanged,
      activeThumbColor: const Color(0xFF5a3d6a),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
    );
  }
}

class _DropdownTile extends StatelessWidget {
  final String label;
  final String value;
  final List<String> items;
  final ValueChanged<String?> onChanged;

  const _DropdownTile({
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          ),
          const Spacer(),
          DropdownButton<String>(
            value: value,
            items: items
                .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                .toList(),
            onChanged: onChanged,
            underline: const SizedBox.shrink(),
            style: const TextStyle(
              fontSize: 13,
              color: Color(0xFF5a3d6a),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _StageTile extends StatelessWidget {
  final String label;
  final Color color;
  const _StageTile({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      dense: true,
      leading: Container(
        width: 12,
        height: 12,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      ),
      title: Text(
        label,
        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
      ),
      trailing: const Icon(
        Icons.drag_handle_rounded,
        color: Color(0xFFCCCCCC),
        size: 20,
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
    );
  }
}

class _ActionTile extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  const _ActionTile({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      leading: Icon(icon, color: const Color(0xFF5a3d6a), size: 20),
      title: Text(
        label,
        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
      ),
      trailing: const Icon(
        Icons.chevron_right_rounded,
        color: Color(0xFFCCCCCC),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
    );
  }
}
