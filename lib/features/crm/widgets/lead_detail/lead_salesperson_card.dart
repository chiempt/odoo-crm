import 'package:flutter/material.dart';
import '../../models/lead_model.dart';
import 'lead_detail_atoms.dart';
import 'lead_detail_tokens.dart';

class LeadSalespersonCard extends StatelessWidget {
  final LeadSalesperson salesperson;
  final VoidCallback? onChange;
  const LeadSalespersonCard({super.key, required this.salesperson, this.onChange});

  @override
  Widget build(BuildContext context) {
    return LdCardShell(
      label: 'ASSIGNED SALESPERSON',
      child: Row(
        children: [
          LdAvatar(
            color: salesperson.avatarColor,
            initials: salesperson.initials,
            radius: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  salesperson.name,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: LdToken.textHigh,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  salesperson.team,
                  style: const TextStyle(fontSize: 13, color: LdToken.textMed),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: onChange,
            child: const Text(
              'Change',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: LdToken.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
