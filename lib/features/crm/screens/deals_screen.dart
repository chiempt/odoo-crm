import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/lead_model.dart';
import '../providers/crm_provider.dart';
import 'deal_detail_screen.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Design tokens
// ─────────────────────────────────────────────────────────────────────────────
abstract final class _T {
  static const primary = Color(0xFF5a3d6a);
  static const bg = Color(0xFFF8F9FB);
  static const text = Color(0xFF1D1B20);
  static const sub = Color(0xFF777777);
  static const hint = Color(0xFF9E9E9E);
}

// ─────────────────────────────────────────────────────────────────────────────
// Screen
// ─────────────────────────────────────────────────────────────────────────────
class DealsScreen extends StatefulWidget {
  const DealsScreen({super.key});

  @override
  State<DealsScreen> createState() => _DealsScreenState();
}

class _DealsScreenState extends State<DealsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this, initialIndex: 0);

    // Initial fetch
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CrmProvider>().fetchLeads();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final crmProvider = context.watch<CrmProvider>();
    final leads = crmProvider.leads;

    return Scaffold(
      backgroundColor: _T.bg,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            _buildSummaryRow(leads),
            _buildTabBar(),
            Expanded(
              child: crmProvider.isLoading && leads.isEmpty
                  ? const Center(
                      child: CircularProgressIndicator(color: _T.primary),
                    )
                  : crmProvider.error != null && leads.isEmpty
                  ? _buildErrorPlaceholder(crmProvider.error!)
                  : TabBarView(
                      controller: _tabController,
                      children: [
                        _buildDealList(leads, crmProvider),
                        _buildDealList(
                          leads.where((d) {
                            if (d.dueDate == 'No Date') return false;
                            try {
                              final date = DateTime.parse(d.dueDate);
                              return date.difference(DateTime.now()).inDays < 7;
                            } catch (_) {
                              return false;
                            }
                          }).toList(),
                          crmProvider,
                        ),
                        _buildDealList(
                          leads.where((d) => d.probability >= 80).toList(),
                          crmProvider,
                        ),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorPlaceholder(String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.redAccent),
            const SizedBox(height: 16),
            Text(
              'Failed to load deals',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            const SizedBox(height: 8),
            Text(
              error,
              textAlign: TextAlign.center,
              style: TextStyle(color: _T.sub),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => context.read<CrmProvider>().fetchLeads(),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  // ── Header ────────────────────────────────────────────────────────────────

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 16, 8),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  'Deals',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: _T.text,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Pipeline overview',
                  style: TextStyle(fontSize: 13, color: Color(0xFF79747E)),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.tune_rounded, color: Color(0xFF444444)),
            onPressed: () {},
          ),
        ],
      ),
    );
  }

  // ── Summary row ───────────────────────────────────────────────────────────

  Widget _buildSummaryRow(List<Lead> leads) {
    final total = leads.fold(0.0, (sum, d) {
      return sum + d.expectedRevenueValue;
    });

    // Calculate Won Rate (simplified for demo based on probability > 50)
    final highProbCount = leads.where((d) => d.probability > 75).length;
    final wonRate = leads.isEmpty
        ? 0
        : (highProbCount / leads.length * 100).toInt();

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Row(
        children: [
          _SummaryTile(
            label: 'Total Pipeline',
            value: '\$${(total / 1000).toStringAsFixed(0)}K',
            color: _T.primary,
          ),
          const SizedBox(width: 10),
          _SummaryTile(
            label: 'Deals',
            value: '${leads.length}',
            color: const Color(0xFF2196F3),
          ),
          const SizedBox(width: 10),
          _SummaryTile(
            label: 'Won Rate',
            value: '$wonRate%',
            color: const Color(0xFF4CAF50),
          ),
        ],
      ),
    );
  }

  // ── Tab bar ───────────────────────────────────────────────────────────────

  Widget _buildTabBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: const Color(0xFFEEEEEE),
        borderRadius: BorderRadius.circular(12),
      ),
      child: TabBar(
        controller: _tabController,
        indicatorSize: TabBarIndicatorSize.tab,
        indicator: BoxDecoration(
          color: _T.primary,
          borderRadius: BorderRadius.circular(10),
        ),
        labelColor: Colors.white,
        unselectedLabelColor: _T.sub,
        labelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
        unselectedLabelStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
        tabs: const [
          Tab(text: 'All'),
          Tab(text: 'Urgent'),
          Tab(text: 'Hot'),
        ],
        padding: const EdgeInsets.all(4),
        dividerColor: Colors.transparent,
      ),
    );
  }

  // ── Deal list ─────────────────────────────────────────────────────────────

  Widget _buildDealList(List<Lead> leads, CrmProvider provider) {
    if (leads.isEmpty && !provider.isLoading) {
      return RefreshIndicator(
        onRefresh: () => provider.fetchLeads(),
        child: ListView(
          children: [
            SizedBox(
              height: 400,
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.handshake_outlined,
                      size: 64,
                      color: Colors.grey[300],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'No deals here',
                      style: TextStyle(color: Colors.grey[400], fontSize: 16),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => provider.fetchLeads(),
      color: _T.primary,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
        itemCount: leads.length + (provider.isFetchingMore ? 1 : 0),
        itemBuilder: (context, i) {
          if (i == leads.length) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(8.0),
                child: CircularProgressIndicator(color: _T.primary),
              ),
            );
          }

          final lead = leads[i];

          // Trigger fetch more when reaching the end
          if (i == leads.length - 1 && provider.hasMore) {
            provider.fetchLeads(isLoadMore: true);
          }

          return _DealCard(
            lead: lead,
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => DealDetailScreen(lead: lead),
              ),
            ),
          );
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Reusable widgets
// ─────────────────────────────────────────────────────────────────────────────

class _SummaryTile extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _SummaryTile({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: const TextStyle(fontSize: 10, color: Color(0xFF9E9E9E)),
            ),
          ],
        ),
      ),
    );
  }
}

class _DealCard extends StatelessWidget {
  final Lead lead;
  final VoidCallback onTap;

  const _DealCard({required this.lead, required this.onTap});

  Color get _stageColor {
    final s = lead.stage;
    return switch (s) {
      LeadStage.newLead => const Color(0xFF2196F3),
      LeadStage.qualified => const Color(0xFFF57C00),
      LeadStage.proposal => const Color(0xFFE53935),
      LeadStage.won => const Color(0xFF4CAF50),
      LeadStage.lost => Colors.grey,
    };
  }

  String get _stageName {
    return switch (lead.stage) {
      LeadStage.newLead => 'New',
      LeadStage.qualified => 'Qualified',
      LeadStage.proposal => 'Proposal',
      LeadStage.won => 'Won',
      LeadStage.lost => 'Lost',
    };
  }

  @override
  Widget build(BuildContext context) {
    int daysLeft = -1;
    if (lead.dueDate != 'No Date') {
      try {
        final date = DateTime.parse(lead.dueDate);
        daysLeft = date.difference(DateTime.now()).inDays;
      } catch (_) {}
    }

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Row 1: avatar + title + value ────────────────────────────
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: lead.avatarColor,
                    child: Text(
                      lead.avatarInitials,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          lead.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: _T.text,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          lead.company,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 12, color: _T.sub),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        lead.value,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: _T.text,
                        ),
                      ),
                      if (daysLeft >= 0)
                        Text(
                          '${daysLeft}d left',
                          style: TextStyle(
                            fontSize: 11,
                            color: daysLeft < 7
                                ? const Color(0xFFE53935)
                                : _T.hint,
                            fontWeight: daysLeft < 7
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                        ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 10),
              // ── Row 2: stage badge + progress bar ────────────────────────
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: _stageColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      _stageName,
                      style: TextStyle(
                        color: _stageColor,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: LinearProgressIndicator(
                      value: lead.probability / 100,
                      backgroundColor: const Color(0xFFEEEEEE),
                      valueColor: AlwaysStoppedAnimation(
                        lead.probability >= 80
                            ? const Color(0xFF4CAF50)
                            : lead.probability >= 60
                            ? const Color(0xFFF57C00)
                            : _T.hint,
                      ),
                      minHeight: 6,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${lead.probability}%',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF555555),
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
}
