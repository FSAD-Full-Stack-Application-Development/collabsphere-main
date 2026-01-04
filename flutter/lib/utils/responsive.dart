import 'package:flutter/material.dart';

enum GridType { cards, tiles, list }

class Responsive {
  // More granular breakpoints for better control
  static bool isExtraSmall(BuildContext context) =>
      MediaQuery.of(context).size.width < 360;

  static bool isSmall(BuildContext context) =>
      MediaQuery.of(context).size.width >= 360 &&
      MediaQuery.of(context).size.width < 480;

  static bool isMedium(BuildContext context) =>
      MediaQuery.of(context).size.width >= 480 &&
      MediaQuery.of(context).size.width < 650;

  static bool isLarge(BuildContext context) =>
      MediaQuery.of(context).size.width >= 650 &&
      MediaQuery.of(context).size.width < 900;

  static bool isExtraLarge(BuildContext context) =>
      MediaQuery.of(context).size.width >= 900 &&
      MediaQuery.of(context).size.width < 1200;

  static bool isUltraWide(BuildContext context) =>
      MediaQuery.of(context).size.width >= 1200;

  // Legacy methods for backward compatibility
  static bool isMobile(BuildContext context) =>
      MediaQuery.of(context).size.width < 650;

  static bool isTablet(BuildContext context) =>
      MediaQuery.of(context).size.width >= 650 &&
      MediaQuery.of(context).size.width < 1100;

  static bool isDesktop(BuildContext context) =>
      MediaQuery.of(context).size.width >= 1100;

  static bool isLargeDesktop(BuildContext context) =>
      MediaQuery.of(context).size.width >= 1400;

  static double getWidth(BuildContext context) =>
      MediaQuery.of(context).size.width;

  static double getHeight(BuildContext context) =>
      MediaQuery.of(context).size.height;

  /// Get responsive value based on screen size
  static T getValue<T>(
    BuildContext context, {
    required T mobile,
    T? tablet,
    T? desktop,
    T? largeDesktop,
  }) {
    if (isLargeDesktop(context) && largeDesktop != null) return largeDesktop;
    if (isDesktop(context) && desktop != null) return desktop;
    if (isTablet(context) && tablet != null) return tablet;
    return mobile;
  }

  // Backward compatibility method
  static T getValueLegacy<T>(
    BuildContext context, {
    required T mobile,
    T? tablet,
    T? desktop,
    T? largeDesktop,
  }) {
    if (isLargeDesktop(context) && largeDesktop != null) return largeDesktop;
    if (isDesktop(context) && desktop != null) return desktop;
    if (isTablet(context) && tablet != null) return tablet;
    return mobile;
  }

  /// Get max width for centered content on large screens
  static double getMaxWidth(BuildContext context) {
    final width = getWidth(context);
    if (width > 1600) return 1400;
    if (width > 1400) return 1200;
    if (width > 1100) return 1000;
    if (width > 650) return 800;
    return width * 0.95; // Leave some margin on very small screens
  }

  /// Get responsive padding
  static double getPadding(BuildContext context) {
    return getValue(
      context,
      mobile: 16,
      tablet: 24,
      desktop: 32,
      largeDesktop: 40,
    );
  }

  /// Get responsive horizontal padding
  static double getHorizontalPadding(BuildContext context) {
    return getValue(
      context,
      mobile: 16,
      tablet: 32,
      desktop: 48,
      largeDesktop: 64,
    );
  }

  /// Get responsive vertical padding
  static double getVerticalPadding(BuildContext context) {
    return getValue(
      context,
      mobile: 12,
      tablet: 20,
      desktop: 28,
      largeDesktop: 36,
    );
  }

  /// Get responsive grid columns (legacy method)
  static int getGridColumns(BuildContext context) {
    return getOptimalGridColumns(context, 100); // Assume many items
  }

  /// Get optimal grid columns based on screen size and item count
  static int getOptimalGridColumns(
    BuildContext context,
    int itemCount, {
    GridType type = GridType.cards,
    bool preferFewerColumns = false,
  }) {
    final width = getWidth(context);

    // Base column suggestions based on screen width
    int maxColumns;
    if (width < 650)
      maxColumns = 1; // mobile
    else if (width < 1100)
      maxColumns = 2; // tablet
    else if (width < 1400)
      maxColumns = 3; // desktop
    else
      maxColumns = 4; // largeDesktop

    // Adjust based on content type
    switch (type) {
      case GridType.tiles:
        maxColumns = (maxColumns * 1.5).round().clamp(2, 6);
        break;
      case GridType.list:
        return 1; // Lists are always single column
      case GridType.cards:
      default:
        // Keep as is for cards
        break;
    }

    // Adjust based on item count to avoid awkward layouts
    if (itemCount <= 1) return 1;
    if (itemCount == 2) return 2;
    if (itemCount == 3) return 3;
    if (itemCount == 4) return 2; // 2x2 grid looks better than 4x1
    if (itemCount == 5) return preferFewerColumns ? 3 : 5; // 3+2 or 5+0
    if (itemCount == 6) return 3; // Perfect 3x2 grid
    if (itemCount == 7) return 4; // 4+3 is better than 3+4
    if (itemCount == 8) return 4; // Perfect 4x2 grid
    if (itemCount == 9) return 3; // Perfect 3x3 grid

    // For larger counts, use the max columns but ensure good distribution
    return maxColumns.clamp(1, itemCount > 10 ? 5 : 4);
  }

  /// Get responsive grid columns for different content types (legacy method)
  static int getGridColumnsForType(BuildContext context, GridType type) {
    return getOptimalGridColumns(context, 100, type: type); // Assume many items
  }

  /// Get responsive spacing
  static double getSpacing(BuildContext context) {
    return getValue(
      context,
      mobile: 8,
      tablet: 12,
      desktop: 16,
      largeDesktop: 20,
    );
  }

  /// Get responsive border radius
  static double getBorderRadius(BuildContext context) {
    return getValue(
      context,
      mobile: 8,
      tablet: 10,
      desktop: 12,
      largeDesktop: 16,
    );
  }

  /// Get responsive icon size
  static double getIconSize(BuildContext context) {
    return getValue(
      context,
      mobile: 20,
      tablet: 24,
      desktop: 28,
      largeDesktop: 32,
    );
  }

  /// Get responsive button height
  static double getButtonHeight(BuildContext context) {
    return getValue(
      context,
      mobile: 48,
      tablet: 52,
      desktop: 56,
      largeDesktop: 60,
    );
  }

  /// Get responsive card elevation
  static double getCardElevation(BuildContext context) {
    return getValue(context, mobile: 2, tablet: 3, desktop: 4, largeDesktop: 6);
  }

  /// Get responsive text scale factor
  static double getTextScale(BuildContext context) {
    return getValue(
      context,
      mobile: 0.9,
      tablet: 1.0,
      desktop: 1.1,
      largeDesktop: 1.2,
    );
  }

  /// Get responsive aspect ratio for cards based on grid columns
  static double getCardAspectRatio(BuildContext context, {int? columns}) {
    final cols = columns ?? getGridColumns(context);

    // Adjust aspect ratio based on number of columns
    if (cols == 1) {
      // Single column - can be wider
      return getValue(
        context,
        mobile: 1.0,
        tablet: 0.9,
        desktop: 0.85,
        largeDesktop: 0.8,
      );
    } else if (cols == 2) {
      // Two columns - balanced aspect ratio
      return getValue(
        context,
        mobile: 0.8,
        tablet: 0.75,
        desktop: 0.7,
        largeDesktop: 0.65,
      );
    } else {
      // Multiple columns - more square/compact
      return getValue(
        context,
        mobile: 0.7,
        tablet: 0.65,
        desktop: 0.6,
        largeDesktop: 0.55,
      );
    }
  }

  /// Get responsive aspect ratio for cards (legacy method)
  static double getCardAspectRatioLegacy(BuildContext context) {
    return getCardAspectRatio(context);
  }

  /// Check if device has high pixel density
  static bool isHighDensity(BuildContext context) {
    return MediaQuery.of(context).devicePixelRatio > 2.5;
  }

  /// Get safe area aware padding
  static EdgeInsets getSafeAreaPadding(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final padding = getPadding(context);
    return EdgeInsets.only(
      left: padding + mediaQuery.padding.left,
      right: padding + mediaQuery.padding.right,
      top: padding + mediaQuery.padding.top,
      bottom: padding + mediaQuery.padding.bottom,
    );
  }
}

/// Responsive layout builder widget
class ResponsiveLayout extends StatelessWidget {
  final Widget mobile;
  final Widget? tablet;
  final Widget? desktop;

  const ResponsiveLayout({
    super.key,
    required this.mobile,
    this.tablet,
    this.desktop,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= 1100 && desktop != null) {
          return desktop!;
        } else if (constraints.maxWidth >= 650 && tablet != null) {
          return tablet!;
        } else {
          return mobile;
        }
      },
    );
  }
}

/// Centered container with max width for large screens
class ResponsiveContainer extends StatelessWidget {
  final Widget child;
  final double? maxWidth;
  final EdgeInsets? padding;

  const ResponsiveContainer({
    super.key,
    required this.child,
    this.maxWidth,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    final width = Responsive.getMaxWidth(context);
    final defaultPadding = Responsive.getPadding(context);

    return Center(
      child: Container(
        padding: padding ?? EdgeInsets.all(defaultPadding),
        child: child,
      ),
    );
  }
}
