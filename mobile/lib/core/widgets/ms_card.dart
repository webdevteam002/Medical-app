import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class MsCard extends StatefulWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final VoidCallback? onTap;
  final Color? color;
  final bool elevated;
  final BorderRadius? borderRadius;
  final Border? border;
  final Gradient? gradient;

  const MsCard({
    super.key,
    required this.child,
    this.padding,
    this.onTap,
    this.color,
    this.elevated = true,
    this.borderRadius,
    this.border,
    this.gradient,
  });

  @override
  State<MsCard> createState() => _MsCardState();
}

class _MsCardState extends State<MsCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final radius =
        widget.borderRadius ?? BorderRadius.circular(AppTheme.borderRadiusMd);

    final isInteractive = widget.onTap != null;

    final defaultBorder = Border.all(
      color: _isHovered && isInteractive
          ? AppTheme.secondaryColor.withValues(alpha: 0.55)
          : AppTheme.borderColor,
      width: _isHovered && isInteractive ? 1.2 : 1.0,
    );

    final shadows = widget.elevated
        ? (_isHovered && isInteractive
            ? AppTheme.cardHoverShadow
            : AppTheme.softShadow)
        : null;

    final content = AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOutCubic,
      width: double.infinity,
      padding: widget.padding ?? const EdgeInsets.all(AppTheme.spacingMd),
      decoration: BoxDecoration(
        color: widget.gradient == null
            ? (widget.color ?? AppTheme.surfaceColor)
            : null,
        gradient: widget.gradient,
        borderRadius: radius,
        border: widget.border ?? defaultBorder,
        boxShadow: shadows,
      ),
      child: widget.child,
    );

    if (!isInteractive) return content;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: widget.onTap,
          borderRadius: radius,
          hoverColor: AppTheme.primaryColor.withValues(alpha: 0.04),
          focusColor: AppTheme.primaryColor.withValues(alpha: 0.08),
          splashColor: AppTheme.primaryColor.withValues(alpha: 0.08),
          child: content,
        ),
      ),
    );
  }
}
