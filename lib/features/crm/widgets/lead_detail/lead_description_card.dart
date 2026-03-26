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
          _CollapsibleLeadDescription(text: lead.description),
          if (lead.keyRequirements.length > 3) ...[
            const SizedBox(height: 10),
            Text(
              '${lead.keyRequirements.length} requirements',
              style: const TextStyle(fontSize: 12, color: LdToken.textLow),
            ),
          ],
          if (lead.keyRequirements.isNotEmpty) ...[
            const SizedBox(height: 14),
            _KeyRequirementsBox(items: lead.keyRequirements),
          ],
        ],
      ),
    );
  }
}

class _CollapsibleLeadDescription extends StatefulWidget {
  final String text;

  const _CollapsibleLeadDescription({required this.text});

  @override
  State<_CollapsibleLeadDescription> createState() =>
      _CollapsibleLeadDescriptionState();
}

class _CollapsibleLeadDescriptionState
    extends State<_CollapsibleLeadDescription> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final showToggle = widget.text.length > 180;
    final maxLines = _expanded ? null : 4;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.text,
          maxLines: maxLines,
          overflow: _expanded ? TextOverflow.visible : TextOverflow.ellipsis,
          style: const TextStyle(
            fontSize: 14,
            color: LdToken.textMed,
            height: 1.55,
          ),
        ),
        if (showToggle)
          TextButton(
            onPressed: () => setState(() => _expanded = !_expanded),
            style: TextButton.styleFrom(
              padding: EdgeInsets.zero,
              minimumSize: const Size(0, 0),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Text(
              _expanded ? 'Show less' : 'Show more',
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: LdToken.primary,
              ),
            ),
          ),
      ],
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
