import 'dart:async';
import 'dart:io';

import 'package:firka/data/models/app_settings_model.dart';
import 'package:firka/services/live_activity_service.dart';
import 'package:firka/app/app_state.dart';
import 'package:firka/app/initialization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:isar_community/isar.dart';
import 'package:majesticons_flutter/majesticons_flutter.dart';
import 'package:webview_flutter/webview_flutter.dart';

import 'package:firka/services/watch_sync_helper.dart';
import 'package:firka/api/consts.dart';
import 'package:firka/api/token_grant.dart';
import 'package:firka/data/models/token_model.dart';
import 'package:firka/core/state/firka_state.dart';
import 'package:firka/core/settings.dart';
import 'package:firka/ui/theme/style.dart';

class LoginWebviewWidget extends StatefulWidget {
  final AppInitialization data;
  final String? username;
  final String? schoolId;

  const LoginWebviewWidget(
    this.data, {
    super.key,
    this.username,
    this.schoolId,
  });

  @override
  State<LoginWebviewWidget> createState() => _LoginWebviewWidgetState();
}

class _LoginWebviewWidgetState extends FirkaState<LoginWebviewWidget>
    with TickerProviderStateMixin {
  late WebViewController _webViewController;
  bool _isLoading = true;
  AnimationController? _fadeAnimationController;
  Animation<double>? _fadeAnimation;

  @override
  void initState() {
    super.initState();

    _fadeAnimationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 1.0,
      end: 0.0,
    ).animate(_fadeAnimationController!);

    var loginUrl = KretaEndpoints.kretaLoginUrl;

    if (widget.username != null && widget.schoolId != null) {
      loginUrl = KretaEndpoints.kretaLoginUrlRefresh(
        widget.username!,
        widget.schoolId!,
      );
    }

    logger.info("Using loginUrl: $loginUrl");

    _webViewController = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..loadRequest(Uri.parse(loginUrl))
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (String url) {
            Timer(const Duration(milliseconds: 500), () {
              if (mounted) {
                setState(() {
                  _isLoading = false;
                });
                _fadeAnimationController?.forward().then((_) {
                  _fadeAnimationController?.reset();
                });
              }
            });
          },
          onPageStarted: (String url) {
            setState(() {
              _isLoading = true;
            });
            _fadeAnimationController?.reset();
          },
          onNavigationRequest: (NavigationRequest request) async {
            var uri = Uri.parse(request.url);

            if (uri.path == "/ellenorzo-student/prod/oauthredirect") {
              var code = uri.queryParameters["code"]!;

              try {
                var isar = widget.data.isar;
                var resp = await getAccessToken(code);

                logger.info("getAccessToken(): $resp");

                var tokenModel = TokenModel.fromResp(resp);

                final accountPicker =
                    (widget.data.settings.group(
                          "profile_settings",
                        )["e_kreta_account_picker"]
                        as SettingsKretenAccountPicker);

                var tokenId = 0;
                var om = 0;
                await isar.writeTxn(() async {
                  om = await isar.tokenModels.put(tokenModel);
                });

                widget.data.tokens = await isar.tokenModels.where().findAll();
                for (var i = 0; i < widget.data.tokens.length; i++) {
                  if (widget.data.tokens[i].studentIdNorm == om) {
                    tokenId = i;
                    break;
                  }
                }

                await isar.writeTxn(() async {
                  accountPicker.accountIndex = tokenId;
                  await accountPicker.save(widget.data.isar.appSettingsModels);
                });

                await accountPicker.postUpdate();

                if (Platform.isIOS) {
                  final watchInstalled =
                      await WatchSyncHelper.isWatchAppInstalled();
                  if (watchInstalled) {
                    try {
                      await WatchSyncHelper.saveTokenToiCloud(tokenModel);
                    } catch (_) {}

                    try {
                      await WatchSyncHelper.sendTokenToWatch();
                    } catch (_) {
                      // Watch may be unavailable, ignore
                    }
                  }
                }

                if (!mounted) return NavigationDecision.prevent;

                widget.data.reauthCubit?.clear();
                if (Platform.isIOS) {
                  LiveActivityService.clearTokenExpiration();
                }

                await initializeApp();

                if (!mounted) return NavigationDecision.prevent;

                if (mounted) {
                  Navigator.of(context).pop();
                  appRouter?.go('/home');
                }
              } catch (ex) {
                if (ex is Error) {
                  logger.shout(
                    "oauthredirect failed:",
                    ex.toString(),
                    ex.stackTrace,
                  );
                } else {
                  logger.shout("oauthredirect failed:", ex.toString());
                }
                appRouter?.go('/error', extra: ex.toString());
              }

              return NavigationDecision.prevent;
            }

            return NavigationDecision.navigate;
          },
        ),
      );
  }

  @override
  void dispose() {
    _fadeAnimationController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final safePadding = mediaQuery.padding;

    return Material(
      color: appStyle.colors.background, //why was this card? :sob:
      child: Padding(
        padding: EdgeInsets.only(
          top: 61 + safePadding.top,
          left: 12,
          right: 12,
          bottom: safePadding.bottom,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Padding(
                  padding: const EdgeInsets.only(left: 2),
                  child: SvgPicture.asset(
                    "assets/icons/dave.svg",
                    width: 24,
                    height: 24,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    widget.data.l10n.runningInDomainBrowser,
                    style: appStyle.fonts.B_16R.copyWith(
                      color: appStyle.colors.textPrimary,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () => Navigator.of(context).pop(),
                  child: Container(
                    width: 36,
                    height: 36,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: appStyle.colors.buttonSecondaryFill,
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                          color: appStyle.colors.shadowColor,
                          offset: const Offset(0, 1),
                          blurRadius: appStyle.colors.shadowBlur.toDouble(),
                        ),
                      ],
                    ),
                    child: Majesticon(
                      Majesticon.multiplySolid,
                      color: appStyle.colors.accent,
                      size: 16,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 22),
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Stack(
                  children: [
                    WebViewWidget(controller: _webViewController),
                    if (_fadeAnimationController != null &&
                        _fadeAnimation != null)
                      IgnorePointer(
                        ignoring: !_isLoading,
                        child: AnimatedBuilder(
                          animation: _fadeAnimationController!,
                          builder: (context, child) => AnimatedOpacity(
                            opacity: _isLoading
                                ? 1.0
                                : _fadeAnimationController!.isAnimating
                                ? _fadeAnimation!.value
                                : 0.0,
                            duration: const Duration(milliseconds: 500),
                            child: Container(
                              color: appStyle.colors.background,
                              child: Center(
                                child: Image.asset(
                                  "assets/images/logos/loading.gif",
                                  width: 50,
                                  height: 50,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Container(
                    height: 42,
                    decoration: BoxDecoration(
                      color: appStyle.colors.card,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Row(
                        children: [
                          Text(
                            "eKréta/Bejelentkezés",
                            style: appStyle.fonts.B_14R.copyWith(
                              fontSize: 16,
                              color: appStyle.colors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: appStyle.colors.buttonSecondaryFill,
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(
                        color: appStyle.colors.shadowColor,
                        offset: const Offset(0, 1),
                        blurRadius: appStyle.colors.shadowBlur.toDouble(),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Image.asset(
                      "assets/icons/button/colorwheel.png",
                      width: 22,
                      height: 22,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: appStyle.colors.buttonSecondaryFill,
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(
                        color: appStyle.colors.shadowColor,
                        offset: const Offset(0, 1),
                        blurRadius: appStyle.colors.shadowBlur.toDouble(),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Majesticon(
                      Majesticon.chevronLeftLine,
                      color: appStyle.colors.secondary,
                      size: 22,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: appStyle.colors.buttonSecondaryFill,
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(
                        color: appStyle.colors.shadowColor,
                        offset: const Offset(0, 1),
                        blurRadius: appStyle.colors.shadowBlur.toDouble(),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Majesticon(
                      Majesticon.menuLine,
                      color: appStyle.colors.secondary,
                      size: 22,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
