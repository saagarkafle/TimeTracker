import 'package:flutter/material.dart';

import '../utils/app_colors.dart';

/// A reusable card widget for displaying information with a border and background
class AppCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets padding;
  final bool isHighlighted;
  final double borderRadius;
  final VoidCallback? onTap;

  const AppCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(12),
    this.isHighlighted = false,
    this.borderRadius = 12,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final borderColor = isHighlighted
        ? AppColors.primaryPurple.withValues(alpha: 0.8)
        : AppColors.getBorderColor(context);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: padding,
        decoration: BoxDecoration(
          color: isDark ? Colors.grey.shade800 : Colors.white,
          borderRadius: BorderRadius.circular(borderRadius),
          border: Border.all(
            color: borderColor,
            width: isHighlighted ? 2 : 1.5,
          ),
        ),
        child: child,
      ),
    );
  }
}

/// A reusable week card widget with gradient background for headers
class GradientCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets padding;
  final double borderRadius;

  const GradientCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(12),
    this.borderRadius = 12,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(borderRadius),
      ),
      child: child,
    );
  }
}

/// A reusable container card for the outer week container
class OuterCard extends StatelessWidget {
  final Widget child;
  final bool isCurrentWeek;
  final EdgeInsets margin;
  final double borderRadius;

  const OuterCard({
    super.key,
    required this.child,
    this.isCurrentWeek = false,
    this.margin = const EdgeInsets.only(bottom: 12),
    this.borderRadius = 16,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final borderColor = isCurrentWeek
        ? AppColors.primaryPurple
        : AppColors.getBorderColor(context);

    return Container(
      margin: margin,
      decoration: BoxDecoration(
        color: isDark ? Colors.grey.shade900 : Colors.white,
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(color: borderColor, width: isCurrentWeek ? 2 : 1.5),
      ),
      child: child,
    );
  }
}

/// A reusable icon container widget
class IconContainer extends StatelessWidget {
  final IconData icon;
  final bool isActive;
  final double size;
  final double iconSize;

  const IconContainer({
    super.key,
    required this.icon,
    this.isActive = true,
    this.size = 40,
    this.iconSize = 20,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all((size - iconSize) / 2),
      decoration: BoxDecoration(
        color: isActive
            ? AppColors.primaryPurple.withValues(alpha: 0.15)
            : Colors.grey.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(
        icon,
        color: isActive ? AppColors.primaryPurple : Colors.grey,
        size: iconSize,
      ),
    );
  }
}

/// A reusable status badge widget
class StatusBadge extends StatelessWidget {
  final String label;
  final Color backgroundColor;
  final Color textColor;
  final double fontSize;

  const StatusBadge({
    super.key,
    required this.label,
    this.backgroundColor = const Color(0xFF667eea),
    this.textColor = Colors.white,
    this.fontSize = 12,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: backgroundColor.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: fontSize,
          fontWeight: FontWeight.bold,
          color: backgroundColor,
        ),
      ),
    );
  }
}
