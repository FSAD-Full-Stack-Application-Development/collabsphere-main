import 'package:collab_sphere/screens/edit_project.dart';
import 'package:flutter/material.dart';
import '../models/project.dart';
import '../theme.dart';
import 'project_detail_state.dart';
import 'profile_details/project_resources_section.dart';
import 'profile_details/project_collaborators_section.dart';
import 'profile_details/project_comments_section.dart';
import 'profile_details/project_funding_section.dart';
import 'profile_details/project_stats_section.dart';
import 'profile_details/project_key_info_section.dart';
import 'profile_details/project_description_section.dart';
import 'profile_details/project_tags_section.dart';
import 'profile_details/project_action_buttons_section.dart';
import '../utils/responsive.dart';

class ProjectDetailPage extends StatefulWidget {
  final String projectId;
  final bool isOwner;

  const ProjectDetailPage({
    super.key,
    required this.projectId,
    this.isOwner = false,
  });

  @override
  State<ProjectDetailPage> createState() => _ProjectDetailPageState();
}

class _ProjectDetailPageState extends State<ProjectDetailPage> {
  late final ProjectDetailState _state;
  Key _contentKey = UniqueKey();

  @override
  void initState() {
    super.initState();
    _state = ProjectDetailState(projectId: widget.projectId);
    _state.addListener(_onStateChanged);
    _state.initialize();
  }

  @override
  void dispose() {
    _state.removeListener(_onStateChanged);
    super.dispose();
  }

  void _onStateChanged() {
    setState(() {
      // Force rebuild by changing key when project updates
      _contentKey = UniqueKey();
    });
  }

  @override
  Widget build(BuildContext context) {
    final padding = Responsive.getPadding(context);

    // Show loading screen while project is being fetched
    if (_state.project == null) {
      return Scaffold(
        body: Container(
          decoration: BoxDecoration(gradient: AppTheme.gradientSoft),
          child: const Center(
            child: CircularProgressIndicator(color: AppTheme.accentGold),
          ),
        ),
      );
    }

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text(
            _state.project!.title,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          actions: [
            if (widget.isOwner)
              IconButton(
                icon: const Icon(Icons.edit, color: Colors.white),
                onPressed: () async {
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => EditProjectPage(project: _state.project!),
                    ),
                  );
                  // Refresh project if edit was successful
                  if (result == true) {
                    _state.initialize();
                  }
                },
              ),
          ],
          flexibleSpace: Container(
            decoration: BoxDecoration(gradient: AppTheme.gradientMain),
          ),
          bottom: TabBar(
            tabs: [
              Tab(
                icon: Icon(Icons.info_outline, color: AppTheme.textDark),
                text: 'Overview',
              ),
              Tab(
                icon: Icon(Icons.group, color: AppTheme.textDark),
                text: 'Team',
              ),
              Tab(
                icon: Icon(Icons.comment, color: AppTheme.textDark),
                text: 'Comments',
              ),
            ],
            indicatorColor: AppTheme.accentGold,
            labelColor: AppTheme.textDark,
            unselectedLabelColor: AppTheme.textDark.withOpacity(0.7),
          ),
        ),
        body: SafeArea(
          child: Container(
            decoration: BoxDecoration(gradient: AppTheme.gradientSoft),
            child: ResponsiveContainer(
              maxWidth: 1200,
              child: TabBarView(
                key: _contentKey, // Force rebuild when project updates
                children: [
                  // Overview Tab
                  SingleChildScrollView(
                    padding: EdgeInsets.all(padding),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Key project information first
                        ProjectKeyInfoSection(project: _state.project),
                        const SizedBox(height: 12),

                        // Project description
                        ProjectDescriptionSection(project: _state.project),
                        const SizedBox(height: 12),

                        // Tags and categorization
                        Container(
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
                              const Row(
                                children: [
                                  Icon(
                                    Icons.label_outline,
                                    size: 18,
                                    color: AppTheme.textMedium,
                                  ),
                                  SizedBox(width: 8),
                                  Text(
                                    'Tags',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: AppTheme.textDark,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              ProjectTagsSection(project: _state.project),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Statistics and metrics
                        ProjectStatsSection(state: _state),
                        const SizedBox(height: 12),

                        // Funding information
                        ProjectFundingSection(state: _state),
                        const SizedBox(height: 12),

                        // Resources and links
                        ProjectResourcesSection(state: _state),
                        const SizedBox(height: 16),

                        // Action buttons at the bottom
                        ProjectActionButtonsSection(state: _state),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                  // Team Tab
                  SingleChildScrollView(
                    padding: EdgeInsets.all(padding),
                    child: ProjectCollaboratorsSection(state: _state),
                  ),
                  // Comments Tab
                  ProjectCommentsSection(state: _state),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
