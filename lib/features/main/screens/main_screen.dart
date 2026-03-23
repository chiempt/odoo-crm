import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class MainScreen extends StatelessWidget {
  final StatefulNavigationShell navigationShell;

  const MainScreen({super.key, required this.navigationShell});

  static const Color _primaryColor = Color(0xFF5a3d6a);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: BottomAppBar(
        shape: const CircularNotchedRectangle(),
        notchMargin: 8,
        child: Container(
          height: 60,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              _buildNavItem(context, 0, Icons.grid_view_rounded, 'Home'),
              // Pipeline is a root-level route (not a shell branch) → use go()
              _buildPipelineItem(context),
              const SizedBox(width: 40), // Space for FAB icon slot
              // Analytics is now branch index 1, Profile is branch index 2
              _buildNavItem(context, 1, Icons.analytics_outlined, 'Analytics'),
              _buildNavItem(
                context,
                2,
                Icons.person_outline_rounded,
                'Profile',
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {},
        backgroundColor: _primaryColor,
        elevation: 4,
        child: const Icon(Icons.add, color: Colors.white, size: 32),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }

  /// Pipeline nav item navigates to /pipeline (root route, not a shell branch)
  Widget _buildPipelineItem(BuildContext context) {
    final isPipelineActive = GoRouterState.of(
      context,
    ).matchedLocation.startsWith('/pipeline');
    return InkWell(
      onTap: () => context.go('/pipeline'),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.filter_list_rounded,
            color: isPipelineActive ? _primaryColor : Colors.grey,
          ),
          Text(
            'Pipeline',
            style: TextStyle(
              color: isPipelineActive ? _primaryColor : Colors.grey,
              fontSize: 12,
              fontWeight: isPipelineActive
                  ? FontWeight.bold
                  : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem(
    BuildContext context,
    int index,
    IconData icon,
    String label,
  ) {
    final isSelected = navigationShell.currentIndex == index;
    return InkWell(
      onTap: () => navigationShell.goBranch(index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected
              ? _primaryColor.withValues(alpha: 0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TweenAnimationBuilder<double>(
              tween: Tween<double>(begin: 0.8, end: isSelected ? 1.2 : 1.0),
              duration: const Duration(milliseconds: 300),
              builder: (context, scale, child) {
                return Transform.scale(
                  scale: scale,
                  child: Icon(
                    icon,
                    color: isSelected ? _primaryColor : Colors.grey,
                  ),
                );
              },
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? _primaryColor : Colors.grey,
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
