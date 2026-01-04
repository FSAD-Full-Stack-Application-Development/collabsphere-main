import 'package:collab_sphere/models/project.dart';
import 'package:collab_sphere/store/project_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../theme.dart';
import 'project_detail_page.dart';
import 'user_detail_page.dart';
import '../api/project.dart';
import 'dart:convert';
import '../store/tags_controller.dart';
import '../widgets/empty_states.dart';
import '../utils/responsive.dart';

class TopScreen extends StatefulWidget {
  const TopScreen({super.key});

  @override
  State<TopScreen> createState() => _TopScreenState();
}

class _TopScreenState extends State<TopScreen>
    with SingleTickerProviderStateMixin {
  String _selectedCountry = 'All';
  String _selectedSchool = 'All';
  String _selectedDept = 'All';
  List<String> _selectedTags = [];
  bool _isLoadingProjects = false;
  bool _isLoadingPeople = false;
  List<Project> _topProjects = [];
  List<Map<String, dynamic>> _topPeople = [];

  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadTopData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadTopData() async {
    await Future.wait([_loadTopProjects(), _loadTopPeople()]);
  }

  Future<void> _loadTopProjects() async {
    if (mounted) setState(() => _isLoadingProjects = true);

    try {
      // Build query parameters
      final queryParams = <String, String>{};
      if (_selectedCountry != 'All') queryParams['country'] = _selectedCountry;
      if (_selectedSchool != 'All') queryParams['university'] = _selectedSchool;
      if (_selectedDept != 'All') queryParams['department'] = _selectedDept;
      if (_selectedTags.isNotEmpty) {
        queryParams['tags'] = _selectedTags.join(',');
      }

      queryParams['limit'] = '20';

      final response = await projectService.getProjects(
        university: _selectedSchool != 'All' ? _selectedSchool : null,
        department: _selectedDept != 'All' ? _selectedDept : null,
        tags: _selectedTags.isNotEmpty ? _selectedTags : null,
        sort: 'votes',
        perPage: 20,
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final projects =
            (data['data'] as List?)?.map((e) => Project.fromJson(e)).toList() ??
            [];
        if (mounted) setState(() => _topProjects = projects);
      }
    } catch (e) {
      // Handle error
    } finally {
      if (mounted) setState(() => _isLoadingProjects = false);
    }
  }

  Future<void> _loadTopPeople() async {
    if (mounted) setState(() => _isLoadingPeople = true);

    try {
      // For now, filter from existing projects
      // In a real implementation, you'd have a separate API endpoint for top people
      final filteredProjects =
          projectController.projects.where((p) {
            if (_selectedCountry != 'All' &&
                p.owner.country?.toLowerCase() !=
                    _selectedCountry.toLowerCase()) {
              return false;
            }
            if (_selectedSchool != 'All' &&
                p.owner.university?.toLowerCase() !=
                    _selectedSchool.toLowerCase()) {
              return false;
            }
            if (_selectedDept != 'All' &&
                p.owner.department?.toLowerCase() !=
                    _selectedDept.toLowerCase()) {
              return false;
            }
            if (_selectedTags.isNotEmpty &&
                !p.tags.any((tag) => _selectedTags.contains(tag.tagName))) {
              return false;
            }
            return true;
          }).toList();

      final people = _getTopPeopleFromProjects(filteredProjects);
      if (mounted) setState(() => _topPeople = people.take(20).toList());
    } catch (e) {
      // Handle error
    } finally {
      if (mounted) setState(() => _isLoadingPeople = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        title: Text(
          'Top',
          style: TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: Responsive.getValue(
              context,
              mobile: 20.0,
              tablet: 22.0,
              desktop: 24.0,
              largeDesktop: 26.0,
            ),
          ),
        ),
        actions: [_filterDropdown(context), const SizedBox(width: 12)],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [Tab(text: 'Projects'), Tab(text: 'Developers')],
        ),
      ),
      body: Container(
        decoration: BoxDecoration(gradient: AppTheme.gradientSoft),
        child: TabBarView(
          controller: _tabController,
          children: [_buildProjectsTab(), _buildDevelopersTab()],
        ),
      ),
    );
  }

  List<Map<String, dynamic>> _getTopPeopleFromProjects(List<Project> projects) {
    final Map<String, Map<String, dynamic>> people = {};

    for (final p in projects) {
      final ownerName = p.owner.fullName;
      final ownerId = p.owner.id;
      people[ownerName] ??= {
        'name': ownerName,
        'userId': ownerId,
        'projects': 0,
        'votes': 0,
        'isOwner': true,
      };
      people[ownerName]!['projects'] =
          (people[ownerName]!['projects'] as int) + 1;
      people[ownerName]!['votes'] =
          (people[ownerName]!['votes'] as int) + p.voteCount;

      for (final collab in p.collaborators ?? []) {
        final name = collab.fullName;
        final collabId = collab.id;
        people[name] ??= {
          'name': name,
          'userId': collabId,
          'projects': 0,
          'votes': 0,
          'isOwner': false,
        };
        people[name]!['projects'] = (people[name]!['projects'] as int) + 1;
        people[name]!['votes'] = (people[name]!['votes'] as int) + p.voteCount;
      }
    }

    final list = people.values.toList();
    list.sort((a, b) {
      final voteCompare = (b['votes'] as int).compareTo(a['votes'] as int);
      if (voteCompare != 0) return voteCompare;

      final projectCompare = (b['projects'] as int).compareTo(
        a['projects'] as int,
      );
      if (projectCompare != 0) return projectCompare;

      final aIsOwner = a['isOwner'] as bool;
      final bIsOwner = b['isOwner'] as bool;
      if (aIsOwner && !bIsOwner) return -1;
      if (!aIsOwner && bIsOwner) return 1;

      return 0;
    });
    return list;
  }

  Widget _buildProjectsTab() {
    final isMobile = Responsive.isMobile(context);
    final padding = Responsive.getPadding(context);

    return RefreshIndicator(
      onRefresh: _loadTopProjects,
      child: CustomScrollView(
        slivers: [
          // Top Projects header
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.all(padding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Top Projects',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: AppTheme.textDark,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (_isLoadingProjects)
                        const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                ],
              ),
            ),
          ),

          // Top Projects list
          _topProjects.isEmpty
              ? const SliverToBoxAdapter(
                child: SizedBox(height: 300, child: NoTopProjectsState()),
              )
              : SliverList(
                delegate: SliverChildBuilderDelegate(
                  (_, i) => _projectRankCard(_topProjects[i], i + 1),
                  childCount: _topProjects.length,
                ),
              ),

          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
    );
  }

  Widget _buildDevelopersTab() {
    final isMobile = Responsive.isMobile(context);
    final padding = Responsive.getPadding(context);

    return RefreshIndicator(
      onRefresh: _loadTopPeople,
      child: CustomScrollView(
        slivers: [
          // Top Developers header
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.all(padding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Top Developers',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: AppTheme.textDark,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (_isLoadingPeople)
                        const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                ],
              ),
            ),
          ),

          // Top People list
          _topPeople.isEmpty
              ? const SliverToBoxAdapter(
                child: SizedBox(height: 300, child: NoTopUsersState()),
              )
              : SliverList(
                delegate: SliverChildBuilderDelegate(
                  (_, i) => _personRankCard(_topPeople[i], i + 1),
                  childCount: _topPeople.length,
                ),
              ),

          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
    );
  }

  Widget _filterDropdown(BuildContext context) {
    return GestureDetector(
      onTap: () => _showFilterSheet(context),
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: AppTheme.spacingMd,
          vertical: AppTheme.spacingXs,
        ),
        decoration: BoxDecoration(
          gradient: AppTheme.gradientMain,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: AppTheme.accentGold.withOpacity(0.3),
              blurRadius: 8,
              spreadRadius: 1,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            const Icon(Icons.filter_list, size: 20, color: Colors.white),
            SizedBox(width: AppTheme.spacingXs),
            Text(
              'Filter',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showFilterSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        // Initialize local selections from current state
        var localSelectedCountry = _selectedCountry;
        var localSelectedSchool = _selectedSchool;
        var localSelectedDept = _selectedDept;
        var localSelectedTags = List<String>.from(_selectedTags);

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
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Filter Top Rankings',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                      const SizedBox(height: 18),
                      SizedBox(
                        width: double.infinity,
                        child: DropdownButtonFormField<String>(
                          value: localSelectedCountry,
                          items:
                              [
                                    'All',
                                    ...projectController
                                        .countrySchoolDepartments
                                        .keys,
                                  ]
                                  .map(
                                    (c) => DropdownMenuItem(
                                      value: c,
                                      child: Text(c),
                                    ),
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
                          isExpanded: true,
                        ),
                      ),
                      const SizedBox(height: 14),
                      SizedBox(
                        width: double.infinity,
                        child: DropdownButtonFormField<String>(
                          value: localSelectedSchool,
                          items:
                              schools
                                  .map(
                                    (s) => DropdownMenuItem(
                                      value: s,
                                      child: Text(s),
                                    ),
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
                          isExpanded: true,
                        ),
                      ),
                      const SizedBox(height: 14),
                      SizedBox(
                        width: double.infinity,
                        child: DropdownButtonFormField<String>(
                          value: localSelectedDept,
                          items:
                              departments
                                  .map(
                                    (d) => DropdownMenuItem(
                                      value: d,
                                      child: Text(d),
                                    ),
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
                          isExpanded: true,
                        ),
                      ),
                      const SizedBox(height: 14),
                      // Tags selection
                      GetBuilder<TagsController>(
                        init: tagsController,
                        builder: (tagsController) {
                          final availableTags = tagsController.getFilteredTags(
                            '',
                            [],
                          );
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Tags',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children:
                                    availableTags.map((tag) {
                                      final isSelected = localSelectedTags
                                          .contains(tag);
                                      return FilterChip(
                                        label: Text(tag),
                                        selected: isSelected,
                                        onSelected: (selected) {
                                          setModalState(() {
                                            if (selected) {
                                              localSelectedTags.add(tag);
                                            } else {
                                              localSelectedTags.remove(tag);
                                            }
                                          });
                                        },
                                        backgroundColor: Colors.grey[200],
                                        selectedColor: AppTheme.accentGold
                                            .withOpacity(0.2),
                                        checkmarkColor: AppTheme.accentGold,
                                      );
                                    }).toList(),
                              ),
                            ],
                          );
                        },
                      ),
                      const SizedBox(height: 18),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            onPressed: () {
                              setState(() {
                                _selectedCountry = 'All';
                                _selectedSchool = 'All';
                                _selectedDept = 'All';
                                _selectedTags.clear();
                              });
                              Navigator.pop(ctx);
                              _loadTopData();
                            },
                            child: const Text('Clear'),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton(
                            onPressed: () {
                              setState(() {
                                _selectedCountry = localSelectedCountry;
                                _selectedSchool = localSelectedSchool;
                                _selectedDept = localSelectedDept;
                                _selectedTags = List<String>.from(
                                  localSelectedTags,
                                );
                              });
                              Navigator.pop(ctx);
                              _loadTopData();
                            },
                            child: const Text('Apply'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  // UI CARDS
  // ────────────────────────────────────────────────
  Widget _projectRankCard(Project p, int rank) {
    final isMobile = MediaQuery.of(context).size.width < 768;
    final cardPadding = isMobile ? AppTheme.spacingMd : AppTheme.spacingLg;

    return GestureDetector(
      onTap:
          () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ProjectDetailPage(projectId: p.id),
            ),
          ).then((result) {
            // Refresh projects if project was edited
            if (result == true) {
              _loadTopProjects();
            }
          }),
      child: Container(
        margin: EdgeInsets.symmetric(
          horizontal: cardPadding,
          vertical: AppTheme.spacingXs,
        ),
        padding: EdgeInsets.all(AppTheme.spacingMd),
        decoration: BoxDecoration(
          gradient: AppTheme.gradientSoft,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppTheme.accentGold.withOpacity(0.2)),
          boxShadow: [AppTheme.shadowMd],
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 20,
              backgroundColor:
                  rank <= 3 ? AppTheme.accentGold : AppTheme.bgLight,
              child: Text(
                '$rank',
                style: TextStyle(
                  color: rank <= 3 ? Colors.white : AppTheme.textDark,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            SizedBox(width: AppTheme.spacingMd),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    p.title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textDark,
                    ),
                  ),
                  Text(
                    p.owner.university ?? 'Independent Researcher',
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppTheme.textLight,
                    ),
                  ),
                ],
              ),
            ),
            Row(
              children: [
                const Icon(Icons.favorite, size: 18, color: Colors.red),
                SizedBox(width: AppTheme.spacingXs),
                Text(
                  '${p.voteCount}',
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textDark,
                  ),
                ),
              ],
            ),
            SizedBox(width: AppTheme.spacingXs),
            Icon(Icons.arrow_forward_ios, size: 16, color: AppTheme.textLight),
          ],
        ),
      ),
    );
  }

  Widget _personRankCard(Map<String, dynamic> person, int rank) {
    final isMobile = MediaQuery.of(context).size.width < 768;
    final cardPadding = isMobile ? AppTheme.spacingMd : AppTheme.spacingLg;
    final name = person['name'] as String;
    final userId = person['userId'] as String;
    final initial = name.isNotEmpty ? name[0].toUpperCase() : '?';

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => UserDetailPage(userId: userId, userName: name),
          ),
        );
      },
      child: Container(
        margin: EdgeInsets.symmetric(
          horizontal: cardPadding,
          vertical: AppTheme.spacingXs,
        ),
        padding: EdgeInsets.all(AppTheme.spacingMd),
        decoration: BoxDecoration(
          gradient: AppTheme.gradientSoft,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppTheme.accentGold.withOpacity(0.2)),
          boxShadow: [AppTheme.shadowMd],
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 24,
              backgroundColor:
                  rank <= 3 ? AppTheme.accentGold : AppTheme.bgLight,
              child: Text(
                initial,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            SizedBox(width: AppTheme.spacingMd),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textDark,
                    ),
                  ),
                  Text(
                    '${person['projects']} projects • ${person['votes']} votes',
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppTheme.textLight,
                    ),
                  ),
                ],
              ),
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (rank <= 3)
                  const Icon(
                    Icons.emoji_events,
                    color: AppTheme.accentGold,
                    size: 24,
                  ),
                const SizedBox(width: 8),
                Icon(
                  Icons.arrow_forward_ios,
                  size: 16,
                  color: AppTheme.textLight,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
