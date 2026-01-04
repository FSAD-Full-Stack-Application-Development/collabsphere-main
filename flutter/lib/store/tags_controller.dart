import 'dart:convert';
import 'package:get/get.dart';
import 'package:collab_sphere/api/tags.dart';

class TagsController extends GetxController {
  bool isLoading = false;
  String? error;
  List<String> tags = [];

  @override
  void onInit() {
    super.onInit();
    fetchTags();
  }

  Future<void> fetchTags() async {
    if (tags.isNotEmpty) return; // Already loaded

    isLoading = true;
    error = null;
    update();

    try {
      final response = await tagService.getAllTags();
      if (response.statusCode == 200 && response.body.isNotEmpty) {
        final decoded = jsonDecode(response.body) as List;
        tags =
            decoded
                .map(
                  (e) =>
                      e is Map ? e['tag_name']?.toString() ?? '' : e.toString(),
                )
                .where((tag) => tag.isNotEmpty)
                .toList();
        error = null;
      } else {
        error = 'Failed to load tags';
        // Fallback to static tags
        tags = [
          'JavaScript',
          'Python',
          'Java',
          'C++',
          'C#',
          'PHP',
          'Ruby',
          'Go',
          'Swift',
          'Kotlin',
          'Dart',
          'TypeScript',
          'React',
          'Vue.js',
          'Angular',
          'Node.js',
          'Express',
          'Django',
          'Flask',
          'Spring',
          'Laravel',
          'Rails',
          'MySQL',
          'PostgreSQL',
          'MongoDB',
          'Redis',
          'Docker',
          'Kubernetes',
          'AWS',
          'Azure',
          'GCP',
          'Git',
          'Linux',
          'Machine Learning',
          'AI',
          'Data Science',
          'Web Development',
          'Mobile Development',
          'DevOps',
        ];
      }
    } catch (e) {
      error = e.toString();
      // Fallback to static tags
      tags = [
        'JavaScript',
        'Python',
        'Java',
        'C++',
        'C#',
        'PHP',
        'Ruby',
        'Go',
        'Swift',
        'Kotlin',
        'Dart',
        'TypeScript',
        'React',
        'Vue.js',
        'Angular',
        'Node.js',
        'Express',
        'Django',
        'Flask',
        'Spring',
        'Laravel',
        'Rails',
        'MySQL',
        'PostgreSQL',
        'MongoDB',
        'Redis',
        'Docker',
        'Kubernetes',
        'AWS',
        'Azure',
        'GCP',
        'Git',
        'Linux',
        'Machine Learning',
        'AI',
        'Data Science',
        'Web Development',
        'Mobile Development',
        'DevOps',
      ];
    } finally {
      isLoading = false;
      update();
    }
  }

  List<String> getFilteredTags(String query, List<String> excludeTags) {
    if (query.isEmpty) {
      // When no query, show first 10 available tags (excluding already selected ones)
      return tags.where((tag) => !excludeTags.contains(tag)).take(10).toList();
    }

    return tags
        .where(
          (tag) =>
              tag.toLowerCase().contains(query.toLowerCase()) &&
              !excludeTags.contains(tag),
        )
        .take(10) // Limit to 10 suggestions
        .toList();
  }
}

final TagsController tagsController = Get.put(TagsController());
