import 'package:flutter/material.dart';
import '../../models/lead_model.dart';
import 'lead_detail_atoms.dart';
import 'lead_detail_tokens.dart';

class LeadHeaderSection extends StatelessWidget {
  final Lead lead;
  const LeadHeaderSection({super.key, required this.lead});

  @override
  Widget build(BuildContext context) {
    final stageTone = _stageTone(lead);

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _Capsule(
                icon: Icons.analytics_outlined,
                text: lead.stageLabel.toUpperCase(),
                bg: stageTone.withValues(alpha: 0.12),
                fg: stageTone,
              ),
              const SizedBox(width: 8),
              _Capsule(
                icon: Icons.percent_rounded,
                text: '${lead.probability}% PROBABILITY',
                bg: LdToken.primary.withValues(alpha: 0.1),
                fg: LdToken.primary,
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  lead.title,
                  style: const TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    color: LdToken.textHigh,
                    height: 1.2,
                    letterSpacing: -0.4,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              LdStarRating(stars: lead.stars, size: 20),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              ...lead.detailTags.map((t) => LdTagBadge(tag: t)),
              if (lead.leadScore > 0)
                Text(
                  'Lead Score: ${lead.leadScore}/100',
                  style: const TextStyle(
                    fontSize: 13,
                    color: LdToken.textMed,
                    fontWeight: FontWeight.w700,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Color _stageTone(Lead lead) {
    switch (lead.stage) {
      case LeadStage.won:
        return LdToken.green;
      case LeadStage.lost:
        return LdToken.accent;
      case LeadStage.proposal:
        return const Color(0xFF2563EB);
      case LeadStage.qualified:
        return const Color(0xFF7C3AED);
      case LeadStage.newLead:
        return LdToken.primary;
    }
  }
}

class _Capsule extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color bg;
  final Color fg;

  const _Capsule({
    required this.icon,
    required this.text,
    required this.bg,
    required this.fg,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: fg),
          const SizedBox(width: 5),
          Text(
            text,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: fg,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }
}
