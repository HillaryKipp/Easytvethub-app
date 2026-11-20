import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/config/env.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/empty_error_views.dart';
import '../../core/widgets/pill_badge.dart';
import '../../data/models/blog_models.dart';
import '../../data/repositories/blog_repository.dart';

class _TocEntry {
  final int level; // 2 or 3
  final String text;
  final double approximateFraction;

  const _TocEntry({
    required this.level,
    required this.text,
    required this.approximateFraction,
  });
}

class ArticleScreen extends ConsumerStatefulWidget {
  final String slug;

  const ArticleScreen({super.key, required this.slug});

  @override
  ConsumerState<ArticleScreen> createState() => _ArticleScreenState();
}

class _ArticleScreenState extends ConsumerState<ArticleScreen> {
  final _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  List<_TocEntry> _extractHeadings(String markdown) {
    final lines = markdown.split('\n');
    final entries = <_TocEntry>[];
    final total = lines.isEmpty ? 1 : lines.length;

    for (var i = 0; i < lines.length; i++) {
      final line = lines[i].trim();
      final match = RegExp(r'^(#{2,3})\s+(.+)$').firstMatch(line);
      if (match != null) {
        final level = match.group(1)!.length;
        final heading = match
            .group(2)!
            .replaceAll(RegExp(r'[*_`#]'), '')
            .trim();
        if (heading.isNotEmpty) {
          entries.add(
            _TocEntry(
              level: level,
              text: heading,
              approximateFraction: (i / total).clamp(0.0, 1.0),
            ),
          );
        }
      }
    }
    return entries;
  }

  void _showTocSheet(BuildContext context, List<_TocEntry> headings) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadii.xxl)),
      ),
      builder: (sheetCtx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.lineStrong,
                      borderRadius: BorderRadius.circular(AppRadii.pill),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    const Icon(
                      LucideIcons.list,
                      size: 18,
                      color: AppColors.purple,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Table of Contents',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Flexible(
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: headings.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (_, idx) {
                      final h = headings[idx];
                      return ListTile(
                        dense: true,
                        contentPadding: EdgeInsets.only(
                          left: h.level == 3 ? 18 : 0,
                          right: 0,
                        ),
                        title: Text(
                          h.text,
                          style: TextStyle(
                            fontSize: h.level == 2 ? 14 : 13,
                            fontWeight: h.level == 2
                                ? FontWeight.w700
                                : FontWeight.w500,
                            color: h.level == 2 ? AppColors.ink : AppColors.text,
                          ),
                        ),
                        trailing: const Icon(
                          LucideIcons.arrowDownRight,
                          size: 14,
                          color: AppColors.purple,
                        ),
                        onTap: () {
                          Navigator.of(sheetCtx).pop();
                          if (_scrollController.hasClients) {
                            final max =
                                _scrollController.position.maxScrollExtent;
                            _scrollController.animateTo(
                              (max * h.approximateFraction).clamp(0.0, max),
                              duration: const Duration(milliseconds: 350),
                              curve: Curves.easeOutCubic,
                            );
                          }
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final asyncArticle = ref.watch(articleDetailProvider(widget.slug));

    return asyncArticle.when(
      loading: () => Scaffold(
        appBar: AppBar(title: const Text('Article')),
        body: const LoadingSkeletonList(itemCount: 4, itemHeight: 120),
      ),
      error: (_, __) => Scaffold(
        appBar: AppBar(title: const Text('Article')),
        body: ErrorStateCard(
          onRetry: () => ref.invalidate(articleDetailProvider(widget.slug)),
        ),
      ),
      data: (article) {
        final headings = _extractHeadings(article.content);
        final mins = estimateReadingTimeMinutes(
          article.content,
          explicitMinutes: article.readingTimeMinutes,
        );

        return Scaffold(
          appBar: AppBar(
            title: Text(
              article.category.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            actions: [
              IconButton(
                icon: const Icon(LucideIcons.share2, size: 19),
                tooltip: 'Share Article',
                onPressed: () {
                  Share.share(
                    '${article.title}\n${Env.canonicalUrl('/blog/${article.slug}')}',
                  );
                },
              ),
            ],
          ),
          floatingActionButton: headings.isNotEmpty
              ? FloatingActionButton.extended(
                  onPressed: () => _showTocSheet(context, headings),
                  backgroundColor: AppColors.purple,
                  foregroundColor: AppColors.white,
                  icon: const Icon(LucideIcons.list, size: 18),
                  label: const Text(
                    'Contents',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                )
              : null,
          body: RefreshIndicator(
            color: AppColors.purple,
            onRefresh: () async {
              ref.invalidate(articleDetailProvider(widget.slug));
              await ref.read(articleDetailProvider(widget.slug).future);
            },
            child: ListView(
              controller: _scrollController,
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 88),
              children: [
                // Header & Byline Card
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: BorderRadius.circular(AppRadii.xxl),
                    border: Border.all(color: AppColors.line),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Wrap(
                        spacing: 8,
                        runSpacing: 6,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          PillBadge.forCategory(article.category),
                          PillBadge(
                            label: '$mins min read',
                            icon: LucideIcons.clock,
                            variant: PillVariant.neutral,
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        article.title,
                        style: Theme.of(context).textTheme.headlineMedium,
                      ),
                      if (article.excerpt != null &&
                          article.excerpt!.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text(
                          article.excerpt!,
                          style: const TextStyle(
                            fontSize: 14.5,
                            color: AppColors.text,
                            height: 1.55,
                          ),
                        ),
                      ],
                      const SizedBox(height: 14),
                      // Author Byline
                      InkWell(
                        borderRadius: BorderRadius.circular(AppRadii.md),
                        onTap: article.author != null
                            ? () => context.push(
                                '/authors/${article.author!.slug}',
                              )
                            : null,
                        child: Row(
                          children: [
                            _AuthorAvatar(author: article.author, radius: 18),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    article.author?.name ??
                                        'EasyTVET Editorial',
                                    style: const TextStyle(
                                      fontSize: 13.5,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.ink,
                                    ),
                                  ),
                                  Text(
                                    article.publishedAt != null
                                        ? 'Published ${formatDate(article.publishedAt)}'
                                        : 'Updated ${formatDate(article.updatedAt)}',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: AppColors.muted,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // 16:9 Rounded Cover Image
                if (article.coverImageUrl != null &&
                    article.coverImageUrl!.isNotEmpty) ...[
                  const SizedBox(height: 14),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(AppRadii.xl),
                    child: AspectRatio(
                      aspectRatio: 16 / 9,
                      child: CachedNetworkImage(
                        imageUrl: article.coverImageUrl!,
                        fit: BoxFit.cover,
                        placeholder: (_, __) =>
                            Container(color: AppColors.purpleTint),
                        errorWidget: (_, __, ___) => const SizedBox.shrink(),
                      ),
                    ),
                  ),
                ],

                // Markdown Content Body
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: BorderRadius.circular(AppRadii.xxl),
                    border: Border.all(color: AppColors.line),
                  ),
                  child: MarkdownBody(
                    data: article.content,
                    selectable: true,
                    onTapLink: (_, href, __) {
                      if (href == null || href.isEmpty) return;
                      if (href.startsWith('/')) {
                        context.push(href);
                      } else {
                        launchUrl(
                          Uri.parse(href),
                          mode: LaunchMode.externalApplication,
                        );
                      }
                    },
                    styleSheet: MarkdownStyleSheet(
                      h1: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: AppColors.ink,
                        height: 1.3,
                      ),
                      h2: const TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.w800,
                        color: AppColors.ink,
                        height: 1.35,
                      ),
                      h3: const TextStyle(
                        fontSize: 16.5,
                        fontWeight: FontWeight.w700,
                        color: AppColors.ink,
                        height: 1.35,
                      ),
                      p: const TextStyle(
                        fontSize: 15,
                        color: AppColors.text,
                        height: 1.7,
                      ),
                      a: const TextStyle(
                        color: AppColors.purple,
                        fontWeight: FontWeight.w600,
                        decoration: TextDecoration.underline,
                      ),
                      listBullet: const TextStyle(
                        color: AppColors.purple,
                        fontWeight: FontWeight.w700,
                      ),
                      blockquoteDecoration: BoxDecoration(
                        color: AppColors.purpleSoft,
                        borderRadius: BorderRadius.circular(AppRadii.md),
                        border: const Border(
                          left: BorderSide(color: AppColors.purple, width: 3.5),
                        ),
                      ),
                      tableHead: const TextStyle(
                        fontWeight: FontWeight.w700,
                        color: AppColors.ink,
                        fontSize: 13,
                      ),
                      tableBody: const TextStyle(
                        color: AppColors.text,
                        fontSize: 13,
                      ),
                      tableBorder: TableBorder.all(
                        color: AppColors.line,
                        borderRadius: BorderRadius.circular(AppRadii.sm),
                      ),
                      tableCellsDecoration: const BoxDecoration(
                        color: AppColors.purpleSoft,
                      ),
                      tableCellsPadding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 8,
                      ),
                      code: const TextStyle(
                        fontFamily: 'monospace',
                        backgroundColor: AppColors.purpleTint,
                        color: AppColors.purpleDark,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ),

                // Official TVET Reference Citation Box
                if ((article.sourceName != null &&
                        article.sourceName!.trim().isNotEmpty) ||
                    (article.sourceUrl != null &&
                        article.sourceUrl!.trim().isNotEmpty)) ...[
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.purpleSoft,
                      borderRadius: BorderRadius.circular(AppRadii.xl),
                      border: Border.all(color: AppColors.lineStrong),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(
                              LucideIcons.shieldCheck,
                              size: 16,
                              color: AppColors.purple,
                            ),
                            SizedBox(width: 6),
                            Text(
                              'Official TVET Reference',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                                color: AppColors.purple,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          article.sourceName ?? 'Official Source Document',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: AppColors.ink,
                          ),
                        ),
                        if (article.sourceUrl != null &&
                            article.sourceUrl!.trim().isNotEmpty) ...[
                          const SizedBox(height: 10),
                          OutlinedButton.icon(
                            onPressed: () {
                              launchUrl(
                                Uri.parse(article.sourceUrl!.trim()),
                                mode: LaunchMode.externalApplication,
                              );
                            },
                            icon: const Icon(
                              LucideIcons.externalLink,
                              size: 14,
                            ),
                            label: const Text('View Official Source'),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],

                // Author Profile Card
                if (article.author != null) ...[
                  const SizedBox(height: 14),
                  _AuthorProfileCard(author: article.author!),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}

class _AuthorAvatar extends StatelessWidget {
  final Author? author;
  final double radius;

  const _AuthorAvatar({required this.author, this.radius = 22});

  @override
  Widget build(BuildContext context) {
    final url = author?.avatarUrl;
    if (url != null && url.isNotEmpty) {
      return CircleAvatar(
        radius: radius,
        backgroundColor: AppColors.purpleTint,
        backgroundImage: CachedNetworkImageProvider(url),
      );
    }
    final initial = (author?.name ?? 'E').trim().isNotEmpty
        ? (author?.name ?? 'E').trim()[0].toUpperCase()
        : 'E';
    return CircleAvatar(
      radius: radius,
      backgroundColor: AppColors.purpleTint,
      child: Text(
        initial,
        style: TextStyle(
          fontSize: radius * 0.85,
          fontWeight: FontWeight.w800,
          color: AppColors.purple,
        ),
      ),
    );
  }
}

class _AuthorProfileCard extends StatelessWidget {
  final Author author;
  const _AuthorProfileCard({required this.author});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppRadii.xxl),
        border: Border.all(color: AppColors.line),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadii.xxl),
        onTap: () => context.push('/authors/${author.slug}'),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _AuthorAvatar(author: author, radius: 24),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          author.name,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: AppColors.ink,
                          ),
                        ),
                      ),
                      if (author.isVerified) ...[
                        const SizedBox(width: 5),
                        const Icon(
                          LucideIcons.badgeCheck,
                          size: 16,
                          color: AppColors.purple,
                        ),
                      ],
                    ],
                  ),
                  if (author.role != null && author.role!.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      author.role!,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.purple,
                      ),
                    ),
                  ],
                  if (author.bio != null && author.bio!.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      author.bio!,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                  const SizedBox(height: 8),
                  const Text(
                    'View all articles by this author →',
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      color: AppColors.purple,
                    ),
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
