import 'dart:collection';

import 'package:flutter/material.dart';
import 'package:firka/core/firka_bundle.dart';
import 'package:firka/app/app_state.dart';
import 'package:firka/core/settings.dart';
import 'package:firka/ui/phone/pages/home/home_grades.dart';
import 'package:firka/ui/phone/pages/home/home_grades_subject.dart';
import 'package:firka/ui/phone/pages/home/home_main.dart';
import 'package:firka/ui/phone/pages/home/home_timetable.dart';
import 'package:firka/ui/phone/pages/home/home_timetable_mo.dart';
import 'package:firka/ui/phone/screens/debug/debug_screen.dart';
import 'package:firka/ui/phone/screens/home/beta_screen.dart';
import 'package:firka/ui/phone/pages/error/error_page.dart';
import 'package:firka/ui/phone/screens/login/login_screen.dart';
import 'package:firka/ui/phone/screens/message/message_screen.dart';
import 'package:firka/ui/phone/screens/home/home_screen.dart';
import 'package:firka/ui/phone/screens/settings/settings_screen.dart';
import 'package:firka/routing/chart_interaction_scope.dart';
import 'package:firka/routing/shell_with_nav_bar.dart';
import 'package:firka/routing/swipable_navigator_container.dart';
import 'package:go_router/go_router.dart';

import 'package:firka/api/model/notice_board.dart';

GoRouter createAppRouter() {
  return GoRouter(
    navigatorKey: navigatorKey,
    initialLocation: _initialLocation,
    redirect: _redirect,
    routes: [
      GoRoute(
        path: '/error',
        builder: (context, state) {
          final exception = state.extra is String
              ? state.extra as String
              : 'Unknown error';
          return DefaultAssetBundle(
            bundle: FirkaBundle(),
            child: ErrorPage(key: state.pageKey, exception: exception),
          );
        },
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => DefaultAssetBundle(
          bundle: FirkaBundle(),
          child: LoginScreen(initData, key: state.pageKey),
        ),
      ),
      GoRoute(
        path: '/beta',
        builder: (context, state) => DefaultAssetBundle(
          bundle: FirkaBundle(),
          child: BetaScreen(initData, key: state.pageKey),
        ),
      ),
      GoRoute(
        path: '/debug',
        builder: (context, state) => DefaultAssetBundle(
          bundle: FirkaBundle(),
          child: DebugScreen(initData, key: state.pageKey),
        ),
      ),
      GoRoute(
        path: '/settings',
        builder: (context, state) {
          final items = state.extra != null
              ? state.extra! as LinkedHashMap<String, SettingsItem>
              : initData.settings.items;
          return DefaultAssetBundle(
            bundle: FirkaBundle(),
            child: SettingsScreen(initData, items, key: state.pageKey),
          );
        },
      ),
      GoRoute(
        path: '/message',
        builder: (context, state) {
          final info = state.extra as InfoBoardItem?;
          if (info == null) {
            return const SizedBox.shrink();
          }
          return DefaultAssetBundle(
            bundle: FirkaBundle(),
            child: MessageScreen(initData, info, key: state.pageKey),
          );
        },
      ),
      StatefulShellRoute(
        builder: (context, state, navigationShell) => DefaultAssetBundle(
          bundle: FirkaBundle(),
          child: HomeScreen(
            child: ShellWithNavBar(
              navigationShell: navigationShell,
              child: navigationShell,
            ),
          ),
        ),
        navigatorContainerBuilder: (context, navigationShell, children) {
          return ChartInteractionScope(
            child: SwipableNavigatorContainer(
              navigationShell: navigationShell,
              children: children,
            ),
          );
        },
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/home',
                pageBuilder: (context, state) => NoTransitionPage(
                  key: state.pageKey,
                  child: DefaultAssetBundle(
                    bundle: FirkaBundle(),
                    child: HomeMainScreen(initData),
                  ),
                ),
                routes: [
                  GoRoute(
                    path: 'subject/:uid',
                    builder: (context, state) {
                      final uid = state.pathParameters['uid'] ?? '';
                      activeSubjectUid = uid;
                      return DefaultAssetBundle(
                        bundle: FirkaBundle(),
                        child: HomeGradesSubjectScreen(initData),
                      );
                    },
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/grades',
                pageBuilder: (context, state) => NoTransitionPage(
                  key: state.pageKey,
                  child: DefaultAssetBundle(
                    bundle: FirkaBundle(),
                    child: HomeGradesScreen(initData),
                  ),
                ),
                routes: [
                  GoRoute(
                    path: 'subject/:uid',
                    builder: (context, state) {
                      final uid = state.pathParameters['uid'] ?? '';
                      activeSubjectUid = uid;
                      return DefaultAssetBundle(
                        bundle: FirkaBundle(),
                        child: HomeGradesSubjectScreen(initData),
                      );
                    },
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/timetable',
                pageBuilder: (context, state) => NoTransitionPage(
                  key: state.pageKey,
                  child: DefaultAssetBundle(
                    bundle: FirkaBundle(),
                    child: HomeTimetableScreen(initData),
                  ),
                ),
                routes: [
                  GoRoute(
                    path: 'monthly',
                    builder: (context, state) => DefaultAssetBundle(
                      bundle: FirkaBundle(),
                      child: HomeTimetableMonthlyScreen(initData),
                    ),
                  ),
                  GoRoute(
                    path: 'subject/:uid',
                    builder: (context, state) {
                      final uid = state.pathParameters['uid'] ?? '';
                      activeSubjectUid = uid;
                      return DefaultAssetBundle(
                        bundle: FirkaBundle(),
                        child: HomeGradesSubjectScreen(initData),
                      );
                    },
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    ],
  );
}

String get _initialLocation {
  if (!initDone) return '/';
  if (initData.tokens.isEmpty) return '/login';
  final betaWarning = initData.settings
      .group('settings')
      .boolean('beta_warning');
  if (!betaWarning) return '/beta';
  return '/home';
}

String? _redirect(BuildContext context, GoRouterState state) {
  if (!initDone) return null;
  final location = state.matchedLocation;
  final hasTokens = initData.tokens.isNotEmpty;
  final betaWarning = initData.settings
      .group('settings')
      .boolean('beta_warning');

  if (!hasTokens) {
    if (location != '/login') return '/login';
    return null;
  }

  if (!betaWarning && location != '/beta') {
    return '/beta';
  }

  if (betaWarning && location == '/beta') {
    return '/home';
  }

  if (hasTokens && location == '/login') {
    return '/home';
  }

  if (location == '/' || location.isEmpty) {
    return '/home';
  }

  return null;
}
