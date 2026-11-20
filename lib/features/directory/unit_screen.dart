import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/config/env.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/drive_link_helper.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/empty_error_views.dart';
import '../../core/widgets/pill_badge.dart';
import '../../data/models/directory_models.dart';
import '../../data/models/saved_models.dart';
import '../../data/repositories/directory_repository.dart';
import '../../data/repositories/downloads_repository.dart';
import 'pdf_viewer_screen.dart';

class UnitScreen extends ConsumerWidget {
  final String programmeSlug;
  final String departmentSlug;
  final String courseSlug;
  final String unitSlug;

  const UnitScreen({
    super.key,
    required this.programmeSlug,
    required this.departmentSlug,
    required this.courseSlug,
    required this.unitSlug,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final key = (
      programmeSlug: programmeSlug,
      departmentSlug: departmentSlug,
      courseSlug: courseSlug,
      unitSlug: unitSlug,
    );
    final asyncData = ref.watch(unitDetailProvider(key));
    final downloadsState = ref.watch(downloadsProvider);
    final unitPath = '/$programmeSlug/$departmentSlug/$courseSlug/$unitSlug';

    return Scaffold(
      appBar: AppBar(
        title: Text(
          asyncData.valueOrNull != null
              ? toTitleCase(asyncData.valueOrNull!.unit.name)
              : 'Unit Past Papers',
        ),
        actions: [
          if (asyncData.valueOrNull != null) ...[
            Builder(
              builder: (context) {
                final unit = asyncData.valueOrNull!.unit;
                final isSaved = downloadsState.isBookmarked('unit_${unit.id}');
                return IconButton(
                  icon: Icon(
                    isSaved ? LucideIcons.bookmarkCheck : LucideIcons.bookmark,
                    size: 20,
                    color: isSaved ? AppColors.purple : AppColors.ink,
                  ),
                  tooltip: isSaved ? 'Remove Bookmark' : 'Bookmark Unit',
                  onPressed: () {
                    ref.read(downloadsProvider.notifier).toggleBookmark(
                          SavedBookmark(
                            id: 'unit_${unit.id}',
                            type: 'unit',
                            title: toTitleCase(unit.name),
                            subtitle: toTitleCase(
                              unit.course?.name ?? courseSlug,
                            ),
                            path: unitPath,
                            level: unit.course?.level,
                            savedAt: DateTime.now(),
                          ),
                        );
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          isSaved
                              ? 'Removed unit from Bookmarks'
                              : 'Saved unit to Bookmarks',
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
              tooltip: 'Share Unit Link',
              onPressed: () {
                final unit = asyncData.valueOrNull!.unit;
                Share.share(
                  '${toTitleCase(unit.name)} Past Papers on EasyTVET Hub\n${Env.canonicalUrl(unitPath)}',
                );
              },
            ),
          ],
        ],
      ),
      body: asyncData.when(
        loading: () => const LoadingSkeletonList(itemCount: 5, itemHeight: 96),
        error: (err, _) => ErrorStateCard(
          onRetry: () => ref.invalidate(unitDetailProvider(key)),
        ),
        data: (data) {
          final unit = data.unit;
          final course = unit.course;
          final dept = course?.department;
          final prog = dept?.programme;
          final isKnec = prog?.isKnec ?? programmeSlug.contains('knec');
          final examBody = isKnec ? 'KNEC' : 'CDACC';
          final unitTitle = toTitleCase(unit.name);
          final courseTitle = toTitleCase(course?.name ?? courseSlug);
          final isBookmarked = downloadsState.isBookmarked('unit_${unit.id}');

          return RefreshIndicator(
            color: AppColors.purple,
            onRefresh: () async {
              ref.invalidate(unitDetailProvider(key));
              await ref.read(unitDetailProvider(key).future);
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
                        spacing: 6,
                        runSpacing: 6,
                        children: [
                          PillBadge(
                            label: courseTitle,
                            variant: PillVariant.purple,
                            onTap: () => context.push(
                              '/$programmeSlug/$departmentSlug/$courseSlug',
                            ),
                          ),
                          if (unit.module != null)
                            PillBadge(
                              label: 'Module ${unit.module!.moduleNumber}',
                              variant: PillVariant.neutral,
                            ),
                          if (course?.level != null)
                            PillBadge(
                              label: isKnec
                                  ? getKnecTierName(course!.level)
                                  : 'Level ${course!.level}',
                              variant: PillVariant.red,
                            ),
                          if (unit.unitCode != null &&
                              unit.unitCode!.trim().isNotEmpty)
                            PillBadge(
                              label: unit.unitCode!.trim(),
                              variant: PillVariant.neutral,
                              monospace: true,
                            ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        '$unitTitle $examBody Past Papers',
                        style: Theme.of(context).textTheme.headlineMedium,
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Text(
                            '${unit.resources.length} assessment file${unit.resources.length == 1 ? '' : 's'}',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                          const Spacer(),
                          PillBadge(
                            label: isBookmarked ? 'Bookmarked' : 'Bookmark',
                            icon: isBookmarked
                                ? LucideIcons.bookmarkCheck
                                : LucideIcons.bookmark,
                            variant: isBookmarked
                                ? PillVariant.solidPurple
                                : PillVariant.purple,
                            onTap: () {
                              ref.read(downloadsProvider.notifier).toggleBookmark(
                                    SavedBookmark(
                                      id: 'unit_${unit.id}',
                                      type: 'unit',
                                      title: unitTitle,
                                      subtitle: courseTitle,
                                      path: unitPath,
                                      level: course?.level,
                                      savedAt: DateTime.now(),
                                    ),
                                  );
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // 2. Priority #1 — Past Papers & Assessment Tools Card
                Container(
                  padding: const EdgeInsets.all(18),
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
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppColors.purpleTint,
                              borderRadius: BorderRadius.circular(AppRadii.md),
                            ),
                            child: const Icon(
                              LucideIcons.fileText,
                              size: 18,
                              color: AppColors.purple,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Past Papers & Assessment Tools',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      if (unit.resources.isEmpty)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: AppColors.purpleSoft,
                            borderRadius: BorderRadius.circular(AppRadii.lg),
                            border: Border.all(
                              color: AppColors.lineStrong,
                              style: BorderStyle.solid,
                            ),
                          ),
                          child: Column(
                            children: [
                              const Icon(
                                LucideIcons.clock,
                                size: 28,
                                color: AppColors.purple,
                              ),
                              const SizedBox(height: 10),
                              const Text(
                                'Past papers for this unit are queued',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 14.5,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.ink,
                                ),
                              ),
                              const SizedBox(height: 6),
                              const Text(
                                'Our academic team uploads verified CDACC & KNEC papers regularly. Need this unit urgently?',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: AppColors.text,
                                  height: 1.5,
                                ),
                              ),
                              const SizedBox(height: 14),
                              OutlinedButton.icon(
                                onPressed: () => context.push('/info/contact'),
                                icon: const Icon(LucideIcons.mail, size: 15),
                                label: const Text('Request This Paper'),
                              ),
                            ],
                          ),
                        )
                      else
                        ...unit.resources.asMap().entries.map((entry) {
                          final idx = entry.key;
                          final res = entry.value;
                          final downloaded = downloadsState.findPdf(res.id);
                          final progress =
                              downloadsState.activeProgress[res.id];

                          return _ResourceTile(
                            index: idx + 1,
                            resource: res,
                            unitName: unitTitle,
                            courseName: courseTitle,
                            webPath: unitPath,
                            isDownloaded: downloaded != null,
                            downloadProgress: progress,
                            onOpenPdf: () {
                              Navigator.of(context).push(
                                MaterialPageRoute<void>(
                                  builder: (_) => PdfViewerScreen(
                                    resource: res,
                                    title: res.displayTitle(unitTitle),
                                    unitName: unitTitle,
                                    courseName: courseTitle,
                                    localPath: downloaded?.localPath,
                                    webPath: unitPath,
                                  ),
                                ),
                              );
                            },
                            onDownloadTap: () => _handleDownload(
                              context: context,
                              ref: ref,
                              resource: res,
                              unitName: unitTitle,
                              courseName: courseTitle,
                              webPath: unitPath,
                              alreadyDownloaded: downloaded != null,
                            ),
                          );
                        }),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // 3. Official Syllabus Placement Table
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: BorderRadius.circular(AppRadii.xxl),
                    border: Border.all(color: AppColors.line),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Official Syllabus Placement',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 12),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(AppRadii.md),
                        child: Container(
                          decoration: BoxDecoration(
                            border: Border.all(color: AppColors.line),
                            borderRadius: BorderRadius.circular(AppRadii.md),
                          ),
                          child: Column(
                            children: [
                              _PlacementRow(
                                label: 'Programme',
                                value: toTitleCase(prog?.name ?? programmeSlug),
                                onTap: () => context.push('/$programmeSlug'),
                              ),
                              const Divider(height: 1),
                              _PlacementRow(
                                label: 'Department',
                                value: toTitleCase(
                                  dept?.name ?? departmentSlug,
                                ),
                                onTap: () => context.push(
                                  '/$programmeSlug/$departmentSlug',
                                ),
                              ),
                              const Divider(height: 1),
                              _PlacementRow(
                                label: 'Course',
                                value: courseTitle,
                                onTap: () => context.push(
                                  '/$programmeSlug/$departmentSlug/$courseSlug',
                                ),
                              ),
                              if (unit.module != null) ...[
                                const Divider(height: 1),
                                _PlacementRow(
                                  label: 'Module',
                                  value: 'Module ${unit.module!.moduleNumber}',
                                ),
                              ],
                              if (unit.unitCode != null &&
                                  unit.unitCode!.trim().isNotEmpty) ...[
                                const Divider(height: 1),
                                _PlacementRow(
                                  label: 'Unit Code',
                                  value: unit.unitCode!.trim(),
                                  monospace: true,
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // 4. Sequential Prev / Next Unit Navigation
                if (data.previousUnit != null || data.nextUnit != null) ...[
                  Row(
                    children: [
                      if (data.previousUnit != null)
                        Expanded(
                          child: _PrevNextButton(
                            label: 'Previous Unit',
                            unitName: toTitleCase(data.previousUnit!.name),
                            isNext: false,
                            onTap: () => context.pushReplacement(
                              '/$programmeSlug/$departmentSlug/$courseSlug/${data.previousUnit!.slug}',
                            ),
                          ),
                        ),
                      if (data.previousUnit != null && data.nextUnit != null)
                        const SizedBox(width: 10),
                      if (data.nextUnit != null)
                        Expanded(
                          child: _PrevNextButton(
                            label: 'Next Unit',
                            unitName: toTitleCase(data.nextUnit!.name),
                            isNext: true,
                            onTap: () => context.pushReplacement(
                              '/$programmeSlug/$departmentSlug/$courseSlug/${data.nextUnit!.slug}',
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),
                ],

                // 5. Other Courses Featuring This Unit
                if (data.otherCourses.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: AppColors.white,
                      borderRadius: BorderRadius.circular(AppRadii.xxl),
                      border: Border.all(color: AppColors.line),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Other Courses Featuring This Unit',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 10),
                        ...data.otherCourses.map(
                          (refItem) => Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            decoration: BoxDecoration(
                              color: AppColors.purpleSoft,
                              borderRadius: BorderRadius.circular(AppRadii.md),
                              border: Border.all(color: AppColors.line),
                            ),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(AppRadii.md),
                              onTap: () => context.push(refItem.unitPath),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 10,
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        toTitleCase(refItem.courseName),
                                        style: const TextStyle(
                                          fontSize: 13.5,
                                          fontWeight: FontWeight.w600,
                                          color: AppColors.ink,
                                        ),
                                      ),
                                    ),
                                    if (refItem.level != null) ...[
                                      const SizedBox(width: 8),
                                      PillBadge(
                                        label: 'L${refItem.level}',
                                        variant: PillVariant.red,
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
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _handleDownload({
    required BuildContext context,
    required WidgetRef ref,
    required ResourceModel resource,
    required String unitName,
    required String courseName,
    required String webPath,
    required bool alreadyDownloaded,
  }) async {
    if (alreadyDownloaded) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Already saved offline in the Saved tab.'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    try {
      await ref.read(downloadsProvider.notifier).downloadResource(
            resource: resource,
            unitName: unitName,
            courseName: courseName,
            webPath: webPath,
          );
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Saved for offline revision in the Saved tab.'),
            backgroundColor: AppColors.green,
          ),
        );
      }
    } on HtmlFallbackRequiredException catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Opening Google Drive in your browser to download this file...',
            ),
          ),
        );
      }
      await launchUrl(
        Uri.parse(e.originalUrl),
        mode: LaunchMode.externalApplication,
      );
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(
              'Direct download failed. Tap to open in browser.',
            ),
            action: SnackBarAction(
              label: 'Open',
              onPressed: () {
                launchUrl(
                  Uri.parse(resource.fileUrl),
                  mode: LaunchMode.externalApplication,
                );
              },
            ),
          ),
        );
      }
    }
  }
}

class _ResourceTile extends StatelessWidget {
  final int index;
  final ResourceModel resource;
  final String unitName;
  final String courseName;
  final String webPath;
  final bool isDownloaded;
  final double? downloadProgress;
  final VoidCallback onOpenPdf;
  final VoidCallback onDownloadTap;

  const _ResourceTile({
    required this.index,
    required this.resource,
    required this.unitName,
    required this.courseName,
    required this.webPath,
    required this.isDownloaded,
    required this.downloadProgress,
    required this.onOpenPdf,
    required this.onDownloadTap,
  });

  @override
  Widget build(BuildContext context) {
    final extLabel = DriveLinkHelper.getFileExtensionLabel(resource.fileUrl);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: AppColors.purpleSoft,
        borderRadius: BorderRadius.circular(AppRadii.md),
        border: Border.all(color: AppColors.line),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadii.md),
        onTap: onOpenPdf,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Container(
                width: 32,
                height: 32,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.purpleTint,
                  borderRadius: BorderRadius.circular(AppRadii.sm),
                ),
                child: Text(
                  '$index',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: AppColors.purple,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      resource.displayTitle(unitName),
                      style: const TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                        color: AppColors.ink,
                        height: 1.3,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: [
                        PillBadge(
                          label: resource.type.label,
                          variant: PillVariant.purple,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                        ),
                        if (resource.year != null)
                          PillBadge(
                            label: '${resource.year}',
                            variant: PillVariant.red,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                          ),
                        PillBadge(
                          label: extLabel,
                          variant: PillVariant.neutral,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              if (downloadProgress != null)
                SizedBox(
                  width: 34,
                  height: 34,
                  child: Padding(
                    padding: const EdgeInsets.all(5),
                    child: CircularProgressIndicator(
                      value: downloadProgress,
                      strokeWidth: 2.5,
                      color: AppColors.purple,
                    ),
                  ),
                )
              else
                IconButton(
                  onPressed: onDownloadTap,
                  tooltip: isDownloaded ? 'Saved Offline' : 'Download Offline',
                  icon: Icon(
                    isDownloaded ? LucideIcons.circleCheck : LucideIcons.download,
                    size: 20,
                    color: isDownloaded ? AppColors.green : AppColors.purple,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PlacementRow extends StatelessWidget {
  final String label;
  final String value;
  final VoidCallback? onTap;
  final bool monospace;

  const _PlacementRow({
    required this.label,
    required this.value,
    this.onTap,
    this.monospace = false,
  });

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            width: 112,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
            color: AppColors.purpleSoft,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                color: AppColors.text,
              ),
            ),
          ),
          const VerticalDivider(width: 1),
          Expanded(
            child: InkWell(
              onTap: onTap,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 11,
                ),
                child: Text(
                  value,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    fontFamily: monospace ? 'monospace' : null,
                    color: onTap != null ? AppColors.purple : AppColors.ink,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PrevNextButton extends StatelessWidget {
  final String label;
  final String unitName;
  final bool isNext;
  final VoidCallback onTap;

  const _PrevNextButton({
    required this.label,
    required this.unitName,
    required this.isNext,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppRadii.lg),
        border: Border.all(color: AppColors.line),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadii.lg),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: isNext
                ? CrossAxisAlignment.end
                : CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (!isNext) ...[
                    const Icon(
                      LucideIcons.arrowLeft,
                      size: 13,
                      color: AppColors.purple,
                    ),
                    const SizedBox(width: 4),
                  ],
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                      color: AppColors.purple,
                    ),
                  ),
                  if (isNext) ...[
                    const SizedBox(width: 4),
                    const Icon(
                      LucideIcons.arrowRight,
                      size: 13,
                      color: AppColors.purple,
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 4),
              Text(
                unitName,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textAlign: isNext ? TextAlign.end : TextAlign.start,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.ink,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
