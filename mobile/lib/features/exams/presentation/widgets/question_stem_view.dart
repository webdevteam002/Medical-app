import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import '../../../../core/theme/app_theme.dart';

/// Renders MCQ stem HTML (including signed <img> URLs from the API).
class QuestionStemView extends StatelessWidget {
  final String stem;
  final String? imageUrl;

  const QuestionStemView({
    super.key,
    required this.stem,
    this.imageUrl,
  });

  bool get _looksLikeHtml =>
      stem.contains('<') && (stem.contains('</') || stem.contains('/>'));

  @override
  Widget build(BuildContext context) {
    final titleStyle = Theme.of(context).textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.bold,
          color: AppTheme.textPrimaryColor,
          height: 1.4,
        );

    if (!_looksLikeHtml && (imageUrl == null || imageUrl!.isEmpty)) {
      return Text(stem, style: titleStyle);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (imageUrl != null &&
            imageUrl!.isNotEmpty &&
            !stem.toLowerCase().contains('<img'))
          Padding(
            padding: const EdgeInsets.only(bottom: AppTheme.spacingMd),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                imageUrl!,
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                loadingBuilder: (context, child, progress) {
                  if (progress == null) return child;
                  return const SizedBox(
                    height: 160,
                    child: Center(child: CircularProgressIndicator()),
                  );
                },
              ),
            ),
          ),
        if (_looksLikeHtml)
          Html(
            data: stem,
            style: {
              'body': Style(
                margin: Margins.zero,
                padding: HtmlPaddings.zero,
                fontSize: FontSize(titleStyle?.fontSize ?? 18),
                fontWeight: titleStyle?.fontWeight,
                color: AppTheme.textPrimaryColor,
                lineHeight: LineHeight.number(1.4),
              ),
              'p': Style(margin: Margins.only(bottom: 8)),
              'img': Style(
                width: Width(100, Unit.percent),
                margin: Margins.symmetric(vertical: 8),
              ),
            },
          )
        else
          Text(stem, style: titleStyle),
      ],
    );
  }
}
