// ...existing code...
import 'base_api.dart';
import 'package:http/http.dart' as http;
import 'package:collab_sphere/models/project.dart';

class ProjectService extends BaseApiService {
  // Like/unlike comment (defensive: do not call with empty commentId)
  Future<http.Response> likeComment(String projectId, String commentId) async {
    if (commentId.isEmpty) {
      throw ArgumentError('commentId cannot be empty');
    }
    return post('/api/v1/projects/$projectId/comments/$commentId/like');
  }

  Future<http.Response> unlikeComment(
    String projectId,
    String commentId,
  ) async {
    if (commentId.isEmpty) {
      throw ArgumentError('commentId cannot be empty');
    }
    return post('/api/v1/projects/$projectId/comments/$commentId/unlike');
  }

  // Comment actions
  Future<http.Response> deleteComment(
    String projectId,
    String commentId,
  ) async {
    if (commentId.isEmpty) {
      throw ArgumentError('commentId cannot be empty');
    }
    return delete('/api/v1/projects/$projectId/comments/$commentId');
  }

  Future<http.Response> reportComment(
    String projectId,
    String commentId,
  ) async {
    if (commentId.isEmpty) {
      throw ArgumentError('commentId cannot be empty');
    }
    return post('/api/v1/projects/$projectId/comments/$commentId/report');
  }

  Future<http.Response> hideComment(String projectId, String commentId) async {
    if (commentId.isEmpty) {
      throw ArgumentError('commentId cannot be empty');
    }
    return post('/api/v1/projects/$projectId/comments/$commentId/hide');
  }

  Future<http.Response> unhideComment(
    String projectId,
    String commentId,
  ) async {
    if (commentId.isEmpty) {
      throw ArgumentError('commentId cannot be empty');
    }
    return post('/api/v1/projects/$projectId/comments/$commentId/unhide');
  }
  // ─────────────────────────────────────────────
  // Collaboration APIs
  // ─────────────────────────────────────────────

  // List all collaborations for a project
  Future<http.Response> getCollaborations(String projectId) async {
    return get('/api/v1/projects/$projectId/collaborations');
  }

  // Add a collaborator to a project
  Future<http.Response> addCollaboration(
    String projectId, {
    required String userId,
    String projectRole = 'viewer',
  }) async {
    return post(
      '/api/v1/projects/$projectId/collaborations',
      body: {
        'collaboration': {'user_id': userId, 'project_role': projectRole},
      },
    );
  }

  // Update a collaborator's role
  Future<http.Response> updateCollaboration(
    String projectId,
    String collaborationId, {
    String? projectRole,
  }) async {
    final body = {
      'collaboration': {if (projectRole != null) 'project_role': projectRole},
    };
    return put(
      '/api/v1/projects/$projectId/collaborations/$collaborationId',
      body: body,
    );
  }

  // Remove a collaborator
  Future<http.Response> removeCollaboration(
    String projectId,
    String collaborationId,
  ) async {
    return delete(
      '/api/v1/projects/$projectId/collaborations/$collaborationId',
    );
  }

  // ─────────────────────────────────────────────
  // Collaboration Request APIs
  // ─────────────────────────────────────────────

  // List all collaboration requests for a project
  Future<http.Response> getCollaborationRequests(String projectId) async {
    return get('/api/v1/projects/$projectId/collab');
  }

  // Create a collaboration request
  Future<http.Response> createCollaborationRequest(String projectId) async {
    return post('/api/v1/projects/$projectId/collab/request');
  }

  // Approve a collaboration request
  Future<http.Response> approveCollaborationRequest(
    String projectId,
    String userId,
  ) async {
    return post(
      '/api/v1/projects/$projectId/collab/approve',
      body: {'user_id': userId},
    );
  }

  // Reject a collaboration request
  Future<http.Response> rejectCollaborationRequest(
    String projectId,
    String userId,
  ) async {
    return post(
      '/api/v1/projects/$projectId/collab/reject',
      body: {'user_id': userId},
    );
  }

  ProjectService({required super.baseUrl});

  // Fetches a map of countries -> universities -> list of departments.
  // Expected JSON shape:
  // {
  //   "Country1": {
  //     "UniversityA": ["Department1", "Department2", ...],
  //     "UniversityB": ["Department3", ...]
  //   },
  //   "Country2": {
  //     "UniversityC": ["Department4", ...]
  //   }
  // }
  Future<http.Response> getUniversityDepartments() async {
    return get('/api/v1/suggestions/university_departments');
  }

  Future<http.Response> getProjects({
    String? query,
    String? status,
    String? visibility,
    List<String>? tags,
    String? university,
    String? department,
    String? sort,
    int? page,
    int? perPage,
  }) async {
    final params = <String, String>{
      if (query != null) 'q': query,
      if (status != null) 'status': status,
      if (visibility != null) 'visibility': visibility,
      if (tags != null && tags.isNotEmpty) 'tags': tags.join(','),
      if (university != null) 'university': university,
      if (department != null) 'department': department,
      if (sort != null) 'sort': sort,
      if (page != null) 'page': page.toString(),
      if (perPage != null) 'per_page': perPage.toString(),
    };
    return get('/api/v1/projects', params: params.isNotEmpty ? params : null);
  }

  // New helper to fetch top projects sorted by votes
  Future<http.Response> getTopProjects({int? page, int? perPage}) async {
    return getProjects(sort: 'votes', page: page, perPage: perPage);
  }

  Future<http.Response> getProject(String projectId) async {
    return get('/api/v1/projects/$projectId');
  }

  Future<http.Response> createProject(Map<String, dynamic> project) async {
    return post('/api/v1/projects', body: project);
  }

  Future<http.Response> updateProject(Project project) async {
    final body = {
      'project': {
        'title': project.title,
        'description': project.description,
        'status': project.status,
        'visibility': project.visibility,
        'show_funds': project.showFunds,
      },
      if (project.tags.isNotEmpty)
        'tag_ids': project.tags.map((t) => t.id).toList(),
    };
    return put('/api/v1/projects/${project.id}', body: body);
  }

  Future<http.Response> deleteProject(String projectId) async {
    return delete('/api/v1/projects/$projectId');
  }

  Future<http.Response> voteProject(
    String projectId, {
    String voteType = 'up',
  }) async {
    return post(
      '/api/v1/projects/$projectId/vote',
      body: {'vote_type': voteType},
    );
  }

  Future<http.Response> unvoteProject(String projectId) async {
    return delete('/api/v1/projects/$projectId/vote');
  }

  Future<http.Response> postComment(String projectId, String text) async {
    return post(
      '/api/v1/projects/$projectId/comments',
      body: {
        'comment': {'content': text},
      },
    );
  }

  Future<http.Response> postReply(
    String projectId,
    String text, {
    required String parentId,
  }) async {
    if (parentId.isEmpty) {
      throw ArgumentError('parentId cannot be empty for a reply');
    }
    final commentBody = <String, dynamic>{
      'content': text,
      'parent_id': parentId,
    };
    return post(
      '/api/v1/projects/$projectId/comments',
      body: {'comment': commentBody},
    );
  }

  // Funding methods
  Future<http.Response> updateProjectFundingGoal(
    String projectId,
    double goal,
  ) async {
    return put(
      '/api/v1/projects/$projectId',
      body: {
        'project': {'funding_goal': goal},
      },
    );
  }

  Future<http.Response> submitFundingRequest(
    String projectId,
    double amount,
    String message,
  ) async {
    return post(
      '/api/v1/projects/$projectId/fund/request',
      body: {
        'funding_request': {'amount': amount, 'note': message},
      },
    );
  }

  Future<http.Response> getFundingRequests(String projectId) async {
    return get('/api/v1/projects/$projectId/fund');
  }

  Future<http.Response> approveFundingRequest(
    String projectId,
    String requestId,
  ) async {
    return post(
      '/api/v1/projects/$projectId/fund/verify',
      body: {'id': requestId},
    );
  }

  Future<http.Response> rejectFundingRequest(
    String projectId,
    String requestId,
  ) async {
    return post(
      '/api/v1/projects/$projectId/fund/reject',
      body: {'id': requestId},
    );
  }

  // Resource methods
  Future<http.Response> getResources(String projectId) async {
    return get('/api/v1/projects/$projectId/resources');
  }

  Future<http.Response> createResource(
    String projectId,
    String title,
    String url, {
    String? description,
  }) async {
    return post(
      '/api/v1/projects/$projectId/resources',
      body: {
        'resource': {
          'title': title,
          'url': url,
          if (description != null) 'description': description,
        },
      },
    );
  }

  Future<http.Response> updateResource(
    String projectId,
    String resourceId,
    String title,
    String url, {
    String? description,
  }) async {
    return put(
      '/api/v1/projects/$projectId/resources/$resourceId',
      body: {
        'resource': {
          'title': title,
          'url': url,
          if (description != null) 'description': description,
        },
      },
    );
  }

  Future<http.Response> deleteResource(
    String projectId,
    String resourceId,
  ) async {
    return delete('/api/v1/projects/$projectId/resources/$resourceId');
  }

  Future<http.Response> approveResource(
    String projectId,
    String resourceId,
  ) async {
    return post('/api/v1/projects/$projectId/resources/$resourceId/approve');
  }

  Future<http.Response> rejectResource(
    String projectId,
    String resourceId,
  ) async {
    return post('/api/v1/projects/$projectId/resources/$resourceId/reject');
  }
}

/// Singleton instance
ProjectService projectService = ProjectService(
  baseUrl: 'https://web06.cs.ait.ac.th/be',
);
