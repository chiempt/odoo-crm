import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/lead_model.dart';
import '../providers/crm_provider.dart';
import 'create_lead_screen.dart';
import '../widgets/lead_detail/lead_detail_tokens.dart';
import '../widgets/lead_detail/lead_header_section.dart';
import '../widgets/lead_detail/lead_revenue_card.dart';
import '../widgets/lead_detail/lead_contact_card.dart';
import '../widgets/lead_detail/lead_source_card.dart';
import '../widgets/lead_detail/lead_next_activity_card.dart';
import '../widgets/lead_detail/lead_description_card.dart';
import '../widgets/lead_detail/lead_qualification_card.dart';
import '../widgets/lead_detail/lead_timeline_card.dart';
import '../widgets/lead_detail/lead_salesperson_card.dart';
import '../widgets/lead_detail/lead_scheduled_card.dart';
import '../widgets/lead_detail/lead_notes_card.dart';
import '../widgets/lead_detail/lead_bottom_bar.dart';
import '../widgets/lead_detail/lead_action_sheets.dart';

class LeadDetailScreen extends StatefulWidget {
  final Lead lead;
  const LeadDetailScreen({super.key, required this.lead});

  @override
  State<LeadDetailScreen> createState() => _LeadDetailScreenState();
}

class _LeadDetailScreenState extends State<LeadDetailScreen> {
  late String _leadId;

  @override
  void initState() {
    super.initState();
    _leadId = widget.lead.id;
    _refreshLead();
  }

  Future<void> _refreshLead() async {
    await context.read<CrmProvider>().fetchLeadById(int.parse(_leadId));
  }

  @override
  Widget build(BuildContext context) {
    final crmProvider = context.watch<CrmProvider>();
    final lead = crmProvider.leads.firstWhere(
      (l) => l.id == _leadId,
      orElse: () => widget.lead,
    );

    return Scaffold(
      backgroundColor: LdToken.bg,
      appBar: _buildAppBar(context, lead),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFF0F6FA), LdToken.bg, LdToken.bg],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            stops: [0, 0.18, 1],
          ),
        ),
        child: RefreshIndicator(
          onRefresh: _refreshLead,
          child: _buildBody(lead),
        ),
      ),
      bottomNavigationBar: LeadDetailBottomBar(
        onComment: () => _showLogNoteDialog(context, lead),
        onSchedule: () => _showScheduleDialog(context, lead),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context, Lead lead) {
    return AppBar(
      backgroundColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      leading: TextButton.icon(
        onPressed: () => Navigator.of(context).pop(),
        icon: const Icon(
          Icons.chevron_left_rounded,
          color: LdToken.primary,
          size: 22,
        ),
        label: const Text(
          'Back',
          style: TextStyle(
            color: LdToken.primary,
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      leadingWidth: 80,
      actions: [
        IconButton(
          onPressed: () => _showMoreMenu(context, lead),
          style: IconButton.styleFrom(
            backgroundColor: Colors.white.withValues(alpha: 0.92),
            side: const BorderSide(color: LdToken.border),
          ),
          icon: const Icon(Icons.more_horiz_rounded, color: LdToken.textHigh),
        ),
        const SizedBox(width: 8),
      ],
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Divider(height: 1, color: LdToken.border),
      ),
    );
  }

  Widget _buildBody(Lead lead) {
    return ListView(
      padding: const EdgeInsets.only(bottom: 80),
      children: [
        LeadHeaderSection(lead: lead),
        const SizedBox(height: 12),
        LeadRevenueCard(lead: lead),
        const SizedBox(height: 10),
        LeadContactCard(lead: lead),
        const SizedBox(height: 10),
        LeadSourceCard(lead: lead),
        if (lead.nextActivity != null) ...[
          const SizedBox(height: 10),
          LeadNextActivityCard(activity: lead.nextActivity!),
        ],
        if (lead.description.isNotEmpty) ...[
          const SizedBox(height: 10),
          LeadDescriptionCard(lead: lead),
        ],
        if (lead.qualificationItems.isNotEmpty) ...[
          const SizedBox(height: 10),
          LeadQualificationCard(lead: lead),
        ],
        if (lead.isQualified) ...[
          const SizedBox(height: 10),
          LeadQualifiedBanner(
            onTap: () => _onConvertToOpportunity(context, lead),
          ),
        ],
        if (lead.timeline.isNotEmpty) ...[
          const SizedBox(height: 10),
          LeadTimelineCard(entries: lead.timeline),
        ],
        if (lead.salesperson != null) ...[
          const SizedBox(height: 10),
          LeadSalespersonCard(
            salesperson: lead.salesperson!,
            onChange: () => _showChangeSalespersonSheet(context, lead),
          ),
        ],
        if (lead.scheduledActivities.isNotEmpty) ...[
          const SizedBox(height: 10),
          LeadScheduledCard(activities: lead.scheduledActivities),
        ],
        if (lead.notes.isNotEmpty) ...[
          const SizedBox(height: 10),
          LeadNotesCard(notes: lead.notes),
        ],
        const SizedBox(height: 12),
      ],
    );
  }

  Future<void> _onConvertToOpportunity(BuildContext context, Lead lead) async {
    final success = await context.read<CrmProvider>().convertToOpportunity(
      int.parse(lead.id),
    );
    if (!context.mounted) return;
    if (success) _refreshLead();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success ? 'Converted to Opportunity' : 'Failed to convert',
        ),
      ),
    );
  }

  void _showMoreMenu(BuildContext context, Lead lead) {
    showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _MoreMenuSheet(
        lead: lead,
        onRefresh: _refreshLead,
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
        if (success) _refreshLead();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              success ? 'Comment posted' : 'Failed to post comment',
            ),
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
        if (success) _refreshLead();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(success ? 'Activity scheduled' : 'Failed to schedule'),
          ),
        );
      }
    });
  }

  void _showChangeSalespersonSheet(BuildContext context, Lead lead) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Consumer<CrmProvider>(
        builder: (context, provider, _) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Change Salesperson',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                if (provider.users.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(20),
                    child: CircularProgressIndicator(),
                  )
                else
                  Flexible(
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: provider.users.length,
                      itemBuilder: (context, index) {
                        final user = provider.users[index];
                        return ListTile(
                          leading: CircleAvatar(
                            backgroundColor: Colors.primaries[user.name.hashCode % Colors.primaries.length],
                            child: Text(
                              user.name.isNotEmpty ? user.name[0].toUpperCase() : '?',
                              style: const TextStyle(color: Colors.white),
                            ),
                          ),
                          title: Text(user.name),
                          onTap: () async {
                            Navigator.pop(context);
                            final success = await provider.assignSalesperson(
                              int.parse(lead.id),
                              user.id,
                            );
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    success
                                        ? 'Salesperson updated'
                                        : 'Failed to update salesperson',
                                  ),
                                ),
                              );
                              if (success) _refreshLead();
                            }
                          },
                        );
                      },
                    ),
                  ),
              ],
            ),
          );
        },
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
          _buildAction(
            context,
            Icons.check_circle_outline_rounded,
            'Mark as Won',
            Colors.green,
            () async {
              final success = await context.read<CrmProvider>().markAsWon(
                int.parse(lead.id),
              );
              if (context.mounted) {
                Navigator.pop(context);
                if (success) onRefresh();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      success ? 'Marked as Won' : 'Failed to update',
                    ),
                  ),
                );
              }
            },
          ),
          _buildAction(
            context,
            Icons.cancel_outlined,
            'Mark as Lost',
            Colors.redAccent,
            () async {
              final success = await context.read<CrmProvider>().markAsLost(
                int.parse(lead.id),
              );
              if (context.mounted) {
                Navigator.pop(context);
                if (success) onRefresh();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      success ? 'Marked as Lost' : 'Failed to update',
                    ),
                  ),
                );
              }
            },
          ),
          _buildAction(
            context,
            Icons.swap_horiz_rounded,
            'Convert to Opportunity',
            Colors.blue,
            () {
              Navigator.pop(context);
              (context.findAncestorStateOfType<_LeadDetailScreenState>()!)
                  ._onConvertToOpportunity(context, lead);
            },
          ),
          const Divider(),
          _buildAction(
            context,
            Icons.edit_outlined,
            'Edit Lead',
            Colors.black87,
            () {
              Navigator.pop(context);
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => CreateLeadScreen(lead: lead)),
              );
            },
          ),
          _buildAction(
            context,
            Icons.delete_outline_rounded,
            'Delete',
            Colors.red,
            () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (_) => AlertDialog(
                  title: const Text('Delete Lead'),
                  content: const Text(
                    'Are you sure you want to delete this lead?',
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
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        success ? 'Lead deleted' : 'Failed to delete',
                      ),
                    ),
                  );
                }
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildAction(
    BuildContext context,
    IconData icon,
    String label,
    Color color,
    VoidCallback onTap,
  ) {
    return ListTile(
      leading: Icon(icon, color: color),
      title: Text(
        label,
        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
      ),
      onTap: onTap,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    );
  }
}
