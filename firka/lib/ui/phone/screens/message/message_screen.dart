import 'package:firka/helpers/extensions.dart';
import 'package:firka/main.dart';
import 'package:flutter/material.dart';
import 'package:majesticons_flutter/majesticons_flutter.dart';

import '../../../../helpers/api/model/notice_board.dart';
import '../../../../helpers/firka_bundle.dart';
import '../../../model/style.dart';
import '../../../widget/firka_icon.dart';

class MessageScreen extends StatelessWidget {
  final AppInitialization data;
  final InfoBoardItem info;

  const MessageScreen(this.data, this.info, {super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultAssetBundle(
        bundle: FirkaBundle(),
        child: Scaffold(
          backgroundColor: appStyle.colors.background,
          body: SafeArea(
            child: SizedBox(
                height: MediaQuery.of(context).size.height,
                child: Align(
                  alignment: Alignment.bottomCenter,
                  child: Container(
                    decoration: BoxDecoration(
                      color: appStyle.colors.background,
                      borderRadius:
                          BorderRadius.vertical(top: Radius.circular(16)),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Transform.translate(
                                offset: const Offset(-4, 0),
                                child: GestureDetector(
                                  child: FirkaIconWidget(
                                      FirkaIconType.majesticons,
                                      Majesticon.chevronLeftLine,
                                      color: appStyle.colors.textSecondary),
                                  onTap: () {
                                    Navigator.of(context).pop();
                                  },
                                ),
                              ),
                              Transform.translate(
                                offset: const Offset(-4, 1),
                                child: Text(
                                  data.l10n.s_a,
                                  style: appStyle.fonts.B_16R.apply(
                                      color: appStyle.colors.textPrimary),
                                ),
                              )
                            ],
                          ),
                          SizedBox(height: 56),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              SizedBox(
                                width: MediaQuery.of(context).size.width * 0.85,
                                child: Text(
                                  info.title,
                                  textAlign: TextAlign.center,
                                  style: appStyle.fonts.H_H2.apply(
                                      color: appStyle.colors.textPrimary),
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                info.date
                                    .format(data.l10n, FormatMode.yyyymmdd),
                                textAlign: TextAlign.center,
                                style: appStyle.fonts.B_16R.apply(
                                    color: appStyle.colors.textSecondary),
                              ),
                            ],
                          ),
                          SizedBox(height: 56),
                          Row(
                            children: [
                              Container(
                                decoration: ShapeDecoration(
                                    color: appStyle.colors.accent,
                                    shape: CircleBorder(
                                      eccentricity: 1,
                                    )),
                                child: SizedBox(
                                  width: 28,
                                  height: 28,
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Padding(
                                        padding:
                                            const EdgeInsets.only(bottom: 6),
                                        child: Text(
                                          info.author[0],
                                          style: appStyle.fonts.H_18px.copyWith(
                                              fontSize: 20,
                                              color:
                                                  appStyle.colors.textPrimary),
                                        ),
                                      )
                                    ],
                                  ),
                                ),
                              ),
                              SizedBox(width: 8),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  SizedBox(
                                    width:
                                        MediaQuery.of(context).size.width / 1.4,
                                    child: Text(
                                      info.author,
                                      style: appStyle.fonts.B_16SB.apply(
                                          color: appStyle.colors.textPrimary),
                                    ),
                                  )
                                ],
                              ),
                            ],
                          ),
                          SizedBox(height: 20),
                          Padding(
                            padding: const EdgeInsets.all(4),
                            child: Container(
                              decoration: BoxDecoration(
                                  color: appStyle.colors.card,
                                  borderRadius:
                                      BorderRadius.all(Radius.circular(16))),
                              child: Padding(
                                padding: const EdgeInsets.all(12),
                                child: Text(
                                  info.contentText,
                                  style: appStyle.fonts.B_16R.apply(
                                      color: appStyle.colors.textPrimary),
                                  textAlign: TextAlign.start,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                )),
          ),
        ));
  }
}
