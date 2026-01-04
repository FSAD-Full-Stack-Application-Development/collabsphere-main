import 'package:collab_sphere/store/auth_controller.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/project.dart';
import '../../theme.dart';
import '../project_detail_state.dart';

class ProjectCommentsSection extends StatefulWidget {
  final ProjectDetailState state;

  const ProjectCommentsSection({super.key, required this.state});

  @override
  State<ProjectCommentsSection> createState() => _ProjectCommentsSectionState();
}

class _ProjectCommentsSectionState extends State<ProjectCommentsSection> {
  final TextEditingController _commentController = TextEditingController();

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
    final spacing = 12.0;

    // Show loading if project not loaded yet
    if (widget.state.project == null) {
      return const Center(
        child: CircularProgressIndicator(color: AppTheme.accentGold),
      );
    }

    return Stack(
      children: [
        Padding(
          padding: EdgeInsets.only(
            bottom: 70,
            left: spacing,
            right: spacing,
            top: spacing,
          ),
          child: ListView.builder(
            itemCount: widget.state.project!.comments.length,
            itemBuilder:
                (_, i) => _commentWidget(widget.state.project!.comments[i], 0),
          ),
        ),
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: Container(
            margin: EdgeInsets.all(spacing),
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(30),
              border: Border.all(color: AppTheme.borderColor.withOpacity(0.5)),
              boxShadow: [AppTheme.shadowMd],
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _commentController,
                    decoration: InputDecoration(
                      hintText: 'Add a comment...',
                      hintStyle: const TextStyle(color: AppTheme.textLight),
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                ),
                CircleAvatar(
                  radius: 20,
                  backgroundColor: AppTheme.accentGold,
                  child: IconButton(
                    icon: const Icon(Icons.send, color: Colors.white, size: 16),
                    onPressed: () async {
                      if (_commentController.text.trim().isNotEmpty) {
                        try {
                          await widget.state.addComment(
                            _commentController.text.trim(),
                          );
                          _commentController.clear();
                        } catch (e) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Failed to add comment: $e'),
                            ),
                          );
                        }
                      }
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _commentWidget(Comment comment, int depth) {
    final user = authController.user;
    final isMe = user != null && comment.author == user.fullName;
    return Container(
      padding: const EdgeInsets.all(8),
      margin: EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: AppTheme.bgWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderColor),
        boxShadow: [AppTheme.shadowMd],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 12,
                backgroundColor: const Color.fromRGBO(232, 180, 76, 1),
                child: Text(
                  comment.author[0].toUpperCase(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                comment.author,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                  color: AppTheme.textDark,
                ),
              ),
              const Spacer(),
              Text(
                _formatTime(comment.timestamp),
                style: const TextStyle(fontSize: 11, color: AppTheme.textLight),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Builder(
            builder: (context) {
              const int maxLength = 150;
              final isLong = comment.text.length > maxLength;
              final isExpanded =
                  widget.state.expandedComments[comment.id] ?? false;
              final displayText =
                  isLong && !isExpanded
                      ? '${comment.text.substring(0, maxLength)}...'
                      : comment.text;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    displayText,
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppTheme.textMedium,
                      height: 1.5,
                    ),
                  ),
                  if (isLong) ...[
                    TextButton(
                      onPressed: () {
                        widget.state.setCommentExpanded(
                          comment.id,
                          !isExpanded,
                        );
                      },
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.zero,
                        minimumSize: const Size(0, 0),
                        foregroundColor: AppTheme.accentGold,
                        textStyle: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      child: Text(isExpanded ? 'Show less' : 'Read more'),
                    ),
                  ],
                ],
              );
            },
          ),
          SizedBox(
            height: 32,
            child: Row(
              children: [
                _likeButton(comment.likes, () => _likeComment(comment)),
                const SizedBox(width: 8),
                _actionButton('Reply', () => _showReplyDialog(comment)),
                if (isMe) ...[
                  const SizedBox(width: 8),
                  _actionButton('Delete', () => _deleteComment(comment)),
                ],
                if (!isMe) ...[
                  const SizedBox(width: 8),
                  _actionButton('Report', () => _reportComment(comment)),
                ],
              ],
            ),
          ),
          if (comment.replies.isNotEmpty) ...[
            SizedBox(
              height: 24,
              child: TextButton(
                onPressed: () {
                  widget.state.setReplyExpanded(
                    comment.id,
                    !(widget.state.expandedReplies[comment.id] ?? false),
                  );
                },
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  minimumSize: const Size(0, 0),
                  foregroundColor: AppTheme.accentGold,
                  textStyle: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                child: Text(
                  widget.state.expandedReplies[comment.id] ?? false
                      ? 'Hide ${comment.replies.length} ${comment.replies.length == 1 ? 'reply' : 'replies'}'
                      : 'View ${comment.replies.length} ${comment.replies.length == 1 ? 'reply' : 'replies'}',
                ),
              ),
            ),
            if (widget.state.expandedReplies[comment.id] ?? false)
              Column(
                children:
                    comment.replies
                        .map(
                          (r) => Padding(
                            padding: const EdgeInsets.only(left: 16),
                            child: _commentWidget(r, depth + 1),
                          ),
                        )
                        .toList(),
              ),
          ],
        ],
      ),
    );
  }

  Widget _likeButton(int count, VoidCallback onTap) => GestureDetector(
    onTap: onTap,
    child: Row(
      children: [
        Icon(
          Icons.favorite,
          size: 16,
          color: count > 0 ? AppTheme.accentGold : AppTheme.textLight,
        ),
        if (count > 0) ...[
          const SizedBox(width: 4),
          Text(
            '$count',
            style: const TextStyle(
              fontSize: 12,
              color: AppTheme.accentGold,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ],
    ),
  );

  Widget _actionButton(String label, VoidCallback onTap) => TextButton(
    onPressed: onTap,
    style: TextButton.styleFrom(
      padding: EdgeInsets.zero,
      minimumSize: const Size(0, 0),
      foregroundColor: AppTheme.accentGold,
      textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
    ),
    child: Text(label),
  );

  void _showReplyDialog(Comment parent) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: const Text('Reply'),
            content: TextField(
              controller: controller,
              decoration: const InputDecoration(hintText: 'Your reply...'),
              maxLines: 3,
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () async {
                  if (controller.text.trim().isNotEmpty) {
                    try {
                      await widget.state.addReply(
                        parent.id,
                        controller.text.trim(),
                      );
                      Navigator.pop(ctx);
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Failed to add reply: $e')),
                      );
                    }
                  }
                },
                child: const Text('Send'),
              ),
            ],
          ),
    );
  }

  void _likeComment(Comment comment) {
    if (comment.id.isEmpty) return;
    // This would need to be implemented in the state class
    // For now, just update locally
    setState(() {
      comment.likes = comment.likes + 1;
    });
  }

  Future<void> _deleteComment(Comment comment) async {
    try {
      await widget.state.deleteComment(comment.id);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Comment deleted.')));
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to delete comment: $e')));
    }
  }

  Future<void> _reportComment(Comment comment) async {
    try {
      await widget.state.reportComment(comment.id);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Comment reported.')));
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to report comment: $e')));
    }
  }

  String _formatTime(DateTime time) {
    final diff = DateTime.now().difference(time);
    if (diff.inMinutes < 1) return 'now';
    if (diff.inHours < 1) return '${diff.inMinutes}m ago';
    if (diff.inDays < 1) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return DateFormat('MMM d, yyyy').format(time);
  }
}
