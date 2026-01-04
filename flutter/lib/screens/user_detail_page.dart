import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get/instance_manager.dart';
import 'dart:convert';
import '../api/auth.dart';
import '../api/project.dart';
import '../models/user.dart';
import '../models/project.dart';
import '../theme.dart';
import '../widgets/project_card_profile.dart';
import '../widgets/empty_states.dart';
import 'project_detail_page.dart';

class UserDetailPage extends StatefulWidget {
  final String userId;
  final String? userName; // Optional display name while loading

  const UserDetailPage({super.key, required this.userId, this.userName});

  @override
  State<UserDetailPage> createState() => _UserDetailPageState();
}

class _UserDetailPageState extends State<UserDetailPage> {
  User? _user;
  List<Project> _userProjects = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Fetch user details
      final userResponse = await authService.getUserById(widget.userId);
      if (userResponse.statusCode == 200) {
        final userData = jsonDecode(userResponse.body);
        _user = User.fromJson(userData);
      } else {
        throw Exception('Failed to load user');
      }

      // Fetch all projects and filter by user
      final projectsResponse = await projectService.getProjects();
      if (projectsResponse.statusCode == 200) {
        final data = jsonDecode(projectsResponse.body);
        final allProjects =
            (data['data'] as List?)?.map((e) => Project.fromJson(e)).toList() ??
            [];

        // Filter projects where user is owner or collaborator
        _userProjects =
            allProjects.where((p) {
              return p.owner.id == widget.userId ||
                  (p.collaborators ?? []).any((u) => u.id == widget.userId);
            }).toList();
      }

      setState(() => _isLoading = false);
    } catch (e) {
      setState(() {
        _error = 'Failed to load user data';
        _isLoading = false;
      });
    }
  }

  Future<void> _refreshData() async {
    await _loadUserData();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: Text(widget.userName ?? 'User Profile'),
          backgroundColor: AppTheme.bgWhite,
        ),
        body: const Center(
          child: CircularProgressIndicator(color: AppTheme.accentGold),
        ),
      );
    }

    if (_error != null || _user == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('User Profile'),
          backgroundColor: AppTheme.bgWhite,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text(_error ?? 'User not found'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _refreshData,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    final isMobile = MediaQuery.of(context).size.width < 768;
    final padding = isMobile ? AppTheme.spacingMd : AppTheme.spacingLg;

    return Scaffold(
      backgroundColor: AppTheme.bgLight,
      body: RefreshIndicator(
        onRefresh: _refreshData,
        child: CustomScrollView(
          slivers: [
            // Header with gradient
            SliverAppBar(
              expandedHeight: 220,
              floating: false,
              pinned: true,
              backgroundColor: AppTheme.bgWhite,
              flexibleSpace: FlexibleSpaceBar(
                background: Stack(
                  fit: StackFit.expand,
                  children: [
                    Container(color: AppTheme.bgLight),
                    Positioned(
                      top: 0,
                      left: 0,
                      right: 0,
                      child: Container(
                        height: 200,
                        decoration: BoxDecoration(
                          gradient: AppTheme.gradientMain,
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 0,
                      left: padding,
                      right: padding,
                      child: Column(
                        children: [
                          CircleAvatar(
                            radius: 40,
                            backgroundColor: AppTheme.accentGold,
                            backgroundImage:
                                _user!.avatarUrl != null &&
                                        _user!.avatarUrl!.isNotEmpty
                                    ? CachedNetworkImageProvider(
                                      _user!.avatarUrl!,
                                    )
                                    : null,
                            child:
                                _user!.avatarUrl == null ||
                                        _user!.avatarUrl!.isEmpty
                                    ? Text(
                                      _getInitials(_user!.fullName),
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 24,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    )
                                    : null,
                          ),
                          SizedBox(height: AppTheme.spacingXs),
                          Text(
                            _user!.fullName,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: AppTheme.textDark,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _user!.email,
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppTheme.textMedium,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Location & University
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  padding,
                  AppTheme.spacingMd,
                  padding,
                  0,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    if (_user!.country != null && _user!.country!.isNotEmpty)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.location_on,
                            size: 14,
                            color: AppTheme.textLight,
                          ),
                          const SizedBox(width: AppTheme.spacingXs),
                          Flexible(
                            child: Text(
                              _user!.country!,
                              style: const TextStyle(
                                fontSize: 13,
                                color: AppTheme.textMedium,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    if (_user!.university != null &&
                        _user!.university!.isNotEmpty)
                      Padding(
                        padding: EdgeInsets.only(top: AppTheme.spacingXs),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.school,
                              size: 14,
                              color: AppTheme.textLight,
                            ),
                            const SizedBox(width: AppTheme.spacingXs),
                            Flexible(
                              child: Text(
                                _user!.university!,
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: AppTheme.textMedium,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    if (_user!.department != null &&
                        _user!.department!.isNotEmpty)
                      Padding(
                        padding: EdgeInsets.only(top: AppTheme.spacingXs),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.work_outline,
                              size: 14,
                              color: AppTheme.textLight,
                            ),
                            const SizedBox(width: AppTheme.spacingXs),
                            Flexible(
                              child: Text(
                                _user!.department!,
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: AppTheme.textMedium,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),

            // Bio
            if (_user!.bio != null && _user!.bio!.isNotEmpty)
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(
                    padding,
                    AppTheme.spacingMd,
                    padding,
                    0,
                  ),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppTheme.borderColor.withOpacity(0.3),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'About',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textDark,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _user!.bio!,
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppTheme.textMedium,
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

            // Stats
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  padding,
                  AppTheme.spacingMd,
                  padding,
                  0,
                ),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppTheme.borderColor.withOpacity(0.3),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _statItem('${_userProjects.length}', 'Projects'),
                    ],
                  ),
                ),
              ),
            ),

            // Tags
            if (_user!.tags.isNotEmpty)
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(
                    padding,
                    AppTheme.spacingMd,
                    padding,
                    0,
                  ),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppTheme.borderColor.withOpacity(0.3),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Skills & Interests',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textDark,
                          ),
                        ),
                        SizedBox(height: AppTheme.spacingXs),
                        Wrap(
                          spacing: AppTheme.spacingXs,
                          runSpacing: AppTheme.spacingXs,
                          children:
                              _user!.tags.map((tag) {
                                return Chip(
                                  label: Text(
                                    tag,
                                    style: const TextStyle(fontSize: 11),
                                  ),
                                  backgroundColor: AppTheme.accentGold
                                      .withOpacity(0.1),
                                  labelStyle: const TextStyle(
                                    color: AppTheme.accentGold,
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  materialTapTargetSize:
                                      MaterialTapTargetSize.shrinkWrap,
                                );
                              }).toList(),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

            // Projects Section Header
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  padding,
                  AppTheme.spacingLg,
                  padding,
                  AppTheme.spacingXs,
                ),
                child: Text(
                  'Projects',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: AppTheme.textDark,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),

            // Projects Grid
            if (_userProjects.isEmpty)
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.all(padding),
                  child: const Center(
                    child: NoProjectsState(
                      customMessage: 'This user has no projects yet.',
                    ),
                  ),
                ),
              )
            else
              SliverPadding(
                padding: EdgeInsets.symmetric(horizontal: padding),
                sliver: SliverGrid(
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: isMobile ? 2 : 3,
                    mainAxisSpacing: AppTheme.spacingMd,
                    crossAxisSpacing: AppTheme.spacingMd,
                    childAspectRatio: 0.8,
                  ),
                  delegate: SliverChildBuilderDelegate((context, index) {
                    final project = _userProjects[index];
                    final screenWidth = MediaQuery.of(context).size.width;
                    final cardWidth =
                        isMobile
                            ? (screenWidth - padding * 2 - AppTheme.spacingMd) /
                                2
                            : (screenWidth -
                                    padding * 2 -
                                    AppTheme.spacingMd * 2) /
                                3;

                    return GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder:
                                (_) => ProjectDetailPage(projectId: project.id),
                          ),
                        );
                      },
                      child: ProjectCardProfile(
                        project: project,
                        onTap: () {
                          Get.to(
                            () => ProjectDetailPage(projectId: project.id),
                          );
                        },
                      ),
                    );
                  }, childCount: _userProjects.length),
                ),
              ),

            // Bottom spacing
            const SliverToBoxAdapter(child: SizedBox(height: 100)),
          ],
        ),
      ),
    );
  }

  Widget _statItem(String value, String label) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: AppTheme.textDark,
            ),
          ),
          Text(
            label,
            style: const TextStyle(fontSize: 11, color: AppTheme.textLight),
          ),
        ],
      ),
    );
  }

  String _getInitials(String fullName) {
    final names = fullName.trim().split(' ');
    if (names.length >= 2) {
      return '${names[0][0]}${names[1][0]}'.toUpperCase();
    }
    return fullName.isNotEmpty ? fullName[0].toUpperCase() : 'U';
  }
}
