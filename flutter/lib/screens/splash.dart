// lib/screens/splash_screen.dart
import 'dart:convert';
import 'dart:developer';

import 'package:collab_sphere/api/auth.dart';
import 'package:collab_sphere/api/project.dart';
import 'package:collab_sphere/models/project.dart';
import 'package:collab_sphere/models/user.dart';
import 'package:collab_sphere/screens/home.dart';
import 'package:collab_sphere/screens/login.dart';
import 'package:collab_sphere/screens/onboarding_screen.dart';
import 'package:collab_sphere/store/project_controller.dart';
import 'package:collab_sphere/store/token.dart';
import 'package:get/get.dart';
import 'package:collab_sphere/store/auth_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scaleAnimation;
  late final Animation<double> _fadeAnimation;

  bool _shouldNavigate = false;
  String? _navigateTo;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );

    _scaleAnimation = Tween<double>(
      begin: 0.5,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.elasticOut));

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0.4, 1.0)),
    );

    // start animation and the startup sequence (async)
    final animationFuture = _controller.forward();
    _startSequence(animationFuture);
  }

  Future<void> _startSequence(Future<void> animationFuture) async {
    // wait for both animation AND the API fetches to finish before navigating
    await Future.wait([animationFuture, _fetchAll()]);
    await _handleNavigation();
  }

  Future<void> _fetchAll() async {
    // run the three fetches concurrently and wait for all to finish
    await Future.wait([
      _fetchSchoolsAndDepartments(),
      _fetchProjects(),
      _fetchTopProjects(),
    ]);
  }

  Future<void> _fetchSchoolsAndDepartments() async {
    try {
      final resp = await projectService.getUniversityDepartments();
      if (resp.statusCode == 200) {
        final raw = jsonDecode(resp.body) as Map<String, dynamic>;
        final data = <String, Map<String, List<String>>>{};
        raw.forEach((country, schools) {
          data[country] = {};
          (schools as Map<String, dynamic>).forEach((school, depts) {
            data[country]![school] = List<String>.from(depts as List);
          });
        });
        if (!mounted) return;
        log("data::: $data");
        projectController.countrySchoolDepartments = data;
        projectController.forceUpdate();
      } else {
        log(
          'getUniversityDepartments failed',
          error: 'status=${resp.statusCode}',
          stackTrace: StackTrace.fromString(resp.body),
        );
      }
    } catch (e, st) {
      log('Error fetching schools & departments', error: e, stackTrace: st);
    }
  }

  Future<void> _fetchProjects() async {
    try {
      final resp = await projectService.getProjects(perPage: 50);
      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body);
        final newProjects =
            (data['data'] as List?)?.map((e) => Project.fromJson(e)).toList() ??
            [];
        if (!mounted) return;
        projectController.projects = newProjects;
        projectController.forceUpdate();
      } else {
        log(
          'getProjects failed',
          error: 'status=${resp.statusCode}',
          stackTrace: StackTrace.fromString(resp.body),
        );
      }
    } catch (e, st) {
      log('Error fetching projects', error: e, stackTrace: st);
    }
  }

  Future<void> _fetchTopProjects() async {
    try {
      final resp = await projectService.getTopProjects();
      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body);
        final newTopProjects =
            (data['data'] as List?)?.map((e) => Project.fromJson(e)).toList() ??
            [];
        if (!mounted) return;
        projectController.topProjects = newTopProjects;
        projectController.forceUpdate();
      } else {
        log(
          'getTopProjects failed',
          error: 'status=${resp.statusCode}',
          stackTrace: StackTrace.fromString(resp.body),
        );
      }
    } catch (e, st) {
      log('Error fetching top projects', error: e, stackTrace: st);
    }
  }

  Future<void> _handleNavigation() async {
    // Check if user has completed onboarding
    final prefs = await SharedPreferences.getInstance();
    final onboardingComplete = prefs.getBool('onboarding_complete') ?? false;

    String? token = await tokenStore.getToken();
    if (token != null) {
      try {
        http.Response res = await authService.getProfile();
        if (res.statusCode != 200) {
          log(
            'getProfile returned non-200',
            error: 'status=${res.statusCode}',
            stackTrace: StackTrace.fromString(res.body),
          );
          await tokenStore.deleteToken();
          token = null;
        } else {
          User user = User.fromJson(jsonDecode(res.body));
          authController.user = user;
          authController.token = token;
          authController.update();
        }
      } catch (e, st) {
        log(
          'Error fetching profile in splash navigation',
          error: e,
          stackTrace: st,
        );
        // ensure token is cleared on unexpected errors
        await tokenStore.deleteToken();
        token = null;
      }
    }

    // Show onboarding for first-time users without a token
    if (!onboardingComplete && token == null) {
      setState(() {
        _shouldNavigate = true;
        _navigateTo = '/onboarding';
      });
    } else {
      setState(() {
        _shouldNavigate = true;
        _navigateTo = token == null ? '/login' : '/home';
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_shouldNavigate && _navigateTo != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (kIsWeb) {
          if (_navigateTo == '/onboarding') {
            // For web, redirect to login after showing message
            GoRouter.of(context).go('/login');
          } else {
            GoRouter.of(context).go(_navigateTo!);
          }
        } else {
          if (_navigateTo == '/onboarding') {
            Get.offAll(
              () => OnboardingScreen(
                onComplete: () {
                  Get.offAll(() => const LoginScreen());
                },
              ),
            );
          } else if (_navigateTo == '/login') {
            Get.offAll(() => const LoginScreen());
          } else {
            Get.offAll(() => const MainScreen());
          }
        }
      });
    }
    return Scaffold(
      backgroundColor: AppTheme.bgLight,
      body: Container(
        decoration: BoxDecoration(gradient: AppTheme.gradientMain),
        child: Center(
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return Transform.scale(
                scale: _scaleAnimation.value,
                child: Opacity(
                  opacity: _fadeAnimation.value,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Logo Circle
                      Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withAlpha(
                                (0.1 * 255).round(),
                              ),
                              blurRadius: 20,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: Center(
                          child: Text(
                            'CS',
                            style: TextStyle(
                              fontSize: 48,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.accentGold,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),

                      // App Name
                      Text(
                        'CollabSphere',
                        style: TextStyle(
                          fontSize: 36,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          letterSpacing: 1.2,
                          shadows: [
                            Shadow(
                              color: Colors.black.withAlpha(
                                (0.3 * 255).round(),
                              ),
                              offset: const Offset(0, 2),
                              blurRadius: 6,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Connect. Collaborate. Create.',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.white.withAlpha((0.9 * 255).round()),
                          letterSpacing: 0.8,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
