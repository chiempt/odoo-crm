import 'package:flutter/material.dart';
import '../../models/lead_model.dart';
import 'lead_detail_atoms.dart';
import 'lead_detail_tokens.dart';

class LeadTimelineCard extends StatelessWidget {
  final List<LeadTimelineEntry> entries;
  const LeadTimelineCard({super.key, required this.entries});

  @override
  Widget build(BuildContext context) {
    return LdCardShell(
      label: 'ACTIVITY TIMELINE',
      child: Column(
        children: entries.asMap().entries.map((e) {
          return _TimelineRow(
            entry: e.value,
            isLast: e.key == entries.length - 1,
          );
        }).toList(),
      ),
    );
  }
}

class _TimelineRow extends StatelessWidget {
  final LeadTimelineEntry entry;
  final bool isLast;

  const _TimelineRow({required this.entry, required this.isLast});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 14,
              height: 14,
              decoration: BoxDecoration(
                color: entry.dotColor,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
              ),
            ),
            if (!isLast)
              Container(width: 2, height: 32, color: LdToken.divider),
          ],
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Padding(
            padding: EdgeInsets.only(bottom: isLast ? 0 : 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.description,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: LdToken.textHigh,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${entry.timeAgo} • ${entry.author}',
                  style: const TextStyle(
                    fontSize: 11,
                    color: LdToken.textLow,
                    letterSpacing: 0.2,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
