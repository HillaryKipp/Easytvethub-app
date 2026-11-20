import '../../core/config/env.dart';

enum ArticleCategory {
  examNews('exam_news', 'Exam News'),
  revisionGuide('revision_guide', 'Revision Guide'),
  courseSpotlight('course_spotlight', 'Course Spotlight'),
  curriculumUpdate('curriculum_update', 'CBET Curriculum');

  final String dbValue;
  final String label;
  const ArticleCategory(this.dbValue, this.label);

  static ArticleCategory fromDb(String? value) => ArticleCategory.values
      .firstWhere((e) => e.dbValue == value, orElse: () => revisionGuide);
}

class Author {
  final String id;
  final String name;
  final String slug;
  final String? role;
  final String? bio;
  final String? avatarUrl;
  final bool isVerified;

  const Author({
    required this.id,
    required this.name,
    required this.slug,
    this.role,
    this.bio,
    this.avatarUrl,
    this.isVerified = true,
  });

  factory Author.fromJson(Map<String, dynamic> json) => Author(
        id: json['id'] as String,
        name: json['name'] as String? ?? 'EasyTVET Editorial',
        slug: json['slug'] as String? ?? 'editorial',
        role: json['role_title'] as String? ?? json['role'] as String?,
        bio: json['bio'] as String?,
        avatarUrl: json['avatar_url'] as String?,
        isVerified: json['is_verified'] as bool? ?? true,
      );
}

class Article {
  final String id;
  final String title;
  final String slug;
  final String? excerpt;
  final String content;
  final String? coverImageUrl;
  final ArticleCategory category;
  final int? readingTimeMinutes;
  final String? sourceName;
  final String? sourceUrl;
  final bool published;
  final DateTime? publishedAt;
  final DateTime updatedAt;
  final Author? author;

  const Article({
    required this.id,
    required this.title,
    required this.slug,
    this.excerpt,
    required this.content,
    this.coverImageUrl,
    required this.category,
    this.readingTimeMinutes,
    this.sourceName,
    this.sourceUrl,
    this.published = true,
    this.publishedAt,
    required this.updatedAt,
    this.author,
  });

  factory Article.fromJson(Map<String, dynamic> json) {
    final rawImage =
        (json['featured_image_url'] as String? ??
                json['cover_image_url'] as String? ??
                json['cover_image'] as String?)
            ?.trim();
    final resolvedImage = rawImage == null || rawImage.isEmpty
        ? null
        : (rawImage.startsWith('/') ? Env.canonicalUrl(rawImage) : rawImage);

    return Article(
      id: json['id'] as String,
      title: json['title'] as String,
      slug: json['slug'] as String,
      excerpt: json['excerpt'] as String?,
      content: json['content'] as String? ?? '',
      coverImageUrl: resolvedImage,
      category: ArticleCategory.fromDb(json['category'] as String?),
      readingTimeMinutes:
          (json['reading_time_minutes'] as num?)?.toInt() ??
          (json['reading_time'] as num?)?.toInt(),
      sourceName: json['source_name'] as String?,
      sourceUrl: json['source_url'] as String?,
      published: json['published'] as bool? ?? true,
      publishedAt: DateTime.tryParse(json['published_at'] as String? ?? ''),
      updatedAt:
          DateTime.tryParse(json['updated_at'] as String? ?? '') ??
          DateTime.now(),
      author: json['author'] is Map<String, dynamic>
          ? Author.fromJson(json['author'] as Map<String, dynamic>)
          : null,
    );
  }
}
