import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
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
  }

  @override
  void dispose() {
    _securityService.disableSecureScreen();
    if (!widget.pdfUrl.startsWith('http') && widget.pdfUrl.isNotEmpty) {
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

    try {
      return PDFView(
        filePath: widget.pdfUrl.startsWith('http') ? null : widget.pdfUrl,
        enableSwipe: true,
        swipeHorizontal: false,
        autoSpacing: true,
        pageFling: true,
        pageSnap: true,
        onRender: (pages) {
          if (mounted) {
            setState(() {
              _totalPages = pages ?? 0;
              _isReady = true;
            });
          }
        },
        onError: (error) {
          if (mounted) {
            setState(() {
              _errorMessage = error.toString();
            });
          }
        },
        onPageError: (page, error) {
          if (mounted) {
            setState(() {
              _errorMessage = 'Page $page error: $error';
            });
          }
        },
        onPageChanged: (int? page, int? total) {
          if (page != null && mounted) {
            setState(() {
              _currentPage = page;
            });
          }
        },
      );
    } on MissingPluginException catch (_) {
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
