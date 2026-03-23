import 'package:flutter/material.dart';

class ContactModel {
  final int id;
  final String name;
  final String company;
  final String email;
  final String phone;
  final Color avatarColor;
  final String initials;
  final String tag;
  final Color tagColor;

  ContactModel({
    required this.id,
    required this.name,
    required this.company,
    required this.email,
    required this.phone,
    required this.avatarColor,
    required this.initials,
    required this.tag,
    required this.tagColor,
  });

  factory ContactModel.fromOdooJson(Map<String, dynamic> json) {
    final name = json['name'] as String? ?? 'Unknown';
    final email = json['email'] != false ? json['email'].toString() : '';
    final phone = json['phone'] != false
        ? json['phone'].toString()
        : (json['mobile'] != false ? json['mobile'].toString() : '');

    String companyName = '';
    if (json['parent_id'] is List && (json['parent_id'] as List).isNotEmpty) {
      companyName = (json['parent_id'] as List)[1].toString();
    } else if (json['is_company'] == true) {
      companyName = 'Company';
    }

    String initials = '';
    final parts = name.split(' ');
    if (parts.length >= 2) {
      initials = '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    } else if (name.isNotEmpty) {
      initials = name.substring(0, 1).toUpperCase();
    }

    final isCompany = json['is_company'] == true;
    final tagLabel = isCompany ? 'Company' : 'Contact';
    final tColor = isCompany
        ? const Color(0xFF2196F3)
        : const Color(0xFF4CAF50);
    final aColor = Colors.primaries[name.hashCode % Colors.primaries.length];

    return ContactModel(
      id: json['id'] as int? ?? 0,
      name: name,
      company: companyName,
      email: email,
      phone: phone,
      avatarColor: aColor,
      initials: initials,
      tag: tagLabel,
      tagColor: tColor,
    );
  }
}
