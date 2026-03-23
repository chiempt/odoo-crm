import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/contact_model.dart';
import '../providers/contact_provider.dart';

class EditContactScreen extends StatefulWidget {
  final ContactModel contact;

  const EditContactScreen({super.key, required this.contact});

  @override
  State<EditContactScreen> createState() => _EditContactScreenState();
}

class _EditContactScreenState extends State<EditContactScreen> {
  final _formKey = GlobalKey<FormState>();
  
  late String _name;
  late String _email;
  late String _phone;
  late bool _isCompany;
  
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _name = widget.contact.name;
    _email = widget.contact.email;
    _phone = widget.contact.phone;
    _isCompany = widget.contact.tag == 'Company';
  }

  Future<void> _saveContact() async {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();

    setState(() => _isSaving = true);
    final provider = context.read<ContactProvider>();
    
    final success = await provider.updateContact(
      id: widget.contact.id,
      name: _name.trim(),
      isCompany: _isCompany,
      email: _email.trim(),
      phone: _phone.trim(),
    );

    setState(() => _isSaving = false);
    
    if (success && mounted) {
      Navigator.of(context).pop(true); // Return true to indicate success
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Contact updated successfully!'), backgroundColor: Colors.green),
      );
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${provider.error ?? "Failed to update"}'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FB),
      appBar: AppBar(
        title: const Text('Edit Contact', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF1D1B20),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Container(color: const Color(0xFFEFEFEF), height: 1),
            Padding(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildTypeSelector(),
                    const SizedBox(height: 24),
                    _buildTextField(
                      label: _isCompany ? 'Company Name' : 'Full Name',
                      icon: Icons.person_outline,
                      initialValue: _name,
                      onSaved: (val) => _name = val ?? '',
                      validator: (val) => val == null || val.trim().isEmpty ? 'Please enter a name' : null,
                    ),
                    const SizedBox(height: 20),
                    _buildTextField(
                      label: 'Email',
                      icon: Icons.email_outlined,
                      initialValue: _email,
                      keyboardType: TextInputType.emailAddress,
                      onSaved: (val) => _email = val ?? '',
                    ),
                    const SizedBox(height: 20),
                    _buildTextField(
                      label: 'Phone number',
                      icon: Icons.phone_outlined,
                      initialValue: _phone,
                      keyboardType: TextInputType.phone,
                      onSaved: (val) => _phone = val ?? '',
                    ),
                    const SizedBox(height: 48),
                    SizedBox(
                      height: 54,
                      child: ElevatedButton(
                        onPressed: _isSaving ? null : _saveContact,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF5a3d6a),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          elevation: 0,
                        ),
                        child: _isSaving
                            ? const CircularProgressIndicator(color: Colors.white)
                            : const Text('Save Changes', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTypeSelector() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFFEFEFEF),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _isCompany = false),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: !_isCompany ? Colors.white : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: !_isCompany
                      ? [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 4, offset: const Offset(0, 2))]
                      : [],
                ),
                child: Text(
                  'Individual',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontWeight: !_isCompany ? FontWeight.bold : FontWeight.w500,
                    color: !_isCompany ? const Color(0xFF5a3d6a) : const Color(0xFF757575),
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _isCompany = true),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: _isCompany ? Colors.white : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: _isCompany
                      ? [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 4, offset: const Offset(0, 2))]
                      : [],
                ),
                child: Text(
                  'Company',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontWeight: _isCompany ? FontWeight.bold : FontWeight.w500,
                    color: _isCompany ? const Color(0xFF5a3d6a) : const Color(0xFF757575),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required String label,
    required IconData icon,
    String? initialValue,
    TextInputType? keyboardType,
    void Function(String?)? onSaved,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      initialValue: initialValue,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: const Color(0xFF9E9E9E)),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF5a3d6a), width: 2),
        ),
      ),
      keyboardType: keyboardType,
      validator: validator,
      onSaved: onSaved,
    );
  }
}
