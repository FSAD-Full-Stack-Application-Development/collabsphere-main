import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../theme.dart';
import '../project_detail_state.dart';

class ProjectResourcesSection extends StatefulWidget {
  final ProjectDetailState state;

  const ProjectResourcesSection({super.key, required this.state});

  @override
  State<ProjectResourcesSection> createState() =>
      _ProjectResourcesSectionState();
}

class _ProjectResourcesSectionState extends State<ProjectResourcesSection> {
  @override
  void initState() {
    super.initState();
    widget.state.addListener(_onStateChanged);
  }

  @override
  void dispose() {
    widget.state.removeListener(_onStateChanged);
    super.dispose();
  }

  void _onStateChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Resources',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                if (widget.state.isOwner || widget.state.isCollaborator)
                  IconButton(
                    onPressed: _showAddResourceDialog,
                    icon: const Icon(Icons.add, size: 20),
                    tooltip: 'Add Resource',
                  ),
              ],
            ),
            const SizedBox(height: 12),
            if (widget.state.resourcesLoading)
              const Center(child: CircularProgressIndicator()),
            if (!widget.state.resourcesLoading &&
                widget.state.resources.isEmpty)
              const Text(
                'No resources available yet.',
                style: TextStyle(color: AppTheme.textLight),
              ),
            if (!widget.state.resourcesLoading &&
                widget.state.resources.isNotEmpty)
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children:
                    widget.state.resources.map<Widget>((resource) {
                      final status = resource['status'] ?? 'pending';
                      final isApproved = status == 'approved';

                      return Container(
                        constraints: const BoxConstraints(maxWidth: 200),
                        child: ElevatedButton.icon(
                          onPressed:
                              isApproved
                                  ? () async {
                                    final url = resource['url'] ?? '';
                                    final title =
                                        resource['title'] ?? 'Resource';
                                    if (url.isNotEmpty) {
                                      final uri = Uri.parse(url);
                                      log("url: ${uri.toString()}");
                                      if (await canLaunchUrl(uri)) {
                                        await launchUrl(
                                          uri,
                                          mode: LaunchMode.externalApplication,
                                        );
                                      } else {
                                        if (context.mounted) {
                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                            SnackBar(
                                              content: Text(
                                                'Could not open $title',
                                              ),
                                            ),
                                          );
                                        }
                                      }
                                    }
                                  }
                                  : null,
                          icon: Icon(
                            _getResourceIcon(resource['title'] ?? ''),
                            size: 16,
                          ),
                          label: Text(
                            resource['title'] ?? 'Resource',
                            style: const TextStyle(fontSize: 12),
                            overflow: TextOverflow.ellipsis,
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                isApproved
                                    ? AppTheme.accentGold
                                    : Colors.grey.shade300,
                            foregroundColor:
                                isApproved ? Colors.white : Colors.grey,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
              ),
            // Pending resources management for owners
            if (widget.state.isOwner &&
                !widget.state.resourcesLoading &&
                widget.state.resources.any((r) => r['status'] == 'pending'))
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Pending Resources',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    ...widget.state.resources
                        .where((r) => r['status'] == 'pending')
                        .map<Widget>(
                          (resource) => Card(
                            child: ListTile(
                              leading: Icon(
                                _getResourceIcon(resource['name'] ?? ''),
                              ),
                              title: Text(resource['name'] ?? ''),
                              subtitle: Text(resource['url'] ?? ''),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(
                                      Icons.check,
                                      color: Colors.green,
                                    ),
                                    tooltip: 'Approve',
                                    onPressed:
                                        () => widget.state.approveResource(
                                          resource['id'],
                                        ),
                                  ),
                                  IconButton(
                                    icon: const Icon(
                                      Icons.close,
                                      color: Colors.red,
                                    ),
                                    tooltip: 'Delete',
                                    onPressed:
                                        () => widget.state.rejectResource(
                                          resource['id'],
                                        ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _showAddResourceDialog() {
    final nameController = TextEditingController();
    final urlController = TextEditingController();
    String? nameError;
    String? urlError;

    showDialog(
      context: context,
      builder:
          (context) => StatefulBuilder(
            builder:
                (context, setState) => AlertDialog(
                  title: const Text('Add Resource'),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextField(
                        controller: nameController,
                        decoration: InputDecoration(
                          labelText: 'Resource Name',
                          hintText: 'e.g., GitHub Repository',
                          errorText: nameError,
                        ),
                        onChanged: (value) {
                          if (nameError != null) {
                            setState(() => nameError = null);
                          }
                        },
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: urlController,
                        decoration: InputDecoration(
                          labelText: 'URL',
                          hintText: 'https://example.com or www.example.com',
                          errorText: urlError,
                        ),
                        onChanged: (value) {
                          if (urlError != null) {
                            setState(() => urlError = null);
                          }
                        },
                      ),
                    ],
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancel'),
                    ),
                    ElevatedButton(
                      onPressed: () async {
                        final name = nameController.text.trim();
                        final url = urlController.text.trim();

                        // Validate inputs
                        bool hasError = false;
                        if (name.isEmpty) {
                          setState(
                            () => nameError = 'Resource name is required',
                          );
                          hasError = true;
                        }
                        if (url.isEmpty) {
                          setState(() => urlError = 'URL is required');
                          hasError = true;
                        }

                        if (!hasError) {
                          // Ensure URL has protocol
                          String processedUrl = url;
                          if (!url.startsWith('http://') &&
                              !url.startsWith('https://')) {
                            processedUrl = 'https://$url';
                          }

                          try {
                            await widget.state.addResource(name, processedUrl);
                            if (context.mounted) {
                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Resource added successfully'),
                                  backgroundColor: Colors.green,
                                ),
                              );
                            }
                          } catch (e) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Failed to add resource: $e'),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                          }
                        }
                      },
                      child: const Text('Add'),
                    ),
                  ],
                ),
          ),
    );
  }

  IconData _getResourceIcon(String title) {
    final lowerTitle = title.toLowerCase();
    if (lowerTitle.contains('github')) return Icons.code;
    if (lowerTitle.contains('figma')) return Icons.design_services;
    if (lowerTitle.contains('notion')) return Icons.article;
    if (lowerTitle.contains('drive') || lowerTitle.contains('docs')) {
      return Icons.cloud;
    }
    if (lowerTitle.contains('slack')) return Icons.chat;
    if (lowerTitle.contains('discord')) return Icons.forum;
    return Icons.link;
  }
}
