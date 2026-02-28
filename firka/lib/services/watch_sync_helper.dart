import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:isar_community/isar.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:firka/app/app_state.dart';
import 'package:firka/services/active_account_helper.dart';
import 'package:firka/api/client/kreta_client.dart';
import 'package:firka/data/models/token_model.dart';

/// Helper class for Watch ↔ iPhone token sync
class WatchSyncHelper {
  static const _watchChannel = MethodChannel('app.firka/watch_sync');
  static const _leaseOwnerIPhone = 'iphone';
  static bool _initialized = false;
  static bool _watchAppInstalledCache = false;
  static DateTime? _lastWatchInstallCheckAt;
  static const Duration _watchInstallCheckCooldown = Duration(seconds: 10);
  static const Duration _tokenUsableSkew = Duration(seconds: 60);
  static const Duration _leasePollInterval = Duration(milliseconds: 250);
  static const Duration _iPhoneRefreshLeaseTtl = Duration(seconds: 120);
  static const Duration _watchRefreshLeaseMaxWait = Duration(seconds: 150);
  static const String _iosFreshInstallHandledKey =
      'ios_fresh_install_cleanup_done_v1';

  /// Invoke method with timeout to prevent infinite blocking
  static Future<T?> _invokeMethodWithTimeout<T>(
    String method, [
    dynamic arguments,
    Duration timeout = const Duration(seconds: 10),
  ]) async {
    try {
      return await _watchChannel
          .invokeMethod<T>(method, arguments)
          .timeout(
            timeout,
            onTimeout: () {
              debugPrint(
                '[WatchSync] Timeout calling $method after ${timeout.inSeconds}s',
              );
              return null;
            },
          );
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
      final payloadJson = utf8.decode(
        base64Url.decode(base64Url.normalize(parts[1])),
      );
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

    final incomingVersion =
        incomingTokenVersion ??
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

  static bool _isAccessTokenUsable(
    DateTime? expiryDate, {
    Duration skew = _tokenUsableSkew,
  }) {
    if (expiryDate == null) return false;
    return expiryDate.isAfter(DateTime.now().add(skew));
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
    unawaited(
      _invokeMethodWithTimeout(
        'watchSyncReady',
        null,
        const Duration(seconds: 2),
      ),
    );
  }

  static Future<bool> isWatchAppInstalled({bool forceRefresh = false}) async {
    if (!Platform.isIOS) return false;
    if (_watchAppInstalledCache && !forceRefresh) return true;

    final now = DateTime.now();
    if (!forceRefresh &&
        _lastWatchInstallCheckAt != null &&
        now.difference(_lastWatchInstallCheckAt!) <
            _watchInstallCheckCooldown) {
      return _watchAppInstalledCache;
    }
    _lastWatchInstallCheckAt = now;

    final result = await _invokeMethodWithTimeout<bool>(
      'isWatchAppInstalled',
      null,
      const Duration(seconds: 2),
    );
    _watchAppInstalledCache = result == true;
    return _watchAppInstalledCache;
  }

  static Future<bool> isWatchReachable({
    bool forceRefreshInstall = false,
  }) async {
    if (!Platform.isIOS) return false;

    final watchInstalled = await isWatchAppInstalled(
      forceRefresh: forceRefreshInstall,
    );
    if (!watchInstalled) return false;

    final result = await _invokeMethodWithTimeout<bool>(
      'isWatchReachable',
      null,
      const Duration(seconds: 2),
    );
    return result == true;
  }

  static Future<void> clearICloudToken({bool notifyWatch = false}) async {
    if (!Platform.isIOS) return;
    await _invokeMethodWithTimeout(
      'clearICloudToken',
      null,
      const Duration(seconds: 5),
    );
    if (notifyWatch) {
      await notifyWatchForceLogout();
    }
  }

  static Future<void> notifyWatchForceLogout() async {
    if (!Platform.isIOS) return;
    final watchInstalled = await isWatchAppInstalled(forceRefresh: true);
    if (!watchInstalled) return;
    await _invokeMethodWithTimeout(
      'sendLogoutToWatch',
      null,
      const Duration(seconds: 5),
    );
  }

  static Future<bool> waitForWatchRefreshLease({
    required int studentIdNorm,
    Duration maxWait = _watchRefreshLeaseMaxWait,
  }) async {
    if (!Platform.isIOS) return true;
    final watchInstalled = await isWatchAppInstalled();
    if (!watchInstalled) return true;

    final timeout = maxWait + const Duration(seconds: 5);
    final result =
        await _invokeMethodWithTimeout<dynamic>('waitForPeerRefreshLease', {
          'owner': _leaseOwnerIPhone,
          'studentIdNorm': studentIdNorm,
          'maxWaitMs': maxWait.inMilliseconds,
          'pollIntervalMs': _leasePollInterval.inMilliseconds,
        }, timeout);

    if (result is! Map) {
      debugPrint('[WatchSync] Lease wait returned invalid response: $result');
      return true;
    }

    final ready = result['ready'] == true;
    final status = result['status'];
    final waitedMs = result['waitedMs'];
    final leaseChanged = result['leaseChanged'] == true;
    debugPrint(
      '[WatchSync] Lease wait status=$status ready=$ready waitedMs=$waitedMs leaseChanged=$leaseChanged',
    );
    return ready;
  }

  static Future<String?> acquireIPhoneRefreshLease({
    required int studentIdNorm,
    Duration ttl = _iPhoneRefreshLeaseTtl,
  }) async {
    if (!Platform.isIOS) return null;
    final watchInstalled = await isWatchAppInstalled();
    if (!watchInstalled) return null;

    final result =
        await _invokeMethodWithTimeout<dynamic>('acquireRefreshLease', {
          'owner': _leaseOwnerIPhone,
          'studentIdNorm': studentIdNorm,
          'ttlMs': ttl.inMilliseconds,
        }, const Duration(seconds: 5));

    if (result is! Map) {
      debugPrint(
        '[WatchSync] Lease acquire returned invalid response: $result',
      );
      return null;
    }
    if (result['skipped'] == true) {
      return null;
    }
    final operationId = result['operationId'] as String?;
    if (operationId == null || operationId.isEmpty) {
      debugPrint('[WatchSync] Lease acquire response missing operationId');
      return null;
    }
    return operationId;
  }

  static Future<void> releaseIPhoneRefreshLease({
    required int studentIdNorm,
    required String operationId,
  }) async {
    if (!Platform.isIOS) return;
    await _invokeMethodWithTimeout('releaseRefreshLease', {
      'owner': _leaseOwnerIPhone,
      'studentIdNorm': studentIdNorm,
      'operationId': operationId,
    }, const Duration(seconds: 5));
  }

  static Future<void> clearRefreshLeaseForAccount(int studentIdNorm) async {
    if (!Platform.isIOS) return;
    final watchInstalled = await isWatchAppInstalled();
    if (!watchInstalled) return;
    await _invokeMethodWithTimeout('clearRefreshLeaseForAccount', {
      'studentIdNorm': studentIdNorm,
    }, const Duration(seconds: 5));
  }

  static Future<void> clearAllRefreshLeases() async {
    if (!Platform.isIOS) return;
    final watchInstalled = await isWatchAppInstalled();
    if (!watchInstalled) return;
    await _invokeMethodWithTimeout(
      'clearAllRefreshLeases',
      null,
      const Duration(seconds: 5),
    );
  }

  static Future<void> clearSharedLanguageState() async {
    if (!Platform.isIOS) return;
    final watchInstalled = await isWatchAppInstalled();
    if (!watchInstalled) return;
    await _invokeMethodWithTimeout(
      'clearSharedLanguageState',
      null,
      const Duration(seconds: 5),
    );
  }

  static Future<bool> runFreshInstallCleanupIfNeeded({
    required Isar isar,
  }) async {
    if (!Platform.isIOS) return false;

    final prefs = await SharedPreferences.getInstance();
    final cleanupHandled = prefs.getBool(_iosFreshInstallHandledKey) ?? false;
    if (cleanupHandled) {
      return false;
    }

    debugPrint(
      '[WatchSync] Fresh iOS install detected, clearing iCloud and local auth state',
    );
    await clearICloudToken(notifyWatch: true);
    await clearAllRefreshLeases();

    await isar.writeTxn(() async {
      await isar.tokenModels.clear();
    });

    if (initDone) {
      initData.tokens = [];
    }
    if (initDone) initData.reauthCubit?.clear();

    await prefs.setBool(_iosFreshInstallHandledKey, true);
    return true;
  }

  static Future<dynamic> _handleMethodCall(MethodCall call) async {
    switch (call.method) {
      case 'getTokenForWatch':
        return _getTokenForWatch();
      case 'getLanguageForWatch':
        return _getLanguageForWatch();
      case 'watchAppInstalled':
        debugPrint('[WatchSync] Watch app installed detected');
        _watchAppInstalledCache = true;
        _lastWatchInstallCheckAt = DateTime.now();
        return null;
      case 'onTokenFromWatch':
        debugPrint('[WatchSync] Token received from Watch');
        return await _processTokenFromWatch(call.arguments);
      case 'onTokenRecoveredFromiCloud':
        debugPrint(
          '[WatchSync] Token recovered from iCloud notification received',
        );
        await _handleTokenRecoveredFromiCloud();
        return null;
      case 'onWatchMessage':
        _handleWatchMessage(call.arguments);
        return null;
      default:
        return null;
    }
  }

  /// Callback for Watch pairing message events.
  /// Set by main.dart to handle "ping" messages for Watch pairing flow.
  static void Function(Map<String, dynamic> message)? onWatchMessage;

  static void _handleWatchMessage(dynamic arguments) {
    if (arguments == null) return;
    try {
      final Map<String, dynamic> message;
      if (arguments is Map<String, dynamic>) {
        message = arguments;
      } else if (arguments is Map) {
        message = Map<String, dynamic>.from(arguments);
      } else {
        debugPrint(
          '[WatchSync] onWatchMessage: unexpected type ${arguments.runtimeType}',
        );
        return;
      }
      debugPrint('[WatchSync] Received Watch message: ${message["id"]}');
      onWatchMessage?.call(message);
    } catch (e) {
      debugPrint('[WatchSync] Error handling Watch message: $e');
    }
  }

  /// Called when iOS receives a fresh token from iCloud (e.g., Watch refreshed)
  /// This clears the reauth flag if it was set, since we now have a valid token
  static Future<void> _handleTokenRecoveredFromiCloud() async {
    if (!initDone) {
      debugPrint(
        '[WatchSync] Cannot handle iCloud recovery: app not initialized',
      );
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
          '[WatchSync] Token recovered from iCloud, reauth flag cleared',
        );
      } else {
        final token = pickActiveToken(
          tokens: initData.tokens,
          settings: initData.settings,
        );
        final expiryDate = token?.expiryDate;
        if (expiryDate != null && expiryDate.isAfter(DateTime.now())) {
          if (initDone) initData.reauthCubit?.clear();
          debugPrint(
            '[WatchSync] Cleared reauth flag after iCloud notification (token is valid)',
          );
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

    if (initData.client.needsReauth) {
      debugPrint('[WatchSync] iPhone needs reauth');
      return {'error': 'needsReauth'};
    }

    if (!_isAccessTokenUsable(token.expiryDate, skew: const Duration())) {
      debugPrint(
        '[WatchSync] Active iPhone token access is expired, forwarding token to Watch for recovery',
      );
    }

    final tokenData = _buildTokenSyncPayload(token, includeSentAt: true);

    debugPrint('[WatchSync] Returning token for Watch');
    return tokenData;
  }

  /// Send a fire-and-forget message to Watch via WatchSessionManager.
  /// Replaces direct watch_connectivity plugin usage to avoid WCSession delegate conflict.
  static Future<void> sendMessageToWatch(Map<String, dynamic> message) async {
    if (!Platform.isIOS) return;
    await _invokeMethodWithTimeout('sendMessageToWatch', message);
  }

  static Future<void> sendTokenToWatch() async {
    if (!Platform.isIOS) return;
    final watchInstalled = await isWatchAppInstalled();
    if (!watchInstalled) return;

    final tokenData = _getTokenForWatch();
    if (tokenData == null) return;

    await _invokeMethodWithTimeout('sendTokenToWatch', tokenData);
    debugPrint('[WatchSync] Token send requested to Watch (async delivery)');
  }

  /// Sends a specific token directly to Watch.
  /// Useful during app initialization before global init state is fully ready.
  static Future<void> sendTokenModelToWatch(
    TokenModel token, {
    bool allowExpiredAccessToken = false,
  }) async {
    if (!Platform.isIOS) return;
    await _sendTokenToWatchInternal(
      token,
      allowExpiredAccessToken: allowExpiredAccessToken,
    );
  }

  static Future<Map<String, dynamic>> _processTokenFromWatch(
    dynamic arguments,
  ) async {
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
      if (!_isAccessTokenUsable(watchExpiryDate, skew: const Duration())) {
        debugPrint(
          '[WatchSync] Rejecting expired token from Watch, expiry: $watchExpiryDate',
        );
        return {'success': false, 'error': 'expired_token'};
      }
      final watchTokenVersion = _resolveIncomingTokenVersion(tokenData);
      final watchUpdatedAtMs = _asInt(tokenData['updatedAtMs']);
      final watchIdToken = tokenData['idToken'] as String?;
      final watchRefreshToken = tokenData['refreshToken'] as String?;

      final isForActiveAccount =
          expectedStudentIdNorm == null ||
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
            '[WatchSync] Ignoring stale token from Watch for active account. Incoming expiry: $watchExpiryDate, incomingVersion: $watchTokenVersion',
          );
          return {'success': false, 'error': 'stale_token'};
        }
      }

      debugPrint(
        '[WatchSync] Accepting token from Watch, expiry: $watchExpiryDate (expired: ${watchExpiryDate.isBefore(DateTime.now())})',
      );

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
        if (initDone) initData.reauthCubit?.clear();
      } else {
        debugPrint(
          '[WatchSync] Stored token for inactive account ($watchStudentIdNorm), active is $expectedStudentIdNorm',
        );
      }

      debugPrint('[WatchSync] Token from Watch saved successfully');
      return {'success': true};
    } catch (e) {
      debugPrint('[WatchSync] Failed to process Watch token: $e');
      return {'success': false, 'error': e.toString()};
    }
  }

  static Future<void> _sendTokenToWatchInternal(
    TokenModel token, {
    bool allowExpiredAccessToken = false,
  }) async {
    if (!Platform.isIOS) return;
    final watchInstalled = await isWatchAppInstalled();
    if (!watchInstalled) {
      debugPrint('[WatchSync] No paired Watch app, skipping token send');
      return;
    }

    if (token.accessToken == null ||
        token.refreshToken == null ||
        token.expiryDate == null) {
      debugPrint('[WatchSync] Token incomplete, not sending to Watch');
      return;
    }

    final accessExpired = !_isAccessTokenUsable(
      token.expiryDate,
      skew: const Duration(),
    );
    if (accessExpired && !allowExpiredAccessToken) {
      debugPrint('[WatchSync] Token expired, not sending to Watch');
      return;
    }
    if (accessExpired && allowExpiredAccessToken) {
      debugPrint(
        '[WatchSync] Sending expired-access token to Watch for account-switch recovery',
      );
    }

    final tokenData = _buildTokenSyncPayload(token, includeSentAt: true);

    await _invokeMethodWithTimeout('sendTokenToWatch', tokenData);
    debugPrint('[WatchSync] iPhone token sent to Watch (or timeout)');
  }

  static String? _getLanguageForWatch() {
    if (!initDone) {
      debugPrint(
        '[WatchSync] App not initialized yet, language unavailable for Watch',
      );
      return null;
    }

    final languageCode = initData.l10n.localeName;
    debugPrint('[WatchSync] Returning language for Watch: $languageCode');
    return languageCode;
  }

  static Future<void> sendLanguageToWatch() async {
    if (!Platform.isIOS) return;
    final watchInstalled = await isWatchAppInstalled();
    if (!watchInstalled) {
      debugPrint('[WatchSync] No paired Watch app, skipping language publish');
      return;
    }

    final languageCode = _getLanguageForWatch();
    if (languageCode == null) return;

    await _invokeMethodWithTimeout('sendLanguageToWatch', languageCode);
    debugPrint(
      '[WatchSync] Language sent to Watch: $languageCode (or timeout)',
    );
  }

  /// Check iCloud for a fresher token and update local storage if found.
  /// This should be called on app startup BEFORE any API calls.
  /// Returns true if a fresher token was found and applied.
  static Future<bool> checkAndRecoverFromiCloud({
    Isar? isar,
    List<TokenModel>? tokens,
    KretaClient? client,
    bool allowExpiredAccessToken = false,
  }) async {
    if (!Platform.isIOS) return false;
    final watchInstalled = await isWatchAppInstalled();
    if (!watchInstalled) {
      return false;
    }

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
        'checkiCloudToken',
        null,
        const Duration(seconds: 5),
      );

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
          '[WatchSync] iCloud token belongs to different account ($iCloudStudentIdNorm), active is $expectedStudentIdNorm - ignoring',
        );
        return false;
      }

      final iCloudExpiry = tokenData['expiryDate'] as int?;
      if (iCloudExpiry == null) {
        debugPrint('[WatchSync] iCloud token has no expiry');
        return false;
      }

      final iCloudExpiryDate = DateTime.fromMillisecondsSinceEpoch(
        iCloudExpiry,
      );
      final iCloudAccessExpired = !_isAccessTokenUsable(
        iCloudExpiryDate,
        skew: const Duration(),
      );
      if (iCloudAccessExpired && !allowExpiredAccessToken) {
        debugPrint(
          '[WatchSync] iCloud token access is expired (expiry: $iCloudExpiryDate), skipping direct apply',
        );
        return false;
      }
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
          '[WatchSync] iCloud has fresher token! iCloud: $iCloudExpiryDate, Local: $localExpiry, iCloudVersion: $iCloudTokenVersion',
        );

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

        final shouldClearReauth =
            !iCloudAccessExpired &&
            (expectedStudentIdNorm == null ||
                newToken.studentIdNorm == expectedStudentIdNorm);
        if (shouldClearReauth) {
          if (initDone) initData.reauthCubit?.clear();
        }

        debugPrint(
          '[WatchSync] Token recovered from iCloud! New expiry: $iCloudExpiryDate',
        );
        return true;
      } else {
        debugPrint(
          '[WatchSync] Local token is same or fresher. Local: $localExpiry, iCloud: $iCloudExpiryDate',
        );
        return false;
      }
    } catch (e) {
      debugPrint('[WatchSync] Failed to check iCloud: $e');
      return false;
    }
  }

  /// Save token to iCloud. Call this after refreshing token on iPhone.
  static Future<void> saveTokenToiCloud(
    TokenModel token, {
    bool forceAccountSwitch = false,
  }) async {
    if (!Platform.isIOS) return;

    if (token.accessToken == null ||
        token.refreshToken == null ||
        token.expiryDate == null) {
      debugPrint('[WatchSync] Token incomplete, not saving to iCloud');
      return;
    }

    final watchInstalled = await isWatchAppInstalled();
    if (!watchInstalled) {
      debugPrint(
        '[WatchSync] Skipping iCloud token save because no paired Watch app is installed',
      );
      return;
    }

    final tokenData = _buildTokenSyncPayload(token);
    tokenData['forceAccountSwitch'] = forceAccountSwitch;

    await _invokeMethodWithTimeout(
      'saveTokeToniCloud',
      tokenData,
      const Duration(seconds: 5),
    );
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
        'requestTokenFromWatch',
        null,
        const Duration(seconds: 10),
      );
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
            !(initData.reauthCubit?.state.needsReauth ?? false)) {
          debugPrint('[WatchSync] Sending iPhone token to Watch (no response)');
          await _sendTokenToWatchInternal(
            currentToken,
            allowExpiredAccessToken: true,
          );
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
            !(initData.reauthCubit?.state.needsReauth ?? false)) {
          debugPrint(
            '[WatchSync] Sending iPhone token to Watch (Watch has no token)',
          );
          await _sendTokenToWatchInternal(
            currentToken,
            allowExpiredAccessToken: true,
          );
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
          '[WatchSync] Watch token belongs to different account ($watchStudentIdNorm), active is $expectedStudentIdNorm - keeping active account',
        );
        if (currentToken != null &&
            currentToken.accessToken != null &&
            currentToken.refreshToken != null &&
            currentToken.expiryDate != null &&
            !(initData.reauthCubit?.state.needsReauth ?? false)) {
          await _sendTokenToWatchInternal(
            currentToken,
            allowExpiredAccessToken: true,
          );
        }
        return;
      }

      final watchExpiryDate = DateTime.fromMillisecondsSinceEpoch(watchExpiry);
      if (!_isAccessTokenUsable(watchExpiryDate, skew: const Duration())) {
        debugPrint(
          '[WatchSync] Watch provided expired token, ignoring and keeping iPhone token',
        );
        if (currentToken != null &&
            currentToken.accessToken != null &&
            currentToken.refreshToken != null &&
            currentToken.expiryDate != null &&
            _isAccessTokenUsable(
              currentToken.expiryDate,
              skew: const Duration(),
            ) &&
            !(initData.reauthCubit?.state.needsReauth ?? false)) {
          await _sendTokenToWatchInternal(
            currentToken,
            allowExpiredAccessToken: true,
          );
        }
        return;
      }
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
          if (initDone) initData.reauthCubit?.clear();
        }

        debugPrint(
          '[WatchSync] Token updated from Watch. New expiry: $watchExpiryDate',
        );
      } else {
        debugPrint(
          '[WatchSync] iPhone token is same or newer, sending to Watch',
        );
        await _sendTokenToWatchInternal(
          currentToken,
          allowExpiredAccessToken: true,
        );
      }
    } catch (e) {
      debugPrint('[WatchSync] Failed to sync token from Watch: $e');
    }
  }
}
