// Integration test that runs against a live mock_kreta_server instance
// (git.firka.app/firka/mock_kreta_server) to catch drift between the wire
// format it serves and the DTOs in this package. The server URL is provided
// by CI via MOCK_KRETA_SERVER_URL; see .woodpecker.yml.
import 'dart:convert';
import 'dart:io';

import 'package:kreta_api/kreta_api.dart';
import 'package:test/test.dart';

final _serverUrl =
    Platform.environment['MOCK_KRETA_SERVER_URL'] ?? 'http://127.0.0.1:8090';

Future<String> _fetchLoginCode(HttpClient client) async {
  final req = await client.getUrl(Uri.parse('$_serverUrl/Account/Login'));
  final resp = await req.close();
  final body = await resp.transform(utf8.decoder).join();

  final match = RegExp(r'name="code" value="([^"]+)"').firstMatch(body);
  if (match == null) {
    fail('mock server login page did not contain a code: $body');
  }
  return match.group(1)!;
}

Future<Map<String, dynamic>> _postToken(
  HttpClient client,
  Map<String, String> form,
) async {
  final req = await client.postUrl(Uri.parse('$_serverUrl/connect/token'));
  req.headers.contentType = ContentType(
    'application',
    'x-www-form-urlencoded',
  );
  req.write(
    form.entries
        .map(
          (e) =>
              '${Uri.encodeQueryComponent(e.key)}=${Uri.encodeQueryComponent(e.value)}',
        )
        .join('&'),
  );
  final resp = await req.close();
  final body = await resp.transform(utf8.decoder).join();
  if (resp.statusCode != 200) {
    throw HttpException('token request failed (${resp.statusCode}): $body');
  }
  return jsonDecode(body) as Map<String, dynamic>;
}

Future<TokenGrantResponse> _authenticate(HttpClient client) async {
  final code = await _fetchLoginCode(client);
  final json = await _postToken(client, {
    'grant_type': 'authorization_code',
    'code': code,
  });
  return TokenGrantResponse.fromJson(json);
}

Future<dynamic> _getAuthed(
  HttpClient client,
  String path,
  String accessToken,
) async {
  final req = await client.getUrl(Uri.parse('$_serverUrl$path'));
  req.headers.set('Authorization', 'Bearer $accessToken');
  final resp = await req.close();
  final body = await resp.transform(utf8.decoder).join();
  if (resp.statusCode != 200) {
    throw HttpException('$path failed (${resp.statusCode}): $body');
  }
  return jsonDecode(body);
}

void main() {
  late HttpClient client;

  setUp(() => client = HttpClient());
  tearDown(() => client.close(force: true));

  group('mock_kreta_server', () {
    test('authorization_code grant returns a usable token', () async {
      final token = await _authenticate(client);

      expect(token.accessToken, isNotEmpty);
      expect(token.refreshToken, isNotEmpty);
      expect(token.tokenType, 'Bearer');
    });

    test('an authorization code can only be redeemed once', () async {
      final code = await _fetchLoginCode(client);
      await _postToken(client, {
        'grant_type': 'authorization_code',
        'code': code,
      });

      await expectLater(
        _postToken(client, {'grant_type': 'authorization_code', 'code': code}),
        throwsA(isA<HttpException>()),
      );
    });

    test('refresh_token grant issues a new token and consumes the old one', () async {
      final first = await _authenticate(client);

      final refreshed = TokenGrantResponse.fromJson(
        await _postToken(client, {
          'grant_type': 'refresh_token',
          'refresh_token': first.refreshToken,
        }),
      );
      expect(refreshed.accessToken, isNotEmpty);
      expect(refreshed.accessToken, isNot(first.accessToken));

      await expectLater(
        _postToken(client, {
          'grant_type': 'refresh_token',
          'refresh_token': first.refreshToken,
        }),
        throwsA(isA<HttpException>()),
      );
    });

    test('student profile matches the Student DTO contract', () async {
      final token = await _authenticate(client);
      final json = await _getAuthed(
        client,
        Uri.parse(KretaEndpoints.getStudent('dummy')).path,
        token.accessToken,
      );

      final student = Student.fromJson(json as Map<String, dynamic>);
      expect(student.name, isNotEmpty);
      expect(student.uid, isNotEmpty);
      expect(student.instituteCode, isNotEmpty);
    });

    test('class groups match the ClassGroup DTO contract', () async {
      final token = await _authenticate(client);
      final json = await _getAuthed(
        client,
        Uri.parse(KretaEndpoints.getClassGroups('dummy')).path,
        token.accessToken,
      );

      final list = (json as List)
          .cast<Map<String, dynamic>>()
          .map(ClassGroup.fromJson)
          .toList();
      expect(list, isNotEmpty);
      for (final group in list) {
        expect(group.uid, isNotEmpty);
        expect(group.name, isNotEmpty);
      }
    });

    test('protected endpoints reject requests without a token', () async {
      final req = await client.getUrl(
        Uri.parse('$_serverUrl/ellenorzo/v3/sajat/TanuloAdatlap'),
      );
      final resp = await req.close();
      await resp.drain();
      expect(resp.statusCode, HttpStatus.unauthorized);
    });
  });
}
