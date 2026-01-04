import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../store/auth_controller.dart';
import '../models/user.dart';
import '../theme.dart';
import '../widgets/autocomplete_field.dart';
import '../static/tags.dart';
import '../static/universities.dart';
import '../static/departments.dart';
import '../api/tags.dart';
import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';
import '../utils/navigation_helper.dart';

class CompleteProfileScreen extends StatefulWidget {
  const CompleteProfileScreen({super.key});
  @override
  State<CompleteProfileScreen> createState() => _CompleteProfileScreenState();
}

class _CompleteProfileScreenState extends State<CompleteProfileScreen> {
  late User user;
  final TextEditingController _tagCtrl = TextEditingController();
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    user = authController.user!;
  }

  void _addTag(String value) {
    final trimmed = value.trim().replaceAll(RegExp(r',$'), '');
    if (trimmed.isEmpty) return;

    // Optimistic UI: add locally first
    if (!user.tags.contains(trimmed)) {
      setState(() => user.tags.add(trimmed));
    }
    _tagCtrl.clear();

    // Create tag globally and persist to user's profile immediately
    () async {
      try {
        final resp = await tagService.createTag(trimmed);
        if (resp.statusCode == 201 || resp.statusCode == 200) {
          // Persist user's tags
          final success = await authController.updateProfile({
            'tags': user.tags,
          });
          if (!success) {
            setState(() {
              _error = authController.error ?? 'Failed to save tags to profile';
            });
          }
        } else {
          setState(() {
            _error = 'Failed to create tag on server';
          });
        }
      } catch (e) {
        setState(() => _error = e.toString());
      }
    }();
  }

  void _removeTag(String tag) => setState(() => user.tags.remove(tag));

  Future<void> _save() async {
    setState(() => _saving = true);
    final payload = user.toJson();
    try {
      final response = await authController.updateProfile(payload);
      if (response) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Profile completed!'),
              backgroundColor: Colors.green,
            ),
          );
          NavigationHelper.pushAndRemoveUntil(context, '/');
        }
      } else {
        setState(() => _error = authController.error ?? 'Failed to save');
      }
    } finally {
      setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final missingBio = user.bio == null || user.bio!.isEmpty;
    // avatar not handled here currently

    return Scaffold(
      appBar: AppBar(
        title: const Text('Complete Your Profile'),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Container(
        decoration: BoxDecoration(gradient: AppTheme.gradientSoft),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Always show University and Department so users can set or edit them
              AutocompleteField(
                label: 'University',
                initialValue: user.university ?? '',
                suggestions: popularUniversities,
                onChanged: (v) => setState(() => user.university = v),
                requiredField: true,
              ),
              const SizedBox(height: 20),
              AutocompleteField(
                label: 'Department',
                initialValue: user.department ?? '',
                suggestions: popularDepartments,
                onChanged: (v) => setState(() => user.department = v),
                requiredField: true,
              ),
              const SizedBox(height: 20),
              if (missingBio)
                TextFormField(
                  initialValue: user.bio ?? '',
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Short Bio',
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (v) => setState(() => user.bio = v),
                ),
              if (missingBio) const SizedBox(height: 20),
              // Tags: always visible so users can add/remove their tags
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Skills & Interests',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children:
                        user.tags
                            .map(
                              (t) => Chip(
                                label: Text(
                                  t,
                                  style: const TextStyle(fontSize: 14),
                                ),
                                backgroundColor: AppTheme.accentGold
                                    .withOpacity(0.15),
                                deleteIconColor: AppTheme.accentGold,
                                onDeleted: () => _removeTag(t),
                              ),
                            )
                            .toList(),
                  ),
                  const SizedBox(height: 12),
                  // Use a Builder so we can capture the controller provided by the
                  // AutocompleteField's builderOverride and clear it from onSelected.
                  Builder(
                    builder: (context) {
                      TextEditingController? _localTagController;
                      return AutocompleteField(
                        label: 'Add Tag',
                        initialValue: '',
                        suggestions:
                            popularTags
                                .where((tag) => !user.tags.contains(tag))
                                .toList(),
                        suggestionsFetcher: (term) async {
                          try {
                            final resp = await tagService.autocomplete(term);
                            if (resp.statusCode == 200 &&
                                resp.body.isNotEmpty) {
                              final decoded = jsonDecode(resp.body) as List;
                              return decoded
                                  .map((e) => e.toString())
                                  .where((t) => !user.tags.contains(t))
                                  .toList();
                            }
                          } catch (_) {}
                          return popularTags
                              .where((tag) => !user.tags.contains(tag))
                              .toList();
                        },
                        onChanged: (_) {}, // no-op
                        onSelected: (tag) {
                          _addTag(tag);
                          // clear the actual controller used by the field
                          _localTagController?.clear();
                        },
                        builderOverride: (context, controller, focusNode) {
                          // capture the provided controller so onSelected can clear it
                          _localTagController = controller;
                          return TextField(
                            controller: controller,
                            focusNode: focusNode,
                            decoration: const InputDecoration(
                              hintText: 'Type and press Enter to add',
                              border: OutlineInputBorder(),
                            ),
                            onSubmitted: (tag) {
                              _addTag(tag);
                              controller.clear();
                            },
                          );
                        },
                      );
                    },
                  ),
                ],
              ),
              const SizedBox(height: 20),
              if (_error != null)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.red[50],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _error!,
                    style: TextStyle(color: Colors.red[700]),
                  ),
                ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _saving ? null : _save,
                  child:
                      _saving
                          ? const CircularProgressIndicator()
                          : const Text('Save & Continue'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
