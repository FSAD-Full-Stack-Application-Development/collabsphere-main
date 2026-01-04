import 'package:flutter/material.dart';
import '../theme.dart';
import 'onboarding_screen.dart';
import 'package:get/get.dart';

class HelpScreen extends StatelessWidget {
  const HelpScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Help & Guide',
          style: TextStyle(color: AppTheme.textDark),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppTheme.textDark),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(gradient: AppTheme.gradientSoft),
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              // Tour button
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: InkWell(
                  onTap: () {
                    Get.to(
                      () => OnboardingScreen(
                        onComplete: () {
                          Get.back();
                        },
                      ),
                    );
                  },
                  borderRadius: BorderRadius.circular(16),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            gradient: AppTheme.gradientMain,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.tour,
                            color: Colors.white,
                            size: 28,
                          ),
                        ),
                        const SizedBox(width: 16),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Take the Tour',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.textDark,
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                'Learn about all features',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: AppTheme.textLight,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Icon(
                          Icons.arrow_forward_ios,
                          color: AppTheme.textLight,
                          size: 20,
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // FAQ Section
              const Text(
                'Frequently Asked Questions',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textDark,
                ),
              ),

              const SizedBox(height: 16),

              _buildFAQItem(
                'How do I create a project?',
                'Tap the "+" button at the bottom of the home screen. Fill in the project details including title, description, tags, and funding goals. Choose your project status and visibility settings.',
              ),

              _buildFAQItem(
                'How can I join a project?',
                'Open any project detail page and look for the "Request to Join" button. The project owner will receive your request and can accept or decline it.',
              ),

              _buildFAQItem(
                'What are tags and how do I use them?',
                'Tags are keywords that categorize your interests and projects. Add tags to your profile to help others find you, and use them when creating projects to make them discoverable.',
              ),

              _buildFAQItem(
                'How does project funding work?',
                'Project owners can set funding goals and enable funding display. Interested supporters can submit funding requests which the owner can approve or reject.',
              ),

              _buildFAQItem(
                'How do I edit my profile?',
                'Go to your profile tab (bottom right), then tap the "Edit Profile" button. You can update your bio, tags, country, university, and department.',
              ),

              _buildFAQItem(
                'What is the difference between Public and Private projects?',
                'Public projects are visible to everyone on the platform. Private projects are only visible to you and your team members.',
              ),

              _buildFAQItem(
                'How do I search for projects?',
                'Use the search bar at the top of the home screen. You can search by keywords, filter by tags, or browse the Top Projects section.',
              ),

              _buildFAQItem(
                'Can I edit or delete my projects?',
                'Yes! Go to the project detail page of your own project, tap the menu icon (three dots), and choose "Edit Project" or "Delete Project".',
              ),

              _buildFAQItem(
                'How do notifications work?',
                'You\'ll receive notifications for collaboration requests, project updates, funding requests, and other important activities. Check the notifications tab to stay updated.',
              ),

              _buildFAQItem(
                'How do I upvote/downvote projects?',
                'Open any project detail page and use the up/down arrow buttons to vote. Your vote helps highlight quality projects in the community.',
              ),

              const SizedBox(height: 24),

              // Quick Tips
              const Text(
                'Quick Tips',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textDark,
                ),
              ),

              const SizedBox(height: 16),

              _buildTipCard(
                Icons.lightbulb_outline,
                'Complete Your Profile',
                'Add a detailed bio and select relevant tags to help others discover and connect with you.',
              ),

              _buildTipCard(
                Icons.workspace_premium,
                'Engage with Projects',
                'Vote and comment on projects to build your reputation in the community.',
              ),

              _buildTipCard(
                Icons.people_outline,
                'Build Your Network',
                'Connect with students from different universities and departments to expand your collaboration opportunities.',
              ),

              _buildTipCard(
                Icons.refresh,
                'Keep Projects Updated',
                'Regularly update your project status and description to keep your team and followers informed.',
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFAQItem(String question, String answer) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Theme(
        data: ThemeData(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          title: Text(
            question,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppTheme.textDark,
            ),
          ),
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Text(
                answer,
                style: const TextStyle(
                  fontSize: 14,
                  color: AppTheme.textLight,
                  height: 1.5,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTipCard(IconData icon, String title, String description) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.accentGold.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: AppTheme.accentGold, size: 24),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textDark,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppTheme.textLight,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
