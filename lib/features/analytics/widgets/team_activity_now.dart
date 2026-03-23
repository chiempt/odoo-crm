import 'package:flutter/material.dart';

class TeamActivityNow extends StatelessWidget {
  const TeamActivityNow({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.bolt_rounded, color: Color(0xFF5a3d6a), size: 18),
                  SizedBox(width: 8),
                  Text(
                    'Team Activity Now',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1D1B20),
                    ),
                  ),
                ],
              ),
              Text(
                '3/5 Active',
                style: TextStyle(
                  fontSize: 12,
                  color: Color(0xFF757575),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          _buildActivityItem(
            name: 'Alex Rivera',
            activity: 'Check-in at Acme Corp',
            time: '5 mins ago',
            location: 'New York, NY',
            visits: 3,
            deals: 5,
            image: 'https://i.pravatar.cc/150?u=alex_rivera',
            statusColor: Colors.green,
            isOnline: true,
          ),
          _buildDivider(),
          _buildActivityItem(
            name: 'Sarah Jenkins',
            activity: 'Meeting with TechStart',
            time: '12 mins ago',
            location: 'San Francisco, CA',
            visits: 2,
            deals: 4,
            image: 'https://i.pravatar.cc/150?u=sarah_jenkins',
            statusColor: Colors.green,
            isOnline: true,
          ),
          _buildDivider(),
          _buildActivityItem(
            name: 'Michael Chen',
            activity: 'Creating proposal',
            time: '8 mins ago',
            location: 'Boston, MA',
            visits: 1,
            deals: 3,
            image: 'https://i.pravatar.cc/150?u=michael_chen',
            statusColor: Colors.green,
            isOnline: true,
          ),
        ],
      ),
    );
  }

  Widget _buildActivityItem({
    required String name,
    required String activity,
    required String time,
    required String location,
    required int visits,
    required int deals,
    required String image,
    required Color statusColor,
    required bool isOnline,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  image: DecorationImage(
                    image: NetworkImage(image),
                    fit: BoxFit.cover,
                  ),
                  border: Border.all(color: const Color(0xFFF0F0F0), width: 2),
                ),
              ),
              Positioned(
                right: 0,
                bottom: 0,
                child: Container(
                  width: 14,
                  height: 14,
                  decoration: BoxDecoration(
                    color: statusColor,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1D1B20),
                      ),
                    ),
                    Text(
                      time,
                      style: const TextStyle(
                        fontSize: 11,
                        color: Color(0xFF9E9E9E),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  activity,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF757575),
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    _buildSubStat(Icons.location_on_outlined, location),
                    const SizedBox(width: 8),
                    _buildSubStat(Icons.location_city_outlined, '$visits'),
                    const SizedBox(width: 8),
                    _buildSubStat(Icons.check_circle_outline, '$deals'),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubStat(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 12, color: const Color(0xFF9E9E9E)),
        const SizedBox(width: 2),
        Text(
          text,
          style: const TextStyle(
            fontSize: 11,
            color: Color(0xFF9E9E9E),
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildDivider() {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 12),
      height: 1,
      color: const Color(0xFFF5F5F5),
    );
  }
}
