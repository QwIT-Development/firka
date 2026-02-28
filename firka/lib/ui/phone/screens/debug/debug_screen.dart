import 'dart:io';
import 'dart:typed_data';

import 'package:firka/data/models/generic_cache_model.dart';
import 'package:firka/data/models/homework_cache_model.dart';
import 'package:firka/data/models/timetable_cache_model.dart';
import 'package:firka/data/models/token_model.dart';
import 'package:firka/core/extensions.dart';
import 'package:firka/core/icon_helper.dart';
import 'package:firka/core/profile_picture.dart';
import 'package:firka/app/app_state.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import 'package:firka/core/debug_helper.dart';
import 'package:firka/core/state/firka_state.dart';
import 'package:firka/data/widget.dart';
import 'package:firka/ui/shared/firka_icon.dart';
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
                    "getStudent(): ${await widget.data.client.getStudent(forceCache: useCache)}",
                  );
                },
                child: const Text('getStudent()'),
              ),
              ElevatedButton(
                onPressed: () async {
                  logger.finest(
                    "getNoticeBoard(): ${await widget.data.client.getNoticeBoard(forceCache: useCache)}",
                  );
                },
                child: const Text('getNoticeBoard()'),
              ),
              ElevatedButton(
                onPressed: () async {
                  logger.finest(
                    "getGrades(): ${await widget.data.client.getGrades(forceCache: useCache)}",
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
                    "getLessons(): ${await widget.data.client.getTimeTable(start, end, forceCache: useCache)}",
                  );
                },
                child: const Text('getLessons()'),
              ),
              ElevatedButton(
                onPressed: () async {
                  logger.finest(
                    "getHomework(): ${await widget.data.client.getHomework(forceCache: useCache)}",
                  );
                },
                child: const Text('getHomework()'),
              ),
              ElevatedButton(
                onPressed: () async {
                  logger.finest(
                    "getTests(): ${await widget.data.client.getTests(forceCache: useCache)}",
                  );
                },
                child: const Text('getTests()'),
              ),
              ElevatedButton(
                onPressed: () async {
                  logger.finest(
                    "getOmissions(): ${await widget.data.client.getOmissions(forceCache: useCache)}",
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
                    await isar.genericCacheModels.clear();
                    await isar.timetableCacheModels.clear();
                    await isar.homeworkCacheModels.clear();
                  });
                  widget.data.client.evictMemCache();
                  if (Platform.isIOS) {
                    await WidgetCacheHelper.clearIOSWidgets();
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

                  widget.data.tokens = List.empty(growable: true);

                  if (!context.mounted) return;
                  context.go('/login');
                },
                child: const Text('wipe users'),
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
                            color: Colors.black,
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
