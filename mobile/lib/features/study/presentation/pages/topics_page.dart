import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/ms_card.dart';
import '../../../../core/widgets/ms_empty_state.dart';
import '../../../../core/widgets/ms_section_header.dart';
import '../../data/datasources/study_remote_datasource.dart';
import '../../data/models/topic_model.dart';

class TopicsPage extends StatefulWidget {
  final String subjectId;
  final String? subjectName;
  final StudyRemoteDataSource? studyRemoteDataSource;

  const TopicsPage({
    super.key,
    required this.subjectId,
    this.subjectName,
    this.studyRemoteDataSource,
  });

  @override
  State<TopicsPage> createState() => _TopicsPageState();
}

class _TopicsPageState extends State<TopicsPage> {
  late final StudyRemoteDataSource _dataSource;
  bool _isLoading = true;
  String? _errorMessage;
  List<TopicModel> _topics = [];

  @override
  void initState() {
    super.initState();
    _dataSource = widget.studyRemoteDataSource ?? StudyRemoteDataSource();
    _fetchTopics();
  }

  Future<void> _fetchTopics() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final topics = await _dataSource.getTopics(widget.subjectId);
      if (mounted) {
        setState(() {
          _topics = topics;
          _isLoading = false;
        });
      }
    } on Failure catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.message;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _errorMessage =
              'Failed to load topics. Please check your connection.';
          _isLoading = false;
        });
      }
    }
  }

  void _onTopicTap(TopicModel topic) {
    try {
      context.push(
        '/subjects/${topic.subjectId}/topics/${topic.id}/materials',
        extra: topic.name,
      );
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final titleText = widget.subjectName != null
        ? '${widget.subjectName} Topics'
        : 'Subject Topics';

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: Text(titleText),
        actions: [
          IconButton(
            tooltip: 'Refresh topics',
            onPressed: _isLoading ? null : _fetchTopics,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppTheme.spacingLg,
            AppTheme.spacingMd,
            AppTheme.spacingLg,
            AppTheme.spacingLg,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              MsSectionHeader(
                title: 'Study Topics',
                subtitle: widget.subjectName != null
                    ? '${widget.subjectName} · select a topic to view PDF notes'
                    : 'Subject modules & learning material',
              ),
              const SizedBox(height: AppTheme.spacingLg),
              Expanded(
                child: _buildBody(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return MsErrorState(message: _errorMessage!, onRetry: _fetchTopics);
    }

    if (_topics.isEmpty) {
      return MsEmptyState(
        icon: Icons.folder_open_rounded,
        title: 'No topics available for this subject',
        message: 'Check back later for updated study topics.',
        actionLabel: 'Refresh',
        onAction: _fetchTopics,
      );
    }

    return RefreshIndicator(
      onRefresh: _fetchTopics,
      color: AppTheme.primaryColor,
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: _topics.length,
        separatorBuilder: (_, __) => const SizedBox(height: AppTheme.spacingMd),
        itemBuilder: (context, index) {
          final topic = _topics[index];
          final topicAccents = [
            AppTheme.primaryColor,
            AppTheme.secondaryColor,
            const Color(0xFF0284C7),
            const Color(0xFF4F46E5),
          ];
          final accent = topicAccents[index % topicAccents.length];

          return MsCard(
            onTap: () => _onTopicTap(topic),
            padding: const EdgeInsets.symmetric(
              horizontal: AppTheme.spacingLg,
              vertical: AppTheme.spacingMd,
            ),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        accent.withValues(alpha: 0.14),
                        accent.withValues(alpha: 0.05),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: accent.withValues(alpha: 0.22),
                      width: 1.2,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      'T${topic.sortOrder}',
                      style: TextStyle(
                        color: accent,
                        fontWeight: FontWeight.w800,
                        fontSize: 14,
                        letterSpacing: -0.2,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: AppTheme.spacingMd),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        topic.name,
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.picture_as_pdf_outlined,
                            size: 13,
                            color: AppTheme.textSecondaryColor,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Clinical PDF notes & past papers',
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(
                                  color: AppTheme.textSecondaryColor,
                                ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceMuted,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: 13,
                      color: AppTheme.textSecondaryColor,
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
