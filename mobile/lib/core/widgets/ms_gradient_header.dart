import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Soft clinical wash used behind auth heroes and home intros.
class MsGradientHeader extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final double minHeight;

  const MsGradientHeader({
    super.key,
    required this.child,
    this.padding,
    this.minHeight = 0,
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
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF0B3A66),
            Color(0xFF145A96),
            Color(0xFF0F766E),
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
        color: light
            ? Colors.white.withValues(alpha: 0.16)
            : AppTheme.primaryColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(size * 0.28),
        border: Border.all(
          color: light
              ? Colors.white.withValues(alpha: 0.28)
              : AppTheme.primaryColor.withValues(alpha: 0.18),
        ),
      ),
      child: Icon(
        Icons.local_hospital_rounded,
        size: size * 0.48,
        color: light ? Colors.white : AppTheme.primaryColor,
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
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: background ?? AppTheme.surfaceMuted,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: fg),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: fg,
            ),
          ),
        ],
      ),
    );
  }
}
