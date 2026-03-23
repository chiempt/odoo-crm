import 'package:flutter/material.dart';

class TopPerformers extends StatelessWidget {
  const TopPerformers({super.key});

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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(
                    Icons.emoji_events_outlined,
                    color: Color(0xFFFBC02D),
                    size: 20,
                  ),
                  SizedBox(width: 8),
                  Text(
                    'Top Performers',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1D1B20),
                    ),
                  ),
                ],
              ),
              Text(
                'This Week',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _buildPerformer(
            rank: 1,
            name: 'Alex Rivera',
            revenue: '\$248,500',
            visits: 12,
            deals: 4,
            winRate: '98%',
            image: 'https://i.pravatar.cc/150?u=alex_rivera',
            isTop: true,
          ),
          const SizedBox(height: 12),
          _buildPerformer(
            rank: 2,
            name: 'Sarah Jenkins',
            revenue: '\$187,200',
            visits: 10,
            deals: 3,
            winRate: '92%',
            image: 'https://i.pravatar.cc/150?u=sarah_jenkins',
          ),
          const SizedBox(height: 12),
          _buildPerformer(
            rank: 3,
            name: 'Michael Chen',
            revenue: '\$165,400',
            visits: 8,
            deals: 3,
            winRate: '85%',
            image: 'https://i.pravatar.cc/150?u=michael_chen',
          ),
        ],
      ),
    );
  }

  Widget _buildPerformer({
    required int rank,
    required String name,
    required String revenue,
    required int visits,
    required int deals,
    required String winRate,
    required String image,
    bool isTop = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isTop ? const Color(0xFFFFD54F) : const Color(0xFFF0F0F0),
          width: isTop ? 2 : 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: isTop ? const Color(0xFFFFD54F) : const Color(0xFFE0E0E0),
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text(
              '$rank',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: isTop ? Colors.black87 : Colors.grey.shade700,
              ),
            ),
          ),
          const SizedBox(width: 12),
          CircleAvatar(radius: 20, backgroundImage: NetworkImage(image)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1D1B20),
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    _buildIconStat(Icons.location_on_outlined, '$visits'),
                    const SizedBox(width: 8),
                    _buildIconStat(Icons.check_circle_outline, '$deals'),
                    const SizedBox(width: 8),
                    _buildWinRate(winRate),
                  ],
                ),
              ],
            ),
          ),
          Text(
            revenue,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: Color(0xFF5a3d6a),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIconStat(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 12, color: Colors.grey.shade500),
        const SizedBox(width: 2),
        Text(text, style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
      ],
    );
  }

  Widget _buildWinRate(String rate) {
    return Row(
      children: [
        const Icon(Icons.trending_up, size: 12, color: Colors.green),
        const SizedBox(width: 2),
        Text(
          rate,
          style: const TextStyle(
            fontSize: 11,
            color: Colors.green,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
