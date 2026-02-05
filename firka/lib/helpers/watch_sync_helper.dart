import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:isar/isar.dart';

import '../main.dart';
import 'api/client/kreta_client.dart';
import 'db/models/token_model.dart';

/// Helper class for Watch ↔ iPhone token sync
class WatchSyncHelper {
  static const _watchChannel = MethodChannel('app.firka/watch_sync');
  static bool _initialized = false;

  static void initialize() {
    if (!Platform.isIOS) return;
    if (_initialized) return;
    _initialized = true;

    _watchChannel.setMethodCallHandler(_handleMethodCall);
    debugPrint('[WatchSync] Handler initialized');
  }

  static Future<dynamic> _handleMethodCall(MethodCall call) async {
    switch (call.method) {
      case 'getTokenForWatch':
        return _getTokenForWatch();
      case 'getLanguageForWatch':
        return _getLanguageForWatch();
      case 'watchAppInstalled':
        debugPrint('[WatchSync] Watch app installed detected');
        return null;
      case 'onTokenFromWatch':
        debugPrint('[WatchSync] Token received from Watch');
        return await _processTokenFromWatch(call.arguments);
      default:
        return null;
    }
  }

  static Map<String, dynamic>? _getTokenForWatch() {
    if (!initDone || initData.tokens.isEmpty) {
      debugPrint('[WatchSync] No token available');
      return {'error': 'no_token'};
    }

    final token = initData.tokens.first;

    if (token.accessToken == null ||
        token.refreshToken == null ||
        token.expiryDate == null) {
      debugPrint('[WatchSync] Token incomplete');
      return {'error': 'token_incomplete'};
    }

    if (KretaClient.needsReauth) {
      debugPrint('[WatchSync] iPhone needs reauth');
      return {'error': 'needsReauth'};
    }

    final tokenData = {
      'studentId': token.studentId,
      'studentIdNorm': token.studentIdNorm,
      'iss': token.iss,
      'idToken': token.idToken,
      'accessToken': token.accessToken,
      'refreshToken': token.refreshToken,
      'expiryDate': token.expiryDate!.millisecondsSinceEpoch,
    };

    debugPrint('[WatchSync] Returning token for Watch');
    return tokenData;
  }

  static Future<void> sendTokenToWatch() async {
    if (!Platform.isIOS) return;

    final tokenData = _getTokenForWatch();
    if (tokenData == null) return;

    try {
      await _watchChannel.invokeMethod('sendTokenToWatch', tokenData);
      debugPrint('[WatchSync] Token sent to Watch');
    } catch (e) {
      debugPrint('[WatchSync] Failed to send token: $e');
    }
  }

  static Future<Map<String, dynamic>> _processTokenFromWatch(dynamic arguments) async {
    if (!initDone) {
      debugPrint('[WatchSync] Cannot process Watch token: app not initialized');
      return {'success': false, 'error': 'not_initialized'};
    }

    try {
      final tokenData = arguments as Map<dynamic, dynamic>;

      final watchExpiry = tokenData['expiryDate'] as int?;
      if (watchExpiry == null) {
        debugPrint('[WatchSync] Watch token has no expiry');
        return {'success': false, 'error': 'no_expiry'};
      }

      final watchExpiryDate = DateTime.fromMillisecondsSinceEpoch(watchExpiry);

      if (watchExpiryDate.isBefore(DateTime.now())) {
        debugPrint('[WatchSync] Watch token is expired');
        return {'success': false, 'error': 'token_expired'};
      }

      debugPrint('[WatchSync] Accepting token from Watch, expiry: $watchExpiryDate');

      final newToken = TokenModel.fromValues(
        tokenData['studentIdNorm'] as int,
        tokenData['studentId'] as String,
        tokenData['iss'] as String,
        tokenData['idToken'] as String,
        tokenData['accessToken'] as String,
        tokenData['refreshToken'] as String,
        watchExpiry,
      );

      await initData.isar.writeTxn(() async {
        await initData.isar.tokenModels.put(newToken);
      });

      initData.tokens = await initData.isar.tokenModels.where().findAll();

      if (initData.client != null) {
        initData.client!.model = newToken;
      }

      KretaClient.clearReauthFlag();

      debugPrint('[WatchSync] Token from Watch saved successfully');
      return {'success': true};
    } catch (e) {
      debugPrint('[WatchSync] Failed to process Watch token: $e');
      return {'success': false, 'error': e.toString()};
    }
  }

  static Future<void> _sendTokenToWatchInternal(TokenModel token) async {
    if (!Platform.isIOS) return;

    if (token.accessToken == null ||
        token.refreshToken == null ||
        token.expiryDate == null) {
      debugPrint('[WatchSync] Token incomplete, not sending to Watch');
      return;
    }

    final tokenData = {
      'studentId': token.studentId,
      'studentIdNorm': token.studentIdNorm,
      'iss': token.iss,
      'idToken': token.idToken,
      'accessToken': token.accessToken,
      'refreshToken': token.refreshToken,
      'expiryDate': token.expiryDate!.millisecondsSinceEpoch,
    };

    try {
      await _watchChannel.invokeMethod('sendTokenToWatch', tokenData);
      debugPrint('[WatchSync] iPhone token sent to Watch');
    } catch (e) {
      debugPrint('[WatchSync] Failed to send token to Watch: $e');
    }
  }

  static String? _getLanguageForWatch() {
    if (!initDone) {
      debugPrint('[WatchSync] App not initialized, returning default language');
      return 'hu';
    }

    final languageCode = initData.l10n.localeName;
    debugPrint('[WatchSync] Returning language for Watch: $languageCode');
    return languageCode;
  }

  static Future<void> sendLanguageToWatch() async {
    if (!Platform.isIOS) return;

    final languageCode = _getLanguageForWatch();
    if (languageCode == null) return;

    try {
      await _watchChannel.invokeMethod('sendLanguageToWatch', languageCode);
      debugPrint('[WatchSync] Language sent to Watch: $languageCode');
    } catch (e) {
      debugPrint('[WatchSync] Failed to send language: $e');
    }
  }

  static Future<void> syncTokenFromWatch({
    Isar? isar,
    List<TokenModel>? tokens,
    KretaClient? client,
  }) async {
    if (!Platform.isIOS) return;

    final effectiveIsar = isar ?? (initDone ? initData.isar : null);
    final effectiveTokens = tokens ?? (initDone ? initData.tokens : null);
    final effectiveClient = client ?? (initDone ? initData.client : null);

    if (effectiveIsar == null || effectiveTokens == null) {
      debugPrint('[WatchSync] Cannot sync: no isar or tokens available');
      return;
    }

    try {
      debugPrint('[WatchSync] Requesting token from Watch...');
      final result = await _watchChannel.invokeMethod('requestTokenFromWatch');
      if (result == null) {
        debugPrint('[WatchSync] No token from Watch');
        return;
      }

      final tokenData = result as Map<dynamic, dynamic>;
      if (tokenData.containsKey('error')) {
        debugPrint('[WatchSync] Watch returned error: ${tokenData['error']}');
        return;
      }

      final watchExpiry = tokenData['expiryDate'] as int?;
      if (watchExpiry == null) {
        debugPrint('[WatchSync] Watch token has no expiry');
        return;
      }

      final watchExpiryDate = DateTime.fromMillisecondsSinceEpoch(watchExpiry);
      final currentToken = effectiveTokens.isNotEmpty ? effectiveTokens.first : null;

      if (currentToken?.expiryDate == null || watchExpiryDate.isAfter(currentToken!.expiryDate!)) {
        debugPrint('[WatchSync] Watch has newer token, updating iPhone');
        final newToken = TokenModel.fromValues(
          tokenData['studentIdNorm'] as int,
          tokenData['studentId'] as String,
          tokenData['iss'] as String,
          tokenData['idToken'] as String,
          tokenData['accessToken'] as String,
          tokenData['refreshToken'] as String,
          watchExpiry,
        );

        await effectiveIsar.writeTxn(() async {
          await effectiveIsar.tokenModels.put(newToken);
        });

        final updatedTokens = await effectiveIsar.tokenModels.where().findAll();

        if (initDone) {
          initData.tokens = updatedTokens;
        }

        if (effectiveClient != null) {
          effectiveClient.model = newToken;
        }

        KretaClient.clearReauthFlag();

        debugPrint('[WatchSync] Token updated from Watch. New expiry: $watchExpiryDate');
      } else {
        debugPrint('[WatchSync] iPhone token is same or newer, sending to Watch');
        await _sendTokenToWatchInternal(currentToken!);
      }
    } catch (e) {
      debugPrint('[WatchSync] Failed to sync token from Watch: $e');
    }
  }
}
