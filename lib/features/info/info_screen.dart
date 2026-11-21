import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/pill_badge.dart';

class InfoScreen extends StatelessWidget {
  final String pageKey; // about | contact | privacy | terms

  const InfoScreen({super.key, required this.pageKey});

  static const _supportEmail = 'masomo@darasahub.com';

  Future<void> _launchEmail(BuildContext context, {String? subject}) async {
    final uri = Uri(
      scheme: 'mailto',
      path: _supportEmail,
      queryParameters: subject != null ? {'subject': subject} : null,
    );
    final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!launched && context.mounted) {
      await _copyEmail(context);
    }
  }

  Future<void> _copyEmail(BuildContext context) async {
    await Clipboard.setData(const ClipboardData(text: _supportEmail));
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Copied $_supportEmail to clipboard'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

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
                if (content.subtitle != null) ...[
                  const SizedBox(height: 6),
                  Text(
                    content.subtitle!,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
                const SizedBox(height: 16),
                ...content.sections.map(
                  (section) => Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (section.title != null) ...[
                          Text(
                            section.title!,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: AppColors.ink,
                            ),
                          ),
                          const SizedBox(height: 6),
                        ],
                        Text(
                          section.body,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                ),
                const Divider(height: 24),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.purpleSoft,
                    borderRadius: BorderRadius.circular(AppRadii.lg),
                    border: Border.all(color: AppColors.line),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Need help or have a question?',
                        style: TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w700,
                          color: AppColors.ink,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Contact our support team directly at $_supportEmail',
                        style: TextStyle(
                          fontSize: 12.5,
                          color: AppColors.text,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          ElevatedButton.icon(
                            onPressed: () => _launchEmail(
                              context,
                              subject: 'EasyTVET Hub: ${content.title}',
                            ),
                            icon: const Icon(LucideIcons.mail, size: 15),
                            label: const Text('Email Support'),
                          ),
                          OutlinedButton.icon(
                            onPressed: () => _copyEmail(context),
                            icon: const Icon(LucideIcons.copy, size: 15),
                            label: const Text('Copy Email'),
                          ),
                        ],
                      ),
                    ],
                  ),
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
          subtitle: 'Direct email support: $_supportEmail',
          icon: LucideIcons.mail,
          sections: [
            _InfoSection(
              title: 'Past Paper & Resource Requests',
              body:
                  'Need a specific CDACC Modular, CDACC Cycle 1 & 2, or KNEC past paper, cutting list, candidate tool, or assessor guide that is not yet listed? Send us an email with the course name, qualification level, and unit title or unit code.',
            ),
            _InfoSection(
              title: 'Report Issues & Feedback',
              body:
                  'If you notice a broken PDF link, an incorrectly categorized unit, or a technical issue in the app, please let us know at $_supportEmail so our team can fix it promptly.',
            ),
            _InfoSection(
              title: 'Copyright & Content Inquiries',
              body:
                  'For institutional partnerships, attribution questions, or content removal requests, reach out directly to $_supportEmail.',
            ),
          ],
        );
      case 'privacy':
        return const _InfoPageContent(
          title: 'Privacy Policy',
          badge: 'Data & Privacy',
          heading: 'Privacy Policy',
          subtitle: 'Last updated: November 2026',
          icon: LucideIcons.shieldCheck,
          sections: [
            _InfoSection(
              title: '1. No User Accounts & No Personal Data Collection',
              body:
                  'EasyTVET Hub is a read-only educational companion app. We do not offer user registration, login, or personal profiles, and we do not collect personally identifiable information such as your name, phone number, location, or contacts.',
            ),
            _InfoSection(
              title: '2. Local On-Device Storage',
              body:
                  'Any past papers you download for offline study, bookmarked courses or units, and the cached offline search index are stored exclusively on your device. You can remove downloaded files and bookmarks at any time inside the Saved tab, or remove all local data by clearing the app storage or uninstalling the app.',
            ),
            _InfoSection(
              title: '3. Internet Access & Third-Party Hosting',
              body:
                  'The app connects to the internet only to fetch publicly available TVET course directories, revision guides, and downloadable PDF documents. Standard technical connection metadata (such as IP address and request timestamps) may be processed transiently by our cloud database and file-hosting providers solely to deliver content reliably and securely.',
            ),
            _InfoSection(
              title: '4. Data Sharing & Advertising',
              body:
                  'We do not sell, rent, or trade user data to third parties. Because no user accounts or personal profiles exist, there is no server-side personal user data stored about you.',
            ),
            _InfoSection(
              title: '5. Children\'s Privacy',
              body:
                  'EasyTVET Hub is designed for Kenyan TVET trainees and trainers and does not knowingly collect personal information from children under 13 or from any other users.',
            ),
            _InfoSection(
              title: '6. Policy Updates & Contact',
              body:
                  'We may update this Privacy Policy in-app as the application evolves. If you have any privacy questions or concerns, please email us at $_supportEmail.',
            ),
          ],
        );
      case 'terms':
        return const _InfoPageContent(
          title: 'Terms & Conditions',
          badge: 'Academic Use',
          heading: 'Terms & Conditions',
          subtitle: 'Last updated: November 2026',
          icon: LucideIcons.fileText,
          sections: [
            _InfoSection(
              title: '1. Acceptance of Terms',
              body:
                  'By accessing or using the EasyTVET Hub mobile application, you agree to these Terms & Conditions. If you do not agree, please discontinue use of the app.',
            ),
            _InfoSection(
              title: '2. Educational Use Only',
              body:
                  'All past papers, assessment tools, cutting lists, and revision guides provided in EasyTVET Hub are intended strictly for personal academic study, training, and examination revision for TVET trainees and trainers.',
            ),
            _InfoSection(
              title: '3. Independence from Examination Bodies',
              body:
                  'EasyTVET Hub is an independent educational study companion and is not officially affiliated with, endorsed by, or operated by TVET CDACC, KNEC, or the Ministry of Education. All official trademarks, curricula, and examination names belong to their respective authorities.',
            ),
            _InfoSection(
              title: '4. Accuracy & Availability',
              body:
                  'While we strive to keep course directories, past papers, and revision guides accurate and accessible, all materials are provided "as is" without warranties of any kind. Trainees should always verify official examination dates, registration procedures, and circulars with their TVET institution or the relevant examination body.',
            ),
            _InfoSection(
              title: '5. Acceptable Use & Intellectual Property',
              body:
                  'You may download available study materials for personal offline revision. Commercial redistribution or automated scraping of app content is not permitted. If you believe any material infringes your rights, please contact $_supportEmail for prompt review.',
            ),
          ],
        );
      case 'about':
      default:
        return const _InfoPageContent(
          title: 'About Us',
          badge: 'EasyTVET Hub Kenya',
          heading: 'Empowering Kenyan TVET Trainees',
          subtitle: 'Offline-ready CDACC & KNEC Study Companion',
          icon: LucideIcons.info,
          sections: [
            _InfoSection(
              title: 'Our Mission',
              body:
                  'EasyTVET Hub organizes CDACC Modular (Cycle 3), Non-Modular CDACC (Cycle 1 & 2), and KNEC past papers, assessment tools, cutting lists, and CBET revision guides into a clean, searchable academic directory built for Kenyan TVET trainees and trainers.',
            ),
            _InfoSection(
              title: 'Built for Offline Revision',
              body:
                  'Save past papers and guides directly to your device so you can revise anytime without relying on mobile data. No account or sign-in is required to access any study resource.',
            ),
          ],
        );
    }
  }
}

class _InfoSection {
  final String? title;
  final String body;

  const _InfoSection({this.title, required this.body});
}

class _InfoPageContent {
  final String title;
  final String badge;
  final String heading;
  final String? subtitle;
  final IconData icon;
  final List<_InfoSection> sections;

  const _InfoPageContent({
    required this.title,
    required this.badge,
    required this.heading,
    this.subtitle,
    required this.icon,
    required this.sections,
  });
}
