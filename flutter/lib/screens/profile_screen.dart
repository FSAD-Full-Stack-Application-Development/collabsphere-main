// lib/screens/profile_screen.dart
import 'package:cached_network_image/cached_network_image.dart';
import 'package:collab_sphere/screens/splash.dart';
import 'package:collab_sphere/store/auth_controller.dart';
import 'package:collab_sphere/store/token.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../api/project.dart';
import 'dart:convert';
import '../models/project.dart';
import '../theme.dart';
import '../utils/responsive.dart';
import 'project_detail_page.dart';
import '../widgets/project_card_profile.dart';
import 'edit_profile.dart';
import 'project_list_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return GetBuilder<AuthController>(
      init: authController,
      builder: (controller) {
        final currentUser = controller.user;

        // Show loading screen while fetching user data
        if (controller.isLoading) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(color: AppTheme.accentGold),
            ),
          );
        }

        // Show no user data only when not authenticated
        if (currentUser == null && !controller.isAuthenticated) {
          return const Scaffold(
            body: Center(child: Text('No user data available')),
          );
        }

        // If we have a user but it's null somehow, show loading
        if (currentUser == null) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(color: AppTheme.accentGold),
            ),
          );
        }

        return const ProfileScreenContent();
      },
    );
  }
}

class ProfileScreenContent extends StatefulWidget {
  const ProfileScreenContent({super.key});

  @override
  State<ProfileScreenContent> createState() => _ProfileScreenContentState();
}

class _ProfileScreenContentState extends State<ProfileScreenContent> {
  late Future<List<Project>> _projectsFuture;

  @override
  void initState() {
    super.initState();
    _projectsFuture = fetchMyProjects();
  }

  Future<List<Project>> fetchMyProjects() async {
    final currentUser = authController.user;
    if (currentUser == null) return [];

    final resp = await projectService.getProjects();
    if (resp.statusCode == 200) {
      final data = jsonDecode(resp.body);
      final projects =
          (data['data'] as List?)?.map((e) => Project.fromJson(e)).toList() ??
          [];
      return projects
          .where(
            (p) =>
                p.owner.id == currentUser.id ||
                (p.collaborators ?? []).any((u) => u.id == currentUser.id),
          )
          .toList();
    }
    return [];
  }

  Future<void> _refreshProjects() async {
    // Refresh user data and projects
    await authController.fetchProfile();
    setState(() {
      _projectsFuture = fetchMyProjects();
    });
  }

  @override
  Widget build(BuildContext context) {
    final padding = Responsive.getPadding(context);

    return RefreshIndicator(
      onRefresh: _refreshProjects,
      child: FutureBuilder<List<Project>>(
        future: _projectsFuture,
        builder: (context, snapshot) {
          final projects = snapshot.data ?? [];

          return CustomScrollView(
            slivers: [
              // Header
              SliverAppBar(
                expandedHeight: 220,
                floating: false,
                pinned: true,
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
                              radius: 40, // Reduced from 50
                              backgroundColor: AppTheme.accentGold,
                              backgroundImage:
                                  authController.user!.avatarUrl != null &&
                                          authController
                                              .user!
                                              .avatarUrl!
                                              .isNotEmpty
                                      ? CachedNetworkImageProvider(
                                        authController.user!.avatarUrl!,
                                      )
                                      : null,
                              child:
                                  authController.user!.avatarUrl == null ||
                                          authController
                                              .user!
                                              .avatarUrl!
                                              .isEmpty
                                      ? Text(
                                        _getInitials(
                                          authController.user!.fullName,
                                        ),
                                        style: const TextStyle(
                                          fontSize: 20,
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      )
                                      : null,
                            ),
                            SizedBox(height: AppTheme.spacingXs),
                            Text(
                              authController.user!.fullName,
                              style: const TextStyle(
                                fontSize: 18, // Reduced from 20
                                fontWeight: FontWeight.w800,
                                color: AppTheme.textDark,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              authController.user!.email,
                              style: const TextStyle(
                                fontSize: 12, // Reduced from 13
                                color: AppTheme.textMedium,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                actions: [
                  IconButton(
                    icon: const Icon(Icons.edit, color: Colors.white),
                    onPressed:
                        () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const EditProfileScreen(),
                          ),
                        ),
                  ),
                ],
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
                      if (authController.user!.country != null &&
                          authController.user!.country!.isNotEmpty)
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
                                authController.user!.country!,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppTheme.textLight,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      if (authController.user!.university != null &&
                          authController.user!.university!.isNotEmpty)
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
                                  authController.user!.university!,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: AppTheme.textLight,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      if (authController.user!.department != null &&
                          authController.user!.department!.isNotEmpty)
                        Padding(
                          padding: EdgeInsets.only(top: AppTheme.spacingXs),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.account_tree,
                                size: 14,
                                color: AppTheme.textLight,
                              ),
                              const SizedBox(width: AppTheme.spacingXs),
                              Flexible(
                                child: Text(
                                  authController.user!.department!,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: AppTheme.textLight,
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
              if (authController.user!.bio != null &&
                  authController.user!.bio!.isNotEmpty)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(
                      padding,
                      AppTheme.spacingXs,
                      padding,
                      0,
                    ),
                    child: Text(
                      authController.user!.bio!,
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppTheme.textMedium,
                      ),
                      textAlign: TextAlign.center,
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
                  child: _statsRow(projects.length),
                ),
              ),

              // Tags
              if (authController.user!.tags.isNotEmpty)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(
                      padding,
                      AppTheme.spacingLg,
                      padding,
                      0,
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
                              authController.user!.tags.map((tag) {
                                return Chip(
                                  label: Text(
                                    tag,
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                  backgroundColor: AppTheme.accentGold
                                      .withAlpha((0.1 * 255).round()),
                                  side: BorderSide(
                                    color: AppTheme.accentGold.withAlpha(
                                      (0.3 * 255).round(),
                                    ),
                                  ),
                                );
                              }).toList(),
                        ),
                      ],
                    ),
                  ),
                ),

              // My Projects
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(
                    padding,
                    AppTheme.spacingLg,
                    padding,
                    0,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          'My Projects',
                          style: Theme.of(
                            context,
                          ).textTheme.titleLarge?.copyWith(
                            color: AppTheme.textDark,
                            fontWeight: FontWeight.w600,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (projects.length > 4)
                        TextButton(
                          style: TextButton.styleFrom(
                            foregroundColor: AppTheme.accentGold,
                            textStyle: const TextStyle(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          onPressed:
                              () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder:
                                      (_) => ProjectListScreen(
                                        title:
                                            '${authController.user!.fullName}\'s Projects',
                                        userId: authController.user!.id,
                                      ),
                                ),
                              ),
                          child: const Text('See More'),
                        ),
                    ],
                  ),
                ),
              ),

              // Project List (limited to 4)
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(
                    padding,
                    AppTheme.spacingMd,
                    padding,
                    0,
                  ),
                  child:
                      projects.isEmpty
                          ? const SizedBox(
                            height: 200,
                            child: Center(child: Text('No projects yet')),
                          )
                          : LayoutBuilder(
                            builder: (context, constraints) {
                              final crossAxisCount = Responsive.getValue(
                                context,
                                mobile: 2,
                                tablet: 2,
                                desktop: 4,
                                largeDesktop: 4,
                              );
                              final displayProjects =
                                  projects.length > 4
                                      ? projects.take(4).toList()
                                      : projects;
                              final spacing = Responsive.getSpacing(context);

                              return Wrap(
                                spacing: spacing,
                                runSpacing: spacing,
                                children:
                                    displayProjects.map((p) {
                                      final cardWidth =
                                          (constraints.maxWidth -
                                              (spacing *
                                                  (crossAxisCount - 1))) /
                                          crossAxisCount;
                                      return SizedBox(
                                        width: cardWidth,
                                        child:
                                            p.title.isEmpty ||
                                                    p.projectStat == null
                                                ? GestureDetector(
                                                  onTap:
                                                      () => Navigator.push(
                                                        context,
                                                        MaterialPageRoute(
                                                          builder:
                                                              (
                                                                _,
                                                              ) => ProjectDetailPage(
                                                                projectId: p.id,
                                                                isOwner:
                                                                    p
                                                                        .owner
                                                                        .id ==
                                                                    authController
                                                                        .user!
                                                                        .id,
                                                              ),
                                                        ),
                                                      ),
                                                  child: Container(
                                                    padding:
                                                        const EdgeInsets.all(
                                                          20,
                                                        ),
                                                    decoration: BoxDecoration(
                                                      color: Colors.grey[200],
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            10,
                                                          ),
                                                    ),
                                                    child: Center(
                                                      child: Text(
                                                        p.title.isNotEmpty
                                                            ? p.title
                                                            : 'Unnamed Project',
                                                        style: const TextStyle(
                                                          fontSize: 14,
                                                          color: Colors.black54,
                                                          fontStyle:
                                                              FontStyle.italic,
                                                        ),
                                                        textAlign:
                                                            TextAlign.center,
                                                      ),
                                                    ),
                                                  ),
                                                )
                                                : ProjectCardProfile(
                                                  project: p,
                                                  showStats: true,
                                                  onTap:
                                                      () => Navigator.push(
                                                        context,
                                                        MaterialPageRoute(
                                                          builder:
                                                              (
                                                                _,
                                                              ) => ProjectDetailPage(
                                                                projectId: p.id,
                                                                isOwner:
                                                                    p
                                                                        .owner
                                                                        .id ==
                                                                    authController
                                                                        .user!
                                                                        .id,
                                                              ),
                                                        ),
                                                      ),
                                                ),
                                      );
                                    }).toList(),
                              );
                            },
                          ),
                ),
              ),

              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: padding),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      _settingsTile(Icons.logout, 'Logout', () {
                        authController.logout();
                        tokenStore.deleteToken();
                        Navigator.of(context).pushReplacement(
                          MaterialPageRoute(builder: (_) => SplashScreen()),
                        );
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Logged out!')),
                        );
                      }, color: Colors.red),
                      const SizedBox(height: AppTheme.spacingLg),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  // ──────────────────────────────────────
  // Stats
  // ──────────────────────────────────────
  Widget _statsRow(int projectCount) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [_statItem('$projectCount', 'Projects')],
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

  Widget _settingsTile(
    IconData icon,
    String title,
    VoidCallback onTap, {
    Color? color,
  }) {
    return ListTile(
      leading: Icon(icon, color: color ?? AppTheme.textMedium, size: 20),
      title: Text(
        title,
        style: TextStyle(color: color ?? AppTheme.textDark, fontSize: 14),
      ),
      trailing: const Icon(Icons.chevron_right, size: 20),
      onTap: onTap,
      contentPadding: EdgeInsets.zero,
      dense: true,
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
