import 'dart:convert';
import 'package:get/get.dart';
import 'package:collab_sphere/api/auth.dart';
import 'package:collab_sphere/store/token.dart';
import 'package:collab_sphere/models/user.dart';

class AuthController extends GetxController {
  bool isLoading = false;
  String? error;
  User? user;
  String? token;
  // Update user profile (for complete profile screen)
  Future<bool> updateProfile(Map<String, dynamic> userData) async {
    isLoading = true;
    error = null;
    update();
    print('[AuthController] updateProfile payload: $userData');
    final response = await authService.updateUser(user!.id, userData);
    print(
      '[AuthController] updateProfile response: ${response.statusCode} ${response.body}',
    );

    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (response.body.isNotEmpty) {
        user = User.fromJson(jsonDecode(response.body));
        isLoading = false;
        update();
        return true;
      }
      // Some servers return 204 No Content on success — fetch profile to refresh local state
      await fetchProfile();
      isLoading = false;
      update();
      return true;
    } else {
      if (response.body.isNotEmpty) {
        final decoded = jsonDecode(response.body);
        error =
            decoded['errors']?.join(', ') ??
            decoded['error'] ??
            'Profile update failed';
      } else {
        error = 'Profile update failed (empty response)';
      }
      isLoading = false;
      update();
      return false;
    }
  }

  Future<bool> login(String email, String password) async {
    isLoading = true;
    error = null;
    update();
    final response = await authService.login(email, password);
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      token = data['token'];
      await tokenStore.saveToken(token!);
      user = User.fromJson(data['user']);
      isLoading = false;
      update();
      return true;
    } else {
      error = 'Invalid email or password';
      isLoading = false;
      update();
      return false;
    }
  }

  Future<bool> register(Map<String, dynamic> userData) async {
    isLoading = true;
    error = null;
    update();
    print('[AuthController] Registering user:');
    print(userData);
    final response = await authService.register(userData);
    print(
      '[AuthController] Registration response status: ${response.statusCode}',
    );
    print('[AuthController] Registration response body: ${response.body}');
    if (response.statusCode == 201) {
      final data = response.body.isNotEmpty ? jsonDecode(response.body) : {};
      token = data['token'];
      await tokenStore.saveToken(token!);
      user = User.fromJson(data['user']);
      isLoading = false;
      update();
      return true;
    } else {
      if (response.body.isNotEmpty) {
        final decoded = jsonDecode(response.body);
        error =
            decoded['errors']?.join(', ') ??
            decoded['error'] ??
            'Registration failed';
      } else {
        error = 'Registration failed (empty response)';
      }
      isLoading = false;
      update();
      return false;
    }
  }

  Future<void> logout() async {
    token = null;
    user = null;
    await tokenStore.deleteToken();
    update();
  }

  Future<void> fetchProfile() async {
    if (token == null) return;
    isLoading = true;
    update();
    final response = await authService.getProfile();
    if (response.statusCode == 200) {
      user = User.fromJson(jsonDecode(response.body));
    }
    isLoading = false;
    update();
  }

  bool get isAuthenticated => token != null && user != null;
}

final AuthController authController = Get.put(AuthController());
