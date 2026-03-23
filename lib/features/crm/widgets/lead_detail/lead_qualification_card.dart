import 'package:flutter/material.dart';
import '../../models/lead_model.dart';
import 'lead_detail_atoms.dart';
import 'lead_detail_tokens.dart';

/// Qualification checklist + "Lead is Qualified!" banner (when applicable).
class LeadQualificationCard extends StatelessWidget {
  final Lead lead;
  const LeadQualificationCard({super.key, required this.lead});

  @override
  Widget build(BuildContext context) {
    return LdCardShell(
      label: 'QUALIFICATION STATUS',
      child: Column(
        children: lead.qualificationItems
            .map((item) => _QualItem(item: item))
            .toList(),
      ),
    );
  }
}

class _QualItem extends StatelessWidget {
  final QualificationItem item;
  const _QualItem({required this.item});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            item.isDone
                ? Icons.check_circle_rounded
                : Icons.radio_button_unchecked_rounded,
            size: 20,
            color: item.isDone ? LdToken.green : LdToken.textLow,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.label,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: item.isDone ? LdToken.textHigh : LdToken.textMed,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  item.subtitle,
                  style: const TextStyle(fontSize: 12, color: LdToken.textLow),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Green banner shown when lead.isQualified == true.
class LeadQualifiedBanner extends StatelessWidget {
  final VoidCallback onTap;
  const LeadQualifiedBanner({super.key, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF1FFF4),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFA5D6A7)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          _BannerInfo(),
          const SizedBox(height: 14),
          _ConvertButton(onTap: onTap)
        ],
      ),
    );
  }
}

class _BannerInfo extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: const BoxDecoration(
            color: LdToken.green,
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.bolt_rounded, size: 20, color: Colors.white),
        ),
        const SizedBox(width: 12),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Lead is Qualified!',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: LdToken.green,
                ),
              ),
              SizedBox(height: 2),
              Text(
                'This lead meets the criteria. Convert to opportunity to move forward.',
                style: TextStyle(
                  fontSize: 12,
                  color: Color(0xFF388E3C),
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ConvertButton extends StatelessWidget {
  final VoidCallback onTap;
  const _ConvertButton({required this.onTap});
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 46,
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: LdToken.green,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Convert to Opportunity',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
            ),
            SizedBox(width: 6),
            Icon(Icons.arrow_forward_rounded, size: 18),
          ],
        ),
      ),
    );
  }
}
