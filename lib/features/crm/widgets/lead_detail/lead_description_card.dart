import 'package:flutter/material.dart';
import '../../models/lead_model.dart';
import 'lead_detail_atoms.dart';
import 'lead_detail_tokens.dart';

class LeadDescriptionCard extends StatelessWidget {
  final Lead lead;
  const LeadDescriptionCard({super.key, required this.lead});

  @override
  Widget build(BuildContext context) {
    return LdCardShell(
      label: 'LEAD DESCRIPTION',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            lead.description,
            style: const TextStyle(
              fontSize: 14,
              color: LdToken.textMed,
              height: 1.55,
            ),
          ),
          if (lead.keyRequirements.isNotEmpty) ...[
            const SizedBox(height: 14),
            _KeyRequirementsBox(items: lead.keyRequirements),
          ],
        ],
      ),
    );
  }
}

class _KeyRequirementsBox extends StatelessWidget {
  final List<String> items;
  const _KeyRequirementsBox({required this.items});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        color: LdToken.reqBg,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'KEY REQUIREMENTS:',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: LdToken.primary,
              letterSpacing: 0.4,
            ),
          ),
          const SizedBox(height: 8),
          ...items.map(
            (r) => Padding(
              padding: const EdgeInsets.only(bottom: 5),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '• ',
                    style: TextStyle(
                      color: LdToken.primary,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      r,
                      style: const TextStyle(
                        fontSize: 13,
                        color: LdToken.primary,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
