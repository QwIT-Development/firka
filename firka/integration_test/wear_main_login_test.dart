import 'package:firka/wear_main.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'test_helpers.dart';

Future<void> main() async {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  await resetAppData();
  setApiUrls();

  group('main', () {
    testWidgets('WearInitializationScreen -> LoginScreen', (tester) async {
      await tester.pumpWidget(WearInitializationScreen());

      await waitUntil(Duration(minutes: 2), tester, () async {
        var ele = find.byKey(const Key('wearLoginScreen'));
        return ele.allCandidates.isNotEmpty;
      });
    });
  });
}
