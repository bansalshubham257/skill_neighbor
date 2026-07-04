import 'package:dio/dio.dart';
import 'package:hive/hive.dart';

// Change this to your backend URL.
// For Android emulator use: http://10.0.2.2:8000
// For real device on same WiFi use: http://YOUR_MACHINE_IP:8000
// Update this URL after deploying backend to Railway
const String kBaseUrl = 'http://192.168.0.3:8000';
// Example Railway URL: 'https://skill-neighbor-backend.up.railway.app'

class ApiService {
  final Dio _dio = Dio(BaseOptions(baseUrl: kBaseUrl));
  final Box userBox = Hive.box('user_box');

  // Get current logged in user
  int? get userId => userBox.get('user_id');

  // Sync user with Google login
  Future<Map<String, dynamic>> syncUser(
    String googleId,
    String email,
    double lat,
    double lng,
    int? societyId,
  ) async {
    final response = await _dio.post('/users/sync', data: {
      'google_id': googleId,
      'email': email,
      'lat': lat,
      'lng': lng,
      'society_id': societyId,
    });
    userBox.put('user_id', response.data['user_id']);
    userBox.put('email', email);
    return response.data;
  }

  // Create a skill listing
  Future<Map<String, dynamic>> createSkill({
    required String title,
    required String description,
    required String category,
    required String priceType,
    double? hourlyRate,
    required String phoneNumber,
  }) async {
    final uid = userId;
    if (uid == null) throw Exception("Not logged in");
    final response = await _dio.post('/skills/create', queryParameters: {
      'user_id': uid,
    }, data: {
      'title': title,
      'description': description,
      'category': category,
      'price_type': priceType,
      'hourly_rate': hourlyRate,
      'phone_number': phoneNumber,
    });
    return response.data;
  }

  // Create a society
  Future<Map<String, dynamic>> createSociety({
    required String name,
    required double lat,
    required double lng,
  }) async {
    final uid = userId;
    if (uid == null) throw Exception("Not logged in");
    final response = await _dio.post('/societies/create', queryParameters: {
      'user_id': uid,
    }, data: {
      'name': name,
      'lat': lat,
      'lng': lng,
    });
    return response.data;
  }

  // Search nearby skills
  Future<List<dynamic>> fetchNearbySkills(
      double lat, double lng, double radius) async {
    final response = await _dio.get('/skills/nearby', queryParameters: {
      'lat': lat,
      'lng': lng,
      'radius': radius,
    });
    return response.data;
  }

  // Search society skills
  Future<List<dynamic>> fetchSocietySkills(int societyId) async {
    final response = await _dio.get('/skills/society/$societyId');
    return response.data;
  }

  // Reward claim (Simulate Ad)
  Future<void> claimReward(String tokenType) async {
    final uid = userId;
    if (uid == null) throw Exception("User not logged in");

    await Future.delayed(const Duration(seconds: 3));

    await _dio.post('/rewards/claim', queryParameters: {
      'user_id': uid,
      'token_type': tokenType,
    });
  }

  // Reward consumption
  Future<bool> consumeReward(String tokenType) async {
    final uid = userId;
    if (uid == null) return false;

    try {
      await _dio.post('/rewards/consume', queryParameters: {
        'user_id': uid,
        'token_type': tokenType,
      });
      return true;
    } catch (e) {
      return false;
    }
  }
}
