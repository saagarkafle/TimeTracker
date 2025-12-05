import 'package:flutter/material.dart';

/// Primary colors for the app
class AppColors {
  // Primary brand colors
  static const Color primaryPurple = Color(0xFF667eea);
  static const Color primaryViolet = Color(0xFF764ba2);

  // Neutral colors - Light theme
  static const Color lightBg = Colors.white;
  static const Color lightSurface = Colors.white;

  // Neutral colors - Dark theme
  static Color darkBg = Colors.grey.shade900;
  static Color darkSurface = Colors.grey.shade800;

  // Status colors
  static const Color successGreen = Colors.greenAccent;
  static const Color warningAmber = Colors.amber;
  static const Color errorRed = Colors.red;

  // Semantic colors
  static const Color textPrimary = Colors.white;
  static const Color textSecondary = Colors.grey;

  // Gradient
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primaryPurple, primaryViolet],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Border colors with alpha values
  static Color getBorderColor(
    BuildContext context, {
    bool isHighlighted = false,
  }) {
    if (isHighlighted) {
      return primaryPurple.withValues(alpha: 0.8);
    }
    return Colors.grey.withValues(alpha: 0.3);
  }

  static Color getBackgroundColor(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark ? darkBg : lightBg;
  }

  static Color getSurfaceColor(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark ? darkSurface : lightSurface;
  }

  static Color getCardBackgroundColor(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark ? Colors.grey.shade800 : Colors.white;
  }

  static Color getExpansionTileBackgroundColor(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark ? Colors.grey.shade800 : Colors.grey.shade50;
  }

  // Icon colors
  static Color getIconColor({bool isActive = true}) {
    return isActive ? primaryPurple : Colors.grey;
  }

  static Color getIconBackgroundColor({bool isActive = true}) {
    return isActive
        ? primaryPurple.withValues(alpha: 0.15)
        : Colors.grey.withValues(alpha: 0.1);
  }

  // Hover and interactive states
  static Color getPressedColor() {
    return primaryPurple.withValues(alpha: 0.8);
  }

  static Color getDisabledColor() {
    return Colors.grey.withValues(alpha: 0.5);
  }

  // Text colors with theme support
  static Color getTextColor(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark ? Colors.white : Colors.black;
  }

  static Color getSecondaryTextColor(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark ? Colors.grey[400]! : Colors.grey[600]!;
  }
}

/// Color constants for specific components
class ComponentColors {
  // Payment status colors
  static const Color paidColor = Color(0xFF4CAF50);
  static const Color pendingColor = Color(0xFFFFC107);
  static const Color unpaidColor = Color(0xFFF44336);

  // Earnings page colors
  static const Color weeklyTotalBg = Color(0xFF667eea);
  static const Color weeklyTotalText = Colors.white;

  // Border colors
  static const Color borderColorLight = Color(0xFFE0E0E0);
  static Color borderColorDark = Colors.grey.shade700;

  // Shadow colors
  static Color shadowColor = Colors.black.withValues(alpha: 0.1);
}

/// Opacity/Alpha constants
class AppOpacity {
  static const double high = 1.0;
  static const double medium = 0.6;
  static const double disabled = 0.5;
  static const double hint = 0.3;
  static const double veryLight = 0.15;
  static const double ultraLight = 0.1;
}
