import 'package:flutter/material.dart';
import '../../theme.dart';
import '../project_detail_state.dart';
import '../../models/project.dart';

class ProjectStatsSection extends StatefulWidget {
  final ProjectDetailState state;

  const ProjectStatsSection({super.key, required this.state});

  @override
  State<ProjectStatsSection> createState() => _ProjectStatsSectionState();
}

class _ProjectStatsSectionState extends State<ProjectStatsSection> {
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

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.borderColor.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _compactStatItem(
            Icons.remove_red_eye_outlined,
            widget.state.project!.projectStat?.totalViews ?? 0,
            'Views',
            Colors.green.shade600,
          ),
          Container(
            height: 24,
            width: 1,
            color: AppTheme.borderColor.withOpacity(0.3),
          ),
          _compactStatItem(
            Icons.favorite_outline,
            widget.state.project!.voteCount,
            'Votes',
            Colors.red.shade600,
          ),
          Container(
            height: 24,
            width: 1,
            color: AppTheme.borderColor.withOpacity(0.3),
          ),
          _compactStatItem(
            Icons.chat_bubble_outline,
            _getTotalCommentCount(),
            'Comments',
            Colors.blue.shade600,
          ),
        ],
      ),
    );
  }

  int _getTotalCommentCount() {
    // Count all comments using depth-first approach
    // Each comment and all its replies are counted exactly once
    int total = 0;
    for (final comment in widget.state.project!.comments) {
      total += _countCommentDepthFirst(comment);
    }
    return total;
  }

  int _countCommentDepthFirst(Comment comment) {
    int count = 1; // Count this comment
    for (final reply in comment.replies) {
      count += _countCommentDepthFirst(reply); // Recursively count all replies
    }
    return count;
  }

  Widget _compactStatItem(
    IconData icon,
    int count,
    String label,
    Color color,
  ) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(icon, size: 18, color: color),
      const SizedBox(width: 6),
      Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _formatCount(count),
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
          Text(
            label,
            style: const TextStyle(
              fontSize: 10,
              color: AppTheme.textLight,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    ],
  );

  String _formatCount(int count) {
    if (count >= 1000000) {
      return '${(count / 1000000).toStringAsFixed(1)}M';
    } else if (count >= 1000) {
      return '${(count / 1000).toStringAsFixed(1)}K';
    }
    return count.toString();
  }
}
