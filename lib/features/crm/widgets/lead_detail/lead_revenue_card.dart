import 'package:flutter/material.dart';
import '../../models/lead_model.dart';
import 'lead_detail_atoms.dart';
import 'lead_detail_tokens.dart';

class LeadRevenueCard extends StatelessWidget {
  final Lead lead;
  const LeadRevenueCard({super.key, required this.lead});

  @override
  Widget build(BuildContext context) {
    return LdCardShell(
      color: LdToken.revBg,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'EXPECTED REVENUE',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: LdToken.textLow,
              letterSpacing: 0.7,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            lead.expectedRevenue,
            style: const TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.w900,
              color: LdToken.textHigh,
              letterSpacing: -1,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              const Icon(
                Icons.schedule_rounded,
                size: 14,
                color: LdToken.textLow,
              ),
              const SizedBox(width: 5),
              Text(
                'Expected close: ${lead.expectedCloseDate}',
                style: const TextStyle(fontSize: 13, color: LdToken.textMed),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
