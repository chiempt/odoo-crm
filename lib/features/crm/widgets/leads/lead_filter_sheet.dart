import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/crm_provider.dart';

class LeadFilterSheet extends StatefulWidget {
  const LeadFilterSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const LeadFilterSheet(),
    );
  }

  @override
  State<LeadFilterSheet> createState() => _LeadFilterSheetState();
}

class _LeadFilterSheetState extends State<LeadFilterSheet> {
  int? _selectedStageId;
  int? _selectedUserId;
  int? _selectedPriority;
  final TextEditingController _minRevCtrl = TextEditingController();
  final TextEditingController _maxRevCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    final p = context.read<CrmProvider>();
    _selectedStageId = p.currentStageId;
    _selectedUserId = p.currentUserId;
    _selectedPriority = p.currentPriority;
    _minRevCtrl.text = p.currentMinRevenue?.toString() ?? '';
    _maxRevCtrl.text = p.currentMaxRevenue?.toString() ?? '';
  }

  void _applyFilters() {
    context.read<CrmProvider>().fetchLeads(
      stageId: _selectedStageId ?? -1,
      userId: _selectedUserId ?? -1,
      priority: _selectedPriority ?? -1,
      minRevenue: double.tryParse(_minRevCtrl.text),
      maxRevenue: double.tryParse(_maxRevCtrl.text),
    );
    Navigator.pop(context);
  }

  void _resetFilters() {
    setState(() {
      _selectedStageId = null;
      _selectedUserId = null;
      _selectedPriority = null;
      _minRevCtrl.clear();
      _maxRevCtrl.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final crmProvider = context.watch<CrmProvider>();
    
    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildHandle(),
          _buildHeader(),
          Flexible(
            child: ListView(
              shrinkWrap: true,
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              children: [
                _buildSectionTitle('Salesperson'),
                _buildUserDropdown(crmProvider.users),
                const SizedBox(height: 20),
                
                _buildSectionTitle('Process Stage'),
                _buildStageGrid(crmProvider.stages),
                const SizedBox(height: 20),
                
                _buildSectionTitle('Priority Level'),
                _buildPriorityPicker(),
                const SizedBox(height: 20),
                
                _buildSectionTitle('Expected Revenue'),
                _buildRevenueRange(),
                const SizedBox(height: 32),
                
                _buildActionButtons(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHandle() {
    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 12),
        width: 40,
        height: 4,
        decoration: BoxDecoration(
          color: Colors.grey[300],
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 10, 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'Filters',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: Color(0xFF1D1B20),
            ),
          ),
          TextButton(
            onPressed: _resetFilters,
            child: const Text('Reset All'),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          color: Colors.grey[600],
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildUserDropdown(List<CrmUser> users) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F5F7),
        borderRadius: BorderRadius.circular(12),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<int?>(
          value: _selectedUserId,
          hint: const Text('All Salespersons'),
          isExpanded: true,
          items: [
            const DropdownMenuItem(value: null, child: Text('All Salespersons')),
            ...users.map((u) => DropdownMenuItem(
              value: u.id,
              child: Text(u.name),
            )),
          ],
          onChanged: (val) => setState(() => _selectedUserId = val),
        ),
      ),
    );
  }

  Widget _buildStageGrid(List<CrmStage> stages) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        _buildChoiceChip('All Stages', _selectedStageId == null, () {
          setState(() => _selectedStageId = null);
        }),
        ...stages.map((s) => _buildChoiceChip(s.name, _selectedStageId == s.id, () {
          setState(() => _selectedStageId = s.id);
        })),
      ],
    );
  }

  Widget _buildChoiceChip(String label, bool isSelected, VoidCallback onTap) {
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => onTap(),
      selectedColor: const Color(0xFF5a3d6a).withValues(alpha: 0.1),
      labelStyle: TextStyle(
        color: isSelected ? const Color(0xFF5a3d6a) : Colors.black87,
        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(
          color: isSelected ? const Color(0xFF5a3d6a) : Colors.grey[300]!,
        ),
      ),
      backgroundColor: Colors.white,
    );
  }

  Widget _buildPriorityPicker() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: List.generate(5, (index) {
        final starCount = index + 1;
        final isSelected = _selectedPriority == starCount;
        return InkWell(
          onTap: () => setState(() => _selectedPriority = isSelected ? null : starCount),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: isSelected ? Colors.amber.withValues(alpha: 0.1) : Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: isSelected ? Colors.amber : Colors.grey[300]!,
              ),
            ),
            child: Row(
              children: [
                Text('$starCount'),
                const Icon(Icons.star_rounded, size: 16, color: Colors.amber),
              ],
            ),
          ),
        );
      }),
    );
  }

  Widget _buildRevenueRange() {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: _minRevCtrl,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              hintText: 'Min',
              filled: true,
              fillColor: const Color(0xFFF5F5F7),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16),
            ),
          ),
        ),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 12),
          child: Text('to'),
        ),
        Expanded(
          child: TextField(
            controller: _maxRevCtrl,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              hintText: 'Max',
              filled: true,
              fillColor: const Color(0xFFF5F5F7),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.grey[100],
              foregroundColor: Colors.black87,
              elevation: 0,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Cancel'),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ElevatedButton(
            onPressed: _applyFilters,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF5a3d6a),
              foregroundColor: Colors.white,
              elevation: 2,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Apply Results'),
          ),
        ),
      ],
    );
  }
}
