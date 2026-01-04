// lib/widgets/project_card_home.dart

import 'package:flutter/material.dart';
import 'package:auto_size_text/auto_size_text.dart';
import '../models/project.dart';
import '../theme.dart';
import '../utils/responsive.dart';

class ProjectCardHome extends StatelessWidget {
  final Project project;
  final VoidCallback onTap;
  final bool showStats;

  const ProjectCardHome({
    super.key,
    required this.project,
    required this.onTap,
    this.showStats = true,
  });

  @override
  Widget build(BuildContext context) {
    // More granular responsive dimensions
    final cardPadding = Responsive.getValue(
      context,
      mobile: 10.0,
      tablet: 12.0,
      desktop: 12.0,
      largeDesktop: 14.0,
    );
    final titleFontSize = Responsive.getValue(
      context,
      mobile: 13.0,
      tablet: 14.0,
      desktop: 15.0,
      largeDesktop: 16.0,
    );
    final subtitleFontSize = Responsive.getValue(
      context,
      mobile: 11.0,
      tablet: 12.0,
      desktop: 13.0,
      largeDesktop: 14.0,
    );
    final smallFontSize = Responsive.getValue(
      context,
      mobile: 9.0,
      tablet: 10.0,
      desktop: 11.0,
      largeDesktop: 12.0,
    );
    final statsFontSize = Responsive.getValue(
      context,
      mobile: 10.0,
      tablet: 11.0,
      desktop: 12.0,
      largeDesktop: 13.0,
    );

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(cardPadding),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.white, AppTheme.accentGold.withOpacity(0.08)],
          ),
          borderRadius: BorderRadius.circular(
            Responsive.getBorderRadius(context),
          ),
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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title
            AutoSizeText(
              project.title,
              style: TextStyle(
                fontSize: titleFontSize,
                fontWeight: FontWeight.w600,
                color: AppTheme.textDark,
              ),
              maxLines: 4, // Allow more lines if needed
              minFontSize: Responsive.getValue(
                context,
                mobile: 10.0,
                tablet: 11.0,
                desktop: 12.0,
                largeDesktop: 13.0,
              ),
              overflow: TextOverflow.ellipsis,
            ),
            SizedBox(
              height: Responsive.getValue(
                context,
                mobile: 3.0,
                tablet: 4.0,
                desktop: 4.0,
                largeDesktop: 5.0,
              ),
            ),
            // Owner and Date
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AutoSizeText(
                  'By ${project.owner.fullName}',
                  style: TextStyle(
                    fontSize: subtitleFontSize,
                    color: AppTheme.textMedium,
                  ),
                  maxLines: 1,
                  minFontSize: Responsive.getValue(
                    context,
                    mobile: 8.0,
                    tablet: 9.0,
                    desktop: 10.0,
                    largeDesktop: 11.0,
                  ),
                  overflow: TextOverflow.ellipsis,
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
            SizedBox(
              height: Responsive.getValue(
                context,
                mobile: 2.0,
                tablet: 2.5,
                desktop: 3.0,
                largeDesktop: 3.0,
              ),
            ),
            // Location
            if ((project.owner.country?.isNotEmpty ?? false) ||
                (project.owner.university?.isNotEmpty ?? false) ||
                (project.owner.department?.isNotEmpty ?? false)) ...[
              if (project.owner.country?.isNotEmpty ?? false)
                Text(
                  project.owner.country!,
                  style: TextStyle(
                    fontSize: smallFontSize,
                    color: AppTheme.textLight,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                )
              else
                Text(
                  "",
                  style: TextStyle(
                    fontSize: smallFontSize,
                    color: AppTheme.textLight,
                  ),
                ),
              if (project.owner.university?.isNotEmpty ?? false)
                AutoSizeText(
                  project.owner.university!,
                  maxLines: 1,
                  style: TextStyle(
                    fontSize: subtitleFontSize,
                    color: AppTheme.textLight,
                    fontWeight: FontWeight.bold,
                  ),
                  minFontSize: Responsive.getValue(
                    context,
                    mobile: 8.0,
                    tablet: 9.0,
                    desktop: 10.0,
                    largeDesktop: 11.0,
                  ),
                )
              else
                Text(
                  "",
                  maxLines: 1,
                  style: TextStyle(
                    fontSize: subtitleFontSize,
                    color: AppTheme.textLight,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              if (project.owner.department?.isNotEmpty ?? false)
                AutoSizeText(
                  project.owner.department!,
                  style: TextStyle(
                    fontSize: smallFontSize,
                    color: AppTheme.textLight,
                  ),
                  maxLines: 1,
                  minFontSize: Responsive.getValue(
                    context,
                    mobile: 7.0,
                    tablet: 8.0,
                    desktop: 9.0,
                    largeDesktop: 10.0,
                  ),
                  overflow: TextOverflow.ellipsis,
                )
              else
                Text(
                  "",
                  style: TextStyle(
                    fontSize: smallFontSize,
                    color: AppTheme.textLight,
                  ),
                ),
            ],

            // Bottom stats
            Container(
              margin: EdgeInsets.only(
                top: Responsive.getValue(
                  context,
                  mobile: 4.0,
                  tablet: 5.0,
                  desktop: 6.0,
                  largeDesktop: 6.0,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: 2),

                  _badge(context, project.status == 'completed'),
                  SizedBox(height: 2),

                  Text(
                    '${(project.collaborators?.length ?? 0) + 1} members',
                    style: TextStyle(
                      fontSize: statsFontSize,
                      color: AppTheme.textDark,
                    ),
                  ),
                  SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        Icons.favorite,
                        size: Responsive.getValue(
                          context,
                          mobile: 10.0,
                          tablet: 11.0,
                          desktop: 12.0,
                          largeDesktop: 13.0,
                        ),
                        color: Colors.red[400],
                      ),
                      SizedBox(
                        width: Responsive.getValue(
                          context,
                          mobile: 2.5,
                          tablet: 3.0,
                          desktop: 3.5,
                          largeDesktop: 4.0,
                        ),
                      ),
                      Text(
                        '${project.projectStat?.totalVotes ?? 0}',
                        style: TextStyle(
                          fontSize: statsFontSize,
                          color: AppTheme.textDark,
                        ),
                      ),
                      SizedBox(width: 8),

                      Icon(
                        Icons.comment,
                        size: Responsive.getValue(
                          context,
                          mobile: 9.0,
                          tablet: 10.0,
                          desktop: 11.0,
                          largeDesktop: 12.0,
                        ),
                        color: AppTheme.textMedium,
                      ),

                      SizedBox(
                        width: Responsive.getValue(
                          context,
                          mobile: 2.5,
                          tablet: 3.0,
                          desktop: 3.5,
                          largeDesktop: 4.0,
                        ),
                      ),
                      Text(
                        '${project.projectStat?.totalComments ?? 0}',
                        style: TextStyle(
                          fontSize: statsFontSize,
                          color: AppTheme.textDark,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _badge(BuildContext context, bool completed) => Container(
    padding: EdgeInsets.symmetric(
      horizontal: Responsive.getValue(
        context,
        mobile: 5.0,
        tablet: 6.0,
        desktop: 7.0,
        largeDesktop: 8.0,
      ),
      vertical: Responsive.getValue(
        context,
        mobile: 2.0,
        tablet: 2.5,
        desktop: 3.0,
        largeDesktop: 3.0,
      ),
    ),
    decoration: BoxDecoration(
      color: completed ? Colors.green[50] : Colors.amber[50],
      borderRadius: BorderRadius.circular(6),
    ),
    child: Text(
      completed ? 'Done' : 'Open',
      style: TextStyle(
        fontSize: Responsive.getValue(
          context,
          mobile: 9.0,
          tablet: 10.0,
          desktop: 11.0,
          largeDesktop: 12.0,
        ),
        color: completed ? Colors.green[700] : Colors.amber[700],
      ),
    ),
  );
}
