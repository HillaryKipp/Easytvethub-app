import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/brand_logo.dart';
import '../../core/widgets/empty_error_views.dart';
import '../../core/widgets/pill_badge.dart';
import '../../data/models/blog_models.dart';
import '../../data/models/directory_models.dart';
import '../../data/repositories/directory_repository.dart';

enum _HomeDeptFilter {
  all('All Courses'),
  modular('Modular CDACC'),
  nonModular('Non Modular CDACC'),
  knec('KNEC');

  final String label;
  const _HomeDeptFilter(this.label);
}

class _MergedDepartmentGroup {
  final String displayName;
  final String? singleDepartmentPath;
  final List<({Course course, Department dept, Programme? prog})> entries;

  const _MergedDepartmentGroup({
    required this.displayName,
    this.singleDepartmentPath,
    required this.entries,
  });
}

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  _HomeDeptFilter _deptFilter = _HomeDeptFilter.all;
  final Set<String> _expandedDeptKeys = {};

  @override
  Widget build(BuildContext context) {
    final homeAsync = ref.watch(homeDirectoryProvider);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(LucideIcons.menu, size: 22),
          tooltip: 'Menu',
          onPressed: () {
            Scaffold.maybeOf(context)?.openDrawer();
          },
        ),
        title: const BrandLogo(height: 30),
        actions: [
          IconButton(
            icon: Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: AppColors.purpleTint,
                borderRadius: BorderRadius.circular(AppRadii.pill),
              ),
              child: const Icon(
                LucideIcons.search,
                size: 18,
                color: AppColors.purple,
              ),
            ),
            tooltip: 'Search Past Papers',
            onPressed: () => context.push('/search'),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: homeAsync.when(
        loading: () => const LoadingSkeletonList(itemCount: 5, itemHeight: 110),
        error: (err, _) => ErrorStateCard(
          message:
              'Could not reach EasyTVET Hub right now. Pull down or tap retry.',
          onRetry: () => ref.invalidate(homeDirectoryProvider),
        ),
        data: (data) => RefreshIndicator(
          color: AppColors.purple,
          onRefresh: () async {
            ref.invalidate(homeDirectoryProvider);
            await ref.read(homeDirectoryProvider.future);
          },
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
            children: [
              _HeroLevelBanner(
                onLevelTap: (lvl) => context.push('/levels/level-$lvl'),
                onSearchTap: () => context.push('/search'),
              ),
              const SizedBox(height: 18),
              _ServiceCardsGrid(programmes: data.programmes),
              const SizedBox(height: 20),
              _buildDepartmentsAccordion(data),
              if (data.latestArticles.isNotEmpty) ...[
                const SizedBox(height: 20),
                _LatestArticlesSection(articles: data.latestArticles),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDepartmentsAccordion(HomeDirectoryData data) {
    final progMap = {for (final p in data.programmes) p.id: p};
    final groups = _buildDepartmentGroups(data.departments, progMap);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppRadii.xxl),
        border: Border.all(color: AppColors.line),
        boxShadow: AppColors.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: double.infinity,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  'Academic Departments',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 2),
                Text(
                  'Browse CDACC & KNEC courses by department',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          // Horizontal slider for department framework filters
          SizedBox(
            height: 38,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              physics: const ClampingScrollPhysics(),
              itemCount: _HomeDeptFilter.values.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final filter = _HomeDeptFilter.values[index];
                final active = _deptFilter == filter;
                return InkWell(
                  borderRadius: BorderRadius.circular(AppRadii.pill),
                  onTap: () {
                    setState(() {
                      _deptFilter = filter;
                      _expandedDeptKeys.clear();
                    });
                    Scrollable.ensureVisible(
                      context,
                      duration: const Duration(milliseconds: 200),
                      alignment: 0.5,
                    );
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 160),
                    alignment: Alignment.center,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: active ? AppColors.purple : AppColors.surface,
                      borderRadius: BorderRadius.circular(AppRadii.pill),
                      border: Border.all(
                        color: active ? AppColors.purple : AppColors.line,
                      ),
                    ),
                    child: Text(
                      filter.label,
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        color: active ? AppColors.white : AppColors.text,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 14),
          if (groups.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Center(
                child: Text(
                  'No departments found for this framework.',
                  style: TextStyle(color: AppColors.muted, fontSize: 13),
                ),
              ),
            )
          else
            ...groups.asMap().entries.map((entry) {
              final idx = entry.key;
              final group = entry.value;
              final key = '${_deptFilter.name}_${group.displayName}';
              final isOpen = _expandedDeptKeys.contains(key);

              return Container(
                margin: EdgeInsets.only(
                  bottom: idx == groups.length - 1 ? 0 : 10,
                ),
                decoration: BoxDecoration(
                  color: AppColors.purpleSoft,
                  borderRadius: BorderRadius.circular(AppRadii.lg),
                  border: Border.all(color: AppColors.line),
                ),
                child: Column(
                  children: [
                    InkWell(
                      borderRadius: BorderRadius.circular(AppRadii.lg),
                      onTap: () {
                        setState(() {
                          if (isOpen) {
                            _expandedDeptKeys.remove(key);
                          } else {
                            _expandedDeptKeys.add(key);
                          }
                        });
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 13,
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                toTitleCase(group.displayName),
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.ink,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 9,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.white,
                                borderRadius: BorderRadius.circular(
                                  AppRadii.pill,
                                ),
                                border: Border.all(color: AppColors.line),
                              ),
                              child: Text(
                                '${group.entries.length}',
                                style: const TextStyle(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.purple,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            AnimatedRotation(
                              turns: isOpen ? 0.5 : 0,
                              duration: const Duration(milliseconds: 200),
                              child: const Icon(
                                LucideIcons.chevronDown,
                                size: 18,
                                color: AppColors.purple,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    if (isOpen) ...[
                      const Divider(height: 1),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
                        child: Column(
                          children: [
                            ...group.entries.map((item) {
                              final progSlug =
                                  item.prog?.slug ??
                                  item.dept.programme?.slug ??
                                  '';
                              final coursePath =
                                  '/$progSlug/${item.dept.slug}/${item.course.slug}';
                              final progLabel = programmeShortLabel(
                                progSlug,
                                fallbackName: item.prog?.name,
                              );

                              return Container(
                                margin: const EdgeInsets.only(bottom: 8),
                                decoration: BoxDecoration(
                                  color: AppColors.white,
                                  borderRadius: BorderRadius.circular(
                                    AppRadii.md,
                                  ),
                                  border: Border.all(color: AppColors.line),
                                ),
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(
                                    AppRadii.md,
                                  ),
                                  onTap: () => context.push(coursePath),
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 10,
                                    ),
                                    child: Row(
                                      children: [
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                toTitleCase(item.course.name),
                                                style: const TextStyle(
                                                  fontSize: 13.5,
                                                  fontWeight: FontWeight.w600,
                                                  color: AppColors.ink,
                                                ),
                                              ),
                                              const SizedBox(height: 5),
                                              Wrap(
                                                spacing: 6,
                                                runSpacing: 4,
                                                children: [
                                                  PillBadge(
                                                    label: progLabel,
                                                    variant: PillVariant.purple,
                                                    padding:
                                                        const EdgeInsets.symmetric(
                                                          horizontal: 8,
                                                          vertical: 2,
                                                        ),
                                                  ),
                                                  if (item.course.level != null)
                                                    PillBadge(
                                                      label:
                                                          'L${item.course.level}',
                                                      variant: PillVariant.red,
                                                      padding:
                                                          const EdgeInsets.symmetric(
                                                            horizontal: 8,
                                                            vertical: 2,
                                                          ),
                                                    ),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ),
                                        const Icon(
                                          LucideIcons.chevronRight,
                                          size: 16,
                                          color: AppColors.muted,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            }),
                            if (group.singleDepartmentPath != null)
                              Align(
                                alignment: Alignment.centerRight,
                                child: TextButton.icon(
                                  onPressed: () =>
                                      context.push(group.singleDepartmentPath!),
                                  icon: const Text(
                                    'View Full Department',
                                    style: TextStyle(
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.purple,
                                    ),
                                  ),
                                  label: const Icon(
                                    LucideIcons.arrowRight,
                                    size: 14,
                                    color: AppColors.purple,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }

  List<_MergedDepartmentGroup> _buildDepartmentGroups(
    List<Department> departments,
    Map<String, Programme> progMap,
  ) {
    bool matchesFilter(Programme? prog) {
      final slug = prog?.slug.toLowerCase() ?? '';
      return switch (_deptFilter) {
        _HomeDeptFilter.all => true,
        _HomeDeptFilter.modular => slug.contains('modular'),
        _HomeDeptFilter.nonModular =>
          !slug.contains('modular') && !slug.contains('knec'),
        _HomeDeptFilter.knec => slug.contains('knec'),
      };
    }

    final filteredDepts = departments.where((d) {
      final prog = d.programme ?? progMap[d.programmeId];
      return matchesFilter(prog) && d.courses.isNotEmpty;
    }).toList();

    if (_deptFilter == _HomeDeptFilter.all) {
      final merged =
          <String, List<({Course course, Department dept, Programme? prog})>>{};
      final displayNames = <String, String>{};
      final singlePaths = <String, String?>{};

      for (final dept in filteredDepts) {
        final normKey = normalizeDepartmentName(dept.name);
        final prog = dept.programme ?? progMap[dept.programmeId];
        displayNames.putIfAbsent(normKey, () => dept.name);

        final path = prog != null ? '/${prog.slug}/${dept.slug}' : null;
        if (!singlePaths.containsKey(normKey)) {
          singlePaths[normKey] = path;
        } else {
          singlePaths[normKey] = null; // merged across multiple frameworks
        }

        final list = merged.putIfAbsent(normKey, () => []);
        for (final c in dept.courses) {
          list.add((course: c, dept: dept, prog: prog));
        }
      }

      return merged.entries.map((e) {
        final sorted = [...e.value]
          ..sort((a, b) => a.course.name.compareTo(b.course.name));
        return _MergedDepartmentGroup(
          displayName: displayNames[e.key] ?? e.key,
          singleDepartmentPath: singlePaths[e.key],
          entries: sorted,
        );
      }).toList()
        ..sort((a, b) => a.displayName.compareTo(b.displayName));
    }

    return filteredDepts.map((dept) {
      final prog = dept.programme ?? progMap[dept.programmeId];
      final entries = dept.courses
          .map((c) => (course: c, dept: dept, prog: prog))
          .toList()
        ..sort((a, b) => a.course.name.compareTo(b.course.name));
      return _MergedDepartmentGroup(
        displayName: dept.name,
        singleDepartmentPath: prog != null
            ? '/${prog.slug}/${dept.slug}'
            : null,
        entries: entries,
      );
    }).toList();
  }
}

class _HeroLevelBanner extends StatelessWidget {
  final ValueChanged<int> onLevelTap;
  final VoidCallback onSearchTap;

  const _HeroLevelBanner({
    required this.onLevelTap,
    required this.onSearchTap,
  });

  @override
  Widget build(BuildContext context) {
    const levels = [3, 4, 5, 6];
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: AppColors.heroGradient,
        borderRadius: BorderRadius.circular(AppRadii.xl),
        boxShadow: AppColors.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              for (int i = 0; i < levels.length; i++) ...[
                if (i > 0) const SizedBox(width: 8),
                Expanded(
                  child: InkWell(
                    borderRadius: BorderRadius.circular(AppRadii.pill),
                    onTap: () => onLevelTap(levels[i]),
                    child: Container(
                      alignment: Alignment.center,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(AppRadii.pill),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.35),
                        ),
                      ),
                      child: Text(
                        'Level ${levels[i]}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppColors.white,
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: onSearchTap,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.red,
                foregroundColor: AppColors.white,
                padding: const EdgeInsets.symmetric(vertical: 13),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadii.pill),
                ),
              ),
              icon: const Icon(LucideIcons.search, size: 17),
              label: const Text(
                'Search',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ServiceCardsGrid extends StatelessWidget {
  final List<Programme> programmes;

  const _ServiceCardsGrid({required this.programmes});

  Programme? _findByPredicate(bool Function(Programme p) test) {
    for (final p in programmes) {
      if (test(p)) return p;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final modularProg = _findByPredicate((p) => p.isModular);
    final nonModularProg = _findByPredicate((p) => !p.isModular && !p.isKnec);
    final knecProg = _findByPredicate((p) => p.isKnec);

    final cards = [
      _ServiceCardItem(
        title: 'Modular CDACC',
        description: 'Cycle 3 CBET modular courses, tools & past papers.',
        cta: 'Explore Cycle 3',
        accent: AppColors.purple,
        onTap: () {
          final slug = modularProg?.slug ?? 'modular-cdacc-courses-cycle-3';
          context.push('/$slug');
        },
      ),
      _ServiceCardItem(
        title: 'CDACC Cycle 1 & 2',
        description: 'Non-modular CBET curricula & assessment guides.',
        cta: 'Explore Cycle 1 & 2',
        accent: AppColors.teal,
        onTap: () {
          final slug = nonModularProg?.slug ?? 'non-modular-cdacc-courses';
          context.push('/$slug');
        },
      ),
      _ServiceCardItem(
        title: 'KNEC Courses',
        description: 'Diploma, Certificate & Artisan KNEC past papers.',
        cta: 'Explore KNEC',
        accent: AppColors.amber,
        onTap: () {
          final slug = knecProg?.slug ?? 'knec-courses';
          context.push('/$slug');
        },
      ),
      _ServiceCardItem(
        title: 'TVET News & Guides',
        description: 'Exam dates, circulars & CBET revision strategies.',
        cta: 'Read Latest News',
        accent: AppColors.red,
        onTap: () => context.push('/blog'),
      ),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: cards.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.22,
      ),
      itemBuilder: (context, index) => _ServiceCard(item: cards[index]),
    );
  }
}

class _ServiceCardItem {
  final String title;
  final String description;
  final String cta;
  final Color accent;
  final VoidCallback onTap;

  const _ServiceCardItem({
    required this.title,
    required this.description,
    required this.cta,
    required this.accent,
    required this.onTap,
  });
}

class _ServiceCard extends StatelessWidget {
  final _ServiceCardItem item;
  const _ServiceCard({required this.item});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppRadii.lg),
        border: Border.all(color: AppColors.line),
        boxShadow: AppColors.cardShadow,
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadii.lg),
        onTap: item.onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                item.title,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: AppColors.ink,
                ),
              ),
              const SizedBox(height: 6),
              Expanded(
                child: Text(
                  item.description,
                  textAlign: TextAlign.center,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.text,
                    height: 1.4,
                  ),
                ),
              ),
              const Divider(height: 14),
              Text(
                item.cta,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: item.accent,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LatestArticlesSection extends StatelessWidget {
  final List<Article> articles;

  const _LatestArticlesSection({required this.articles});

  @override
  Widget build(BuildContext context) {
    final visibleArticles = articles.take(3).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Latest Articles & Circulars',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 10),
        ...visibleArticles.asMap().entries.map((entry) {
          final index = entry.key;
          final article = entry.value;
          final mins = estimateReadingTimeMinutes(
            article.content,
            explicitMinutes: article.readingTimeMinutes,
          );

          return Padding(
            padding: EdgeInsets.only(
              bottom: index == visibleArticles.length - 1 ? 0 : 8,
            ),
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(AppRadii.lg),
                border: Border.all(color: AppColors.line),
                boxShadow: AppColors.cardShadow,
              ),
              child: InkWell(
                borderRadius: BorderRadius.circular(AppRadii.lg),
                onTap: () => context.push('/blog/${article.slug}'),
                child: Padding(
                  padding: const EdgeInsets.all(10),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(AppRadii.md),
                        child: SizedBox(
                          width: 72,
                          height: 64,
                          child: article.coverImageUrl != null &&
                                  article.coverImageUrl!.isNotEmpty
                              ? CachedNetworkImage(
                                  imageUrl: article.coverImageUrl!,
                                  fit: BoxFit.cover,
                                  placeholder: (_, __) => Container(
                                    color: AppColors.purpleTint,
                                  ),
                                  errorWidget: (_, __, ___) =>
                                      _ArticleImageFallback(),
                                )
                              : _ArticleImageFallback(),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Row(
                              children: [
                                PillBadge.forCategory(article.category),
                                const Spacer(),
                                Text(
                                  '$mins min',
                                  style: const TextStyle(
                                    fontSize: 10.5,
                                    color: AppColors.muted,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              article.title,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: AppColors.ink,
                                height: 1.25,
                              ),
                            ),
                            if (article.publishedAt != null) ...[
                              const SizedBox(height: 3),
                              Text(
                                formatDate(article.publishedAt),
                                style: const TextStyle(
                                  fontSize: 10.5,
                                  color: AppColors.muted,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }),
        const SizedBox(height: 6),
        Center(
          child: TextButton(
            onPressed: () => context.push('/blog'),
            child: const Text(
              'View All Articles →',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppColors.purple,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _ArticleImageFallback extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(gradient: AppColors.heroGradient),
      child: const Center(
        child: Icon(LucideIcons.bookOpen, color: Colors.white70, size: 28),
      ),
    );
  }
}
