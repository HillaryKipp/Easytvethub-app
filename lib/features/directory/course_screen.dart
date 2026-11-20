import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:share_plus/share_plus.dart';
import '../../core/config/env.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/empty_error_views.dart';
import '../../core/widgets/faq_accordion.dart';
import '../../core/widgets/pill_badge.dart';
import '../../data/models/saved_models.dart';
import '../../data/repositories/directory_repository.dart';
import '../../data/repositories/downloads_repository.dart';

class CourseScreen extends ConsumerWidget {
  final String programmeSlug;
  final String departmentSlug;
  final String courseSlug;

  const CourseScreen({
    super.key,
    required this.programmeSlug,
    required this.departmentSlug,
    required this.courseSlug,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final key = (
      programmeSlug: programmeSlug,
      departmentSlug: departmentSlug,
      courseSlug: courseSlug,
    );
    final asyncData = ref.watch(courseDetailProvider(key));
    final downloadsState = ref.watch(downloadsProvider);
    final coursePath = '/$programmeSlug/$departmentSlug/$courseSlug';

    return Scaffold(
      appBar: AppBar(
        title: Text(
          asyncData.valueOrNull != null
              ? toTitleCase(asyncData.valueOrNull!.course.name)
              : 'Course Details',
        ),
        actions: [
          if (asyncData.valueOrNull != null) ...[
            Builder(
              builder: (context) {
                final course = asyncData.valueOrNull!.course;
                final isSaved = downloadsState.isBookmarked('course_${course.id}');
                return IconButton(
                  icon: Icon(
                    isSaved ? LucideIcons.bookmarkCheck : LucideIcons.bookmark,
                    size: 20,
                    color: isSaved ? AppColors.purple : AppColors.ink,
                  ),
                  tooltip: isSaved ? 'Remove Bookmark' : 'Bookmark Course',
                  onPressed: () {
                    ref.read(downloadsProvider.notifier).toggleBookmark(
                          SavedBookmark(
                            id: 'course_${course.id}',
                            type: 'course',
                            title: toTitleCase(course.name),
                            subtitle: toTitleCase(
                              course.department?.name ?? departmentSlug,
                            ),
                            path: coursePath,
                            level: course.level,
                            savedAt: DateTime.now(),
                          ),
                        );
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          isSaved
                              ? 'Removed from Saved Bookmarks'
                              : 'Saved course to Bookmarks',
                        ),
                        duration: const Duration(seconds: 2),
                      ),
                    );
                  },
                );
              },
            ),
            IconButton(
              icon: const Icon(LucideIcons.share2, size: 19),
              tooltip: 'Share Course',
              onPressed: () {
                final course = asyncData.valueOrNull!.course;
                Share.share(
                  '${toTitleCase(course.name)} — Past Papers & Units on EasyTVET Hub\n${Env.canonicalUrl(coursePath)}',
                );
              },
            ),
          ],
        ],
      ),
      body: asyncData.when(
        loading: () => const LoadingSkeletonList(itemCount: 5, itemHeight: 96),
        error: (err, _) => ErrorStateCard(
          onRetry: () => ref.invalidate(courseDetailProvider(key)),
        ),
        data: (data) {
          final course = data.course;
          final dept = course.department;
          final prog = dept?.programme;
          final isKnec = prog?.isKnec ?? programmeSlug.contains('knec');
          final isSaved = downloadsState.isBookmarked('course_${course.id}');

          return RefreshIndicator(
            color: AppColors.purple,
            onRefresh: () async {
              ref.invalidate(courseDetailProvider(key));
              await ref.read(courseDetailProvider(key).future);
            },
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
              children: [
                // 1. Compact Header Card
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
                          if (dept != null)
                            PillBadge(
                              label: toTitleCase(dept.name),
                              variant: PillVariant.purple,
                              onTap: () =>
                                  context.push('/$programmeSlug/$departmentSlug'),
                            ),
                          if (course.level != null)
                            PillBadge(
                              label: isKnec
                                  ? getKnecTierName(course.level)
                                  : 'Level ${course.level}',
                              variant: PillVariant.red,
                            ),
                          PillBadge(
                            label:
                                '${course.modules.length} Modules • ${course.totalUnits} Units',
                            variant: PillVariant.neutral,
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        toTitleCase(course.name),
                        style: Theme.of(context).textTheme.headlineMedium,
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(
                            LucideIcons.clock,
                            size: 13,
                            color: AppColors.muted,
                          ),
                          const SizedBox(width: 5),
                          Text(
                            'Updated ${formatDate(course.updatedAt)}',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                          const Spacer(),
                          InkWell(
                            borderRadius: BorderRadius.circular(AppRadii.pill),
                            onTap: () {
                              ref.read(downloadsProvider.notifier).toggleBookmark(
                                    SavedBookmark(
                                      id: 'course_${course.id}',
                                      type: 'course',
                                      title: toTitleCase(course.name),
                                      subtitle: toTitleCase(
                                        dept?.name ?? departmentSlug,
                                      ),
                                      path: coursePath,
                                      level: course.level,
                                      savedAt: DateTime.now(),
                                    ),
                                  );
                            },
                            child: PillBadge(
                              label: isSaved ? 'Saved' : 'Save Course',
                              icon: isSaved
                                  ? LucideIcons.bookmarkCheck
                                  : LucideIcons.bookmark,
                              variant: isSaved
                                  ? PillVariant.solidPurple
                                  : PillVariant.purple,
                            ),
                          ),
                        ],
                      ),
                      if ((course.intro ?? course.description) != null &&
                          (course.intro ?? course.description)!
                              .trim()
                              .isNotEmpty) ...[
                        const SizedBox(height: 12),
                        Text(
                          (course.intro ?? course.description)!.trim(),
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // 2. Module Cards
                if (course.modules.isEmpty)
                  const EmptyStateCard(
                    icon: LucideIcons.layers,
                    title: 'Units Coming Soon',
                    message:
                        'Modules and units for this course are being organized.',
                  )
                else
                  ...course.modules.map((module) {
                    final moduleHeading =
                        module.title != null && module.title!.trim().isNotEmpty
                            ? 'Module ${module.moduleNumber}: ${toTitleCase(module.title!)}'
                            : 'Module ${module.moduleNumber}';
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
                                  moduleHeading,
                                  style: Theme.of(context).textTheme.titleMedium,
                                ),
                              ),
                              PillBadge(
                                label: '${module.units.length} units',
                                variant: PillVariant.purple,
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          ...module.units.asMap().entries.map((entry) {
                            final idx = entry.key;
                            final unit = entry.value;
                            final resourceCount = unit.resources.length;

                            return Container(
                              margin: EdgeInsets.only(
                                bottom: idx == module.units.length - 1 ? 0 : 8,
                              ),
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
                                  '/$programmeSlug/$departmentSlug/$courseSlug/${unit.slug}',
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(12),
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 28,
                                        height: 28,
                                        alignment: Alignment.center,
                                        decoration: BoxDecoration(
                                          color: AppColors.purpleTint,
                                          borderRadius: BorderRadius.circular(
                                            AppRadii.sm,
                                          ),
                                        ),
                                        child: Text(
                                          '${idx + 1}',
                                          style: const TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w800,
                                            color: AppColors.purple,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              toTitleCase(unit.name),
                                              style: const TextStyle(
                                                fontSize: 13.5,
                                                fontWeight: FontWeight.w600,
                                                color: AppColors.ink,
                                                height: 1.3,
                                              ),
                                            ),
                                            if (unit.unitCode != null &&
                                                unit.unitCode!
                                                    .trim()
                                                    .isNotEmpty) ...[
                                              const SizedBox(height: 3),
                                              Text(
                                                unit.unitCode!.trim(),
                                                style: const TextStyle(
                                                  fontSize: 11,
                                                  fontFamily: 'monospace',
                                                  color: AppColors.muted,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                            ],
                                          ],
                                        ),
                                      ),
                                      if (resourceCount > 0) ...[
                                        const SizedBox(width: 8),
                                        PillBadge(
                                          label: '$resourceCount',
                                          icon: LucideIcons.fileText,
                                          variant: PillVariant.red,
                                        ),
                                      ],
                                      const SizedBox(width: 4),
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
                        ],
                      ),
                    );
                  }),

                // 3. Related Courses (Vertical Progression & Same Level)
                if (data.otherLevelVariants.isNotEmpty) ...[
                  _RelatedCoursesCard(
                    title: 'Other Qualification Levels',
                    icon: LucideIcons.trendingUp,
                    courses: data.otherLevelVariants,
                    fallbackProgrammeSlug: programmeSlug,
                    fallbackDeptSlug: departmentSlug,
                    isKnec: isKnec,
                  ),
                  const SizedBox(height: 14),
                ],
                if (data.sameLevelDepartmentCourses.isNotEmpty) ...[
                  _RelatedCoursesCard(
                    title: 'More Courses in ${toTitleCase(dept?.name ?? 'Department')}',
                    icon: LucideIcons.bookCopy,
                    courses: data.sameLevelDepartmentCourses,
                    fallbackProgrammeSlug: programmeSlug,
                    fallbackDeptSlug: departmentSlug,
                    isKnec: isKnec,
                  ),
                  const SizedBox(height: 14),
                ],

                // Contextual Revision Articles
                if (data.relatedArticles.isNotEmpty) ...[
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.white,
                      borderRadius: BorderRadius.circular(AppRadii.xxl),
                      border: Border.all(color: AppColors.line),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Revision Guides & TVET Updates',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 10),
                        ...data.relatedArticles.map(
                          (article) => ListTile(
                            contentPadding: EdgeInsets.zero,
                            dense: true,
                            title: Text(
                              article.title,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w600,
                                color: AppColors.ink,
                              ),
                            ),
                            subtitle: Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Wrap(
                                spacing: 8,
                                crossAxisAlignment: WrapCrossAlignment.center,
                                children: [
                                  PillBadge.forCategory(article.category),
                                  if (article.publishedAt != null)
                                    Text(
                                      formatDate(article.publishedAt),
                                      style: const TextStyle(
                                        fontSize: 11,
                                        color: AppColors.muted,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            trailing: const Icon(
                              LucideIcons.chevronRight,
                              size: 16,
                              color: AppColors.muted,
                            ),
                            onTap: () => context.push('/blog/${article.slug}'),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                ],

                if (course.faq.isNotEmpty) FaqAccordion(items: course.faq),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _RelatedCoursesCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<dynamic> courses;
  final String fallbackProgrammeSlug;
  final String fallbackDeptSlug;
  final bool isKnec;

  const _RelatedCoursesCard({
    required this.title,
    required this.icon,
    required this.courses,
    required this.fallbackProgrammeSlug,
    required this.fallbackDeptSlug,
    required this.isKnec,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
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
              Icon(icon, size: 17, color: AppColors.purple),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...courses.map((c) {
            final pSlug =
                c.department?.programme?.slug ?? fallbackProgrammeSlug;
            final dSlug = c.department?.slug ?? fallbackDeptSlug;
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(
                color: AppColors.purpleSoft,
                borderRadius: BorderRadius.circular(AppRadii.md),
                border: Border.all(color: AppColors.line),
              ),
              child: InkWell(
                borderRadius: BorderRadius.circular(AppRadii.md),
                onTap: () => context.push('/$pSlug/$dSlug/${c.slug}'),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          toTitleCase(c.name as String),
                          style: const TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w600,
                            color: AppColors.ink,
                          ),
                        ),
                      ),
                      if (c.level != null) ...[
                        const SizedBox(width: 8),
                        PillBadge(
                          label: isKnec
                              ? getKnecTierName(c.level as int?)
                              : 'L${c.level}',
                          variant: PillVariant.red,
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}
