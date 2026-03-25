import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/lead_model.dart';
import '../models/lead_form_data.dart';
import '../providers/crm_provider.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Design tokens
// ─────────────────────────────────────────────────────────────────────────────
abstract final class _Tokens {
  static const primary = Color(0xFF5a3d6a);
  static const background = Color(0xFFF5F5F8);
  static const cardBg = Colors.white;
  static const border = Color(0xFFE0E0E0);
  static const label = Color(0xFF888888);
  static const hint = Color(0xFFBBBBBB);
  static const text = Color(0xFF1D1B20);
}

// ─────────────────────────────────────────────────────────────────────────────
// Dropdown options
// ─────────────────────────────────────────────────────────────────────────────
abstract final class _Options {
  static const sources = [
    'Select source...',
    'Website',
    'Email Campaign',
    'Cold Call',
    'Referral',
    'Social Media',
    'Trade Show',
    'Other',
  ];

  static const statuses = [
    'New Lead',
    'Qualified',
    'Proposition',
    'Won',
    'Lost',
  ];

  static const industries = [
    'Select industry...',
    'Technology',
    'Finance',
    'Healthcare',
    'Manufacturing',
    'Retail',
    'Education',
    'Real Estate',
    'Other',
  ];

  static const companySizes = [
    'Select size...',
    '1–10',
    '11–50',
    '51–200',
    '201–500',
    '500+',
  ];

  static const priorityLabels = [
    'No Priority',
    'Low Priority',
    'Medium Priority',
    'High Priority',
    'Critical',
  ];
}

// ─────────────────────────────────────────────────────────────────────────────
// Screen
// ─────────────────────────────────────────────────────────────────────────────
class CreateLeadScreen extends StatefulWidget {
  final Lead? lead;
  final Map<String, String>? initialData;
  const CreateLeadScreen({super.key, this.lead, this.initialData});

  @override
  State<CreateLeadScreen> createState() => _CreateLeadScreenState();
}

class _CreateLeadScreenState extends State<CreateLeadScreen> {
  final _formKey = GlobalKey<FormState>();
  var _data = const LeadFormData();

  // Controllers – only for fields that need external read access
  final _titleCtrl = TextEditingController();
  final _campaignCtrl = TextEditingController();
  final _contactCtrl = TextEditingController();
  final _jobTitleCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _mobileCtrl = TextEditingController();
  final _companyCtrl = TextEditingController();
  final _websiteCtrl = TextEditingController();
  final _streetCtrl = TextEditingController();
  final _cityCtrl = TextEditingController();
  final _stateCtrl = TextEditingController();
  final _zipCtrl = TextEditingController();
  final _countryCtrl = TextEditingController();
  final _revenueCtrl = TextEditingController();
  final _probCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.lead != null) {
      final l = widget.lead!;
      _titleCtrl.text = l.title;
      _contactCtrl.text = l.contactName;
      _emailCtrl.text = l.email;
      _phoneCtrl.text = l.phone;
      _companyCtrl.text = l.company;
      _revenueCtrl.text = l.value.replaceAll(RegExp(r'[^0-9.]'), '');
      _probCtrl.text = l.probability.toString();
      _notesCtrl.text = l.description;

      _data = _data.copyWith(
        priority: l.stars,
        assignTo: l.assignee,
        // map other fields
      );
    } else if (widget.initialData != null) {
      final d = widget.initialData!;
      _contactCtrl.text = d['name'] ?? '';
      _emailCtrl.text = d['email'] ?? '';
      _phoneCtrl.text = d['phone'] ?? '';
      _companyCtrl.text = d['company'] ?? '';
      _notesCtrl.text = d['notes'] ?? '';

      // Auto-set title if empty
      if (_titleCtrl.text.isEmpty && _companyCtrl.text.isNotEmpty) {
        _titleCtrl.text = 'Lead: ${_companyCtrl.text}';
      }
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<CrmProvider>();
      if (provider.users.isEmpty) provider.fetchUsers();
      if (provider.partners.isEmpty) provider.fetchPartners();
    });
  }

  @override
  void dispose() {
    for (final c in [
      _titleCtrl,
      _campaignCtrl,
      _contactCtrl,
      _jobTitleCtrl,
      _emailCtrl,
      _phoneCtrl,
      _mobileCtrl,
      _companyCtrl,
      _websiteCtrl,
      _streetCtrl,
      _cityCtrl,
      _stateCtrl,
      _zipCtrl,
      _countryCtrl,
      _revenueCtrl,
      _probCtrl,
      _notesCtrl,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  // ── Actions ──────────────────────────────────────────────────────────────

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate:
          _data.closeDate ?? DateTime.now().add(const Duration(days: 30)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(primary: _Tokens.primary),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() => _data = _data.copyWith(closeDate: picked));
    }
  }

  void _addTag() async {
    final ctrl = TextEditingController();
    final tag = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Add Tag'),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          decoration: const InputDecoration(hintText: 'Tag name'),
          onSubmitted: (v) => Navigator.pop(context, v.trim()),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, ctrl.text.trim()),
            child: const Text('Add'),
          ),
        ],
      ),
    );
    if (tag != null && tag.isNotEmpty) {
      setState(() => _data = _data.copyWith(tags: [..._data.tags, tag]));
    }
    ctrl.dispose();
  }

  void _removeTag(String tag) => setState(
    () => _data = _data.copyWith(
      tags: _data.tags.where((t) => t != tag).toList(),
    ),
  );

  void _onSave() async {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();

    final crmProvider = context.read<CrmProvider>();

    // Find user id by name
    int? userId;
    final selectedUser = crmProvider.users
        .where((u) => u.name == _data.assignTo)
        .firstOrNull;
    userId = selectedUser?.id;

    // Find partner id by company name
    int? partnerId;
    final selectedPartner = crmProvider.partners
        .where((p) => p.name == _companyCtrl.text.trim())
        .firstOrNull;
    partnerId = selectedPartner?.id;

    final normalizedSource = _data.source == _Options.sources.first
        ? ''
        : _data.source.trim();
    final normalizedCampaign = _campaignCtrl.text.trim();
    final normalizedTags = _data.tags
        .map((t) => t.trim())
        .where((t) => t.isNotEmpty)
        .toSet()
        .toList();

    int? sourceId;
    int? campaignId;
    List<int> tagIds = const [];

    try {
      final results = await Future.wait<dynamic>([
        normalizedSource.isNotEmpty
            ? crmProvider.ensureLeadSourceId(normalizedSource)
            : Future<int?>.value(null),
        normalizedCampaign.isNotEmpty
            ? crmProvider.ensureLeadCampaignId(normalizedCampaign)
            : Future<int?>.value(null),
        normalizedTags.isNotEmpty
            ? crmProvider.ensureLeadTagIds(normalizedTags)
            : Future<List<int>>.value(const []),
      ]);
      sourceId = results[0] as int?;
      campaignId = results[1] as int?;
      tagIds = results[2] as List<int>;
    } catch (e) {
      debugPrint('Resolve lead references error: $e');
    }

    final Map<String, dynamic> odooValues = {
      'name': _titleCtrl.text.trim(),
      'type': 'opportunity', // standard for pipeline leads
      if (partnerId != null) 'partner_id': partnerId,
      if (partnerId == null) 'partner_name': _companyCtrl.text.trim(),
      'contact_name': _contactCtrl.text.trim(),
      'email_from': _emailCtrl.text.trim(),
      'phone': _phoneCtrl.text.trim(),
      'mobile': _mobileCtrl.text.trim(),
      'function': _jobTitleCtrl.text.trim(),
      'website': _websiteCtrl.text.trim(),
      'street': _streetCtrl.text.trim(),
      'city': _cityCtrl.text.trim(),
      'zip': _zipCtrl.text.trim(),
      'description': _notesCtrl.text.trim(),
      'expected_revenue':
          double.tryParse(
            _revenueCtrl.text.trim().replaceAll(RegExp(r'[^0-9.]'), ''),
          ) ??
          0.0,
      'probability': double.tryParse(_probCtrl.text.trim()) ?? 0.0,
      'priority': (_data.priority - 1).clamp(0, 3).toString(),
      if (userId != null) 'user_id': userId,
      if (sourceId != null) 'source_id': sourceId,
      if (campaignId != null) 'campaign_id': campaignId,
      if (tagIds.isNotEmpty)
        'tag_ids': [
          [6, 0, tagIds],
        ],
      if (_data.closeDate != null)
        'date_deadline': _data.closeDate!.toIso8601String().split('T')[0],
    };

    final success = widget.lead == null
        ? await crmProvider.createLead(odooValues)
        : await crmProvider.updateLead(int.parse(widget.lead!.id), odooValues);

    if (mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Lead saved successfully!'),
            backgroundColor: Color(0xFF4CAF50),
          ),
        );
        Navigator.of(context).pop();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(crmProvider.error ?? 'Failed to save lead'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _Tokens.background,
      appBar: _buildAppBar(),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.only(bottom: 40),
          children: [
            _SyncBanner(),
            _Section(
              icon: Icons.trending_up_rounded,
              title: 'Lead Information',
              children: _leadInfoFields(),
            ),
            _Section(
              icon: Icons.person_outline_rounded,
              title: 'Contact Information',
              children: _contactInfoFields(),
            ),
            _Section(
              icon: Icons.business_outlined,
              title: 'Company Information',
              children: _companyInfoFields(),
            ),
            _Section(
              icon: Icons.trending_up_rounded,
              title: 'Deal Information',
              children: _dealInfoFields(),
            ),
            _Section(
              icon: Icons.people_alt_outlined,
              title: 'Assignment',
              children: _assignmentFields(),
            ),
            const SizedBox(height: 8),
            _buildFooter(),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      centerTitle: true,
      leading: TextButton.icon(
        onPressed: () => Navigator.of(context).pop(),
        icon: const Icon(
          Icons.chevron_left_rounded,
          color: _Tokens.primary,
          size: 22,
        ),
        label: const Text(
          'Back',
          style: TextStyle(
            color: _Tokens.primary,
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
      leadingWidth: 100,
      title: const Text(
        'New Lead',
        style: TextStyle(
          color: _Tokens.text,
          fontWeight: FontWeight.w700,
          fontSize: 18,
        ),
      ),
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Divider(height: 1, color: Colors.grey.shade200),
      ),
    );
  }

  // ── Lead Information Fields ───────────────────────────────────────────────

  List<Widget> _leadInfoFields() => [
    _FormField(
      label: 'LEAD/OPPORTUNITY TITLE',
      required: true,
      child: _TextInput(
        controller: _titleCtrl,
        hint: 'e.g. Cloud Migration Services',
        validator: _required('Title'),
      ),
    ),
    _FormField(
      label: 'LEAD SOURCE',
      required: true,
      child: _DropdownField(
        value: _data.source.isEmpty ? _Options.sources.first : _data.source,
        items: _Options.sources,
        onChanged: (v) => setState(() => _data = _data.copyWith(source: v)),
        validator: (v) => v == _Options.sources.first ? 'Required' : null,
      ),
    ),
    _FormField(
      label: 'CAMPAIGN',
      child: _TextInput(
        controller: _campaignCtrl,
        hint: 'e.g. Enterprise Solutions Q4',
      ),
    ),
    _FormField(
      label: 'LEAD STATUS',
      required: true,
      child: _DropdownField(
        value: _data.status,
        items: _Options.statuses,
        onChanged: (v) => setState(() => _data = _data.copyWith(status: v)),
      ),
    ),
    _FormField(
      label: 'TAGS',
      child: _TagsField(tags: _data.tags, onAdd: _addTag, onRemove: _removeTag),
    ),
  ];

  // ── Contact Information Fields ────────────────────────────────────────────

  List<Widget> _contactInfoFields() => [
    _FormField(
      label: 'CONTACT NAME',
      required: true,
      child: _TextInput(
        controller: _contactCtrl,
        hint: 'e.g. John Smith',
        validator: _required('Contact name'),
      ),
    ),
    _FormField(
      label: 'JOB TITLE',
      child: _TextInput(controller: _jobTitleCtrl, hint: 'e.g. IT Director'),
    ),
    _FormField(
      label: 'EMAIL',
      required: true,
      child: _TextInput(
        controller: _emailCtrl,
        hint: 'contact@company.com',
        keyboardType: TextInputType.emailAddress,
        prefixIcon: Icons.mail_outline_rounded,
        validator: _emailValidator,
      ),
    ),
    _FormField(
      label: 'PHONE',
      required: true,
      child: _TextInput(
        controller: _phoneCtrl,
        hint: '+1 (555) 123-4567',
        keyboardType: TextInputType.phone,
        prefixIcon: Icons.phone_outlined,
        validator: _required('Phone'),
      ),
    ),
    _FormField(
      label: 'MOBILE',
      child: _TextInput(
        controller: _mobileCtrl,
        hint: '+1 (555) 987-6543',
        keyboardType: TextInputType.phone,
        prefixIcon: Icons.phone_android_outlined,
      ),
    ),
  ];

  // ── Company Information Fields ────────────────────────────────────────────

  List<Widget> _companyInfoFields() => [
    _FormField(
      label: 'COMPANY NAME',
      required: true,
      child: _TextInput(
        controller: _companyCtrl,
        hint: 'Search or enter company name...',
        suffixIcon: Icons.search_rounded,
        validator: _required('Company name'),
      ),
    ),
    _FormField(
      label: 'INDUSTRY',
      child: _DropdownField(
        value: _data.industry.isEmpty
            ? _Options.industries.first
            : _data.industry,
        items: _Options.industries,
        onChanged: (v) => setState(() => _data = _data.copyWith(industry: v)),
      ),
    ),
    _FormField(
      label: 'COMPANY SIZE',
      child: _DropdownField(
        value: _data.companySize.isEmpty
            ? _Options.companySizes.first
            : _data.companySize,
        items: _Options.companySizes,
        onChanged: (v) =>
            setState(() => _data = _data.copyWith(companySize: v)),
      ),
    ),
    _FormField(
      label: 'WEBSITE',
      child: _TextInput(
        controller: _websiteCtrl,
        hint: 'https://www.company.com',
        keyboardType: TextInputType.url,
      ),
    ),
    _FormField(
      label: 'STREET ADDRESS',
      child: _TextInput(
        controller: _streetCtrl,
        hint: '123 Main Street',
        prefixIcon: Icons.location_on_outlined,
      ),
    ),
    Row(
      children: [
        Expanded(
          child: _FormField(
            label: 'CITY',
            child: _TextInput(controller: _cityCtrl, hint: 'San Francisco'),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _FormField(
            label: 'STATE',
            child: _TextInput(controller: _stateCtrl, hint: 'CA'),
          ),
        ),
      ],
    ),
    Row(
      children: [
        Expanded(
          child: _FormField(
            label: 'ZIP CODE',
            child: _TextInput(
              controller: _zipCtrl,
              hint: '94102',
              keyboardType: TextInputType.number,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _FormField(
            label: 'COUNTRY',
            child: _TextInput(controller: _countryCtrl, hint: 'USA'),
          ),
        ),
      ],
    ),
  ];

  // ── Deal Information Fields ───────────────────────────────────────────────

  List<Widget> _dealInfoFields() => [
    Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: _FormField(
            label: 'EXPECTED REVENUE',
            required: true,
            child: _TextInput(
              controller: _revenueCtrl,
              hint: '\$0.00',
              keyboardType: TextInputType.number,
              validator: _required('Revenue'),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _FormField(
            label: 'PROBABILITY (%)',
            child: _TextInput(
              controller: _probCtrl,
              hint: '0-100',
              keyboardType: TextInputType.number,
            ),
          ),
        ),
      ],
    ),
    _FormField(
      label: 'EXPECTED CLOSE DATE',
      required: true,
      child: _DatePickerField(date: _data.closeDate, onTap: _pickDate),
    ),
    _FormField(
      label: 'PRIORITY LEVEL',
      required: true,
      child: _StarPriorityField(
        value: _data.priority,
        onChanged: (v) => setState(() => _data = _data.copyWith(priority: v)),
      ),
    ),
  ];

  // ── Assignment Fields ─────────────────────────────────────────────────────

  List<Widget> _assignmentFields() {
    final crmProvider = context.watch<CrmProvider>();
    final userOptions = [
      'Select salesperson...',
      ...crmProvider.users.map((u) => u.name),
    ];

    // Safety check: ensure current value exists in options to prevent Dropdown crash
    // This can happen if the users list is still loading or doesn't contain the current assignee
    String currentValue = _data.assignTo;
    if (currentValue.isEmpty || !userOptions.contains(currentValue)) {
      currentValue = userOptions.first;
    }

    return [
      _FormField(
        label: 'ASSIGN TO',
        child: _DropdownField(
          value: currentValue,
          items: userOptions,
          onChanged: (v) {
            if (v != null) {
              setState(() => _data = _data.copyWith(assignTo: v));
            }
          },
        ),
      ),
      _FormField(
        label: 'INTERNAL NOTES & DESCRIPTION',
        child: _TextInput(
          controller: _notesCtrl,
          hint:
              'Briefly describe the lead, key requirements, pain points, and any other relevant information...',
          maxLines: 5,
        ),
      ),
    ];
  }

  // ── Footer ────────────────────────────────────────────────────────────────

  Widget _buildFooter() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton.icon(
              onPressed: _onSave,
              icon: const Icon(Icons.save_alt_rounded, size: 20),
              label: const Text(
                'Save Lead',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: _Tokens.primary,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text(
              'Cancel',
              style: TextStyle(color: _Tokens.label, fontSize: 15),
            ),
          ),
        ],
      ),
    );
  }

  // ── Validators ────────────────────────────────────────────────────────────

  FormFieldValidator<String> _required(String field) =>
      (v) => (v == null || v.trim().isEmpty) ? '$field is required' : null;

  String? _emailValidator(String? v) {
    if (v == null || v.trim().isEmpty) return 'Email is required';
    final emailRx = RegExp(r'^[^@]+@[^@]+\.[^@]+');
    return emailRx.hasMatch(v.trim()) ? null : 'Enter a valid email';
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Reusable UI Components
// ─────────────────────────────────────────────────────────────────────────────

class _SyncBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: const Row(
        children: [
          Icon(Icons.sync_rounded, size: 16, color: _Tokens.primary),
          SizedBox(width: 6),
          Text(
            'SYNCING WITH ODOO ERP',
            style: TextStyle(
              color: _Tokens.primary,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.6,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Section card ─────────────────────────────────────────────────────────────

class _Section extends StatelessWidget {
  final IconData icon;
  final String title;
  final List<Widget> children;

  const _Section({
    required this.icon,
    required this.title,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 12, 12, 0),
      decoration: BoxDecoration(
        color: _Tokens.cardBg,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 18, color: _Tokens.primary),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: _Tokens.text,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            ...children,
          ],
        ),
      ),
    );
  }
}

// ── Form field wrapper (label + content) ─────────────────────────────────────

class _FormField extends StatelessWidget {
  final String label;
  final bool required;
  final Widget child;

  const _FormField({
    required this.label,
    this.required = false,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          RichText(
            text: TextSpan(
              text: label,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: _Tokens.label,
                letterSpacing: 0.5,
              ),
              children: required
                  ? const [
                      TextSpan(
                        text: ' *',
                        style: TextStyle(color: Colors.redAccent),
                      ),
                    ]
                  : [],
            ),
          ),
          const SizedBox(height: 6),
          child,
        ],
      ),
    );
  }
}

// ── Text input ───────────────────────────────────────────────────────────────

class _TextInput extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final TextInputType keyboardType;
  final IconData? prefixIcon;
  final IconData? suffixIcon;
  final int maxLines;
  final FormFieldValidator<String>? validator;

  const _TextInput({
    required this.controller,
    required this.hint,
    this.keyboardType = TextInputType.text,
    this.prefixIcon,
    this.suffixIcon,
    this.maxLines = 1,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      validator: validator,
      style: const TextStyle(fontSize: 14, color: _Tokens.text),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: _Tokens.hint, fontSize: 14),
        prefixIcon: prefixIcon != null
            ? Icon(prefixIcon, size: 18, color: _Tokens.hint)
            : null,
        suffixIcon: suffixIcon != null
            ? Icon(suffixIcon, size: 18, color: _Tokens.hint)
            : null,
        filled: true,
        fillColor: const Color(0xFFF8F8F8),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 12,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: _Tokens.border, width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: _Tokens.border, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: _Tokens.primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Colors.redAccent, width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Colors.redAccent, width: 1.5),
        ),
      ),
    );
  }
}

// ── Dropdown field ────────────────────────────────────────────────────────────

class _DropdownField extends StatelessWidget {
  final String value;
  final List<String> items;
  final ValueChanged<String?> onChanged;
  final FormFieldValidator<String>? validator;

  const _DropdownField({
    required this.value,
    required this.items,
    required this.onChanged,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      initialValue: value,
      validator: validator,
      isExpanded: true,
      icon: const Icon(Icons.keyboard_arrow_down_rounded, color: _Tokens.label),
      style: const TextStyle(fontSize: 14, color: _Tokens.text),
      decoration: InputDecoration(
        filled: true,
        fillColor: const Color(0xFFF8F8F8),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 12,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: _Tokens.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: _Tokens.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: _Tokens.primary, width: 1.5),
        ),
      ),
      items: items
          .map((e) => DropdownMenuItem(value: e, child: Text(e)))
          .toList(),
      onChanged: onChanged,
    );
  }
}

// ── Date picker field ─────────────────────────────────────────────────────────

class _DatePickerField extends StatelessWidget {
  final DateTime? date;
  final VoidCallback onTap;

  const _DatePickerField({required this.date, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final label = date == null
        ? 'mm/dd/yyyy'
        : '${date!.month.toString().padLeft(2, '0')}/'
              '${date!.day.toString().padLeft(2, '0')}/'
              '${date!.year}';
    final isPlaceholder = date == null;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 48,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: const Color(0xFFF8F8F8),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: _Tokens.border),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.calendar_today_outlined,
              size: 16,
              color: _Tokens.hint,
            ),
            const SizedBox(width: 10),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                color: isPlaceholder ? _Tokens.hint : _Tokens.text,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Star priority field ───────────────────────────────────────────────────────

class _StarPriorityField extends StatelessWidget {
  final int value;
  final ValueChanged<int> onChanged;

  const _StarPriorityField({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 4),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(5, (i) {
            final starValue = i + 1;
            return GestureDetector(
              onTap: () => onChanged(starValue),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: Icon(
                  starValue <= value
                      ? Icons.star_rounded
                      : Icons.star_outline_rounded,
                  size: 40,
                  color: starValue <= value
                      ? _Tokens.primary
                      : const Color(0xFFDDDDDD),
                ),
              ),
            );
          }),
        ),
        const SizedBox(height: 8),
        Text(
          _Options.priorityLabels[(value - 1).clamp(0, 4)],
          style: const TextStyle(fontSize: 13, color: _Tokens.label),
        ),
        const SizedBox(height: 4),
      ],
    );
  }
}

// ── Tags field ────────────────────────────────────────────────────────────────

class _TagsField extends StatelessWidget {
  final List<String> tags;
  final VoidCallback onAdd;
  final ValueChanged<String> onRemove;

  // Predefined tag colors cycling
  static const _colors = [
    Color(0xFFE3F2FD), // light blue
    Color(0xFFE8F5E9), // light green
    Color(0xFFFFF3E0), // light orange
    Color(0xFFF3E5F5), // light purple
    Color(0xFFE0F2F1), // light teal
  ];

  static const _textColors = [
    Color(0xFF1565C0),
    Color(0xFF2E7D32),
    Color(0xFFE65100),
    Color(0xFF6A1B9A),
    Color(0xFF00695C),
  ];

  const _TagsField({
    required this.tags,
    required this.onAdd,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        ...tags.asMap().entries.map((entry) {
          final i = entry.key % _colors.length;
          return _TagChip(
            label: entry.value,
            bgColor: _colors[i],
            textColor: _textColors[i],
            onRemove: () => onRemove(entry.value),
          );
        }),
        GestureDetector(
          onTap: onAdd,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              border: Border.all(color: _Tokens.border),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.add, size: 14, color: _Tokens.label),
                SizedBox(width: 4),
                Text(
                  'Add Tag',
                  style: TextStyle(
                    fontSize: 12,
                    color: _Tokens.label,
                    fontWeight: FontWeight.w500,
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

class _TagChip extends StatelessWidget {
  final String label;
  final Color bgColor;
  final Color textColor;
  final VoidCallback onRemove;

  const _TagChip({
    required this.label,
    required this.bgColor,
    required this.textColor,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(left: 12, right: 4, top: 5, bottom: 5),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: textColor,
            ),
          ),
          const SizedBox(width: 4),
          GestureDetector(
            onTap: onRemove,
            child: Icon(Icons.close, size: 14, color: textColor),
          ),
        ],
      ),
    );
  }
}
