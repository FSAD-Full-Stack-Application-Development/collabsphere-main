import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';

class NavigationHelper {
  /// Navigate to a named route
  static void push(BuildContext context, String route) {
    if (kIsWeb) {
      context.push(route);
    } else {
      Get.toNamed(route);
    }
  }

  /// Navigate to a named route and replace current
  static void pushReplacement(BuildContext context, String route) {
    if (kIsWeb) {
      context.go(route);
    } else {
      Get.offNamed(route);
    }
  }

  /// Navigate to a named route and remove all previous routes
  static void pushAndRemoveUntil(BuildContext context, String route) {
    if (kIsWeb) {
      context.go(route);
    } else {
      Get.offAllNamed(route);
    }
  }

  /// Pop the current route
  static void pop(BuildContext context, [dynamic result]) {
    if (kIsWeb) {
      context.pop(result);
    } else {
      Get.back(result: result);
    }
  }

  /// Check if we can pop
  static bool canPop(BuildContext context) {
    if (kIsWeb) {
      return context.canPop();
    } else {
      return Get.key.currentState?.canPop() ?? false;
    }
  }
}
