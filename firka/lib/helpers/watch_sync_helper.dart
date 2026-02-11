import 'dart:async';
import 'dart:convert';
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

  /// Invoke method with timeout to prevent infinite blocking
  static Future<T?> _invokeMethodWithTimeout<T>(
    String method, [
    dynamic arguments,
    Duration timeout = const Duration(seconds: 10),
  ]) async {
    try {
      return await _watchChannel
          .invokeMethod<T>(method, arguments)
          .timeout(timeout, onTimeout: () {
        debugPrint(
            '[WatchSync] Timeout calling $method after ${timeout.inSeconds}s');
        return null;
      });
    } catch (e) {
      debugPrint('[WatchSync] Error calling $method: $e');
      return null;
    }
  }

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

  static int? _asInt(dynamic value) {
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
  }

  static int? _extractTokenVersionFromIdToken(String? idToken) {
    if (idToken == null || idToken.isEmpty) return null;
    final parts = idToken.split('.');
    if (parts.length < 2) return null;

    try {
      final payloadJson =
          utf8.decode(base64Url.decode(base64Url.normalize(parts[1])));
      final payload = jsonDecode(payloadJson);
      if (payload is! Map) return null;
      final iatSeconds = _asInt(payload['iat']);
      if (iatSeconds == null || iatSeconds <= 0) return null;
      return iatSeconds * 1000;
    } catch (_) {
      return null;
    }
  }

  static int? _resolveIncomingTokenVersion(Map<dynamic, dynamic> tokenData) {
    return _asInt(tokenData['tokenVersion']) ??
        _extractTokenVersionFromIdToken(tokenData['idToken'] as String?);
  }

  static int? _resolveTokenVersionForModel(TokenModel token) {
    final tokenVersion = token.tokenVersion;
    if (tokenVersion != null && tokenVersion > 0) {
      return tokenVersion;
    }
    return _extractTokenVersionFromIdToken(token.idToken);
  }

  static int? _resolveUpdatedAtForModel(TokenModel token) {
    final updatedAtMs = token.updatedAtMs;
    if (updatedAtMs != null && updatedAtMs > 0) {
      return updatedAtMs;
    }
    return null;
  }

  static bool _isIncomingTokenNewerThanCurrent({
    required DateTime incomingExpiry,
    required String? incomingIdToken,
    required String? incomingRefreshToken,
    required int? incomingTokenVersion,
    required int? incomingUpdatedAtMs,
    required TokenModel currentToken,
  }) {
    final currentExpiry = currentToken.expiryDate;
    if (currentExpiry == null) {
      return true;
    }

    final incomingVersion = incomingTokenVersion ??
        _extractTokenVersionFromIdToken(incomingIdToken);
    final currentVersion = _resolveTokenVersionForModel(currentToken);
    final currentUpdatedAtMs = _resolveUpdatedAtForModel(currentToken);

    if (incomingVersion != null &&
        currentVersion != null &&
        incomingVersion != currentVersion) {
      return incomingVersion > currentVersion;
    }

    if (incomingExpiry.isAfter(currentExpiry)) {
      return true;
    }
    if (incomingExpiry.isBefore(currentExpiry)) {
      return false;
    }

    if (incomingVersion != null && currentVersion == null) {
      return true;
    }
    if (incomingVersion == null && currentVersion != null) {
      return false;
    }

    if (incomingUpdatedAtMs != null &&
        currentUpdatedAtMs != null &&
        incomingUpdatedAtMs != currentUpdatedAtMs) {
      return incomingUpdatedAtMs > currentUpdatedAtMs;
    }
    if (incomingUpdatedAtMs != null && currentUpdatedAtMs == null) {
      return true;
    }
    if (incomingUpdatedAtMs == null && currentUpdatedAtMs != null) {
      return false;
    }

    final currentRefresh = currentToken.refreshToken;
    if (incomingRefreshToken != null &&
        currentRefresh != null &&
        incomingRefreshToken != currentRefresh) {
      if (incomingIdToken != null && incomingIdToken != currentToken.idToken) {
        return true;
      }
      return false;
    }

    return false;
  }

  static Map<String, dynamic> _buildTokenSyncPayload(
    TokenModel token, {
    bool includeSentAt = false,
  }) {
    final nowMs = DateTime.now().millisecondsSinceEpoch;
    final tokenVersion = _resolveTokenVersionForModel(token) ?? nowMs;
    final updatedAtMs = (token.updatedAtMs != null && token.updatedAtMs! > 0)
        ? token.updatedAtMs!
        : nowMs;
    final payload = <String, dynamic>{
      'studentId': token.studentId,
      'studentIdNorm': token.studentIdNorm,
      'iss': token.iss,
      'idToken': token.idToken,
      'accessToken': token.accessToken,
      'refreshToken': token.refreshToken,
      'expiryDate': token.expiryDate!.millisecondsSinceEpoch,
      'tokenVersion': tokenVersion,
      'updatedAtMs': updatedAtMs,
    };
    if (includeSentAt) {
      payload['sentAtMs'] = nowMs;
    }
    return payload;
  }

  static void initialize() {
    if (!Platform.isIOS) return;
    if (_initialized) return;
    _initialized = true;

    _watchChannel.setMethodCallHandler(_handleMethodCall);
    debugPrint('[WatchSync] Handler initialized');
    unawaited(_invokeMethodWithTimeout(
      'watchSyncReady',
      null,
      const Duration(seconds: 2),
    ));
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
        debugPrint(
            '[WatchSync] Token recovered from iCloud notification received');
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
      debugPrint(
          '[WatchSync] Cannot handle iCloud recovery: app not initialized');
      return;
    }

    try {
      final recovered = await checkAndRecoverFromiCloud(
        isar: initData.isar,
        tokens: initData.tokens,
        client: initData.client,
      );

      if (recovered) {
        debugPrint(
            '[WatchSync] Token recovered from iCloud, reauth flag cleared');
      } else {
        final token = pickActiveToken(
          tokens: initData.tokens,
          settings: initData.settings,
        );
        final expiryDate = token?.expiryDate;
        if (expiryDate != null && expiryDate.isAfter(DateTime.now())) {
          KretaClient.clearReauthFlag();
          debugPrint(
              '[WatchSync] Cleared reauth flag after iCloud notification (token is valid)');
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

    final tokenData = _buildTokenSyncPayload(token, includeSentAt: true);

    debugPrint('[WatchSync] Returning token for Watch');
    return tokenData;
  }

  static Future<void> sendTokenToWatch() async {
    if (!Platform.isIOS) return;

    final tokenData = _getTokenForWatch();
    if (tokenData == null) return;

    await _invokeMethodWithTimeout('sendTokenToWatch', tokenData);
    debugPrint('[WatchSync] Token send requested to Watch (async delivery)');
  }

  /// Sends a specific token directly to Watch.
  /// Useful during app initialization before global init state is fully ready.
  static Future<void> sendTokenModelToWatch(TokenModel token) async {
    if (!Platform.isIOS) return;
    await _sendTokenToWatchInternal(token);
  }

  static Future<Map<String, dynamic>> _processTokenFromWatch(
      dynamic arguments) async {
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
      final currentToken = _resolveCurrentToken(
        tokens: initData.tokens,
        client: initData.client,
      );

      final watchExpiryDate = DateTime.fromMillisecondsSinceEpoch(watchExpiry);
      final watchTokenVersion = _resolveIncomingTokenVersion(tokenData);
      final watchUpdatedAtMs = _asInt(tokenData['updatedAtMs']);
      final watchIdToken = tokenData['idToken'] as String?;
      final watchRefreshToken = tokenData['refreshToken'] as String?;

      final isForActiveAccount = expectedStudentIdNorm == null ||
          watchStudentIdNorm == expectedStudentIdNorm;
      if (isForActiveAccount &&
          currentToken != null &&
          currentToken.studentIdNorm == watchStudentIdNorm) {
        if (!_isIncomingTokenNewerThanCurrent(
          incomingExpiry: watchExpiryDate,
          incomingIdToken: watchIdToken,
          incomingRefreshToken: watchRefreshToken,
          incomingTokenVersion: watchTokenVersion,
          incomingUpdatedAtMs: watchUpdatedAtMs,
          currentToken: currentToken,
        )) {
          debugPrint(
              '[WatchSync] Ignoring stale token from Watch for active account. Incoming expiry: $watchExpiryDate, incomingVersion: $watchTokenVersion');
          return {'success': false, 'error': 'stale_token'};
        }
      }

      debugPrint(
          '[WatchSync] Accepting token from Watch, expiry: $watchExpiryDate (expired: ${watchExpiryDate.isBefore(DateTime.now())})');

      final newToken = TokenModel.fromValues(
        watchStudentIdNorm,
        tokenData['studentId'] as String,
        tokenData['iss'] as String,
        tokenData['idToken'] as String,
        tokenData['accessToken'] as String,
        tokenData['refreshToken'] as String,
        watchExpiry,
        tokenVersion: watchTokenVersion,
        updatedAtMs: watchUpdatedAtMs ?? DateTime.now().millisecondsSinceEpoch,
      );

      await initData.isar.writeTxn(() async {
        await initData.isar.tokenModels.put(newToken);
      });

      initData.tokens = await initData.isar.tokenModels.where().findAll();
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

    final tokenData = _buildTokenSyncPayload(token, includeSentAt: true);

    await _invokeMethodWithTimeout('sendTokenToWatch', tokenData);
    debugPrint('[WatchSync] iPhone token sent to Watch (or timeout)');
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

    await _invokeMethodWithTimeout('sendLanguageToWatch', languageCode);
    debugPrint(
        '[WatchSync] Language sent to Watch: $languageCode (or timeout)');
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
      final result = await _invokeMethodWithTimeout(
          'checkiCloudToken', null, const Duration(seconds: 5));

      if (result == null) {
        debugPrint('[WatchSync] No response from native (timeout or error)');
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
      if (expectedStudentIdNorm != null &&
          iCloudStudentIdNorm != expectedStudentIdNorm) {
        debugPrint(
            '[WatchSync] iCloud token belongs to different account ($iCloudStudentIdNorm), active is $expectedStudentIdNorm - ignoring');
        return false;
      }

      final iCloudExpiry = tokenData['expiryDate'] as int?;
      if (iCloudExpiry == null) {
        debugPrint('[WatchSync] iCloud token has no expiry');
        return false;
      }

      final iCloudExpiryDate =
          DateTime.fromMillisecondsSinceEpoch(iCloudExpiry);
      final iCloudTokenVersion = _resolveIncomingTokenVersion(tokenData);
      final iCloudUpdatedAtMs = _asInt(tokenData['updatedAtMs']);
      final iCloudIdToken = tokenData['idToken'] as String?;
      final iCloudRefreshToken = tokenData['refreshToken'] as String?;

      final currentToken = _resolveCurrentToken(
        tokens: effectiveTokens,
        client: effectiveClient,
      );
      final localExpiry = currentToken?.expiryDate;
      final shouldAccept = currentToken == null
          ? true
          : _isIncomingTokenNewerThanCurrent(
              incomingExpiry: iCloudExpiryDate,
              incomingIdToken: iCloudIdToken,
              incomingRefreshToken: iCloudRefreshToken,
              incomingTokenVersion: iCloudTokenVersion,
              incomingUpdatedAtMs: iCloudUpdatedAtMs,
              currentToken: currentToken,
            );

      if (shouldAccept) {
        debugPrint(
            '[WatchSync] iCloud has fresher token! iCloud: $iCloudExpiryDate, Local: $localExpiry, iCloudVersion: $iCloudTokenVersion');

        final newToken = TokenModel.fromValues(
          (tokenData['studentIdNorm'] as int?) ?? 0,
          tokenData['studentId'] as String,
          tokenData['iss'] as String,
          tokenData['idToken'] as String,
          tokenData['accessToken'] as String,
          tokenData['refreshToken'] as String,
          iCloudExpiry,
          tokenVersion: iCloudTokenVersion,
          updatedAtMs:
              iCloudUpdatedAtMs ?? DateTime.now().millisecondsSinceEpoch,
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

        debugPrint(
            '[WatchSync] Token recovered from iCloud! New expiry: $iCloudExpiryDate');
        return true;
      } else {
        debugPrint(
            '[WatchSync] Local token is same or fresher. Local: $localExpiry, iCloud: $iCloudExpiryDate');
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

    final tokenData = _buildTokenSyncPayload(token);

    await _invokeMethodWithTimeout(
        'saveTokeToniCloud', tokenData, const Duration(seconds: 5));
    debugPrint('[WatchSync] Token saved to iCloud (or timeout)');
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
      final result = await _invokeMethodWithTimeout(
          'requestTokenFromWatch', null, const Duration(seconds: 10));
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
          debugPrint(
              '[WatchSync] Sending iPhone token to Watch (Watch has no token)');
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

      if (expectedStudentIdNorm != null &&
          watchStudentIdNorm != expectedStudentIdNorm) {
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
      final watchTokenVersion = _resolveIncomingTokenVersion(tokenData);
      final watchUpdatedAtMs = _asInt(tokenData['updatedAtMs']);
      final watchIdToken = tokenData['idToken'] as String?;
      final watchRefreshToken = tokenData['refreshToken'] as String?;
      final shouldAccept = currentToken == null
          ? true
          : _isIncomingTokenNewerThanCurrent(
              incomingExpiry: watchExpiryDate,
              incomingIdToken: watchIdToken,
              incomingRefreshToken: watchRefreshToken,
              incomingTokenVersion: watchTokenVersion,
              incomingUpdatedAtMs: watchUpdatedAtMs,
              currentToken: currentToken,
            );
      if (shouldAccept) {
        debugPrint('[WatchSync] Watch has newer token, updating iPhone');
        final newToken = TokenModel.fromValues(
          tokenData['studentIdNorm'] as int,
          tokenData['studentId'] as String,
          tokenData['iss'] as String,
          tokenData['idToken'] as String,
          tokenData['accessToken'] as String,
          tokenData['refreshToken'] as String,
          watchExpiry,
          tokenVersion: watchTokenVersion,
          updatedAtMs:
              watchUpdatedAtMs ?? DateTime.now().millisecondsSinceEpoch,
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

        debugPrint(
            '[WatchSync] Token updated from Watch. New expiry: $watchExpiryDate');
      } else {
        debugPrint(
            '[WatchSync] iPhone token is same or newer, sending to Watch');
        await _sendTokenToWatchInternal(currentToken);
      }
    } catch (e) {
      debugPrint('[WatchSync] Failed to sync token from Watch: $e');
    }
  }
}
