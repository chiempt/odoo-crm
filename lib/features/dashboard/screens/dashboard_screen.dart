import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../authentication/providers/auth_provider.dart';
import '../providers/dashboard_provider.dart';
import 'package:intl/intl.dart';
import '../widgets/home_header.dart';
import '../widgets/quick_actions_grid.dart';
import '../widgets/featured_campaign_card.dart';

import '../widgets/upcoming_activities_section.dart';
import '../widgets/performance_card.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final dashboardProvider = context.watch<DashboardProvider>();
    final textTheme = Theme.of(context).textTheme;

    final formatCurrency = NumberFormat.compactCurrency(
      symbol: '\$',
      decimalDigits: 1,
    );
    final revenue = formatCurrency.format(dashboardProvider.totalRevenue);
    final leads = dashboardProvider.newLeadsCount.toString();

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FB),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _animateWidget(
              delay: 0,
              child: HomeHeader(
                userName: authProvider.name ?? 'Guest',
                userUid: authProvider.uid,
                profileImageUrl:
                    authProvider.uid != null && authProvider.serverUrl != null
                    ? '${authProvider.serverUrl}/web/image?model=res.users&id=${authProvider.uid}&field=avatar_128'
                    : null,
                authHeaders: authProvider.token != null
                    ? {'Cookie': 'session_id=${authProvider.token}'}
                    : null,
                onLogout: () => authProvider.logout(),
              ),
            ),

            const SizedBox(height: 24),

            _animateWidget(delay: 1, child: const QuickActionsGrid()),

            const SizedBox(height: 24),

            _animateWidget(delay: 2, child: const FeaturedCampaignCard()),

            const SizedBox(height: 24),

            _animateWidget(delay: 3, child: const UpcomingActivitiesSection()),

            const SizedBox(height: 24),

            _animateWidget(
              delay: 4,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: _buildPerformanceHeader(
                  context,
                  textTheme,
                  dashboardProvider,
                ),
              ),
            ),

            const SizedBox(height: 12),

            _animateWidget(
              delay: 5,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    Expanded(
                      child: PerformanceCard(
                        label: 'TOTAL REVENUE',
                        value: revenue,
                        trend:
                            'Open Leads', // Just a label update since we're tracking open expected revenue
                        icon: Icons.attach_money,
                        iconBg: const Color(0xFFF3E8FF),
                        iconCol: const Color(0xFF6750A4),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: PerformanceCard(
                        label: 'OPEN LEADS',
                        value: leads,
                        trend: 'Active',
                        icon: Icons.person_add_alt_1_outlined,
                        iconBg: const Color(0xFFE0F2FE),
                        iconCol: const Color(0xFF0284C7),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 120), // Padding for the floating dock
          ],
        ),
      ),
    );
  }

  Widget _buildPerformanceHeader(
    BuildContext context,
    TextTheme textTheme,
    DashboardProvider dashboardProvider,
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'Performance',
          style: textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: const Color(0xFF1D1B20),
          ),
        ),
        PopupMenuButton<String>(
          initialValue: dashboardProvider.selectedPeriod,
          onSelected: (String period) {
            dashboardProvider.setPeriod(period);
          },
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                dashboardProvider.selectedPeriod,
                style: const TextStyle(
                  color: Color(0xFF79747E),
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Icon(Icons.expand_more, size: 20, color: Color(0xFF79747E)),
            ],
          ),
          itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
            const PopupMenuItem<String>(value: 'Today', child: Text('Today')),
            const PopupMenuItem<String>(
              value: 'This Week',
              child: Text('This Week'),
            ),
            const PopupMenuItem<String>(
              value: 'This Month',
              child: Text('This Month'),
            ),
            const PopupMenuItem<String>(
              value: 'This Quarter',
              child: Text('This Quarter'),
            ),
            const PopupMenuItem<String>(
              value: 'This Year',
              child: Text('This Year'),
            ),
            const PopupMenuItem<String>(
              value: 'All Time',
              child: Text('All Time'),
            ),
          ],
        ),
      ],
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
