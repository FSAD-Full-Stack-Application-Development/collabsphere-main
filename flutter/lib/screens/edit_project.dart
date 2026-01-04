import 'package:flutter/material.dart';
import 'dart:convert';
import '../models/project.dart';
import '../theme.dart';
import '../widgets/gradient.dart';
import '../api/project.dart';

class EditProjectPage extends StatefulWidget {
  final Project project;
  const EditProjectPage({super.key, required this.project});

  @override
  State<EditProjectPage> createState() => _EditProjectPageState();
}

class _EditProjectPageState extends State<EditProjectPage> {
  final _formKey = GlobalKey<FormState>();
  late Map<String, dynamic> _data;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _data = {
      'title': widget.project.title,
      'description': widget.project.description ?? '',
      'status': _capitalize(widget.project.status),
      'visibility': _capitalize(widget.project.visibility),
      'showFunds': widget.project.showFunds,
    };
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save(); // Save form values to _data
    setState(() => _saving = true);

    try {
      // Create updated project with lowercase values for backend
      final updatedProject = Project(
        id: widget.project.id,
        title: _data['title'],
        description: _data['description'],
        status:
            _data['status']?.toString().toLowerCase() ?? widget.project.status,
        visibility:
            _data['visibility']?.toString().toLowerCase() ??
            widget.project.visibility,
        showFunds: _data['showFunds'] ?? widget.project.showFunds,
        owner: widget.project.owner,
        tags: widget.project.tags,
        collaborators: widget.project.collaborators,
        projectStat: widget.project.projectStat,
        voteCount: widget.project.voteCount,
        comments: widget.project.comments,
        fundingGoal: widget.project.fundingGoal,
        currentFunding: widget.project.currentFunding,
      );

      final response = await projectService.updateProject(updatedProject);

      if (!mounted) return;

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Project updated successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true); // Return true to indicate success
      } else {
        final errorBody = jsonDecode(response.body);
        final errorMessage =
            errorBody['errors']?.join(', ') ??
            errorBody['error'] ??
            'Failed to update project';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMessage), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error updating project: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  String _capitalize(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1).toLowerCase();
  }

  InputDecoration _inputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: AppTheme.textLight),
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppTheme.borderColor, width: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Edit Project',
          style: TextStyle(color: AppTheme.textDark),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppTheme.textDark),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      // Detect taps anywhere in the body and unfocus text fields
      body: Container(
        decoration: BoxDecoration(gradient: AppTheme.gradientSoft),
        child: GestureDetector(
          behavior: HitTestBehavior.translucent,
          onTap: () {
            final currentFocus = FocusScope.of(context);
            if (!currentFocus.hasPrimaryFocus &&
                currentFocus.focusedChild != null) {
              currentFocus.unfocus();
            }
          },
          child: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Title
                    TextFormField(
                      initialValue: _data['title'],
                      decoration: _inputDecoration(
                        'Project Title',
                        Icons.title,
                      ),
                      validator:
                          (v) => v?.trim().isEmpty ?? true ? 'Required' : null,
                      onChanged: (v) => _data['title'] = v,
                    ),
                    const SizedBox(height: 16),

                    // Description
                    TextFormField(
                      initialValue: _data['description'],
                      decoration: _inputDecoration(
                        'Description',
                        Icons.description,
                      ),
                      maxLines: 5,
                      validator:
                          (v) => v?.trim().isEmpty ?? true ? 'Required' : null,
                      onChanged: (v) => _data['description'] = v,
                    ),
                    const SizedBox(height: 16),

                    // Status and Visibility in a single row
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: _data['status'],
                            decoration: _inputDecoration('Status', Icons.flag),
                            items: const [
                              DropdownMenuItem(
                                value: 'Ideation',
                                child: Text('Ideation'),
                              ),
                              DropdownMenuItem(
                                value: 'Ongoing',
                                child: Text('Ongoing'),
                              ),
                              DropdownMenuItem(
                                value: 'Completed',
                                child: Text('Completed'),
                              ),
                            ],
                            onChanged:
                                (v) => setState(() {
                                  _data['status'] = v ?? _data['status'];
                                }),
                            validator:
                                (v) =>
                                    (v == null || v.isEmpty)
                                        ? 'Required'
                                        : null,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: _data['visibility'],
                            decoration: _inputDecoration(
                              'Visibility',
                              Icons.visibility,
                            ),
                            items: const [
                              DropdownMenuItem(
                                value: 'Public',
                                child: Text('Public'),
                              ),
                              DropdownMenuItem(
                                value: 'Private',
                                child: Text('Private'),
                              ),
                            ],
                            onChanged:
                                (v) => setState(() {
                                  _data['visibility'] =
                                      v ?? _data['visibility'];
                                }),
                            validator:
                                (v) =>
                                    (v == null || v.isEmpty)
                                        ? 'Required'
                                        : null,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // Show Funding Switch
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppTheme.borderColor),
                      ),
                      child: SwitchListTile(
                        title: Text(
                          'Show Funding?',
                          style: TextStyle(
                            color: AppTheme.textDark,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        value: _data['showFunds'] == true,
                        activeColor: AppTheme.accentGold,
                        onChanged:
                            (v) => setState(() => _data['showFunds'] = v),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Button with inline loading indicator
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        // The themed gradient button (disabled while submitting)
                        GradientButton(
                          text: _saving ? 'Updating...' : 'Update Project',
                          onPressed: _saving ? () {} : _save,
                          fullWidth: true,
                        ),

                        if (_saving)
                          // small circular indicator centered over the button to indicate loading
                          SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                AppTheme.textLight,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
