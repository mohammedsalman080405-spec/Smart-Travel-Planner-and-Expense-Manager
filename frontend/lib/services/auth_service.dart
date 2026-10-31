import '../config/api_config.dart';
import '../models/user.dart';
import 'api_service.dart';

class AuthService {
  static Future<Map<String, dynamic>> login(String email, String password) async {
    final response = await ApiService.post(
      ApiConfig.login,
      body: {'email': email, 'password': password},
    );
    final token = response['token'];
    await ApiService.saveToken(token);
    final user = User.fromJson(response['user']);
    return {'token': token, 'user': user};
  }

  static Future<Map<String, dynamic>> register(String fullName, String email, String password, {String? phone}) async {
    final response = await ApiService.post(
      ApiConfig.register,
      body: {
        'full_name': fullName,
        'email': email,
        'password': password,
        'phone': phone ?? '',
      },
    );
    final token = response['token'];
    await ApiService.saveToken(token);
    final user = User.fromJson(response['user']);
    return {'token': token, 'user': user};
  }

  static Future<User> getProfile() async {
    final response = await ApiService.get(ApiConfig.profile, needsAuth: true);
    return User.fromJson(response);
  }

  static Future<void> logout() async {
    try {
      await ApiService.post(ApiConfig.logout);
    } catch (_) {}
    await ApiService.removeToken();
  }
}
