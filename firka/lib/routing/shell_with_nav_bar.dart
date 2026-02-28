import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:majesticons_flutter/majesticons_flutter.dart';

import 'package:firka/app/app_state.dart';
import 'package:firka/ui/phone/pages/extras/extras.dart';
import 'package:firka/ui/theme/style.dart';
import 'package:firka/ui/phone/widgets/bottom_nav_icon.dart';

class ShellWithNavBar extends StatelessWidget {
  const ShellWithNavBar({
    super.key,
    required this.navigationShell,
    required this.child,
  });

  final StatefulNavigationShell navigationShell;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final data = initData;
    final currentIndex = navigationShell.currentIndex;

    return Scaffold(
      backgroundColor: appStyle.colors.background,
      body: child,
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.bottomCenter,
            end: Alignment.topCenter,
            colors: [
              appStyle.colors.background,
              appStyle.colors.background.withValues(alpha: 0.0),
            ],
            stops: const [0.0, 1.0],
          ),
        ),
        width: MediaQuery.sizeOf(context).width,
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(55, 0, 55, 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                BottomNavIconWidget(
                  () {
                    if (currentIndex != 0) {
                      navigationShell.goBranch(0);
                    }
                  },
                  currentIndex == 0,
                  currentIndex == 0
                      ? Majesticon.homeSolid
                      : Majesticon.homeLine,
                  data.l10n.home,
                  currentIndex == 0
                      ? appStyle.colors.accent
                      : appStyle.colors.secondary,
                  appStyle.colors.textPrimary,
                ),
                BottomNavIconWidget(
                  () {
                    if (currentIndex != 1) {
                      navigationShell.goBranch(1);
                    }
                  },
                  currentIndex == 1,
                  currentIndex == 1
                      ? Majesticon.bookmarkSolid
                      : Majesticon.bookmarkLine,
                  data.l10n.grades,
                  currentIndex == 1
                      ? appStyle.colors.accent
                      : appStyle.colors.secondary,
                  appStyle.colors.textPrimary,
                ),
                BottomNavIconWidget(
                  () {
                    if (currentIndex != 2) {
                      navigationShell.goBranch(2);
                    }
                  },
                  currentIndex == 2,
                  currentIndex == 2
                      ? Majesticon.calendarSolid
                      : Majesticon.calendarLine,
                  data.l10n.timetable,
                  currentIndex == 2
                      ? appStyle.colors.accent
                      : appStyle.colors.secondary,
                  appStyle.colors.textPrimary,
                ),
                BottomNavIconWidget(
                  () {
                    showExtrasBottomSheet(context, data);
                  },
                  false,
                  data.profilePicture != null
                      ? data.profilePicture!
                      : Majesticon.menuLine,
                  data.l10n.other,
                  appStyle.colors.secondary,
                  appStyle.colors.textPrimary,
                  isProfilePicture: data.profilePicture != null,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
