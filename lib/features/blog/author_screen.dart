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
import '../../data/repositories/blog_repository.dart';

class AuthorScreen extends ConsumerWidget {
  final String slug;

  const AuthorScreen({super.key, required this.slug});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncData = ref.watch(authorDetailProvider(slug));

    return Scaffold(
      appBar: AppBar(
        title: Text(asyncData.valueOrNull?.author.name ?? 'Author Profile'),
      ),
      body: asyncData.when(
        loading: () => const LoadingSkeletonList(itemCount: 4, itemHeight: 110),
        error: (_, __) => ErrorStateCard(
          onRetry: () => ref.invalidate(authorDetailProvider(slug)),
        ),
        data: (data) {
          final author = data.author;
          return RefreshIndicator(
            color: AppColors.purple,
            onRefresh: () async {
              ref.invalidate(authorDetailProvider(slug));
              await ref.read(authorDetailProvider(slug).future);
            },
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: BorderRadius.circular(AppRadii.xxl),
                    border: Border.all(color: AppColors.line),
                  ),
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: 36,
                        backgroundColor: AppColors.purpleTint,
                        backgroundImage: author.avatarUrl != null &&
                                author.avatarUrl!.isNotEmpty
                            ? CachedNetworkImageProvider(author.avatarUrl!)
                            : null,
                        child: author.avatarUrl == null ||
                                author.avatarUrl!.isEmpty
                            ? Text(
                                author.name.isNotEmpty
                                    ? author.name[0].toUpperCase()
                                    : 'E',
                                style: const TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.purple,
                                ),
                              )
                            : null,
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Flexible(
                            child: Text(
                              author.name,
                              textAlign: TextAlign.center,
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                          ),
                          if (author.isVerified) ...[
                            const SizedBox(width: 6),
                            const Icon(
                              LucideIcons.badgeCheck,
                              size: 18,
                              color: AppColors.purple,
                            ),
                          ],
                        ],
                      ),
                      if (author.role != null && author.role!.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        PillBadge(
                          label: author.role!,
                          variant: PillVariant.purple,
                        ),
                      ],
                      if (author.bio != null && author.bio!.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        Text(
                          author.bio!,
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  'Published Articles (${data.articles.length})',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 10),
                if (data.articles.isEmpty)
                  const EmptyStateCard(
                    icon: LucideIcons.bookOpen,
                    title: 'No published articles yet',
                    message: 'Check back soon for new guides from this author.',
                  )
                else
                  ...data.articles.map(
                    (article) => Container(
                      margin: const EdgeInsets.only(bottom: 10),
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
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  PillBadge.forCategory(article.category),
                                  const Spacer(),
                                  if (article.publishedAt != null)
                                    Text(
                                      formatDate(article.publishedAt),
                                      style: const TextStyle(
                                        fontSize: 11.5,
                                        color: AppColors.muted,
                                      ),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                article.title,
                                style: const TextStyle(
                                  fontSize: 14.5,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.ink,
                                ),
                              ),
                              if (article.excerpt != null &&
                                  article.excerpt!.isNotEmpty) ...[
                                const SizedBox(height: 4),
                                Text(
                                  article.excerpt!,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: Theme.of(context).textTheme.bodyMedium,
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}
