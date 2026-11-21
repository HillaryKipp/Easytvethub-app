import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import 'brand_logo.dart';

class AppShell extends StatefulWidget {
  final Widget child;
  final String currentLocation;
  final GlobalKey<NavigatorState> shellNavigatorKey;

  const AppShell({
    super.key,
    required this.child,
    required this.currentLocation,
    required this.shellNavigatorKey,
  });

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  DateTime? _lastBackPress;

  static const _tabRoutes = [
    '/',
    '/tab/modular',
    '/tab/non-modular',
    '/tab/knec',
    '/saved',
  ];

  int _selectedIndex(String location) {
    final path = location.toLowerCase();
    if (path == '/saved' || path.startsWith('/saved/')) {
      return 4;
    }
    if (path == '/tab/knec' || path.contains('knec')) {
      return 3;
    }
    if (path == '/tab/non-modular' || path.contains('non-modular')) {
      return 2;
    }
    if (path == '/tab/modular' || path.contains('modular')) {
      return 1;
    }
    return 0;
  }

  void _handleBackNavigation() {
    if (_scaffoldKey.currentState?.isDrawerOpen ?? false) {
      _scaffoldKey.currentState!.closeDrawer();
      return;
    }

    final shellNav = widget.shellNavigatorKey.currentState;
    if (shellNav != null && shellNav.canPop()) {
      shellNav.pop();
      return;
    }

    if (widget.currentLocation != '/') {
      context.go('/');
      return;
    }

    final now = DateTime.now();
    if (_lastBackPress == null ||
        now.difference(_lastBackPress!) > const Duration(seconds: 2)) {
      _lastBackPress = now;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text('Press back again to exit EasyTVET Hub'),
            duration: Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
          ),
        );
      return;
    }

    SystemNavigator.pop();
  }

  @override
  Widget build(BuildContext context) {
    final selectedIndex = _selectedIndex(widget.currentLocation);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        _handleBackNavigation();
      },
      child: Scaffold(
        key: _scaffoldKey,
        drawer: const AppUtilityDrawer(),
        body: widget.child,
        bottomNavigationBar: Container(
          decoration: const BoxDecoration(
            border: Border(top: BorderSide(color: AppColors.line)),
          ),
          child: NavigationBar(
            selectedIndex: selectedIndex,
            onDestinationSelected: (index) {
              context.go(_tabRoutes[index]);
            },
            destinations: const [
              NavigationDestination(
                icon: Icon(LucideIcons.house),
                selectedIcon: Icon(LucideIcons.house),
                label: 'Home',
              ),
              NavigationDestination(
                icon: Icon(LucideIcons.layers),
                selectedIcon: Icon(LucideIcons.layers),
                label: 'Modular',
              ),
              NavigationDestination(
                icon: Icon(LucideIcons.bookMarked),
                selectedIcon: Icon(LucideIcons.bookMarked),
                label: 'Non Modular',
              ),
              NavigationDestination(
                icon: Icon(LucideIcons.award),
                selectedIcon: Icon(LucideIcons.award),
                label: 'KNEC',
              ),
              NavigationDestination(
                icon: Icon(LucideIcons.download),
                selectedIcon: Icon(LucideIcons.download),
                label: 'Saved',
              ),
            ],
          ),
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
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  BrandLogo(height: 44, showWordmark: false),
                  SizedBox(height: 10),
                  Text(
                    'EasyTVET Hub',
                    textAlign: TextAlign.center,
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
                    textAlign: TextAlign.center,
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
                'EasyTVET Hub • Student Companion App',
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
