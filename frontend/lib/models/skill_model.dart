class SkillModel {
  final int? id;
  final int userId;
  final String category;
  final String title;
  final String description;
  final String priceType;
  final double? hourlyRate;
  final String phoneNumber;
  final String? userEmail;

  SkillModel({
    this.id,
    required this.userId,
    required this.category,
    required this.title,
    required this.description,
    required this.priceType,
    this.hourlyRate,
    required this.phoneNumber,
    this.userEmail,
  });

  factory SkillModel.fromJson(Map<String, dynamic> json) {
    return SkillModel(
      id: json['id'],
      userId: json['user_id'] ?? 0,
      category: json['category'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      priceType: json['price_type'] ?? 'Negotiable',
      hourlyRate: json['hourly_rate']?.toDouble(),
      phoneNumber: json['phone_number'] ?? '',
      userEmail: json['email'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'description': description,
      'category': category,
      'price_type': priceType,
      'hourly_rate': hourlyRate,
      'phone_number': phoneNumber,
    };
  }
}
