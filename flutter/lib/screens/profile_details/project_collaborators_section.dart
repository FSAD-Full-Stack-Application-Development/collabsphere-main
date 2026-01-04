import 'package:flutter/material.dart';
import '../../theme.dart';
import '../project_detail_state.dart';

class ProjectCollaboratorsSection extends StatefulWidget {
  final ProjectDetailState state;

  const ProjectCollaboratorsSection({super.key, required this.state});

  @override
  State<ProjectCollaboratorsSection> createState() =>
      _ProjectCollaboratorsSectionState();
}

class _ProjectCollaboratorsSectionState
    extends State<ProjectCollaboratorsSection> {
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
    if (widget.state.project == null) {
      return const Center(
        child: CircularProgressIndicator(color: AppTheme.accentGold),
      );
    }

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Team',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            if (widget.state.collabLoading)
              const Center(child: CircularProgressIndicator()),
            if (!widget.state.collabLoading)
              Wrap(
                spacing: 16,
                runSpacing: 16,
                children:
                    widget.state.collaborations.map<Widget>((collab) {
                      final user = collab['user'];
                      return Column(
                        children: [
                          CircleAvatar(
                            radius: 24,
                            backgroundColor: AppTheme.accentGold,
                            child: Text(
                              (user['full_name'] ?? '?').isNotEmpty
                                  ? user['full_name'][0].toUpperCase()
                                  : '?',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            user['full_name'] ?? '',
                            style: const TextStyle(fontSize: 13),
                          ),
                          if (widget.state.isOwner &&
                              user['id'] != widget.state.project!.owner.id)
                            IconButton(
                              icon: const Icon(
                                Icons.remove_circle,
                                color: Colors.red,
                              ),
                              tooltip: 'Remove collaborator',
                              onPressed: () async {
                                try {
                                  await widget.state.removeCollaboration(
                                    collab['id'],
                                  );
                                  if (mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          'Collaborator removed successfully.',
                                        ),
                                        backgroundColor: Colors.blue,
                                      ),
                                    );
                                  }
                                } catch (e) {
                                  if (mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          'Failed to remove collaborator: $e',
                                        ),
                                        backgroundColor: Colors.red,
                                      ),
                                    );
                                  }
                                }
                              },
                            ),
                        ],
                      );
                    }).toList(),
              ),
            if (widget.state.isNormalUser && !widget.state.collabLoading)
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child:
                    widget.state.collabRequestSent
                        ? const Text(
                          'Collaboration request sent!',
                          style: TextStyle(color: Colors.green),
                        )
                        : ElevatedButton.icon(
                          icon: const Icon(Icons.group_add),
                          label: const Text('Request Collaboration'),
                          onPressed: () async {
                            try {
                              await widget.state.requestCollaboration();
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Collaboration request sent successfully! The project owner will review and approve it.',
                                    ),
                                    backgroundColor: Colors.green,
                                  ),
                                );
                              }
                            } catch (e) {
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      'Failed to send collaboration request: $e',
                                    ),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                              }
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.accentGold,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              vertical: 12,
                              horizontal: 18,
                            ),
                          ),
                        ),
              ),
            if (widget.state.isOwner &&
                !widget.state.collabRequestsLoading &&
                widget.state.collabRequests.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Pending Collaboration Requests',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    ...widget.state.collabRequests.map<Widget>(
                      (req) => Card(
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: AppTheme.accentGold,
                            child: Text(
                              (req['user']['full_name'] ?? '?').isNotEmpty
                                  ? req['user']['full_name'][0].toUpperCase()
                                  : '?',
                              style: const TextStyle(color: Colors.white),
                            ),
                          ),
                          title: Text(req['user']['full_name'] ?? ''),
                          subtitle: Text(req['user']['email'] ?? ''),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(
                                  Icons.check,
                                  color: Colors.green,
                                ),
                                tooltip: 'Approve',
                                onPressed: () async {
                                  try {
                                    await widget.state.approveCollabRequest(
                                      req['user']['id'],
                                    );
                                    if (mounted) {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        const SnackBar(
                                          content: Text(
                                            'Collaboration request approved!',
                                          ),
                                          backgroundColor: Colors.green,
                                        ),
                                      );
                                    }
                                  } catch (e) {
                                    if (mounted) {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            'Failed to approve request: $e',
                                          ),
                                          backgroundColor: Colors.red,
                                        ),
                                      );
                                    }
                                  }
                                },
                              ),
                              IconButton(
                                icon: const Icon(
                                  Icons.close,
                                  color: Colors.red,
                                ),
                                tooltip: 'Reject',
                                onPressed: () async {
                                  try {
                                    await widget.state.rejectCollabRequest(
                                      req['user']['id'],
                                    );
                                    if (mounted) {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        const SnackBar(
                                          content: Text(
                                            'Collaboration request rejected.',
                                          ),
                                          backgroundColor: Colors.blue,
                                        ),
                                      );
                                    }
                                  } catch (e) {
                                    if (mounted) {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            'Failed to reject request: $e',
                                          ),
                                          backgroundColor: Colors.red,
                                        ),
                                      );
                                    }
                                  }
                                },
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
}
