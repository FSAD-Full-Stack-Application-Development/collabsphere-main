import 'package:flutter/material.dart';
import '../../models/project.dart';
import '../../theme.dart';

class ProjectKeyInfoSection extends StatelessWidget {
  final Project? project;

  const ProjectKeyInfoSection({super.key, required this.project});

  @override
  Widget build(BuildContext context) {
    if (project == null) {
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
          children: [
            // Owner info, status, and visibility in one compact row
            Row(
              children: [
                // Owner info with avatar
                Expanded(
                  flex: 2,
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 18, // Slightly smaller
                        backgroundColor: AppTheme.accentGold,
                        child: Text(
                          project!.owner.fullName.isNotEmpty
                              ? project!.owner.fullName[0].toUpperCase()
                              : '?',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              project!.owner.fullName,
                              style: const TextStyle(
                                fontSize: 15, // Slightly smaller
                                fontWeight: FontWeight.bold,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.visible,
                            ),
                            const Text(
                              'Project Owner',
                              style: TextStyle(
                                fontSize: 11, // Smaller
                                color: AppTheme.textLight,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                // Status badge (compact)
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 8),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: _getStatusColor().withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _getStatusColor().withOpacity(0.3),
                    ),
                  ),
                  child: Text(
                    _getStatusText(),
                    style: TextStyle(
                      color: _getStatusColor(),
                      fontWeight: FontWeight.w600,
                      fontSize: 11, // Smaller
                    ),
                  ),
                ),
                // Visibility badge (compact)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color:
                        project!.visibility == 'public'
                            ? Colors.green.withOpacity(0.1)
                            : Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color:
                          project!.visibility == 'public'
                              ? Colors.green.withOpacity(0.3)
                              : Colors.orange.withOpacity(0.3),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        project!.visibility == 'public'
                            ? Icons.public
                            : Icons.lock,
                        size: 14, // Smaller
                        color:
                            project!.visibility == 'public'
                                ? Colors.green
                                : Colors.orange,
                      ),
                      const SizedBox(width: 3),
                      Text(
                        project!.visibility == 'public' ? 'Public' : 'Private',
                        style: TextStyle(
                          fontSize: 11, // Smaller
                          fontWeight: FontWeight.w600,
                          color:
                              project!.visibility == 'public'
                                  ? Colors.green
                                  : Colors.orange,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor() {
    switch (project!.status) {
      case 'Completed':
        return Colors.green;
      case 'Ongoing':
        return Colors.blue;
      case 'Ideation':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  String _getStatusText() {
    switch (project!.status) {
      case 'Completed':
        return 'Completed';
      case 'Ongoing':
        return 'Ongoing';
      case 'Ideation':
        return 'Planning';
      default:
        return project!.status;
    }
  }
}
