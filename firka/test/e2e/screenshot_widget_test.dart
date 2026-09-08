import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

const _mockServerUrl = 'http://127.0.0.1:8090';

class _RealHttpOverrides extends HttpOverrides {}

Future<List<Map<String, dynamic>>> _getMockLessons(HttpClient httpClient) async {
  final req = await httpClient.getUrl(Uri.parse('$_mockServerUrl/admin/api/timetable'));
  final resp = await req.close();
  final body = await resp.transform(utf8.decoder).join();
  final list = jsonDecode(body) as List;
  return list.cast<Map<String, dynamic>>();
}

Future<void> _putMockLessons(HttpClient httpClient, List<Map<String, dynamic>> lessons) async {
  final req = await httpClient.putUrl(Uri.parse('$_mockServerUrl/admin/api/timetable'));
  req.headers.contentType = ContentType.json;
  req.write(jsonEncode(lessons));
  final resp = await req.close();
  if (resp.statusCode != 204 && resp.statusCode != 200) {
    final body = await resp.transform(utf8.decoder).join();
    throw Exception('Failed to update mock lessons (${resp.statusCode}): $body');
  }
}

Future<void> _seedMockLessonsToday(HttpClient httpClient) async {
  final req = await httpClient.postUrl(Uri.parse('$_mockServerUrl/admin/api/timetable/today'));
  final resp = await req.close();
  if (resp.statusCode != 200) {
    final body = await resp.transform(utf8.decoder).join();
    throw Exception('Failed to shift lessons to today (${resp.statusCode}): $body');
  }
}

class TimetableWidgetView extends StatelessWidget {
  final GlobalKey boundaryKey;
  final List<Map<String, dynamic>> lessons;

  const TimetableWidgetView({
    required this.boundaryKey,
    required this.lessons,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    const bgColor = Color(0xFFFAFFF0);
    const cardColor = Color(0xFFEFF4E3);
    const textPrimary = Color(0xFF1B1C18);
    const textSecondary = Color(0xFF45483D);
    const warningColor = Color(0xFFE65100);

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: bgColor,
        body: Center(
          child: RepaintBoundary(
            key: boundaryKey,
            child: Container(
              width: 320,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Mai órarend',
                    style: TextStyle(
                      color: textSecondary,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  for (final lesson in lessons.take(4))
                    Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        color: lesson['HelyettesTanarNeve'] != null &&
                                (lesson['HelyettesTanarNeve'] as String).isNotEmpty
                            ? warningColor.withValues(alpha: 0.15)
                            : cardColor,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: [
                          Text(
                            '${lesson['Oraszam'] ?? 1}.',
                            style: const TextStyle(
                              color: textSecondary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  lesson['Nev'] as String? ?? '',
                                  style: const TextStyle(
                                    color: textPrimary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                if (lesson['HelyettesTanarNeve'] != null &&
                                    (lesson['HelyettesTanarNeve'] as String).isNotEmpty)
                                  Text(
                                    'Helyettes: ${lesson['HelyettesTanarNeve']}',
                                    style: const TextStyle(
                                      color: warningColor,
                                      fontSize: 12,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          if (lesson['TeremNeve'] != null)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: textSecondary.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                lesson['TeremNeve'] as String,
                                style: const TextStyle(
                                  color: textSecondary,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

Future<List<int>> _capturePng(WidgetTester tester, GlobalKey key) async {
  return await tester.runAsync(() async {
    final boundary = key.currentContext!.findRenderObject() as RenderRepaintBoundary;
    final image = await boundary.toImage(pixelRatio: 2.0);
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    return byteData!.buffer.asUint8List().toList();
  }) ?? [];
}

int _countDifferentBytes(List<int> a, List<int> b) {
  int diff = 0;
  final minLen = a.length < b.length ? a.length : b.length;
  for (int i = 0; i < minLen; i++) {
    if (a[i] != b[i]) diff++;
  }
  diff += (a.length - b.length).abs();
  return diff;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  HttpOverrides.global = _RealHttpOverrides();

  group('Widget End-to-End Screenshot Comparison Test', () {
    late HttpClient httpClient;
    late List<Map<String, dynamic>> originalLessons;

    setUp(() async {
      HttpOverrides.global = _RealHttpOverrides();
      httpClient = HttpClient()..connectionTimeout = const Duration(seconds: 5);
      originalLessons = await _getMockLessons(httpClient);
    });

    tearDown(() async {
      try {
        await _putMockLessons(httpClient, originalLessons);
      } catch (_) {}
      httpClient.close(force: true);
    });

    testWidgets('Widget screenshots differ programmatically after mock server timetable mutation', (tester) async {
      HttpOverrides.global = _RealHttpOverrides();

      late List<Map<String, dynamic>> lessonsBefore;
      await tester.runAsync(() async {
        await _seedMockLessonsToday(httpClient);
        lessonsBefore = await _getMockLessons(httpClient);
      });
      expect(lessonsBefore.isNotEmpty, isTrue);

      final boundaryKey1 = GlobalKey();
      await tester.pumpWidget(TimetableWidgetView(boundaryKey: boundaryKey1, lessons: lessonsBefore));
      await tester.pump();

      final screenshotBefore = await _capturePng(tester, boundaryKey1);
      expect(screenshotBefore, isNotEmpty);

      late List<Map<String, dynamic>> lessonsAfter;
      final targetName = lessonsBefore.first['Nev'];
      await tester.runAsync(() async {
        final mutateReq = await httpClient.postUrl(Uri.parse('$_mockServerUrl/admin/api/timetable/mutate'));
        mutateReq.headers.contentType = ContentType.json;
        mutateReq.write(jsonEncode({
          'Uid': lessonsBefore.first['Uid'],
          'Nev': targetName,
          'TeremNeve': 'LAB-999',
          'HelyettesTanarNeve': 'Prof. E2E Teszt',
        }));
        final mutateResp = await mutateReq.close();
        expect(mutateResp.statusCode, equals(200));

        lessonsAfter = await _getMockLessons(httpClient);
      });

      final targetLesson = lessonsAfter.firstWhere((l) => l['Nev'] == targetName);
      expect(targetLesson['TeremNeve'], equals('LAB-999'));
      expect(targetLesson['HelyettesTanarNeve'], equals('Prof. E2E Teszt'));

      final boundaryKey2 = GlobalKey();
      await tester.pumpWidget(TimetableWidgetView(boundaryKey: boundaryKey2, lessons: lessonsAfter));
      await tester.pump();

      final screenshotAfter = await _capturePng(tester, boundaryKey2);
      expect(screenshotAfter, isNotEmpty);

      expect(screenshotBefore, isNot(equals(screenshotAfter)));
      expect(_countDifferentBytes(screenshotBefore, screenshotAfter), greaterThan(0));
    });
  });
}
