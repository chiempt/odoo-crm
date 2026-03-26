import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/services/odoo_crm_service.dart';

class ScheduleCallScreen extends StatefulWidget {
  const ScheduleCallScreen({super.key});

  @override
  State<ScheduleCallScreen> createState() => _ScheduleCallScreenState();
}

class _ScheduleCallScreenState extends State<ScheduleCallScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _notesController = TextEditingController();
  final OdooCrmService _crmService = OdooCrmService();

  DateTime _selectedDate = DateTime.now();
  TimeOfDay _selectedTime = TimeOfDay.now();
  String _activityType = 'call';
  int? _selectedLeadId;
  List<Map<String, dynamic>> _leads = [];
  bool _isLoading = false;
  bool _isLoadingLeads = true;

  @override
  void initState() {
    super.initState();
    _loadLeads();
  }

  Future<void> _loadLeads() async {
    try {
      final leads = await _crmService.fetchLeads(
        domain: [
          ['type', '=', 'opportunity'],
          ['probability', '<', 100],
        ],
        fields: ['id', 'name', 'partner_name'],
        limit: 100,
      );
      setState(() {
        _leads = leads;
        _isLoadingLeads = false;
      });
    } catch (e) {
      setState(() => _isLoadingLeads = false);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error loading leads: $e')));
      }
    }
  }

  Future<void> _scheduleActivity() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedLeadId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a lead/opportunity')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final dateTime = DateTime(
        _selectedDate.year,
        _selectedDate.month,
        _selectedDate.day,
        _selectedTime.hour,
        _selectedTime.minute,
      );

      await _crmService.createActivity(
        leadId: _selectedLeadId!,
        summary: _titleController.text,
        note: _notesController.text.isEmpty ? null : _notesController.text,
        dateDeadline: DateFormat('yyyy-MM-dd').format(dateTime),
        activityTypeKey: _activityType,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Activity scheduled successfully!')),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FB),
      appBar: AppBar(
        title: const Text('Schedule Activity'),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: _isLoadingLeads
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSectionTitle('Activity Type'),
                    const SizedBox(height: 12),
                    _buildActivityTypeSelector(),
                    const SizedBox(height: 24),
                    _buildSectionTitle('Lead/Opportunity'),
                    const SizedBox(height: 12),
                    _buildLeadDropdown(),
                    const SizedBox(height: 24),
                    _buildSectionTitle('Title'),
                    const SizedBox(height: 12),
                    _buildTextField(
                      controller: _titleController,
                      hint: 'e.g., Follow-up call with client',
                      validator: (v) =>
                          v?.isEmpty ?? true ? 'Title is required' : null,
                    ),
                    const SizedBox(height: 24),
                    _buildSectionTitle('Date & Time'),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(child: _buildDatePicker()),
                        const SizedBox(width: 12),
                        Expanded(child: _buildTimePicker()),
                      ],
                    ),
                    const SizedBox(height: 24),
                    _buildSectionTitle('Notes (Optional)'),
                    const SizedBox(height: 12),
                    _buildTextField(
                      controller: _notesController,
                      hint: 'Add any additional notes...',
                      maxLines: 4,
                    ),
                    const SizedBox(height: 32),
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _scheduleActivity,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF6750A4),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: _isLoading
                            ? const CircularProgressIndicator(
                                color: Colors.white,
                              )
                            : const Text(
                                'Schedule Activity',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: Color(0xFF1D1B20),
      ),
    );
  }

  Widget _buildActivityTypeSelector() {
    return Row(
      children: [
        Expanded(
          child: _buildTypeCard(
            'Call',
            Icons.phone_in_talk_rounded,
            'call',
            const Color(0xFFFFF3E0),
            const Color(0xFFF57C00),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildTypeCard(
            'Meeting',
            Icons.event_rounded,
            'meeting',
            const Color(0xFFE3F2FD),
            const Color(0xFF1976D2),
          ),
        ),
      ],
    );
  }

  Widget _buildTypeCard(
    String label,
    IconData icon,
    String value,
    Color bgColor,
    Color iconColor,
  ) {
    final isSelected = _activityType == value;
    return InkWell(
      onTap: () => setState(() => _activityType = value),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? iconColor : const Color(0xFFE0E0E0),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: iconColor, size: 28),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: isSelected ? iconColor : const Color(0xFF79747E),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLeadDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE0E0E0)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<int>(
          isExpanded: true,
          value: _selectedLeadId,
          hint: const Text('Select a lead or opportunity'),
          items: _leads.map((lead) {
            final name = lead['name']?.toString() ?? 'Unnamed';
            final rawPartner = lead['partner_name'];
            final partner = (rawPartner is String) ? rawPartner : '';
            return DropdownMenuItem<int>(
              value: lead['id'],
              child: Text(
                partner.isNotEmpty ? '$name - $partner' : name,
                overflow: TextOverflow.ellipsis,
              ),
            );
          }).toList(),
          onChanged: (value) => setState(() => _selectedLeadId = value),
        ),
      ),
    );
  }

  Widget _buildDatePicker() {
    return InkWell(
      onTap: () async {
        final date = await showDatePicker(
          context: context,
          initialDate: _selectedDate,
          firstDate: DateTime.now(),
          lastDate: DateTime.now().add(const Duration(days: 365)),
        );
        if (date != null) setState(() => _selectedDate = date);
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE0E0E0)),
        ),
        child: Row(
          children: [
            const Icon(Icons.calendar_today, color: Color(0xFF79747E)),
            const SizedBox(width: 12),
            Text(
              DateFormat('MMM dd, yyyy').format(_selectedDate),
              style: const TextStyle(fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimePicker() {
    return InkWell(
      onTap: () async {
        final time = await showTimePicker(
          context: context,
          initialTime: _selectedTime,
        );
        if (time != null) setState(() => _selectedTime = time);
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE0E0E0)),
        ),
        child: Row(
          children: [
            const Icon(Icons.access_time, color: Color(0xFF79747E)),
            const SizedBox(width: 12),
            Text(
              _selectedTime.format(context),
              style: const TextStyle(fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      validator: validator,
      decoration: InputDecoration(
        hintText: hint,
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFF6750A4), width: 2),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _notesController.dispose();
    super.dispose();
  }
}
