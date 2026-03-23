import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/dashboard_provider.dart';
import '../models/activity_model.dart';
import 'package:go_router/go_router.dart';

class UpcomingActivitiesSection extends StatelessWidget {
  const UpcomingActivitiesSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<DashboardProvider>(
      builder: (context, provider, child) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Upcoming',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1D1B20),
                    ),
                  ),
                  if (provider.upcomingActivities.isNotEmpty)
                    TextButton(
                      onPressed: () => context.push('/dashboard/calls'),
                      child: const Text(
                        'View All',
                        style: TextStyle(
                          color: Color(0xFF6750A4),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            if (provider.isLoadingActivities)
              const Center(child: CircularProgressIndicator())
            else if (provider.activitiesError != null)
              Center(
                child: Text(
                  'Error loading activities',
                  style: const TextStyle(color: Colors.red),
                ),
              )
            else if (provider.upcomingActivities.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 20),
                child: Center(
                  child: Text(
                    'No upcoming activities',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
              )
            else
              ...provider.upcomingActivities.map(
                (activity) => _buildActivityCard(context, activity),
              ),
          ],
        );
      },
    );
  }

  Widget _buildActivityCard(BuildContext context, CrmActivity activity) {
    // Parse date
    DateTime? deadline;
    try {
      if (activity.dateDeadline.isNotEmpty) {
        deadline = DateTime.parse(activity.dateDeadline);
      }
    } catch (e) {
      // ignore
    }

    final month = deadline != null
        ? DateFormat('MMM').format(deadline).toUpperCase()
        : 'N/A';
    final day = deadline != null ? DateFormat('dd').format(deadline) : '--';

    // Time format, since dateDeadline is usually just a yyyy-mm-dd in Odoo mail.activity,
    // we use 'Due Date' as time.
    final timeStr = deadline != null
        ? DateFormat('MMM dd, yyyy').format(deadline)
        : '';

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFF0F0F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                children: [
                  Text(
                    month,
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF9E9E9E),
                    ),
                  ),
                  Text(
                    day,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF1D1B20),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            activity.resName,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF1D1B20),
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: activity.tagColor,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            activity.tagLabel,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: activity.tagTextColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (activity.summary.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        activity.summary,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF424242),
                        ),
                      ),
                    ],
                    const SizedBox(height: 4),
                    Text(
                      timeStr,
                      style: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFF757575),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(activity.icon, color: const Color(0xFF9E9E9E), size: 20),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 44,
            child: ElevatedButton(
              onPressed: () {
                // Navigate to lead details
                if (activity.resModel == 'crm.lead') {
                  context.push('/leads/${activity.resId}');
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF5a3d6a),
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'View Deal',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
