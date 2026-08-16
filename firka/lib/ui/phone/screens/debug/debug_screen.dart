import 'dart:io';

import 'package:firka_common/data/models/class_average_cache_model.dart';
import 'package:firka_common/data/models/class_group_cache_model.dart';
import 'package:firka_common/data/models/grade_cache_model.dart';
import 'package:firka_common/data/models/homework_cache_model.dart';
import 'package:firka_common/data/models/lesson_cache_model.dart';
import 'package:firka_common/data/models/message_cache_model.dart';
import 'package:firka_common/data/models/omission_cache_model.dart';
import 'package:firka_common/data/models/subject_cache_model.dart';
import 'package:firka_common/data/models/teacher_model.dart';
import 'package:firka_common/data/models/test_cache_model.dart';
import 'package:firka_common/data/models/token_model.dart';
import 'package:firka/core/extensions.dart';
import 'package:firka/core/icon_helper.dart';
import 'package:firka/core/profile_picture.dart';
import 'package:firka/app/app_state.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import 'package:firka/core/debug_helper.dart';
import 'package:firka/core/state/firka_state.dart';
import 'package:firka/ui/shared/firka_icon.dart';
import 'package:firka/ui/theme/style.dart';
import 'package:firka_common/ui/components/filled_circle.dart';
import 'package:flutter/services.dart';
import 'package:home_widget/home_widget.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

class DebugScreen extends StatefulWidget {
  final AppInitialization data;

  const DebugScreen(this.data, {super.key});

  @override
  State<DebugScreen> createState() => _DebugScreen();
}

class _DebugScreen extends FirkaState<DebugScreen> {
  _DebugScreen();

  late ImagePicker _picker;
  Uint8List? profilePictureData;

  bool useCache = true;

  @override
  void initState() {
    super.initState();

    _picker = ImagePicker();
    profilePictureData = widget.data.profilePicture;
  }

  @override
  Widget build(BuildContext context) {
    Widget profilePicture = SizedBox(height: 0);
    if (profilePictureData != null) {
      profilePicture = Image.memory(profilePictureData!);
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Debug'), centerTitle: true),
      body: Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'Debug Screen',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Text('use cache'),
                  Switch(
                    value: useCache,
                    onChanged: (bool value) {
                      setState(() {
                        useCache = value;
                      });
                    },
                  ),
                ],
              ),
              const SizedBox(height: 5),
              Row(
                children: [
                  Text('tick debug timer'),
                  Switch(
                    value: debugTimeAdvance,
                    onChanged: (bool value) {
                      setState(() {
                        debugTimeAdvance = value;
                      });
                    },
                  ),
                ],
              ),
              const SizedBox(height: 20),
              profilePicture,
              ElevatedButton(
                onPressed: () async {
                  await pickProfilePicture(widget.data, _picker);

                  setState(() {
                    if (widget.data.profilePicture != null) {
                      profilePictureData = widget.data.profilePicture;
                    }
                  });
                },
                child: const Text('Pick pfp'),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () async {
                  var d = await showDatePicker(
                    context: context,
                    firstDate: DateTime.now().subtract(Duration(days: 365)),
                    lastDate: DateTime.now().add(Duration(days: 365)),
                  );

                  if (!context.mounted) return;
                  var t = await showTimePicker(
                    context: context,
                    initialTime: TimeOfDay.now(),
                  );

                  if (!context.mounted) return;
                  if (d != null && t != null) {
                    debugFakeTime = d.getMidnight().add(
                      Duration(hours: t.hour, minutes: t.minute),
                    );

                    debugSetAt = DateTime.now();
                  }
                },
                child: const Text('Set fake time'),
              ),
              ElevatedButton(
                onPressed: () async {
                  final d = await showDatePicker(
                    context: context,
                    firstDate: DateTime.now().subtract(Duration(days: 365)),
                    lastDate: DateTime.now().add(Duration(days: 365)),
                  );
                  if (!context.mounted || d == null) return;
                  try {
                    if (Platform.isAndroid) {
                      await HomeWidget.updateWidget(
                        qualifiedAndroidName:
                            'app.firka.naplo.glance.TimetableWidgetReceiver',
                      );
                      await const MethodChannel(
                        'firka.app/main',
                      ).invokeMethod<void>('refreshTimetableWidget');
                    }
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Widget state generated for ${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}',
                        ),
                      ),
                    );
                  } catch (e) {
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Failed to generate widget state: $e'),
                      ),
                    );
                  }
                },
                child: const Text('Generate widget state for date'),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () async {
                  await widget.data.isar.writeTxn(() async {
                    await widget.data.isar.writeTxn(() async {});
                  });
                },
                child: const Text('Throw Exception'),
              ),
              ElevatedButton(
                onPressed: () async {
                  logger.finest(
                    "getStudent(): ${await widget.data.client!.getStudent()}",
                  );
                },
                child: const Text('getStudent()'),
              ),
              ElevatedButton(
                onPressed: () async {
                  logger.finest(
                    "getNoticeBoard(): ${await widget.data.client!.getNoticeBoard()}",
                  );
                },
                child: const Text('getNoticeBoard()'),
              ),
              ElevatedButton(
                onPressed: () async {
                  logger.finest(
                    "getInfoBoard(): ${await widget.data.client!.getInfoBoard(from: timeNow())}",
                  );
                },
                child: const Text('getInfoBoard()'),
              ),
              ElevatedButton(
                onPressed: () async {
                  logger.finest(
                    "getGrades(): ${await widget.data.client!.getGrades()}",
                  );
                },
                child: const Text('getGrades()'),
              ),
              ElevatedButton(
                onPressed: () async {
                  var now = timeNow();

                  var start = now.subtract(Duration(days: 14));
                  var end = now.add(Duration(days: 7));

                  logger.finest(
                    "getLessons(): ${await widget.data.client!.getLessons(start, end)}",
                  );
                },
                child: const Text('getLessons()'),
              ),
              ElevatedButton(
                onPressed: () async {
                  logger.finest(
                    "getHomework(): ${await widget.data.client!.getHomework(from: timeNow())}",
                  );
                },
                child: const Text('getHomework()'),
              ),
              ElevatedButton(
                onPressed: () async {
                  logger.finest(
                    "getTests(): ${await widget.data.client!.getTests(from: timeNow())}",
                  );
                },
                child: const Text('getTests()'),
              ),
              ElevatedButton(
                onPressed: () async {
                  logger.finest(
                    "getOmissions(): ${await widget.data.client!.getOmissions()}",
                  );
                },
                child: const Text('getOmissions()'),
              ),
              ElevatedButton(
                onPressed: () {
                  setState(() {});
                },
                child: const Text('re-render'),
              ),
              ElevatedButton(
                style: ButtonStyle(
                  backgroundColor: WidgetStateProperty<Color>.fromMap(
                    <WidgetStatesConstraint, Color>{
                      WidgetState.any: Colors.orange,
                    },
                  ),
                ),
                onPressed: () async {
                  final isar = widget.data.isar;
                  await isar.writeTxn(() async {
                    await isar.subjectCacheModels.clear();
                    await isar.testCacheModels.clear();
                    await isar.gradeCacheModels.clear();
                    await isar.omissionCacheModels.clear();
                    await isar.messageCacheModels.clear();
                    await isar.classGroupCacheModels.clear();
                    await isar.classAverageCacheModels.clear();
                    await isar.lessonCacheModels.clear();
                    await isar.teacherModels.clear();
                    await isar.homeworkCacheModels.clear();
                  });
                  if (Platform.isIOS) {
                  } else {
                    final dataDir = await getApplicationDocumentsDirectory();
                    final widgetFile = File(
                      p.join(dataDir.path, 'widget_state.json'),
                    );
                    if (await widgetFile.exists()) {
                      await widgetFile.delete();
                    }
                  }
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Cache cleared')),
                  );
                },
                child: const Text('Clear all cache'),
              ),
              ElevatedButton(
                style: ButtonStyle(
                  backgroundColor: WidgetStateProperty<Color>.fromMap(
                    <WidgetStatesConstraint, Color>{
                      WidgetState.any: Colors.red,
                    },
                  ),
                ),
                onPressed: () async {
                  var isar = widget.data.isar;

                  await isar.writeTxn(() async {
                    await isar.tokenModels.clear();
                  });

                  if (!context.mounted) return;
                  context.go('/login');
                },
                child: const Text('wipe users'),
              ),
              const SizedBox(height: 20),
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 16,
                runSpacing: 16,
                children: [
                  for (final entry in _themeColorSwatches())
                    _themeColorSwatch(context, entry.$1, entry.$2),
                ],
              ),
              SizedBox(
                height: 600,
                child: GridView.count(
                  crossAxisCount: 2,
                  children: ClassIcon.values.map((e) {
                    return Column(
                      children: [
                        Center(
                          child: Text(
                            e.name,
                            style: TextTheme.of(context).headlineSmall,
                          ),
                        ),
                        Center(
                          child: FirkaIconWidget(
                            FirkaIconType.majesticons,
                            getIconData(e),
                            color: appStyle.colors.textPrimary,
                          ),
                        ),
                      ],
                    );
                  }).toList(),
                  /*
                  children: List.generate(100, (index) {
                    return Center(
                      child: Text(
                        'Item $index',
                        style: TextTheme.of(context).headlineSmall,
                      ),
                    );
                  }),
                  */
                ),
              ),
              SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}

List<(String, Color)> _themeColorSwatches() {
  final c = appStyle.colors;
  return [
    ("background", c.background),
    ("backgroundAmoled", c.backgroundAmoled),
    ("background0p", c.background0p),
    ("success", c.success),
    ("textPrimary", c.textPrimary),
    ("textSecondary", c.textSecondary),
    ("textTertiary", c.textTertiary),
    if (c.textTeritary != null) ("textTeritary", c.textTeritary!),
    ("textPrimaryLight", c.textPrimaryLight),
    ("textSecondaryLight", c.textSecondaryLight),
    ("textTertiaryLight", c.textTertiaryLight),
    ("card", c.card),
    ("cardTranslucent", c.cardTranslucent),
    ("buttonSecondaryFill", c.buttonSecondaryFill),
    ("buttonDisabledIcon", c.buttonDisabledIcon),
    ("accent", c.accent),
    ("secondary", c.secondary),
    ("shadowColor", c.shadowColor),
    ("a10p", c.a10p),
    ("a15p", c.a15p),
    ("warningAccent", c.warningAccent),
    ("warningText", c.warningText),
    ("warning15p", c.warning15p),
    ("warningCard", c.warningCard),
    ("errorAccent", c.errorAccent),
    ("errorText", c.errorText),
    ("error15p", c.error15p),
    ("errorCard", c.errorCard),
    ("grade5", c.grade5),
    ("grade4", c.grade4),
    ("grade3", c.grade3),
    ("grade2", c.grade2),
    ("grade1", c.grade1),
  ];
}

Widget _themeColorSwatch(BuildContext context, String name, Color color) {
  final darkBg = color.computeLuminance() > 0.5;
  final bg = darkBg ? const Color(0xFF121212) : const Color(0xFFF2F2F2);
  final labelColor = darkBg ? const Color(0xFFF2F2F2) : const Color(0xFF121212);

  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
    decoration: BoxDecoration(
      color: bg,
      borderRadius: BorderRadius.circular(8),
    ),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          name,
          style: TextTheme.of(context).bodySmall?.copyWith(color: labelColor),
        ),
        FilledCircle(
          diameter: 40,
          color: color,
          child: const SizedBox(),
        ),
      ],
    ),
  );
}
