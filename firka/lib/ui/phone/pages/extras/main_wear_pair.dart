import 'package:firka/ui/components/firka_card.dart';
import 'package:firka/services/watch_sync_helper.dart';
import 'package:firka/services/wear_sync_cache.dart';
import 'package:firka/app/app_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'package:firka/ui/theme/style.dart';

void showWearBottomSheet(
  BuildContext context,
  AppInitialization data,
  String model,
) async {
  final payload = await buildWearSyncPayload(data.client);
  if (payload == null) return;
  if (!context.mounted) return;

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
                      child: Text(
                        data.l10n.pairing,
                        style: appStyle.fonts.H_14px.apply(
                          color: appStyle.colors.secondary,
                        ),
                      ),
                    ),
                    Center(
                      child: Text(
                        model,
                        style: appStyle.fonts.H_H2.apply(
                          color: appStyle.colors.textPrimary,
                        ),
                      ),
                    ),
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 6),
                        child: Text(
                          data.l10n.pairing_description,
                          style: appStyle.fonts.B_16R.apply(
                            color: appStyle.colors.textPrimary,
                          ),
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
                              style: appStyle.fonts.B_16R.apply(
                                color: appStyle.colors.textSecondary,
                              ),
                            ),
                          ],
                          color: appStyle.colors.accent,
                        ),
                        onTap: () {
                          final m = data.client.model;
                          WatchSyncHelper.sendMessageToWatch({
                            'id': 'init_data',
                            'auth': {
                              'studentId': m.studentId,
                              'studentIdNorm': m.studentIdNorm,
                              'iss': m.iss,
                              'idToken': m.idToken,
                              'accessToken': m.accessToken,
                              'refreshToken': m.refreshToken,
                              'expiryDate':
                                  m.expiryDate!.millisecondsSinceEpoch,
                            },
                            'lastSyncAt': payload['lastSyncAt'],
                            'timetable': payload['timetable'],
                            'grades': payload['grades'],
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
                              style: appStyle.fonts.B_16R.apply(
                                color: appStyle.colors.textSecondary,
                              ),
                            ),
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
