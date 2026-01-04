import 'dart:convert';
import 'package:collab_sphere/store/project_controller.dart';
import 'package:collab_sphere/utils/responsive.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:go_router/go_router.dart';
import '../models/project.dart';
import '../api/project.dart';
import '../screens/project_list_screen.dart';
import '../widgets/project_card_home.dart';
import '../theme.dart';
import 'create_project.dart';
import 'project_detail_page.dart';
import 'profile_screen.dart';
import 'top_screen.dart';
import 'notification_screen.dart';
import 'onboarding_screen.dart';
import '../widgets/gradient.dart';
import '../store/auth_controller.dart';
import '../store/tags_controller.dart';
import 'tags_browse_screen.dart';
import '../widgets/empty_states.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key, this.initialIndex = 0});
  final int initialIndex;
  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  late final PageController _pageController;
  int _currentIndex = 0;
  final _searchController = TextEditingController();
  bool _loading = false;
  bool _error = false;
  Future<void> fetchProjects() async {
    setState(() {
      _loading = true;
      _error = false;
    });
    try {
      final resp = await projectService.getProjects(perPage: 50);
      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body);
        final newProjects =
            (data['data'] as List?)?.map((e) => Project.fromJson(e)).toList() ??
            [];
        setState(() {
          projectController.projects = newProjects;
          projectController.forceUpdate();
        });
      } else {
        setState(() {
          _error = true;
        });
      }
    } catch (e) {
      setState(() {
        _error = true;
      });
    }
    setState(() {
      _loading = false;
    });
  }

  Future<void> fetchTopProjects() async {
    setState(() {
      _loading = true;
      _error = false;
    });
    try {
      final resp = await projectService.getTopProjects();
      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body);
        final newTopProjects =
            (data['data'] as List?)?.map((e) => Project.fromJson(e)).toList() ??
            [];
        setState(() {
          projectController.topProjects = newTopProjects;
          projectController.forceUpdate();
        });
      } else {
        setState(() {
          _error = true;
        });
      }
    } catch (e) {
      setState(() {
        _error = true;
      });
    }
    setState(() {
      _loading = false;
    });
  }

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: _currentIndex);
    _searchController.addListener(() => setState(() {}));
    fetchProjects();
    fetchTopProjects();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar:
          _currentIndex == 0
              ? AppBar(
                backgroundColor: Colors.transparent,
                elevation: 0,
                automaticallyImplyLeading: false,
                title: Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    GradientLogo(
                      size: Responsive.getValue(
                        context,
                        mobile: 32.0,
                        tablet: 36.0,
                        desktop: 18.0,
                        largeDesktop: 20.0,
                      ),
                    ),
                    SizedBox(width: Responsive.getSpacing(context)),
                    Expanded(
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'CollabSphere',
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: Responsive.getValue(
                              context,
                              mobile: 18.0,
                              tablet: 20.0,
                              desktop: 18.0,
                              largeDesktop: 20.0,
                            ),
                            letterSpacing: 0.5,
                            color: AppTheme.textDark,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                  ],
                ),
                centerTitle: false,
                actions: [
                  IconButton(
                    icon: const Icon(
                      Icons.help_outline,
                      color: AppTheme.textDark,
                    ),
                    onPressed: () {
                      Get.to(
                        () => OnboardingScreen(
                          onComplete: () {
                            Get.back();
                          },
                        ),
                      );
                    },
                    tooltip: 'View Guide',
                  ),
                ],
              )
              : null,
      body: Container(
        decoration: BoxDecoration(gradient: AppTheme.gradientSoft),
        child: GetBuilder<ProjectController>(
          init: projectController,
          builder:
              (_) => PageView(
                controller: _pageController,
                onPageChanged: (i) => setState(() => _currentIndex = i),
                children: [
                  RefreshIndicator(
                    onRefresh: () async {
                      await Future.wait<void>([
                        fetchProjects(),
                        fetchTopProjects(),
                      ]);
                    },
                    child: ResponsiveContainer(
                      maxWidth: 1400,
                      child: Column(
                        children: [
                          Padding(
                            padding: EdgeInsets.fromLTRB(
                              Responsive.getHorizontalPadding(context),
                              12,
                              Responsive.getHorizontalPadding(context),
                              0,
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: TextField(
                                    controller: _searchController,
                                    onSubmitted: (query) {
                                      if (query.trim().isNotEmpty) {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder:
                                                (_) => ProjectListScreen(
                                                  title: 'Search Results',
                                                  query: query.trim(),
                                                ),
                                          ),
                                        );
                                      }
                                    },
                                    decoration: InputDecoration(
                                      hintText: 'Search projects...',
                                      prefixIcon: Icon(
                                        Icons.search,
                                        size: Responsive.getValue(
                                          context,
                                          mobile: 18.0,
                                          tablet: 20.0,
                                          desktop: 18.0,
                                          largeDesktop: 20.0,
                                        ),
                                      ),
                                      suffixIcon: IconButton(
                                        icon: Icon(
                                          Icons.search,
                                          size: Responsive.getValue(
                                            context,
                                            mobile: 18.0,
                                            tablet: 20.0,
                                            desktop: 18.0,
                                            largeDesktop: 20.0,
                                          ),
                                        ),
                                        onPressed: () {
                                          final query =
                                              _searchController.text.trim();
                                          if (query.isNotEmpty) {
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder:
                                                    (_) => ProjectListScreen(
                                                      title: 'Search Results',
                                                      query: query,
                                                    ),
                                              ),
                                            );
                                          }
                                        },
                                      ),
                                      filled: true,
                                      fillColor: Colors.white,
                                      contentPadding: EdgeInsets.symmetric(
                                        horizontal:
                                            Responsive.getHorizontalPadding(
                                              context,
                                            ),
                                        vertical: Responsive.getVerticalPadding(
                                          context,
                                        ),
                                      ),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(
                                          Responsive.getBorderRadius(context),
                                        ),
                                        borderSide: BorderSide.none,
                                      ),
                                    ),
                                  ),
                                ),
                                SizedBox(width: Responsive.getSpacing(context)),
                                Container(
                                  decoration: BoxDecoration(
                                    gradient: AppTheme.gradientMain,
                                    borderRadius: BorderRadius.circular(
                                      Responsive.getBorderRadius(context),
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: AppTheme.accentGold.withOpacity(
                                          0.3,
                                        ),
                                        blurRadius: 8,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: ElevatedButton.icon(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.transparent,
                                      foregroundColor: Colors.white,
                                      shadowColor: Colors.transparent,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(
                                          Responsive.getBorderRadius(context),
                                        ),
                                      ),
                                      padding: EdgeInsets.symmetric(
                                        horizontal: Responsive.getValue(
                                          context,
                                          mobile: 14.0,
                                          tablet: 16.0,
                                          desktop: 18.0,
                                          largeDesktop: 20.0,
                                        ),
                                        vertical: Responsive.getVerticalPadding(
                                          context,
                                        ),
                                      ),
                                    ),
                                    icon: Icon(
                                      Icons.filter_list,
                                      size: Responsive.getValue(
                                        context,
                                        mobile: 16.0,
                                        tablet: 18.0,
                                        desktop: 18.0,
                                        largeDesktop: 20.0,
                                      ),
                                    ),
                                    label: Text(
                                      'Filter',
                                      style: TextStyle(
                                        fontSize: Responsive.getValue(
                                          context,
                                          mobile: 14.0,
                                          tablet: 15.0,
                                          desktop: 18.0,
                                          largeDesktop: 20.0,
                                        ),
                                      ),
                                    ),
                                    onPressed: _showFilterSheet,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 8),
                          Expanded(child: _buildHomePage()),
                        ],
                      ),
                    ),
                  ),
                  ResponsiveContainer(
                    padding: EdgeInsets.zero,
                    child: const NotificationScreen(),
                  ),
                  ResponsiveContainer(
                    padding: EdgeInsets.zero,
                    child: const TopScreen(),
                  ),
                  ResponsiveContainer(
                    padding: EdgeInsets.zero,
                    child: const ProfileScreen(),
                  ),
                ],
              ),
        ),
      ),
      floatingActionButton:
          (_currentIndex == 0 || _currentIndex == 3)
              ? Container(
                decoration: BoxDecoration(
                  gradient: AppTheme.gradientMain,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.accentGold.withOpacity(0.4),
                      blurRadius: 12,
                      spreadRadius: 2,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: FloatingActionButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder:
                            (_) => CreateProjectPage(
                              currentUser: authController.user!,
                            ),
                      ),
                    );
                  },
                  backgroundColor: Colors.transparent,
                  elevation: 0,
                  child: const Icon(Icons.add, color: Colors.white, size: 28),
                ),
              )
              : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: AppTheme.bgWhite,
          boxShadow: [AppTheme.shadowMd],
        ),
        child: BottomNavigationBar(
          type: BottomNavigationBarType.fixed,
          backgroundColor: AppTheme.bgWhite,
          selectedItemColor: AppTheme.accentGold,
          unselectedItemColor: AppTheme.textLight,
          elevation: 0,
          currentIndex: _currentIndex,
          onTap: (i) {
            setState(() => _currentIndex = i);
            _pageController.jumpToPage(i);
          },
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.notifications_outlined),
              label: 'Notifications',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.star_outline),
              label: 'Top',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_outline),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }

  void _showFilterSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        // Initialize local selections from current state
        var localSelectedSchool = 'All';
        var localSelectedDept = 'All';
        // Find country for current selected school (if any)
        var localSelectedCountry = 'All';
        final countries = [
          'All',
          ...projectController.countrySchoolDepartments.keys,
        ];
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            // Compute school list based on selected country
            List<String> schools = ['All'];
            if (localSelectedCountry == 'All') {
              for (var m in projectController.countrySchoolDepartments.values) {
                schools.addAll(m.keys);
              }
            } else {
              schools.addAll(
                projectController
                    .countrySchoolDepartments[localSelectedCountry]!
                    .keys,
              );
            }
            // Ensure uniqueness and stable ordering
            schools = schools.toSet().toList();
            // Compute departments for selected school
            List<String> departments = ['All'];
            if (localSelectedSchool != 'All') {
              if (localSelectedCountry != 'All') {
                departments.addAll(
                  projectController
                          .countrySchoolDepartments[localSelectedCountry]![localSelectedSchool] ??
                      [],
                );
              } else {
                // find the first school match across countries
                for (var c in projectController.countrySchoolDepartments.keys) {
                  if (projectController.countrySchoolDepartments[c]!
                      .containsKey(localSelectedSchool)) {
                    departments.addAll(
                      projectController
                          .countrySchoolDepartments[c]![localSelectedSchool]!,
                    );
                    break;
                  }
                }
              }
            }
            departments = departments.toSet().toList();
            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Filter Projects',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                    const SizedBox(height: 18),
                    DropdownButtonFormField<String>(
                      value: localSelectedCountry,
                      items:
                          countries
                              .map(
                                (c) =>
                                    DropdownMenuItem(value: c, child: Text(c)),
                              )
                              .toList(),
                      onChanged:
                          (v) => setModalState(() {
                            localSelectedCountry = v ?? 'All';
                            // reset dependent selections
                            localSelectedSchool = 'All';
                            localSelectedDept = 'All';
                          }),
                      decoration: InputDecoration(
                        labelText: 'Country',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    DropdownButtonFormField<String>(
                      value: localSelectedSchool,
                      items:
                          schools
                              .map(
                                (s) =>
                                    DropdownMenuItem(value: s, child: Text(s)),
                              )
                              .toList(),
                      onChanged:
                          (v) => setModalState(() {
                            localSelectedSchool = v ?? 'All';
                            localSelectedDept = 'All';
                          }),
                      decoration: InputDecoration(
                        labelText: 'University / School',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    DropdownButtonFormField<String>(
                      value: localSelectedDept,
                      items:
                          departments
                              .map(
                                (d) =>
                                    DropdownMenuItem(value: d, child: Text(d)),
                              )
                              .toList(),
                      onChanged:
                          (v) => setModalState(() {
                            localSelectedDept = v ?? 'All';
                          }),
                      decoration: InputDecoration(
                        labelText: 'Department',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () {
                            Navigator.pop(ctx);
                          },
                          child: const Text('Clear'),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: () {
                            Navigator.pop(ctx);
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder:
                                    (_) => ProjectListScreen(
                                      title: 'Filtered Projects',
                                      university:
                                          localSelectedSchool != 'All'
                                              ? localSelectedSchool
                                              : null,
                                      department:
                                          localSelectedDept != 'All'
                                              ? localSelectedDept
                                              : null,
                                    ),
                              ),
                            );
                          },
                          child: const Text('Apply'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _openDetail(Project p) {
    print('Opening project: ${p.title}');
    try {
      final isOwner = authController.user?.id == p.owner.id;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ProjectDetailPage(projectId: p.id, isOwner: isOwner),
        ),
      ).then((result) {
        // Refresh projects if project was edited
        if (result == true) {
          fetchProjects();
        }
      });
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error opening project: $e')));
    }
  }

  Widget _buildHomePage() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error) {
      return const Center(child: Text('Failed to load projects'));
    }
    final columns = Responsive.getOptimalGridColumns(
      context,
      projectController.topProjects.length,
      type: GridType.cards,
    );
    final spacing = Responsive.getSpacing(context);
    return SingleChildScrollView(
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: Responsive.getHorizontalPadding(context),
          vertical: Responsive.getVerticalPadding(context),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: AutoSizeText(
                    'Top Projects',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: AppTheme.textDark,
                      fontWeight: FontWeight.w600,
                      fontSize: Responsive.getValue(
                        context,
                        mobile: 18.0,
                        tablet: 20.0,
                        desktop: 18.0,
                        largeDesktop: 20.0,
                      ),
                    ),
                    maxLines: 1,
                    minFontSize: 14,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                TextButton(
                  style: TextButton.styleFrom(
                    foregroundColor: AppTheme.accentGold,
                    textStyle: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: Responsive.getValue(
                        context,
                        mobile: 14.0,
                        tablet: 15.0,
                        desktop: 18.0,
                        largeDesktop: 20.0,
                      ),
                    ),
                  ),
                  onPressed:
                      () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder:
                              (_) => const ProjectListScreen(
                                title: 'Top Projects',
                                topProjects: true,
                              ),
                        ),
                      ),
                  child: const AutoSizeText(
                    'See More',
                    maxLines: 1,
                    minFontSize: 10,
                  ),
                ),
              ],
            ),
            SizedBox(height: Responsive.getSpacing(context)),
            projectController.topProjects.isEmpty
                ? const SizedBox(height: 200, child: NoTopProjectsState())
                : LayoutBuilder(
                  builder: (context, constraints) {
                    final crossAxisCount = Responsive.getValue(
                      context,
                      mobile: 2,
                      tablet: 2,
                      desktop: 3,
                      largeDesktop: 4,
                    );
                    final displayProjects =
                        projectController.topProjects.length > 4
                            ? projectController.topProjects.take(4).toList()
                            : projectController.topProjects;

                    return Wrap(
                      spacing: spacing,
                      runSpacing: spacing,
                      children:
                          displayProjects.map((p) {
                            final cardWidth =
                                (constraints.maxWidth -
                                    (spacing * (crossAxisCount - 1))) /
                                crossAxisCount;
                            return SizedBox(
                              width: cardWidth,
                              child:
                                  p.title.isEmpty || p.projectStat == null
                                      ? GestureDetector(
                                        onTap: () => _openDetail(p),
                                        child: Container(
                                          padding: const EdgeInsets.all(20),
                                          decoration: BoxDecoration(
                                            color: Colors.grey[200],
                                            borderRadius: BorderRadius.circular(
                                              Responsive.getBorderRadius(
                                                context,
                                              ),
                                            ),
                                          ),
                                          child: Center(
                                            child: AutoSizeText(
                                              p.title.isNotEmpty
                                                  ? p.title
                                                  : 'Unnamed Project',
                                              style: TextStyle(
                                                fontSize: Responsive.getValue(
                                                  context,
                                                  mobile: 10,
                                                  tablet: 11,
                                                  desktop: 12,
                                                  largeDesktop: 18,
                                                ),
                                                color: Colors.black54,
                                                fontStyle: FontStyle.italic,
                                              ),
                                              textAlign: TextAlign.center,
                                              maxLines: 2,
                                              minFontSize: 10,
                                            ),
                                          ),
                                        ),
                                      )
                                      : ProjectCardHome(
                                        project: p,
                                        onTap: () => _openDetail(p),
                                      ),
                            );
                          }).toList(),
                    );
                  },
                ),
            SizedBox(
              height: Responsive.getValue(
                context,
                mobile: AppTheme.spacingLg,
                tablet: AppTheme.spacingLg,
                desktop: AppTheme.spacingXl,
                largeDesktop: AppTheme.spacingXl,
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: AutoSizeText(
                    'Top Tags',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: AppTheme.textDark,
                      fontWeight: FontWeight.w600,
                      fontSize: Responsive.getValue(
                        context,
                        mobile: 16.0,
                        tablet: 17.0,
                        desktop: 18.0,
                        largeDesktop: 20.0,
                      ),
                    ),
                    maxLines: 1,
                    minFontSize: 14,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                TextButton(
                  style: TextButton.styleFrom(
                    foregroundColor: AppTheme.accentGold,
                    textStyle: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: Responsive.getValue(
                        context,
                        mobile: 12.0,
                        tablet: 13.0,
                        desktop: 18.0,
                        largeDesktop: 20.0,
                      ),
                    ),
                  ),
                  onPressed:
                      () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const TagsBrowseScreen(),
                        ),
                      ),
                  child: const AutoSizeText(
                    'See More',
                    maxLines: 1,
                    minFontSize: 10,
                  ),
                ),
              ],
            ),
            SizedBox(height: Responsive.getSpacing(context)),
            GetBuilder<TagsController>(
              init: tagsController,
              builder: (tagsController) {
                final tags = tagsController.getFilteredTags('', []);
                final displayTags = tags.take(10).toList();
                return Wrap(
                  spacing: Responsive.getSpacing(context),
                  runSpacing: Responsive.getSpacing(context),
                  children:
                      displayTags.map((tag) {
                        return GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder:
                                    (_) => ProjectListScreen(
                                      title: 'Projects with "$tag"',
                                      tags: [tag],
                                    ),
                              ),
                            );
                          },
                          child: Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: Responsive.getValue(
                                context,
                                mobile: AppTheme.spacingMd,
                                tablet: AppTheme.spacingMd,
                                desktop: AppTheme.spacingLg,
                                largeDesktop: AppTheme.spacingLg,
                              ),
                              vertical: Responsive.getValue(
                                context,
                                mobile: AppTheme.spacingXs,
                                tablet: AppTheme.spacingXs,
                                desktop: AppTheme.spacingMd,
                                largeDesktop: AppTheme.spacingMd,
                              ),
                            ),
                            decoration: BoxDecoration(
                              color: AppTheme.accentGold.withAlpha(25),
                              borderRadius: BorderRadius.circular(
                                Responsive.getBorderRadius(context),
                              ),
                              border: Border.all(
                                color: AppTheme.accentGold.withAlpha(77),
                                width: 1,
                              ),
                            ),
                            child: AutoSizeText(
                              tag,
                              style: TextStyle(
                                color: AppTheme.accentGold,
                                fontSize: Responsive.getValue(
                                  context,
                                  mobile: 10.0,
                                  tablet: 11.0,
                                  desktop: 18.0,
                                  largeDesktop: 20.0,
                                ),
                                fontWeight: FontWeight.w500,
                              ),
                              maxLines: 1,
                              minFontSize: 10,
                            ),
                          ),
                        );
                      }).toList(),
                );
              },
            ),
            SizedBox(
              height: Responsive.getValue(
                context,
                mobile: AppTheme.spacingLg,
                tablet: AppTheme.spacingLg,
                desktop: AppTheme.spacingXl,
                largeDesktop: AppTheme.spacingXl,
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: AutoSizeText(
                    'New Projects',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: AppTheme.textDark,
                      fontWeight: FontWeight.w600,
                      fontSize: Responsive.getValue(
                        context,
                        mobile: 16.0,
                        tablet: 17.0,
                        desktop: 18.0,
                        largeDesktop: 20.0,
                      ),
                    ),
                    maxLines: 1,
                    minFontSize: 14,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                TextButton(
                  style: TextButton.styleFrom(
                    foregroundColor: AppTheme.accentGold,
                    textStyle: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: Responsive.getValue(
                        context,
                        mobile: 12.0,
                        tablet: 13.0,
                        desktop: 18.0,
                        largeDesktop: 20.0,
                      ),
                    ),
                  ),
                  onPressed:
                      () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder:
                              (_) => const ProjectListScreen(
                                title: 'New Projects',
                              ),
                        ),
                      ),
                  child: const AutoSizeText(
                    'See More',
                    maxLines: 1,
                    minFontSize: 10,
                  ),
                ),
              ],
            ),
            SizedBox(height: Responsive.getSpacing(context)),
            projectController.projects.isEmpty
                ? const SizedBox(height: 200, child: NoProjectsState())
                : LayoutBuilder(
                  builder: (context, constraints) {
                    final crossAxisCount = Responsive.getValue(
                      context,
                      mobile: 2,
                      tablet: 2,
                      desktop: 3,
                      largeDesktop: 4,
                    );
                    final displayProjects =
                        projectController.projects.length > 4
                            ? projectController.projects.take(4).toList()
                            : projectController.projects;

                    return Wrap(
                      spacing: spacing,
                      runSpacing: spacing,
                      children:
                          displayProjects.map((p) {
                            final cardWidth =
                                (constraints.maxWidth -
                                    (spacing * (crossAxisCount - 1))) /
                                crossAxisCount;
                            return SizedBox(
                              width: cardWidth,
                              child:
                                  p.title.isEmpty || p.projectStat == null
                                      ? GestureDetector(
                                        onTap: () => _openDetail(p),
                                        child: Container(
                                          padding: const EdgeInsets.all(20),
                                          decoration: BoxDecoration(
                                            color: Colors.grey[200],
                                            borderRadius: BorderRadius.circular(
                                              Responsive.getBorderRadius(
                                                context,
                                              ),
                                            ),
                                          ),
                                          child: Center(
                                            child: AutoSizeText(
                                              p.title.isNotEmpty
                                                  ? p.title
                                                  : 'Unnamed Project',
                                              style: TextStyle(
                                                fontSize: Responsive.getValue(
                                                  context,
                                                  mobile: 10,
                                                  tablet: 11,
                                                  desktop: 12,
                                                  largeDesktop: 18,
                                                ),
                                                color: Colors.black54,
                                                fontStyle: FontStyle.italic,
                                              ),
                                              textAlign: TextAlign.center,
                                              maxLines: 2,
                                              minFontSize: 10,
                                            ),
                                          ),
                                        ),
                                      )
                                      : ProjectCardHome(
                                        project: p,
                                        onTap: () => _openDetail(p),
                                      ),
                            );
                          }).toList(),
                    );
                  },
                ),
          ],
        ),
      ),
    );
  }
}
