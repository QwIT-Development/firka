import 'package:firka/helpers/ui/firka_card.dart';
import 'package:firka/main.dart';
import 'package:firka/ui/model/style.dart';
import 'package:firka/ui/phone/screens/settings/settings_screen.dart';
import 'package:flutter/material.dart';

import '../../../../helpers/firka_bundle.dart';
import '../../screens/debug/debug_screen.dart';

void showExtrasBottomSheet(BuildContext context, AppInitialization data) {
  showModalBottomSheet(
    context: context,
    elevation: 100,
    isScrollControlled: true,
    enableDrag: true,
    backgroundColor: Colors.transparent,
    barrierColor: appStyle.colors.a15p,
    constraints: BoxConstraints(
      maxHeight: MediaQuery.of(context).size.height * 0.3,
    ),
    builder: (BuildContext context) {
      return Stack(
        children: [
          Positioned.fill(
            child: GestureDetector(
              onTap: () => Navigator.pop(context),
              behavior: HitTestBehavior.opaque,
              child: Container(color: Colors.transparent),
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              decoration: BoxDecoration(
                color: appStyle.colors.background,
                borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    GestureDetector(
                      onTap: () => {
                        Navigator.pop(context),
                        Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => DefaultAssetBundle(
                                    bundle: FirkaBundle(),
                                    child: DebugScreen(data))))
                      },
                      child: FirkaCard(
                        left: [Text('Debug screen')],
                        right: [],
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => DefaultAssetBundle(
                                    bundle: FirkaBundle(),
                                    child: SettingsScreen(
                                        data, data.settings.items))));
                      },
                      child: FirkaCard(
                        left: [Text('Settings')],
                        right: [],
                      ),
                    )
                  ],
                ),
              ),
            ),
          ),
        ],
      );
    },
  );
}
