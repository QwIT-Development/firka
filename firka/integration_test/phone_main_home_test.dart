import 'package:firka/helpers/db/models/generic_cache_model.dart';
import 'package:firka/helpers/db/models/timetable_cache_model.dart';
import 'package:firka/helpers/db/models/token_model.dart';
import 'package:firka/main.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';

import 'test_helpers.dart';

Future<void> main() async {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  await resetAppData();
  setApiUrls();

  group('main', () {
    testWidgets('InitializationScreen -> HomeScreen', (tester) async {
      final dir = await getApplicationDocumentsDirectory();

      var isar = await Isar.open(
        [TokenModelSchema, GenericCacheModelSchema, TimetableCacheModelSchema],
        inspector: true,
        directory: dir.path,
      );
      isarInit = isar;

      await isar.writeTxn(() async {
        await isar.tokenModels.put(TokenModel());
      });

      await tester.pumpWidget(InitializationScreen());

      await waitUntil(Duration(minutes: 2), tester, () async {
        var ele = find.byKey(const Key('homeScreen'));
        return ele.allCandidates.isNotEmpty;
      });
    });
  });
}
