class CrmLead {
  final int id;
  final String name;
  final String partnerName;
  final String emailFrom;
  final String phone;
  final double expectedRevenue;
  final double probability;
  final int stageId;
  final String stageName;

  final int userId;
  final String userName;

  CrmLead({
    required this.id,
    required this.name,
    required this.partnerName,
    required this.emailFrom,
    required this.phone,
    required this.expectedRevenue,
    required this.probability,
    required this.stageId,
    required this.stageName,
    required this.userId,
    required this.userName,
  });

  factory CrmLead.fromJson(Map<String, dynamic> json) {
    return CrmLead(
      id: json['id'] ?? 0,
      name: json['name'] is String ? json['name'] : '',
      partnerName:
          json['partner_id'] != null &&
              json['partner_id'] is List &&
              json['partner_id'].length > 1
          ? json['partner_id'][1]
          : '',
      emailFrom: json['email_from'] is String ? json['email_from'] : '',
      phone: json['phone'] is String ? json['phone'] : '',
      expectedRevenue: (json['expected_revenue'] is num)
          ? (json['expected_revenue'] as num).toDouble()
          : 0.0,
      probability: (json['probability'] is num)
          ? (json['probability'] as num).toDouble()
          : 0.0,
      stageId:
          json['stage_id'] != null &&
              json['stage_id'] is List &&
              json['stage_id'].isNotEmpty
          ? (json['stage_id'][0] as int? ?? 0)
          : 0,
      stageName:
          json['stage_id'] != null &&
              json['stage_id'] is List &&
              json['stage_id'].length > 1
          ? json['stage_id'][1]
          : 'New',
      userId: json['user_id'] is List && (json['user_id'] as List).isNotEmpty
          ? (json['user_id'] as List)[0] as int
          : 0,
      userName: json['user_id'] is List && (json['user_id'] as List).length > 1
          ? (json['user_id'] as List)[1].toString()
          : 'Unassigned',
    );
  }
}
