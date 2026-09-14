import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:firka_common/ui/theme/core_theme.dart';

/// The 16 customizable color slots of a Firka theme.
enum ThemeColorSlot {
  accent,
  background,
  card,
  button,
  secondary,
  textPrimary,
  textSecondary,
  textTertiary,
  shadowColor,
  success,
  warningAccent,
  warningText,
  warningCard,
  errorAccent,
  errorText,
  errorCard,
}

/// Decoded theme binary data.
class ThemeBinaryData {
  /// Format version (e.g. 0).
  final int version;

  /// Ordered list of colors stored as raw bytes.
  final List<Color> colors;

  const ThemeBinaryData({
    required this.version,
    required this.colors,
  });

  /// True if the payload contains both light (0..15) and dark (16..31) slots.
  bool get isFullTheme => colors.length >= 32;

  /// Retrieves the color for [slot] in light mode, or null if out of range.
  Color? lightSlot(ThemeColorSlot slot) {
    final idx = slot.index;
    return idx < colors.length ? colors[idx] : null;
  }

  /// Retrieves the color for [slot] in dark mode, or null if out of range.
  Color? darkSlot(ThemeColorSlot slot) {
    final idx = 16 + slot.index;
    return idx < colors.length ? colors[idx] : null;
  }

  /// Extracts the full theme mapping for light and dark modes.
  ({Map<ThemeColorSlot, Color> light, Map<ThemeColorSlot, Color> dark}) toThemeSlots() {
    final lightMap = <ThemeColorSlot, Color>{};
    final darkMap = <ThemeColorSlot, Color>{};

    for (final slot in ThemeColorSlot.values) {
      final lColor = lightSlot(slot);
      if (lColor != null) lightMap[slot] = lColor;

      final dColor = darkSlot(slot) ?? lColor;
      if (dColor != null) darkMap[slot] = dColor;
    }

    return (light: lightMap, dark: darkMap);
  }

  @override
  String toString() =>
      'ThemeBinaryData(version: $version, colors: ${colors.length})';
}

/// Binary encoder and decoder for Firka themes.
///
/// Format specification:
/// 1. Header: Varint storing the format version (e.g. `0x00` for version 0).
/// 2. Colors: Raw 32-bit ARGB bytes (4 bytes per color: Alpha, Red, Green, Blue).
class ThemeBinaryFormat {
  /// Current binary format version.
  static const int currentVersion = 0;

  /// Encodes [value] into a standard unsigned LEB128 varint.
  static void writeVarint(BytesBuilder builder, int value) {
    if (value < 0) {
      throw ArgumentError.value(value, 'value', 'Varint must be non-negative');
    }
    var v = value;
    while (v >= 0x80) {
      builder.addByte((v & 0x7F) | 0x80);
      v >>= 7;
    }
    builder.addByte(v & 0x7F);
  }

  /// Reads a standard unsigned LEB128 varint from [bytes] starting at [offset].
  /// Returns a record of `(value, bytesRead)`.
  static (int value, int bytesRead) readVarint(Uint8List bytes, [int offset = 0]) {
    var result = 0;
    var shift = 0;
    var index = offset;

    while (index < bytes.length) {
      final byte = bytes[index++];
      result |= (byte & 0x7F) << shift;
      if ((byte & 0x80) == 0) {
        return (result, index - offset);
      }
      shift += 7;
      if (shift >= 64) {
        throw const FormatException('Varint overflow');
      }
    }
    throw const FormatException('Unexpected end of buffer while reading varint');
  }

  /// Encodes a list of [colors] into the binary theme format.
  ///
  /// Prepends [version] as a varint (default 0), followed by 4 raw bytes per
  /// color in 32-bit ARGB order (Alpha, Red, Green, Blue).
  static Uint8List encode({
    required List<Color> colors,
    int version = currentVersion,
  }) {
    final builder = BytesBuilder(copy: false);

    // 1. Version as varint
    writeVarint(builder, version);

    // 2. Colors as raw bytes (4 bytes each: A, R, G, B)
    for (final color in colors) {
      final argb = color.toARGB32();
      builder.addByte((argb >> 24) & 0xFF);
      builder.addByte((argb >> 16) & 0xFF);
      builder.addByte((argb >> 8) & 0xFF);
      builder.addByte(argb & 0xFF);
    }

    return builder.takeBytes();
  }

  /// Decodes raw binary theme [bytes].
  ///
  /// Reads the leading varint version and parses the subsequent raw bytes as
  /// 32-bit ARGB colors (4 bytes per color).
  static ThemeBinaryData decode(Uint8List bytes) {
    if (bytes.isEmpty) {
      throw const FormatException('Cannot decode empty theme bytes');
    }

    // 1. Read version varint
    final (version, headerLength) = readVarint(bytes, 0);

    final colorByteLength = bytes.length - headerLength;
    if (colorByteLength % 4 != 0) {
      throw FormatException(
        'Invalid color byte length ($colorByteLength). '
        'Color bytes must be a multiple of 4.',
      );
    }

    final colorCount = colorByteLength ~/ 4;
    final colors = <Color>[];

    for (var i = 0; i < colorCount; i++) {
      final offset = headerLength + (i * 4);
      final a = bytes[offset];
      final r = bytes[offset + 1];
      final g = bytes[offset + 2];
      final b = bytes[offset + 3];
      colors.add(Color.fromARGB(a, r, g, b));
    }

    return ThemeBinaryData(version: version, colors: colors);
  }

  /// Encodes a complete 32-color Firka theme (16 light slots + 16 dark slots).
  static Uint8List encodeFullTheme({
    required Map<ThemeColorSlot, Color> light,
    required Map<ThemeColorSlot, Color> dark,
    int version = currentVersion,
  }) {
    final colors = <Color>[];

    // Light slots (0..15)
    for (final slot in ThemeColorSlot.values) {
      colors.add(light[slot] ?? Colors.transparent);
    }

    // Dark slots (16..31)
    for (final slot in ThemeColorSlot.values) {
      colors.add(dark[slot] ?? light[slot] ?? Colors.transparent);
    }

    return encode(colors: colors, version: version);
  }

  /// Encodes a [CoreTheme] (both light and dark colors) into binary.
  static Uint8List encodeCoreTheme(
    CoreTheme theme, {
    int version = currentVersion,
  }) {
    Color getSlot(CoreThemeColors c, ThemeColorSlot slot) => switch (slot) {
      ThemeColorSlot.accent => c.accent,
      ThemeColorSlot.background => c.background,
      ThemeColorSlot.card => c.card,
      ThemeColorSlot.button => c.buttonSecondaryFill,
      ThemeColorSlot.secondary => c.secondary,
      ThemeColorSlot.textPrimary => c.textPrimary,
      ThemeColorSlot.textSecondary => c.textSecondary,
      ThemeColorSlot.textTertiary => c.textTertiary,
      ThemeColorSlot.shadowColor => c.shadowColor,
      ThemeColorSlot.success => c.success,
      ThemeColorSlot.warningAccent => c.warningAccent,
      ThemeColorSlot.warningText => c.warningText,
      ThemeColorSlot.warningCard => c.warningCard,
      ThemeColorSlot.errorAccent => c.errorAccent,
      ThemeColorSlot.errorText => c.errorText,
      ThemeColorSlot.errorCard => c.errorCard,
    };

    final lightMap = {
      for (final slot in ThemeColorSlot.values) slot: getSlot(theme.light, slot),
    };
    final darkMap = {
      for (final slot in ThemeColorSlot.values) slot: getSlot(theme.dark, slot),
    };

    return encodeFullTheme(light: lightMap, dark: darkMap, version: version);
  }

  /// Encodes [bytes] to Base64 (URL-safe without padding by default).
  static String toBase64(Uint8List bytes, {bool urlSafe = true}) {
    final b64 = urlSafe ? base64UrlEncode(bytes) : base64Encode(bytes);
    return urlSafe ? b64.replaceAll('=', '') : b64;
  }

  /// Decodes a Base64 or URL-safe Base64 string into binary theme bytes.
  static Uint8List fromBase64(String encoded) {
    var normalized = encoded.trim();
    final mod = normalized.length % 4;
    if (mod != 0) {
      normalized += '=' * (4 - mod);
    }
    return base64Url.decode(normalized);
  }

  /// Convenience method: Encodes [colors] directly into a URL-safe Base64 string.
  static String encodeToBase64(
    List<Color> colors, {
    int version = currentVersion,
    bool urlSafe = true,
  }) {
    final bytes = encode(colors: colors, version: version);
    return toBase64(bytes, urlSafe: urlSafe);
  }

  /// Convenience method: Decodes a URL-safe Base64 string into [ThemeBinaryData].
  static ThemeBinaryData decodeFromBase64(String encoded) {
    final bytes = fromBase64(encoded);
    return decode(bytes);
  }
}
