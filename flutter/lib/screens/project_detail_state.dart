import 'package:flutter/material.dart';
import 'dart:convert';
import '../models/project.dart';
import '../models/user.dart';
import '../api/project.dart';
import '../store/auth_controller.dart';

class ProjectDetailState extends ChangeNotifier {
  Project? project;
  final String projectId;

  // State variables
  List<dynamic> _collaborations = [];
  List<dynamic> _collabRequests = [];
  bool _collabLoading = false;
  bool _collabRequestSent = false;
  bool _collabRequestsLoading = false;
  bool _voted = false;
  bool _projectLoaded = false;

  bool isOwner = false;
  bool isCollaborator = false;
  bool isNormalUser = false;

  Map<String, bool> _expandedComments = {};
  Map<String, bool> _expandedReplies = {};

  // Resources state
  List<dynamic> _resources = [];
  bool _resourcesLoading = false;

  ProjectDetailState({required this.projectId}) {
    _fetchProjectDetail(projectId);
  }

  void initialize() {
    // Re-fetch project data when called after edit
    _fetchProjectDetail(projectId);
  }

  void _updateUserRole() {
    final user = authController.user;
    final proj = project;
    if (user == null || proj == null) {
      isOwner = false;
      isCollaborator = false;
      isNormalUser = true;
      return;
    }
    isOwner = user.id == proj.owner.id;
    isCollaborator =
        !isOwner && (proj.collaborators?.any((c) => c.id == user.id) ?? false);
    isNormalUser = !isOwner && !isCollaborator;
    // Fetch collaboration requests for owners (to show pending) and normal users (to check if already requested)
    if (isOwner || isNormalUser) _fetchCollabRequests();
  }

  Future<void> _fetchProjectDetail(String projectId) async {
    try {
      final resp = await projectService.getProject(projectId);
      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body);
        project = Project.fromJson(data);
        _projectLoaded = true;
        _voted = data['user_voted'] ?? false;
        _updateUserRole();
        _fetchCollaborations();
        _fetchResources();
        notifyListeners();
      }
    } catch (e) {
      // keep the passed project
    }
  }

  Future<void> _fetchCollaborations() async {
    if (project == null) return;
    _collabLoading = true;
    notifyListeners();
    try {
      final resp = await projectService.getCollaborations(project!.id);
      if (resp.statusCode == 200) {
        _collaborations = jsonDecode(resp.body);
        // Update project.collaborators from the collaborations data
        project = Project(
          id: project!.id,
          title: project!.title,
          description: project!.description,
          status: project!.status,
          visibility: project!.visibility,
          showFunds: project!.showFunds,
          fundingGoal: project!.fundingGoal,
          currentFunding: project!.currentFunding,
          owner: project!.owner,
          tags: project!.tags,
          collaborators:
              _collaborations
                  .map(
                    (collab) =>
                        User.fromJson(collab['user'] as Map<String, dynamic>),
                  )
                  .toList(),
          projectStat: project!.projectStat,
          voteCount: project!.voteCount,
          comments: project!.comments,
        );
        _updateUserRole();
      }
    } finally {
      _collabLoading = false;
      notifyListeners();
    }
  }

  Future<void> _fetchResources() async {
    if (project == null) return;
    _resourcesLoading = true;
    notifyListeners();
    try {
      final resp = await projectService.getResources(project!.id);
      if (resp.statusCode == 200) {
        _resources = jsonDecode(resp.body);
      }
    } finally {
      _resourcesLoading = false;
      notifyListeners();
    }
  }

  Future<void> _fetchCollabRequests() async {
    if (project == null) return;
    _collabRequestsLoading = true;
    notifyListeners();
    try {
      final resp = await projectService.getCollaborationRequests(project!.id);
      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body);
        _collabRequests = data['requests'] ?? [];
        // Check if user has already sent a pending request
        _collabRequestSent = _collabRequests.any(
          (req) => req['status'] == 'pending',
        );
      } else {
        _collabRequestSent = false;
      }
    } catch (e) {
      _collabRequestSent = false;
    } finally {
      _collabRequestsLoading = false;
      notifyListeners();
    }
  }

  Future<void> requestCollaboration() async {
    if (project == null) return;
    _collabRequestSent = false;
    notifyListeners();
    final resp = await projectService.createCollaborationRequest(project!.id);
    if (resp.statusCode == 200 || resp.statusCode == 201) {
      _collabRequestSent = true;
    } else {
      // Parse error message from response
      String errorMessage = 'Failed to send collaboration request';
      try {
        final errorData = jsonDecode(resp.body);
        if (errorData['error'] != null) {
          errorMessage = errorData['error'];
        }
      } catch (e) {
        // Use default error message if parsing fails
      }
      throw Exception('$errorMessage (${resp.statusCode})');
    }
    notifyListeners();
  }

  Future<void> approveCollabRequest(String userId) async {
    if (project == null) return;
    await projectService.approveCollaborationRequest(project!.id, userId);
    await _fetchCollabRequests();
    await _fetchCollaborations();
    _updateUserRole();
  }

  Future<void> rejectCollabRequest(String userId) async {
    if (project == null) return;
    await projectService.rejectCollaborationRequest(project!.id, userId);
    await _fetchCollabRequests();
    _updateUserRole();
  }

  Future<void> removeCollaboration(String collaborationId) async {
    if (project == null) return;
    await projectService.removeCollaboration(project!.id, collaborationId);
    await _fetchCollaborations();
    _updateUserRole();
  }

  // ────────────────────────────────────────────────
  // RESOURCES ACTIONS
  // ────────────────────────────────────────────────
  Future<void> addResource(String name, String url) async {
    if (project == null) return;
    try {
      final resp = await projectService.createResource(project!.id, name, url);
      if (resp.statusCode == 201) {
        _fetchResources();
        // Success feedback handled by UI
      } else {
        throw Exception('Failed to add resource: ${resp.body}');
      }
    } catch (e, stack) {
      print('[ERROR] Failed to add resource: $e\n$stack');
      rethrow;
    }
  }

  Future<void> approveResource(String resourceId) async {
    if (project == null) return;
    await projectService.approveResource(project!.id, resourceId);
    _fetchResources();
  }

  Future<void> rejectResource(String resourceId) async {
    if (project == null) return;
    try {
      final resp = await projectService.rejectResource(project!.id, resourceId);
      if (resp.statusCode == 200) {
        await _fetchResources();
      } else {
        throw Exception('Failed to reject resource: ${resp.body}');
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<void> deleteResource(String resourceId) async {
    if (project == null) return;
    try {
      final resp = await projectService.deleteResource(project!.id, resourceId);
      if (resp.statusCode == 200) {
        await _fetchResources();
      } else {
        throw Exception('Failed to delete resource: ${resp.body}');
      }
    } catch (e) {
      rethrow;
    }
  }

  // ────────────────────────────────────────────────
  // COMMENTS ACTIONS
  // ────────────────────────────────────────────────
  Future<void> deleteComment(String commentId) async {
    if (project == null) return;
    print('Deleting comment: id=$commentId');
    final resp = await projectService.deleteComment(project!.id, commentId);
    if (resp.statusCode == 200) {
      await _fetchProjectDetail(projectId);
    } else {
      throw Exception('Failed to delete comment: ${resp.body}');
    }
  }

  Future<void> reportComment(String commentId) async {
    if (project == null) return;
    final resp = await projectService.reportComment(project!.id, commentId);
    if (resp.statusCode != 200) {
      throw Exception('Failed to report comment: ${resp.body}');
    }
  }

  Future<void> addComment(String text) async {
    if (project == null) return;
    try {
      final response = await projectService.postComment(project!.id, text);
      if (response.statusCode == 201) {
        await _fetchProjectDetail(projectId);
      } else {
        throw Exception('Failed to add comment');
      }
    } catch (e, stack) {
      print('[ERROR] Failed to add comment: $e\n$stack');
      rethrow;
    }
  }

  Future<void> addReply(String parentId, String text) async {
    if (project == null) return;
    try {
      if (parentId.isEmpty) {
        throw ArgumentError('Cannot reply to a comment with empty id');
      }
      final response = await projectService.postReply(
        project!.id,
        text,
        parentId: parentId,
      );
      if (response.statusCode == 201) {
        await _fetchProjectDetail(projectId);
      } else {
        throw Exception('Failed to add reply');
      }
    } catch (e, stack) {
      print('[ERROR] Failed to add reply: $e\n$stack');
      rethrow;
    }
  }

  void likeComment(String commentId) {
    if (project == null) return;
    projectService.likeComment(project!.id, commentId).then((resp) {
      if (resp.statusCode == 200) {
        // Refresh to get updated likes
        _fetchProjectDetail(projectId);
      }
    });
  }

  void toggleVote() async {
    if (project == null) return;
    try {
      final response =
          _voted
              ? await projectService.unvoteProject(project!.id)
              : await projectService.voteProject(project!.id);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _voted = !_voted;
        project!.voteCount = data['vote_count'];
        notifyListeners();
      }
    } catch (e, stack) {
      print('[ERROR] Failed to toggle vote: $e\n$stack');
    }
  }

  // ────────────────────────────────────────────────
  // RESOURCES ACTIONS
  // ────────────────────────────────────────────────

  // Getters
  List<dynamic> get collaborations => _collaborations;
  List<dynamic> get collabRequests => _collabRequests;
  bool get collabLoading => _collabLoading;
  bool get collabRequestSent => _collabRequestSent;
  bool get collabRequestsLoading => _collabRequestsLoading;
  bool get voted => _voted;
  Map<String, bool> get expandedComments => _expandedComments;
  Map<String, bool> get expandedReplies => _expandedReplies;
  List<dynamic> get resources => _resources;
  bool get resourcesLoading => _resourcesLoading;

  // Setters for comment expansion
  void setCommentExpanded(String commentId, bool expanded) {
    _expandedComments[commentId] = expanded;
    notifyListeners();
  }

  void setReplyExpanded(String commentId, bool expanded) {
    _expandedReplies[commentId] = expanded;
    notifyListeners();
  }

  // Public method to refresh project data
  Future<void> refreshProject() async {
    await _fetchProjectDetail(projectId);
  }
}
