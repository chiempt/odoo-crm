import 'package:flutter/material.dart';
import '../../models/lead_model.dart';
import 'lead_detail_atoms.dart';
import 'lead_detail_tokens.dart';

class LeadSourceCard extends StatelessWidget {
  final Lead lead;
  const LeadSourceCard({super.key, required this.lead});

  @override
  Widget build(BuildContext context) {
    return LdCardShell(
      label: 'LEAD SOURCE & CAMPAIGN',
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: lead.sourceIconBgColor,
              shape: BoxShape.circle,
            ),
            child: Icon(lead.sourceIcon, size: 22, color: LdToken.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  lead.source,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: LdToken.textHigh,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  lead.campaign,
                  style: const TextStyle(fontSize: 13, color: LdToken.textMed),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
