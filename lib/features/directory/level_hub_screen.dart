import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/empty_error_views.dart';
import '../../core/widgets/pill_badge.dart';
import '../../data/models/directory_models.dart';
import '../../data/repositories/directory_repository.dart';

class LevelHubScreen extends ConsumerStatefulWidget {
  final int level;

  const LevelHubScreen({super.key, required this.level});

  @override
  ConsumerState<LevelHubScreen> createState() => _LevelHubScreenState();
}

class _LevelHubScreenState extends ConsumerState<LevelHubScreen> {
  String _frameworkFilter = 'all'; // all | modular | non_modular | knec

  @override
  Widget build(BuildContext context) {
    final asyncCourses = ref.watch(levelCoursesProvider(widget.level));
    final knecTier = getKnecTierName(widget.level);

    return Scaffold(
      appBar: AppBar(
        title: Text('KNQF Level ${widget.level} Courses'),
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.search, size: 20),
            onPressed: () => context.push('/search'),
          ),
        ],
      ),
      body: asyncCourses.when(
        loading: () => const LoadingSkeletonList(itemCount: 6, itemHeight: 92),
        error: (err, _) => ErrorStateCard(
          onRetry: () => ref.invalidate(levelCoursesProvider(widget.level)),
        ),
        data: (courses) {
          final filtered = courses.where((c) {
            final slug = c.department?.programme?.slug.toLowerCase() ?? '';
            return switch (_frameworkFilter) {
              'modular' => slug.contains('modular'),
              'non_modular' =>
                !slug.contains('modular') && !slug.contains('knec'),
              'knec' => slug.contains('knec'),
              _ => true,
            };
          }).toList();

          // Group by normalized department name
          final grouped = <String, List<Course>>{};
          for (final c in filtered) {
            final deptName = c.department?.name ?? 'General Department';
            final key = toTitleCase(deptName);
            grouped.putIfAbsent(key, () => []).add(c);
          }
          final sortedGroups = grouped.entries.toList()
            ..sort((a, b) => a.key.compareTo(b.key));

          return RefreshIndicator(
            color: AppColors.purple,
            onRefresh: () async {
              ref.invalidate(levelCoursesProvider(widget.level));
              await ref.read(levelCoursesProvider(widget.level).future);
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
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Wrap(
                        spacing: 8,
                        runSpacing: 6,
                        children: [
                          PillBadge(
                            label: 'Qualification Hub • KNQF Level ${widget.level}',
                            variant: PillVariant.purple,
                          ),
                          if (widget.level >= 4)
                            PillBadge(
                              label: 'KNEC $knecTier',
                              variant: PillVariant.red,
                            ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'TVET Level ${widget.level} Courses & Past Papers',
                        style: Theme.of(context).textTheme.headlineMedium,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Showing ${filtered.length} published Level ${widget.level} courses across CDACC and KNEC frameworks.',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    gradient: AppColors.heroGradient,
                    borderRadius: BorderRadius.circular(AppRadii.xl),
                  ),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        for (final entry in const [
                          ('all', 'All Frameworks'),
                          ('modular', 'Modular CDACC'),
                          ('non_modular', 'CDACC Cycle 1 & 2'),
                          ('knec', 'KNEC'),
                        ])
                          Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(
                                AppRadii.pill,
                              ),
                              onTap: () =>
                                  setState(() => _frameworkFilter = entry.$1),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: _frameworkFilter == entry.$1
                                      ? AppColors.red
                                      : Colors.white.withValues(alpha: 0.14),
                                  borderRadius: BorderRadius.circular(
                                    AppRadii.pill,
                                  ),
                                  border: Border.all(
                                    color: _frameworkFilter == entry.$1
                                        ? AppColors.red
                                        : Colors.white.withValues(alpha: 0.28),
                                  ),
                                ),
                                child: Text(
                                  entry.$2,
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
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                if (sortedGroups.isEmpty)
                  EmptyStateCard(
                    icon: LucideIcons.graduationCap,
                    title: 'No courses found',
                    message:
                        'No Level ${widget.level} courses match this framework filter.',
                    actionLabel: 'Show All Frameworks',
                    onAction: () => setState(() => _frameworkFilter = 'all'),
                  )
                else
                  ...sortedGroups.map((entry) {
                    return Container(
                      margin: const EdgeInsets.only(bottom: 14),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.white,
                        borderRadius: BorderRadius.circular(AppRadii.xxl),
                        border: Border.all(color: AppColors.line),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  entry.key,
                                  style: Theme.of(context).textTheme.titleMedium,
                                ),
                              ),
                              PillBadge(
                                label: '${entry.value.length}',
                                variant: PillVariant.purple,
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          ...entry.value.map((course) {
                            final progSlug =
                                course.department?.programme?.slug ?? '';
                            final deptSlug = course.department?.slug ?? '';
                            return Container(
                              margin: const EdgeInsets.only(bottom: 8),
                              decoration: BoxDecoration(
                                color: AppColors.purpleSoft,
                                borderRadius: BorderRadius.circular(
                                  AppRadii.md,
                                ),
                                border: Border.all(color: AppColors.line),
                              ),
                              child: InkWell(
                                borderRadius: BorderRadius.circular(
                                  AppRadii.md,
                                ),
                                onTap: () {
                                  if (progSlug.isNotEmpty &&
                                      deptSlug.isNotEmpty) {
                                    context.push(
                                      '/$progSlug/$deptSlug/${course.slug}',
                                    );
                                  }
                                },
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 14,
                                    vertical: 12,
                                  ),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              toTitleCase(course.name),
                                              style: const TextStyle(
                                                fontSize: 13.5,
                                                fontWeight: FontWeight.w600,
                                                color: AppColors.ink,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            PillBadge(
                                              label: programmeShortLabel(
                                                progSlug,
                                              ),
                                              variant: PillVariant.purple,
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 8,
                                                    vertical: 2,
                                                  ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        '${course.totalUnits} units',
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: AppColors.muted,
                                        ),
                                      ),
                                      const SizedBox(width: 4),
                                      const Icon(
                                        LucideIcons.chevronRight,
                                        size: 15,
                                        color: AppColors.muted,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          }),
                        ],
                      ),
                    );
                  }),
              ],
            ),
          );
        },
      ),
    );
  }
}
