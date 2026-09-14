import 'dart:typed_data';
import 'package:firka_common/ui/theme/core_theme.dart';
import 'package:firka_common/ui/theme/theme_binary_format.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ThemeBinaryFormat varint tests', () {
    test('encodes and decodes 0 (version 0) as a single byte 0x00', () {
      final builder = BytesBuilder();
      ThemeBinaryFormat.writeVarint(builder, 0);
      final bytes = builder.takeBytes();

      expect(bytes.length, 1);
      expect(bytes[0], 0x00);

      final (value, bytesRead) = ThemeBinaryFormat.readVarint(bytes, 0);
      expect(value, 0);
      expect(bytesRead, 1);
    });

    test('encodes and decodes multi-byte varints', () {
      for (final testVal in [1, 63, 127, 128, 255, 300, 16384, 2097151]) {
        final builder = BytesBuilder();
        ThemeBinaryFormat.writeVarint(builder, testVal);
        final bytes = builder.takeBytes();

        final (decoded, bytesRead) = ThemeBinaryFormat.readVarint(bytes, 0);
        expect(decoded, testVal);
        expect(bytesRead, bytes.length);
      }
    });

    test('throws on negative varint', () {
      final builder = BytesBuilder();
      expect(() => ThemeBinaryFormat.writeVarint(builder, -1), throwsArgumentError);
    });
  });

  group('ThemeBinaryFormat color encoding', () {
    test('encodes empty list as only version varint', () {
      final bytes = ThemeBinaryFormat.encode(colors: []);
      expect(bytes, equals([0x00]));

      final decoded = ThemeBinaryFormat.decode(bytes);
      expect(decoded.version, 0);
      expect(decoded.colors, isEmpty);
    });

    test('stores colors as 4 raw ARGB bytes following version 0', () {
      const red = Color(0xFFFF0000);
      const semiGreen = Color(0x8000FF00);

      final bytes = ThemeBinaryFormat.encode(colors: [red, semiGreen]);

      expect(bytes[0], 0x00);
      expect(bytes.sublist(1, 5), equals([0xFF, 0xFF, 0x00, 0x00]));
      expect(bytes.sublist(5, 9), equals([0x80, 0x00, 0xFF, 0x00]));
      expect(bytes.length, 9);

      final decoded = ThemeBinaryFormat.decode(bytes);
      expect(decoded.version, 0);
      expect(decoded.colors.length, 2);
      expect(decoded.colors[0], red);
      expect(decoded.colors[1], semiGreen);
    });

    test('round-trips full theme (32 colors)', () {
      final lightMap = {
        for (final slot in ThemeColorSlot.values)
          slot: Color((0xFF000000 + slot.index * 0x0F0F0F) & 0xFFFFFFFF),
      };
      final darkMap = {
        for (final slot in ThemeColorSlot.values)
          slot: Color((0xFF111111 + slot.index * 0x0E0E0E) & 0xFFFFFFFF),
      };

      final bytes = ThemeBinaryFormat.encodeFullTheme(
        light: lightMap,
        dark: darkMap,
      );

      expect(bytes.length, 129);
      expect(bytes[0], 0x00);

      final decoded = ThemeBinaryFormat.decode(bytes);
      expect(decoded.version, 0);
      expect(decoded.isFullTheme, isTrue);

      final slots = decoded.toThemeSlots();
      for (final slot in ThemeColorSlot.values) {
        expect(slots.light[slot], lightMap[slot]);
        expect(slots.dark[slot], darkMap[slot]);
      }
    });

    test('round-trips CoreTheme (firkaCore)', () {
      final bytes = ThemeBinaryFormat.encodeCoreTheme(firkaCore);
      expect(bytes.length, 129);

      final decoded = ThemeBinaryFormat.decode(bytes);
      expect(decoded.version, 0);

      final slots = decoded.toThemeSlots();
      expect(slots.light[ThemeColorSlot.accent], firkaCore.light.accent);
      expect(slots.light[ThemeColorSlot.background], firkaCore.light.background);
      expect(slots.dark[ThemeColorSlot.accent], firkaCore.dark.accent);
      expect(slots.dark[ThemeColorSlot.background], firkaCore.dark.background);
    });

    test('throws on malformed binary data', () {
      expect(() => ThemeBinaryFormat.decode(Uint8List(0)), throwsFormatException);
      expect(
        () => ThemeBinaryFormat.decode(Uint8List.fromList([0x00, 0xFF, 0x00, 0x00])),
        throwsFormatException,
      );
    });

    test('Base64 and URL-safe serialization', () {
      final colors = [const Color(0xFFA7DC22), const Color(0xFFFAFFF0)];
      final b64 = ThemeBinaryFormat.encodeToBase64(colors);

      expect(b64.contains('/'), isFalse);
      expect(b64.contains('+'), isFalse);
      expect(b64.contains('='), isFalse);

      final decoded = ThemeBinaryFormat.decodeFromBase64(b64);
      expect(decoded.version, 0);
      expect(decoded.colors, equals(colors));
    });
  });
}
