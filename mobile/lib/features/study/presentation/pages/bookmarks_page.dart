import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/theme/app_theme.dart';
import '../../data/datasources/study_remote_datasource.dart';
import '../../data/models/bookmarked_material_model.dart';

class BookmarksPage extends StatefulWidget {
  final StudyRemoteDataSource? studyRemoteDataSource;

  const BookmarksPage({
    super.key,
    this.studyRemoteDataSource,
  });

  @override
  State<BookmarksPage> createState() => _BookmarksPageState();
}

class _BookmarksPageState extends State<BookmarksPage> {
  late final StudyRemoteDataSource _dataSource;
  bool _isLoading = true;
  String? _errorMessage;
  List<BookmarkedMaterialModel> _bookmarks = [];
  final Set<String> _removingBookmarkIds = {};
  bool _isRequestingAccess = false;

  @override
  void initState() {
    super.initState();
    _dataSource = widget.studyRemoteDataSource ?? StudyRemoteDataSource();
    _fetchBookmarks();
  }

  Future<void> _fetchBookmarks() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final list = await _dataSource.getBookmarks();
      if (mounted) {
        setState(() {
          _bookmarks = list;
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
              'Failed to load bookmarked materials. Please check connection.';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _removeBookmark(BookmarkedMaterialModel item) async {
    if (_removingBookmarkIds.contains(item.id)) return;

    if (!mounted) return;
    setState(() {
      _removingBookmarkIds.add(item.id);
    });

    try {
      await _dataSource.removeBookmark(item.id);
      if (mounted) {
        setState(() {
          _removingBookmarkIds.remove(item.id);
          _bookmarks.removeWhere((b) => b.id == item.id);
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('"${item.title}" removed from bookmarks.'),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } on Failure catch (e) {
      if (mounted) {
        setState(() {
          _removingBookmarkIds.remove(item.id);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.message),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _removingBookmarkIds.remove(item.id);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to remove bookmark.'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  Future<void> _openMaterial(BookmarkedMaterialModel item) async {
    if (_isRequestingAccess) return;

    if (!mounted) return;
    setState(() {
      _isRequestingAccess = true;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Row(
          children: [
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            ),
            SizedBox(width: 12),
            Text('Requesting material access...'),
          ],
        ),
        duration: Duration(seconds: 2),
      ),
    );

    try {
      final access = await _dataSource.getMaterialAccess(item.id);
      if (mounted) {
        setState(() {
          _isRequestingAccess = false;
        });

        context.push(
          '/materials/${item.id}/view',
          extra: {
            'title': item.title,
            'pdfUrl': access.url,
            'watermarkText': access.watermark,
          },
        );
      }
    } on Failure catch (e) {
      if (mounted) {
        setState(() {
          _isRequestingAccess = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.message),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _isRequestingAccess = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to obtain material access.'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  String _formatFileSize(String bytesStr) {
    final bytes = int.tryParse(bytesStr) ?? 0;
    if (bytes <= 0) return '';
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  String _formatDate(DateTime? date) {
    if (date == null) return '';
    return '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  IconData _getMaterialIcon(String type) {
    switch (type.toUpperCase()) {
      case 'VIDEO':
        return Icons.play_circle_fill_rounded;
      case 'NOTES':
        return Icons.note_alt_rounded;
      case 'PDF':
      default:
        return Icons.picture_as_pdf_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bookmarked Materials'),
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
                'Bookmarks Library',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: AppTheme.spacingXs),
              const Text(
                'Quick access to your saved study materials',
                style: TextStyle(
                  fontSize: 13,
                  color: AppTheme.textSecondaryColor,
                ),
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
                    fontSize: 15, color: AppTheme.textPrimaryColor),
              ),
              const SizedBox(height: AppTheme.spacingLg),
              ElevatedButton.icon(
                onPressed: _fetchBookmarks,
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

    if (_bookmarks.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.bookmark_outline_rounded,
                size: 64, color: AppTheme.textSecondaryColor),
            const SizedBox(height: AppTheme.spacingMd),
            const Text(
              'No bookmarked materials',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimaryColor,
              ),
            ),
            const SizedBox(height: AppTheme.spacingXs),
            const Text(
              'Materials you bookmark will appear here for quick access.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: AppTheme.textSecondaryColor,
              ),
            ),
            const SizedBox(height: AppTheme.spacingLg),
            OutlinedButton.icon(
              onPressed: _fetchBookmarks,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Refresh'),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _fetchBookmarks,
      child: ListView.separated(
        itemCount: _bookmarks.length,
        separatorBuilder: (context, index) =>
            const SizedBox(height: AppTheme.spacingMd),
        itemBuilder: (context, index) {
          final item = _bookmarks[index];
          final sizeFormatted = _formatFileSize(item.fileSizeBytes);
          final dateFormatted = _formatDate(item.bookmarkedAt);
          final isRemoving = _removingBookmarkIds.contains(item.id);

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
                child: Icon(
                  _getMaterialIcon(item.type),
                  color: AppTheme.primaryColor,
                ),
              ),
              title: Text(
                item.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimaryColor,
                ),
              ),
              subtitle: Wrap(
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  if (dateFormatted.isNotEmpty)
                    Text(
                      'Saved $dateFormatted',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppTheme.textSecondaryColor,
                      ),
                    ),
                  if (sizeFormatted.isNotEmpty) ...[
                    if (dateFormatted.isNotEmpty) const SizedBox(width: 6),
                    Text(
                      '($sizeFormatted)',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppTheme.textSecondaryColor,
                      ),
                    ),
                  ],
                ],
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (isRemoving)
                    const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  else
                    IconButton(
                      icon: const Icon(
                        Icons.bookmark_rounded,
                        color: AppTheme.primaryColor,
                      ),
                      tooltip: 'Remove Bookmark',
                      onPressed: () => _removeBookmark(item),
                    ),
                  const SizedBox(width: 4),
                  const Icon(Icons.chevron_right_rounded,
                      color: AppTheme.textSecondaryColor),
                ],
              ),
              onTap: () => _openMaterial(item),
            ),
          );
        },
      ),
    );
  }
}
