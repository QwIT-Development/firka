import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:isar/isar.dart';

import '../main.dart';
import 'active_account_helper.dart';
import 'api/client/kreta_client.dart';
import 'db/models/token_model.dart';

/// Helper class for Watch ↔ iPhone token sync
class WatchSyncHelper {
  static const _watchChannel = MethodChannel('app.firka/watch_sync');
  static bool _initialized = false;

  static TokenModel? _resolveCurrentToken({
    List<TokenModel>? tokens,
    KretaClient? client,
  }) {
    final effectiveTokens = tokens ?? (initDone ? initData.tokens : null);
    if (effectiveTokens == null || effectiveTokens.isEmpty) return null;

    final preferredStudentIdNorm = client?.model.studentIdNorm;
    if (preferredStudentIdNorm != null) {
      for (final token in effectiveTokens) {
        if (token.studentIdNorm == preferredStudentIdNorm) {
          return token;
        }
      }
    }

    if (initDone) {
      return pickActiveToken(
        tokens: effectiveTokens,
        settings: initData.settings,
        preferredStudentIdNorm: preferredStudentIdNorm,
      );
    }

    return effectiveTokens.first;
  }

  static int? _resolveExpectedStudentIdNorm({
    List<TokenModel>? tokens,
    KretaClient? client,
  }) {
    final fromClient = client?.model.studentIdNorm;
    if (fromClient != null) return fromClient;
    return _resolveCurrentToken(tokens: tokens, client: client)?.studentIdNorm;
  }

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
      case 'onTokenRecoveredFromiCloud':
        debugPrint('[WatchSync] Token recovered from iCloud notification received');
        await _handleTokenRecoveredFromiCloud();
        return null;
      default:
        return null;
    }
  }

  /// Called when iOS receives a fresh token from iCloud (e.g., Watch refreshed)
  /// This clears the reauth flag if it was set, since we now have a valid token
  static Future<void> _handleTokenRecoveredFromiCloud() async {
    if (!initDone) {
      debugPrint('[WatchSync] Cannot handle iCloud recovery: app not initialized');
      return;
    }

    try {
      final recovered = await checkAndRecoverFromiCloud(
        isar: initData.isar,
        tokens: initData.tokens,
        client: initData.client,
      );

      if (recovered) {
        debugPrint('[WatchSync] Token recovered from iCloud, reauth flag cleared');
      } else {
        final token = pickActiveToken(
          tokens: initData.tokens,
          settings: initData.settings,
        );
        final expiryDate = token?.expiryDate;
        if (expiryDate != null && expiryDate.isAfter(DateTime.now())) {
          KretaClient.clearReauthFlag();
          debugPrint('[WatchSync] Cleared reauth flag after iCloud notification (token is valid)');
        }
      }
    } catch (e) {
      debugPrint('[WatchSync] Failed to handle iCloud recovery: $e');
    }
  }

  static Map<String, dynamic>? _getTokenForWatch() {
    if (!initDone || initData.tokens.isEmpty) {
      debugPrint('[WatchSync] No token available');
      return {'error': 'no_token'};
    }

    final token = pickActiveToken(
      tokens: initData.tokens,
      settings: initData.settings,
    );
    if (token == null) {
      debugPrint('[WatchSync] No active token available');
      return {'error': 'no_token'};
    }

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

      final watchStudentIdNorm = tokenData['studentIdNorm'] as int?;
      if (watchStudentIdNorm == null) {
        debugPrint('[WatchSync] Watch token has no studentIdNorm');
        return {'success': false, 'error': 'no_student_id_norm'};
      }

      final expectedStudentIdNorm = _resolveExpectedStudentIdNorm(
        tokens: initData.tokens,
        client: initData.client,
      );

      final watchExpiryDate = DateTime.fromMillisecondsSinceEpoch(watchExpiry);

      if (watchExpiryDate.isBefore(DateTime.now())) {
        debugPrint('[WatchSync] Watch token is expired');
        return {'success': false, 'error': 'token_expired'};
      }

      debugPrint('[WatchSync] Accepting token from Watch, expiry: $watchExpiryDate');

      final newToken = TokenModel.fromValues(
        watchStudentIdNorm,
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
      final isForActiveAccount = expectedStudentIdNorm == null ||
          watchStudentIdNorm == expectedStudentIdNorm;
      if (isForActiveAccount) {
        initData.client.model = newToken;
        KretaClient.clearReauthFlag();
      } else {
        debugPrint(
            '[WatchSync] Stored token for inactive account ($watchStudentIdNorm), active is $expectedStudentIdNorm');
      }

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

  /// Check iCloud for a fresher token and update local storage if found.
  /// This should be called on app startup BEFORE any API calls.
  /// Returns true if a fresher token was found and applied.
  static Future<bool> checkAndRecoverFromiCloud({
    Isar? isar,
    List<TokenModel>? tokens,
    KretaClient? client,
  }) async {
    if (!Platform.isIOS) return false;

    final effectiveIsar = isar ?? (initDone ? initData.isar : null);
    final effectiveTokens = tokens ?? (initDone ? initData.tokens : null);
    final effectiveClient = client ?? (initDone ? initData.client : null);

    if (effectiveIsar == null) {
      debugPrint('[WatchSync] Cannot check iCloud: no isar available');
      return false;
    }

    try {
      debugPrint('[WatchSync] Checking iCloud for fresher token...');
      final result = await _watchChannel.invokeMethod('checkiCloudToken');

      if (result == null) {
        debugPrint('[WatchSync] No response from native');
        return false;
      }

      final tokenData = result as Map<dynamic, dynamic>;
      if (tokenData.containsKey('error')) {
        debugPrint('[WatchSync] iCloud check returned: ${tokenData['error']}');
        return false;
      }

      final expectedStudentIdNorm = _resolveExpectedStudentIdNorm(
        tokens: effectiveTokens,
        client: effectiveClient,
      );

      final iCloudStudentIdNorm = tokenData['studentIdNorm'] as int?;
      if (expectedStudentIdNorm != null && iCloudStudentIdNorm != expectedStudentIdNorm) {
        debugPrint(
            '[WatchSync] iCloud token belongs to different account ($iCloudStudentIdNorm), active is $expectedStudentIdNorm - ignoring');
        return false;
      }

      final iCloudExpiry = tokenData['expiryDate'] as int?;
      if (iCloudExpiry == null) {
        debugPrint('[WatchSync] iCloud token has no expiry');
        return false;
      }

      final iCloudExpiryDate = DateTime.fromMillisecondsSinceEpoch(iCloudExpiry);

      if (iCloudExpiryDate.isBefore(DateTime.now())) {
        debugPrint('[WatchSync] iCloud token is expired');
        return false;
      }

      final currentToken = _resolveCurrentToken(
        tokens: effectiveTokens,
        client: effectiveClient,
      );
      final localExpiry = currentToken?.expiryDate;

      if (localExpiry == null || iCloudExpiryDate.isAfter(localExpiry)) {
        debugPrint('[WatchSync] iCloud has fresher token! iCloud: $iCloudExpiryDate, Local: $localExpiry');

        final newToken = TokenModel.fromValues(
          (tokenData['studentIdNorm'] as int?) ?? 0,
          tokenData['studentId'] as String,
          tokenData['iss'] as String,
          tokenData['idToken'] as String,
          tokenData['accessToken'] as String,
          tokenData['refreshToken'] as String,
          iCloudExpiry,
        );

        await effectiveIsar.writeTxn(() async {
          await effectiveIsar.tokenModels.put(newToken);
        });

        final updatedTokens = await effectiveIsar.tokenModels.where().findAll();

        if (initDone) {
          initData.tokens = updatedTokens;
        }

        if (effectiveClient != null &&
            (expectedStudentIdNorm == null ||
                newToken.studentIdNorm == expectedStudentIdNorm)) {
          effectiveClient.model = newToken;
        }

        if (expectedStudentIdNorm == null ||
            newToken.studentIdNorm == expectedStudentIdNorm) {
          KretaClient.clearReauthFlag();
        }

        debugPrint('[WatchSync] Token recovered from iCloud! New expiry: $iCloudExpiryDate');
        return true;
      } else {
        debugPrint('[WatchSync] Local token is same or fresher. Local: $localExpiry, iCloud: $iCloudExpiryDate');
        return false;
      }
    } catch (e) {
      debugPrint('[WatchSync] Failed to check iCloud: $e');
      return false;
    }
  }

  /// Save token to iCloud. Call this after refreshing token on iPhone.
  static Future<void> saveTokenToiCloud(TokenModel token) async {
    if (!Platform.isIOS) return;

    if (token.accessToken == null ||
        token.refreshToken == null ||
        token.expiryDate == null) {
      debugPrint('[WatchSync] Token incomplete, not saving to iCloud');
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
      await _watchChannel.invokeMethod('saveTokeToniCloud', tokenData);
      debugPrint('[WatchSync] Token saved to iCloud');
    } catch (e) {
      debugPrint('[WatchSync] Failed to save token to iCloud: $e');
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
      final expectedStudentIdNorm = _resolveExpectedStudentIdNorm(
        tokens: effectiveTokens,
        client: effectiveClient,
      );
      final currentToken = _resolveCurrentToken(
        tokens: effectiveTokens,
        client: effectiveClient,
      );

      if (result == null) {
        debugPrint('[WatchSync] No response from Watch');
        if (currentToken != null &&
            currentToken.accessToken != null &&
            currentToken.refreshToken != null &&
            currentToken.expiryDate != null &&
            !KretaClient.needsReauth) {
          debugPrint('[WatchSync] Sending iPhone token to Watch (no response)');
          await _sendTokenToWatchInternal(currentToken);
        }
        return;
      }

      final tokenData = result as Map<dynamic, dynamic>;
      if (tokenData.containsKey('error')) {
        debugPrint('[WatchSync] Watch returned error: ${tokenData['error']}');
        if (currentToken != null &&
            currentToken.accessToken != null &&
            currentToken.refreshToken != null &&
            currentToken.expiryDate != null &&
            !KretaClient.needsReauth) {
          debugPrint('[WatchSync] Sending iPhone token to Watch (Watch has no token)');
          await _sendTokenToWatchInternal(currentToken);
        }
        return;
      }

      final watchExpiry = tokenData['expiryDate'] as int?;
      if (watchExpiry == null) {
        debugPrint('[WatchSync] Watch token has no expiry');
        return;
      }

      final watchStudentIdNorm = tokenData['studentIdNorm'] as int?;
      if (watchStudentIdNorm == null) {
        debugPrint('[WatchSync] Watch token has no studentIdNorm');
        return;
      }

      if (expectedStudentIdNorm != null && watchStudentIdNorm != expectedStudentIdNorm) {
        debugPrint(
            '[WatchSync] Watch token belongs to different account ($watchStudentIdNorm), active is $expectedStudentIdNorm - keeping active account');
        if (currentToken != null &&
            currentToken.accessToken != null &&
            currentToken.refreshToken != null &&
            currentToken.expiryDate != null &&
            !KretaClient.needsReauth) {
          await _sendTokenToWatchInternal(currentToken);
        }
        return;
      }

      final watchExpiryDate = DateTime.fromMillisecondsSinceEpoch(watchExpiry);

      final currentExpiry = currentToken?.expiryDate;
      if (currentExpiry == null || watchExpiryDate.isAfter(currentExpiry)) {
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

        if (effectiveClient != null &&
            (expectedStudentIdNorm == null ||
                newToken.studentIdNorm == expectedStudentIdNorm)) {
          effectiveClient.model = newToken;
        }

        if (expectedStudentIdNorm == null ||
            newToken.studentIdNorm == expectedStudentIdNorm) {
          KretaClient.clearReauthFlag();
        }

        debugPrint('[WatchSync] Token updated from Watch. New expiry: $watchExpiryDate');
      } else {
        debugPrint('[WatchSync] iPhone token is same or newer, sending to Watch');
        final tokenToSend = currentToken;
        if (tokenToSend != null) {
          await _sendTokenToWatchInternal(tokenToSend);
        }
      }
    } catch (e) {
      debugPrint('[WatchSync] Failed to sync token from Watch: $e');
    }
  }
}
