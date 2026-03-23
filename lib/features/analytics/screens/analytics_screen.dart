import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../crm/models/lead_model.dart';
import '../../crm/providers/crm_provider.dart';
import '../../dashboard/models/activity_model.dart';
import '../../dashboard/providers/dashboard_provider.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final crm = context.read<CrmProvider>();
      final dashboard = context.read<DashboardProvider>();

      crm.fetchLeads();
      dashboard.fetchMetrics();
      dashboard.fetchUpcomingActivities(limit: 10);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<DashboardProvider, CrmProvider>(
      builder: (context, dashboard, crm, _) {
        final leads = crm.leads;
        final hotDeals = leads.where((l) => l.probability >= 70).length;
        final overdueDeals = leads.where(_isOverdue).length;
        final stageBreakdown = _stageBreakdown(leads);

        return Scaffold(
          backgroundColor: const Color(0xFFF8F9FB),
          body: RefreshIndicator(
            onRefresh: () async {
              await Future.wait([
                crm.fetchLeads(),
                dashboard.fetchMetrics(),
                dashboard.fetchUpcomingActivities(limit: 10),
              ]);
            },
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(0, 0, 0, 120),
              children: [
                _Header(
                  period: dashboard.selectedPeriod,
                  onPeriodChanged: dashboard.setPeriod,
                  openDeals: leads.length,
                  hotDeals: hotDeals,
                  overdueDeals: overdueDeals,
                ),
                const SizedBox(height: 14),
                _animate(
                  delay: 0,
                  child: _MetricGrid(
                  totalRevenue: dashboard.totalRevenue,
                  openDeals: leads.length,
                  hotDeals: hotDeals,
                  overdueDeals: overdueDeals,
                ),
                ),
                const SizedBox(height: 14),
                _animate(
                  delay: 1,
                  child: _StageBreakdownCard(stageBreakdown: stageBreakdown),
                ),
                const SizedBox(height: 14),
                _animate(
                  delay: 2,
                  child: _UpcomingActivitiesCard(
                  isLoading: dashboard.isLoadingActivities,
                  activities: dashboard.upcomingActivities,
                ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  bool _isOverdue(Lead lead) {
    final due = lead.dueDate.trim();
    if (due.isEmpty || due == 'No Date') return false;
    final parsed = DateTime.tryParse(due);
    if (parsed == null) return false;
    return parsed.isBefore(DateTime.now());
  }

  Map<String, int> _stageBreakdown(List<Lead> leads) {
    final map = <String, int>{};
    for (final lead in leads) {
      map.update(lead.stageLabel, (v) => v + 1, ifAbsent: () => 1);
    }
    return map;
  }

  Widget _animate({required int delay, required Widget child}) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: 1),
      duration: Duration(milliseconds: 550 + (delay * 120)),
      curve: Curves.easeOutCubic,
      builder: (context, value, _) => Opacity(
        opacity: value,
        child: Transform.translate(
          offset: Offset(0, 16 * (1 - value)),
          child: child,
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final String period;
  final ValueChanged<String> onPeriodChanged;
  final int openDeals;
  final int hotDeals;
  final int overdueDeals;

  const _Header({
    required this.period,
    required this.onPeriodChanged,
    required this.openDeals,
    required this.hotDeals,
    required this.overdueDeals,
  });

  static const _periodOptions = [
    'Today',
    'This Week',
    'This Month',
    'This Quarter',
    'This Year',
    'All Time',
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 58, 18, 24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF5A3D6A), Color(0xFF6F4B84)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(26),
          bottomRight: Radius.circular(26),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Leader Dashboard',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        letterSpacing: -0.4,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Real-time team performance',
                      style: TextStyle(fontSize: 13, color: Color(0xFFE1D5EA)),
                    ),
                  ],
                ),
              ),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.14),
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  onPressed: () {},
                  icon: const Icon(Icons.insights_outlined, color: Colors.white),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              _stat('Open', '$openDeals'),
              const SizedBox(width: 8),
              _stat('Hot', '$hotDeals'),
              const SizedBox(width: 8),
              _stat('Overdue', '$overdueDeals'),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _periodOptions.contains(period) ? period : 'This Month',
                dropdownColor: const Color(0xFF6B4E80),
                iconEnabledColor: Colors.white,
                style: const TextStyle(color: Colors.white, fontSize: 13),
                items: _periodOptions
                    .map(
                      (p) => DropdownMenuItem<String>(
                        value: p,
                        child: Text(p),
                      ),
                    )
                    .toList(),
                onChanged: (v) {
                  if (v != null) onPeriodChanged(v);
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _stat(String label, String value) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.13),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label.toUpperCase(),
              style: const TextStyle(
                color: Color(0xFFE9DFF0),
                fontSize: 10,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.8,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MetricGrid extends StatelessWidget {
  final double totalRevenue;
  final int openDeals;
  final int hotDeals;
  final int overdueDeals;

  const _MetricGrid({
    required this.totalRevenue,
    required this.openDeals,
    required this.hotDeals,
    required this.overdueDeals,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      crossAxisCount: 2,
      crossAxisSpacing: 10,
      mainAxisSpacing: 10,
      childAspectRatio: 1.3,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: [
        _MetricTile(
          title: 'Revenue',
          value: _money(totalRevenue),
          icon: Icons.paid_outlined,
          color: const Color(0xFF5A3D6A),
          subtitle: 'Expected total',
        ),
        _MetricTile(
          title: 'Open Deals',
          value: '$openDeals',
          icon: Icons.account_tree_outlined,
          color: const Color(0xFF1565C0),
          subtitle: 'Current pipeline',
        ),
        _MetricTile(
          title: 'Hot Deals',
          value: '$hotDeals',
          icon: Icons.local_fire_department_outlined,
          color: const Color(0xFFEF6C00),
          subtitle: 'Probability ≥ 70%',
        ),
        _MetricTile(
          title: 'Overdue',
          value: '$overdueDeals',
          icon: Icons.warning_amber_rounded,
          color: const Color(0xFFC62828),
          subtitle: 'Deadline passed',
        ),
      ],
    );
  }

  String _money(double value) {
    if (value >= 1000000) return '\$${(value / 1000000).toStringAsFixed(1)}M';
    if (value >= 1000) return '\$${(value / 1000).toStringAsFixed(1)}K';
    return '\$${value.toStringAsFixed(0)}';
  }
}

class _MetricTile extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final String subtitle;

  const _MetricTile({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF0EAF4)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: color),
          const Spacer(),
          Text(
            value,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: Color(0xFF1D1B20),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            title,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: Color(0xFF444444),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: const TextStyle(fontSize: 11, color: Color(0xFF8C8C8C)),
          ),
        ],
      ),
    );
  }
}

class _StageBreakdownCard extends StatelessWidget {
  final Map<String, int> stageBreakdown;

  const _StageBreakdownCard({required this.stageBreakdown});

  @override
  Widget build(BuildContext context) {
    final total = stageBreakdown.values.fold<int>(0, (sum, v) => sum + v);
    final entries = stageBreakdown.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Pipeline by Stage',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: Color(0xFF1D1B20),
            ),
          ),
          const SizedBox(height: 16),
          if (entries.isEmpty)
            const Text(
              'No pipeline data yet',
              style: TextStyle(color: Color(0xFF8C8C8C)),
            )
          else
            ...entries.map((entry) {
              final ratio = total == 0 ? 0.0 : entry.value / total;
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            entry.key,
                            style: const TextStyle(
                              fontSize: 13,
                              color: Color(0xFF444444),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        Text(
                          '${entry.value}',
                          style: const TextStyle(
                            fontSize: 13,
                            color: Color(0xFF444444),
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 5),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(999),
                      child: LinearProgressIndicator(
                        minHeight: 8,
                        value: math.max(0.02, ratio),
                        backgroundColor: const Color(0xFFF1ECF5),
                        valueColor: const AlwaysStoppedAnimation<Color>(
                          Color(0xFF5A3D6A),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }
}

class _UpcomingActivitiesCard extends StatelessWidget {
  final bool isLoading;
  final List<CrmActivity> activities;

  const _UpcomingActivitiesCard({
    required this.isLoading,
    required this.activities,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Upcoming Activities',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: Color(0xFF1D1B20),
            ),
          ),
          const SizedBox(height: 12),
          if (isLoading)
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: CircularProgressIndicator(),
              ),
            )
          else if (activities.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Text(
                'No upcoming activities',
                style: TextStyle(color: Color(0xFF8C8C8C)),
              ),
            )
          else
            ...activities.take(6).map((activity) {
              return ListTile(
                contentPadding: EdgeInsets.zero,
                leading: CircleAvatar(
                  backgroundColor: const Color(0xFFF1ECF5),
                  child: const Icon(
                    Icons.event_note_rounded,
                    color: Color(0xFF5A3D6A),
                    size: 18,
                  ),
                ),
                title: Text(
                  activity.summary.isEmpty ? activity.resName : activity.summary,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1D1B20),
                  ),
                ),
                subtitle: Text(
                  '${activity.activityTypeName.isEmpty ? "Activity" : activity.activityTypeName} • ${activity.dateDeadline}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF7D7D7D),
                  ),
                ),
              );
            }),
        ],
      ),
    );
  }
}
