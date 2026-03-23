import 'package:flutter/material.dart';
import 'lead_detail_tokens.dart';

class LeadDetailBottomBar extends StatelessWidget {
  final VoidCallback onComment;
  final VoidCallback onSchedule;

  const LeadDetailBottomBar({
    super.key,
    required this.onComment,
    required this.onSchedule,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: LdToken.card,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.07),
            blurRadius: 12,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
          child: Row(
            children: [
              Expanded(child: _CommentButton(onTap: onComment)),
              const SizedBox(width: 10),
              Expanded(child: _ScheduleButton(onTap: onSchedule)),
            ],
          ),
        ),
      ),
    );
  }
}

class _CommentButton extends StatelessWidget {
  final VoidCallback onTap;
  const _CommentButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onTap,
      icon: const Icon(Icons.chat_bubble_outline_rounded, size: 18),
      label: const Text(
        'Comment',
        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
      ),
      style: OutlinedButton.styleFrom(
        foregroundColor: LdToken.textMed,
        side: const BorderSide(color: LdToken.border, width: 1.5),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        padding: const EdgeInsets.symmetric(vertical: 13),
      ),
    );
  }
}

class _ScheduleButton extends StatelessWidget {
  final VoidCallback onTap;
  const _ScheduleButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: onTap,
      icon: const Icon(Icons.calendar_month_outlined, size: 18),
      label: const Text(
        'Schedule',
        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: LdToken.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        padding: const EdgeInsets.symmetric(vertical: 13),
      ),
    );
  }
}
