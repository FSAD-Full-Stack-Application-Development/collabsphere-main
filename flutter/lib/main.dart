import 'package:collab_sphere/screens/edit_profile.dart';
import 'package:collab_sphere/screens/home.dart';
import 'package:collab_sphere/screens/login.dart';
import 'package:collab_sphere/screens/register.dart';
import 'package:collab_sphere/screens/complete_profile.dart';
import 'package:collab_sphere/screens/splash.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:get/get.dart';
import 'package:back_button_interceptor/back_button_interceptor.dart';
import 'package:url_strategy/url_strategy.dart';
import 'package:go_router/go_router.dart';
import '../theme.dart';
import 'package:collab_sphere/store/auth_controller.dart';

Future<bool> myInterceptor(bool stopDefaultButtonEvent, RouteInfo info) async {
  // Get the current context
  final context = Get.context;
  if (context != null) {
    // Check if we can pop the current route
    final navigator = Navigator.of(context);
    if (navigator.canPop()) {
      // There's a route to go back to, allow normal back navigation
      navigator.pop();
      return true; // Prevent default (we handled it)
    }

    // We're at the root, show exit confirmation
    final shouldExit = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Exit App'),
            content: const Text('Do you want to exit the app?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('No'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Yes'),
              ),
            ],
          ),
    );

    // If user wants to exit, allow default (exit app)
    // Otherwise prevent exit
    return shouldExit != true;
  }

  return true; // Prevent default if no context
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  setPathUrlStrategy(); // Enable path-based routing for web
  Get.put(AuthController()); // Initialize auth controller for both platforms
  if (!kIsWeb) {
    BackButtonInterceptor.add(myInterceptor);
  }
  runApp(const CollabSphereApp());
}

// GoRouter configuration for web
final GoRouter _router = GoRouter(
  routes: [
    GoRoute(path: '/', builder: (context, state) => const SplashScreen()),
    GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
    GoRoute(
      path: '/register',
      builder: (context, state) => const RegisterScreen(),
    ),
    GoRoute(
      path: '/complete-profile',
      builder: (context, state) => const CompleteProfileScreen(),
    ),
    GoRoute(
      path: '/edit-profile',
      builder: (context, state) => const EditProfileScreen(),
    ),
    GoRoute(
      path: '/home',
      builder: (context, state) => const MainScreen(initialIndex: 0),
    ),
    GoRoute(
      path: '/notifications',
      builder: (context, state) => const MainScreen(initialIndex: 1),
    ),
    GoRoute(
      path: '/top',
      builder: (context, state) => const MainScreen(initialIndex: 2),
    ),
    GoRoute(
      path: '/profile',
      builder: (context, state) => const MainScreen(initialIndex: 3),
    ),
  ],
);

class CollabSphereApp extends StatelessWidget {
  const CollabSphereApp({super.key});

  @override
  Widget build(BuildContext context) {
    if (kIsWeb) {
      return MaterialApp.router(
        title: 'CollabSphere',
        debugShowCheckedModeBanner: false,
        theme: _buildTheme(),
        routerConfig: _router,
      );
    } else {
      return GetMaterialApp(
        title: 'CollabSphere',
        debugShowCheckedModeBanner: false,
        theme: _buildTheme(),
        initialRoute: '/',
        getPages: [
          GetPage(name: '/', page: () => const SplashScreen()),
          GetPage(name: '/home', page: () => const MainScreen()),
          GetPage(name: '/register', page: () => const RegisterScreen()),
          GetPage(name: '/login', page: () => const LoginScreen()),
          GetPage(name: '/edit-profile', page: () => const EditProfileScreen()),
          GetPage(
            name: '/complete-profile',
            page: () => const CompleteProfileScreen(),
          ),
        ],
      );
    }
  }

  ThemeData _buildTheme() {
    return ThemeData(
      useMaterial3: true,
      fontFamily: GoogleFonts.inter().fontFamily,
      scaffoldBackgroundColor: AppTheme.bgLight,
      textTheme: GoogleFonts.interTextTheme().apply(
        bodyColor: AppTheme.textDark,
        displayColor: AppTheme.textDark,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppTheme.bgWhite,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        border: _inputBorder(),
        enabledBorder: _inputBorder(),
        focusedBorder: _inputBorder(color: AppTheme.accentGold, width: 2),
        errorBorder: _inputBorder(color: const Color(0xFFEF4444)),
        focusedErrorBorder: _inputBorder(
          color: const Color(0xFFEF4444),
          width: 2,
        ),
        hintStyle: const TextStyle(color: Color(0xFFA0AEC0), fontSize: 15),
      ),
    );
  }

  OutlineInputBorder _inputBorder({Color? color, double width = 2}) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: BorderSide(
        color: color ?? AppTheme.borderColor,
        width: width,
      ),
    );
  }
}
