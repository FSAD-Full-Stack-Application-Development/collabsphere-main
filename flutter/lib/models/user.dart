class User {
  final String id;
  String fullName;
  String email;
  String? bio;
  String? avatarUrl;
  String? country;
  String? university;
  String? department;
  List<String> tags;

  User({
    required this.id,
    required this.fullName,
    required this.email,
    this.bio,
    this.avatarUrl,
    this.country,
    this.university,
    this.department,
    required this.tags,
  });

  /// Parse JSON → User
  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'].toString(),
      fullName: json['full_name'] as String,
      email: json['email'] as String,
      bio: json['bio'] as String?,
      avatarUrl: json['avatar_url'] as String?,
      country: json['country'] as String?,
      university: json['university'] as String?,
      department: json['department'] as String?,
      tags:
          (json['tags'] is List)
              ? (json['tags'] as List).map((e) => e as String).toList()
              : <String>[],
    );
  }

  /// Convert User → JSON (e.g., for profile update)
  Map<String, dynamic> toJson() {
    return {
      'full_name': fullName,
      'email': email,
      'bio': bio,
      'avatar_url': avatarUrl,
      'country': country,
      'university': university,
      'department': department,
      'tags': tags,
    };
  }

  @override
  String toString() {
    return 'User(id: $id, name: $fullName, email: $email, country: $country)';
  }
}
