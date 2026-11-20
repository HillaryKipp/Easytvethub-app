import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/config/env.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/pill_badge.dart';

class InfoScreen extends StatelessWidget {
  final String pageKey; // about | contact | privacy | terms

  const InfoScreen({super.key, required this.pageKey});

  @override
  Widget build(BuildContext context) {
    final content = _resolveContent(pageKey);

    return Scaffold(
      appBar: AppBar(title: Text(content.title)),
      body: ListView(
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
                PillBadge(
                  label: content.badge,
                  icon: content.icon,
                  variant: PillVariant.purple,
                ),
                const SizedBox(height: 12),
                Text(
                  content.heading,
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 12),
                ...content.paragraphs.map(
                  (p) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Text(
                      p,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                ElevatedButton.icon(
                  onPressed: () {
                    launchUrl(
                      Uri.parse(Env.canonicalUrl(content.webPath)),
                      mode: LaunchMode.externalApplication,
                    );
                  },
                  icon: const Icon(LucideIcons.externalLink, size: 16),
                  label: Text('Open ${content.title} on easytvethub.com'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  _InfoPageContent _resolveContent(String key) {
    switch (key) {
      case 'contact':
        return const _InfoPageContent(
          title: 'Contact Us',
          badge: 'Support & Paper Requests',
          heading: 'Get in Touch with EasyTVET Hub',
          icon: LucideIcons.mail,
          webPath: '/contact-us',
          paragraphs: [
            'Need a specific CDACC or KNEC past paper, cutting list, or assessment tool that is not yet listed? Reach out to our editorial team via our website contact form.',
            'We prioritize requests from Kenyan TVET trainees preparing for upcoming modular and non-modular CDACC and KNEC examination cycles.',
          ],
        );
      case 'privacy':
        return const _InfoPageContent(
          title: 'Privacy Policy',
          badge: 'Data & Privacy',
          heading: 'Your Privacy on EasyTVET Hub',
          icon: LucideIcons.shieldCheck,
          webPath: '/privacy-policy',
          paragraphs: [
            'The EasyTVET Hub mobile app is a read-only student companion. No account creation, sign-in, or personal profile is required to browse courses, search units, or download past papers.',
            'Downloaded PDFs, bookmarks, and the offline search index are stored exclusively on your device.',
          ],
        );
      case 'terms':
        return const _InfoPageContent(
          title: 'Terms & Conditions',
          badge: 'Academic Use',
          heading: 'Terms of Use',
          icon: LucideIcons.fileText,
          webPath: '/terms-and-conditions',
          paragraphs: [
            'All past papers, curriculum guides, and revision materials on EasyTVET Hub are provided for educational and examination revision purposes for Kenyan TVET trainees and trainers.',
            'For the complete and latest legal terms, please review the full Terms & Conditions page on easytvethub.com.',
          ],
        );
      case 'about':
      default:
        return const _InfoPageContent(
          title: 'About Us',
          badge: 'EasyTVET Hub Kenya',
          heading: 'Empowering Kenyan TVET Trainees',
          icon: LucideIcons.info,
          webPath: '/about-us',
          paragraphs: [
            'EasyTVET Hub organizes CDACC Modular (Cycle 3), CDACC Cycle 1 & 2, and KNEC past papers, assessment tools, cutting lists, and CBET revision guides into a clean, searchable academic directory.',
            'This mobile app mirrors easytvethub.com with offline PDF downloads and synced offline search so trainees can revise anywhere without burning mobile data.',
          ],
        );
    }
  }
}

class _InfoPageContent {
  final String title;
  final String badge;
  final String heading;
  final IconData icon;
  final String webPath;
  final List<String> paragraphs;

  const _InfoPageContent({
    required this.title,
    required this.badge,
    required this.heading,
    required this.icon,
    required this.webPath,
    required this.paragraphs,
  });
}
