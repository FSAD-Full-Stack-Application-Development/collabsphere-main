import 'dart:convert';

import 'package:collab_sphere/api/project.dart';
import 'package:flutter/material.dart';
import 'package:collab_sphere/models/project.dart';
import 'package:collab_sphere/models/user.dart';
import '../widgets/gradient.dart';
import '../widgets/autocomplete_field.dart';
import '../store/tags_controller.dart';
import '../theme.dart';
import '../utils/responsive.dart';

class CreateProjectPage extends StatefulWidget {
  final User currentUser;
  const CreateProjectPage({super.key, required this.currentUser});

  @override
  State<CreateProjectPage> createState() => _CreateProjectPageState();
}

class _CreateProjectPageState extends State<CreateProjectPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _titleCtrl = TextEditingController();
  final TextEditingController _descCtrl = TextEditingController();

  final List<Tag> _tags = [];

  String _status = 'Ideation';
  String _visibility = 'public';
  bool _isSubmitting = false;
  @override
  void initState() {
    super.initState();
    // Tags are loaded globally by TagsController
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  String _extractErrorMessage(String body) {
    try {
      final data = jsonDecode(body);
      if (data is Map) {
        if (data.containsKey('errors')) {
          final errors = data['errors'];
          if (errors is String) return errors;
          if (errors is List) return errors.join(', ');
          if (errors is Map) {
            // Join all values (which may be lists) into a single message
            return errors.values
                .map((v) {
                  if (v is List) return v.join(', ');
                  return v.toString();
                })
                .join(', ');
          }
        }
        if (data.containsKey('error')) return data['error'].toString();
        if (data.containsKey('message')) return data['message'].toString();
      }
      return body;
    } catch (_) {
      return body;
    }
  }

  void _createProject() async {
    if (!_formKey.currentState!.validate()) return;

    final Map<String, dynamic> payload = {
      'project': {
        'title': _titleCtrl.text.trim(),
        'description': _descCtrl.text.trim(),
        'status': _status,
        'visibility': _visibility,
        'show_funds': true,
      },
      'tags': _tags.map((t) => t.tagName).toList(),
    };

    setState(() => _isSubmitting = true);

    try {
      final response = await projectService.createProject(payload);

      if (!mounted) return;

      if (response.statusCode == 201) {
        // Success: optionally parse returned project
        String successMessage = 'Project created successfully';
        try {
          final data = jsonDecode(response.body);
          if (data is Map && data.containsKey('project')) {
            final proj = data['project'];
            if (proj is Map && proj.containsKey('title')) {
              successMessage = 'Created "${proj['title']}"';
            }
          } else if (data is Map && data.containsKey('message')) {
            successMessage = data['message'].toString();
          }
        } catch (_) {
          // ignore json parse errors for success message
        }

        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(successMessage)));

        // Close the create page and return success
        Navigator.pop(context, true);
      } else {
        final errorMsg = _extractErrorMessage(response.body);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Failed to create project (status ${response.statusCode}): $errorMsg',
            ),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Network or unexpected error: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
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
          'Create Project',
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
              padding: EdgeInsets.all(Responsive.getPadding(context)),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Title
                    TextFormField(
                      controller: _titleCtrl,
                      decoration: _inputDecoration(
                        'Project Title',
                        Icons.title,
                      ),
                      validator:
                          (v) => v?.trim().isEmpty ?? true ? 'Required' : null,
                    ),
                    const SizedBox(height: 16),

                    // Description
                    TextFormField(
                      controller: _descCtrl,
                      decoration: _inputDecoration(
                        'Description',
                        Icons.description,
                      ),
                      maxLines: 5,
                      validator:
                          (v) => v?.trim().isEmpty ?? true ? 'Required' : null,
                    ),
                    const SizedBox(height: 16),

                    // Status and Visibility in a single row
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: _status,
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
                                  _status = v ?? _status;
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
                            value: _visibility,
                            decoration: _inputDecoration(
                              'Visibility',
                              Icons.visibility,
                            ),
                            items: const [
                              DropdownMenuItem(
                                value: 'public',
                                child: Text('Public'),
                              ),
                              DropdownMenuItem(
                                value: 'private',
                                child: Text('Private'),
                              ),
                            ],
                            onChanged:
                                (v) => setState(() {
                                  _visibility = v ?? _visibility;
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

                    // Tags
                    AutocompleteField(
                      label: 'Add Tag',
                      initialValue: '',
                      suggestions: tagsController.getFilteredTags(
                        '', // Empty query to get all available tags
                        _tags.map((t) => t.tagName).toList(),
                      ),
                      suggestionsFetcher: (query) async {
                        return tagsController.getFilteredTags(
                          query,
                          _tags.map((t) => t.tagName).toList(),
                        );
                      },
                      onChanged: (_) {}, // no-op
                      onSelected: (tag) {
                        final tagName = tag.trim();
                        if (tagName.isNotEmpty &&
                            !_tags.any((t) => t.tagName == tagName)) {
                          setState(() {
                            _tags.add(
                              Tag(
                                id:
                                    DateTime.now().millisecondsSinceEpoch
                                        .toString(),
                                tagName: tagName,
                              ),
                            );
                          });
                        }
                        FocusScope.of(context).unfocus();
                      },
                      builderOverride: (context, controller, focusNode) {
                        return TextField(
                          controller: controller,
                          focusNode: focusNode,
                          onSubmitted: (value) {
                            final tagName = value.trim();
                            if (tagName.isNotEmpty &&
                                !_tags.any((t) => t.tagName == tagName)) {
                              setState(() {
                                _tags.add(
                                  Tag(
                                    id:
                                        DateTime.now().millisecondsSinceEpoch
                                            .toString(),
                                    tagName: tagName,
                                  ),
                                );
                              });
                            }
                            controller.clear();
                            FocusScope.of(context).unfocus();
                          },
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: Colors.white,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 16,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: const BorderSide(
                                color: Color(0xFFE2E8F0),
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: const BorderSide(
                                color: Color(0xFFFFC107),
                                width: 2,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      children:
                          _tags.map((t) {
                            return Chip(
                              label: Text(t.tagName),
                              deleteIconColor: AppTheme.textDark,
                              onDeleted: () => setState(() => _tags.remove(t)),
                            );
                          }).toList(),
                    ),

                    const SizedBox(height: 24),

                    // Button with inline loading indicator
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        // The themed gradient button (disabled while submitting)
                        GradientButton(
                          text:
                              _isSubmitting ? 'Creating...' : 'Create Project',
                          onPressed: _isSubmitting ? () {} : _createProject,
                          fullWidth: true,
                        ),

                        if (_isSubmitting)
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
