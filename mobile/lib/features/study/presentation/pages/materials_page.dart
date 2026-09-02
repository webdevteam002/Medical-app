import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/storage/offline_material_storage.dart';
import '../../../../core/theme/app_theme.dart';
import '../../data/datasources/study_remote_datasource.dart';
import '../../data/models/material_model.dart';
import '../../data/models/offline_material_model.dart';

class MaterialsPage extends StatefulWidget {
  final String subjectId;
  final String topicId;
  final String? topicName;
  final StudyRemoteDataSource? studyRemoteDataSource;
  final OfflineMaterialStorage? offlineMaterialStorage;
  final ApiClient? apiClient;

  const MaterialsPage({
    super.key,
    required this.subjectId,
    required this.topicId,
    this.topicName,
    this.studyRemoteDataSource,
    this.offlineMaterialStorage,
    this.apiClient,
  });

  @override
  State<MaterialsPage> createState() => _MaterialsPageState();
}

class _MaterialsPageState extends State<MaterialsPage> {
  late final StudyRemoteDataSource _dataSource;
  late final OfflineMaterialStorage _offlineStorage;
  late final ApiClient _apiClient;

  bool _isLoading = true;
  String? _errorMessage;
  List<MaterialModel> _materials = [];
  Set<String> _downloadedMaterialIds = {};
  final Set<String> _downloadingMaterialIds = {};
  bool _isRequestingAccess = false;

  @override
  void initState() {
    super.initState();
    _dataSource = widget.studyRemoteDataSource ?? StudyRemoteDataSource();
    _offlineStorage = widget.offlineMaterialStorage ?? OfflineMaterialStorage();
    _apiClient = widget.apiClient ?? ApiClient();
    _fetchMaterials();
  }

  Future<void> _fetchMaterials() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final materials = await _dataSource.getMaterials(
        subjectId: widget.subjectId,
        topicId: widget.topicId,
      );

      final offlineList = await _offlineStorage.listMaterials();
      final downloadedIds = offlineList.map((e) => e.materialId).toSet();

      if (mounted) {
        setState(() {
          _materials = materials;
          _downloadedMaterialIds = downloadedIds;
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
              'Failed to load materials. Please check your connection.';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _downloadMaterial(MaterialModel material) async {
    if (_downloadingMaterialIds.contains(material.id)) return;

    setState(() {
      _downloadingMaterialIds.add(material.id);
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Downloading "${material.title}"...'),
        duration: const Duration(seconds: 2),
      ),
    );

    try {
      final access = await _dataSource.getMaterialAccess(material.id);

      final response = await _apiClient.client.get<List<int>>(
        access.url,
        options: Options(responseType: ResponseType.bytes),
      );

      final pdfBytes = response.data;
      if (pdfBytes == null || pdfBytes.isEmpty) {
        throw const NetworkFailure('Failed to download material bytes.');
      }

      final offlineModel = OfflineMaterialModel(
        materialId: material.id,
        title: material.title,
        type: material.type,
        topicId: material.topicId,
        fileSizeBytes: pdfBytes.length.toString(),
        downloadedAt: DateTime.now(),
        localPath: '',
        isEncrypted: true,
      );

      await _offlineStorage.saveMaterial(
        model: offlineModel,
        rawBytes: pdfBytes,
      );

      if (mounted) {
        setState(() {
          _downloadingMaterialIds.remove(material.id);
          _downloadedMaterialIds.add(material.id);
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:
                Text('"${material.title}" downloaded & encrypted offline.'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } on Failure catch (e) {
      if (mounted) {
        setState(() {
          _downloadingMaterialIds.remove(material.id);
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
          _downloadingMaterialIds.remove(material.id);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to download offline material.'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  Future<void> _onMaterialTap(MaterialModel material) async {
    if (_isRequestingAccess) return;

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
            Text('Requesting secure material access...'),
          ],
        ),
        duration: Duration(seconds: 2),
      ),
    );

    try {
      final access = await _dataSource.getMaterialAccess(material.id);
      if (mounted) {
        setState(() {
          _isRequestingAccess = false;
        });

        context.push(
          '/materials/${material.id}/view',
          extra: {
            'title': material.title,
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

  Color _getMaterialColor(String type) {
    switch (type.toUpperCase()) {
      case 'VIDEO':
        return Colors.purple;
      case 'NOTES':
        return Colors.orange;
      case 'PDF':
      default:
        return AppTheme.primaryColor;
    }
  }

  @override
  Widget build(BuildContext context) {
    final titleText = widget.topicName != null
        ? '${widget.topicName} Materials'
        : 'Study Materials';

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
                'Materials Library',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: AppTheme.spacingXs),
              Text(
                'Topic ID: ${widget.topicId}',
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
                    fontSize: 15, color: AppTheme.textPrimaryColor),
              ),
              const SizedBox(height: AppTheme.spacingLg),
              ElevatedButton.icon(
                onPressed: _fetchMaterials,
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

    if (_materials.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.folder_open_rounded,
                size: 64, color: AppTheme.textSecondaryColor),
            const SizedBox(height: AppTheme.spacingMd),
            const Text(
              'No materials available for this topic',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimaryColor,
              ),
            ),
            const SizedBox(height: AppTheme.spacingXs),
            const Text(
              'Check back later for updated study materials.',
              style: TextStyle(
                fontSize: 14,
                color: AppTheme.textSecondaryColor,
              ),
            ),
            const SizedBox(height: AppTheme.spacingLg),
            OutlinedButton(
              onPressed: _fetchMaterials,
              child: const Text('Refresh'),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      itemCount: _materials.length,
      separatorBuilder: (context, index) =>
          const SizedBox(height: AppTheme.spacingMd),
      itemBuilder: (context, index) {
        final material = _materials[index];
        final sizeFormatted = _formatFileSize(material.fileSizeBytes);
        final isDownloaded = _downloadedMaterialIds.contains(material.id);
        final isDownloading = _downloadingMaterialIds.contains(material.id);

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
              backgroundColor:
                  _getMaterialColor(material.type).withValues(alpha: 0.1),
              child: Icon(
                _getMaterialIcon(material.type),
                color: _getMaterialColor(material.type),
              ),
            ),
            title: Text(
              material.title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimaryColor,
              ),
            ),
            subtitle: Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    material.type,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textSecondaryColor,
                    ),
                  ),
                ),
                if (sizeFormatted.isNotEmpty) ...[
                  const SizedBox(width: 8),
                  Text(
                    sizeFormatted,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppTheme.textSecondaryColor,
                    ),
                  ),
                ],
                if (isDownloaded) ...[
                  const SizedBox(width: 8),
                  const Text(
                    '• Offline',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.green,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ],
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (material.isDownloadable) ...[
                  if (isDownloading)
                    const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  else if (isDownloaded)
                    const Icon(Icons.check_circle_rounded, color: Colors.green)
                  else
                    IconButton(
                      icon: const Icon(Icons.download_for_offline_outlined,
                          color: AppTheme.primaryColor),
                      onPressed: () => _downloadMaterial(material),
                    ),
                ],
                const Icon(Icons.chevron_right_rounded,
                    color: AppTheme.textSecondaryColor),
              ],
            ),
            onTap: () => _onMaterialTap(material),
          ),
        );
      },
    );
  }
}
