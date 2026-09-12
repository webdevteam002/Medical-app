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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          if (_isReady && _totalPages > 0)
            Padding(
              padding: const EdgeInsets.only(right: AppTheme.spacingMd),
              child: Center(
                child: Text(
                  '${_currentPage + 1} / $_totalPages',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
        ],
      ),
      body: Stack(
        children: [
          _buildPdfBody(),
          _buildWatermarkOverlay(_formattedWatermark),
        ],
      ),
    );
  }

  Widget _buildPdfBody() {
    if (widget.isTestMode) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.picture_as_pdf_rounded,
                size: 48, color: AppTheme.primaryColor),
            const SizedBox(height: AppTheme.spacingMd),
            Text(
              widget.title,
              style: const TextStyle(
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
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: AppTheme.spacingMd),
            Text('Loading PDF…'),
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
              const Icon(Icons.error_outline_rounded,
                  size: 48, color: Colors.redAccent),
              const SizedBox(height: AppTheme.spacingMd),
              Text(
                _errorMessage,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    fontSize: 15, color: AppTheme.textPrimaryColor),
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
        backgroundColor: AppTheme.backgroundColor,
        loadingBannerBuilder: (context, bytesDownloaded, totalBytes) =>
            const Center(child: CircularProgressIndicator()),
        errorBannerBuilder: (context, error, stackTrace, documentRef) =>
            Center(
          child: Padding(
            padding: const EdgeInsets.all(AppTheme.spacingLg),
            child: Text(
              'Could not open PDF in the app.\n$error',
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppTheme.textPrimaryColor),
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
              color: Colors.black.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              text,
              style: TextStyle(
                color: Colors.red.withValues(alpha: 0.3),
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
