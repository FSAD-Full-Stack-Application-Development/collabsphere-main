// lib/widgets/project_card_profile.dart

import 'package:flutter/material.dart';
import '../models/project.dart';
import '../theme.dart';
import '../utils/responsive.dart';

class ProjectCardProfile extends StatelessWidget {
  final Project project;
  final VoidCallback onTap;
  final bool showStats;

  const ProjectCardProfile({
    super.key,
    required this.project,
    required this.onTap,
    this.showStats = true,
  });

  @override
  Widget build(BuildContext context) {
    final padding = Responsive.getValue(
      context,
      mobile: 8.0,
      tablet: 10.0,
      desktop: 10.0,
      largeDesktop: 12.0,
    );
    final titleFontSize = Responsive.getValue(
      context,
      mobile: 12.0,
      tablet: 13.0,
      desktop: 14.0,
      largeDesktop: 15.0,
    );
    final subtitleFontSize = Responsive.getValue(
      context,
      mobile: 10.0,
      tablet: 11.0,
      desktop: 12.0,
      largeDesktop: 13.0,
    );
    final smallFontSize = Responsive.getValue(
      context,
      mobile: 8.0,
      tablet: 9.0,
      desktop: 10.0,
      largeDesktop: 11.0,
    );

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(padding),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.white, AppTheme.accentGold.withOpacity(0.08)],
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
        child: Column(
          mainAxisSize: MainAxisSize.min,
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
                    style: TextStyle(
                      fontSize: titleFontSize,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textDark,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 2),
            // Owner and Date
            Row(
              children: [
                Expanded(
                  child: Text(
                    'By ${project.owner.fullName}',
                    style: TextStyle(
                      fontSize: subtitleFontSize,
                      color: AppTheme.textMedium,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (project.createdAt != null)
                  Text(
                    project.createdAt!.toLocal().toString().split(' ')[0],
                    style: TextStyle(
                      fontSize: smallFontSize,
                      color: AppTheme.textLight,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 2),
            // Location
            if ((project.owner.country?.isNotEmpty ?? false) ||
                (project.owner.university?.isNotEmpty ?? false) ||
                (project.owner.department?.isNotEmpty ?? false))
              Wrap(
                spacing: 8,
                runSpacing: 2,
                children: [
                  if (project.owner.country?.isNotEmpty ?? false)
                    Text(
                      project.owner.country!,
                      style: const TextStyle(
                        fontSize: 10,
                        color: AppTheme.textLight,
                      ),
                    ),
                  if (project.owner.university?.isNotEmpty ?? false)
                    Text(
                      project.owner.university!,
                      style: const TextStyle(
                        fontSize: 10,
                        color: AppTheme.textLight,
                      ),
                    ),
                  if (project.owner.department?.isNotEmpty ?? false)
                    Text(
                      project.owner.department!,
                      style: const TextStyle(
                        fontSize: 10,
                        color: AppTheme.textLight,
                      ),
                    ),
                ],
              ),
            const SizedBox(height: 4),
            // Bottom stats (similar to ProjectCardHome)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 1),
                _badge(project.status == 'completed'),
                const SizedBox(height: 1),
                Text(
                  '${(project.collaborators?.length ?? 0) + 1} members',
                  style: const TextStyle(
                    fontSize: 10,
                    color: AppTheme.textDark,
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Icon(Icons.favorite, size: 12, color: Colors.red[400]),
                    const SizedBox(width: 2),
                    Text(
                      '${project.projectStat?.totalVotes ?? 0}',
                      style: const TextStyle(
                        fontSize: 10,
                        color: AppTheme.textDark,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Icon(
                      Icons.comment,
                      size: 12,
                      color: AppTheme.textMedium,
                    ),
                    const SizedBox(width: 2),
                    Text(
                      '${project.projectStat?.totalComments ?? 0}',
                      style: const TextStyle(
                        fontSize: 10,
                        color: AppTheme.textDark,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _badge(bool completed) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
    decoration: BoxDecoration(
      color: completed ? Colors.green[50] : Colors.amber[50],
      borderRadius: BorderRadius.circular(4),
    ),
    child: Text(
      completed ? 'Done' : 'Open',
      style: TextStyle(
        fontSize: 9,
        color: completed ? Colors.green[700] : Colors.amber[700],
      ),
    ),
  );
}
