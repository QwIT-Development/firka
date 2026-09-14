import 'package:firka/ui/phone/screens/themes/user_theme.dart';
import 'package:firka/ui/phone/screens/themes/widgets/theme_qr_card.dart';
import 'package:firka_common/ui/theme/core_theme.dart';
import 'package:firka_common/ui/theme/theme_binary_format.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Theme sharing binary format in firka', () {
    test('encode and decode URL-safe base64 string for firkaCore', () {
      final bytes = ThemeBinaryFormat.encodeCoreTheme(firkaCore);
      final b64 = ThemeBinaryFormat.toBase64(bytes);
      expect(b64.isNotEmpty, isTrue);

      final decodedBytes = ThemeBinaryFormat.fromBase64(b64);
      final decoded = ThemeBinaryFormat.decode(decodedBytes);
      final slots = decoded.toThemeSlots();
      expect(slots.light[ThemeColorSlot.background], firkaCore.light.background);
      expect(slots.dark[ThemeColorSlot.background], firkaCore.dark.background);
      expect(slots.light[ThemeColorSlot.accent], firkaCore.light.accent);
      expect(slots.dark[ThemeColorSlot.accent], firkaCore.dark.accent);
    });

    testWidgets('ThemeQrCard renders theme name and QR code', (tester) async {
      final bytes = ThemeBinaryFormat.encodeCoreTheme(firkaCore);
      final b64 = ThemeBinaryFormat.toBase64(bytes);
      final userTheme = UserTheme(
        id: 'test_theme',
        name: 'Firka Green',
        origin: ThemeOrigin.own,
        swatch: const [
          Color(0xFFA7DC22),
          Colors.white,
          Color(0xFF1E1E1E),
        ],
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: ThemeQrCard(
                theme: userTheme,
                shareData: b64,
              ),
            ),
          ),
        ),
      );

      expect(find.text('Firka Green'), findsOneWidget);
      expect(find.text('https://firka.app'), findsOneWidget);
    });
  });
}
