import 'package:firka/ui/shared/dave_mascot.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('getDaveColorFilter returns null for default firka green (#A7DC22)', () {
    expect(getDaveColorFilter(const Color(0xFFA7DC22)), isNull);
  });

  test('getDaveColorFilter returns non-null ColorFilter for non-default color', () {
    final filter = getDaveColorFilter(const Color(0xFFFF0000));
    expect(filter, isNotNull);
  });
}
