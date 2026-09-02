import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/theme/app_theme.dart';
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
    context.push(
      '/subjects/${topic.subjectId}/topics/${topic.id}/materials',
      extra: topic.name,
    );
  }

  @override
  Widget build(BuildContext context) {
    final titleText = widget.subjectName != null
        ? '${widget.subjectName} Topics'
        : 'Subject Topics';

    return Scaffold(
      appBar: AppBar(
        title: Text(titleText),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.spacingLg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Study Topics',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: AppTheme.spacingXs),
              Text(
                'Subject ID: ${widget.subjectId}',
                style: Theme.of(context).textTheme.bodyMedium,
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
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.spacingLg),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline_rounded,
                  size: 48, color: Colors.redAccent),
              const SizedBox(height: AppTheme.spacingMd),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppTheme.textPrimaryColor,
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: AppTheme.spacingLg),
              ElevatedButton.icon(
                onPressed: _fetchTopics,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Retry'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_topics.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.folder_open_rounded,
                size: 64, color: AppTheme.textSecondaryColor),
            const SizedBox(height: AppTheme.spacingMd),
            const Text(
              'No topics available for this subject',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimaryColor,
              ),
            ),
            const SizedBox(height: AppTheme.spacingXs),
            const Text(
              'Check back later for updated study topics.',
              style: TextStyle(
                fontSize: 14,
                color: AppTheme.textSecondaryColor,
              ),
            ),
            const SizedBox(height: AppTheme.spacingLg),
            OutlinedButton(
              onPressed: _fetchTopics,
              child: const Text('Refresh'),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      itemCount: _topics.length,
      separatorBuilder: (context, index) =>
          const SizedBox(height: AppTheme.spacingMd),
      itemBuilder: (context, index) {
        final topic = _topics[index];
        return Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTheme.borderRadiusMd),
            side: const BorderSide(color: Color(0xFFE2E8F0)),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: AppTheme.spacingLg,
              vertical: AppTheme.spacingSm,
            ),
            leading: CircleAvatar(
              backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.1),
              child: Text(
                'T${topic.sortOrder}',
                style: const TextStyle(
                  color: AppTheme.primaryColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
            title: Text(
              topic.name,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimaryColor,
              ),
            ),
            trailing: const Icon(Icons.chevron_right_rounded,
                color: AppTheme.textSecondaryColor),
            onTap: () => _onTopicTap(topic),
          ),
        );
      },
    );
  }
}
