import 'package:flutter/material.dart';
import '../../models/project.dart';
import '../../theme.dart';

class ProjectDescriptionSection extends StatelessWidget {
  final Project? project;

  const ProjectDescriptionSection({super.key, required this.project});

  @override
  Widget build(BuildContext context) {
    if (project == null) {
      return const Center(
        child: CircularProgressIndicator(color: AppTheme.accentGold),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.borderColor.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                Icons.description_outlined,
                size: 18,
                color: AppTheme.textMedium,
              ),
              SizedBox(width: 8),
              Text(
                'Description',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            project?.description ?? '-',
            style: const TextStyle(
              fontSize: 15,
              height: 1.6,
              color: AppTheme.textDark,
            ),
          ),
        ],
      ),
    );
  }
}
