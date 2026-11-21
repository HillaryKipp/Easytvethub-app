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

class DepartmentScreen extends ConsumerStatefulWidget {
  final String programmeSlug;
  final String departmentSlug;

  const DepartmentScreen({
    super.key,
    required this.programmeSlug,
    required this.departmentSlug,
  });

  @override
  ConsumerState<DepartmentScreen> createState() => _DepartmentScreenState();
}

class _DepartmentScreenState extends ConsumerState<DepartmentScreen> {
  int? _selectedLevel;

  @override
  Widget build(BuildContext context) {
    final key = (
      programmeSlug: widget.programmeSlug,
      departmentSlug: widget.departmentSlug,
    );
    final asyncDept = ref.watch(departmentDetailProvider(key));

    return Scaffold(
      appBar: AppBar(
        title: Text(
          asyncDept.valueOrNull != null
              ? toTitleCase(asyncDept.valueOrNull!.name)
              : 'Department',
        ),
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.search, size: 20),
            onPressed: () => context.push('/search'),
          ),
        ],
      ),
      body: asyncDept.when(
        loading: () => const LoadingSkeletonList(itemCount: 5, itemHeight: 90),
        error: (err, _) => ErrorStateCard(
          onRetry: () => ref.invalidate(departmentDetailProvider(key)),
        ),
        data: (dept) {
          final isKnec = dept.programme?.isKnec ?? false;
          final levels = isKnec ? const [6, 5, 4] : const [6, 5, 4, 3];
          final courses = _selectedLevel == null
              ? dept.courses
              : dept.courses.where((c) => c.level == _selectedLevel).toList();

          return RefreshIndicator(
            color: AppColors.purple,
            onRefresh: () async {
              ref.invalidate(departmentDetailProvider(key));
              await ref.read(departmentDetailProvider(key).future);
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
                          if (dept.programme != null)
                            PillBadge(
                              label: toTitleCase(dept.programme!.name),
                              variant: PillVariant.purple,
                              onTap: () =>
                                  context.push('/${dept.programme!.slug}'),
                            ),
                          PillBadge(
                            label: '${dept.courses.length} Courses',
                            variant: PillVariant.neutral,
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        toTitleCase(dept.name),
                        style: Theme.of(context).textTheme.headlineMedium,
                      ),
                      if ((dept.intro ?? dept.description) != null &&
                          (dept.intro ?? dept.description)!
                              .trim()
                              .isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text(
                          (dept.intro ?? dept.description)!.trim(),
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
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
                        _LevelPill(
                          label: 'All Levels',
                          selected: _selectedLevel == null,
                          onTap: () => setState(() => _selectedLevel = null),
                        ),
                        ...levels.map(
                          (lvl) => _LevelPill(
                            label: isKnec
                                ? getKnecTierName(lvl)
                                : 'Level $lvl',
                            selected: _selectedLevel == lvl,
                            onTap: () => setState(() => _selectedLevel = lvl),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                if (courses.isEmpty)
                  EmptyStateCard(
                    icon: LucideIcons.bookX,
                    title: 'No courses match this level',
                    message: 'Select another level or view all courses.',
                    actionLabel: 'Show All',
                    onAction: () => setState(() => _selectedLevel = null),
                  )
                else
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.white,
                      borderRadius: BorderRadius.circular(AppRadii.xxl),
                      border: Border.all(color: AppColors.line),
                    ),
                    child: Column(
                      children: courses.asMap().entries.map((entry) {
                        final idx = entry.key;
                        final course = entry.value;
                        return Container(
                          margin: EdgeInsets.only(
                            bottom: idx == courses.length - 1 ? 0 : 10,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.purpleSoft,
                            borderRadius: BorderRadius.circular(AppRadii.md),
                            border: Border.all(color: AppColors.line),
                          ),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(AppRadii.md),
                            onTap: () => context.push(
                              '/${widget.programmeSlug}/${dept.slug}/${course.slug}',
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(14),
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
                                            fontSize: 14,
                                            fontWeight: FontWeight.w700,
                                            color: AppColors.ink,
                                          ),
                                        ),
                                        const SizedBox(height: 6),
                                        Wrap(
                                          spacing: 6,
                                          runSpacing: 4,
                                          children: [
                                            if (course.level != null)
                                              PillBadge(
                                                label: isKnec
                                                    ? getKnecTierName(
                                                        course.level,
                                                      )
                                                    : 'Level ${course.level}',
                                                variant: PillVariant.red,
                                              ),
                                            PillBadge(
                                              label:
                                                  '${course.totalUnits} units',
                                              variant: PillVariant.neutral,
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
                      }).toList(),
                    ),
                  ),
                if (dept.faq.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  FaqAccordion(items: dept.faq),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}

class _LevelPill extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _LevelPill({
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
        child: Container(
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
