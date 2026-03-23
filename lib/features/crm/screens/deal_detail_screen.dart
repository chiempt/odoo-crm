import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/lead_model.dart';
import '../providers/crm_provider.dart';
import '../widgets/lead_detail/lead_action_sheets.dart';
import '../widgets/lead_detail/lead_followers_sheet.dart';
import '../widgets/lead_detail/lead_attachments_sheet.dart';
import 'create_lead_screen.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Design tokens
// ─────────────────────────────────────────────────────────────────────────────
abstract final class _T {
  static const primary = Color(0xFF5a3d6a);
  static const bg = Color(0xFFF8F9FB);
  static const text = Color(0xFF1D1B20);
  static const sub = Color(0xFF777777);
  static const hint = Color(0xFF9E9E9E);
  static const border = Color(0xFFEEEEEE);
  static const card = Colors.white;
}

// ─────────────────────────────────────────────────────────────────────────────
// Screen
// ─────────────────────────────────────────────────────────────────────────────
class DealDetailScreen extends StatefulWidget {
  final Lead lead;

  const DealDetailScreen({super.key, required this.lead});

  @override
  State<DealDetailScreen> createState() => _DealDetailScreenState();
}

class _DealDetailScreenState extends State<DealDetailScreen> {
  static const _stageLabels = ['New', 'Qualified', 'Proposal', 'Won', 'Lost'];

  @override
  void initState() {
    super.initState();
    _refreshData();
  }

  Future<void> _refreshData() async {
    if (!mounted) return;
    await context.read<CrmProvider>().fetchLeadById(int.parse(widget.lead.id));
  }

  Lead _getLatestLead() {
    final crmProvider = context.watch<CrmProvider>();
    return crmProvider.leads.firstWhere(
      (l) => l.id == widget.lead.id,
      orElse: () => widget.lead,
    );
  }

  @override
  Widget build(BuildContext context) {
    final lead = _getLatestLead();

    return Scaffold(
      backgroundColor: _T.bg,
      appBar: _buildAppBar(context, lead),
      body: RefreshIndicator(
        onRefresh: _refreshData,
        color: _T.primary,
        child: ListView(
          padding: const EdgeInsets.only(bottom: 100),
          children: [
            _buildHero(lead),
            _buildStagePills(lead),
            const SizedBox(height: 12),
            _buildCustomerCard(context, lead),
            if (lead.scheduledActivities.isNotEmpty) ...[
              const SizedBox(height: 10),
              _buildActivityCard(lead.scheduledActivities.first),
            ],
            const SizedBox(height: 10),
            _buildNotesCard(lead),
            const SizedBox(height: 10),
            _buildMetaRow(lead),
            const SizedBox(height: 10),
            _buildHistorySection(lead),
            const SizedBox(height: 80),
          ],
        ),
      ),
      floatingActionButton: _buildFab(context),
      bottomNavigationBar: _buildBottomBar(context, lead),
    );
  }

  // ── AppBar ────────────────────────────────────────────────────────────────

  PreferredSizeWidget _buildAppBar(BuildContext context, Lead lead) {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      leading: TextButton.icon(
        onPressed: () => Navigator.of(context).pop(),
        icon: const Icon(
          Icons.chevron_left_rounded,
          color: _T.primary,
          size: 22,
        ),
        label: const Text(
          'Deal',
          style: TextStyle(
            color: _T.primary,
            fontSize: 15,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
      leadingWidth: 100,
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context)
              .push(
                MaterialPageRoute(builder: (_) => CreateLeadScreen(lead: lead)),
              )
              .then((_) => _refreshData()),
          child: const Text(
            'Edit',
            style: TextStyle(
              color: _T.primary,
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        IconButton(
          onPressed: () => _showMoreMenu(context, lead),
          icon: const Icon(Icons.more_vert, color: _T.text),
        ),
      ],
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Divider(height: 1, color: Colors.grey.shade200),
      ),
    );
  }

  // ── Hero header ───────────────────────────────────────────────────────────

  Widget _buildHero(Lead lead) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            lead.title,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: _T.text,
              height: 1.25,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            lead.value,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w900,
              color: _T.primary,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'at ${lead.probability}% probability',
            style: const TextStyle(fontSize: 13, color: _T.hint),
          ),
        ],
      ),
    );
  }

  // ── Stage pills ───────────────────────────────────────────────────────────

  Widget _buildStagePills(Lead lead) {
    final stageName = switch (lead.stage) {
      LeadStage.newLead => 'New',
      LeadStage.qualified => 'Qualified',
      LeadStage.proposal => 'Proposal',
      LeadStage.won => 'Won',
      LeadStage.lost => 'Lost',
    };

    final currentIdx = _stageLabels.indexOf(stageName);
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: _stageLabels.asMap().entries.map((e) {
          final isActive = e.key == currentIdx;
          final isPast = currentIdx != -1 && e.key < currentIdx;
          return GestureDetector(
            onTap: () => _changeStage(lead, e.value),
            child: _StagePill(
              label: e.value.toUpperCase(),
              isActive: isActive,
              isPast: isPast,
            ),
          );
        }).toList(),
      ),
    );
  }

  Future<void> _changeStage(Lead lead, String label) async {
    final provider = context.read<CrmProvider>();
    // Find matching stage from Odoo stages
    final matchingStage =
        provider.stages
            .where((s) => s.name.toLowerCase().contains(label.toLowerCase()))
            .firstOrNull ??
        provider.stages
            .where(
              (s) => label == 'New' && s.name.toLowerCase().contains('new'),
            )
            .firstOrNull;

    if (matchingStage != null) {
      final success = await provider.updateLead(int.parse(lead.id), {
        'stage_id': matchingStage.id,
      });
      if (success) {
        _refreshData();
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Stage updated to $label')));
        }
      }
    }
  }

  // ── Customer card ─────────────────────────────────────────────────────────

  Widget _buildCustomerCard(BuildContext context, Lead lead) {
    return _Card(
      label: 'CUSTOMER INFO',
      child: Column(
        children: [
          Row(
            children: [
              _Avatar(
                color: lead.avatarColor,
                initials: lead.avatarInitials,
                radius: 26,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      lead.contactName.isNotEmpty
                          ? lead.contactName
                          : lead.company,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: _T.text,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      lead.company,
                      style: const TextStyle(fontSize: 13, color: _T.sub),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _OutlineButton(
                  icon: Icons.phone_outlined,
                  label: 'Call',
                  onTap: () async {
                    if (lead.phone.isNotEmpty) {
                      final uri = Uri.parse('tel:${lead.phone}');
                      if (await canLaunchUrl(uri)) await launchUrl(uri);
                    }
                  },
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _FilledButton(
                  icon: Icons.mail_outline_rounded,
                  label: 'Email',
                  onTap: () async {
                    if (lead.email.isNotEmpty) {
                      final uri = Uri.parse('mailto:${lead.email}');
                      if (await canLaunchUrl(uri)) await launchUrl(uri);
                    }
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Activity card ─────────────────────────────────────────────────────────

  Widget _buildActivityCard(ScheduledActivity act) {
    return _Card(
      label: 'ACTIVITIES',
      labelTrailing: _DueBadge(label: 'DUE', color: act.priorityColor),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: act.iconBgColor,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(act.icon, size: 20, color: _T.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  act.title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: _T.text,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  act.description,
                  style: const TextStyle(
                    fontSize: 13,
                    color: _T.sub,
                    height: 1.4,
                  ),
                ),
                if (act.date.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    act.date,
                    style: const TextStyle(fontSize: 12, color: _T.hint),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Notes card ────────────────────────────────────────────────────────────

  Widget _buildNotesCard(Lead lead) {
    if (lead.notes.isEmpty) {
      if (lead.description.isEmpty) return const SizedBox.shrink();
      return _Card(
        label: 'DESCRIPTION',
        child: Text(
          lead.description,
          style: const TextStyle(fontSize: 13, color: _T.sub, height: 1.55),
        ),
      );
    }

    return _Card(
      label: 'NOTES',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: lead.notes
            .map(
              (n) => Padding(
                padding: const EdgeInsets.only(bottom: 12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      n.content,
                      style: const TextStyle(
                        fontSize: 13,
                        color: _T.sub,
                        fontStyle: FontStyle.italic,
                        height: 1.55,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${n.timeAgo} • ${n.author}',
                      style: const TextStyle(fontSize: 11, color: _T.hint),
                    ),
                    if (n != lead.notes.last) const Divider(height: 24),
                  ],
                ),
              ),
            )
            .toList(),
      ),
    );
  }

  // ── Meta row (deadline + assignee) ─────────────────────────────────

  Widget _buildMetaRow(Lead lead) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: _MetaTile(label: 'DEADLINE', value: lead.dueDate),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _MetaTile(label: 'ASSIGNEE', value: lead.assignee),
          ),
        ],
      ),
    );
  }

  // ── History section ───────────────────────────────────────────────────────

  Widget _buildHistorySection(Lead lead) {
    if (lead.timeline.isEmpty) return const SizedBox.shrink();
    return _Card(
      label: 'CHANNAL MESSAGES',
      child: Column(
        children: lead.timeline.asMap().entries.map((e) {
          final isLast = e.key == lead.timeline.length - 1;
          return _HistoryEntry(entry: e.value, isLast: isLast);
        }).toList(),
      ),
    );
  }

  // ── FAB ───────────────────────────────────────────────────────────────────

  Widget _buildFab(BuildContext context) {
    return FloatingActionButton(
      onPressed: () => Navigator.of(
        context,
      ).push(MaterialPageRoute(builder: (_) => const CreateLeadScreen())),
      backgroundColor: _T.primary,
      elevation: 4,
      shape: const CircleBorder(),
      child: const Icon(Icons.add, color: Colors.white, size: 26),
    );
  }

  // ── Bottom action bar ─────────────────────────────────────────────────────

  Widget _buildBottomBar(BuildContext context, Lead lead) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.07),
            blurRadius: 12,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        child: SizedBox(
          height: 60,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _BottomAction(
                icon: Icons.edit_note_rounded,
                label: 'Log Note',
                onTap: () => _showLogNoteDialog(context, lead),
              ),
              _BottomAction(
                icon: Icons.calendar_month_outlined,
                label: 'Schedule',
                onTap: () => _showScheduleDialog(context, lead),
              ),
              _BottomAction(
                icon: Icons.attach_file_rounded,
                label: 'Attach',
                onTap: () => AttachmentsSheet.show(context, lead),
              ),
              _BottomAction(
                icon: Icons.group_add_outlined,
                label: 'Followers',
                onTap: () => FollowersSheet.show(context, lead),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showLogNoteDialog(BuildContext context, Lead lead) {
    LogNoteSheet.show(context, lead, (body) async {
      final success = await context.read<CrmProvider>().logMessage(
        int.parse(lead.id),
        body,
      );
      if (context.mounted) {
        if (success) _refreshData();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(success ? 'Note logged' : 'Failed to log note'),
          ),
        );
      }
    });
  }

  void _showScheduleDialog(BuildContext context, Lead lead) {
    ScheduleActivitySheet.show(context, lead, (summary, note, date) async {
      final success = await context.read<CrmProvider>().scheduleActivity(
        leadId: int.parse(lead.id),
        summary: summary,
        note: note,
        dateDeadline: date,
      );
      if (context.mounted) {
        if (success) _refreshData();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              success ? 'Activity scheduled' : 'Failed to schedule',
            ),
          ),
        );
      }
    });
  }

  // ── Context menu ──────────────────────────────────────────────────────────

  void _showMoreMenu(BuildContext context, Lead lead) {
    showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _MoreMenuSheet(lead: lead, onRefresh: _refreshData),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Private components
// ─────────────────────────────────────────────────────────────────────────────

class _StagePill extends StatelessWidget {
  final String label;
  final bool isActive;
  final bool isPast;

  const _StagePill({
    required this.label,
    required this.isActive,
    required this.isPast,
  });

  @override
  Widget build(BuildContext context) {
    final bg = isActive
        ? _T.primary
        : isPast
        ? _T.primary.withValues(alpha: 0.08)
        : Colors.white;
    final textColor = isActive
        ? Colors.white
        : isPast
        ? _T.primary
        : _T.hint;
    final borderColor = isActive
        ? _T.primary
        : isPast
        ? _T.primary.withValues(alpha: 0.3)
        : _T.border;

    return Container(
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor),
        boxShadow: isActive
            ? [
                BoxShadow(
                  color: _T.primary.withValues(alpha: 0.25),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ]
            : [],
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
          color: textColor,
          letterSpacing: 0.4,
        ),
      ),
    );
  }
}

class _Card extends StatelessWidget {
  final String label;
  final Widget? labelTrailing;
  final Widget child;

  const _Card({required this.label, required this.child, this.labelTrailing});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      decoration: BoxDecoration(
        color: _T.card,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: _T.hint,
                  letterSpacing: 0.8,
                ),
              ),
              const Spacer(),
              if (labelTrailing != null) labelTrailing!,
            ],
          ),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  final Color color;
  final String initials;
  final double radius;

  const _Avatar({
    required this.color,
    required this.initials,
    required this.radius,
  });

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: radius,
      backgroundColor: color,
      child: Text(
        initials,
        style: TextStyle(
          color: Colors.white,
          fontSize: radius * 0.55,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

class _OutlineButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _OutlineButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 42,
        decoration: BoxDecoration(
          border: Border.all(color: _T.border, width: 1.5),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 17, color: _T.text),
            const SizedBox(width: 6),
            Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: _T.text,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FilledButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _FilledButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 42,
        decoration: BoxDecoration(
          color: _T.primary,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 17, color: Colors.white),
            const SizedBox(width: 6),
            Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DueBadge extends StatelessWidget {
  final String label;
  final Color color;

  const _DueBadge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: color,
          letterSpacing: 0.4,
        ),
      ),
    );
  }
}

class _MetaTile extends StatelessWidget {
  final String label;
  final String value;

  const _MetaTile({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            color: _T.hint,
            letterSpacing: 0.6,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value.isNotEmpty && value != 'No Date' ? value : '—',
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: _T.text,
          ),
        ),
      ],
    );
  }
}

class _HistoryEntry extends StatelessWidget {
  final LeadTimelineEntry entry;
  final bool isLast;

  const _HistoryEntry({required this.entry, required this.isLast});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Timeline stem + dot
        Column(
          children: [
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: entry.dotColor,
                shape: BoxShape.circle,
              ),
            ),
            if (!isLast) Container(width: 2, height: 28, color: _T.border),
          ],
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Padding(
            padding: EdgeInsets.only(bottom: isLast ? 0 : 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.description,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: _T.text,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${entry.timeAgo} • ${entry.author}',
                  style: const TextStyle(
                    fontSize: 11,
                    color: _T.hint,
                    letterSpacing: 0.2,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _BottomAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _BottomAction({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 22, color: _T.hint),
          const SizedBox(height: 2),
          Text(label, style: const TextStyle(fontSize: 10, color: _T.hint)),
        ],
      ),
    );
  }
}

class _MoreMenuSheet extends StatelessWidget {
  final Lead lead;
  final VoidCallback onRefresh;

  const _MoreMenuSheet({required this.lead, required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),
          ListTile(
            leading: const Icon(
              Icons.check_circle_outline_rounded,
              color: Colors.green,
            ),
            title: const Text('Mark as Won'),
            onTap: () async {
              final success = await context.read<CrmProvider>().markAsWon(
                int.parse(lead.id),
              );
              if (context.mounted) {
                Navigator.pop(context);
                if (success) {
                  onRefresh();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Marked as Won!')),
                  );
                }
              }
            },
          ),
          ListTile(
            leading: const Icon(
              Icons.mark_as_unread_outlined,
              color: Colors.redAccent,
            ),
            title: const Text('Mark as Lost'),
            onTap: () async {
              final success = await context.read<CrmProvider>().markAsLost(
                int.parse(lead.id),
              );
              if (context.mounted) {
                Navigator.pop(context);
                if (success) {
                  onRefresh();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Marked as Lost.')),
                  );
                }
              }
            },
          ),
          ListTile(
            leading: const Icon(
              Icons.delete_outline_rounded,
              color: Colors.red,
            ),
            title: const Text('Delete'),
            onTap: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (_) => AlertDialog(
                  title: const Text('Delete Deal'),
                  content: const Text(
                    'Are you sure you want to delete this deal?',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('Cancel'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: const Text(
                        'Delete',
                        style: TextStyle(color: Colors.red),
                      ),
                    ),
                  ],
                ),
              );
              if (confirm == true && context.mounted) {
                final success = await context.read<CrmProvider>().deleteLead(
                  int.parse(lead.id),
                );
                if (context.mounted) {
                  Navigator.pop(context); // close sheet
                  Navigator.pop(context); // back to list
                  if (success)
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Deal deleted')),
                    );
                }
              }
            },
          ),
        ],
      ),
    );
  }
}
