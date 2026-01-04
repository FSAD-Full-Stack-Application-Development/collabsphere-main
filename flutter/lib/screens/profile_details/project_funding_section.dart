import 'package:collab_sphere/store/auth_controller.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../theme.dart';
import '../project_detail_state.dart';
import '../view_requests.dart';
import '../../api/project.dart';

class ProjectFundingSection extends StatefulWidget {
  final ProjectDetailState state;

  const ProjectFundingSection({super.key, required this.state});

  @override
  State<ProjectFundingSection> createState() => _ProjectFundingSectionState();
}

class _ProjectFundingSectionState extends State<ProjectFundingSection> {
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
    final currentUserId = authController.user?.id;
    final isOwner = widget.state.project!.isOwnerFor(currentUserId);

    // Don't show funding section if no funding goal is set
    if (widget.state.project!.fundingGoal == null ||
        widget.state.project!.fundingGoal == 0) {
      if (isOwner) {
        // Show "Add Funding Goal" button for owner
        return Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          color: Colors.white,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Funding',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Set a funding goal to start receiving contributions from the community.',
                  style: TextStyle(color: AppTheme.textLight),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _showAddFundingGoalDialog,
                    icon: const Icon(Icons.add),
                    label: const Text('Add Funding Goal'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.accentGold,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      } else {
        // Hide funding section for non-owners if no goal is set
        return const SizedBox.shrink();
      }
    }

    // Show funding progress if goal is set
    final raised = widget.state.project!.currentFunding ?? 0.0;
    final goal = widget.state.project!.fundingGoal!;
    final progress = goal > 0 ? raised / goal : 0.0;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Funding Progress',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                if (isOwner)
                  IconButton(
                    onPressed: _showAddFundingGoalDialog,
                    icon: const Icon(Icons.edit, size: 20),
                    tooltip: 'Edit Funding Goal',
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '\$${NumberFormat.compact().format(raised)} raised',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.accentGold,
                  ),
                ),
                Text(
                  '\$${NumberFormat.compact().format(goal)} goal',
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppTheme.textLight,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: progress.clamp(0.0, 1.0),
              minHeight: 6,
              backgroundColor: AppTheme.bgLight,
              valueColor: const AlwaysStoppedAnimation(AppTheme.accentGold),
              borderRadius: BorderRadius.circular(3),
            ),
            const SizedBox(height: 16),
            // Funding actions
            if (!isOwner)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _showFundProjectDialog,
                  icon: const Icon(Icons.attach_money),
                  label: const Text('Fund This Project'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.accentGold,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              )
            else
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _navigateToFundingRequests(),
                      icon: const Icon(Icons.list),
                      label: const Text('View Requests'),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: AppTheme.accentGold),
                        foregroundColor: AppTheme.accentGold,
                      ),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  void _showAddFundingGoalDialog() {
    final TextEditingController goalController = TextEditingController(
      text: widget.state.project!.fundingGoal?.toStringAsFixed(0) ?? '',
    );

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Set Funding Goal'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: goalController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Funding Goal (\$)',
                    hintText: 'Enter amount in USD',
                    prefixText: '\$',
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () async {
                  final goal = double.tryParse(goalController.text.trim());
                  if (goal != null && goal > 0) {
                    try {
                      // Update project with funding goal
                      final response = await projectService
                          .updateProjectFundingGoal(
                            widget.state.project!.id,
                            goal,
                          );

                      if (response.statusCode == 200) {
                        // Refresh project data
                        await widget.state.refreshProject();
                        Navigator.of(context).pop();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Funding goal updated successfully'),
                          ),
                        );
                      } else {
                        throw Exception('Failed to update funding goal');
                      }
                    } catch (e) {
                      ScaffoldMessenger.of(
                        context,
                      ).showSnackBar(SnackBar(content: Text('Error: $e')));
                    }
                  }
                },
                child: const Text('Set Goal'),
              ),
            ],
          ),
    );
  }

  void _showFundProjectDialog() {
    final TextEditingController amountController = TextEditingController();
    final TextEditingController messageController = TextEditingController();
    bool isLoading = false;

    showDialog(
      context: context,
      builder:
          (context) => StatefulBuilder(
            builder:
                (context, setState) => AlertDialog(
                  title: const Text('Fund This Project'),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextField(
                        controller: amountController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Amount (\$)',
                          hintText: 'Enter funding amount',
                          prefixText: '\$',
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: messageController,
                        maxLines: 3,
                        decoration: const InputDecoration(
                          labelText: 'Message (Optional)',
                          hintText: 'Leave a message for the project owner',
                        ),
                      ),
                    ],
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancel'),
                    ),
                    ElevatedButton(
                      onPressed:
                          isLoading
                              ? null
                              : () async {
                                final amount = double.tryParse(
                                  amountController.text.trim(),
                                );
                                if (amount != null && amount > 0) {
                                  setState(() => isLoading = true);
                                  try {
                                    final resp = await projectService
                                        .submitFundingRequest(
                                          widget.state.project!.id,
                                          amount,
                                          messageController.text.trim().isEmpty
                                              ? ''
                                              : messageController.text.trim(),
                                        );

                                    if (resp.statusCode == 200 ||
                                        resp.statusCode == 201) {
                                      Navigator.pop(context);
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        const SnackBar(
                                          content: Text(
                                            'Funding request submitted successfully! It will be processed once approved by the project owner.',
                                          ),
                                          backgroundColor: Colors.green,
                                        ),
                                      );
                                    } else {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            'Failed to submit funding request: ${resp.statusCode}',
                                          ),
                                          backgroundColor: Colors.red,
                                        ),
                                      );
                                    }
                                  } catch (e) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          'Error submitting funding request: $e',
                                        ),
                                        backgroundColor: Colors.red,
                                      ),
                                    );
                                  } finally {
                                    setState(() => isLoading = false);
                                  }
                                } else {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'Please enter a valid amount greater than 0',
                                      ),
                                      backgroundColor: Colors.orange,
                                    ),
                                  );
                                }
                              },
                      child:
                          isLoading
                              ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.white,
                                  ),
                                ),
                              )
                              : const Text('Fund Project'),
                    ),
                  ],
                ),
          ),
    );
  }

  void _navigateToFundingRequests() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ViewFundingRequestsPage(project: widget.state.project!),
      ),
    );
  }
}
