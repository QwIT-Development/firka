import 'package:firka/helpers/api/consts.dart';
import 'package:firka/helpers/db/models/token_model.dart';
import 'package:firka/main.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:watch_connectivity/watch_connectivity.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../../../../helpers/api/token_grant.dart';
import '../home/home_screen.dart';
import '../login/login_screen.dart';

class WearLoginScreen extends StatefulWidget {
  final AppInitialization data;

  const WearLoginScreen(this.data, {super.key});

  @override
  State<WearLoginScreen> createState() => _WearLoginScreenState(data);
}

class _WearLoginScreenState extends State<WearLoginScreen> {
  late WebViewController _webViewController;
  final AppInitialization data;

  _WearLoginScreenState(this.data);

  final watch = WatchConnectivity();

  @override
  void initState() {
    super.initState();

    _webViewController = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..loadRequest(Uri.parse(KretaEndpoints.kretaLoginUrl))
      ..setNavigationDelegate(NavigationDelegate(
          onNavigationRequest: (NavigationRequest request) async {
        var uri = Uri.parse(request.url);

        if (uri.path == "/ellenorzo-student/prod/oauthredirect") {
          if (kDebugMode) {
            print("query params: ${uri.queryParameters}");
          }

          var code = uri.queryParameters["code"]!;

          try {
            var resp = await getAccessToken(code);

            if (kDebugMode) {
              print("getAccessToken(): $resp");
            }

            var tokenModel = TokenModel.fromResp(resp);

            debugPrint("[Phone -> Watch]: auth");
            watch.sendMessage({
              "id": "auth",
              "data": {
                "studentId": tokenModel.studentId,
                "iss": tokenModel.iss,
                "idToken": tokenModel.idToken,
                "accessToken": tokenModel.accessToken,
                "refreshToken": tokenModel.refreshToken,
                "expiryDate": tokenModel.expiryDate!.millisecondsSinceEpoch
              }
            });

            if (!mounted) return NavigationDecision.prevent;

            if (widget.data.tokenCount > 0) {
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(
                    builder: (context) => HomeScreen(widget.data)),
                (route) => false, // Remove all previous routes
              );
            } else {
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(
                    builder: (context) => LoginScreen(widget.data)),
                (route) => false, // Remove all previous routes
              );
            }
          } catch (ex) {
            if (kDebugMode) {
              print("oauthredirect failed: $ex");
            }
            // TODO: display an error popup
          }

          return NavigationDecision.prevent;
        }

        return NavigationDecision.navigate;
      }));

    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarBrightness: Brightness.light,
      statusBarIconBrightness: Brightness.dark,
      statusBarColor: Colors.transparent,
      systemNavigationBarColor: Color(0xFFDAE4F7),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final paddingWidthHorizontal = MediaQuery.of(context).size.width -
        MediaQuery.of(context).size.width * 0.95;

    return MaterialApp(
      home: Scaffold(
        backgroundColor: const Color(0xFFFAFFEF),
        body: SafeArea(
            child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 16),
                Padding(
                  padding: EdgeInsets.only(left: paddingWidthHorizontal),
                  child: Row(
                    children: [
                      Container(
                        width: 30,
                        height: 30,
                        clipBehavior: Clip.antiAlias,
                        decoration: ShapeDecoration(
                          image: const DecorationImage(
                            image: AssetImage(
                                'assets/images/logos/colored_logo.png'),
                            fit: BoxFit.cover,
                          ),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(6)),
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'Firka',
                        style: TextStyle(
                          color: Color(0xFF394B0A),
                          fontSize: 17,
                          fontFamily: 'Montserrat',
                          fontVariations: [
                            FontVariation('wght', 700),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: EdgeInsets.only(top: 16, left: 16),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        'Placeholder :3',
                        style: TextStyle(
                          color: Color(0xFF394B0A),
                          fontSize: 24,
                          fontFamily: 'Montserrat',
                          fontVariations: [
                            FontVariation('wght', 700),
                          ],
                        ),
                      )
                    ],
                  ),
                ),
              ],
            ),
            Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Container(
                  width: double.infinity,
                  height: 200,
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Color(0x00DAE4F7),
                        Color(0xFFDAE4F7)
                      ], // customize colors
                      stops: [0.0, 0.5], // percentages (0% → 50% → 100%)
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                )
              ],
            ),
            Positioned(
              bottom: 10,
              left: 0,
              right: 0,
              child: Column(
                children: [
                  Center(
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                          horizontal: paddingWidthHorizontal),
                      child: InkWell(
                        onTap: () {
                          showModalBottomSheet<void>(
                            context: context,
                            isScrollControlled: true,
                            builder: (BuildContext context) {
                              return Padding(
                                padding: EdgeInsets.only(
                                    bottom: MediaQuery.of(context)
                                        .viewInsets
                                        .bottom),
                                child: FractionallySizedBox(
                                  heightFactor: 0.90,
                                  child: Center(
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.start,
                                      mainAxisSize: MainAxisSize.max,
                                      children: <Widget>[
                                        Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.center,
                                          mainAxisAlignment:
                                              MainAxisAlignment.start,
                                          children: [
                                            Padding(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      vertical: 16),
                                              child: Container(
                                                decoration: const BoxDecoration(
                                                  color: Color(0xFFB9C8E5),
                                                  borderRadius:
                                                      BorderRadius.all(
                                                          Radius.circular(2)),
                                                ),
                                                width: 40,
                                                height: 4,
                                              ),
                                            ),
                                          ],
                                        ),
                                        Container(
                                          height: MediaQuery.of(context)
                                                  .size
                                                  .height *
                                              0.8,
                                          // Adjust height for content
                                          margin: const EdgeInsets.symmetric(
                                              horizontal: 16),
                                          // Add ClipRRect for circular edges
                                          child: ClipRRect(
                                            borderRadius:
                                                BorderRadius.circular(20),
                                            child: WebViewWidget(
                                              controller: _webViewController,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            },
                          );
                        },
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          width: double.infinity,
                          height: 48,
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          decoration: ShapeDecoration(
                            color: const Color(0xFFA7DB21), // Accent-Accent
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            shadows: const [
                              BoxShadow(
                                color: Color(0x33647E22),
                                blurRadius: 2,
                                offset: Offset(0, 1),
                                spreadRadius: 0,
                              )
                            ],
                          ),
                          child: const Center(
                            child: Text(
                              'Bejelentkezés E-Kréta fiókkal',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Color(0xFF394B0A),
                                // Text-Primary
                                fontSize: 17,
                                fontFamily: 'Montserrat',
                                fontVariations: [
                                  FontVariation('wght', 700),
                                ],
                                letterSpacing: -0.30,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Adatvédelmi tájékoztató',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Color(0x7F394C0A) /* Text-Teritary */,
                      fontSize: 14,
                      fontFamily: 'Montserrat',
                      fontVariations: [
                        FontVariation('wght', 500),
                      ],
                      height: 1.30,
                    ),
                  ),
                ],
              ),
            ),
          ],
        )),
      ),
    );
  }
}
