import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/config/env.dart';
import '../../core/config/supabase_client.dart';
import '../../core/utils/formatters.dart';
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
  final SupabaseClient? _supabase;
  SearchIndexSnapshot? _memoryCache;

  SearchRepository(this._dio, {SupabaseClient? supabase})
    : _supabase = supabase;

  Future<SearchIndexSnapshot> getIndex({bool forceRefresh = false}) async {
    if (_memoryCache != null &&
        _memoryCache!.documents.isNotEmpty &&
        !forceRefresh) {
      return _memoryCache!;
    }

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
      try {
        final raw = await file.readAsString();
        final cachedDocs = parseJson(raw);
        if (cachedDocs.isNotEmpty) {
          _memoryCache = SearchIndexSnapshot(
            documents: cachedDocs,
            lastSyncedAt: lastSyncDate,
            servedFromCache: true,
          );
          return _memoryCache!;
        }
      } catch (_) {
        // Ignore corrupted cache and re-sync below
      }
    }

    // 1. Primary: build fresh index directly from Supabase
    if (_supabase != null) {
      try {
        final docs = await _fetchFromSupabase(_supabase);
        if (docs.isNotEmpty) {
          final now = DateTime.now();
          final encoded = jsonEncode(docs.map((d) => d.toJson()).toList());
          await file.writeAsString(encoded);
          await prefs.setInt(_lastSyncKey, now.millisecondsSinceEpoch);
          _memoryCache = SearchIndexSnapshot(
            documents: docs,
            lastSyncedAt: now,
            servedFromCache: false,
          );
          return _memoryCache!;
        }
      } catch (_) {
        // Fall through to search-index.json / stale cache
      }
    }

    // 2. Fallback: static search-index.json
    try {
      final response = await _dio.get<String>(
        Env.searchIndexUrl,
        options: Options(
          responseType: ResponseType.plain,
          receiveTimeout: const Duration(seconds: 6),
          sendTimeout: const Duration(seconds: 6),
        ),
      );
      if (response.data != null && response.data!.isNotEmpty) {
        final parsed = parseJson(response.data!);
        if (parsed.isNotEmpty) {
          final now = DateTime.now();
          await file.writeAsString(response.data!);
          await prefs.setInt(_lastSyncKey, now.millisecondsSinceEpoch);
          _memoryCache = SearchIndexSnapshot(
            documents: parsed,
            lastSyncedAt: now,
            servedFromCache: false,
          );
          return _memoryCache!;
        }
      }
    } catch (_) {
      // Fall through to stale local cache
    }

    // 3. Offline fallback: serve stale local cache if available
    if (await file.exists()) {
      try {
        final raw = await file.readAsString();
        final cachedDocs = parseJson(raw);
        if (cachedDocs.isNotEmpty) {
          _memoryCache = SearchIndexSnapshot(
            documents: cachedDocs,
            lastSyncedAt: lastSyncDate,
            servedFromCache: true,
          );
          return _memoryCache!;
        }
      } catch (_) {
        // Ignore corrupted cache
      }
    }

    return const SearchIndexSnapshot(documents: []);
  }

  Future<List<SearchDocument>> _fetchFromSupabase(SupabaseClient client) async {
    final rows = await client
        .from('courses')
        .select(
          'id, name, slug, level, '
          'department:departments(name, slug, programme:programmes(name, slug)), '
          'units(id, name, slug, unit_code, resources(id))',
        )
        .eq('published', true);

    final docs = <SearchDocument>[];
    for (final raw in (rows as List<dynamic>)) {
      if (raw is! Map<String, dynamic>) continue;
      final dept = raw['department'] as Map<String, dynamic>?;
      final prog = dept?['programme'] as Map<String, dynamic>?;
      final progSlug = prog?['slug'] as String? ?? '';
      final deptSlug = dept?['slug'] as String? ?? '';
      final courseSlug = raw['slug'] as String? ?? '';
      if (progSlug.isEmpty || deptSlug.isEmpty || courseSlug.isEmpty) continue;

      final courseName = raw['name'] as String? ?? '';
      final level = (raw['level'] as num?)?.toInt();
      final progLabel = programmeShortLabel(
        progSlug,
        fallbackName: prog?['name'] as String?,
      );
      final deptName = toTitleCase(dept?['name'] as String? ?? '');
      final courseBreadcrumb = '$progLabel > $deptName';
      final coursePath = '/$progSlug/$deptSlug/$courseSlug';

      docs.add(
        SearchDocument(
          id: raw['id'] as String? ?? coursePath,
          type: 'course',
          name: courseName,
          level: level,
          path: coursePath,
          breadcrumb: courseBreadcrumb,
        ),
      );

      final units = raw['units'];
      if (units is List) {
        final unitBreadcrumb = '$courseBreadcrumb > ${toTitleCase(courseName)}';
        for (final u in units) {
          if (u is! Map<String, dynamic>) continue;
          final unitSlug = u['slug'] as String? ?? '';
          if (unitSlug.isEmpty) continue;
          final resources = u['resources'];
          final resCount = resources is List ? resources.length : 0;
          final unitCode = (u['unit_code'] as String?)?.trim();

          docs.add(
            SearchDocument(
              id: u['id'] as String? ?? '$coursePath/$unitSlug',
              type: 'unit',
              name: u['name'] as String? ?? '',
              code: (unitCode != null && unitCode.isNotEmpty) ? unitCode : null,
              level: level,
              path: '$coursePath/$unitSlug',
              breadcrumb: unitBreadcrumb,
              resourceCount: resCount > 0 ? resCount : null,
            ),
          );
        }
      }
    }

    return docs;
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
  return SearchRepository(
    ref.watch(dioProvider),
    supabase: ref.watch(supabaseClientProvider),
  );
});

final searchIndexProvider = FutureProvider<SearchIndexSnapshot>((ref) async {
  return ref.watch(searchRepositoryProvider).getIndex();
});
