import 'package:flutter/material.dart';

class OnboardingStep {
  final String title;
  final String description;
  final IconData icon;
  final String imagePath;
  final List<String> features;

  const OnboardingStep({
    required this.title,
    required this.description,
    required this.icon,
    this.imagePath = '',
    this.features = const [],
  });
}

class OnboardingData {
  static final List<OnboardingStep> steps = [
    OnboardingStep(
      title: 'Welcome to CollabSphere',
      description:
          'Your academic collaboration platform connecting students, researchers, and innovators worldwide.',
      icon: Icons.rocket_launch,
      features: [
        'Connect with peers globally',
        'Collaborate on academic projects',
        'Share ideas and innovations',
      ],
    ),
    OnboardingStep(
      title: 'Discover Projects',
      description:
          'Explore innovative projects from universities around the world. Search, filter by tags, and find projects that match your interests.',
      icon: Icons.explore,
      features: [
        'Browse all projects',
        'Search by keywords',
        'Filter by tags and categories',
        'View trending and top projects',
      ],
    ),
    OnboardingStep(
      title: 'Create & Manage Projects',
      description:
          'Bring your ideas to life! Create projects, set goals, manage team members, and track progress.',
      icon: Icons.add_box,
      features: [
        'Create new projects',
        'Set project status and visibility',
        'Add descriptions and tags',
        'Set funding goals',
        'Manage team collaborators',
      ],
    ),
    OnboardingStep(
      title: 'Collaborate & Communicate',
      description:
          'Join projects, work with teams, and engage with the community through comments and discussions.',
      icon: Icons.groups,
      features: [
        'Request to join projects',
        'Comment on projects',
        'Vote on projects you like',
        'View team members and collaborators',
      ],
    ),
    OnboardingStep(
      title: 'Build Your Profile',
      description:
          'Create a professional academic profile showcasing your skills, projects, and interests.',
      icon: Icons.person,
      features: [
        'Add bio and description',
        'Select tags and interests',
        'Showcase your projects',
        'Connect with others',
      ],
    ),
    OnboardingStep(
      title: 'Get Funding Support',
      description:
          'Request funding for your projects and support others. Track funding goals and contributions.',
      icon: Icons.attach_money,
      features: [
        'Set project funding goals',
        'Submit funding requests',
        'Manage and approve requests',
        'Track funding progress',
      ],
    ),
    OnboardingStep(
      title: 'Stay Connected',
      description:
          'Receive notifications about collaboration requests, project updates, and community activity.',
      icon: Icons.notifications_active,
      features: [
        'Collaboration requests',
        'Project updates',
        'Funding notifications',
        'Community mentions',
      ],
    ),
  ];
}
