import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Soft clinical wash used behind auth heroes and home intros.
class MsGradientHeader extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final double minHeight;
  final Gradient? gradient;

  const MsGradientHeader({
    super.key,
    required this.child,
    this.padding,
    this.minHeight = 0,
    this.gradient,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      constraints: BoxConstraints(minHeight: minHeight),
      padding: padding ??
          const EdgeInsets.fromLTRB(
            AppTheme.spacingLg,
            AppTheme.spacingXl,
            AppTheme.spacingLg,
            AppTheme.spacingLg,
          ),
      decoration: BoxDecoration(
        gradient: gradient ??
            const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF072545),
                Color(0xFF0B3A66),
                Color(0xFF0D9488),
              ],
              stops: [0.0, 0.55, 1.0],
            ),
      ),
      child: child,
    );
  }
}

class MsBrandMark extends StatelessWidget {
  final double size;
  final bool light;

  const MsBrandMark({
    super.key,
    this.size = 56,
    this.light = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: light
            ? LinearGradient(
                colors: [
                  Colors.white.withValues(alpha: 0.22),
                  Colors.white.withValues(alpha: 0.10),
                ],
              )
            : LinearGradient(
                colors: [
                  AppTheme.primaryColor.withValues(alpha: 0.14),
                  AppTheme.secondaryColor.withValues(alpha: 0.10),
                ],
              ),
        borderRadius: BorderRadius.circular(size * 0.28),
        border: Border.all(
          color: light
              ? Colors.white.withValues(alpha: 0.35)
              : AppTheme.primaryColor.withValues(alpha: 0.20),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: (light ? Colors.black : AppTheme.primaryColor)
                .withValues(alpha: 0.08),
            blurRadius: size * 0.25,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Center(
        child: Icon(
          Icons.local_hospital_rounded,
          size: size * 0.52,
          color: light ? Colors.white : AppTheme.primaryColor,
        ),
      ),
    );
  }
}

class MsMetaChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color? color;
  final Color? background;

  const MsMetaChip({
    super.key,
    required this.icon,
    required this.label,
    this.color,
    this.background,
  });

  @override
  Widget build(BuildContext context) {
    final fg = color ?? AppTheme.primaryColor;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 5),
      decoration: BoxDecoration(
        color: background ?? AppTheme.surfaceMuted,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: (color ?? AppTheme.borderColor).withValues(alpha: 0.25),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: fg),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: fg,
              letterSpacing: 0.1,
            ),
          ),
        ],
      ),
    );
  }
}
