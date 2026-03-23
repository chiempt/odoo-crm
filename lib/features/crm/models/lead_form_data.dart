/// Immutable value object representing the data entered in the Create Lead form.
class LeadFormData {
  final String title;
  final String source;
  final String campaign;
  final String status;
  final List<String> tags;

  // Contact
  final String contactName;
  final String jobTitle;
  final String email;
  final String phone;
  final String mobile;

  // Company
  final String companyName;
  final String industry;
  final String companySize;
  final String website;
  final String street;
  final String city;
  final String state;
  final String zipCode;
  final String country;

  // Deal
  final String expectedRevenue;
  final String probability;
  final DateTime? closeDate;
  final int priority; // 1–5

  // Assignment
  final String assignTo;
  final String notes;

  const LeadFormData({
    this.title = '',
    this.source = '',
    this.campaign = '',
    this.status = 'New Lead',
    this.tags = const ['Enterprise', 'Cloud'],
    this.contactName = '',
    this.jobTitle = '',
    this.email = '',
    this.phone = '',
    this.mobile = '',
    this.companyName = '',
    this.industry = '',
    this.companySize = '',
    this.website = '',
    this.street = '',
    this.city = '',
    this.state = '',
    this.zipCode = '',
    this.country = '',
    this.expectedRevenue = '',
    this.probability = '',
    this.closeDate,
    this.priority = 3,
    this.assignTo = '',
    this.notes = '',
  });

  LeadFormData copyWith({
    String? title,
    String? source,
    String? campaign,
    String? status,
    List<String>? tags,
    String? contactName,
    String? jobTitle,
    String? email,
    String? phone,
    String? mobile,
    String? companyName,
    String? industry,
    String? companySize,
    String? website,
    String? street,
    String? city,
    String? state,
    String? zipCode,
    String? country,
    String? expectedRevenue,
    String? probability,
    DateTime? closeDate,
    int? priority,
    String? assignTo,
    String? notes,
  }) {
    return LeadFormData(
      title: title ?? this.title,
      source: source ?? this.source,
      campaign: campaign ?? this.campaign,
      status: status ?? this.status,
      tags: tags ?? this.tags,
      contactName: contactName ?? this.contactName,
      jobTitle: jobTitle ?? this.jobTitle,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      mobile: mobile ?? this.mobile,
      companyName: companyName ?? this.companyName,
      industry: industry ?? this.industry,
      companySize: companySize ?? this.companySize,
      website: website ?? this.website,
      street: street ?? this.street,
      city: city ?? this.city,
      state: state ?? this.state,
      zipCode: zipCode ?? this.zipCode,
      country: country ?? this.country,
      expectedRevenue: expectedRevenue ?? this.expectedRevenue,
      probability: probability ?? this.probability,
      closeDate: closeDate ?? this.closeDate,
      priority: priority ?? this.priority,
      assignTo: assignTo ?? this.assignTo,
      notes: notes ?? this.notes,
    );
  }

  @override
  String toString() => 'LeadFormData(title: $title, contact: $contactName)';
}
