import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'core/config/env.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_colors.dart';
import 'core/theme/app_theme.dart';
import 'data/repositories/search_repository.dart';

class EasyTvetApp extends ConsumerStatefulWidget {
  const EasyTvetApp({super.key});

  @override
  ConsumerState<EasyTvetApp> createState() => _EasyTvetAppState();
}

class _EasyTvetAppState extends ConsumerState<EasyTvetApp> {
  @override
  void initState() {
    super.initState();
    // Kick off background sync of easytvethub.com/search-index.json (24h TTL)
    Future.microtask(() {
      ref.read(searchRepositoryProvider).getIndex();
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!Env.isConfigured) {
      return MaterialApp(
        title: 'EasyTVET Hub',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        home: const _MissingEnvScreen(),
      );
    }

    final router = ref.watch(appRouterProvider);
    return MaterialApp.router(
      title: 'EasyTVET Hub',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      routerConfig: router,
    );
  }
}

class _MissingEnvScreen extends StatelessWidget {
  const _MissingEnvScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Container(
          margin: const EdgeInsets.all(24),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(AppRadii.xxl),
            border: Border.all(color: AppColors.line),
          ),
          child: const Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(LucideIcons.settings, size: 32, color: AppColors.purple),
              SizedBox(height: 12),
              Text(
                'Supabase Configuration Required',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: AppColors.ink,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 8),
              Text(
                'Pass SUPABASE_URL and SUPABASE_ANON_KEY via --dart-define when running the app.',
                style: TextStyle(fontSize: 13.5, color: AppColors.text),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
