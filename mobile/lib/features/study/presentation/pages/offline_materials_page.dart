import 'dart:io';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import '../../../../core/storage/offline_material_storage.dart';
import '../../../../core/theme/app_theme.dart';
import '../../data/models/offline_material_model.dart';

class OfflineMaterialsPage extends StatefulWidget {
  final OfflineMaterialStorage? storage;

  const OfflineMaterialsPage({
    super.key,
    this.storage,
  });

  @override
  State<OfflineMaterialsPage> createState() => _OfflineMaterialsPageState();
}

class _OfflineMaterialsPageState extends State<OfflineMaterialsPage> {
  late final OfflineMaterialStorage _storage;
  bool _isLoading = true;
  String? _errorMessage;
  List<OfflineMaterialModel> _offlineMaterials = [];
  bool _isOpening = false;

  @override
  void initState() {
    super.initState();
    _storage = widget.storage ?? OfflineMaterialStorage();
    _loadOfflineMaterials();
  }

  Future<void> _loadOfflineMaterials() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final list = await _storage.listMaterials();
      if (mounted) {
        setState(() {
          _offlineMaterials = list;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to load offline materials.';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _openOfflineMaterial(OfflineMaterialModel item) async {
    if (_isOpening) return;

    if (!mounted) return;
    setState(() {
      _isOpening = true;
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
            Text('Decrypting offline document...'),
          ],
        ),
        duration: Duration(seconds: 2),
      ),
    );

    try {
      final decryptedBytes = await _storage.readDecryptedBytes(item.materialId);

      final tempDir = await getTemporaryDirectory();
      final tempFile =
          File(path.join(tempDir.path, 'decrypted_${item.materialId}.pdf'));
      await tempFile.writeAsBytes(decryptedBytes, flush: true);

      if (mounted) {
        setState(() {
          _isOpening = false;
        });

        context.push(
          '/materials/${item.materialId}/view',
          extra: {
            'title': item.title,
            'pdfUrl': tempFile.path,
            'watermarkText': 'Offline Authorized Copy',
          },
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isOpening = false;
        });

        // Corrupted file / Decryption failure recovery dialog
        showDialog(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: const Text('Corrupted Offline File'),
            content: Text(
              'Failed to decrypt "${item.title}". The encrypted file may be corrupted or key state changed. Would you like to remove this corrupted copy?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.of(dialogContext).pop();
                  _performDelete(item.materialId);
                },
                child: const Text(
                  'Remove File',
                  style: TextStyle(color: Colors.redAccent),
                ),
              ),
            ],
          ),
        );
      }
    }
  }

  Future<void> _confirmDelete(OfflineMaterialModel item) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Remove Offline Material'),
        content: Text('Remove "${item.title}" from offline storage?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text(
              'Remove',
              style: TextStyle(color: Colors.redAccent),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _performDelete(item.materialId);
    }
  }

  Future<void> _performDelete(String materialId) async {
    try {
      await _storage.deleteMaterial(materialId);
      await _loadOfflineMaterials();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Material removed from offline storage.')),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to delete offline material.'),
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

  String _formatDate(DateTime date) {
    return '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Offline Materials'),
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
                'Offline Downloads',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: AppTheme.spacingXs),
              const Text(
                'AES-256 Encrypted Private Storage',
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
              onPressed: _loadOfflineMaterials,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      );
    }

    if (_offlineMaterials.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.download_for_offline_outlined,
                size: 64, color: AppTheme.textSecondaryColor),
            const SizedBox(height: AppTheme.spacingMd),
            const Text(
              'No offline materials',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimaryColor,
              ),
            ),
            const SizedBox(height: AppTheme.spacingXs),
            const Text(
              'Downloaded materials will appear here for offline study.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: AppTheme.textSecondaryColor,
              ),
            ),
            const SizedBox(height: AppTheme.spacingLg),
            OutlinedButton.icon(
              onPressed: _loadOfflineMaterials,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Refresh'),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadOfflineMaterials,
      child: ListView.separated(
        itemCount: _offlineMaterials.length,
        separatorBuilder: (context, index) =>
            const SizedBox(height: AppTheme.spacingMd),
        itemBuilder: (context, index) {
          final item = _offlineMaterials[index];
          final sizeFormatted = _formatFileSize(item.fileSizeBytes);
          final dateFormatted = _formatDate(item.downloadedAt);

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
              leading: const CircleAvatar(
                backgroundColor: Color(0xFFE2E8F0),
                child: Icon(
                  Icons.lock_clock_rounded,
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
                  Text(
                    'Downloaded $dateFormatted',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppTheme.textSecondaryColor,
                    ),
                  ),
                  if (sizeFormatted.isNotEmpty) ...[
                    const SizedBox(width: 6),
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
              trailing: IconButton(
                icon: const Icon(Icons.delete_outline_rounded,
                    color: Colors.redAccent),
                onPressed: () => _confirmDelete(item),
              ),
              onTap: () => _openOfflineMaterial(item),
            ),
          );
        },
      ),
    );
  }
}
