import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../authentication/providers/auth_provider.dart';
import '../widgets/profile_header.dart';
import '../widgets/profile_widgets.dart';
import '../providers/profile_provider.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  static const _prefsPrefix = 'crm.settings.';

  Future<Map<String, String>> _loadCrmSettingSummary() async {
    final prefs = await SharedPreferences.getInstance();
    final notificationsEnabled =
        (prefs.getBool('${_prefsPrefix}email_notifications') ?? true) ||
        (prefs.getBool('${_prefsPrefix}push_notifications') ?? true);
    final syncEnabled = prefs.getBool('${_prefsPrefix}real_time_sync') ?? true;
    final syncInterval =
        prefs.getString('${_prefsPrefix}sync_interval') ?? '30s';
    final pipelineView =
        prefs.getString('${_prefsPrefix}pipeline_view') ?? 'Kanban';

    return {
      'notifications': notificationsEnabled
          ? 'All activities & mentions'
          : 'Disabled',
      'sync': syncEnabled ? 'Enabled (every $syncInterval)' : 'Disabled',
      'pipelineView': '$pipelineView (Default)',
    };
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final profileProvider = context.watch<ProfileProvider>();

    // Construct avatar URL same way as in DashboardHeader
    final String? avatarUrl =
        authProvider.uid != null && authProvider.serverUrl != null
        ? '${authProvider.serverUrl}/web/image?model=res.users&id=${authProvider.uid}&field=avatar_128'
        : null;

    final String userName = authProvider.name ?? 'Guest User';
    final String userEmail = authProvider.username ?? 'No Email';

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FB),
      body: profileProvider.isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF5a3d6a)),
            )
          : SingleChildScrollView(
              child: Column(
                children: [
                  ProfileHeader(
                    userName: userName,
                    jobTitle: 'Odoo User',
                    company: authProvider.database ?? 'Unknown DB',
                    avatarUrl: avatarUrl,
                    authHeaders: authProvider.token != null
                        ? {'Cookie': 'session_id=${authProvider.token}'}
                        : null,
                  ),
                  const SizedBox(height: 24),

                  _animateWidget(
                    delay: 0,
                    child: ProfileStatRow(
                      dealsWon: profileProvider.dealsWon,
                      activeLeads: profileProvider.activeLeads,
                    ),
                  ),

                  const SizedBox(height: 16),

                  _animateWidget(
                    delay: 1,
                    child: ProfileMenuCard(
                      title: 'Work Information',
                      items: [
                        ProfileMenuItem(
                          icon: Icons.mail_outline_rounded,
                          label: 'Email / Username',
                          subtitle: userEmail,
                          iconColor: const Color(0xFF5a3d6a),
                          onTap: () {},
                        ),
                        ProfileMenuItem(
                          icon: Icons.phone_outlined,
                          label: 'Phone',
                          subtitle: profileProvider.phone.isEmpty
                              ? 'Not set'
                              : profileProvider.phone,
                          iconColor: const Color(0xFF5a3d6a),
                          onTap: () {},
                        ),
                        ProfileMenuItem(
                          icon: Icons.location_on_outlined,
                          label: 'Office / Location',
                          subtitle: profileProvider.tz.isNotEmpty
                              ? profileProvider.tz
                              : 'Not set',
                          iconColor: const Color(0xFF5a3d6a),
                          onTap: () {},
                        ),
                      ],
                    ),
                  ),

                  _animateWidget(
                    delay: 2,
                    child: FutureBuilder<Map<String, String>>(
                      future: _loadCrmSettingSummary(),
                      builder: (context, snapshot) {
                        final summary =
                            snapshot.data ??
                            const {
                              'notifications': 'All activities & mentions',
                              'sync': 'Enabled (every 30s)',
                              'pipelineView': 'Kanban (Default)',
                            };
                        return ProfileMenuCard(
                          title: 'CRM Settings',
                          items: [
                            ProfileMenuItem(
                              icon: Icons.notifications_none_rounded,
                              label: 'Notifications',
                              subtitle: summary['notifications'] ?? 'Disabled',
                              iconColor: Colors.blue,
                              onTap: () => context.go('/pipeline?tab=settings'),
                            ),
                            ProfileMenuItem(
                              icon: Icons.sync_rounded,
                              label: 'Real-time Sync',
                              subtitle: summary['sync'] ?? 'Disabled',
                              iconColor: Colors.green,
                              onTap: () => context.go('/pipeline?tab=settings'),
                            ),
                            ProfileMenuItem(
                              icon: Icons.filter_list_rounded,
                              label: 'Pipeline View',
                              subtitle:
                                  summary['pipelineView'] ?? 'Kanban (Default)',
                              iconColor: Colors.orange,
                              onTap: () => context.go('/pipeline?tab=settings'),
                            ),
                          ],
                        );
                      },
                    ),
                  ),

                  _animateWidget(
                    delay: 3,
                    child: ProfileMenuCard(
                      title: 'System & Support',
                      items: [
                        ProfileMenuItem(
                          icon: Icons.language_rounded,
                          label: 'Language',
                          subtitle: profileProvider.lang,
                          iconColor: Colors.teal,
                          onTap: () {},
                        ),
                        ProfileMenuItem(
                          icon: Icons.help_outline_rounded,
                          label: 'Help Center',
                          iconColor: Colors.indigo,
                          onTap: () {},
                        ),
                        ProfileMenuItem(
                          icon: Icons.info_outline_rounded,
                          label: 'App Version',
                          subtitle: 'v2.4.0 (Stable)',
                          iconColor: Colors.grey,
                          onTap: () {},
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  _animateWidget(
                    delay: 4,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton.icon(
                          onPressed: () => authProvider.logout(),
                          icon: const Icon(Icons.logout_rounded, size: 20),
                          label: const Text(
                            'Logout',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: Colors.red,
                            elevation: 0,
                            side: BorderSide(
                              color: Colors.red.withValues(alpha: 0.1),
                              width: 1.5,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 120), // Padding for Floating Dock
                ],
              ),
            ),
    );
  }

  Widget _animateWidget({required Widget child, required int delay}) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 600 + (delay * 100)),
      curve: Curves.easeOutQuint,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, 30 * (1 - value)),
            child: child,
          ),
        );
      },
      child: child,
    );
  }
}
