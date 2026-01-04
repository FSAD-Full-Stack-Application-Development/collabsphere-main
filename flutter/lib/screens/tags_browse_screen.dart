import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../store/tags_controller.dart';
import '../theme.dart';
import 'project_list_screen.dart';

class TagsBrowseScreen extends StatefulWidget {
  const TagsBrowseScreen({super.key});

  @override
  State<TagsBrowseScreen> createState() => _TagsBrowseScreenState();
}

class _TagsBrowseScreenState extends State<TagsBrowseScreen> {
  final TagsController _tagsController = tagsController;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Browse by Tags'),
        backgroundColor: AppTheme.bgWhite,
        foregroundColor: AppTheme.textDark,
        elevation: 1,
      ),
      body: Container(
        decoration: BoxDecoration(gradient: AppTheme.gradientSoft),
        child: GetBuilder<TagsController>(
          init: _tagsController,
          builder: (controller) {
            if (controller.isLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            if (controller.tags.isEmpty) {
              return const Center(child: Text('No tags available'));
            }

            return SingleChildScrollView(
              padding: EdgeInsets.all(AppTheme.spacingMd),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    spacing: AppTheme.spacingXs,
                    runSpacing: AppTheme.spacingXs,
                    children:
                        controller.tags.map((tag) {
                          return GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder:
                                      (_) => ProjectListScreen(
                                        title: 'Projects with "$tag"',
                                        tags: [tag],
                                      ),
                                ),
                              );
                            },
                            child: Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: AppTheme.spacingMd,
                                vertical: AppTheme.spacingXs,
                              ),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    Colors.white,
                                    AppTheme.accentGold.withOpacity(0.08),
                                  ],
                                ),
                                border: Border.all(
                                  color: AppTheme.accentGold.withOpacity(0.4),
                                  width: 1.5,
                                ),
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppTheme.accentGold.withOpacity(0.2),
                                    blurRadius: 6,
                                    spreadRadius: 0.5,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Text(
                                tag,
                                style: TextStyle(
                                  color: AppTheme.textDark,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                  ),
                  SizedBox(height: AppTheme.spacingXl),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
