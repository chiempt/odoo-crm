import 'package:flutter/material.dart';
import '../../models/lead_model.dart';
import 'lead_detail_atoms.dart';
import 'lead_detail_tokens.dart';

class LeadScheduledCard extends StatelessWidget {
  final List<ScheduledActivity> activities;
  const LeadScheduledCard({super.key, required this.activities});

  @override
  Widget build(BuildContext context) {
    return LdCardShell(
      label: 'SCHEDULED ACTIVITIES',
      labelTrailing: Text(
        '${activities.length} upcoming',
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: LdToken.primary,
        ),
      ),
      child: Column(
        children: activities.asMap().entries.map((e) {
          return _ScheduledRow(
            activity: e.value,
            isLast: e.key == activities.length - 1,
          );
        }).toList(),
      ),
    );
  }
}

class _ScheduledRow extends StatelessWidget {
  final ScheduledActivity activity;
  final bool isLast;

  const _ScheduledRow({required this.activity, required this.isLast});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: activity.iconBgColor,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(activity.icon, size: 20, color: LdToken.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        activity.title,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: LdToken.textHigh,
                        ),
                      ),
                    ),
                    _PriorityBadge(
                      label: activity.priority,
                      color: activity.priorityColor,
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  activity.description,
                  style: const TextStyle(
                    fontSize: 13,
                    color: LdToken.textMed,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(
                      Icons.calendar_today_outlined,
                      size: 12,
                      color: LdToken.textLow,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      activity.date,
                      style: const TextStyle(
                        fontSize: 12,
                        color: LdToken.textLow,
                      ),
                    ),
                    const SizedBox(width: 10),
                    const Icon(
                      Icons.schedule_rounded,
                      size: 12,
                      color: LdToken.textLow,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      activity.duration,
                      style: const TextStyle(
                        fontSize: 12,
                        color: LdToken.textLow,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PriorityBadge extends StatelessWidget {
  final String label;
  final Color color;

  const _PriorityBadge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }
}
