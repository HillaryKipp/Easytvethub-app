import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';

/// Displays `assets/logo.jpg` when present, or a clean EasyTVET Hub monogram fallback.
class BrandLogo extends StatelessWidget {
  final double height;
  final bool showWordmark;

  const BrandLogo({
    super.key,
    this.height = 34,
    this.showWordmark = true,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          height: height,
          width: height,
          padding: const EdgeInsets.all(2),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(AppRadii.sm),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(AppRadii.sm - 2),
            child: Image.asset(
              'assets/easytvethub.png',
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) => Container(
                decoration: BoxDecoration(
                  gradient: AppColors.heroGradient,
                  borderRadius: BorderRadius.circular(AppRadii.sm - 2),
                ),
                child: const Icon(
                  LucideIcons.graduationCap,
                  color: AppColors.white,
                  size: 18,
                ),
              ),
            ),
          ),
        ),
        if (showWordmark) ...[
          const SizedBox(width: 10),
          RichText(
            text: const TextSpan(
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.4,
                color: AppColors.ink,
              ),
              children: [
                TextSpan(text: 'EasyTVET '),
                TextSpan(
                  text: 'Hub',
                  style: TextStyle(color: AppColors.purple),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}
