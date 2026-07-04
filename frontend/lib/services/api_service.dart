import 'package:dio/dio.dart';
import 'package:hive/hive.dart';

// Set via --dart-define=API_BASE_URL=... during build
// Defaults to local dev server
const String kBaseUrl = String.fromEnvironment('API_BASE_URL', defaultValue: 'http://10.0.2.2:8000');

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
  Future<List<dynamic>> fetchSocieties() async {
    final response = await _dio.get('/societies/list');
    return response.data;
  }

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

  Future<Map<String, dynamic>> joinSociety(int societyId) async {
    final uid = userId;
    if (uid == null) throw Exception("Not logged in");
    final response = await _dio.post('/societies/join', queryParameters: {
      'user_id': uid,
      'society_id': societyId,
    });
    return response.data;
  }

  Future<void> leaveSociety() async {
    final uid = userId;
    if (uid == null) throw Exception("Not logged in");
    await _dio.post('/societies/leave', queryParameters: {'user_id': uid});
  }

  // Search
  Future<List<dynamic>> fetchMySkills() async {
    final uid = userId;
    if (uid == null) throw Exception("Not logged in");
    final response = await _dio.get('/skills/my', queryParameters: {'user_id': uid});
    return response.data;
  }

  Future<Map<String, dynamic>> updateSkill(int skillId, {
    required String title,
    required String description,
    required String category,
    required String priceType,
    double? hourlyRate,
    required String phoneNumber,
  }) async {
    final uid = userId;
    if (uid == null) throw Exception("Not logged in");
    final response = await _dio.put('/skills/update', queryParameters: {
      'skill_id': skillId,
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

  Future<void> deleteSkill(int skillId) async {
    final uid = userId;
    if (uid == null) throw Exception("Not logged in");
    await _dio.delete('/skills/delete', queryParameters: {
      'skill_id': skillId,
      'user_id': uid,
    });
  }

  Future<List<dynamic>> fetchNearbySkills(
      double lat, double lng, double radius) async {
    final uid = userId;
    final response = await _dio.get('/skills/nearby', queryParameters: {
      'lat': lat,
      'lng': lng,
      'radius': radius,
      if (uid != null) 'current_user_id': uid,
    });
    return response.data;
  }

  Future<List<dynamic>> fetchSocietySkills(int societyId) async {
    final uid = userId;
    final response = await _dio.get('/skills/society/$societyId', queryParameters: {
      if (uid != null) 'current_user_id': uid,
    });
    return response.data;
  }

  // Likes
  Future<Map<String, dynamic>> likeSkill(int skillId) async {
    final uid = userId;
    if (uid == null) throw Exception("Not logged in");
    final response = await _dio.post('/skills/like', queryParameters: {
      'skill_id': skillId,
      'user_id': uid,
    });
    return response.data;
  }

  // Notifications
  Future<List<dynamic>> fetchNotifications() async {
    final uid = userId;
    if (uid == null) throw Exception("Not logged in");
    final response = await _dio.get('/notifications', queryParameters: {
      'user_id': uid,
    });
    return response.data;
  }

  Future<int> fetchNotificationCount() async {
    final uid = userId;
    if (uid == null) return 0;
    final response = await _dio.get('/notifications/count', queryParameters: {
      'user_id': uid,
    });
    return response.data['count'] ?? 0;
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
