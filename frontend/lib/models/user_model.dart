class UserModel {
  final int? id;
  final String googleId;
  final String email;
  final double lat;
  final double lng;
  final int? societyId;
  final String? societyName;

  UserModel({
    this.id,
    required this.googleId,
    required this.email,
    required this.lat,
    required this.lng,
    this.societyId,
    this.societyName,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['user_id'],
      googleId: json['google_id'] ?? '',
      email: json['email'] ?? '',
      lat: (json['lat'] ?? 0.0).toDouble(),
      lng: (json['lng'] ?? 0.0).toDouble(),
      societyId: json['society_id'],
      societyName: json['society_name'],
    );
  }
}
