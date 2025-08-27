import 'package:firka/helpers/debug_helper.dart';
import 'package:firka/helpers/ui/firka_card.dart';
import 'package:firka/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:watch_connectivity/watch_connectivity.dart';

import '../../../model/style.dart';

void showWearBottomSheet(
    BuildContext context, AppInitialization data, String model) async {
  final watch = WatchConnectivity();
  final timetable = await data.client
      .getTimeTable(timeNow(), timeNow().add(Duration(days: 7)));

  if (timetable.err != null) {
    return;
  }

  List<Map<String, dynamic>> timetableArray = List.empty(growable: true);

  for (var l in timetable.response!) {
    timetableArray.add(l.toJson());
  }

  showModalBottomSheet(
    context: context,
    elevation: 100,
    isScrollControlled: true,
    enableDrag: false,
    isDismissible: false,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.transparent,
    constraints: BoxConstraints(
      maxHeight: MediaQuery.of(context).size.height * 0.47,
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
                color: appStyle.colors.card,
                borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    SvgPicture.asset("assets/images/wear_pair.svg"),
                    SizedBox(height: 32),
                    Center(
                      child: Text(data.l10n.pairing,
                          style: appStyle.fonts.H_14px
                              .apply(color: appStyle.colors.secondary)),
                    ),
                    Center(
                      child: Text(model,
                          style: appStyle.fonts.H_H2
                              .apply(color: appStyle.colors.textPrimary)),
                    ),
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 6),
                        child: Text(
                          data.l10n.pairing_description,
                          style: appStyle.fonts.B_14R
                              .apply(color: appStyle.colors.textPrimary),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                    SizedBox(height: 32),
                    SizedBox(
                      width: MediaQuery.of(context).size.width / 1.1,
                      child: GestureDetector(
                        child: FirkaCard(
                          left: [],
                          center: [
                            Text(
                              data.l10n.pair,
                              style: appStyle.fonts.B_14R
                                  .apply(color: appStyle.colors.textSecondary),
                            )
                          ],
                          color: appStyle.colors.accent,
                        ),
                        onTap: () {
                          watch.sendMessage({
                            "id": "init_data",
                            // "timetable": timetableArray,
                            "auth": {
                              "studentId": data.client.model.studentId,
                              "iss": data.client.model.iss,
                              "idToken": data.client.model.idToken,
                              "accessToken": data.client.model.accessToken,
                              "refreshToken": data.client.model.refreshToken,
                              "expiryDate": data.client.model.expiryDate!
                                  .millisecondsSinceEpoch,
                            },
                          });
                        },
                      ),
                    ),
                    SizedBox(height: 8),
                    SizedBox(
                      width: MediaQuery.of(context).size.width / 1.1,
                      child: GestureDetector(
                        child: FirkaCard(
                          left: [],
                          center: [
                            Text(
                              data.l10n.cancel,
                              style: appStyle.fonts.B_14R
                                  .apply(color: appStyle.colors.textSecondary),
                            )
                          ],
                          color: appStyle.colors.buttonSecondaryFill,
                        ),
                        onTap: () {
                          Navigator.pop(context);
                        },
                      ),
                    ),
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
