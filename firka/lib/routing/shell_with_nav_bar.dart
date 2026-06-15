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
            padding: const EdgeInsets.fromLTRB(55, 16, 55, 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                ...[
                  (data.l10n.home, Majesticon.homeSolid, Majesticon.homeLine),
                  (
                    data.l10n.grades,
                    Majesticon.bookmarkSolid,
                    Majesticon.bookmarkLine,
                  ),
                  (
                    data.l10n.timetable,
                    Majesticon.calendarSolid,
                    Majesticon.calendarLine,
                  ),
                  (
                    initData.l10n.omissions,
                    Majesticon.timerSolid,
                    Majesticon.timerLine,
                  ),
                ].indexed.map(
                  (nav) => BottomNavIconWidget(
                    () {
                      if (currentIndex != nav.$1) {
                        navigationShell.goBranch(nav.$1);
                      }
                    },
                    currentIndex == nav.$1,
                    currentIndex == nav.$1 ? nav.$2.$2 : nav.$2.$3,
                    nav.$2.$1,
                  ),
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
