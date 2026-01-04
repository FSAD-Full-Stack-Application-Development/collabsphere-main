import 'package:flutter/material.dart';
import '../../models/project.dart';
import '../../theme.dart';

class ProjectTagsSection extends StatelessWidget {
  final Project? project;

  const ProjectTagsSection({super.key, required this.project});

  @override
  Widget build(BuildContext context) {
    if (project == null) {
      return const Center(
        child: CircularProgressIndicator(color: AppTheme.accentGold),
      );
    }

    return Wrap(
      spacing: 4, // Even more compact
      runSpacing: 4, // Even more compact
      children:
          project!.tags
              .map(
                (tag) => Chip(
                  label: Text(
                    tag.tagName,
                    style: const TextStyle(
                      fontSize: 13,
                    ), // Increased for better readability
                  ),
                  backgroundColor: AppTheme.accentGold.withOpacity(0.1),
                  labelStyle: const TextStyle(color: AppTheme.accentGold),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 1,
                  ), // More compact padding
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  visualDensity: VisualDensity.compact, // More compact
                ),
              )
              .toList(),
    );
  }
}
