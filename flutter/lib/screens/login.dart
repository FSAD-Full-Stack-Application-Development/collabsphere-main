// Removed unused imports
import 'package:collab_sphere/store/auth_controller.dart';
import 'package:get/get.dart';
import 'package:collab_sphere/widgets/gradient.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';

import '../widgets/alert_error.dart';
import '../theme.dart';
import '../utils/navigation_helper.dart';
import '../utils/responsive.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  String _email = '';
  String _password = '';

  @override
  void initState() {
    super.initState();
    // Clear any previous errors when entering login screen
    WidgetsBinding.instance.addPostFrameCallback((_) {
      authController.error = null;
      authController.update();
    });
  }

  Future<void> _submit(BuildContext context) async {
    if (!_formKey.currentState!.validate()) return;
    final success = await authController.login(_email, _password);
    if (success) {
      NavigationHelper.pushAndRemoveUntil(context, '/');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = Responsive.isMobile(context);
    final padding = Responsive.getValue(
      context,
      mobile: 32.0,
      tablet: 48.0,
      desktop: 64.0,
      largeDesktop: 80.0,
    );

    return GetBuilder<AuthController>(
      init: authController,
      builder:
          (auth) => Scaffold(
            body: Container(
              decoration: BoxDecoration(gradient: AppTheme.gradientSoft),
              child: Center(
                child: SingleChildScrollView(
                  padding: EdgeInsets.symmetric(horizontal: padding),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: Responsive.getValue(
                        context,
                        mobile: 480.0,
                        tablet: 520.0,
                        desktop: 580.0,
                        largeDesktop: 640.0,
                      ),
                    ),
                    child: _buildCard(
                      child: Form(
                        key: _formKey,
                        child: Column(
                          children: [
                            const GradientLogo(),
                            const SizedBox(height: 20),
                            const Text(
                              'Welcome Back',
                              style: TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.w700,
                                color: AppTheme.textDark,
                                letterSpacing: -0.02,
                              ),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Sign in to continue to CollabSphere',
                              style: TextStyle(
                                color: AppTheme.textLight,
                                fontSize: 15,
                              ),
                            ),
                            const SizedBox(height: 32),

                            // Error Alert
                            if (auth.error != null) ErrorAlert(auth.error!),
                            if (auth.error != null) const SizedBox(height: 24),

                            // Email Field
                            _field(
                              label: 'Email Address',
                              key: 'email',
                              required: true,
                              keyboard: TextInputType.emailAddress,
                              autofocus: true,
                              hint: 'you@example.com',
                            ),
                            const SizedBox(height: 24),

                            // Password Field
                            _field(
                              label: 'Password',
                              key: 'password',
                              required: true,
                              obscureText: true,
                              hint: 'Enter your password',
                            ),
                            const SizedBox(height: 24),

                            // Submit Button
                            GradientButton(
                              text: 'Sign In',
                              onPressed: () => _submit(context),
                              loading: auth.isLoading,
                            ),
                            const SizedBox(height: 32),

                            // Divider
                            const Divider(
                              color: AppTheme.borderColor,
                              height: 1,
                            ),
                            const SizedBox(height: 16),

                            // Footer Link
                            _footerLink(
                              text: "Don't have an account?",
                              link: 'Create one now',
                              route: '/register',
                              context: context,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
    );
  }

  // Reusable form field
  Widget _field({
    required String label,
    required String key,
    required bool required,
    TextInputType? keyboard,
    bool obscureText = false,
    bool autofocus = false,
    String? hint,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppTheme.textDark,
            letterSpacing: 0.01,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          autofocus: autofocus,
          keyboardType: keyboard,
          obscureText: obscureText,
          validator:
              required
                  ? (v) => v?.trim().isEmpty ?? true ? 'Required' : null
                  : null,
          onChanged: (v) {
            if (key == 'email') _email = v;
            if (key == 'password') _password = v;
          },
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: Color(0xFFA0AEC0), fontSize: 15),
          ),
        ),
      ],
    );
  }

  // Footer link with gold accent
  Widget _footerLink({
    required String text,
    required String link,
    required String route,
    required BuildContext context,
  }) {
    return RichText(
      textAlign: TextAlign.center,
      text: TextSpan(
        style: const TextStyle(color: AppTheme.textMedium, fontSize: 15),
        children: [
          TextSpan(text: '$text '),
          WidgetSpan(
            child: InkWell(
              onTap: () => NavigationHelper.pushReplacement(context, route),
              child: Text(
                link,
                style: const TextStyle(
                  color: AppTheme.accentGold,
                  fontWeight: FontWeight.w600,
                  decoration: TextDecoration.none,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Card with hover shadow & border
  Widget _buildCard({required Widget child}) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(40),
        decoration: BoxDecoration(
          color: AppTheme.bgWhite,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.borderColor),
          boxShadow: [AppTheme.shadowMd],
        ),
        child: child,
      ),
    );
  }
}
