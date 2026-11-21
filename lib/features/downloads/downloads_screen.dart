import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/empty_error_views.dart';
import '../../core/widgets/pill_badge.dart';
import '../../data/repositories/downloads_repository.dart';
import '../directory/pdf_viewer_screen.dart';

class DownloadsScreen extends ConsumerStatefulWidget {
  const DownloadsScreen({super.key});

  @override
  ConsumerState<DownloadsScreen> createState() => _DownloadsScreenState();
}

class _DownloadsScreenState extends ConsumerState<DownloadsScreen> {
  int _tabIndex = 0; // 0 = Offline PDFs, 1 = Bookmarks

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(downloadsProvider);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(LucideIcons.menu, size: 22),
          onPressed: () => Scaffold.maybeOf(context)?.openDrawer(),
        ),
        title: const Text('Saved & Offline'),
      ),
      body: Column(
        children: [
          Container(
            color: AppColors.white,
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(AppRadii.pill),
                border: Border.all(color: AppColors.line),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: _SegmentButton(
                      label: 'Offline PDFs (${state.pdfs.length})',
                      selected: _tabIndex == 0,
                      onTap: () => setState(() => _tabIndex = 0),
                    ),
                  ),
                  Expanded(
                    child: _SegmentButton(
                      label: 'Bookmarks (${state.bookmarks.length})',
                      selected: _tabIndex == 1,
                      onTap: () => setState(() => _tabIndex = 1),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: !state.isLoaded
                ? const LoadingSkeletonList(itemCount: 4, itemHeight: 84)
                : _tabIndex == 0
                    ? _buildOfflinePdfs(context, state)
                    : _buildBookmarks(context, state),
          ),
        ],
      ),
    );
  }

  Widget _buildOfflinePdfs(BuildContext context, DownloadsState state) {
    if (state.pdfs.isEmpty) {
      return EmptyStateCard(
        icon: LucideIcons.download,
        title: 'No Offline PDFs Yet',
        message:
            'Tap the download icon on any CDACC or KNEC past paper to save it here for 100% offline revision.',
        actionLabel: 'Browse Courses',
        onAction: () => context.go('/'),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: state.pdfs.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final pdf = state.pdfs[index];
        return Container(
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(AppRadii.lg),
            border: Border.all(color: AppColors.line),
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(AppRadii.lg),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => PdfViewerScreen(
                    title: pdf.title,
                    unitName: pdf.unitName,
                    courseName: pdf.courseName,
                    localPath: pdf.localPath,
                    originalUrl: pdf.originalUrl,
                    webPath: pdf.webPath,
                  ),
                ),
              );
            },
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.greenTint,
                      borderRadius: BorderRadius.circular(AppRadii.md),
                    ),
                    child: const Icon(
                      LucideIcons.fileCheck,
                      size: 20,
                      color: AppColors.green,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          pdf.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: AppColors.ink,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${pdf.unitName} • ${pdf.courseName}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.muted,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Wrap(
                          spacing: 6,
                          runSpacing: 4,
                          children: [
                            PillBadge(
                              label: pdf.resourceTypeLabel,
                              variant: PillVariant.purple,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                            ),
                            if (pdf.year != null)
                              PillBadge(
                                label: '${pdf.year}',
                                variant: PillVariant.red,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2,
                                ),
                              ),
                            PillBadge(
                              label: 'Offline Ready',
                              variant: PillVariant.green,
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
                  IconButton(
                    icon: const Icon(
                      LucideIcons.trash2,
                      size: 18,
                      color: AppColors.muted,
                    ),
                    tooltip: 'Delete Offline File',
                    onPressed: () {
                      ref
                          .read(downloadsProvider.notifier)
                          .removeDownload(pdf.resourceId);
                    },
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildBookmarks(BuildContext context, DownloadsState state) {
    if (state.bookmarks.isEmpty) {
      return EmptyStateCard(
        icon: LucideIcons.bookmark,
        title: 'No Bookmarks Yet',
        message:
            'Bookmark your current courses or revision units to jump back to them quickly.',
        actionLabel: 'Search Courses & Units',
        onAction: () => context.push('/search'),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: state.bookmarks.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final bm = state.bookmarks[index];
        return Container(
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(AppRadii.lg),
            border: Border.all(color: AppColors.line),
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(AppRadii.lg),
            onTap: () => context.push(bm.path),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.purpleTint,
                      borderRadius: BorderRadius.circular(AppRadii.md),
                    ),
                    child: Icon(
                      bm.type == 'course'
                          ? LucideIcons.graduationCap
                          : LucideIcons.bookOpen,
                      size: 20,
                      color: AppColors.purple,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          bm.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: AppColors.ink,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          bm.subtitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.muted,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Wrap(
                          spacing: 6,
                          children: [
                            PillBadge(
                              label: bm.type.toUpperCase(),
                              variant: PillVariant.purple,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                            ),
                            if (bm.level != null)
                              PillBadge(
                                label: 'Level ${bm.level}',
                                variant: PillVariant.red,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2,
                                ),
                              ),
                            Text(
                              formatDate(bm.savedAt),
                              style: const TextStyle(
                                fontSize: 11,
                                color: AppColors.muted,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(
                      LucideIcons.x,
                      size: 18,
                      color: AppColors.muted,
                    ),
                    tooltip: 'Remove Bookmark',
                    onPressed: () {
                      ref
                          .read(downloadsProvider.notifier)
                          .removeBookmark(bm.id);
                    },
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _SegmentButton extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _SegmentButton({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(AppRadii.pill),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(vertical: 9),
        decoration: BoxDecoration(
          color: selected ? AppColors.purple : Colors.transparent,
          borderRadius: BorderRadius.circular(AppRadii.pill),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w700,
            color: selected ? AppColors.white : AppColors.text,
          ),
        ),
      ),
    );
  }
}
