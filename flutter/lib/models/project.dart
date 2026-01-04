import 'dart:convert';
import 'user.dart'; // <-- import your existing User model

/// Paginated project list response
class ProjectListResponse {
  final List<Project> data;
  final PaginationMeta meta;

  ProjectListResponse({required this.data, required this.meta});

  factory ProjectListResponse.fromJson(Map<String, dynamic> json) {
    return ProjectListResponse(
      data:
          (json['data'] as List<dynamic>)
              .map((e) => Project.fromJson(e as Map<String, dynamic>))
              .toList(),
      meta: PaginationMeta.fromJson(json['meta'] as Map<String, dynamic>),
    );
  }

  static ProjectListResponse fromRawJson(String str) =>
      ProjectListResponse.fromJson(json.decode(str) as Map<String, dynamic>);
}

/// Individual Project model
class Project {
  final String id;
  final String title;
  final String? description;
  final String status;
  final String visibility;
  final bool showFunds;
  final double? fundingGoal;
  final double? currentFunding;
  final DateTime? createdAt;
  final User owner;
  final List<Tag> tags;
  final List<User>? collaborators;
  final ProjectStat? projectStat;
  int voteCount;
  final List<Comment> comments; //  NEW

  Project({
    required this.id,
    required this.title,
    this.description,
    required this.status,
    required this.visibility,
    required this.showFunds,
    this.fundingGoal,
    this.currentFunding,
    this.createdAt,
    required this.owner,
    required this.tags,
    this.collaborators,
    this.projectStat,
    this.voteCount = 0,
    this.comments = const [],
  });

  factory Project.fromJson(Map<String, dynamic> json) {
    return Project(
      id: json['id'],
      title: json['title'] ?? '',
      description: json['description'],
      status: json['status'] ?? '',
      visibility: json['visibility'] ?? '',
      showFunds: json['show_funds'] ?? false,
      fundingGoal:
          json['funding_goal'] != null
              ? double.tryParse(json['funding_goal'].toString())
              : null,
      currentFunding:
          json['current_funding'] != null
              ? double.tryParse(json['current_funding'].toString())
              : null,
      createdAt:
          json['created_at'] != null
              ? DateTime.parse(json['created_at'])
              : null,
      owner: User.fromJson(json['owner'] as Map<String, dynamic>),
      tags:
          (json['tags'] as List<dynamic>)
              .map((t) => Tag.fromJson(t as Map<String, dynamic>))
              .toList(),
      collaborators:
          json['collaborators'] != null
              ? (json['collaborators'] as List<dynamic>)
                  .map((c) => User.fromJson(c as Map<String, dynamic>))
                  .toList()
              : null,
      projectStat:
          json['project_stat'] != null
              ? ProjectStat.fromJson(
                json['project_stat'] as Map<String, dynamic>,
              )
              : null,
      voteCount: json['project_stat']?['total_votes'] ?? 0,
      comments:
          json['comments'] != null
              ? (json['comments'] as List<dynamic>)
                  .map((c) => Comment.fromJson(c as Map<String, dynamic>))
                  .toList()
              : [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "id": id,
      "title": title,
      "description": description,
      "status": status,
      "visibility": visibility,
      "show_funds": showFunds,
      "funding_goal": fundingGoal,
      "current_funding": currentFunding,
      "owner": owner.toJson(),
      "tags": tags.map((t) => t.toJson()).toList(),
      "collaborators": collaborators?.map((c) => c.toJson()).toList(),
      "project_stat": projectStat?.toJson(),
      "vote_count": voteCount,
      "comments": comments.map((c) => c.toJson()).toList(),
    };
  }

  // Helper method to check if a user is the owner
  bool isOwnerFor(String? userId) => owner.id == userId;
}

/// Tag model
class Tag {
  final String id;
  final String tagName;

  Tag({required this.id, required this.tagName});

  factory Tag.fromJson(Map<String, dynamic> json) {
    return Tag(id: json['id'].toString(), tagName: json['tag_name'] ?? '');
  }

  Map<String, dynamic> toJson() => {"id": id, "tag_name": tagName};
}

/// Project statistics
class ProjectStat {
  final int totalViews;
  var totalVotes;
  final int totalComments;

  ProjectStat({
    required this.totalViews,
    required this.totalVotes,
    required this.totalComments,
  });

  factory ProjectStat.fromJson(Map<String, dynamic> json) {
    return ProjectStat(
      totalViews: int.tryParse(json['total_views']?.toString() ?? '0') ?? 0,
      totalVotes: int.tryParse(json['total_votes']?.toString() ?? '0') ?? 0,
      totalComments:
          int.tryParse(json['total_comments']?.toString() ?? '0') ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
    "total_views": totalViews,
    "total_votes": totalVotes,
    "total_comments": totalComments,
  };
}

class Comment {
  final String id;
  final String author;
  final String text;
  final DateTime timestamp;
  int likes;
  List<Comment> replies;

  Comment({
    required this.id,
    required this.author,
    required this.text,
    required this.timestamp,
    this.likes = 0,
    List<Comment>? replies,
  }) : replies = replies ?? [];

  factory Comment.fromJson(Map<String, dynamic> json) {
    // Ensure id is present from backend
    String id = json['id']?.toString() ?? '';
    if (id.isEmpty) {
      throw FormatException('Comment missing required id field');
    }
    return Comment(
      id: id,
      author:
          (json['author'] ?? json['user']?['full_name'] ?? 'Anonymous')
              .toString(),
      text: (json['text'] ?? json['content'] ?? '').toString(),
      timestamp:
          json['timestamp'] != null
              ? DateTime.parse(json['timestamp'].toString())
              : DateTime.parse(
                (json['created_at'] ?? DateTime.now().toIso8601String())
                    .toString(),
              ),
      likes: json['likes'] ?? 0,
      replies:
          (json['replies'] as List<dynamic>? ?? [])
              .map((e) => Comment.fromJson(e))
              .toList(),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'author': author,
    'text': text,
    'timestamp': timestamp.toIso8601String(),
    'likes': likes,
    'replies': replies.map((e) => e.toJson()).toList(),
  };
}

/// Pagination metadata
class PaginationMeta {
  final int currentPage;
  final int? nextPage;
  final int? prevPage;
  final int totalPages;
  final int totalCount;

  PaginationMeta({
    required this.currentPage,
    this.nextPage,
    this.prevPage,
    required this.totalPages,
    required this.totalCount,
  });

  factory PaginationMeta.fromJson(Map<String, dynamic> json) {
    return PaginationMeta(
      currentPage: json['current_page'] ?? 1,
      nextPage: json['next_page'],
      prevPage: json['prev_page'],
      totalPages: json['total_pages'] ?? 1,
      totalCount: json['total_count'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
    "current_page": currentPage,
    "next_page": nextPage,
    "prev_page": prevPage,
    "total_pages": totalPages,
    "total_count": totalCount,
  };
}
