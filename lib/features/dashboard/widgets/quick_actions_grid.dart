import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class QuickActionsGrid extends StatelessWidget {
  const QuickActionsGrid({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 20),
          child: Text(
            'Quick Actions',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1D1B20),
            ),
          ),
        ),
        const SizedBox(height: 12),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 1.6,
          children: [
            _buildActionCard(
              context,
              'Add New',
              Icons.add_circle_rounded,
              const Color(0xFFE3F2FD),
              const Color(0xFF1976D2),
              () => _showAddNewSheet(context),
            ),
            _buildActionCard(
              context,
              'Schedule Call',
              Icons.phone_in_talk_rounded,
              const Color(0xFFFFF3E0),
              const Color(0xFFF57C00),
              () => context.push('/dashboard/calls'),
            ),
            _buildActionCard(
              context,
              'Smart Scan',
              Icons.qr_code_scanner_rounded,
              const Color(0xFFEDE7F6),
              const Color(0xFF673AB7),
              () => context.push('/dashboard/smart-scan'),
            ),
            _buildActionCard(
              context,
              'Analytics',
              Icons.bar_chart_rounded,
              const Color(0xFFE8F5E9),
              const Color(0xFF388E3C),
              () => context.go('/analytics'),
            ),
          ],
        ),
      ],
    );
  }

  Future<void> _showAddNewSheet(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Add New',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1D1B20),
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Choose what you want to create from Home.',
                  style: TextStyle(color: Color(0xFF6B7280)),
                ),
                const SizedBox(height: 16),
                _buildAddNewOption(
                  context: context,
                  label: 'Lead',
                  icon: Icons.person_add_alt_1_rounded,
                  color: const Color(0xFF1976D2),
                  onTap: () {
                    Navigator.of(sheetContext).pop();
                    context.push('/crm/create-lead');
                  },
                ),
                const SizedBox(height: 10),
                _buildAddNewOption(
                  context: context,
                  label: 'Contact',
                  icon: Icons.contacts_rounded,
                  color: const Color(0xFF7E57C2),
                  onTap: () {
                    Navigator.of(sheetContext).pop();
                    context.push('/pipeline?tab=contacts');
                  },
                ),
                const SizedBox(height: 10),
                _buildAddNewOption(
                  context: context,
                  label: 'Deal',
                  icon: Icons.handshake_rounded,
                  color: const Color(0xFF16A34A),
                  onTap: () {
                    Navigator.of(sheetContext).pop();
                    context.push('/pipeline?tab=deals');
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildAddNewOption({
    required BuildContext context,
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Ink(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFE5E7EB)),
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1D1B20),
                ),
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: Color(0xFF9CA3AF)),
          ],
        ),
      ),
    );
  }

  Widget _buildActionCard(
    BuildContext context,
    String label,
    IconData icon,
    Color bgColor,
    Color iconColor,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
          border: Border.all(color: const Color(0xFFF5F5F5)),
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: iconColor, size: 24),
            ),
            Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1D1B20),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
