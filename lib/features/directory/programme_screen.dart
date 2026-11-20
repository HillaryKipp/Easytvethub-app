import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/empty_error_views.dart';
import '../../core/widgets/faq_accordion.dart';
import '../../core/widgets/pill_badge.dart';
import '../../data/repositories/directory_repository.dart';

class ProgrammeScreen extends ConsumerStatefulWidget {
  final String programmeSlug;

  const ProgrammeScreen({super.key, required this.programmeSlug});

  @override
  ConsumerState<ProgrammeScreen> createState() => _ProgrammeScreenState();
}

class _ProgrammeScreenState extends ConsumerState<ProgrammeScreen> {
  int? _selectedLevel;

  @override
  Widget build(BuildContext context) {
    final asyncData = ref.watch(programmeDetailProvider(widget.programmeSlug));

    return Scaffold(
      appBar: AppBar(
        title: Text(
          asyncData.valueOrNull != null
              ? toTitleCase(asyncData.valueOrNull!.programme.name)
              : 'Programme',
        ),
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.search, size: 20),
            onPressed: () => context.go('/search'),
          ),
        ],
      ),
      body: asyncData.when(
        loading: () => const LoadingSkeletonList(itemCount: 5, itemHeight: 100),
        error: (err, _) => ErrorStateCard(
          onRetry: () =>
              ref.invalidate(programmeDetailProvider(widget.programmeSlug)),
        ),
        data: (data) {
          final programme = data.programme;
          final availableLevels = programme.isKnec
              ? const [6, 5, 4]
              : const [6, 5, 4, 3];

          final filteredDepts = data.departments
              .map((dept) {
                final courses = _selectedLevel == null
                    ? dept.courses
                    : dept.courses
                          .where((c) => c.level == _selectedLevel)
                          .toList();
                return (dept: dept, courses: courses);
              })
              .where((item) => item.courses.isNotEmpty)
              .toList();

          return RefreshIndicator(
            color: AppColors.purple,
            onRefresh: () async {
              ref.invalidate(programmeDetailProvider(widget.programmeSlug));
              await ref.read(
                programmeDetailProvider(widget.programmeSlug).future,
              );
            },
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
              children: [
                // Header Card
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
                      const PillBadge(
                        label: 'TVET Programme Framework',
                        variant: PillVariant.purple,
                      ),
                      const SizedBox(height: 10),
                      Text(
                        toTitleCase(programme.name),
                        style: Theme.of(context).textTheme.headlineMedium,
                      ),
                      if ((programme.intro ?? programme.description) != null &&
                          (programme.intro ?? programme.description)!
                              .trim()
                              .isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text(
                          (programme.intro ?? programme.description)!.trim(),
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                // Purple Gradient Level Filter Bar
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
                        _GradientFilterPill(
                          label: 'All Levels',
                          selected: _selectedLevel == null,
                          onTap: () => setState(() => _selectedLevel = null),
                        ),
                        ...availableLevels.map((lvl) {
                          final label = programme.isKnec
                              ? getKnecTierName(lvl)
                              : 'Level $lvl';
                          return _GradientFilterPill(
                            label: label,
                            selected: _selectedLevel == lvl,
                            onTap: () => setState(() => _selectedLevel = lvl),
                          );
                        }),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                if (filteredDepts.isEmpty)
                  EmptyStateCard(
                    icon: LucideIcons.folderOpen,
                    title: 'No courses at this level',
                    message:
                        'Try selecting "All Levels" to view all courses under ${toTitleCase(programme.name)}.',
                    actionLabel: 'Show All Levels',
                    onAction: () => setState(() => _selectedLevel = null),
                  )
                else
                  ...filteredDepts.map((group) {
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
                          InkWell(
                            onTap: () => context.push(
                              '/${programme.slug}/${group.dept.slug}',
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    toTitleCase(group.dept.name),
                                    style: Theme.of(
                                      context,
                                    ).textTheme.titleMedium,
                                  ),
                                ),
                                PillBadge(
                                  label: '${group.courses.length} courses',
                                  variant: PillVariant.purple,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),
                          ...group.courses.map((course) {
                            final unitsCount = course.totalUnits;
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
                                onTap: () => context.push(
                                  '/${programme.slug}/${group.dept.slug}/${course.slug}',
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 14,
                                    vertical: 12,
                                  ),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          toTitleCase(course.name),
                                          style: const TextStyle(
                                            fontSize: 13.5,
                                            fontWeight: FontWeight.w600,
                                            color: AppColors.ink,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        '$unitsCount units',
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: AppColors.muted,
                                          fontWeight: FontWeight.w500,
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
                if (programme.faq.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  FaqAccordion(items: programme.faq),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}

class _GradientFilterPill extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _GradientFilterPill({
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
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: selected
                ? AppColors.red
                : Colors.white.withValues(alpha: 0.14),
            borderRadius: BorderRadius.circular(AppRadii.pill),
            border: Border.all(
              color: selected
                  ? AppColors.red
                  : Colors.white.withValues(alpha: 0.28),
            ),
          ),
          child: Text(
            label,
            style: const TextStyle(
              color: AppColors.white,
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }
}
