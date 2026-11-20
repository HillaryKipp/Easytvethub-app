import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../data/models/directory_models.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';

class FaqAccordion extends StatefulWidget {
  final List<FaqItem> items;
  final String title;

  const FaqAccordion({
    super.key,
    required this.items,
    this.title = 'Frequently Asked Questions',
  });

  @override
  State<FaqAccordion> createState() => _FaqAccordionState();
}

class _FaqAccordionState extends State<FaqAccordion> {
  final Set<int> _expanded = {};

  @override
  Widget build(BuildContext context) {
    if (widget.items.isEmpty) return const SizedBox.shrink();

    return Container(
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
                  LucideIcons.circleHelp,
                  size: 18,
                  color: AppColors.purple,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  widget.title,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ...widget.items.asMap().entries.map((entry) {
            final idx = entry.key;
            final item = entry.value;
            final isOpen = _expanded.contains(idx);

            return Container(
              margin: EdgeInsets.only(
                bottom: idx == widget.items.length - 1 ? 0 : 10,
              ),
              decoration: BoxDecoration(
                color: AppColors.purpleSoft,
                borderRadius: BorderRadius.circular(AppRadii.md),
                border: Border.all(color: AppColors.line),
              ),
              child: InkWell(
                borderRadius: BorderRadius.circular(AppRadii.md),
                onTap: () {
                  setState(() {
                    if (isOpen) {
                      _expanded.remove(idx);
                    } else {
                      _expanded.add(idx);
                    }
                  });
                },
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              item.question,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: AppColors.ink,
                                height: 1.35,
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
                      if (isOpen) ...[
                        const SizedBox(height: 10),
                        const Divider(),
                        const SizedBox(height: 10),
                        Text(
                          item.answer,
                          style: Theme.of(context).textTheme.bodyMedium,
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
