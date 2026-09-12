import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'ms_gradient_header.dart';

/// Full-screen clinical auth layout: atmospheric canvas + centered portal card.
class MsAuthShell extends StatelessWidget {
  final String brandTitle;
  final String brandSubtitle;
  final String formTitle;
  final String formSubtitle;
  final Widget form;
  final Widget? footer;
  final List<String> trustLabels;

  const MsAuthShell({
    super.key,
    required this.brandTitle,
    required this.brandSubtitle,
    required this.formTitle,
    required this.formSubtitle,
    required this.form,
    this.footer,
    this.trustLabels = const ['MBBS Years 1–5', 'FCPS Prep', 'Secure session'],
  });

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).padding.bottom;
    final width = MediaQuery.of(context).size.width;
    final isWide = width >= 900;

    return Scaffold(
      body: Stack(
        children: [
          const Positioned.fill(child: _AuthAtmosphere()),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(
                  isWide ? 48 : AppTheme.spacingLg,
                  AppTheme.spacingLg,
                  isWide ? 48 : AppTheme.spacingLg,
                  AppTheme.spacingLg + bottomInset,
                ),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: isWide ? 980 : 460,
                  ),
                  child: isWide
                      ? _WideAuthLayout(
                          brandTitle: brandTitle,
                          brandSubtitle: brandSubtitle,
                          trustLabels: trustLabels,
                          formTitle: formTitle,
                          formSubtitle: formSubtitle,
                          form: form,
                          footer: footer,
                        )
                      : _CompactAuthLayout(
                          brandTitle: brandTitle,
                          brandSubtitle: brandSubtitle,
                          trustLabels: trustLabels,
                          formTitle: formTitle,
                          formSubtitle: formSubtitle,
                          form: form,
                          footer: footer,
                        ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AuthAtmosphere extends StatelessWidget {
  const _AuthAtmosphere();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF071E36),
            Color(0xFF0B3A66),
            Color(0xFF0C4A6E),
            Color(0xFF115E59),
          ],
          stops: [0.0, 0.35, 0.72, 1.0],
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            top: -80,
            right: -60,
            child: _GlowOrb(
              size: 280,
              color: const Color(0xFF38BDF8).withValues(alpha: 0.18),
            ),
          ),
          Positioned(
            bottom: -100,
            left: -70,
            child: _GlowOrb(
              size: 320,
              color: const Color(0xFF2DD4BF).withValues(alpha: 0.16),
            ),
          ),
          Positioned.fill(
            child: CustomPaint(painter: _SubtleGridPainter()),
          ),
        ],
      ),
    );
  }
}

class _GlowOrb extends StatelessWidget {
  final double size;
  final Color color;

  const _GlowOrb({required this.size, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [color, color.withValues(alpha: 0)],
        ),
      ),
    );
  }
}

class _SubtleGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.035)
      ..strokeWidth = 1;

    const step = 36.0;
    for (double x = 0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _WideAuthLayout extends StatelessWidget {
  final String brandTitle;
  final String brandSubtitle;
  final List<String> trustLabels;
  final String formTitle;
  final String formSubtitle;
  final Widget form;
  final Widget? footer;

  const _WideAuthLayout({
    required this.brandTitle,
    required this.brandSubtitle,
    required this.trustLabels,
    required this.formTitle,
    required this.formSubtitle,
    required this.form,
    this.footer,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          flex: 5,
          child: Padding(
            padding: const EdgeInsets.only(right: 40),
            child: _BrandPanel(
              title: brandTitle,
              subtitle: brandSubtitle,
              trustLabels: trustLabels,
              compact: false,
            ),
          ),
        ),
        Expanded(
          flex: 4,
          child: _AuthFormCard(
            title: formTitle,
            subtitle: formSubtitle,
            form: form,
            footer: footer,
          ),
        ),
      ],
    );
  }
}

class _CompactAuthLayout extends StatelessWidget {
  final String brandTitle;
  final String brandSubtitle;
  final List<String> trustLabels;
  final String formTitle;
  final String formSubtitle;
  final Widget form;
  final Widget? footer;

  const _CompactAuthLayout({
    required this.brandTitle,
    required this.brandSubtitle,
    required this.trustLabels,
    required this.formTitle,
    required this.formSubtitle,
    required this.form,
    this.footer,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _BrandPanel(
          title: brandTitle,
          subtitle: brandSubtitle,
          trustLabels: trustLabels,
          compact: true,
        ),
        const SizedBox(height: AppTheme.spacingLg),
        _AuthFormCard(
          title: formTitle,
          subtitle: formSubtitle,
          form: form,
          footer: footer,
        ),
      ],
    );
  }
}

class _BrandPanel extends StatelessWidget {
  final String title;
  final String subtitle;
  final List<String> trustLabels;
  final bool compact;

  const _BrandPanel({
    required this.title,
    required this.subtitle,
    required this.trustLabels,
    required this.compact,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment:
          compact ? CrossAxisAlignment.center : CrossAxisAlignment.start,
      children: [
        MsBrandMark(light: true, size: compact ? 58 : 72),
        SizedBox(height: compact ? AppTheme.spacingMd : AppTheme.spacingLg),
        Text(
          title,
          textAlign: compact ? TextAlign.center : TextAlign.start,
          style: TextStyle(
            fontSize: compact ? 34 : 44,
            fontWeight: FontWeight.w800,
            color: Colors.white,
            letterSpacing: -1.0,
            height: 1.1,
          ),
        ),
        const SizedBox(height: AppTheme.spacingSm),
        Text(
          subtitle,
          textAlign: compact ? TextAlign.center : TextAlign.start,
          style: TextStyle(
            fontSize: compact ? 15 : 17,
            color: const Color(0xFFC7D9EE),
            height: 1.45,
            fontWeight: FontWeight.w400,
          ),
        ),
        const SizedBox(height: AppTheme.spacingLg),
        Wrap(
          alignment: compact ? WrapAlignment.center : WrapAlignment.start,
          spacing: 8,
          runSpacing: 8,
          children: trustLabels
              .map(
                (label) => Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.18),
                    ),
                  ),
                  child: Text(
                    label,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.1,
                    ),
                  ),
                ),
              )
              .toList(),
        ),
      ],
    );
  }
}

class _AuthFormCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final Widget form;
  final Widget? footer;

  const _AuthFormCard({
    required this.title,
    required this.subtitle,
    required this.form,
    this.footer,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(28, 28, 28, 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.white.withValues(alpha: 0.65)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.22),
            blurRadius: 40,
            offset: const Offset(0, 18),
          ),
          BoxShadow(
            color: const Color(0xFF0B3A66).withValues(alpha: 0.18),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.3,
                ),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppTheme.textSecondaryColor,
                  height: 1.4,
                ),
          ),
          const SizedBox(height: 22),
          form,
          if (footer != null) ...[
            const SizedBox(height: 20),
            footer!,
          ],
        ],
      ),
    );
  }
}

class MsAuthErrorBanner extends StatelessWidget {
  final String message;

  const MsAuthErrorBanner({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.errorSoft,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppTheme.errorColor.withValues(alpha: 0.22),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: AppTheme.errorColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.error_outline_rounded,
              color: AppTheme.errorColor,
              size: 18,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: Color(0xFF991B1B),
                fontSize: 13,
                fontWeight: FontWeight.w600,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class MsAuthFooterLink extends StatelessWidget {
  final String prompt;
  final String actionLabel;
  final VoidCallback onTap;

  const MsAuthFooterLink({
    super.key,
    required this.prompt,
    required this.actionLabel,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      alignment: WrapAlignment.center,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Text(
          prompt,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        TextButton(
          onPressed: onTap,
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            minimumSize: Size.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          child: Text(
            actionLabel,
            style: const TextStyle(
              color: AppTheme.primaryColor,
              fontWeight: FontWeight.w800,
              fontSize: 14,
            ),
          ),
        ),
      ],
    );
  }
}
