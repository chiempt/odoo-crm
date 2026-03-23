import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/lead_model.dart';

class LeadCard extends StatelessWidget {
  final Lead lead;
  final VoidCallback onTap;

  const LeadCard({
    super.key,
    required this.lead,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final tagColor = lead.tagColor ?? Colors.transparent;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border(
            left: BorderSide(
              color: tagColor != Colors.transparent
                  ? tagColor
                  : const Color(0xFFE0E0E0),
              width: 4,
            ),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Row 1: Title + Tag + Value
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      lead.title,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1D1B20),
                        height: 1.3,
                      ),
                    ),
                  ),
                  if (lead.tag != null) ...[
                    const SizedBox(width: 8),
                    _TagChip(label: lead.tag!, color: tagColor),
                  ],
                  const SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        lead.value,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF1D1B20),
                        ),
                      ),
                      Text(
                        '${lead.probability}% probability',
                        style: const TextStyle(
                          fontSize: 10,
                          color: Color(0xFF9E9E9E),
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 8),

              // Row 2: Avatar + Assignee + Company
              Row(
                children: [
                  CircleAvatar(
                    radius: 12,
                    backgroundColor: lead.avatarColor,
                    child: Text(
                      lead.avatarInitials,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    lead.assignee,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF555555),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Text(
                    '•',
                    style: TextStyle(color: Color(0xFFAAAAAA), fontSize: 12),
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      lead.company,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF777777),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 8),
              const Divider(height: 1, color: Color(0xFFF0F0F0)),
              const SizedBox(height: 8),

              // Row 3: Stars + Stage + Due + Actions
              Row(
                children: [
                  _StarRating(stars: lead.stars),
                  const SizedBox(width: 8),
                  const Text(
                    '•',
                    style: TextStyle(color: Color(0xFFCCCCCC), fontSize: 12),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Stage: ${lead.stageLabel}',
                    style: const TextStyle(
                      fontSize: 11,
                      color: Color(0xFF777777),
                    ),
                  ),
                  const SizedBox(width: 6),
                  const Text(
                    '•',
                    style: TextStyle(color: Color(0xFFCCCCCC), fontSize: 12),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Due: ${lead.dueDate}',
                    style: const TextStyle(
                      fontSize: 11,
                      color: Color(0xFF777777),
                    ),
                  ),
                  const Spacer(),
                  _ActionButton(
                    icon: Icons.phone_outlined,
                    bgColor: const Color(0xFFF0F0F0),
                    iconColor: const Color(0xFF555555),
                    onTap: () => _launch(
                      context,
                      scheme: 'tel',
                      value: lead.phone,
                      emptyMessage: 'Phone number is missing',
                    ),
                  ),
                  const SizedBox(width: 8),
                  _ActionButton(
                    icon: Icons.email_outlined,
                    bgColor: const Color(0xFFE0F7F4),
                    iconColor: const Color(0xFF00897B),
                    onTap: () => _launch(
                      context,
                      scheme: 'mailto',
                      value: lead.email,
                      emptyMessage: 'Email is missing',
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
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

class _TagChip extends StatelessWidget {
  final String label;
  final Color color;
  const _TagChip({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

class _StarRating extends StatelessWidget {
  final int stars;
  const _StarRating({required this.stars});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (index) {
        return Icon(
          index < stars ? Icons.star_rounded : Icons.star_outline_rounded,
          size: 14,
          color: index < stars
              ? const Color(0xFFFFA726)
              : const Color(0xFFCCCCCC),
        );
      }),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final Color bgColor;
  final Color iconColor;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.bgColor,
    required this.iconColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, size: 16, color: iconColor),
      ),
    );
  }
}
