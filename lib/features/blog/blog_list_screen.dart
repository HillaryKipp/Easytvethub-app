import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/empty_error_views.dart';
import '../../core/widgets/pill_badge.dart';
import '../../data/models/blog_models.dart';
import '../../data/repositories/blog_repository.dart';

class BlogListScreen extends ConsumerStatefulWidget {
  const BlogListScreen({super.key});

  @override
  ConsumerState<BlogListScreen> createState() => _BlogListScreenState();
}

class _BlogListScreenState extends ConsumerState<BlogListScreen> {
  ArticleCategory? _selectedCategory;

  @override
  Widget build(BuildContext context) {
    final asyncArticles = ref.watch(blogArticlesProvider(_selectedCategory));

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(LucideIcons.menu, size: 22),
          onPressed: () => Scaffold.maybeOf(context)?.openDrawer(),
        ),
        title: const Text('TVET News & Guides'),
      ),
      body: Column(
        children: [
          Container(
            color: AppColors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _CategoryChip(
                    label: 'All',
                    selected: _selectedCategory == null,
                    onTap: () => setState(() => _selectedCategory = null),
                  ),
                  ...ArticleCategory.values.map(
                    (cat) => _CategoryChip(
                      label: cat.label,
                      selected: _selectedCategory == cat,
                      onTap: () => setState(() => _selectedCategory = cat),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: asyncArticles.when(
              loading: () =>
                  const LoadingSkeletonList(itemCount: 4, itemHeight: 160),
              error: (_, __) => ErrorStateCard(
                onRetry: () =>
                    ref.invalidate(blogArticlesProvider(_selectedCategory)),
              ),
              data: (articles) {
                if (articles.isEmpty) {
                  return EmptyStateCard(
                    icon: LucideIcons.newspaper,
                    title: 'No articles in this category yet',
                    message:
                        'Switch back to All to browse the latest CDACC & KNEC exam guides.',
                    actionLabel: 'Show All Articles',
                    onAction: () => setState(() => _selectedCategory = null),
                  );
                }

                final featured = articles.first;
                final rest = articles.skip(1).toList();

                return RefreshIndicator(
                  color: AppColors.purple,
                  onRefresh: () async {
                    ref.invalidate(blogArticlesProvider(_selectedCategory));
                    await ref.read(
                      blogArticlesProvider(_selectedCategory).future,
                    );
                  },
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
                    children: [
                      // Featured Article Hero Card (#F8F5FD)
                      _FeaturedArticleCard(article: featured),
                      if (rest.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        ...rest.map(
                          (article) => Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: _ArticleListCard(article: article),
                          ),
                        ),
                      ],
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _CategoryChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadii.pill),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
          decoration: BoxDecoration(
            color: selected ? AppColors.purple : AppColors.surface,
            borderRadius: BorderRadius.circular(AppRadii.pill),
            border: Border.all(
              color: selected ? AppColors.purple : AppColors.line,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
              color: selected ? AppColors.white : AppColors.text,
            ),
          ),
        ),
      ),
    );
  }
}

class _FeaturedArticleCard extends StatelessWidget {
  final Article article;
  const _FeaturedArticleCard({required this.article});

  @override
  Widget build(BuildContext context) {
    final mins = estimateReadingTimeMinutes(
      article.content,
      explicitMinutes: article.readingTimeMinutes,
    );

    return Container(
      decoration: BoxDecoration(
        color: AppColors.purpleSoft,
        borderRadius: BorderRadius.circular(AppRadii.xxl),
        border: Border.all(color: AppColors.line),
        boxShadow: AppColors.cardShadow,
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadii.xxl),
        onTap: () => context.push('/blog/${article.slug}'),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(AppRadii.xxl),
              ),
              child: AspectRatio(
                aspectRatio: 16 / 9,
                child: article.coverImageUrl != null &&
                        article.coverImageUrl!.isNotEmpty
                    ? CachedNetworkImage(
                        imageUrl: article.coverImageUrl!,
                        fit: BoxFit.cover,
                        placeholder: (_, __) =>
                            Container(color: AppColors.purpleTint),
                        errorWidget: (_, __, ___) => _CoverFallback(),
                      )
                    : _CoverFallback(),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const PillBadge(
                        label: 'FEATURED',
                        variant: PillVariant.solidPurple,
                      ),
                      const SizedBox(width: 8),
                      PillBadge.forCategory(article.category),
                      const Spacer(),
                      Text(
                        '$mins min read',
                        style: const TextStyle(
                          fontSize: 11.5,
                          color: AppColors.muted,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    article.title,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  if (article.excerpt != null &&
                      article.excerpt!.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      article.excerpt!,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Text(
                        article.author?.name ?? 'EasyTVET Editorial',
                        style: const TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                          color: AppColors.purple,
                        ),
                      ),
                      if (article.publishedAt != null) ...[
                        const Text(
                          ' • ',
                          style: TextStyle(color: AppColors.muted),
                        ),
                        Text(
                          formatDate(article.publishedAt),
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.muted,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ArticleListCard extends StatelessWidget {
  final Article article;
  const _ArticleListCard({required this.article});

  @override
  Widget build(BuildContext context) {
    final mins = estimateReadingTimeMinutes(
      article.content,
      explicitMinutes: article.readingTimeMinutes,
    );

    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppRadii.lg),
        border: Border.all(color: AppColors.line),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadii.lg),
        onTap: () => context.push('/blog/${article.slug}'),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(AppRadii.md),
                child: SizedBox(
                  width: 96,
                  height: 88,
                  child: article.coverImageUrl != null &&
                          article.coverImageUrl!.isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: article.coverImageUrl!,
                          fit: BoxFit.cover,
                          placeholder: (_, __) =>
                              Container(color: AppColors.purpleTint),
                          errorWidget: (_, __, ___) => _CoverFallback(),
                        )
                      : _CoverFallback(),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        PillBadge.forCategory(article.category),
                        const Spacer(),
                        Text(
                          '$mins min',
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.muted,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      article.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.ink,
                        height: 1.3,
                      ),
                    ),
                    if (article.excerpt != null &&
                        article.excerpt!.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        article.excerpt!,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.text,
                          height: 1.35,
                        ),
                      ),
                    ],
                    const SizedBox(height: 6),
                    Text(
                      '${article.author?.name ?? 'EasyTVET Editorial'}${article.publishedAt != null ? ' • ${formatDate(article.publishedAt)}' : ''}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.muted,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CoverFallback extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(gradient: AppColors.heroGradient),
      child: const Center(
        child: Icon(LucideIcons.bookOpen, color: Colors.white70, size: 24),
      ),
    );
  }
}
