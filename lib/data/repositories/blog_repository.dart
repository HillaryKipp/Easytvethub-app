import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/config/supabase_client.dart';
import '../models/blog_models.dart';

class AuthorDetailData {
  final Author author;
  final List<Article> articles;

  const AuthorDetailData({required this.author, required this.articles});
}

class BlogRepository {
  final SupabaseClient _client;

  BlogRepository(this._client);

  Future<List<Article>> getArticles({ArticleCategory? category}) async {
    var query = _client
        .from('articles')
        .select('*, author:authors(*)')
        .eq('published', true);

    if (category != null) {
      query = query.eq('category', category.dbValue);
    }

    final rows = await query.order('published_at', ascending: false);
    return (rows as List<dynamic>)
        .whereType<Map<String, dynamic>>()
        .map(Article.fromJson)
        .toList();
  }

  Future<Article> getArticleBySlug(String slug) async {
    final row = await _client
        .from('articles')
        .select('*, author:authors(*)')
        .eq('slug', slug)
        .eq('published', true)
        .single();
    return Article.fromJson(row);
  }

  Future<AuthorDetailData> getAuthorBySlug(String slug) async {
    final authorRow = await _client
        .from('authors')
        .select('*')
        .eq('slug', slug)
        .single();
    final author = Author.fromJson(authorRow);

    final articleRows = await _client
        .from('articles')
        .select('*, author:authors(*)')
        .eq('author_id', author.id)
        .eq('published', true)
        .order('published_at', ascending: false);

    final articles = (articleRows as List<dynamic>)
        .whereType<Map<String, dynamic>>()
        .map(Article.fromJson)
        .toList();

    return AuthorDetailData(author: author, articles: articles);
  }
}

final blogRepositoryProvider = Provider<BlogRepository>((ref) {
  return BlogRepository(ref.watch(supabaseClientProvider));
});

final blogArticlesProvider =
    FutureProvider.family<List<Article>, ArticleCategory?>((
      ref,
      category,
    ) async {
      return ref.watch(blogRepositoryProvider).getArticles(category: category);
    });

final articleDetailProvider = FutureProvider.family<Article, String>((
  ref,
  slug,
) async {
  return ref.watch(blogRepositoryProvider).getArticleBySlug(slug);
});

final authorDetailProvider = FutureProvider.family<AuthorDetailData, String>((
  ref,
  slug,
) async {
  return ref.watch(blogRepositoryProvider).getAuthorBySlug(slug);
});
