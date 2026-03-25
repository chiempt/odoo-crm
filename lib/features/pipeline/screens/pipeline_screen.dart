import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/pipeline_provider.dart';
import 'package:intl/intl.dart';
import '../../crm/models/lead_model.dart';
import '../../crm/screens/lead_detail_screen.dart';

class PipelineScreen extends StatefulWidget {
  const PipelineScreen({super.key});

  @override
  State<PipelineScreen> createState() => _PipelineScreenState();
}

class _PipelineScreenState extends State<PipelineScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final pipelineProvider = context.read<PipelineProvider>();
      if (pipelineProvider.leads.isEmpty) {
        pipelineProvider.fetchLeads();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Pipeline',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              context.read<PipelineProvider>().fetchLeads();
            },
          ),
        ],
      ),
      body: Consumer<PipelineProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading && provider.leads.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.error != null && provider.leads.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(
                    provider.error!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.red),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => provider.fetchLeads(),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          if (provider.leads.isEmpty) {
            return const Center(
              child: Text(
                'No leads found.',
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            );
          }

          final formatter = NumberFormat.currency(
            locale: 'en_US',
            symbol: '\$',
          );

          return RefreshIndicator(
            onRefresh: () => provider.fetchLeads(),
            child: ListView.separated(
              padding: const EdgeInsets.all(16.0),
              itemCount: provider.leads.length,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final lead = provider.leads[index];
                return InkWell(
                  onTap: () {
                    final crmLead = lead;
                    // Create a skeleton Lead object for the detail screen
                    // It will fetch full details in its initState
                    final skeletonLead = Lead(
                      id: crmLead.id.toString(),
                      title: crmLead.name,
                      company: crmLead.partnerName,
                      value: formatter.format(crmLead.expectedRevenue),
                      probability: crmLead.probability.toInt(),
                      assignee: crmLead.userName,
                      stars: 1,
                      stage: _mapStageName(crmLead.stageName),
                      dueDate: 'No Date',
                      avatarColor: Colors.primaries[crmLead.userId % Colors.primaries.length],
                      avatarInitials: _getInitials(crmLead.userName),
                      expectedRevenueValue: crmLead.expectedRevenue,
                    );

                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => LeadDetailScreen(lead: skeletonLead),
                      ),
                    );
                  },
                  child: Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  lead.name.isNotEmpty
                                      ? lead.name
                                      : 'Unknown Lead',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: Theme.of(
                                    context,
                                  ).primaryColor.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  lead.stageName,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: Theme.of(context).primaryColor,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          if (lead.partnerName.isNotEmpty) ...[
                            Row(
                              children: [
                                const Icon(
                                  Icons.person_outline,
                                  size: 16,
                                  color: Colors.grey,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    lead.partnerName,
                                    style: const TextStyle(color: Colors.black87),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                          ],
                          Row(
                            children: [
                              const Icon(
                                Icons.assignment_ind_outlined,
                                size: 16,
                                color: Colors.grey,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  lead.userName,
                                  style: const TextStyle(color: Colors.black54),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          if (lead.expectedRevenue > 0) ...[
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                const Icon(
                                  Icons.attach_money,
                                  size: 16,
                                  color: Colors.green,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  '${formatter.format(lead.expectedRevenue)} (${lead.probability}%)',
                                  style: const TextStyle(
                                    color: Colors.green,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }

  LeadStage _mapStageName(String name) {
    final ls = name.toLowerCase();
    if (ls.contains('qual')) return LeadStage.qualified;
    if (ls.contains('prop')) return LeadStage.proposal;
    if (ls.contains('won')) return LeadStage.won;
    if (ls.contains('lost')) return LeadStage.lost;
    return LeadStage.newLead;
  }

  String _getInitials(String name) {
    if (name.isEmpty) return '??';
    final parts = name.split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name.substring(0, 1).toUpperCase();
  }
}
