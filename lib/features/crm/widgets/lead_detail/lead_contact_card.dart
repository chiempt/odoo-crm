import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/lead_model.dart';
import 'lead_detail_atoms.dart';
import 'lead_detail_tokens.dart';

class LeadContactCard extends StatelessWidget {
  final Lead lead;
  const LeadContactCard({super.key, required this.lead});

  @override
  Widget build(BuildContext context) {
    return LdCardShell(
      label: 'CONTACT INFORMATION',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _ContactIdentity(lead: lead),
          const SizedBox(height: 14),
          const Divider(height: 1, color: LdToken.divider),
          const SizedBox(height: 12),
          if (lead.email.isNotEmpty)
            LdIconRow(icon: Icons.mail_outline_rounded, text: lead.email),
          if (lead.phone.isNotEmpty)
            LdIconRow(icon: Icons.phone_outlined, text: lead.phone),
          if (lead.location.isNotEmpty)
            LdIconRow(icon: Icons.location_on_outlined, text: lead.location),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: LdOutlineButton(
                  icon: Icons.phone_outlined,
                  label: 'Call',
                  onTap: () => _launch(
                    context,
                    scheme: 'tel',
                    value: lead.phone,
                    emptyMessage: 'Phone number is missing',
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: LdFilledButton(
                  icon: Icons.mail_outline_rounded,
                  label: 'Email',
                  onTap: () => _launch(
                    context,
                    scheme: 'mailto',
                    value: lead.email,
                    emptyMessage: 'Email is missing',
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _launch(
    BuildContext context, {
    required String scheme,
    required String value,
    required String emptyMessage,
  }) async {
    final normalized = value.trim();
    if (normalized.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(emptyMessage)),
      );
      return;
    }

    final uri = Uri.parse('$scheme:$normalized');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
      return;
    }

    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Unable to open $scheme action')),
    );
  }
}

class _ContactIdentity extends StatelessWidget {
  final Lead lead;
  const _ContactIdentity({required this.lead});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        LdAvatar(
          color: lead.avatarColor,
          initials: lead.avatarInitials,
          radius: 28,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                lead.contactName,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: LdToken.textHigh,
                ),
              ),
              const SizedBox(height: 3),
              _IconLabel(icon: Icons.business_outlined, text: lead.company),
              const SizedBox(height: 2),
              _IconLabel(
                icon: Icons.person_outline_rounded,
                text: lead.contactTitle,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _IconLabel extends StatelessWidget {
  final IconData icon;
  final String text;
  const _IconLabel({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 13, color: LdToken.textLow),
        const SizedBox(width: 4),
        Text(
          text,
          style: const TextStyle(fontSize: 13, color: LdToken.textMed),
        ),
      ],
    );
  }
}
