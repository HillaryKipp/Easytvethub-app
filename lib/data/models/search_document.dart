class SearchDocument {
  final String id;
  final String type; // 'course' | 'unit' | 'article'
  final String name;
  final String? code;
  final int? level;
  final String path; // e.g. /modular-cdacc-courses-cycle-3/dept/course/unit/
  final String breadcrumb;
  final int? resourceCount;

  const SearchDocument({
    required this.id,
    required this.type,
    required this.name,
    this.code,
    this.level,
    required this.path,
    required this.breadcrumb,
    this.resourceCount,
  });

  /// Returns a normalized GoRouter path without trailing slash (except root).
  String get normalizedPath {
    var p = path.trim();
    if (!p.startsWith('/')) p = '/$p';
    if (p.length > 1 && p.endsWith('/')) {
      p = p.substring(0, p.length - 1);
    }
    return p;
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'type': type,
    'name': name,
    if (code != null) 'code': code,
    if (level != null) 'level': level,
    'path': path,
    'breadcrumb': breadcrumb,
    if (resourceCount != null) 'resourceCount': resourceCount,
  };

  factory SearchDocument.fromJson(Map<String, dynamic> json) => SearchDocument(
        id: json['id'] as String? ?? '',
        type: json['type'] as String? ?? 'unit',
        name: json['name'] as String? ?? '',
        code: json['code'] as String?,
        level: (json['level'] as num?)?.toInt(),
        path: json['path'] as String? ?? '/',
        breadcrumb: json['breadcrumb'] as String? ?? '',
        resourceCount: (json['resourceCount'] as num?)?.toInt(),
      );
}
