import 'package:flutter/material.dart';

class CrmActivity {
  final int id;
  final int resId;
  final String resName;
  final String resModel;
  final String activityTypeName;
  final String summary;
  final String dateDeadline;
  final String state;

  CrmActivity({
    required this.id,
    required this.resId,
    required this.resName,
    required this.resModel,
    required this.activityTypeName,
    required this.summary,
    required this.dateDeadline,
    required this.state,
  });

  factory CrmActivity.fromOdooJson(Map<String, dynamic> json) {
    String typeName = '';
    if (json['activity_type_id'] is List &&
        (json['activity_type_id'] as List).length > 1) {
      typeName = (json['activity_type_id'] as List)[1].toString();
    }

    return CrmActivity(
      id: json['id'] as int? ?? 0,
      resId: json['res_id'] as int? ?? 0,
      resName: json['res_name']?.toString() ?? 'Unknown',
      resModel: json['res_model']?.toString() ?? 'crm.lead',
      activityTypeName: typeName,
      summary: json['summary']?.toString() ?? '',
      dateDeadline: json['date_deadline']?.toString() ?? '',
      state: json['state']?.toString() ?? '',
    );
  }

  Color get tagColor {
    if (state == 'overdue') return const Color(0xFFFFEBEE);
    if (state == 'today') return const Color(0xFFFFF8E1);
    return const Color(0xFFE8F5E9); // planned
  }

  Color get tagTextColor {
    if (state == 'overdue') return const Color(0xFFD32F2F);
    if (state == 'today') return const Color(0xFFF57C00);
    return const Color(0xFF2E7D32); // planned
  }

  String get tagLabel {
    if (state == 'overdue') return 'OVERDUE';
    if (state == 'today') return 'TODAY';
    return 'PLANNED';
  }

  IconData get icon {
    final lower = activityTypeName.toLowerCase();
    if (lower.contains('call')) return Icons.phone_outlined;
    if (lower.contains('email')) return Icons.email_outlined;
    if (lower.contains('meeting')) return Icons.videocam_outlined;
    if (lower.contains('demo')) return Icons.computer_outlined;
    return Icons.task_alt_outlined;
  }
}
