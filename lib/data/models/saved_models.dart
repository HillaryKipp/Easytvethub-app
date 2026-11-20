class DownloadedPdf {
  final String resourceId;
  final String title;
  final String unitName;
  final String courseName;
  final String resourceTypeLabel;
  final int? year;
  final String localPath;
  final String originalUrl;
  final String? webPath;
  final DateTime downloadedAt;

  const DownloadedPdf({
    required this.resourceId,
    required this.title,
    required this.unitName,
    required this.courseName,
    required this.resourceTypeLabel,
    this.year,
    required this.localPath,
    required this.originalUrl,
    this.webPath,
    required this.downloadedAt,
  });

  Map<String, dynamic> toJson() => {
        'resourceId': resourceId,
        'title': title,
        'unitName': unitName,
        'courseName': courseName,
        'resourceTypeLabel': resourceTypeLabel,
        'year': year,
        'localPath': localPath,
        'originalUrl': originalUrl,
        'webPath': webPath,
        'downloadedAt': downloadedAt.toIso8601String(),
      };

  factory DownloadedPdf.fromJson(Map<String, dynamic> json) => DownloadedPdf(
        resourceId: json['resourceId'] as String,
        title: json['title'] as String,
        unitName: json['unitName'] as String? ?? '',
        courseName: json['courseName'] as String? ?? '',
        resourceTypeLabel: json['resourceTypeLabel'] as String? ?? 'PDF',
        year: (json['year'] as num?)?.toInt(),
        localPath: json['localPath'] as String,
        originalUrl: json['originalUrl'] as String? ?? '',
        webPath: json['webPath'] as String?,
        downloadedAt:
            DateTime.tryParse(json['downloadedAt'] as String? ?? '') ??
            DateTime.now(),
      );
}

class SavedBookmark {
  final String id;
  final String type; // 'course' | 'unit'
  final String title;
  final String subtitle;
  final String path;
  final int? level;
  final DateTime savedAt;

  const SavedBookmark({
    required this.id,
    required this.type,
    required this.title,
    required this.subtitle,
    required this.path,
    this.level,
    required this.savedAt,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type,
        'title': title,
        'subtitle': subtitle,
        'path': path,
        'level': level,
        'savedAt': savedAt.toIso8601String(),
      };

  factory SavedBookmark.fromJson(Map<String, dynamic> json) => SavedBookmark(
        id: json['id'] as String,
        type: json['type'] as String? ?? 'course',
        title: json['title'] as String,
        subtitle: json['subtitle'] as String? ?? '',
        path: json['path'] as String,
        level: (json['level'] as num?)?.toInt(),
        savedAt:
            DateTime.tryParse(json['savedAt'] as String? ?? '') ??
            DateTime.now(),
      );
}
