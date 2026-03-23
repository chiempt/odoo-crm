import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Represents a single activity (task/reminder) linked to a deal.
class DealActivity {
  final String title;
  final String description;
  final IconData icon;
  final Color iconBgColor;
  final String dueLabel; // e.g. "Due Tomorrow"
  final Color dueLabelColor;

  const DealActivity({
    required this.title,
    required this.description,
    required this.icon,
    required this.iconBgColor,
    required this.dueLabel,
    required this.dueLabelColor,
  });

  factory DealActivity.fromOdooActivity(Map<String, dynamic> json) {
    final state = json['state'] ?? 'planned';
    final dateDeadline = json['date_deadline'];
    
    Color dueLabelColor;
    String dueLabel;
    
    if (state == 'overdue') {
      dueLabelColor = const Color(0xFFE53935);
      dueLabel = 'OVERDUE';
    } else if (state == 'today') {
      dueLabelColor = const Color(0xFFF57C00);
      dueLabel = 'DUE TODAY';
    } else {
      dueLabelColor = const Color(0xFF4CAF50);
      if (dateDeadline != null) {
        try {
          final date = DateTime.parse(dateDeadline);
          final now = DateTime.now();
          final diff = date.difference(now).inDays;
          if (diff == 1) {
            dueLabel = 'DUE TOMORROW';
            dueLabelColor = const Color(0xFFF57C00);
          } else if (diff > 1) {
            dueLabel = 'DUE IN $diff DAYS';
          } else {
            dueLabel = 'DUE SOON';
          }
        } catch (e) {
          dueLabel = 'SCHEDULED';
        }
      } else {
        dueLabel = 'SCHEDULED';
      }
    }

    return DealActivity(
      title: json['summary'] ?? 'Activity',
      description: json['note'] ?? '',
      icon: Icons.calendar_today_rounded,
      iconBgColor: const Color(0xFFEDE7F6),
      dueLabel: dueLabel,
      dueLabelColor: dueLabelColor,
    );
  }
}

/// Represents a single entry in the activity history timeline.
class DealHistoryEntry {
  final String description;
  final String timeAgo;
  final String author;
  final Color dotColor;

  const DealHistoryEntry({
    required this.description,
    required this.timeAgo,
    required this.author,
    required this.dotColor,
  });

  factory DealHistoryEntry.fromOdooMessage(Map<String, dynamic> json) {
    final date = json['date'];
    String timeAgo = 'RECENTLY';
    
    if (date != null) {
      try {
        final messageDate = DateTime.parse(date);
        final now = DateTime.now();
        final diff = now.difference(messageDate);
        
        if (diff.inDays > 0) {
          timeAgo = '${diff.inDays} DAY${diff.inDays > 1 ? 'S' : ''} AGO';
        } else if (diff.inHours > 0) {
          timeAgo = '${diff.inHours} HOUR${diff.inHours > 1 ? 'S' : ''} AGO';
        } else if (diff.inMinutes > 0) {
          timeAgo = '${diff.inMinutes} MIN AGO';
        } else {
          timeAgo = 'JUST NOW';
        }
      } catch (e) {
        timeAgo = 'RECENTLY';
      }
    }

    String authorName = 'SYSTEM';
    if (json['author_id'] is List && (json['author_id'] as List).length > 1) {
      authorName = (json['author_id'][1] as String).toUpperCase();
    }

    return DealHistoryEntry(
      description: _stripHtml(json['body'] ?? 'Activity logged'),
      timeAgo: timeAgo,
      author: authorName,
      dotColor: const Color(0xFF2196F3),
    );
  }

  static String _stripHtml(String html) {
    return html
        .replaceAll(RegExp(r'<[^>]*>'), '')
        .replaceAll('&nbsp;', ' ')
        .replaceAll('&amp;', '&')
        .trim();
  }
}

/// Full deal model with all fields needed for list and detail views.
class Deal {
  final String id;
  final String title;
  final String company;
  final String value; // display string e.g. "$45,000.00"
  final String stage; // "New" | "Qualified" | "Proposal" | "Negotiation" | "Won"
  final int probability; // 0–100
  final Color avatarColor;
  final String initials;
  final int daysLeft;

  // Detail-only fields
  final String contactName;
  final String contactTitle;
  final String closingDate;
  final String salesperson;
  final String notes;
  final DealActivity? activity;
  final List<DealHistoryEntry> history;

  const Deal({
    required this.id,
    required this.title,
    required this.company,
    required this.value,
    required this.stage,
    required this.probability,
    required this.avatarColor,
    required this.initials,
    required this.daysLeft,
    this.contactName = '',
    this.contactTitle = '',
    this.closingDate = '',
    this.salesperson = '',
    this.notes = '',
    this.activity,
    this.history = const [],
  });

  /// Create Deal from Odoo CRM Lead/Opportunity
  factory Deal.fromOdoo(Map<String, dynamic> json) {
    final id = json['id']?.toString() ?? '0';
    final name = json['name'] ?? 'Untitled Deal';
    
    // Partner/Company name
    String company = '';
    if (json['partner_name'] != null && json['partner_name'] != false) {
      company = json['partner_name'];
    } else if (json['partner_id'] is List && (json['partner_id'] as List).length > 1) {
      company = json['partner_id'][1];
    } else {
      company = 'No Company';
    }

    // Expected revenue
    final rawRevenue = json['expected_revenue'];
    final revenue = (rawRevenue is num) ? rawRevenue.toDouble() : 0.0;
    final currencyFormat = NumberFormat.currency(symbol: '\$', decimalDigits: 2);
    final value = currencyFormat.format(revenue);

    // Stage
    String stage = 'New';
    if (json['stage_id'] is List && (json['stage_id'] as List).length > 1) {
      stage = json['stage_id'][1];
    }

    // Probability
    final probValue = json['probability'];
    final probability = (probValue is num) ? probValue.toInt() : 0;

    // Contact name
    String contactName = (json['contact_name'] is String) ? json['contact_name'] : '';
    if (contactName.isEmpty && json['partner_id'] is List && (json['partner_id'] as List).length > 1) {
      contactName = (json['partner_id'] as List)[1].toString();
    }

    // Salesperson
    String salesperson = '';
    if (json['user_id'] is List && (json['user_id'] as List).length > 1) {
      salesperson = (json['user_id'] as List)[1].toString();
    }

    // Closing date
    String closingDate = '';
    final rawDeadline = json['date_deadline'];
    if (rawDeadline is String && rawDeadline.isNotEmpty) {
      try {
        final date = DateTime.parse(rawDeadline);
        closingDate = DateFormat('MMM dd, yyyy').format(date);
      } catch (e) {
        closingDate = rawDeadline;
      }
    }

    // Days left
    int daysLeft = 0;
    if (rawDeadline is String && rawDeadline.isNotEmpty) {
      try {
        final deadline = DateTime.parse(rawDeadline);
        final now = DateTime.now();
        daysLeft = deadline.difference(now).inDays;
      } catch (e) {
        daysLeft = 0;
      }
    }

    // Generate initials and color
    final initials = _generateInitials(contactName.isNotEmpty ? contactName : company);
    final avatarColor = _generateColor(id);

    return Deal(
      id: id,
      title: name,
      company: company,
      value: value,
      stage: stage,
      probability: probability,
      avatarColor: avatarColor,
      initials: initials,
      daysLeft: daysLeft,
      contactName: contactName,
      contactTitle: (json['title'] is String) ? json['title'] as String : '',
      closingDate: closingDate,
      salesperson: salesperson,
      notes: (json['description'] is String) ? json['description'] as String : '',
    );
  }

  /// Create Deal with activities and history
  Deal copyWithDetails({
    DealActivity? activity,
    List<DealHistoryEntry>? history,
  }) {
    return Deal(
      id: id,
      title: title,
      company: company,
      value: value,
      stage: stage,
      probability: probability,
      avatarColor: avatarColor,
      initials: initials,
      daysLeft: daysLeft,
      contactName: contactName,
      contactTitle: contactTitle,
      closingDate: closingDate,
      salesperson: salesperson,
      notes: notes,
      activity: activity ?? this.activity,
      history: history ?? this.history,
    );
  }

  /// Convert Deal to Odoo format for create/update
  Map<String, dynamic> toOdoo() {
    return {
      'name': title,
      'partner_name': company,
      'contact_name': contactName,
      'expected_revenue': double.tryParse(value.replaceAll(RegExp(r'[^\d.]'), '')) ?? 0.0,
      'probability': probability,
      'description': notes,
      if (closingDate.isNotEmpty) 'date_deadline': closingDate,
    };
  }

  static String _generateInitials(String name) {
    final parts = name.trim().split(' ');
    if (parts.isEmpty) return '??';
    if (parts.length == 1) {
      return parts[0].substring(0, parts[0].length > 1 ? 2 : 1).toUpperCase();
    }
    return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
  }

  static Color _generateColor(String id) {
    final colors = [
      const Color(0xFF5C6BC0),
      const Color(0xFF7B1FA2),
      const Color(0xFF009688),
      const Color(0xFFE91E63),
      const Color(0xFF00897B),
      const Color(0xFFD32F2F),
      const Color(0xFF1976D2),
      const Color(0xFFF57C00),
    ];
    final hash = id.hashCode.abs();
    return colors[hash % colors.length];
  }

  /// Ordered pipeline stages for the stage-progress bar.
  static const stages = ['New', 'Qualified', 'Proposal', 'Negotiation', 'Won'];
}

/// Canonical sample data shared across the feature.
abstract final class DealSampleData {
  static final all = <Deal>[
    Deal(
      id: '1',
      title: 'Cloud Migration Services',
      company: 'Global Systems Inc.',
      value: '\$45,000.00',
      stage: 'Proposal',
      probability: 85,
      avatarColor: const Color(0xFF5C6BC0),
      initials: 'DM',
      daysLeft: 5,
      contactName: 'David Martinez',
      contactTitle: 'CTO, Global Systems Inc.',
      closingDate: 'Dec 05, 2025',
      salesperson: 'Sarah Jenkins',
      notes:
          '"Client is comparing our delivery times with competitors. '
          'Emphasize our local warehouse stock during next call. '
          'Budget is flexible if we can guarantee 48h setup."',
      activity: const DealActivity(
        title: 'Review Technical Specs',
        description:
            'Follow up on hardware requirements with the engineering team.',
        icon: Icons.calendar_today_rounded,
        iconBgColor: Color(0xFFEDE7F6),
        dueLabel: 'DUE TOMORROW',
        dueLabelColor: Color(0xFFF57C00),
      ),
      history: const [
        DealHistoryEntry(
          description: 'Stage changed to Proposal',
          timeAgo: '2 HOURS AGO',
          author: 'SARAH JENKINS',
          dotColor: Color(0xFF4CAF50),
        ),
        DealHistoryEntry(
          description: 'Lead qualified and moved',
          timeAgo: '1 DAY AGO',
          author: 'DAVID MARTINEZ',
          dotColor: Color(0xFF2196F3),
        ),
      ],
    ),
    Deal(
      id: '2',
      title: 'Enterprise CRM Setup',
      company: 'Nexus Corp',
      value: '\$95,000.00',
      stage: 'Negotiation',
      probability: 90,
      avatarColor: const Color(0xFF7B1FA2),
      initials: 'JL',
      daysLeft: 2,
      contactName: 'James Liu',
      contactTitle: 'VP of Operations, Nexus Corp',
      closingDate: 'Nov 28, 2025',
      salesperson: 'Michael Roberts',
      notes:
          '"Negotiations are going well. Final pricing deck shared. '
          'Decision expected by end of week. Ensure legal reviews the NDA."',
      activity: const DealActivity(
        title: 'Final Pricing Review',
        description:
            'Send updated pricing deck and confirm legal review of NDA.',
        icon: Icons.description_outlined,
        iconBgColor: Color(0xFFE8F5E9),
        dueLabel: 'DUE TODAY',
        dueLabelColor: Color(0xFFE53935),
      ),
      history: const [
        DealHistoryEntry(
          description: 'Stage changed to Negotiation',
          timeAgo: '5 HOURS AGO',
          author: 'MICHAEL ROBERTS',
          dotColor: Color(0xFF4CAF50),
        ),
      ],
    ),
    Deal(
      id: '3',
      title: 'Software Licensing',
      company: 'Digital Innovations',
      value: '\$62,000.00',
      stage: 'Qualified',
      probability: 75,
      avatarColor: const Color(0xFF009688),
      initials: 'MR',
      daysLeft: 12,
      contactName: 'Michael Roberts',
      contactTitle: 'IT Manager, Digital Innovations',
      closingDate: 'Jan 08, 2026',
      salesperson: 'Emily Watson',
      notes:
          '"Interested in multi-year licensing. Needs a demo of the API integration module."',
      history: const [
        DealHistoryEntry(
          description: 'Lead qualified',
          timeAgo: '3 DAYS AGO',
          author: 'EMILY WATSON',
          dotColor: Color(0xFF2196F3),
        ),
      ],
    ),
    Deal(
      id: '4',
      title: 'Office Equipment Purchase',
      company: 'TechStart Hub',
      value: '\$28,500.00',
      stage: 'Qualified',
      probability: 65,
      avatarColor: const Color(0xFFE91E63),
      initials: 'SC',
      daysLeft: 18,
      contactName: 'Sarah Chen',
      contactTitle: 'Office Manager, TechStart Hub',
      closingDate: 'Jan 20, 2026',
      salesperson: 'David Martinez',
      notes:
          '"Budget approved for Q1. Awaiting final spec list from their facilities team."',
      history: const [
        DealHistoryEntry(
          description: 'Email sent with product catalog',
          timeAgo: '2 DAYS AGO',
          author: 'DAVID MARTINEZ',
          dotColor: Color(0xFFF57C00),
        ),
      ],
    ),
    Deal(
      id: '5',
      title: 'Cloud Storage Solution',
      company: 'DataFlow Ltd.',
      value: '\$33,200.00',
      stage: 'New',
      probability: 60,
      avatarColor: const Color(0xFF00897B),
      initials: 'PN',
      daysLeft: 25,
      contactName: 'Priya Nair',
      contactTitle: 'Data Architect, DataFlow Ltd.',
      closingDate: 'Feb 10, 2026',
      salesperson: 'James Liu',
      notes: '"Initial discovery call completed. Needs custom SLA terms."',
      history: const [
        DealHistoryEntry(
          description: 'Deal created',
          timeAgo: '1 WEEK AGO',
          author: 'JAMES LIU',
          dotColor: Color(0xFF9E9E9E),
        ),
      ],
    ),
  ];
}
