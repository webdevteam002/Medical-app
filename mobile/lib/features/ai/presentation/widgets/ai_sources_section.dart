import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../data/models/ai_citation.dart';

/// Compact Sources list for RAG-backed AI answers.
/// Informational only — does not open files or bypass material access.
class AiSourcesSection extends StatelessWidget {
  final List<AiCitation> citations;
  final String? grounding;
  final bool compact;

  const AiSourcesSection({
    super.key,
    required this.citations,
    this.grounding,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    if (citations.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Sources',
          style: TextStyle(
            fontSize: compact ? 12 : 13,
            fontWeight: FontWeight.w700,
            color: AppTheme.textPrimaryColor,
          ),
        ),
        SizedBox(height: compact ? 4 : AppTheme.spacingSm),
        ...citations.map((c) => _CitationRow(citation: c, compact: compact)),
        if (grounding != null) ...[
          SizedBox(height: compact ? 4 : AppTheme.spacingSm),
          Text(
            'Grounding: $grounding',
            style: TextStyle(
              fontSize: compact ? 10 : 11,
              color: AppTheme.textSecondaryColor,
            ),
          ),
        ],
      ],
    );
  }
}

class _CitationRow extends StatelessWidget {
  final AiCitation citation;
  final bool compact;

  const _CitationRow({
    required this.citation,
    required this.compact,
  });

  @override
  Widget build(BuildContext context) {
    final page = citation.pageLabel;
    final contextLabel = citation.contextLabel;

    return Padding(
      padding: EdgeInsets.only(bottom: compact ? 4 : 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.menu_book_outlined,
            size: compact ? 14 : 16,
            color: AppTheme.textSecondaryColor,
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  citation.title,
                  style: TextStyle(
                    fontSize: compact ? 11 : 12,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimaryColor,
                  ),
                ),
                if (contextLabel.isNotEmpty)
                  Text(
                    contextLabel,
                    style: TextStyle(
                      fontSize: compact ? 10 : 11,
                      color: AppTheme.textSecondaryColor,
                    ),
                  ),
                if (page != null)
                  Text(
                    page,
                    style: TextStyle(
                      fontSize: compact ? 10 : 11,
                      color: AppTheme.textSecondaryColor,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
