import "package:firka/app/app_state.dart";
import "package:firka/core/firka_bundle.dart";
import "package:firka/ui/phone/widgets/bottom_nav_icon.dart";
import "package:firka/ui/theme/style.dart";
import "package:flutter/material.dart";
import "package:intl/intl.dart";
import "package:majesticons_flutter/majesticons_flutter.dart";

/// Which bottom-nav tab is highlighted inside a theme page preview.
enum ThemePreviewNavTab { home, grades, timetable, omissions, other }

/// Phone-shaped frame that downscales a full-size home page for the theme carousel.
class ThemePagePreview extends StatelessWidget {
  static const double designWidth = 390;
  static const double designHeight = 844;

  final Widget body;
  final ThemePreviewNavTab activeTab;
  final AppInitialization data;

  const ThemePagePreview({
    super.key,
    required this.body,
    required this.activeTab,
    required this.data,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 6),
      decoration: BoxDecoration(
        color: appStyle.colors.background,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: appStyle.colors.shadowColor,
            offset: const Offset(0, 1),
            blurRadius: 2,
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: LayoutBuilder(
        builder: (context, constraints) {
          return FittedBox(
            fit: BoxFit.contain,
            alignment: Alignment.topCenter,
            child: SizedBox(
              width: designWidth,
              height: designHeight,
              child: MediaQuery(
                data: MediaQuery.of(context).copyWith(
                  size: const Size(designWidth, designHeight),
                  padding: EdgeInsets.zero,
                  viewPadding: EdgeInsets.zero,
                  viewInsets: EdgeInsets.zero,
                ),
                child: IgnorePointer(
                  child: DefaultAssetBundle(
                    bundle: FirkaBundle(),
                    child: ColoredBox(
                      color: appStyle.colors.background,
                      child: Column(
                        children: [
                          _PreviewStatusBar(),
                          Expanded(child: body),
                          _PreviewBottomNav(
                            data: data,
                            activeTab: activeTab,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _PreviewStatusBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final time = DateFormat("H:mm").format(DateTime.now());
    return SizedBox(
      height: 28,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Row(
          children: [
            Text(
              time,
              style: appStyle.fonts.B_12SB.apply(
                color: appStyle.colors.textPrimary,
              ),
            ),
            const Spacer(),
            Icon(
              Icons.signal_cellular_alt,
              size: 12,
              color: appStyle.colors.textPrimary,
            ),
            const SizedBox(width: 4),
            Icon(
              Icons.wifi,
              size: 12,
              color: appStyle.colors.textPrimary,
            ),
            const SizedBox(width: 4),
            Icon(
              Icons.battery_full,
              size: 12,
              color: appStyle.colors.textPrimary,
            ),
          ],
        ),
      ),
    );
  }
}

class _PreviewBottomNav extends StatelessWidget {
  final AppInitialization data;
  final ThemePreviewNavTab activeTab;

  const _PreviewBottomNav({
    required this.data,
    required this.activeTab,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = data.l10n;
    final tabs = <(ThemePreviewNavTab, String, Object, Object)>[
      (
        ThemePreviewNavTab.home,
        l10n.home,
        Majesticon.homeSolid,
        Majesticon.homeLine,
      ),
      (
        ThemePreviewNavTab.grades,
        l10n.grades,
        Majesticon.bookmarkSolid,
        Majesticon.bookmarkLine,
      ),
      (
        ThemePreviewNavTab.timetable,
        l10n.timetable,
        Majesticon.calendarSolid,
        Majesticon.calendarLine,
      ),
      (
        ThemePreviewNavTab.omissions,
        l10n.omissions,
        Majesticon.timerSolid,
        Majesticon.timerLine,
      ),
    ];

    return Container(
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
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            ...tabs.map((nav) {
              final active = activeTab == nav.$1;
              return BottomNavIconWidget(
                () {},
                active,
                active ? nav.$3 : nav.$4,
                nav.$2,
              );
            }),
            BottomNavIconWidget(
              () {},
              activeTab == ThemePreviewNavTab.other,
              data.profilePicture != null
                  ? data.profilePicture!
                  : Majesticon.menuLine,
              l10n.other,
              isProfilePicture: data.profilePicture != null,
            ),
          ],
        ),
      ),
    );
  }
}
