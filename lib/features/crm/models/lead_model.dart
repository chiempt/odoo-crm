// Pure data layer – no Flutter/UI imports.
// Color values are stored as ARGB int to keep model framework-agnostic.
// Presentation layer converts via Color(int) when needed.
import 'dart:ui' show Color;
import 'package:flutter/material.dart' show IconData, Icons, Colors;

// ─────────────────────────────────────────────────────────────────────────────
// Value types
// ─────────────────────────────────────────────────────────────────────────────

enum LeadStage { newLead, qualified, proposal, won, lost }

enum LeadTagKind { hot, warm, cold }

class LeadTag {
  final String label;
  final Color bgColor;
  final Color textColor;
  final IconData? icon;

  const LeadTag({
    required this.label,
    required this.bgColor,
    required this.textColor,
    this.icon,
  });
}

class LeadActivity {
  final String title;
  final String description;
  final String dueLabel; // "DUE TODAY", "DUE TOMORROW"
  final Color dueLabelColor;
  final String scheduledTime; // "Today, 3:00 PM"
  final String duration; // "30 minutes"
  final IconData icon;
  final Color iconBgColor;
  final String actionLabel; // "Start Call", "Join Meeting"

  const LeadActivity({
    required this.title,
    required this.description,
    required this.dueLabel,
    required this.dueLabelColor,
    required this.scheduledTime,
    required this.duration,
    required this.icon,
    required this.iconBgColor,
    required this.actionLabel,
  });
}

class QualificationItem {
  final String label;
  final String subtitle;
  final bool isDone;

  const QualificationItem({
    required this.label,
    required this.subtitle,
    required this.isDone,
  });
}

class LeadTimelineEntry {
  final String description;
  final String timeAgo;
  final String author;
  final Color dotColor;

  const LeadTimelineEntry({
    required this.description,
    required this.timeAgo,
    required this.author,
    required this.dotColor,
  });
}

class LeadSalesperson {
  final String name;
  final String team;
  final Color avatarColor;
  final String initials;

  const LeadSalesperson({
    required this.name,
    required this.team,
    required this.avatarColor,
    required this.initials,
  });
}

class ScheduledActivity {
  final String title;
  final String description;
  final String priority; // "High", "Medium", "Low"
  final Color priorityColor;
  final String date;
  final String duration;
  final IconData icon;
  final Color iconBgColor;

  const ScheduledActivity({
    required this.title,
    required this.description,
    required this.priority,
    required this.priorityColor,
    required this.date,
    required this.duration,
    required this.icon,
    required this.iconBgColor,
  });
}

class NoteEntry {
  final String type; // "PHONE CALL", "NOTE", "EMAIL"
  final String content;
  final String timeAgo;
  final String author;
  final IconData icon;
  final Color iconBgColor;

  const NoteEntry({
    required this.type,
    required this.content,
    required this.timeAgo,
    required this.author,
    required this.icon,
    required this.iconBgColor,
  });
}

class LeadFollower {
  final int id;
  final int partnerId;
  final String name;
  final String? email;

  const LeadFollower({
    required this.id,
    required this.partnerId,
    required this.name,
    this.email,
  });
}

class LeadAttachment {
  final int id;
  final String name;
  final String? mimetype;
  final int fileSize;
  final String createDate;

  const LeadAttachment({
    required this.id,
    required this.name,
    this.mimetype,
    required this.fileSize,
    required this.createDate,
  });

  String get fileSizeLabel {
    if (fileSize < 1024) return '$fileSize B';
    if (fileSize < 1024 * 1024)
      return '${(fileSize / 1024).toStringAsFixed(1)} KB';
    return '${(fileSize / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Root aggregate
// ─────────────────────────────────────────────────────────────────────────────

class Lead {
  // ── List-view fields ──────────────────────────────────────────────────────
  final String id;
  final String title;
  final String? tag; // "HOT" | "WARM" | null
  final Color? tagColor;
  final String value; // "$45,000"
  final int probability;
  final String assignee;
  final String company;
  final int stars; // 1–5
  final LeadStage stage;
  final String dueDate;
  final Color avatarColor;
  final String avatarInitials;
  final double expectedRevenueValue;

  // ── Detail-only fields ────────────────────────────────────────────────────
  final List<LeadTag> detailTags;
  final int leadScore;

  // Revenue
  final String expectedRevenue;
  final String expectedCloseDate;
  final String closingDate;

  // Contact
  final String contactName;
  final String contactTitle;
  final String email;
  final String phone;
  final String location;

  // Source
  final String source;
  final String campaign;
  final IconData sourceIcon;
  final Color sourceIconBgColor;

  // Activity
  final LeadActivity? nextActivity;

  // Description
  final String description;
  final List<String> keyRequirements;

  // Qualification
  final List<QualificationItem> qualificationItems;
  final bool isQualified;

  // Timeline
  final List<LeadTimelineEntry> timeline;

  // Salesperson
  final LeadSalesperson? salesperson;

  // Scheduled
  final List<ScheduledActivity> scheduledActivities;

  // Notes
  final List<NoteEntry> notes;

  // Followers & Attachments
  final List<LeadFollower> followers;
  final List<LeadAttachment> attachments;

  String get stageLabel {
    switch (stage) {
      case LeadStage.newLead:
        return 'New';
      case LeadStage.qualified:
        return 'Qualified';
      case LeadStage.proposal:
        return 'Proposal';
      case LeadStage.won:
        return 'Won';
      case LeadStage.lost:
        return 'Lost';
    }
  }

  const Lead({
    required this.id,
    required this.title,
    this.tag,
    this.tagColor,
    required this.value,
    required this.probability,
    required this.assignee,
    required this.company,
    required this.stars,
    required this.stage,
    required this.dueDate,
    required this.avatarColor,
    required this.avatarInitials,
    this.detailTags = const [],
    this.leadScore = 0,
    this.expectedRevenue = '',
    this.expectedCloseDate = '',
    this.closingDate = '',
    this.contactName = '',
    this.contactTitle = '',
    this.email = '',
    this.phone = '',
    this.location = '',
    this.source = '',
    this.campaign = '',
    this.sourceIcon = Icons.campaign_outlined,
    this.sourceIconBgColor = const Color(0xFFE3F2FD),
    this.nextActivity,
    this.description = '',
    this.keyRequirements = const [],
    this.qualificationItems = const [],
    this.isQualified = false,
    this.timeline = const [],
    this.salesperson,
    this.scheduledActivities = const [],
    this.notes = const [],
    this.followers = const [],
    this.attachments = const [],
    this.expectedRevenueValue = 0.0,
  });

  factory Lead.fromOdooJson(Map<String, dynamic> json) {
    final name = json['name'] as String? ?? 'Unnamed';
    final partner =
        json['partner_id'] is List && (json['partner_id'] as List).isNotEmpty
        ? (json['partner_id'] as List)[1].toString()
        : (json['partner_name'] is String
              ? json['partner_name'] as String
              : 'Unknown Partner');
    final rawRevenue = json['expected_revenue'];
    final double revenueDouble = (rawRevenue is num)
        ? rawRevenue.toDouble()
        : 0.0;
    final probValue = json['probability'];
    final prob = (probValue is num) ? probValue.toInt() : 0;
    final stageName =
        json['stage_id'] is List && (json['stage_id'] as List).length > 1
        ? (json['stage_id'] as List)[1].toString()
        : 'New';

    final expectedRevenueStr = revenueDouble >= 1000
        ? '${(revenueDouble / 1000).toStringAsFixed(1)}K'
        : revenueDouble.toStringAsFixed(0);

    // Convert Odoo Stage to UI Stage Enum approx
    LeadStage parsedStage = LeadStage.newLead;
    final ls = stageName.toLowerCase();
    if (ls.contains('qualfied') || ls.contains('qual')) {
      parsedStage = LeadStage.qualified;
    }
    if (ls.contains('prop')) {
      parsedStage = LeadStage.proposal;
    }
    if (ls.contains('won')) {
      parsedStage = LeadStage.won;
    }
    if (ls.contains('lost')) {
      parsedStage = LeadStage.lost;
    }

    // Determine initial avatar
    String assigneeStr =
        json['user_id'] is List && (json['user_id'] as List).length > 1
        ? (json['user_id'] as List)[1].toString()
        : 'Unassigned';
    String initials = '';
    if (assigneeStr.isNotEmpty) {
      final parts = assigneeStr.split(' ');
      if (parts.length >= 2) {
        initials = '${parts[0][0]}${parts[1][0]}'.toUpperCase();
      } else {
        initials = parts[0].substring(0, 1).toUpperCase();
      }
    }

    // Populate salesperson object
    final salesperson =
        json['user_id'] is List && (json['user_id'] as List).length > 1
        ? LeadSalesperson(
            name: (json['user_id'] as List)[1].toString(),
            team:
                json['team_id'] is List && (json['team_id'] as List).length > 1
                ? (json['team_id'] as List)[1].toString()
                : 'Sales Team',
            avatarColor:
                Colors.primaries[((json['user_id'] as List)[1].toString())
                        .hashCode %
                    Colors.primaries.length],
            initials: initials,
          )
        : null;

    return Lead(
      id: json['id'].toString(),
      title: name,
      tag: prob > 70 ? 'HOT' : (prob > 30 ? 'WARM' : 'COLD'),
      tagColor: prob > 70
          ? const Color(0xFFE53935)
          : (prob > 30 ? const Color(0xFFF57C00) : const Color(0xFF1E88E5)),
      value: '\$$expectedRevenueStr',
      probability: prob,
      assignee: assigneeStr,
      company: partner,
      stars: revenueDouble > 50000 ? 5 : (revenueDouble > 10000 ? 3 : 1),
      stage: parsedStage,
      dueDate: json['date_deadline'] != false && json['date_deadline'] != null
          ? json['date_deadline'].toString().split(' ')[0]
          : 'No Date',
      avatarColor:
          Colors.primaries[assigneeStr.hashCode % Colors.primaries.length],
      avatarInitials: initials,
      email: json['email_from'] is String ? json['email_from'] as String : '',
      phone: json['phone'] is String
          ? json['phone'] as String
          : (json['mobile'] is String ? json['mobile'] as String : ''),
      description: json['description'] is String
          ? json['description'] as String
          : '',
      expectedRevenue: '\$$expectedRevenueStr',
      contactName: json['contact_name'] is String
          ? json['contact_name'] as String
          : '',
      location: json['city'] is String ? json['city'] as String : '',
      expectedRevenueValue: revenueDouble,
      salesperson: salesperson,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Sample data (presentation-layer colors are acceptable here because this is
// a frontend app without a real backend; replace with API mapping later).
// ─────────────────────────────────────────────────────────────────────────────

abstract final class LeadSampleData {
  static final all = <Lead>[
    Lead(
      id: '1',
      title: 'Cloud Migration Services',
      tag: 'HOT',
      tagColor: const Color(0xFFE53935),
      value: '\$45,000',
      probability: 85,
      assignee: 'David Martinez',
      company: 'Global Systems Inc.',
      stars: 4,
      stage: LeadStage.newLead,
      dueDate: 'Nov 30',
      avatarColor: const Color(0xFF5C6BC0),
      avatarInitials: 'DM',
      // ── detail ──
      detailTags: const [
        LeadTag(
          label: 'NEW LEAD',
          bgColor: Color(0xFFE8F5E9),
          textColor: Color(0xFF2E7D32),
        ),
        LeadTag(
          label: 'HOT',
          bgColor: Color(0xFFE3F2FD),
          textColor: Color(0xFF1565C0),
          icon: Icons.bolt_rounded,
        ),
      ],
      leadScore: 85,
      expectedRevenue: '\$45,000',
      expectedCloseDate: 'Nov 30, 2023',
      contactName: 'David Martinez',
      contactTitle: 'IT Director',
      email: 'david.martinez@globalsys.com',
      phone: '+1 (555) 123-4567',
      location: 'San Francisco, CA',
      source: 'LinkedIn Campaign',
      campaign: 'Enterprise Solutions Q4',
      sourceIcon: Icons.campaign_outlined,
      sourceIconBgColor: const Color(0xFFE3F2FD),
      nextActivity: const LeadActivity(
        title: 'Discovery Call',
        description:
            'Initial consultation to understand cloud infrastructure needs',
        dueLabel: 'DUE TODAY',
        dueLabelColor: Color(0xFFF57C00),
        scheduledTime: 'Today, 3:00 PM',
        duration: '30 minutes',
        icon: Icons.calendar_today_rounded,
        iconBgColor: Color(0xFFEDE7F6),
        actionLabel: 'Start Call',
      ),
      description:
          "Company is looking to migrate 50+ servers to cloud infrastructure. "
          "They're evaluating AWS and Azure. Budget approved for Q1 2024. "
          "Main concerns are downtime and data security during migration.",
      keyRequirements: const [
        'Zero-downtime migration strategy',
        'SOC 2 compliance support',
        '24/7 technical support post-migration',
      ],
      qualificationItems: const [
        QualificationItem(
          label: 'Budget Confirmed',
          subtitle: '\$40K - \$50K range approved',
          isDone: true,
        ),
        QualificationItem(
          label: 'Decision Maker Identified',
          subtitle: 'CTO & IT Director involved',
          isDone: true,
        ),
        QualificationItem(
          label: 'Timeline Defined',
          subtitle: 'Pending next meeting',
          isDone: false,
        ),
      ],
      isQualified: true,
      timeline: const [
        LeadTimelineEntry(
          description: 'Lead created from LinkedIn campaign',
          timeAgo: '2 DAYS AGO',
          author: 'AUTOMATED',
          dotColor: Color(0xFF4CAF50),
        ),
        LeadTimelineEntry(
          description: 'First contact email sent',
          timeAgo: 'YESTERDAY',
          author: 'SARAH JENKINS',
          dotColor: Color(0xFF4CAF50),
        ),
        LeadTimelineEntry(
          description: 'Response received - interested',
          timeAgo: '5 HOURS AGO',
          author: 'DAVID MARTINEZ',
          dotColor: Color(0xFF4CAF50),
        ),
      ],
      salesperson: const LeadSalesperson(
        name: 'Sarah Jenkins',
        team: 'Enterprise Sales Team',
        avatarColor: Color(0xFF5C6BC0),
        initials: 'SJ',
      ),
      scheduledActivities: const [
        ScheduledActivity(
          title: 'Discovery Call',
          description:
              'Initial consultation to understand cloud infrastructure needs',
          priority: 'High',
          priorityColor: Color(0xFFE53935),
          date: 'Feb 12, 2026 • 3:00 PM',
          duration: '30 min',
          icon: Icons.phone_outlined,
          iconBgColor: Color(0xFFE3F2FD),
        ),
        ScheduledActivity(
          title: 'Technical Demo',
          description:
              'Present cloud migration solution and answer technical questions',
          priority: 'High',
          priorityColor: Color(0xFFE53935),
          date: 'Feb 14, 2026 • 10:00 AM',
          duration: '60 min',
          icon: Icons.videocam_outlined,
          iconBgColor: Color(0xFFE8F5E9),
        ),
      ],
      notes: const [
        NoteEntry(
          type: 'PHONE CALL',
          content:
              'Had a brief conversation about their current infrastructure. '
              'They have 50+ servers running on-premise.',
          timeAgo: '3 hours ago',
          author: 'Sarah Jenkins',
          icon: Icons.phone_outlined,
          iconBgColor: Color(0xFFE3F2FD),
        ),
        NoteEntry(
          type: 'NOTE',
          content:
              'Decision maker confirmed. CTO will join the discovery call tomorrow.',
          timeAgo: '5 hours ago',
          author: 'Sarah Jenkins',
          icon: Icons.description_outlined,
          iconBgColor: Color(0xFFFFF8E1),
        ),
      ],
    ),
    Lead(
      id: '2',
      title: 'Office Equipment\nPurchase',
      tag: 'WARM',
      tagColor: const Color(0xFFF57C00),
      value: '\$28,500',
      probability: 65,
      assignee: 'Sarah Chen',
      company: 'TechStart Hub',
      stars: 3,
      stage: LeadStage.qualified,
      dueDate: 'Dec 15',
      avatarColor: const Color(0xFFE91E63),
      avatarInitials: 'SC',
      leadScore: 65,
      expectedRevenue: '\$28,500',
      expectedCloseDate: 'Dec 15, 2023',
      contactName: 'Sarah Chen',
      contactTitle: 'Office Manager',
      email: 'sarah.chen@techstarthub.com',
      phone: '+1 (555) 234-5678',
      location: 'Austin, TX',
      source: 'Website Form',
      campaign: 'Q4 Office Upgrade',
      sourceIcon: Icons.language_outlined,
      sourceIconBgColor: const Color(0xFFE8F5E9),
      description:
          'TechStart Hub is expanding and needs office equipment for 30 new hires.',
      qualificationItems: const [
        QualificationItem(
          label: 'Budget Confirmed',
          subtitle: '\$25K - \$35K range',
          isDone: true,
        ),
        QualificationItem(
          label: 'Decision Maker Identified',
          subtitle: 'Office Manager',
          isDone: true,
        ),
        QualificationItem(
          label: 'Timeline Defined',
          subtitle: 'Q1 2024 delivery',
          isDone: true,
        ),
      ],
      isQualified: false,
      timeline: const [
        LeadTimelineEntry(
          description: 'Form submitted on website',
          timeAgo: '3 DAYS AGO',
          author: 'AUTOMATED',
          dotColor: Color(0xFF4CAF50),
        ),
        LeadTimelineEntry(
          description: 'Initial email sent',
          timeAgo: '2 DAYS AGO',
          author: 'SARAH JENKINS',
          dotColor: Color(0xFF4CAF50),
        ),
      ],
      salesperson: const LeadSalesperson(
        name: 'Sarah Jenkins',
        team: 'SMB Sales Team',
        avatarColor: Color(0xFF5C6BC0),
        initials: 'SJ',
      ),
    ),
    Lead(
      id: '3',
      title: 'Software Licensing',
      tag: 'HOT',
      tagColor: const Color(0xFFE53935),
      value: '\$62,000',
      probability: 75,
      assignee: 'Michael Roberts',
      company: 'Digital Innovations',
      stars: 5,
      stage: LeadStage.newLead,
      dueDate: 'Nov 20',
      avatarColor: const Color(0xFF009688),
      avatarInitials: 'MR',
      leadScore: 78,
      expectedRevenue: '\$62,000',
      expectedCloseDate: 'Nov 20, 2023',
      contactName: 'Michael Roberts',
      contactTitle: 'IT Manager',
      email: 'm.roberts@digitalinno.com',
      phone: '+1 (555) 345-6789',
      location: 'New York, NY',
      source: 'Cold Call',
      campaign: 'Nov Outreach',
      sourceIcon: Icons.phone_outlined,
      sourceIconBgColor: const Color(0xFFFCE4EC),
      description:
          'Digital Innovations needs enterprise software licenses for 200 users.',
      qualificationItems: const [
        QualificationItem(
          label: 'Budget Confirmed',
          subtitle: '\$60K approved',
          isDone: true,
        ),
        QualificationItem(
          label: 'Decision Maker Identified',
          subtitle: 'IT Manager',
          isDone: false,
        ),
        QualificationItem(
          label: 'Timeline Defined',
          subtitle: 'Pending approval',
          isDone: false,
        ),
      ],
      isQualified: false,
      timeline: const [
        LeadTimelineEntry(
          description: 'Cold call initiated',
          timeAgo: '1 WEEK AGO',
          author: 'MICHAEL ROBERTS',
          dotColor: Color(0xFF4CAF50),
        ),
      ],
      salesperson: const LeadSalesperson(
        name: 'Michael Roberts',
        team: 'Enterprise Team',
        avatarColor: Color(0xFF009688),
        initials: 'MR',
      ),
    ),
    Lead(
      id: '4',
      title: 'Marketing Consultation',
      tag: null,
      tagColor: null,
      value: '\$15,000',
      probability: 45,
      assignee: 'Emily Watson',
      company: 'Brand Builders Co.',
      stars: 2,
      stage: LeadStage.newLead,
      dueDate: 'Jan 10',
      avatarColor: const Color(0xFFFF7043),
      avatarInitials: 'EW',
      leadScore: 42,
      expectedRevenue: '\$15,000',
      expectedCloseDate: 'Jan 10, 2024',
      contactName: 'Emily Watson',
      contactTitle: 'Marketing Director',
      email: 'emily@brandbuilders.co',
      phone: '+1 (555) 456-7890',
      location: 'Chicago, IL',
      source: 'Referral',
      campaign: 'Partner Network',
      sourceIcon: Icons.people_outline,
      sourceIconBgColor: const Color(0xFFF3E5F5),
      description:
          'Brand Builders Co. is looking for CRM consulting services to improve their lead pipeline.',
      qualificationItems: const [
        QualificationItem(
          label: 'Budget Confirmed',
          subtitle: 'Under review',
          isDone: false,
        ),
        QualificationItem(
          label: 'Decision Maker Identified',
          subtitle: 'Marketing Director',
          isDone: true,
        ),
        QualificationItem(
          label: 'Timeline Defined',
          subtitle: 'Q1 2024',
          isDone: false,
        ),
      ],
      isQualified: false,
      timeline: const [
        LeadTimelineEntry(
          description: 'Referred by partner',
          timeAgo: '4 DAYS AGO',
          author: 'PARTNER NETWORK',
          dotColor: Color(0xFF9E9E9E),
        ),
      ],
      salesperson: const LeadSalesperson(
        name: 'Emily Watson',
        team: 'SMB Sales Team',
        avatarColor: Color(0xFFFF7043),
        initials: 'EW',
      ),
    ),
    Lead(
      id: '5',
      title: 'Enterprise CRM Setup',
      tag: 'HOT',
      tagColor: const Color(0xFFE53935),
      value: '\$95,000',
      probability: 90,
      assignee: 'James Liu',
      company: 'Nexus Corp',
      stars: 5,
      stage: LeadStage.proposal,
      dueDate: 'Nov 25',
      avatarColor: const Color(0xFF7B1FA2),
      avatarInitials: 'JL',
      leadScore: 92,
      expectedRevenue: '\$95,000',
      expectedCloseDate: 'Nov 25, 2023',
      contactName: 'James Liu',
      contactTitle: 'VP of Operations',
      email: 'j.liu@nexuscorp.com',
      phone: '+1 (555) 567-8901',
      location: 'Seattle, WA',
      source: 'Trade Show',
      campaign: 'TechWorld 2023',
      sourceIcon: Icons.store_outlined,
      sourceIconBgColor: const Color(0xFFFFF3E0),
      description:
          'Nexus Corp wants a full CRM overhaul for 500+ employees across 3 offices.',
      qualificationItems: const [
        QualificationItem(
          label: 'Budget Confirmed',
          subtitle: '\$90K–\$100K',
          isDone: true,
        ),
        QualificationItem(
          label: 'Decision Maker Identified',
          subtitle: 'VP Ops + CEO',
          isDone: true,
        ),
        QualificationItem(
          label: 'Timeline Defined',
          subtitle: 'Start Jan 2024',
          isDone: true,
        ),
      ],
      isQualified: true,
      timeline: const [
        LeadTimelineEntry(
          description: 'Met at TechWorld 2023',
          timeAgo: '2 WEEKS AGO',
          author: 'JAMES LIU',
          dotColor: Color(0xFF4CAF50),
        ),
        LeadTimelineEntry(
          description: 'Follow-up meeting scheduled',
          timeAgo: '1 WEEK AGO',
          author: 'JAMES LIU',
          dotColor: Color(0xFF4CAF50),
        ),
      ],
      salesperson: const LeadSalesperson(
        name: 'James Liu',
        team: 'Enterprise Team',
        avatarColor: Color(0xFF7B1FA2),
        initials: 'JL',
      ),
    ),
    Lead(
      id: '6',
      title: 'Cloud Storage Solution',
      tag: 'WARM',
      tagColor: const Color(0xFFF57C00),
      value: '\$33,200',
      probability: 60,
      assignee: 'Priya Nair',
      company: 'DataFlow Ltd.',
      stars: 3,
      stage: LeadStage.qualified,
      dueDate: 'Dec 08',
      avatarColor: const Color(0xFF00897B),
      avatarInitials: 'PN',
      leadScore: 60,
      expectedRevenue: '\$33,200',
      expectedCloseDate: 'Dec 08, 2023',
      contactName: 'Priya Nair',
      contactTitle: 'Data Architect',
      email: 'p.nair@dataflow.io',
      phone: '+1 (555) 678-9012',
      location: 'Boston, MA',
      source: 'Email Campaign',
      campaign: 'Cloud Storage Push',
      sourceIcon: Icons.email_outlined,
      sourceIconBgColor: const Color(0xFFE0F2F1),
      description:
          'DataFlow Ltd. needs scalable cloud storage for 10TB+ data with custom SLA.',
      qualificationItems: const [
        QualificationItem(
          label: 'Budget Confirmed',
          subtitle: '\$30K–\$40K',
          isDone: true,
        ),
        QualificationItem(
          label: 'Decision Maker Identified',
          subtitle: 'Data Architect',
          isDone: true,
        ),
        QualificationItem(
          label: 'Timeline Defined',
          subtitle: 'Pending SLA review',
          isDone: false,
        ),
      ],
      isQualified: false,
      timeline: const [
        LeadTimelineEntry(
          description: 'Email opened and clicked',
          timeAgo: '5 DAYS AGO',
          author: 'AUTOMATED',
          dotColor: Color(0xFF4CAF50),
        ),
      ],
      salesperson: const LeadSalesperson(
        name: 'Priya Nair',
        team: 'SMB Sales Team',
        avatarColor: Color(0xFF00897B),
        initials: 'PN',
      ),
    ),
  ];
}
