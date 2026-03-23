import 'package:flutter/material.dart';
import '../../models/lead_model.dart';
import 'lead_detail_atoms.dart';
import 'lead_detail_tokens.dart';

class LeadNotesCard extends StatelessWidget {
  final List<NoteEntry> notes;
  const LeadNotesCard({super.key, required this.notes});

  @override
  Widget build(BuildContext context) {
    return LdCardShell(
      label: 'COMMENTS & ACTIVITIES',
      labelTrailing: Text(
        '${notes.length} comments',
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: LdToken.primary,
        ),
      ),
      child: Column(
        children: notes.asMap().entries.map((e) {
          return _NoteRow(note: e.value, isLast: e.key == notes.length - 1);
        }).toList(),
      ),
    );
  }
}

class _NoteRow extends StatelessWidget {
  final NoteEntry note;
  final bool isLast;

  const _NoteRow({required this.note, required this.isLast});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: note.iconBgColor,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(note.icon, size: 18, color: LdToken.primary),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      note.type,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: LdToken.textLow,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      note.timeAgo,
                      style: const TextStyle(
                        fontSize: 11,
                        color: LdToken.textLow,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  note.content,
                  style: const TextStyle(
                    fontSize: 13,
                    color: LdToken.textMed,
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  'by ${note.author}',
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
