import 'dart:collection';

import 'package:firka/ui/phone/widgets/info_card.dart';
import 'package:firka/ui/phone/widgets/omission_bar.dart';
import 'package:firka_common/data/models/omission_cache_model.dart';
import 'package:firka_common/data/models/subject_cache_model.dart';
import 'package:firka_common/data/util.dart';
import 'package:firka_common/ui/shared/firka_icon.dart';
import 'package:isar_community/isar.dart';
import 'package:kreta_api/kreta_api.dart';
import 'package:firka_common/ui/components/firka_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:firka/core/state/firka_state.dart';
import 'package:firka/app/app_state.dart';
import 'package:firka/core/bloc/home_refresh_cubit.dart';
import 'package:firka/ui/theme/style.dart';
import 'package:majesticons_flutter/majesticons_flutter.dart';

class HomeOmissionsScreen extends StatefulWidget {
  final AppInitialization data;

  const HomeOmissionsScreen(this.data, {super.key});

  @override
  State<StatefulWidget> createState() => _HomeOmissionsScreen();
}

class _HomeOmissionsScreen extends FirkaState<HomeOmissionsScreen> {
  @override
  Widget build(BuildContext context) {
    return BlocListener<HomeRefreshCubit, HomeRefreshState>(
      listenWhen: (previous, current) =>
          current.refreshTrigger != previous.refreshTrigger,
      listener: (context, state) {
        setState(() {});
      },
      child: _buildContent(context),
    );
  }

  Widget _buildContent(BuildContext context) {
    final omissionItems = widget.data.client!.cache
        .getOmissions()
        .findAllSync();

    final overallExcused = omissionItems
        .where((o) => o.state == OmissionState.excused)
        .length;

    final overallUnexcused = omissionItems
        .where((o) => o.state == OmissionState.unexcused)
        .length;

    final overallPending = omissionItems
        .where((o) => o.state == OmissionState.pending)
        .length;

    return Padding(
      padding: const EdgeInsets.only(left: 20.0, right: 20.0, top: 12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.data.l10n.omissions,
            style: appStyle.fonts.H_H2.apply(
              color: appStyle.colors.textPrimary,
            ),
          ),
          SizedBox(height: 20),
          Row(
            spacing: 10,
            children: [
              Expanded(
                child: FirkaCard.single(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        spacing: 4,
                        children: [
                          FirkaIconWidget(
                            FirkaIconType.majesticonsLocal,
                            "checkSolid",
                            size: 12.0,
                            color: appStyle.colors.accent,
                          ),
                          Text(
                            overallExcused.toString(),
                            style: appStyle.fonts.H_18px.copyWith(
                              color: appStyle.colors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                      Text(
                        initData.l10n.omission_state_excused,
                        style: appStyle.fonts.B_16R.copyWith(
                          color: appStyle.colors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Expanded(
                child: FirkaCard.single(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        spacing: 4,
                        children: [
                          FirkaIconWidget(
                            FirkaIconType.majesticons,
                            Majesticon.timerSolid,
                            size: 12.0,
                            color: appStyle.colors.warningAccent,
                          ),
                          Text(
                            overallPending.toString(),
                            style: appStyle.fonts.H_18px.copyWith(
                              color: appStyle.colors.warningAccent,
                            ),
                          ),
                        ],
                      ),
                      Text(
                        initData.l10n.omission_state_pending,
                        style: appStyle.fonts.B_16R.copyWith(
                          color: appStyle.colors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Expanded(
                child: FirkaCard.single(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        spacing: 4,
                        children: [
                          FirkaIconWidget(
                            FirkaIconType.majesticons,
                            Majesticon.restrictedSolid,
                            size: 12.0,
                            color: appStyle.colors.errorAccent,
                          ),
                          Text(
                            overallUnexcused.toString(),
                            style: appStyle.fonts.H_18px.copyWith(
                              color: appStyle.colors.errorAccent,
                            ),
                          ),
                        ],
                      ),
                      Text(
                        initData.l10n.omission_state_unexcused,
                        style: appStyle.fonts.B_16R.copyWith(
                          color: appStyle.colors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 10),
          OmissionBar(),
          SizedBox(height: 20),
          Expanded(
            child: ListView(
              children: [
                Text(
                  initData.l10n.subjects,
                  style: appStyle.fonts.B_16SB.copyWith(
                    color: appStyle.colors.textPrimary,
                  ),
                ),
                SizedBox(height: 10),
                ...omissionItems
                    .fold(
                      LinkedHashMap<
                        SubjectCacheModel,
                        List<OmissionCacheModel>
                      >(
                        equals: (a, b) => a.cacheKey == b.cacheKey,
                        hashCode: (a) => a.cacheKey,
                      ),
                      (map, o) => map
                        ..putIfAbsent(
                          o.lesson.loadAndGet()!.subject.loadAndGet()!,
                          () => [],
                        ).add(o),
                    )
                    .entries
                    .map((entry) {
                      final excused = entry.value
                          .where((o) => o.state == OmissionState.excused)
                          .length;

                      final unexcused = entry.value
                          .where((o) => o.state == OmissionState.unexcused)
                          .length;

                      final pending = entry.value
                          .where((o) => o.state == OmissionState.pending)
                          .length;

                      return FirkaCard.single(
                        height: 64,
                        margin: EdgeInsets.only(bottom: 10),
                        padding: EdgeInsets.symmetric(horizontal: 16),
                        child: Row(
                          spacing: 12,
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            InfoCard.buildSubject(
                              appStyle.colors.accent,
                              entry.key,
                            ),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.center,
                                spacing: 2,
                                children: [
                                  Text(
                                    entry.key.name,
                                    style: appStyle.fonts.B_16SB.copyWith(
                                      color: appStyle.colors.textPrimary,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  Row(
                                    spacing: 4,
                                    children: [
                                      FirkaIconWidget(
                                        FirkaIconType.majesticonsLocal,
                                        "checkSolid",
                                        size: 12.0,
                                        color: appStyle.colors.accent,
                                      ),
                                      Text(
                                        excused.toString(),
                                        style: appStyle.fonts.B_14R.copyWith(
                                          color: appStyle.colors.textSecondary,
                                        ),
                                      ),
                                      SizedBox(width: 4),
                                      FirkaIconWidget(
                                        FirkaIconType.majesticons,
                                        Majesticon.timerSolid,
                                        size: 12.0,
                                        color: appStyle.colors.warningAccent,
                                      ),
                                      Text(
                                        pending.toString(),
                                        style: appStyle.fonts.B_14R.copyWith(
                                          color: appStyle.colors.textSecondary,
                                        ),
                                      ),
                                      SizedBox(width: 4),
                                      FirkaIconWidget(
                                        FirkaIconType.majesticons,
                                        Majesticon.restrictedLine,
                                        size: 12.0,
                                        color: appStyle.colors.errorAccent,
                                      ),
                                      Text(
                                        unexcused.toString(),
                                        style: appStyle.fonts.B_14R.copyWith(
                                          color: appStyle.colors.textSecondary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
