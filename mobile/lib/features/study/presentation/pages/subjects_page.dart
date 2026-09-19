import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/ms_card.dart';
import '../../../../core/widgets/ms_empty_state.dart';
import '../../../../core/widgets/ms_section_header.dart';
import '../../data/datasources/study_remote_datasource.dart';
import '../../data/models/subject_model.dart';

class SubjectsPage extends StatefulWidget {
  final String yearSlug;
  final String? yearName;
  final StudyRemoteDataSource? studyRemoteDataSource;

  const SubjectsPage({
    super.key,
    required this.yearSlug,
    this.yearName,
    this.studyRemoteDataSource,
  });

  @override
  State<SubjectsPage> createState() => _SubjectsPageState();
}

class _SubjectsPageState extends State<SubjectsPage> {
  late final StudyRemoteDataSource _dataSource;
  bool _isLoading = true;
  String? _errorMessage;
  List<SubjectModel> _subjects = [];

  @override
  void initState() {
    super.initState();
    _dataSource = widget.studyRemoteDataSource ?? StudyRemoteDataSource();
    _fetchSubjects();
  }

  @override
  void didUpdateWidget(covariant SubjectsPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.yearSlug != widget.yearSlug) {
      _fetchSubjects();
    }
  }

  Future<void> _fetchSubjects() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final subjects = await _dataSource.getSubjects(widget.yearSlug);
      if (mounted) {
        setState(() {
          _subjects = subjects;
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
              'Failed to load subjects. Please check your connection.';
          _isLoading = false;
        });
      }
    }
  }

  void _onSubjectTap(SubjectModel subject) {
    context.push('/subjects/${subject.id}/topics', extra: subject.name);
  }

  String get _yearLabel {
    if (widget.yearName != null && widget.yearName!.trim().isNotEmpty) {
      return widget.yearName!;
    }
    return widget.yearSlug
        .replaceAll('-', ' ')
        .split(' ')
        .map((w) => w.isEmpty ? w : '${w[0].toUpperCase()}${w.substring(1)}')
        .join(' ');
  }

  IconData _iconForSubject(String slug, String name) {
    final key = '${slug}_$name'.toLowerCase();
    if (key.contains('past') || key.contains('paper')) {
      return Icons.description_outlined;
    }
    if (key.contains('anat')) return Icons.accessibility_new_rounded;
    if (key.contains('physio')) return Icons.monitor_heart_outlined;
    if (key.contains('biochem') || key.contains('chem')) {
      return Icons.science_outlined;
    }
    if (key.contains('patho')) return Icons.biotech_outlined;
    if (key.contains('pharma')) return Icons.medication_outlined;
    if (key.contains('micro')) return Icons.coronavirus_outlined;
    if (key.contains('forensic')) return Icons.gavel_rounded;
    if (key.contains('community') || key.contains('psm')) {
      return Icons.public_outlined;
    }
    return Icons.menu_book_rounded;
  }

  Color _accentForIndex(int index) {
    final accents = [
      AppTheme.primaryColor,
      AppTheme.secondaryColor,
      Color(0xFF0369A1),
      Color(0xFF0F766E),
      Color(0xFF4338CA),
      Color(0xFFB45309),
    ];
    return accents[index % accents.length];
  }

  @override
  Widget build(BuildContext context) {
    final titleText = widget.yearName != null
        ? '${widget.yearName} Subjects'
        : 'Medical Subjects';

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: Text(titleText),
        actions: [
          IconButton(
            tooltip: 'Refresh subjects',
            onPressed: _isLoading ? null : _fetchSubjects,
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
                title: 'Available Subjects',
                subtitle: '$_yearLabel · open a subject to browse topics',
              ),
              const SizedBox(height: AppTheme.spacingLg),
              Expanded(child: _buildBody()),
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
      return MsErrorState(message: _errorMessage!, onRetry: _fetchSubjects);
    }

    if (_subjects.isEmpty) {
      return MsEmptyState(
        icon: Icons.folder_open_rounded,
        title: 'No subjects available for this year',
        message: 'Check back later for updated subject modules.',
        actionLabel: 'Refresh',
        onAction: _fetchSubjects,
      );
    }

    return RefreshIndicator(
      onRefresh: _fetchSubjects,
      color: AppTheme.primaryColor,
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: _subjects.length,
        separatorBuilder: (_, __) => const SizedBox(height: AppTheme.spacingMd),
        itemBuilder: (context, index) {
          final subject = _subjects[index];
          final accent = _accentForIndex(index);
          final icon = _iconForSubject(subject.slug, subject.name);

          return MsCard(
            onTap: () => _onSubjectTap(subject),
            padding: const EdgeInsets.all(AppTheme.spacingMd),
            child: Row(
              children: [
                Container(
                  width: 54,
                  height: 54,
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: accent.withValues(alpha: 0.18),
                    ),
                  ),
                  child: Icon(icon, color: accent, size: 26),
                ),
                const SizedBox(width: AppTheme.spacingMd),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        subject.name,
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Browse topics & study materials',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceMuted,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 14,
                    color: AppTheme.primaryColor,
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
