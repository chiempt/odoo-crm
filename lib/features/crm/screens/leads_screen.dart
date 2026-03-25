import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/crm_provider.dart';
import 'lead_detail_screen.dart';
import 'create_lead_screen.dart';
import '../widgets/leads/lead_card.dart';
import '../widgets/leads/lead_filter_sheet.dart';

const Color _primaryColor = Color(0xFF5a3d6a);

class LeadsScreen extends StatefulWidget {
  const LeadsScreen({super.key});

  @override
  State<LeadsScreen> createState() => _LeadsScreenState();
}

class _LeadsScreenState extends State<LeadsScreen> {
  bool _isListView = true;

  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final crmProvider = context.read<CrmProvider>();
      if (crmProvider.leads.isEmpty) {
        crmProvider.fetchLeads();
      }
    });
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      final crmProvider = context.read<CrmProvider>();
      if (!crmProvider.isFetchingMore && crmProvider.hasMore) {
        crmProvider.fetchLeads(isLoadMore: true);
      }
    }
  }

  void _onSearchSubmit(String query) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      if (mounted) {
        context.read<CrmProvider>().fetchLeads(query: query);
      }
    });
  }

  void _onFilterTap(int filterIndex, int stageId) {
    context.read<CrmProvider>().fetchLeads(
      filterIndex: filterIndex,
      stageId: stageId,
    );
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final crmProvider = context.watch<CrmProvider>();
    final allLeads = crmProvider.leads;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FB),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(allLeads.length, crmProvider),
            _buildSearchBar(),
            _buildFilterChips(),
            _buildSortRow(allLeads.length),
            Expanded(
              child: crmProvider.isLoading && allLeads.isEmpty
                  ? const Center(child: CircularProgressIndicator())
                  : allLeads.isEmpty
                  ? _buildEmptyState()
                  : RefreshIndicator(
                      onRefresh: () => crmProvider.fetchLeads(),
                      child: _isListView
                          ? ListView.builder(
                              controller: _scrollController,
                              physics: const AlwaysScrollableScrollPhysics(),
                              padding: const EdgeInsets.only(
                                bottom: 100,
                                left: 16,
                                right: 16,
                              ),
                              itemCount: allLeads.length + (crmProvider.isFetchingMore ? 1 : 0),
                              itemBuilder: (context, index) {
                                if (index == allLeads.length) {
                                  return const Padding(
                                    padding: EdgeInsets.symmetric(vertical: 16.0),
                                    child: Center(child: CircularProgressIndicator()),
                                  );
                                }
                                final lead = allLeads[index];
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 12),
                                  child: LeadCard(
                                    lead: lead,
                                    onTap: () => Navigator.of(context).push(
                                      MaterialPageRoute<void>(
                                        builder: (_) => LeadDetailScreen(lead: lead),
                                      ),
                                    ),
                                  ),
                                );
                              },
                            )
                          : GridView.builder(
                              controller: _scrollController,
                              physics: const AlwaysScrollableScrollPhysics(),
                              padding: const EdgeInsets.only(
                                bottom: 100,
                                left: 16,
                                right: 16,
                              ),
                              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                childAspectRatio: 0.75,
                                crossAxisSpacing: 12,
                                mainAxisSpacing: 12,
                              ),
                              itemCount: allLeads.length + (crmProvider.isFetchingMore ? 1 : 0),
                              itemBuilder: (context, index) {
                                if (index == allLeads.length) {
                                  return const Center(child: CircularProgressIndicator());
                                }
                                final lead = allLeads[index];
                                return LeadCard(
                                  lead: lead,
                                  onTap: () => Navigator.of(context).push(
                                    MaterialPageRoute<void>(
                                      builder: (_) => LeadDetailScreen(lead: lead),
                                    ),
                                  ),
                                );
                              },
                            ),
                    ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final res = await Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const CreateLeadScreen()),
          );
          if (!context.mounted || res != true) return;
          context.read<CrmProvider>().fetchLeads();
        },
        backgroundColor: _primaryColor,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildHeader(int totalActiveCount, CrmProvider crmProvider) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 16, 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Leads',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1D1B20),
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '$totalActiveCount active leads',
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF79747E),
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.tune_rounded, color: Color(0xFF444444)),
            onPressed: () => LeadFilterSheet.show(context),
            tooltip: 'Filter',
          ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Color(0xFF444444)),
            onPressed: () => crmProvider.fetchLeads(),
            tooltip: 'Refresh',
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
      child: TextField(
        controller: _searchController,
        onChanged: _onSearchSubmit,
        onSubmitted: _onSearchSubmit,
        textInputAction: TextInputAction.search,
        decoration: InputDecoration(
          hintText: 'Search leads...',
          hintStyle: const TextStyle(color: Color(0xFFAAAAAA), fontSize: 14),
          prefixIcon: const Icon(
            Icons.search,
            color: Color(0xFFAAAAAA),
            size: 20,
          ),
          suffixIcon: IconButton(
            icon: const Icon(Icons.clear, size: 20),
            onPressed: () {
              _searchController.clear();
              _onSearchSubmit('');
            },
            color: const Color(0xFFAAAAAA),
          ),
          filled: true,
          fillColor: const Color(0xFFEFEFEF),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
        ),
      ),
    );
  }

  Widget _buildFilterChips() {
    final crmProvider = context.watch<CrmProvider>();
    final stages = crmProvider.stages;

    // Define standard filters
    final List<Map<String, dynamic>> standardFilters = [
      {'name': 'All', 'filterIndex': 0, 'stageId': -1},
      {'name': 'My Leads', 'filterIndex': 2, 'stageId': -1},
    ];

    return SizedBox(
      height: 42,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          // Standard Filters
          ...standardFilters.map((f) {
            final isSelected =
                crmProvider.currentFilterIndex == f['filterIndex'] &&
                crmProvider.currentStageId == null;
            return _buildFilterItem(
              f['name'],
              isSelected,
              () => _onFilterTap(f['filterIndex'], f['stageId']),
            );
          }),

          // Vertical Divider
          if (stages.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: VerticalDivider(
                color: const Color(0xFFDDDDDD),
                thickness: 1,
                indent: 8,
                endIndent: 8,
              ),
            ),

          // Stage Filters
          ...stages.map((stage) {
            final isSelected = crmProvider.currentStageId == stage.id;
            return _buildFilterItem(
              stage.name,
              isSelected,
              () => _onFilterTap(0, stage.id),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildFilterItem(String label, bool isSelected, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? _primaryColor : Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isSelected ? _primaryColor : const Color(0xFFDDDDDD),
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: _primaryColor.withValues(alpha: 0.25),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : [],
          ),
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? Colors.white : const Color(0xFF444444),
              fontSize: 13,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSortRow(int count) {
    final crmProvider = context.watch<CrmProvider>();
    String sortLabel = 'Date';
    if (crmProvider.currentOrder.contains('expected_revenue')) {
      sortLabel = 'Value';
    } else if (crmProvider.currentOrder.contains('name')) {
      sortLabel = 'Name';
    } else if (crmProvider.currentOrder.contains('probability')) {
      sortLabel = 'Probability';
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 4),
      child: Row(
        children: [
          PopupMenuButton<String>(
            tooltip: 'Sort by',
            onSelected: (val) {
              context.read<CrmProvider>().fetchLeads(order: val);
            },
            offset: const Offset(0, 30),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'create_date desc', child: Text('Newest First')),
              const PopupMenuItem(value: 'expected_revenue desc', child: Text('Revenue: High to Low')),
              const PopupMenuItem(value: 'probability desc', child: Text('Probability: High to Low')),
              const PopupMenuItem(value: 'name asc', child: Text('Name: A to Z')),
            ],
            child: Row(
              children: [
                Text(
                  'Sort by: $sortLabel',
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF555555),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(width: 2),
                const Icon(
                  Icons.keyboard_arrow_down_rounded,
                  size: 18,
                  color: Color(0xFF555555),
                ),
              ],
            ),
          ),
          const Spacer(),
          Text(
            'VIEW:',
            style: const TextStyle(
              fontSize: 11,
              color: Color(0xFF9E9E9E),
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () => setState(() => _isListView = true),
            child: Icon(
              Icons.view_list_rounded,
              size: 22,
              color: _isListView ? _primaryColor : const Color(0xFFAAAAAA),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () => setState(() => _isListView = false),
            child: Icon(
              Icons.grid_view_rounded,
              size: 20,
              color: !_isListView ? _primaryColor : const Color(0xFFAAAAAA),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.filter_list_off, size: 64, color: Colors.grey[300]),
          const SizedBox(height: 12),
          Text(
            'No leads found',
            style: TextStyle(color: Colors.grey[400], fontSize: 16),
          ),
        ],
      ),
    );
  }
}

// LeadItem removed – use Lead from lead_model.dart

// LeadItem removed – use Lead from lead_model.dart
