import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../../data/models/blog_models.dart';

enum PillVariant {
  purple,
  red,
  neutral,
  sky,
  amber,
  teal,
  green,
  solidPurple,
  solidRed,
}

class PillBadge extends StatelessWidget {
  final String label;
  final PillVariant variant;
  final IconData? icon;
  final bool monospace;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry? padding;

  const PillBadge({
    super.key,
    required this.label,
    this.variant = PillVariant.purple,
    this.icon,
    this.monospace = false,
    this.onTap,
    this.padding,
  });

  factory PillBadge.forCategory(ArticleCategory category) {
    switch (category) {
      case ArticleCategory.examNews:
        return PillBadge(label: category.label, variant: PillVariant.red);
      case ArticleCategory.revisionGuide:
        return PillBadge(label: category.label, variant: PillVariant.purple);
      case ArticleCategory.courseSpotlight:
        return PillBadge(label: category.label, variant: PillVariant.amber);
      case ArticleCategory.curriculumUpdate:
        return PillBadge(label: category.label, variant: PillVariant.sky);
    }
  }

  @override
  Widget build(BuildContext context) {
    final (bg, fg, border) = switch (variant) {
      PillVariant.purple => (
        AppColors.purpleTint,
        AppColors.purple,
        Colors.transparent,
      ),
      PillVariant.red => (
        AppColors.redTint,
        AppColors.red,
        Colors.transparent,
      ),
      PillVariant.neutral => (
        AppColors.surface,
        AppColors.text,
        AppColors.line,
      ),
      PillVariant.sky => (
        AppColors.skyTint,
        AppColors.skyText,
        Colors.transparent,
      ),
      PillVariant.amber => (
        AppColors.amberBadgeTint,
        AppColors.amberBadgeText,
        Colors.transparent,
      ),
      PillVariant.teal => (
        AppColors.tealTint,
        AppColors.teal,
        Colors.transparent,
      ),
      PillVariant.green => (
        AppColors.greenTint,
        AppColors.green,
        Colors.transparent,
      ),
      PillVariant.solidPurple => (
        AppColors.purple,
        AppColors.white,
        Colors.transparent,
      ),
      PillVariant.solidRed => (
        AppColors.red,
        AppColors.white,
        Colors.transparent,
      ),
    };

    final child = Container(
      padding:
          padding ?? const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppRadii.pill),
        border: border == Colors.transparent
            ? null
            : Border.all(color: border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 12, color: fg),
            const SizedBox(width: 4),
          ],
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
                color: fg,
                fontFamily: monospace ? 'monospace' : null,
                height: 1.2,
              ),
            ),
          ),
        ],
      ),
    );

    if (onTap == null) return child;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadii.pill),
      child: child,
    );
  }
}
