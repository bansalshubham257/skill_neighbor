class SocietyModel {
  final int? id;
  final String name;
  final double lat;
  final double lng;
  final int? memberCount;

  SocietyModel({
    this.id,
    required this.name,
    required this.lat,
    required this.lng,
    this.memberCount,
  });

  factory SocietyModel.fromJson(Map<String, dynamic> json) {
    return SocietyModel(
      id: json['id'],
      name: json['name'] ?? '',
      lat: (json['lat'] ?? 0.0).toDouble(),
      lng: (json['lng'] ?? 0.0).toDouble(),
      memberCount: json['member_count'],
    );
  }
}
