// lib/screens/edit_profile.dart
import 'dart:convert';
import 'package:collab_sphere/api/auth.dart';
import 'package:flutter/material.dart';
import 'package:collab_sphere/store/auth_controller.dart';
import '../models/user.dart';
import '../theme.dart';
import '../widgets/gradient.dart';
import '../widgets/autocomplete_field.dart';
import '../static/countries.dart';
import '../store/tags_controller.dart';
import '../static/universities.dart';
import '../static/departments.dart';
import '../api/tags.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});
  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();

  // ---- 1. tempUser holds the editable copy ----
  late User tempUser;

  final TextEditingController _tagCtrl = TextEditingController();

  bool _saving = false;
  String? _error;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadProfile();
    // Tags are loaded globally by TagsController
  }

  // -----------------------------------------------------------------
  // 2. Load current user → tempUser (deep copy of lists)
  // -----------------------------------------------------------------
  Future<void> _loadProfile() async {
    final current = authController.user;
    if (current == null) {
      Navigator.of(context).pop(); // safety
      return;
    }

    setState(() {
      tempUser = User(
        id: current.id,
        fullName: current.fullName,
        email: current.email,
        bio: current.bio,
        avatarUrl: current.avatarUrl,
        country: current.country,
        university: current.university,
        department: current.department,
        tags: List<String>.from(current.tags), // deep copy
      );
      _loading = false;
    });
  }

  // -----------------------------------------------------------------
  // 5. SAVE → API → update global instance
  // -----------------------------------------------------------------
  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _saving = true);
    final Map<String, dynamic> payload = {
      'full_name': tempUser.fullName,
      'email': tempUser.email,
      'bio': tempUser.bio,
      'avatar_url': tempUser.avatarUrl,
      'country': tempUser.country,
      'university': tempUser.university,
      'department': tempUser.department,
      'tags': tempUser.tags,
    };
    try {
      // Use authController.updateProfile which handles update() internally
      final success = await authController.updateProfile(payload);

      if (success) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Profile saved successfully!'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context);
        }
      } else {
        final msg = authController.error ?? 'Failed to save profile';
        throw Exception(msg);
      }
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _saving = false);
    }
  }

  // -----------------------------------------------------------------
  // 6. Tag helpers
  // -----------------------------------------------------------------
  void _addTag(String value) {
    final trimmed = value.trim().replaceAll(RegExp(r',$'), '');
    if (trimmed.isEmpty) return;

    // optimistic: add locally
    if (!tempUser.tags.contains(trimmed)) {
      setState(() => tempUser.tags.add(trimmed));
    }
    _tagCtrl.clear();

    // create global tag and persist user's tags immediately
    () async {
      try {
        final resp = await tagService.createTag(trimmed);
        if (resp.statusCode == 201 || resp.statusCode == 200) {
          final success = await authController.updateProfile({
            'tags': tempUser.tags,
          });
          if (!success) {
            setState(
              () => _error = authController.error ?? 'Failed to save tags',
            );
          }
        } else {
          setState(() => _error = 'Failed to create tag on server');
        }
      } catch (e) {
        setState(() => _error = e.toString());
      }
    }();
  }

  void _removeTag(String tag) => setState(() => tempUser.tags.remove(tag));

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

  // -----------------------------------------------------------------
  // UI
  // -----------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: AppTheme.accentGold),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Edit Profile',
          style: TextStyle(color: AppTheme.textDark),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: AppTheme.textDark),
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
                    // Avatar placeholder (you can add image upload later)
                    Center(
                      child: CircleAvatar(
                        radius: 70,
                        backgroundColor: AppTheme.accentGold,
                        child: Text(
                          tempUser.fullName.isNotEmpty
                              ? tempUser.fullName[0].toUpperCase()
                              : 'U',
                          style: const TextStyle(
                            fontSize: 56,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Full Name
                    TextFormField(
                      initialValue: tempUser.fullName,
                      decoration: _inputDecoration('Full Name', Icons.person),
                      validator:
                          (v) => v?.trim().isEmpty ?? true ? 'Required' : null,
                      onChanged: (v) => tempUser.fullName = v,
                    ),
                    const SizedBox(height: 16),

                    // Email
                    TextFormField(
                      initialValue: tempUser.email,
                      decoration: _inputDecoration('Email', Icons.email),
                      keyboardType: TextInputType.emailAddress,
                      validator:
                          (v) => v?.trim().isEmpty ?? true ? 'Required' : null,
                      onChanged: (v) => tempUser.email = v,
                    ),
                    const SizedBox(height: 16),

                    // Country
                    AutocompleteField(
                      label: 'Country',
                      initialValue: tempUser.country ?? '',
                      suggestions: allCountries,
                      onChanged: (v) => tempUser.country = v.isEmpty ? null : v,
                      forceSelect: true,
                    ),
                    const SizedBox(height: 16),

                    // Bio
                    TextFormField(
                      initialValue: tempUser.bio ?? '',
                      decoration: _inputDecoration(
                        'Short Bio',
                        Icons.description,
                      ),
                      maxLines: 3,
                      onChanged: (v) => tempUser.bio = v.isEmpty ? null : v,
                    ),
                    const SizedBox(height: 16),

                    // University
                    AutocompleteField(
                      label: 'University',
                      initialValue: tempUser.university ?? '',
                      suggestions: popularUniversities,
                      onChanged:
                          (v) => tempUser.university = v.isEmpty ? null : v,
                      requiredField: true,
                    ),
                    const SizedBox(height: 16),

                    // Department
                    AutocompleteField(
                      label: 'Department',
                      initialValue: tempUser.department ?? '',
                      suggestions: popularDepartments,
                      onChanged:
                          (v) => tempUser.department = v.isEmpty ? null : v,
                      requiredField: true,
                    ),
                    const SizedBox(height: 16),

                    // Tags
                    AutocompleteField(
                      label: 'Add Tag',
                      initialValue: '',
                      suggestions: tagsController.getFilteredTags(
                        '', // Empty query to get all available tags
                        tempUser.tags,
                      ),
                      suggestionsFetcher: (query) async {
                        return tagsController.getFilteredTags(
                          query,
                          tempUser.tags,
                        );
                      },
                      onChanged: (_) {}, // no-op
                      onSelected: (tag) {
                        final tagName = tag.trim();
                        if (tagName.isNotEmpty &&
                            !tempUser.tags.contains(tagName)) {
                          setState(() {
                            tempUser.tags.add(tagName);
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
                                !tempUser.tags.contains(tagName)) {
                              setState(() {
                                tempUser.tags.add(tagName);
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
                          tempUser.tags.map((t) {
                            return Chip(
                              label: Text(t),
                              deleteIconColor: AppTheme.textDark,
                              onDeleted: () => _removeTag(t),
                            );
                          }).toList(),
                    ),

                    if (_error != null) ...[
                      const SizedBox(height: 16),
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
                    ],

                    const SizedBox(height: 24),

                    // Button with inline loading indicator
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        // The themed gradient button (disabled while submitting)
                        GradientButton(
                          text: _saving ? 'Saving...' : 'Save Profile',
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
