import 'package:flutter/material.dart';
import '../../models/lead_model.dart';
import 'lead_detail_atoms.dart';
import 'lead_detail_tokens.dart';

class LeadNextActivityCard extends StatelessWidget {
  final LeadActivity activity;
  const LeadNextActivityCard({super.key, required this.activity});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: LdToken.card,
        borderRadius: BorderRadius.circular(14),
        border: Border(
          left: BorderSide(color: activity.dueLabelColor, width: 4),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _ActivityHeader(activity: activity),
          const SizedBox(height: 12),
          _ActivityContent(activity: activity),
          const SizedBox(height: 14),
          _ActivityActionButton(activity: activity),
        ],
      ),
    );
  }
}

class _ActivityHeader extends StatelessWidget {
  final LeadActivity activity;
  const _ActivityHeader({required this.activity});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Text(
          'NEXT ACTIVITY',
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            color: LdToken.textLow,
            letterSpacing: 0.7,
          ),
        ),
        const Spacer(),
        LdDueBadge(label: activity.dueLabel, color: activity.dueLabelColor),
      ],
    );
  }
}

class _ActivityContent extends StatelessWidget {
  final LeadActivity activity;
  const _ActivityContent({required this.activity});

  @override
  Widget build(BuildContext context) {
    return Row(
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
              Text(
                activity.title,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: LdToken.textHigh,
                ),
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
              Text(
                '${activity.scheduledTime} • ${activity.duration}',
                style: const TextStyle(fontSize: 12, color: LdToken.textLow),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ActivityActionButton extends StatelessWidget {
  final LeadActivity activity;
  const _ActivityActionButton({required this.activity});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 46,
      child: ElevatedButton.icon(
        onPressed: () {},
        icon: const Icon(Icons.phone_outlined, size: 18),
        label: Text(
          activity.actionLabel,
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: LdToken.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }
}
