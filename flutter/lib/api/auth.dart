import 'package:http/http.dart' as http;
import 'base_api.dart';
import 'package:collab_sphere/store/token.dart';

class AuthService extends BaseApiService {
  AuthService({required String baseUrl}) : super(baseUrl: baseUrl);

  // Login
  Future<http.Response> login(String email, String password) async {
    return post(
      '/auth/login',
      body: {'email': email, 'password': password},
      auth: false,
    );
  }

  // Register
  Future<http.Response> register(Map<String, dynamic> userData) async {
    return post('/auth/register', body: {'user': userData}, auth: false);
  }

  // Get current user's profile (/api/v1/users/profile)
  Future<http.Response> getProfile() async {
    return get('/api/v1/users/profile');
  }

  // Get user by id or 'me' (/api/v1/users/:id)
  Future<http.Response> getUserById(dynamic id) async {
    return get('/api/v1/users/$id');
  }

  // Update user by id (/api/v1/users/:id)
  Future<http.Response> updateUser(
    dynamic id,
    Map<String, dynamic> userData,
  ) async {
    final bodyMap = <String, dynamic>{'user': userData};
    if (userData.containsKey('tags')) {
      bodyMap['tags'] = userData['tags'];
    }
    return patch('/api/v1/users/$id', body: bodyMap);
  }

  // Delete user by id (/api/v1/users/:id)
  Future<http.Response> deleteUser(dynamic id) async {
    return delete('/api/v1/users/$id');
  }

  // List users (admin only) (/api/v1/users)
  Future<http.Response> listUsers({int page = 1, int perPage = 25}) async {
    return get(
      '/api/v1/users',
      params: {'page': page.toString(), 'per_page': perPage.toString()},
    );
  }

  // Autocomplete universities
  Future<http.Response> autocompleteUniversities(String term) async {
    return get(
      '/api/v1/users/autocomplete/universities',
      params: {'term': term},
    );
  }

  // Autocomplete countries
  Future<http.Response> autocompleteCountries(String term) async {
    return get('/api/v1/users/autocomplete/countries', params: {'term': term});
  }

  // Logout: Remove token from store
  Future<void> logout() async {
    await tokenStore.deleteToken();
    // Optionally clear user info if you store it
  }

  // Check if user is authenticated (token exists)
  Future<bool> isAuthenticated() async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }
}

/// Singleton instance for use throughout the app
final AuthService authService = AuthService(
  baseUrl: 'https://web06.cs.ait.ac.th/be',
);
