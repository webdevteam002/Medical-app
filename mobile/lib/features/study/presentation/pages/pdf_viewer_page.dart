import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:path_provider/path_provider.dart';

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

  String? _localPdfPath;
  bool _isLoadingFile = true;
  int _totalPages = 0;
  int _currentPage = 0;
  bool _isReady = false;
  String _errorMessage = '';
  bool _openedExternally = false;

  bool get _isDesktop {
    if (kIsWeb) return false;
    return Platform.isWindows || Platform.isLinux || Platform.isMacOS;
  }

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

  Future<void> _openWithSystemViewer() async {
    final path = _localPdfPath;
    if (path == null || path.isEmpty) return;
    try {
      if (Platform.isWindows) {
        await Process.start('cmd', ['/c', 'start', '', path],
            runInShell: false);
      } else if (Platform.isMacOS) {
        await Process.start('open', [path]);
      } else {
        await Process.start('xdg-open', [path]);
      }
      if (mounted) {
        setState(() => _openedExternally = true);
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open system PDF viewer.')),
        );
      }
    }
  }

  @override
  void dispose() {
    _securityService.disableSecureScreen();
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

    // Desktop: flutter_pdfview is unsupported — open with the OS PDF app.
    if (_isDesktop) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.spacingLg),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.picture_as_pdf_rounded,
                  size: 64, color: AppTheme.primaryColor),
              const SizedBox(height: AppTheme.spacingMd),
              Text(
                widget.title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimaryColor,
                ),
              ),
              const SizedBox(height: AppTheme.spacingSm),
              const Text(
                'In-app PDF preview is not available on Windows desktop.\nOpen the file in your system PDF viewer.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppTheme.textSecondaryColor),
              ),
              const SizedBox(height: AppTheme.spacingLg),
              ElevatedButton.icon(
                onPressed: _openWithSystemViewer,
                icon: const Icon(Icons.open_in_new),
                label: Text(_openedExternally ? 'Open again' : 'Open PDF'),
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

    try {
      return PDFView(
        filePath: path,
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
