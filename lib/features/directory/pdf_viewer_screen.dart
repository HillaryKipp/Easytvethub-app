import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:pdfrx/pdfrx.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/config/env.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/directory_models.dart';
import '../../data/repositories/downloads_repository.dart';

class PdfViewerScreen extends ConsumerStatefulWidget {
  final ResourceModel? resource;
  final String title;
  final String unitName;
  final String courseName;
  final String? localPath;
  final String? originalUrl;
  final String? webPath;

  const PdfViewerScreen({
    super.key,
    this.resource,
    required this.title,
    required this.unitName,
    required this.courseName,
    this.localPath,
    this.originalUrl,
    this.webPath,
  });

  @override
  ConsumerState<PdfViewerScreen> createState() => _PdfViewerScreenState();
}

class _PdfViewerScreenState extends ConsumerState<PdfViewerScreen> {
  String? _resolvedPath;
  bool _loading = true;
  bool _needsExternalBrowser = false;
  String? _errorMessage;

  String get _effectiveUrl =>
      widget.resource?.fileUrl ?? widget.originalUrl ?? '';

  @override
  void initState() {
    super.initState();
    _preparePdf();
  }

  Future<void> _preparePdf() async {
    setState(() {
      _loading = true;
      _needsExternalBrowser = false;
      _errorMessage = null;
    });

    if (widget.localPath != null && await File(widget.localPath!).exists()) {
      if (mounted) {
        setState(() {
          _resolvedPath = widget.localPath;
          _loading = false;
        });
      }
      return;
    }

    if (_effectiveUrl.isEmpty) {
      if (mounted) {
        setState(() {
          _loading = false;
          _errorMessage = 'No PDF URL provided for this resource.';
        });
      }
      return;
    }

    try {
      final path = await ref
          .read(downloadsProvider.notifier)
          .fetchTempPdfForViewing(
            resourceId:
                widget.resource?.id ?? widget.title.hashCode.toString(),
            rawUrl: _effectiveUrl,
          );
      if (mounted) {
        setState(() {
          _resolvedPath = path;
          _loading = false;
        });
      }
    } on HtmlFallbackRequiredException {
      if (mounted) {
        setState(() {
          _needsExternalBrowser = true;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _errorMessage =
              'Could not load the PDF in-app. You can open it directly in your browser.';
          _loading = false;
        });
      }
    }
  }

  Future<void> _openExternally() async {
    if (_effectiveUrl.isEmpty) return;
    await launchUrl(
      Uri.parse(_effectiveUrl),
      mode: LaunchMode.externalApplication,
    );
  }

  Future<void> _saveOffline() async {
    final res = widget.resource;
    if (res == null) return;
    try {
      await ref.read(downloadsProvider.notifier).downloadResource(
            resource: res,
            unitName: widget.unitName,
            courseName: widget.courseName,
            webPath: widget.webPath,
          );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Saved offline to your Saved tab.'),
            backgroundColor: AppColors.green,
          ),
        );
      }
    } on HtmlFallbackRequiredException {
      await _openExternally();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Download failed. Try opening in browser.'),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final downloads = ref.watch(downloadsProvider);
    final resId = widget.resource?.id;
    final isDownloaded = resId != null && downloads.findPdf(resId) != null;
    final progress = resId != null ? downloads.activeProgress[resId] : null;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        actions: [
          if (widget.resource != null)
            progress != null
                ? const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 14),
                    child: Center(
                      child: SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.purple,
                        ),
                      ),
                    ),
                  )
                : IconButton(
                    icon: Icon(
                      isDownloaded
                          ? LucideIcons.circleCheck
                          : LucideIcons.download,
                      size: 20,
                      color: isDownloaded ? AppColors.green : AppColors.purple,
                    ),
                    tooltip: isDownloaded ? 'Saved Offline' : 'Save Offline',
                    onPressed: isDownloaded ? null : _saveOffline,
                  ),
          if (_effectiveUrl.isNotEmpty)
            IconButton(
              icon: const Icon(LucideIcons.externalLink, size: 19),
              tooltip: 'Open in Browser',
              onPressed: _openExternally,
            ),
          IconButton(
            icon: const Icon(LucideIcons.share2, size: 19),
            tooltip: 'Share',
            onPressed: () {
              final url = widget.webPath != null
                  ? Env.canonicalUrl(widget.webPath!)
                  : _effectiveUrl;
              Share.share('${widget.title}\n$url');
            },
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(color: AppColors.purple),
            SizedBox(height: 14),
            Text(
              'Loading past paper...',
              style: TextStyle(
                color: AppColors.text,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      );
    }

    if (_needsExternalBrowser) {
      return Center(
        child: Container(
          margin: const EdgeInsets.all(20),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(AppRadii.xxl),
            border: Border.all(color: AppColors.line),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.purpleTint,
                  borderRadius: BorderRadius.circular(AppRadii.lg),
                ),
                child: const Icon(
                  LucideIcons.externalLink,
                  size: 28,
                  color: AppColors.purple,
                ),
              ),
              const SizedBox(height: 14),
              const Text(
                'Open via Google Drive',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: AppColors.ink,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Google Drive requires opening this document directly in your browser or Drive app (for example, due to file size or permissions).',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13.5,
                  color: AppColors.text,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 18),
              ElevatedButton.icon(
                onPressed: _openExternally,
                icon: const Icon(LucideIcons.externalLink, size: 16),
                label: const Text('Open in Browser / Drive'),
              ),
            ],
          ),
        ),
      );
    }

    if (_errorMessage != null || _resolvedPath == null) {
      return Center(
        child: Container(
          margin: const EdgeInsets.all(20),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(AppRadii.xxl),
            border: Border.all(color: AppColors.line),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(LucideIcons.fileWarning, size: 32, color: AppColors.red),
              const SizedBox(height: 12),
              Text(
                _errorMessage ?? 'Unable to open PDF.',
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.text, fontSize: 14),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 10,
                children: [
                  OutlinedButton(
                    onPressed: _preparePdf,
                    child: const Text('Retry'),
                  ),
                  if (_effectiveUrl.isNotEmpty)
                    ElevatedButton.icon(
                      onPressed: _openExternally,
                      icon: const Icon(LucideIcons.externalLink, size: 15),
                      label: const Text('Open in Browser'),
                    ),
                ],
              ),
            ],
          ),
        ),
      );
    }

    return PdfViewer.file(
      _resolvedPath!,
      params: const PdfViewerParams(
        backgroundColor: AppColors.surface,
      ),
    );
  }
}
