import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/blog/article_screen.dart';
import '../../features/blog/author_screen.dart';
import '../../features/blog/blog_list_screen.dart';
import '../../features/directory/course_screen.dart';
import '../../features/directory/department_screen.dart';
import '../../features/directory/level_hub_screen.dart';
import '../../features/directory/programme_screen.dart';
import '../../features/directory/unit_screen.dart';
import '../../features/downloads/downloads_screen.dart';
import '../../features/home/home_screen.dart';
import '../../features/info/info_screen.dart';
import '../../features/search/search_screen.dart';
import '../widgets/app_shell.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'root');

final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/',
    redirect: (context, state) {
      // Normalize trailing slashes from web deep links or search-index.json paths
      final path = state.uri.path;
      if (path.length > 1 && path.endsWith('/')) {
        return path.substring(0, path.length - 1);
      }
      return null;
    },
    routes: [
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return AppShell(navigationShell: navigationShell);
        },
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/',
                builder: (context, state) => const HomeScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/search',
                builder: (context, state) => const SearchScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/blog',
                builder: (context, state) => const BlogListScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/saved',
                builder: (context, state) => const DownloadsScreen(),
              ),
            ],
          ),
        ],
      ),

      // Specific static / prefixed deep-link routes (must come before /:programmeSlug)
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: '/levels/:levelSlug',
        builder: (context, state) {
          final raw = state.pathParameters['levelSlug'] ?? 'level-6';
          final match = RegExp(r'(\d+)').firstMatch(raw);
          final level = int.tryParse(match?.group(1) ?? '6') ?? 6;
          return LevelHubScreen(level: level.clamp(3, 6));
        },
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: '/blog/:slug',
        builder: (context, state) {
          final slug = state.pathParameters['slug']!;
          return ArticleScreen(slug: slug);
        },
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: '/authors/:slug',
        builder: (context, state) {
          final slug = state.pathParameters['slug']!;
          return AuthorScreen(slug: slug);
        },
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: '/info/:pageKey',
        builder: (context, state) {
          final pageKey = state.pathParameters['pageKey'] ?? 'about';
          return InfoScreen(pageKey: pageKey);
        },
      ),
      // Web info path aliases for universal deep linking
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: '/about-us',
        builder: (_, __) => const InfoScreen(pageKey: 'about'),
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: '/contact-us',
        builder: (_, __) => const InfoScreen(pageKey: 'contact'),
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: '/privacy-policy',
        builder: (_, __) => const InfoScreen(pageKey: 'privacy'),
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: '/terms-and-conditions',
        builder: (_, __) => const InfoScreen(pageKey: 'terms'),
      ),

      // Directory hierarchy routes matching easytvethub.com 1:1
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: '/:programmeSlug',
        builder: (context, state) {
          return ProgrammeScreen(
            programmeSlug: state.pathParameters['programmeSlug']!,
          );
        },
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: '/:programmeSlug/:departmentSlug',
        builder: (context, state) {
          return DepartmentScreen(
            programmeSlug: state.pathParameters['programmeSlug']!,
            departmentSlug: state.pathParameters['departmentSlug']!,
          );
        },
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: '/:programmeSlug/:departmentSlug/:courseSlug',
        builder: (context, state) {
          return CourseScreen(
            programmeSlug: state.pathParameters['programmeSlug']!,
            departmentSlug: state.pathParameters['departmentSlug']!,
            courseSlug: state.pathParameters['courseSlug']!,
          );
        },
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: '/:programmeSlug/:departmentSlug/:courseSlug/:unitSlug',
        builder: (context, state) {
          return UnitScreen(
            programmeSlug: state.pathParameters['programmeSlug']!,
            departmentSlug: state.pathParameters['departmentSlug']!,
            courseSlug: state.pathParameters['courseSlug']!,
            unitSlug: state.pathParameters['unitSlug']!,
          );
        },
      ),
    ],
  );
});
