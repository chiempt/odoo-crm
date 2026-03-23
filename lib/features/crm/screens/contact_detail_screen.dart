import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/contact_model.dart';
import 'edit_contact_screen.dart';

class ContactDetailScreen extends StatelessWidget {
  final ContactModel contact;

  const ContactDetailScreen({super.key, required this.contact});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FB),
      appBar: AppBar(
        title: const Text('Contact Details'),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF1D1B20),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            onPressed: () async {
              final result = await Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => EditContactScreen(contact: contact),
                ),
              );
              if (result == true) {
                // Return to previous screen (contacts list) and reload if updated
                if (context.mounted) {
                  Navigator.of(context).pop();
                }
              }
            },
            tooltip: 'Edit Contact',
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Container(color: const Color(0xFFEFEFEF), height: 1),
            _buildProfileHeader(context),
            const SizedBox(height: 16),
            _buildActionButtons(context),
            const SizedBox(height: 24),
            _buildInfoCard(context),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileHeader(BuildContext context) {
    return Container(
      color: Colors.white,
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 20),
      child: Column(
        children: [
          CircleAvatar(
            radius: 48,
            backgroundColor: contact.avatarColor,
            child: Text(
              contact.initials,
              style: const TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            contact.name,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1D1B20),
            ),
            textAlign: TextAlign.center,
          ),
          if (contact.company.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              contact.company,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Color(0xFF757575),
              ),
              textAlign: TextAlign.center,
            ),
          ],
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: contact.tagColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              contact.tag,
              style: TextStyle(
                color: contact.tagColor,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _ActionButton(
            label: 'Call',
            icon: Icons.phone,
            color: const Color(0xFF4CAF50),
            onTap: () => _launchAction('tel:${contact.phone}'),
            enabled: contact.phone.isNotEmpty,
          ),
          _ActionButton(
            label: 'Message',
            icon: Icons.message,
            color: const Color(0xFF2196F3),
            onTap: () => _launchAction('sms:${contact.phone}'),
            enabled: contact.phone.isNotEmpty,
          ),
          _ActionButton(
            label: 'Email',
            icon: Icons.email,
            color: const Color(0xFF9C27B0),
            onTap: () => _launchAction('mailto:${contact.email}'),
            enabled: contact.email.isNotEmpty,
          ),
        ],
      ),
    );
  }

  Future<void> _launchAction(String urlString) async {
    final Uri url = Uri.parse(urlString);
    try {
      await launchUrl(url);
    } catch (_) {}
  }

  Widget _buildInfoCard(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        children: [
          _InfoTile(
            icon: Icons.email_outlined,
            title: 'Email Address',
            value: contact.email.isEmpty ? 'Not provided' : contact.email,
          ),
          const Divider(height: 1, indent: 64, color: Color(0xFFF0F0F0)),
          _InfoTile(
            icon: Icons.phone_outlined,
            title: 'Phone Number',
            value: contact.phone.isEmpty ? 'Not provided' : contact.phone,
          ),
          const Divider(height: 1, indent: 64, color: Color(0xFFF0F0F0)),
          _InfoTile(
            icon: Icons.business_outlined,
            title: 'Company',
            value: contact.company.isEmpty ? 'Not provided' : contact.company,
          ),
          const Divider(height: 1, indent: 64, color: Color(0xFFF0F0F0)),
          const _InfoTile(
            icon: Icons.location_on_outlined,
            title: 'Location',
            value: 'Address not provided in Odoo',
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  final bool enabled;

  const _ActionButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Column(
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: enabled
                  ? color.withValues(alpha: 0.1)
                  : const Color(0xFFF5F5F5),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: enabled ? color : const Color(0xFFBDBDBD),
              size: 24,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: enabled
                  ? const Color(0xFF424242)
                  : const Color(0xFF9E9E9E),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;

  const _InfoTile({
    required this.icon,
    required this.title,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: const Color(0xFFF5F5F5),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: const Color(0xFF757575), size: 20),
      ),
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 12,
          color: Color(0xFF9E9E9E),
          fontWeight: FontWeight.w500,
        ),
      ),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 4.0),
        child: Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            color: Color(0xFF1D1B20),
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
    );
  }
}
