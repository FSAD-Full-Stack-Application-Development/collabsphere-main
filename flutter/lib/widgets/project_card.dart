// lib/widgets/project_card.dart

import 'package:flutter/material.dart';
import '../models/project.dart';
import '../theme.dart';

// lib/widgets/project_card.dart
class ProjectCard extends StatelessWidget {
  final Project project;
  final VoidCallback onTap;
  final bool showStats;

  const ProjectCard({
    super.key,
    required this.project,
    required this.onTap,
    this.showStats = true,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.white, AppTheme.accentGold.withOpacity(0.05)],
          ),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            width: 2,
            color: AppTheme.accentGold.withOpacity(0.3),
          ),
          boxShadow: [
            BoxShadow(
              color: AppTheme.accentGold.withOpacity(0.15),
              blurRadius: 8,
              spreadRadius: 1,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(width: 3, height: 3, color: AppTheme.accentGold),
                const SizedBox(width: 5),
                Expanded(
                  child: Text(
                    project.title,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            if (project.description != null && project.description!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 2.0),
                child: Text(
                  project.description!,
                  style: const TextStyle(
                    fontSize: 10,
                    color: AppTheme.textMedium,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            const SizedBox(height: 6),
            Row(
              children: [
                _badge(project.status == 'completed'),
                const SizedBox(width: 5),
                Text(
                  '${(project.collaborators?.length ?? 0) + 1} members',
                  style: const TextStyle(fontSize: 10),
                ),
                const Spacer(),
                if (showStats) ...[
                  Icon(Icons.favorite, size: 12, color: Colors.red[400]),
                  const SizedBox(width: 2),
                  Text(
                    '${project.projectStat?.totalVotes ?? 0}',
                    style: const TextStyle(fontSize: 10),
                  ),
                  const SizedBox(width: 6),
                  const Icon(
                    Icons.remove_red_eye,
                    size: 12,
                    color: AppTheme.textLight,
                  ),
                  const SizedBox(width: 2),
                  Text(
                    '${project.projectStat?.totalViews ?? 0}',
                    style: const TextStyle(fontSize: 10),
                  ),
                ],
              ],
            ),
            if (project.tags.isNotEmpty) const SizedBox(height: 4),
          ],
        ),
      ),
    );
  }

  Widget _badge(bool completed) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
    decoration: BoxDecoration(
      color: completed ? Colors.green[50] : Colors.amber[50],
      borderRadius: BorderRadius.circular(6),
    ),
    child: Text(
      completed ? 'Done' : 'Open',
      style: TextStyle(
        fontSize: 10,
        color: completed ? Colors.green[700] : Colors.amber[700],
      ),
    ),
  );
}
