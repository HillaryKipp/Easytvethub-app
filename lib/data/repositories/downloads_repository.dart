import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/config/supabase_client.dart';
import '../../core/utils/drive_link_helper.dart';
import '../models/directory_models.dart';
import '../models/saved_models.dart';

class HtmlFallbackRequiredException implements Exception {
  final String originalUrl;
  const HtmlFallbackRequiredException(this.originalUrl);

  @override
  String toString() =>
      'Google Drive returned an HTML page; open externally: $originalUrl';
}

class DownloadsState {
  final List<DownloadedPdf> pdfs;
  final List<SavedBookmark> bookmarks;
  final Map<String, double> activeProgress;
  final bool isLoaded;

  const DownloadsState({
    this.pdfs = const [],
    this.bookmarks = const [],
    this.activeProgress = const {},
    this.isLoaded = false,
  });

  DownloadsState copyWith({
    List<DownloadedPdf>? pdfs,
    List<SavedBookmark>? bookmarks,
    Map<String, double>? activeProgress,
    bool? isLoaded,
  }) {
    return DownloadsState(
      pdfs: pdfs ?? this.pdfs,
      bookmarks: bookmarks ?? this.bookmarks,
      activeProgress: activeProgress ?? this.activeProgress,
      isLoaded: isLoaded ?? this.isLoaded,
    );
  }

  DownloadedPdf? findPdf(String resourceId) {
    for (final pdf in pdfs) {
      if (pdf.resourceId == resourceId) return pdf;
    }
    return null;
  }

  bool isBookmarked(String id) => bookmarks.any((b) => b.id == id);
}

class DownloadsRepository extends StateNotifier<DownloadsState> {
  static const _pdfsKey = 'easytvet_downloaded_pdfs_v1';
  static const _bookmarksKey = 'easytvet_saved_bookmarks_v1';

  final Dio _dio;

  DownloadsRepository(this._dio) : super(const DownloadsState()) {
    _hydrate();
  }

  Future<void> _hydrate() async {
    final prefs = await SharedPreferences.getInstance();

    final rawPdfs = prefs.getString(_pdfsKey);
    final loadedPdfs = <DownloadedPdf>[];
    if (rawPdfs != null && rawPdfs.isNotEmpty) {
      try {
        final decoded = jsonDecode(rawPdfs) as List<dynamic>;
        for (final item in decoded.whereType<Map<String, dynamic>>()) {
          final pdf = DownloadedPdf.fromJson(item);
          if (await File(pdf.localPath).exists()) {
            loadedPdfs.add(pdf);
          }
        }
      } catch (_) {}
    }

    final rawBookmarks = prefs.getString(_bookmarksKey);
    final loadedBookmarks = <SavedBookmark>[];
    if (rawBookmarks != null && rawBookmarks.isNotEmpty) {
      try {
        final decoded = jsonDecode(rawBookmarks) as List<dynamic>;
        for (final item in decoded.whereType<Map<String, dynamic>>()) {
          loadedBookmarks.add(SavedBookmark.fromJson(item));
        }
      } catch (_) {}
    }

    state = state.copyWith(
      pdfs: loadedPdfs,
      bookmarks: loadedBookmarks,
      isLoaded: true,
    );
  }

  Future<void> _persistPdfs(List<DownloadedPdf> pdfs) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _pdfsKey,
      jsonEncode(pdfs.map((e) => e.toJson()).toList()),
    );
  }

  Future<void> _persistBookmarks(List<SavedBookmark> bookmarks) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _bookmarksKey,
      jsonEncode(bookmarks.map((e) => e.toJson()).toList()),
    );
  }

  /// Downloads a PDF resource to local storage, checking Content-Type for HTML interstitials.
  Future<DownloadedPdf> downloadResource({
    required ResourceModel resource,
    required String unitName,
    required String courseName,
    String? webPath,
  }) async {
    final existing = state.findPdf(resource.id);
    if (existing != null && await File(existing.localPath).exists()) {
      return existing;
    }

    final directUrl = DriveLinkHelper.toDirectDownloadUrl(resource.fileUrl);
    final docsDir = await getApplicationDocumentsDirectory();
    final papersDir = Directory('${docsDir.path}/papers');
    if (!await papersDir.exists()) {
      await papersDir.create(recursive: true);
    }

    final safeId = resource.id.replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_');
    final targetPath = '${papersDir.path}/$safeId.pdf';

    _setProgress(resource.id, 0.05);

    try {
      final response = await _dio.download(
        directUrl,
        targetPath,
        onReceiveProgress: (received, total) {
          if (total > 0) {
            _setProgress(resource.id, (received / total).clamp(0.05, 0.99));
          }
        },
        options: Options(
          responseType: ResponseType.bytes,
          followRedirects: true,
          validateStatus: (status) => status != null && status < 400,
        ),
      );

      final contentType = response.headers.value('content-type');
      if (DriveLinkHelper.isHtmlContentType(contentType)) {
        await _safeDeleteFile(targetPath);
        _clearProgress(resource.id);
        throw HtmlFallbackRequiredException(resource.fileUrl);
      }

      // Also verify PDF magic header (%PDF) as a secondary guard against Drive HTML pages
      final file = File(targetPath);
      if (await file.exists()) {
        final bytes = await file.openRead(0, 16).first;
        final header = String.fromCharCodes(bytes);
        if (header.trimLeft().startsWith('<')) {
          await _safeDeleteFile(targetPath);
          _clearProgress(resource.id);
          throw HtmlFallbackRequiredException(resource.fileUrl);
        }
      }

      final downloaded = DownloadedPdf(
        resourceId: resource.id,
        title: resource.displayTitle(unitName),
        unitName: unitName,
        courseName: courseName,
        resourceTypeLabel: resource.type.label,
        year: resource.year,
        localPath: targetPath,
        originalUrl: resource.fileUrl,
        webPath: webPath,
        downloadedAt: DateTime.now(),
      );

      final updated = [
        downloaded,
        ...state.pdfs.where((p) => p.resourceId != resource.id),
      ];
      state = state.copyWith(pdfs: updated);
      await _persistPdfs(updated);
      _clearProgress(resource.id);
      return downloaded;
    } catch (e) {
      _clearProgress(resource.id);
      rethrow;
    }
  }

  /// Fetches a PDF temporarily for in-app viewing without saving to offline list,
  /// returning a local file path or throwing [HtmlFallbackRequiredException].
  Future<String> fetchTempPdfForViewing({
    required String resourceId,
    required String rawUrl,
  }) async {
    final existing = state.findPdf(resourceId);
    if (existing != null && await File(existing.localPath).exists()) {
      return existing.localPath;
    }

    final directUrl = DriveLinkHelper.toDirectDownloadUrl(rawUrl);
    final tempDir = await getTemporaryDirectory();
    final safeId = resourceId.replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_');
    final tempPath = '${tempDir.path}/preview_$safeId.pdf';

    final response = await _dio.download(
      directUrl,
      tempPath,
      options: Options(
        responseType: ResponseType.bytes,
        followRedirects: true,
        validateStatus: (status) => status != null && status < 400,
      ),
    );

    final contentType = response.headers.value('content-type');
    if (DriveLinkHelper.isHtmlContentType(contentType)) {
      await _safeDeleteFile(tempPath);
      throw HtmlFallbackRequiredException(rawUrl);
    }

    final file = File(tempPath);
    if (await file.exists()) {
      final bytes = await file.openRead(0, 16).first;
      final header = String.fromCharCodes(bytes);
      if (header.trimLeft().startsWith('<')) {
        await _safeDeleteFile(tempPath);
        throw HtmlFallbackRequiredException(rawUrl);
      }
    }

    return tempPath;
  }

  Future<void> removeDownload(String resourceId) async {
    final target = state.findPdf(resourceId);
    if (target != null) {
      await _safeDeleteFile(target.localPath);
    }
    final updated = state.pdfs.where((p) => p.resourceId != resourceId).toList();
    state = state.copyWith(pdfs: updated);
    await _persistPdfs(updated);
  }

  Future<void> toggleBookmark(SavedBookmark bookmark) async {
    final exists = state.isBookmarked(bookmark.id);
    final updated = exists
        ? state.bookmarks.where((b) => b.id != bookmark.id).toList()
        : [bookmark, ...state.bookmarks];
    state = state.copyWith(bookmarks: updated);
    await _persistBookmarks(updated);
  }

  Future<void> removeBookmark(String id) async {
    final updated = state.bookmarks.where((b) => b.id != id).toList();
    state = state.copyWith(bookmarks: updated);
    await _persistBookmarks(updated);
  }

  void _setProgress(String resourceId, double value) {
    final next = Map<String, double>.from(state.activeProgress)
      ..[resourceId] = value;
    state = state.copyWith(activeProgress: next);
  }

  void _clearProgress(String resourceId) {
    final next = Map<String, double>.from(state.activeProgress)
      ..remove(resourceId);
    state = state.copyWith(activeProgress: next);
  }

  Future<void> _safeDeleteFile(String path) async {
    try {
      final f = File(path);
      if (await f.exists()) await f.delete();
    } catch (_) {}
  }
}

final downloadsProvider =
    StateNotifierProvider<DownloadsRepository, DownloadsState>((ref) {
      return DownloadsRepository(ref.watch(dioProvider));
    });
