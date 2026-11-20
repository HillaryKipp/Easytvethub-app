import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import 'brand_logo.dart';

class AppShell extends StatelessWidget {
  final StatefulNavigationShell navigationShell;

  const AppShell({super.key, required this.navigationShell});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: const AppUtilityDrawer(),
      body: navigationShell,
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: AppColors.line)),
        ),
        child: NavigationBar(
          selectedIndex: navigationShell.currentIndex,
          onDestinationSelected: (index) {
            navigationShell.goBranch(
              index,
              initialLocation: index == navigationShell.currentIndex,
            );
          },
          destinations: const [
            NavigationDestination(
              icon: Icon(LucideIcons.house),
              selectedIcon: Icon(LucideIcons.house),
              label: 'Home',
            ),
            NavigationDestination(
              icon: Icon(LucideIcons.search),
              selectedIcon: Icon(LucideIcons.search),
              label: 'Search',
            ),
            NavigationDestination(
              icon: Icon(LucideIcons.bookOpen),
              selectedIcon: Icon(LucideIcons.bookOpen),
              label: 'Blog',
            ),
            NavigationDestination(
              icon: Icon(LucideIcons.download),
              selectedIcon: Icon(LucideIcons.download),
              label: 'Saved',
            ),
          ],
        ),
      ),
    );
  }
}

class AppUtilityDrawer extends StatelessWidget {
  const AppUtilityDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: AppColors.white,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 18),
              decoration: const BoxDecoration(
                gradient: AppColors.heroGradient,
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  BrandLogo(height: 36, showWordmark: false),
                  SizedBox(height: 12),
                  Text(
                    'EasyTVET Hub',
                    style: TextStyle(
                      color: AppColors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.3,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Kenyan TVET Past Papers & CBET Guides',
                    style: TextStyle(
                      color: Color(0xFFDCD2EA),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 12),
                children: [
                  const _DrawerSectionHeader('Qualification Levels'),
                  for (final level in [6, 5, 4, 3])
                    _DrawerNavTile(
                      icon: LucideIcons.graduationCap,
                      label: 'KNQF Level $level Hub',
                      onTap: () {
                        Navigator.of(context).pop();
                        context.push('/levels/level-$level');
                      },
                    ),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Divider(),
                  ),
                  const _DrawerSectionHeader('Information & Legal'),
                  _DrawerNavTile(
                    icon: LucideIcons.info,
                    label: 'About Us',
                    onTap: () {
                      Navigator.of(context).pop();
                      context.push('/info/about');
                    },
                  ),
                  _DrawerNavTile(
                    icon: LucideIcons.mail,
                    label: 'Contact Us',
                    onTap: () {
                      Navigator.of(context).pop();
                      context.push('/info/contact');
                    },
                  ),
                  _DrawerNavTile(
                    icon: LucideIcons.shieldCheck,
                    label: 'Privacy Policy',
                    onTap: () {
                      Navigator.of(context).pop();
                      context.push('/info/privacy');
                    },
                  ),
                  _DrawerNavTile(
                    icon: LucideIcons.fileText,
                    label: 'Terms & Conditions',
                    onTap: () {
                      Navigator.of(context).pop();
                      context.push('/info/terms');
                    },
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: AppColors.surface,
                border: Border(top: BorderSide(color: AppColors.line)),
              ),
              child: const Text(
                'easytvethub.com • Student Companion App',
                style: TextStyle(
                  fontSize: 11.5,
                  color: AppColors.muted,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DrawerSectionHeader extends StatelessWidget {
  final String title;
  const _DrawerSectionHeader(this.title);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 6),
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.7,
          color: AppColors.muted,
        ),
      ),
    );
  }
}

class _DrawerNavTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _DrawerNavTile({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      dense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 2),
      leading: Container(
        padding: const EdgeInsets.all(7),
        decoration: BoxDecoration(
          color: AppColors.purpleTint,
          borderRadius: BorderRadius.circular(AppRadii.sm),
        ),
        child: Icon(icon, size: 16, color: AppColors.purple),
      ),
      title: Text(
        label,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: AppColors.ink,
        ),
      ),
      trailing: const Icon(
        LucideIcons.chevronRight,
        size: 16,
        color: AppColors.muted,
      ),
      onTap: onTap,
    );
  }
}
