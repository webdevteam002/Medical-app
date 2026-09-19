import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class MsPrimaryButton extends StatefulWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final IconData? icon;
  final Gradient? gradient;
  final double? height;
  final Color? backgroundColor;

  const MsPrimaryButton({
    super.key,
    required this.label,
    this.onPressed,
    this.isLoading = false,
    this.icon,
    this.gradient,
    this.height,
    this.backgroundColor,
  });

  @override
  State<MsPrimaryButton> createState() => _MsPrimaryButtonState();
}

class _MsPrimaryButtonState extends State<MsPrimaryButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onPressed != null && !widget.isLoading;
    final borderRadius = BorderRadius.circular(AppTheme.borderRadiusSm);

    Widget childContent;
    if (widget.isLoading) {
      childContent = const SizedBox(
        width: 20,
        height: 20,
        child: CircularProgressIndicator(
          strokeWidth: 2.2,
          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
        ),
      );
    } else if (widget.icon == null) {
      childContent = Text(
        widget.label,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w700,
          fontSize: 15,
          letterSpacing: 0.2,
        ),
      );
    } else {
      childContent = Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(widget.icon, size: 19, color: Colors.white),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              widget.label,
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 15,
                letterSpacing: 0.2,
              ),
            ),
          ),
        ],
      );
    }

    // Modern gradient or solid fill
    final defaultGradient = widget.gradient ??
        (enabled ? AppTheme.primaryGradient : null);

    return MouseRegion(
      cursor: enabled ? SystemMouseCursors.click : SystemMouseCursors.basic,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        width: double.infinity,
        height: widget.height ?? AppTheme.buttonHeight,
        decoration: BoxDecoration(
          gradient: enabled ? defaultGradient : null,
          color: enabled
              ? (widget.backgroundColor ?? AppTheme.primaryColor)
              : AppTheme.primaryColor.withValues(alpha: 0.45),
          borderRadius: borderRadius,
          boxShadow: enabled && _isHovered
              ? AppTheme.glowShadow(AppTheme.primaryColor)
              : [
                  BoxShadow(
                    color: AppTheme.primaryColor.withValues(alpha: 0.16),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: widget.isLoading ? null : widget.onPressed,
            borderRadius: borderRadius,
            splashColor: Colors.white.withValues(alpha: 0.18),
            highlightColor: Colors.white.withValues(alpha: 0.08),
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppTheme.spacingLg,
                ),
                child: childContent,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class MsSecondaryButton extends StatefulWidget {
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final double? height;

  const MsSecondaryButton({
    super.key,
    required this.label,
    this.onPressed,
    this.icon,
    this.height,
  });

  @override
  State<MsSecondaryButton> createState() => _MsSecondaryButtonState();
}

class _MsSecondaryButtonState extends State<MsSecondaryButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onPressed != null;
    final borderRadius = BorderRadius.circular(AppTheme.borderRadiusSm);

    return MouseRegion(
      cursor: enabled ? SystemMouseCursors.click : SystemMouseCursors.basic,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        width: double.infinity,
        height: widget.height ?? AppTheme.buttonHeight,
        decoration: BoxDecoration(
          color: _isHovered && enabled
              ? AppTheme.primaryColor.withValues(alpha: 0.05)
              : AppTheme.surfaceColor,
          borderRadius: borderRadius,
          border: Border.all(
            color: _isHovered && enabled
                ? AppTheme.primaryColor
                : AppTheme.borderColor,
            width: 1.4,
          ),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: widget.onPressed,
            borderRadius: borderRadius,
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppTheme.spacingLg,
                ),
                child: widget.icon == null
                    ? Text(
                        widget.label,
                        style: const TextStyle(
                          color: AppTheme.primaryColor,
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                        ),
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            widget.icon,
                            size: 19,
                            color: AppTheme.primaryColor,
                          ),
                          const SizedBox(width: 8),
                          Flexible(
                            child: Text(
                              widget.label,
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                              style: const TextStyle(
                                color: AppTheme.primaryColor,
                                fontWeight: FontWeight.w700,
                                fontSize: 15,
                              ),
                            ),
                          ),
                        ],
                      ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
