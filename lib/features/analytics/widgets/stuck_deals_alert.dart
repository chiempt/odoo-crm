import 'package:flutter/material.dart';

class StuckDealsAlert extends StatelessWidget {
  const StuckDealsAlert({super.key});

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
                    Icons.warning_amber_rounded,
                    color: Color(0xFFF57C00),
                    size: 20,
                  ),
                  SizedBox(width: 8),
                  Text(
                    'Stuck Deals Alert',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1D1B20),
                    ),
                  ),
                ],
              ),
              TextButton(
                onPressed: () {},
                child: const Text(
                  'View All',
                  style: TextStyle(fontSize: 12, color: Color(0xFF5a3d6a)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF3E0),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFFFCCbc)),
            ),
            child: const Row(
              children: [
                Icon(Icons.access_time, size: 16, color: Color(0xFFE65100)),
                SizedBox(width: 8),
                Text(
                  '4 deals stuck for 35+ days',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFFE65100),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          _buildDealItem(
            company: 'Acme Corporation',
            stage: 'Proposal',
            owner: 'Alex Rivera',
            amount: '\$125,000',
            days: '45 days',
            lastAction: 'Sent proposal',
            probability: '65%',
          ),
          _buildDivider(),
          _buildDealItem(
            company: 'Global Tech Inc',
            stage: 'Negotiation',
            owner: 'Sarah Jenkins',
            amount: '\$89,500',
            days: '38 days',
            lastAction: 'Price discussion',
            probability: '70%',
          ),
          const SizedBox(height: 16),
          Center(
            child: Text(
              '+ 1 more stuck deals',
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey.shade500,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDealItem({
    required String company,
    required String stage,
    required String owner,
    required String amount,
    required String days,
    required String lastAction,
    required String probability,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              company,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1D1B20),
              ),
            ),
            Text(
              amount,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: Color(0xFF1D1B20),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '$stage • $owner',
              style: const TextStyle(fontSize: 12, color: Color(0xFF757575)),
            ),
            Text(
              probability,
              style: const TextStyle(fontSize: 12, color: Color(0xFF757575)),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              lastAction,
              style: const TextStyle(fontSize: 13, color: Color(0xFF9E9E9E)),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF3E0),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                days,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFE65100),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDivider() {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 16),
      height: 1,
      color: const Color(0xFFF5F5F5),
    );
  }
}
