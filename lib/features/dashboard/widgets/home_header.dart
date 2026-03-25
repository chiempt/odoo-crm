import 'package:flutter/material.dart';

class HomeHeader extends StatelessWidget {
  final String userName;
  final String? profileImageUrl;
  final int? userUid;
  final Map<String, String>? authHeaders;
  final VoidCallback onLogout;

  const HomeHeader({
    super.key,
    required this.userName,
    this.profileImageUrl,
    this.userUid,
    this.authHeaders,
    required this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    final String imageUrl =
        profileImageUrl ??
        (userUid != null
            ? '/web/image?model=res.users&id=$userUid&field=avatar_128'
            : 'https://ui-avatars.com/api/?name=$userName&background=random');

    // Only apply headers if it's an Odoo URL (doesn't contain ui-avatars.com)
    final bool isOdooUrl = !imageUrl.contains('ui-avatars.com');

    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: Color(0xFF5a3d6a),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
      ),
      padding: const EdgeInsets.fromLTRB(20, 60, 20, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.2),
                ),
                child: ClipOval(
                  child: Image.network(
                    imageUrl,
                    headers: isOdooUrl ? authHeaders : null,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Center(
                        child: Text(
                          userName.isNotEmpty ? userName[0].toUpperCase() : '?',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 20,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Welcome back,',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.white.withValues(alpha: 0.7),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    userName,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
              const Spacer(),
              _buildIconAction(Icons.search_rounded, () {}),
              const SizedBox(width: 8),
              _buildIconAction(
                Icons.notifications_none_rounded,
                onLogout,
                hasBadge: true,
              ),
            ],
          ),
          const SizedBox(height: 24),
          _buildQuickSearch(),
        ],
      ),
    );
  }

  Widget _buildIconAction(
    IconData icon,
    VoidCallback onTap, {
    bool hasBadge = false,
  }) {
    return Stack(
      children: [
        Container(
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: IconButton(
            onPressed: onTap,
            padding: const EdgeInsets.all(8),
            constraints: const BoxConstraints(),
            icon: Icon(icon, color: Colors.white, size: 22),
          ),
        ),
        if (hasBadge)
          Positioned(
            right: 4,
            top: 4,
            child: Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: Colors.redAccent,
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFF5a3d6a), width: 1.5),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildQuickSearch() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(
            Icons.search_rounded,
            size: 20,
            color: Colors.white.withValues(alpha: 0.5),
          ),
          const SizedBox(width: 12),
          Text(
            'Search leads, contacts, tasks...',
            style: TextStyle(
              fontSize: 15,
              color: Colors.white.withValues(alpha: 0.5),
            ),
          ),
        ],
      ),
    );
  }
}
