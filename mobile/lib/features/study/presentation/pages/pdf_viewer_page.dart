import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdfrx/pdfrx.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/security/security_service.dart';
import '../../../../core/theme/app_theme.dart';

class PdfViewerPage extends StatefulWidget {
  final String title;
  final String pdfUrl;
  final String? watermarkText;
  final bool isTestMode;
  final SecurityService? securityService;

  const PdfViewerPage({
    super.key,
    required this.title,
    required this.pdfUrl,
    this.watermarkText,
    this.isTestMode = false,
    this.securityService,
  });

  @override
  State<PdfViewerPage> createState() => _PdfViewerPageState();
}

class _PdfViewerPageState extends State<PdfViewerPage> {
  late final SecurityService _securityService;
  late final String _formattedWatermark;
  final PdfViewerController _controller = PdfViewerController();

  String? _localPdfPath;
  bool _isLoadingFile = true;
  int _totalPages = 0;
  int _currentPage = 0;
  bool _isReady = false;
  String _errorMessage = '';
  bool _isDarkCanvas = false;

  @override
  void initState() {
    super.initState();
    _securityService = widget.securityService ?? SecurityService();
    _formattedWatermark = SecurityService.buildDynamicWatermark(
      backendWatermark: widget.watermarkText,
    );
    _securityService.enableSecureScreen();
    if (!widget.isTestMode) {
      _prepareLocalPdf();
    } else {
      _isLoadingFile = false;
    }
  }

  Future<void> _prepareLocalPdf() async {
    try {
      if (!widget.pdfUrl.startsWith('http')) {
        if (mounted) {
          setState(() {
            _localPdfPath = widget.pdfUrl;
            _isLoadingFile = false;
          });
        }
        return;
      }

      final dir = await getTemporaryDirectory();
      final path =
          '${dir.path}${Platform.pathSeparator}medstudy_${DateTime.now().millisecondsSinceEpoch}.pdf';

      await ApiClient().client.download(widget.pdfUrl, path);

      if (mounted) {
        setState(() {
          _localPdfPath = path;
          _isLoadingFile = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _errorMessage =
              'Unable to load PDF. Check that the API is running and you are signed in.';
          _isLoadingFile = false;
        });
      }
    }
  }

  @override
  void dispose() {
    // Keep capture protection on after leaving the PDF viewer (app-wide policy).
    final path = _localPdfPath;
    if (path != null &&
        path.isNotEmpty &&
        (widget.pdfUrl.startsWith('http') || path != widget.pdfUrl)) {
      try {
        final file = File(path);
        if (file.existsSync()) {
          file.deleteSync();
        }
      } catch (_) {}
    } else if (!widget.pdfUrl.startsWith('http') && widget.pdfUrl.isNotEmpty) {
      try {
        final file = File(widget.pdfUrl);
        if (file.existsSync()) {
          file.deleteSync();
        }
      } catch (_) {}
    }
    super.dispose();
  }

  void _zoomIn() {
    final zoom = _controller.currentZoom;
    if (zoom != null) {
      _controller.zoomUp();
    }
  }

  void _zoomOut() {
    final zoom = _controller.currentZoom;
    if (zoom != null) {
      _controller.zoomDown();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _isDarkCanvas ? const Color(0xFF0F172A) : AppTheme.backgroundColor,
      appBar: AppBar(
        title: Text(
          widget.title,
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        backgroundColor: AppTheme.surfaceColor,
        foregroundColor: AppTheme.textPrimaryColor,
        elevation: 0,
        actions: [
          if (_isReady && _totalPages > 0)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceMuted,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppTheme.borderColor),
                  ),
                  child: Text(
                    '${_currentPage + 1} / $_totalPages',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                ),
              ),
            ),
          IconButton(
            tooltip: _isDarkCanvas ? 'Light Canvas' : 'Dark Canvas',
            icon: Icon(
              _isDarkCanvas ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
              color: AppTheme.primaryColor,
            ),
            onPressed: () => setState(() => _isDarkCanvas = !_isDarkCanvas),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: Stack(
        children: [
          _buildPdfBody(),
          _buildWatermarkOverlay(_formattedWatermark),
          if (_isReady && _totalPages > 0) _buildFloatingControls(),
        ],
      ),
    );
  }

  Widget _buildFloatingControls() {
    return Positioned(
      bottom: 20,
      left: 0,
      right: 0,
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: AppTheme.surfaceColor.withValues(alpha: 0.94),
            borderRadius: BorderRadius.circular(30),
            border: Border.all(color: AppTheme.borderColor),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.12),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left_rounded),
                tooltip: 'Previous page',
                onPressed: _currentPage > 0
                    ? () => _controller.goToPage(pageNumber: _currentPage)
                    : null,
                iconSize: 22,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Text(
                  '${_currentPage + 1} of $_totalPages',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimaryColor,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.chevron_right_rounded),
                tooltip: 'Next page',
                onPressed: _currentPage < _totalPages - 1
                    ? () => _controller.goToPage(pageNumber: _currentPage + 2)
                    : null,
                iconSize: 22,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
              ),
              Container(
                height: 20,
                width: 1,
                color: AppTheme.borderColor,
                margin: const EdgeInsets.symmetric(horizontal: 6),
              ),
              IconButton(
                icon: const Icon(Icons.zoom_out_rounded),
                tooltip: 'Zoom out',
                onPressed: _zoomOut,
                iconSize: 20,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
              ),
              IconButton(
                icon: const Icon(Icons.zoom_in_rounded),
                tooltip: 'Zoom in',
                onPressed: _zoomIn,
                iconSize: 20,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPdfBody() {
    if (widget.isTestMode) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(
                Icons.picture_as_pdf_rounded,
                size: 38,
                color: AppTheme.primaryColor,
              ),
            ),
            const SizedBox(height: AppTheme.spacingMd),
            Text(
              widget.title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimaryColor,
              ),
            ),
          ],
        ),
      );
    }

    if (_isLoadingFile) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: AppTheme.spacingMd),
            Text(
              'Loading PDF…',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: AppTheme.textSecondaryColor,
              ),
            ),
          ],
        ),
      );
    }

    if (_errorMessage.isNotEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.spacingLg),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline_rounded,
                size: 48,
                color: Colors.redAccent,
              ),
              const SizedBox(height: AppTheme.spacingMd),
              Text(
                _errorMessage,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 15,
                  color: AppTheme.textPrimaryColor,
                ),
              ),
            ],
          ),
        ),
      );
    }

    final path = _localPdfPath;
    if (path == null || path.isEmpty) {
      return const Center(child: Text('PDF file not found.'));
    }

    return PdfViewer.file(
      path,
      controller: _controller,
      params: PdfViewerParams(
        backgroundColor:
            _isDarkCanvas ? const Color(0xFF0F172A) : AppTheme.backgroundColor,
        loadingBannerBuilder: (context, bytesDownloaded, totalBytes) =>
            const Center(child: CircularProgressIndicator()),
        errorBannerBuilder: (context, error, stackTrace, documentRef) => Center(
          child: Padding(
            padding: const EdgeInsets.all(AppTheme.spacingLg),
            child: Text(
              'Could not open PDF in the app.\n$error',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppTheme.textPrimaryColor),
            ),
          ),
        ),
        onViewerReady: (document, controller) {
          if (!mounted) return;
          setState(() {
            _totalPages = document.pages.length;
            _isReady = true;
            _currentPage = (controller.pageNumber ?? 1) - 1;
          });
        },
        onPageChanged: (pageNumber) {
          if (!mounted || pageNumber == null) return;
          setState(() {
            _currentPage = pageNumber - 1;
          });
        },
      ),
    );
  }

  Widget _buildWatermarkOverlay(String text) {
    return IgnorePointer(
      child: Center(
        child: Transform.rotate(
          angle: -0.4,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.04),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: Colors.red.withValues(alpha: 0.12),
              ),
            ),
            child: Text(
              text,
              style: TextStyle(
                color: Colors.red.withValues(alpha: 0.28),
                fontSize: 14,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.1,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
