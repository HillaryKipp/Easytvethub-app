import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/empty_error_views.dart';
import '../../core/widgets/pill_badge.dart';
import '../../data/repositories/search_repository.dart';

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();
  String _query = '';
  String _typeFilter = 'all'; // all | course | unit
  int? _levelFilter;
  bool _isFocused = false;
  bool _refreshing = false;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(() {
      if (mounted) setState(() => _isFocused = _focusNode.hasFocus);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _forceSync() async {
    setState(() => _refreshing = true);
    try {
      await ref.read(searchRepositoryProvider).getIndex(forceRefresh: true);
      ref.invalidate(searchIndexProvider);
      await ref.read(searchIndexProvider.future);
    } finally {
      if (mounted) setState(() => _refreshing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final indexAsync = ref.watch(searchIndexProvider);
    final repo = ref.watch(searchRepositoryProvider);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(LucideIcons.menu, size: 22),
          onPressed: () => Scaffold.maybeOf(context)?.openDrawer(),
        ),
        title: const Text('Search Past Papers'),
        actions: [
          IconButton(
            icon: _refreshing
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.purple,
                    ),
                  )
                : const Icon(LucideIcons.refreshCw, size: 19),
            tooltip: 'Sync Search Index',
            onPressed: _refreshing ? null : _forceSync,
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Bar & Filter Chips Container
          Container(
            color: AppColors.white,
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: _controller,
                  focusNode: _focusNode,
                  textInputAction: TextInputAction.search,
                  onChanged: (value) => setState(() => _query = value),
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: _isFocused ? AppColors.white : AppColors.surface,
                    hintText: 'Search courses, units, or unit codes...',
                    prefixIcon: const Icon(
                      LucideIcons.search,
                      size: 18,
                      color: AppColors.purple,
                    ),
                    suffixIcon: _query.isNotEmpty
                        ? IconButton(
                            icon: const Icon(
                              LucideIcons.x,
                              size: 16,
                              color: AppColors.muted,
                            ),
                            onPressed: () {
                              _controller.clear();
                              setState(() => _query = '');
                            },
                          )
                        : null,
                  ),
                ),
                const SizedBox(height: 10),
                // Type filter chips
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      for (final item in const [
                        ('all', 'All Items'),
                        ('course', 'Courses'),
                        ('unit', 'Units'),
                      ])
                        Padding(
                          padding: const EdgeInsets.only(right: 6),
                          child: _FilterChip(
                            label: item.$2,
                            selected: _typeFilter == item.$1,
                            activeColor: AppColors.purple,
                            onTap: () => setState(() => _typeFilter = item.$1),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                // Level filter chips
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: _FilterChip(
                          label: 'All Levels',
                          selected: _levelFilter == null,
                          activeColor: AppColors.red,
                          onTap: () => setState(() => _levelFilter = null),
                        ),
                      ),
                      for (final lvl in const [6, 5, 4, 3])
                        Padding(
                          padding: const EdgeInsets.only(right: 6),
                          child: _FilterChip(
                            label: 'Level $lvl',
                            selected: _levelFilter == lvl,
                            activeColor: AppColors.red,
                            onTap: () => setState(() => _levelFilter = lvl),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: indexAsync.when(
              loading: () =>
                  const LoadingSkeletonList(itemCount: 6, itemHeight: 78),
              error: (_, __) => ErrorStateCard(
                title: 'Search Index Unavailable',
                message:
                    'Connect to the internet once to sync the offline search index.',
                onRetry: _forceSync,
              ),
              data: (snapshot) {
                final results = repo.search(
                  docs: snapshot.documents,
                  query: _query,
                  typeFilter: _typeFilter,
                  levelFilter: _levelFilter,
                );

                return RefreshIndicator(
                  color: AppColors.purple,
                  onRefresh: _forceSync,
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
                    itemCount: results.isEmpty ? 2 : results.length + 1,
                    itemBuilder: (context, index) {
                      if (index == 0) {
                        final syncText = snapshot.lastSyncedAt != null
                            ? 'Index synced ${formatDate(snapshot.lastSyncedAt)} • ${snapshot.documents.length} items'
                            : '${snapshot.documents.length} indexed items';
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: Row(
                            children: [
                              const Icon(
                                LucideIcons.zap,
                                size: 13,
                                color: AppColors.purple,
                              ),
                              const SizedBox(width: 5),
                              Expanded(
                                child: Text(
                                  syncText,
                                  style: const TextStyle(
                                    fontSize: 11.5,
                                    color: AppColors.muted,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                              Text(
                                '${results.length} shown',
                                style: const TextStyle(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.purple,
                                ),
                              ),
                            ],
                          ),
                        );
                      }

                      if (results.isEmpty) {
                        return EmptyStateCard(
                          icon: LucideIcons.searchX,
                          title: 'No matching resources',
                          message:
                              'Try another keyword, unit code, or clear your Type/Level filters.',
                          actionLabel: 'Reset Filters',
                          onAction: () {
                            _controller.clear();
                            setState(() {
                              _query = '';
                              _typeFilter = 'all';
                              _levelFilter = null;
                            });
                          },
                        );
                      }

                      final doc = results[index - 1];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        decoration: BoxDecoration(
                          color: AppColors.white,
                          borderRadius: BorderRadius.circular(AppRadii.lg),
                          border: Border.all(color: AppColors.line),
                        ),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(AppRadii.lg),
                          onTap: () => context.push(doc.normalizedPath),
                          child: Padding(
                            padding: const EdgeInsets.all(14),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        toTitleCase(doc.name),
                                        style: const TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w700,
                                          color: AppColors.ink,
                                          height: 1.3,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    const Icon(
                                      LucideIcons.chevronRight,
                                      size: 16,
                                      color: AppColors.muted,
                                    ),
                                  ],
                                ),
                                if (doc.breadcrumb.isNotEmpty) ...[
                                  const SizedBox(height: 4),
                                  Text(
                                    doc.breadcrumb,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: AppColors.muted,
                                    ),
                                  ),
                                ],
                                const SizedBox(height: 8),
                                Wrap(
                                  spacing: 6,
                                  runSpacing: 4,
                                  children: [
                                    PillBadge(
                                      label: doc.type.toUpperCase(),
                                      variant: PillVariant.purple,
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 2,
                                      ),
                                    ),
                                    if (doc.level != null)
                                      PillBadge(
                                        label: 'Level ${doc.level}',
                                        variant: PillVariant.red,
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 2,
                                        ),
                                      ),
                                    if (doc.code != null &&
                                        doc.code!.trim().isNotEmpty)
                                      PillBadge(
                                        label: doc.code!.trim(),
                                        variant: PillVariant.neutral,
                                        monospace: true,
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 2,
                                        ),
                                      ),
                                    if (doc.resourceCount != null &&
                                        doc.resourceCount! > 0)
                                      PillBadge(
                                        label:
                                            '${doc.resourceCount} paper${doc.resourceCount == 1 ? '' : 's'}',
                                        icon: LucideIcons.fileText,
                                        variant: PillVariant.red,
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
                        ),
                      );
                    },
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

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final Color activeColor;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.selected,
    required this.activeColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(AppRadii.pill),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? activeColor : AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadii.pill),
          border: Border.all(
            color: selected ? activeColor : AppColors.line,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: selected ? AppColors.white : AppColors.text,
          ),
        ),
      ),
    );
  }
}
