import 'package:http/http.dart' as http;
import 'base_api.dart';

class SuggestionsService extends BaseApiService {
  SuggestionsService({required String baseUrl}) : super(baseUrl: baseUrl);

  Future<http.Response> tags(String query) async {
    return get('/api/v1/suggestions/tags', params: {'query': query});
  }

  Future<http.Response> countries(String query) async {
    return get('/api/v1/suggestions/countries', params: {'query': query});
  }

  Future<http.Response> universities(String query) async {
    return get('/api/v1/suggestions/universities', params: {'query': query});
  }

  Future<http.Response> departments(String query) async {
    return get('/api/v1/suggestions/departments', params: {'query': query});
  }
}

final SuggestionsService suggestionsService = SuggestionsService(
  baseUrl: 'https://web06.cs.ait.ac.th/be',
);
