import 'package:http/http.dart' as http;
import 'base_api.dart';

class TagService extends BaseApiService {
  TagService({required String baseUrl}) : super(baseUrl: baseUrl);

  // Get all tags
  Future<http.Response> getAllTags() async {
    return get('/api/v1/tags');
  }

  // Autocomplete suggestions from backend
  Future<http.Response> autocomplete(String term) async {
    return get('/api/v1/suggestions/tags', params: {'query': term});
  }

  // Create tag globally
  Future<http.Response> createTag(String tagName) async {
    return post('/api/v1/tags', body: {'tag_name': tagName});
  }
}

final TagService tagService = TagService(
  baseUrl: 'https://web06.cs.ait.ac.th/be',
);
