import 'package:dio/dio.dart';
import 'package:hive/hive.dart';

// Update this URL after deploying backend to Railway
const String kBaseUrl = 'http://192.168.0.3:8000';
// Example Railway URL: 'https://skill-neighbor-backend.up.railway.app'

class ApiService {
  final Dio _dio = Dio(BaseOptions(baseUrl: kBaseUrl));
  final Box userBox = Hive.box('user_box');

  int? get userId => userBox.get('user_id');

  // Auth
  Future<Map<String, dynamic>> login(String username, String password) async {
    final response = await _dio.post('/auth/login', data: {
      'username': username,
      'password': password,
    });
    return response.data;
  }

  Future<Map<String, dynamic>> register(String username, String password,
      {String email = '', double lat = 0, double lng = 0}) async {
    final response = await _dio.post('/auth/register', data: {
      'username': username,
      'password': password,
      'email': email,
      'lat': lat,
      'lng': lng,
    });
    return response.data;
  }

  // Skills
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

  // Society
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

  // Search
  Future<List<dynamic>> fetchNearbySkills(
      double lat, double lng, double radius) async {
    final response = await _dio.get('/skills/nearby', queryParameters: {
      'lat': lat,
      'lng': lng,
      'radius': radius,
    });
    return response.data;
  }

  Future<List<dynamic>> fetchSocietySkills(int societyId) async {
    final response = await _dio.get('/skills/society/$societyId');
    return response.data;
  }

  // Rewards
  Future<void> claimReward(String tokenType) async {
    final uid = userId;
    if (uid == null) throw Exception("User not logged in");
    await Future.delayed(const Duration(seconds: 3));
    await _dio.post('/rewards/claim', queryParameters: {
      'user_id': uid,
      'token_type': tokenType,
    });
  }

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
