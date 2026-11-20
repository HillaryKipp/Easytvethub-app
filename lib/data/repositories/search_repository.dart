import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/config/env.dart';
import '../../core/config/supabase_client.dart';
import '../models/search_document.dart';

class SearchIndexSnapshot {
  final List<SearchDocument> documents;
  final DateTime? lastSyncedAt;
  final bool servedFromCache;

  const SearchIndexSnapshot({
    required this.documents,
    this.lastSyncedAt,
    this.servedFromCache = false,
  });
}

class SearchRepository {
  static const _cacheFileName = 'search_index_cache.json';
  static const _lastSyncKey = 'search_index_last_sync_ms';
  static const _ttl = Duration(hours: 24);

  final Dio _dio;
  SearchIndexSnapshot? _memoryCache;

  SearchRepository(this._dio);

  Future<SearchIndexSnapshot> getIndex({bool forceRefresh = false}) async {
    if (_memoryCache != null && !forceRefresh) return _memoryCache!;

    final dir = await getApplicationSupportDirectory();
    final file = File('${dir.path}/$_cacheFileName');
    final prefs = await SharedPreferences.getInstance();
    final lastSyncMs = prefs.getInt(_lastSyncKey) ?? 0;
    final lastSyncDate = lastSyncMs > 0
        ? DateTime.fromMillisecondsSinceEpoch(lastSyncMs)
        : null;
    final isStale =
        DateTime.now().millisecondsSinceEpoch - lastSyncMs > _ttl.inMilliseconds;

    if (!forceRefresh && await file.exists() && !isStale) {
      final raw = await file.readAsString();
      _memoryCache = SearchIndexSnapshot(
        documents: parseJson(raw),
        lastSyncedAt: lastSyncDate,
        servedFromCache: true,
      );
      return _memoryCache!;
    }

    try {
      final response = await _dio.get<String>(
        Env.searchIndexUrl,
        options: Options(responseType: ResponseType.plain),
      );
      if (response.data != null && response.data!.isNotEmpty) {
        final now = DateTime.now();
        await file.writeAsString(response.data!);
        await prefs.setInt(_lastSyncKey, now.millisecondsSinceEpoch);
        _memoryCache = SearchIndexSnapshot(
          documents: parseJson(response.data!),
          lastSyncedAt: now,
          servedFromCache: false,
        );
        return _memoryCache!;
      }
    } catch (_) {
      // Offline fallback: serve stale local cache if available
      if (await file.exists()) {
        final raw = await file.readAsString();
        _memoryCache = SearchIndexSnapshot(
          documents: parseJson(raw),
          lastSyncedAt: lastSyncDate,
          servedFromCache: true,
        );
        return _memoryCache!;
      }
    }

    return const SearchIndexSnapshot(documents: []);
  }

  List<SearchDocument> search({
    required List<SearchDocument> docs,
    required String query,
    String typeFilter = 'all', // 'all' | 'course' | 'unit'
    int? levelFilter,
  }) {
    final tokens = query
        .trim()
        .toLowerCase()
        .split(RegExp(r'\s+'))
        .where((t) => t.isNotEmpty)
        .toList();

    final filtered = docs.where((doc) {
      if (typeFilter != 'all' && doc.type != typeFilter) return false;
      if (levelFilter != null && doc.level != levelFilter) return false;
      if (tokens.isEmpty) return true;

      final haystack = '${doc.name} ${doc.code ?? ''} ${doc.breadcrumb}'
          .toLowerCase();
      return tokens.every(haystack.contains);
    }).toList();

    // Rank name/code matches above breadcrumb-only matches
    if (tokens.isNotEmpty) {
      final q = query.trim().toLowerCase();
      filtered.sort((a, b) {
        int score(SearchDocument d) {
          final n = d.name.toLowerCase();
          final c = (d.code ?? '').toLowerCase();
          if (n == q || c == q) return 100;
          if (n.startsWith(q)) return 60;
          if (n.contains(q) || c.contains(q)) return 30;
          return 10;
        }

        return score(b).compareTo(score(a));
      });
    }

    return tokens.isEmpty ? filtered.take(60).toList() : filtered;
  }

  List<SearchDocument> parseJson(String raw) {
    final decoded = jsonDecode(raw);
    if (decoded is! List) return const [];
    return decoded
        .whereType<Map<String, dynamic>>()
        .map(SearchDocument.fromJson)
        .toList();
  }
}

final searchRepositoryProvider = Provider<SearchRepository>((ref) {
  return SearchRepository(ref.watch(dioProvider));
});

final searchIndexProvider = FutureProvider<SearchIndexSnapshot>((ref) async {
  return ref.watch(searchRepositoryProvider).getIndex();
});
