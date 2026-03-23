import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/lead_model.dart';
import '../../providers/crm_provider.dart';

class FollowersSheet extends StatefulWidget {
  final Lead lead;

  const FollowersSheet({super.key, required this.lead});

  static Future<void> show(BuildContext context, Lead lead) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => FollowersSheet(lead: lead),
    );
  }

  @override
  State<FollowersSheet> createState() => _FollowersSheetState();
}

class _FollowersSheetState extends State<FollowersSheet> {
  final TextEditingController _searchCtrl = TextEditingController();
  List<CrmPartner> _searchResults = [];

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _searchPartners(String query) async {
    if (query.isEmpty) {
      setState(() {
        _searchResults = [];
      });
      return;
    }

    final provider = context.read<CrmProvider>();
    final matches = provider.partners
        .where((p) => p.name.toLowerCase().contains(query.toLowerCase()))
        .toList();

    setState(() {
      _searchResults = matches;
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<CrmProvider>();
    final lead = provider.leads.firstWhere(
      (l) => l.id == widget.lead.id,
      orElse: () => widget.lead,
    );

    final List<LeadFollower> followers = lead.followers;
    final int followerCount = followers.length;

    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          const SizedBox(height: 12),
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Followers',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                Text(
                  '$followerCount total',
                  style: TextStyle(color: Colors.grey[600], fontSize: 13),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: TextField(
              controller: _searchCtrl,
              onChanged: _searchPartners,
              decoration: InputDecoration(
                hintText: 'Add followers...',
                prefixIcon: const Icon(Icons.person_add_outlined, size: 20),
                filled: true,
                fillColor: Colors.grey[100],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
              ),
            ),
          ),
          const SizedBox(height: 8),
          if (_searchCtrl.text.isNotEmpty)
            Expanded(
              child: ListView.builder(
                itemCount: _searchResults.length,
                itemBuilder: (context, index) {
                  final partner = _searchResults[index];
                  final isAlreadyFollowing = lead.followers.any(
                    (f) => f.partnerId == partner.id,
                  );

                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Colors
                          .primaries[partner.id % Colors.primaries.length],
                      child: Text(
                        partner.name[0].toUpperCase(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                        ),
                      ),
                    ),
                    title: Text(
                      partner.name,
                      style: const TextStyle(fontSize: 14),
                    ),
                    trailing: isAlreadyFollowing
                        ? const Icon(Icons.check_circle, color: Colors.green)
                        : TextButton(
                            onPressed: () async {
                              final success = await provider.addFollower(
                                int.parse(lead.id),
                                partner.id,
                              );
                              if (success) {
                                provider.fetchLeadById(int.parse(lead.id));
                                _searchCtrl.clear();
                                setState(() => _searchResults = []);
                              }
                            },
                            child: const Text('Add'),
                          ),
                  );
                },
              ),
            )
          else
            Expanded(
              child: ListView.builder(
                itemCount: followers.length,
                itemBuilder: (context, index) {
                  final f = followers[index];
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Colors
                          .primaries[f.partnerId % Colors.primaries.length],
                      radius: 18,
                      child: Text(
                        f.name[0].toUpperCase(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    title: Text(f.name, style: const TextStyle(fontSize: 14)),
                    trailing: IconButton(
                      icon: const Icon(
                        Icons.delete_outline,
                        color: Colors.redAccent,
                        size: 20,
                      ),
                      onPressed: () async {
                        final success = await provider.removeFollower(
                          int.parse(lead.id),
                          f.partnerId,
                        );
                        if (success) {
                          provider.fetchLeadById(int.parse(lead.id));
                        }
                      },
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}
