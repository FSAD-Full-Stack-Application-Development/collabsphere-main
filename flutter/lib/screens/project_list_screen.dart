import 'dart:convert';
import 'package:flutter/material.dart';
import '../api/project.dart';
import '../models/project.dart';
import '../theme.dart';
import 'project_detail_page.dart';
import '../utils/responsive.dart';

class ProjectListScreen extends StatefulWidget {
  final String? title;
  final String? sort;
  final String? query;
  final List<String>? tags;
  final String? university;
  final String? department;
  final bool topProjects;
  final String? userId;

  const ProjectListScreen({
    super.key,
    this.title,
    this.sort,
    this.query,
    this.tags,
    this.university,
    this.department,
    this.topProjects = false,
    this.userId,
  });

  @override
  State<ProjectListScreen> createState() => _ProjectListScreenState();
}

class _ProjectListScreenState extends State<ProjectListScreen> {
  int _page = 1;
  bool _isLoading = false;
  bool _hasMore = true;
  List<Project> _projects = [];
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _fetchProjects();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 200 &&
        !_isLoading &&
        _hasMore) {
      _fetchProjects();
    }
  }

  Future<void> _fetchProjects() async {
    setState(() => _isLoading = true);
    final resp = await projectService.getProjects(
      sort: widget.topProjects ? 'votes' : widget.sort,
      query: widget.query,
      tags: widget.tags,
      university: widget.university,
      department: widget.department,
      page: _page,
      perPage: 20,
    );
    if (resp.statusCode == 200) {
      final data = jsonDecode(resp.body);
      var newProjects =
          (data['data'] as List?)?.map((e) => Project.fromJson(e)).toList() ??
          [];

      // Filter by user if userId is provided
      if (widget.userId != null) {
        newProjects =
            newProjects.where((project) {
              return project.owner.id == widget.userId ||
                  (project.collaborators ?? []).any(
                    (user) => user.id == widget.userId,
                  );
            }).toList();
      }

      setState(() {
        _projects.addAll(newProjects);
        _hasMore = newProjects.length == 20;
        _page++;
      });
    }
    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    final padding = Responsive.getPadding(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.title ??
              (widget.topProjects ? 'Top Projects' : 'New Projects'),
        ),
        backgroundColor: AppTheme.bgWhite,
        foregroundColor: AppTheme.textDark,
        elevation: 1,
      ),
      body: SafeArea(
        child: Container(
          decoration: BoxDecoration(gradient: AppTheme.gradientSoft),
          child:
              _projects.isEmpty && !_isLoading
                  ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.search_off,
                          size: 64,
                          color: AppTheme.textLight,
                        ),
                        SizedBox(height: AppTheme.spacingMd),
                        Text(
                          'No projects found',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w500,
                            color: AppTheme.textMedium,
                          ),
                        ),
                        SizedBox(height: AppTheme.spacingXs),
                        Text(
                          widget.tags != null && widget.tags!.isNotEmpty
                              ? 'No projects with this tag yet'
                              : 'Try adjusting your search criteria',
                          style: TextStyle(
                            fontSize: 14,
                            color: AppTheme.textLight,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  )
                  : ListView.builder(
                    controller: _scrollController,
                    padding: EdgeInsets.all(padding),
                    itemCount: _projects.length + (_hasMore ? 1 : 0),
                    itemBuilder: (context, i) {
                      if (i >= _projects.length) {
                        return const Center(
                          child: Padding(
                            padding: EdgeInsets.all(16),
                            child: CircularProgressIndicator(),
                          ),
                        );
                      }
                      final p = _projects[i];
                      return Container(
                        margin: const EdgeInsets.symmetric(vertical: 8),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              Colors.white,
                              AppTheme.accentGold.withOpacity(0.08),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            width: 2,
                            color: AppTheme.accentGold.withOpacity(0.3),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: AppTheme.accentGold.withOpacity(0.2),
                              blurRadius: 10,
                              spreadRadius: 1,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: ListTile(
                          title: Text(
                            p.title,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text(
                            p.description ?? '',
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          trailing:
                              p.projectStat != null
                                  ? Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Icon(
                                        Icons.favorite,
                                        color: Colors.red,
                                        size: 16,
                                      ),
                                      Text(
                                        '${p.projectStat!.totalVotes}',
                                        style: const TextStyle(fontSize: 12),
                                      ),
                                    ],
                                  )
                                  : null,
                          onTap:
                              () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder:
                                      (_) => ProjectDetailPage(
                                        projectId: p.id,
                                        isOwner: false,
                                      ),
                                ),
                              ),
                        ),
                      );
                    },
                  ),
        ),
      ),
    );
  }
}
