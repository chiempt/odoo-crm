import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'leads_screen.dart';
import 'contacts_screen.dart';
import 'deals_screen.dart';
import 'crm_settings_screen.dart';
import 'create_lead_screen.dart';
import 'create_contact_screen.dart';

class CrmShell extends StatefulWidget {
  final int initialIndex;

  const CrmShell({super.key, this.initialIndex = 2});

  @override
  State<CrmShell> createState() => _CrmShellState();
}

class _CrmShellState extends State<CrmShell> {
  late int _currentIndex;

  static const Color _primaryColor = Color(0xFF5a3d6a);

  final List<Widget> _screens = [
    const _HomeTab(),
    const ContactsScreen(),
    const LeadsScreen(),
    const DealsScreen(),
    const CrmSettingsScreen(),
  ];

  @override
  void initState() {
    super.initState();
    if (widget.initialIndex < 0) {
      _currentIndex = 0;
    } else if (widget.initialIndex >= _screens.length) {
      _currentIndex = _screens.length - 1;
    } else {
      _currentIndex = widget.initialIndex;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: _screens),
      bottomNavigationBar: _buildBottomNav(),
      floatingActionButton: _buildFab(),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }

  Widget _buildFab() {
    return FloatingActionButton(
      onPressed: _onFabPressed,
      backgroundColor: _primaryColor,
      elevation: 6,
      shape: const CircleBorder(),
      child: const Icon(Icons.add, color: Colors.white, size: 28),
    );
  }

  void _onFabPressed() {
    switch (_currentIndex) {
      case 1: // Contacts
        Navigator.of(context).push(
          MaterialPageRoute<void>(builder: (_) => const CreateContactScreen()),
        );
        break;
      case 2: // Leads → open CreateLeadScreen
        Navigator.of(context).push(
          MaterialPageRoute<void>(builder: (_) => const CreateLeadScreen()),
        );
        break;
      case 3: // Deals
        Navigator.of(context).push(
          MaterialPageRoute<void>(builder: (_) => const CreateLeadScreen()),
        );
        break;
      default:
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Create new item')));
    }
  }

  Widget _buildBottomNav() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        child: SizedBox(
          height: 62,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _NavItem(
                icon: Icons.home_outlined,
                activeIcon: Icons.home,
                label: 'Home',
                index: 0,
                currentIndex: _currentIndex,
                onTap: _onNavTap,
                primaryColor: _primaryColor,
              ),
              _NavItem(
                icon: Icons.contacts_outlined,
                activeIcon: Icons.contacts,
                label: 'CONTACTS',
                index: 1,
                currentIndex: _currentIndex,
                onTap: _onNavTap,
                primaryColor: _primaryColor,
              ),
              _NavItem(
                icon: Icons.filter_list_rounded,
                activeIcon: Icons.filter_list_rounded,
                label: 'LEADS',
                index: 2,
                currentIndex: _currentIndex,
                onTap: _onNavTap,
                primaryColor: _primaryColor,
              ),
              _NavItem(
                icon: Icons.handshake_outlined,
                activeIcon: Icons.handshake,
                label: 'Deals',
                index: 3,
                currentIndex: _currentIndex,
                onTap: _onNavTap,
                primaryColor: _primaryColor,
              ),
              _NavItem(
                icon: Icons.settings_outlined,
                activeIcon: Icons.settings,
                label: 'SETTINGS',
                index: 4,
                currentIndex: _currentIndex,
                onTap: _onNavTap,
                primaryColor: _primaryColor,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _onNavTap(int index) {
    if (index == 0) {
      // Home → Navigate back to main dashboard
      context.go('/');
      return;
    }
    setState(() => _currentIndex = index);
  }
}

// Placeholder Home tab inside CRM (redirects to main)
class _HomeTab extends StatelessWidget {
  const _HomeTab();

  @override
  Widget build(BuildContext context) {
    return const SizedBox.shrink();
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final int index;
  final int currentIndex;
  final ValueChanged<int> onTap;
  final Color primaryColor;

  const _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.index,
    required this.currentIndex,
    required this.onTap,
    required this.primaryColor,
  });

  @override
  Widget build(BuildContext context) {
    final isSelected = currentIndex == index;
    return GestureDetector(
      onTap: () => onTap(index),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: Icon(
                isSelected ? activeIcon : icon,
                key: ValueKey(isSelected),
                color: isSelected ? primaryColor : const Color(0xFF9E9E9E),
                size: 22,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? primaryColor : const Color(0xFF9E9E9E),
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                letterSpacing: 0.3,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
