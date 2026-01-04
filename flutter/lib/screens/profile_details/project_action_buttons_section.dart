import 'package:flutter/material.dart';
import '../../theme.dart';
import '../../store/auth_controller.dart';
import '../project_detail_state.dart';

class ProjectActionButtonsSection extends StatefulWidget {
  final ProjectDetailState state;

  const ProjectActionButtonsSection({super.key, required this.state});

  @override
  State<ProjectActionButtonsSection> createState() =>
      _ProjectActionButtonsSectionState();
}

class _ProjectActionButtonsSectionState
    extends State<ProjectActionButtonsSection> {
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

    final currentUserId = authController.user?.id;
    final isOwner = widget.state.project!.isOwnerFor(currentUserId);
    final isCollaborator =
        !isOwner &&
        (widget.state.project!.collaborators?.any(
              (c) => c.id == currentUserId,
            ) ??
            false);
    final isNormalUser = !isOwner && !isCollaborator;

    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            icon: Icon(
              widget.state.voted ? Icons.favorite : Icons.favorite_border,
            ),
            label: Text(widget.state.voted ? 'Voted' : 'Vote'),
            onPressed: widget.state.toggleVote,
            style: ElevatedButton.styleFrom(
              backgroundColor:
                  widget.state.voted ? Colors.red : AppTheme.accentGold,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
          ),
        ),
        const SizedBox(width: 8),
        if (isNormalUser)
          Expanded(
            child: ElevatedButton.icon(
              icon: Icon(
                widget.state.project!.status == 'completed'
                    ? Icons.check_circle
                    : isCollaborator
                    ? Icons.group
                    : Icons.group_add,
              ),
              label: Text(
                widget.state.project!.status == 'completed'
                    ? 'Completed'
                    : isCollaborator
                    ? 'Collaborator'
                    : (widget.state.collabRequestSent
                        ? 'Requested'
                        : 'Collaborate'),
              ),
              onPressed:
                  widget.state.project!.status == 'completed' || isCollaborator
                      ? null
                      : widget.state.collabRequestSent
                      ? null
                      : () async {
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
                backgroundColor:
                    widget.state.project!.status == 'completed'
                        ? Colors.grey
                        : isCollaborator
                        ? Colors.green
                        : AppTheme.accentGold,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ),
      ],
    );
  }
}
