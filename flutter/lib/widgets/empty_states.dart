// lib/widgets/empty_states.dart

import 'package:flutter/material.dart';
import '../theme.dart';
import '../utils/responsive.dart';

class EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Widget? action;

  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    final iconSize = Responsive.getValue(
      context,
      mobile: 64.0,
      tablet: 72.0,
      desktop: 80.0,
      largeDesktop: 88.0,
    );
    final titleFontSize = Responsive.getValue(
      context,
      mobile: 18.0,
      tablet: 20.0,
      desktop: 22.0,
      largeDesktop: 24.0,
    );
    final subtitleFontSize = Responsive.getValue(
      context,
      mobile: 14.0,
      tablet: 15.0,
      desktop: 16.0,
      largeDesktop: 17.0,
    );
    final padding = Responsive.getPadding(context);

    return Center(
      child: Padding(
        padding: EdgeInsets.all(padding),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: iconSize, color: AppTheme.textLight),
            const SizedBox(height: 16),
            Text(
              title,
              style: TextStyle(
                fontSize: titleFontSize,
                fontWeight: FontWeight.w600,
                color: AppTheme.textDark,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: subtitleFontSize,
                color: AppTheme.textMedium,
              ),
              textAlign: TextAlign.center,
            ),
            if (action != null) ...[const SizedBox(height: 24), action!],
          ],
        ),
      ),
    );
  }
}

// Specific empty states for different contexts
class NoProjectsState extends StatelessWidget {
  final String? customMessage;

  const NoProjectsState({super.key, this.customMessage});

  @override
  Widget build(BuildContext context) {
    return EmptyState(
      icon: Icons.folder_open_outlined,
      title: 'No Projects Found',
      subtitle:
          customMessage ?? 'There are no projects to display at the moment.',
    );
  }
}

class NoTopProjectsState extends StatelessWidget {
  const NoTopProjectsState({super.key});

  @override
  Widget build(BuildContext context) {
    return EmptyState(
      icon: Icons.star_border_outlined,
      title: 'No Top Projects',
      subtitle: 'Top projects will appear here once they receive votes.',
    );
  }
}

class NoUsersState extends StatelessWidget {
  const NoUsersState({super.key});

  @override
  Widget build(BuildContext context) {
    return EmptyState(
      icon: Icons.people_outline,
      title: 'No Users Found',
      subtitle: 'There are no users to display at the moment.',
    );
  }
}

class NoTopUsersState extends StatelessWidget {
  const NoTopUsersState({super.key});

  @override
  Widget build(BuildContext context) {
    return EmptyState(
      icon: Icons.leaderboard_outlined,
      title: 'No Top Contributors',
      subtitle: 'Top contributors will appear here based on their activity.',
    );
  }
}

class NoNotificationsState extends StatelessWidget {
  const NoNotificationsState({super.key});

  @override
  Widget build(BuildContext context) {
    return EmptyState(
      icon: Icons.notifications_none_outlined,
      title: 'No Notifications',
      subtitle: 'You\'re all caught up! Check back later for updates.',
    );
  }
}
