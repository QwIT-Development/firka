import 'dart:async';

import 'package:firka/helpers/db/models/app_settings_model.dart';
import 'package:firka/main.dart';
import 'package:flutter/material.dart';
import 'package:isar/isar.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../../../helpers/api/consts.dart';
import '../../../helpers/api/token_grant.dart';
import '../../../helpers/db/models/token_model.dart';
import '../../../helpers/firka_bundle.dart';
import '../../../helpers/firka_state.dart';
import '../../../helpers/settings.dart';
import '../../../ui/model/style.dart';
import '../pages/error/error_page.dart';

class LoginWebviewWidget extends StatefulWidget {
  final AppInitialization data;
  final String? username;
  final String? schoolId;

  const LoginWebviewWidget(this.data,
      {super.key, this.username, this.schoolId});

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

    _fadeAnimation =
        Tween<double>(begin: 1.0, end: 0.0).animate(_fadeAnimationController!);

    var loginUrl = KretaEndpoints.kretaLoginUrl;

    if (widget.username != null && widget.schoolId != null) {
      loginUrl = KretaEndpoints.kretaLoginUrlRefresh(
          widget.username!, widget.schoolId!);
    }

    logger.info("Using loginUrl: $loginUrl");

    _webViewController = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..loadRequest(Uri.parse(loginUrl))
      ..setNavigationDelegate(NavigationDelegate(
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

            final accountPicker = (widget.data.settings
                    .group("profile_settings")["e_kreta_account_picker"]
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

            if (!mounted) return NavigationDecision.prevent;

            runApp(InitializationScreen());
          } catch (ex) {
            if (ex is Error) {
              logger.shout(
                  "oauthredirect failed:", ex.toString(), ex.stackTrace);
            } else {
              logger.shout("oauthredirect failed:", ex.toString());
            }
            Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => DefaultAssetBundle(
                        bundle: FirkaBundle(),
                        child: ErrorPage(
                          exception: ex.toString(),
                        ))));
          }

          return NavigationDecision.prevent;
        }

        return NavigationDecision.navigate;
      }));
  }

  @override
  void dispose() {
    _fadeAnimationController?.dispose();
    super.dispose();
  }


  @override
  Widget build(BuildContext context) {
    return Material(
      color: appStyle.colors.card,
      child: Padding(
        padding:
            EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: FractionallySizedBox(
          heightFactor: 0.90,
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              mainAxisSize: MainAxisSize.max,
              children: <Widget>[
                Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      child: Container(
                        decoration: BoxDecoration(
                          color: appStyle.colors.secondary.withValues(alpha: 0.5),
                          borderRadius: BorderRadius.all(Radius.circular(2)),
                        ),
                        width: 40,
                        height: 4,
                      ),
                    ),
                  ],
                ),
                Container(
                  height: MediaQuery.of(context).size.height * 0.8,
                  // Adjust height for content
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  // Add ClipRRect for circular edges
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: Stack(
                      children: [
                        WebViewWidget(
                          controller: _webViewController,
                        ),
                        if (_fadeAnimationController != null && _fadeAnimation != null)
                          AnimatedBuilder(
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
                                  child: SizedBox(
                                    width: 32,
                                    height: 32,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 3,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        appStyle.colors.accent,
                                      ),
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
              ],
            ),
          ),
        ),
      ),
    );
  }
}
