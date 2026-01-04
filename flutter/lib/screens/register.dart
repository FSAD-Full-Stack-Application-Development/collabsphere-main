// lib/screens/register_screen.dart
import 'package:collab_sphere/widgets/gradient.dart';
import 'package:collab_sphere/store/auth_controller.dart';
import 'package:get/get.dart';
import 'package:flutter/material.dart';
import '../widgets/step_badge.dart';
import '../widgets/alert_error.dart';
import '../theme.dart';
import '../widgets/autocomplete_field.dart';
import '../static/countries.dart';
import 'dart:convert';
import '../api/suggestions.dart';
import '../utils/responsive.dart';
import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';
import '../utils/navigation_helper.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});
  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final Map<String, String> _data = {
    'full_name': '',
    'email': '',
    'password': '',
    'country': '',
    'bio': '',
  };

  @override
  void initState() {
    super.initState();
    // Clear any previous errors when entering register screen
    WidgetsBinding.instance.addPostFrameCallback((_) {
      authController.error = null;
      authController.update();
    });
  }

  Future<void> _submit(BuildContext context) async {
    if (!_formKey.currentState!.validate()) return;
    // Country validation: must be empty or in allCountries
    final country = _data['country']?.trim() ?? '';
    if (country.isNotEmpty && !allCountries.contains(country)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a valid country from the list.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    final success = await authController.register(_data);
    if (success) {
      await authController.fetchProfile();
      final user = authController.user;
      // If any optional fields are missing, go to complete profile, else go to home
      if (user != null &&
          ((user.university == null || user.university!.isEmpty) ||
              (user.department == null || user.department!.isEmpty) ||
              (user.tags.isEmpty))) {
        NavigationHelper.pushAndRemoveUntil(context, '/complete-profile');
      } else {
        NavigationHelper.pushAndRemoveUntil(context, '/');
      }
    } else {
      // Show error dialog/snackbar and reset loading state
      if (mounted) {
        final errorMsg =
            authController.error ?? 'Registration failed. Please try again.';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMsg), backgroundColor: Colors.red),
        );
        setState(() {}); // Force rebuild to update loading state
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // -------------------------------------------------
    // 1. Detect screen size – same breakpoints as CSS
    // -------------------------------------------------
    final isMobile = Responsive.isMobile(context);
    final isVerySmall =
        Responsive.getWidth(context) < 480; // ≤ 480 px → extra‑tight

    // -------------------------------------------------
    // 2. Responsive values (exact copy of CSS media)
    // -------------------------------------------------
    final double cardPadding = Responsive.getValue(
      context,
      mobile: 20.0,
      tablet: 30.0,
      desktop: 40.0,
      largeDesktop: 50.0,
    );
    final double maxCardWidth = Responsive.getValue(
      context,
      mobile: double.infinity,
      tablet: 600.0,
      desktop: 580.0,
      largeDesktop: 560.0,
    );
    final double logoSize = Responsive.getValue(
      context,
      mobile: 48.0,
      tablet: 56.0,
      desktop: 64.0,
      largeDesktop: 72.0,
    );
    final double titleSize = Responsive.getValue(
      context,
      mobile: 24.0,
      tablet: 28.0,
      desktop: 32.0,
      largeDesktop: 36.0,
    );
    final double fieldSpacing = Responsive.getValue(
      context,
      mobile: 16.0,
      tablet: 20.0,
      desktop: 24.0,
      largeDesktop: 28.0,
    );
    final double buttonTopMargin = Responsive.getValue(
      context,
      mobile: 8.0,
      tablet: 16.0,
      desktop: 24.0,
      largeDesktop: 32.0,
    );

    return GetBuilder<AuthController>(
      builder:
          (auth) => Scaffold(
            body: Container(
              decoration: BoxDecoration(gradient: AppTheme.gradientSoft),
              child: SafeArea(
                child: Center(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.symmetric(
                      horizontal: isVerySmall ? 12 : (isMobile ? 16 : 32),
                    ),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(maxWidth: maxCardWidth),
                      child: _buildCard(
                        padding: EdgeInsets.all(cardPadding),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            children: [
                              GradientLogo(size: logoSize),
                              SizedBox(height: isMobile ? 16 : 20),
                              Text(
                                'Create Your Account',
                                style: TextStyle(
                                  fontSize: titleSize,
                                  fontWeight: FontWeight.w700,
                                  color: AppTheme.textDark,
                                  letterSpacing: -0.02,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              SizedBox(height: isMobile ? 6 : 8),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const StepBadge('Step 1 of 2'),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Basic Information',
                                    style: TextStyle(
                                      color: AppTheme.textLight,
                                      fontSize: isMobile ? 14 : 15,
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: isMobile ? 24 : 32),
                              if (auth.error != null) ErrorAlert(auth.error!),
                              if (auth.error != null)
                                SizedBox(height: fieldSpacing),
                              _field(
                                'Full Name *',
                                'full_name',
                                required: true,
                                autofocus: true,
                                isMobile: isMobile,
                              ),
                              SizedBox(height: fieldSpacing),
                              _field(
                                'Email Address *',
                                'email',
                                required: true,
                                keyboard: TextInputType.emailAddress,
                                isMobile: isMobile,
                              ),
                              SizedBox(height: fieldSpacing),
                              _passwordField(isMobile: isMobile),
                              SizedBox(height: fieldSpacing),
                              AutocompleteField(
                                label: 'Country (Optional)',
                                initialValue: _data['country'] ?? '',
                                suggestions: allCountries,
                                suggestionsFetcher: (term) async {
                                  try {
                                    final resp = await suggestionsService
                                        .countries(term);
                                    if (resp.statusCode == 200 &&
                                        resp.body.isNotEmpty) {
                                      final decoded =
                                          jsonDecode(resp.body) as List;
                                      return decoded
                                          .map((e) => e.toString())
                                          .toList();
                                    }
                                  } catch (_) {}
                                  return allCountries
                                      .where(
                                        (c) => c.toLowerCase().contains(
                                          term.toLowerCase(),
                                        ),
                                      )
                                      .toList();
                                },
                                onChanged:
                                    (v) => setState(() => _data['country'] = v),
                                forceSelect: true,
                              ),
                              SizedBox(height: fieldSpacing),
                              // University and Department are collected in Complete Profile
                              // Removed from register to keep registration single-step + onboarding
                              SizedBox(height: fieldSpacing),
                              _textarea(
                                'Short Bio (Optional)',
                                'bio',
                                isMobile: isMobile,
                              ),
                              SizedBox(height: buttonTopMargin),
                              GradientButton(
                                text: 'Create account',
                                onPressed: () => _submit(context),
                                loading: auth.isLoading,
                                fullWidth: true,
                              ),
                              SizedBox(height: isMobile ? 24 : 32),
                              const Divider(
                                color: AppTheme.borderColor,
                                height: 1,
                              ),
                              SizedBox(height: isMobile ? 12 : 16),
                              _footerLink(
                                'Already have an account?',
                                'Sign in instead',
                                '/login',
                                isMobile: isMobile,
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
          ),
    );
  }

  // -----------------------------------------------------------------
  // Re‑usable field (label + TextFormField)
  // -----------------------------------------------------------------
  Widget _field(
    String label,
    String key, {
    bool required = false,
    TextInputType? keyboard,
    bool autofocus = false,
    bool isMobile = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
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
          validator:
              required
                  ? (v) => v?.trim().isEmpty ?? true ? 'Required' : null
                  : null,
          onChanged: (v) => _data[key] = v,
          style: const TextStyle(fontSize: 15),
          decoration: InputDecoration(
            hintText: _hint(key),
            hintStyle: const TextStyle(color: Color(0xFFA0AEC0)),
          ),
        ),
      ],
    );
  }

  // -----------------------------------------------------------------
  // Password field + helper text
  // -----------------------------------------------------------------
  Widget _passwordField({required bool isMobile}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Password *',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppTheme.textDark,
            letterSpacing: 0.01,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          obscureText: true,
          validator:
              (v) => (v?.length ?? 0) < 6 ? 'Minimum 6 characters' : null,
          onChanged: (v) => _data['password'] = v,
          style: const TextStyle(fontSize: 15),
          decoration: const InputDecoration(
            hintText: 'Minimum 6 characters',
            hintStyle: TextStyle(color: Color(0xFFA0AEC0)),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Use at least 6 characters with a mix of letters and numbers',
          style: TextStyle(
            color: AppTheme.textLight,
            fontSize: isMobile ? 12 : 13,
          ),
        ),
      ],
    );
  }

  // -----------------------------------------------------------------
  // Textarea (bio)
  // -----------------------------------------------------------------
  Widget _textarea(String label, String key, {required bool isMobile}) {
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
          maxLines: 4,
          onChanged: (v) => _data[key] = v,
          style: const TextStyle(fontSize: 15),
          decoration: const InputDecoration(
            hintText: 'Tell us a bit about yourself and your interests...',
            alignLabelWithHint: true,
            hintStyle: TextStyle(color: Color(0xFFA0AEC0)),
          ),
        ),
      ],
    );
  }

  // -----------------------------------------------------------------
  // Footer link (gold accent)
  // -----------------------------------------------------------------
  Widget _footerLink(
    String text,
    String link,
    String route, {
    required bool isMobile,
    required BuildContext context,
  }) {
    return RichText(
      textAlign: TextAlign.center,
      text: TextSpan(
        style: TextStyle(
          color: AppTheme.textMedium,
          fontSize: isMobile ? 14 : 15,
        ),
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

  // -----------------------------------------------------------------
  // Card with hover‑shadow (desktop) – no hover on mobile
  // -----------------------------------------------------------------
  Widget _buildCard({
    required EdgeInsetsGeometry padding,
    required Widget child,
  }) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: padding,
      decoration: BoxDecoration(
        color: AppTheme.bgWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderColor),
        boxShadow: const [AppTheme.shadowMd],
      ),
      child: child,
    );
  }

  // -----------------------------------------------------------------
  // Hint text per field
  // -----------------------------------------------------------------
  String _hint(String key) {
    switch (key) {
      case 'full_name':
        return 'John Doe';
      case 'email':
        return 'you@example.com';
      case 'country':
        return 'e.g., Malaysia, Singapore';
      default:
        return '';
    }
  }
}
