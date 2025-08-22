import 'dart:math' as math;

import 'package:carousel_slider/carousel_slider.dart';
import 'package:firka/helpers/api/client/kreta_client.dart';
import 'package:firka/helpers/api/consts.dart';
import 'package:firka/helpers/db/models/token_model.dart';
import 'package:firka/helpers/firka_bundle.dart';
import 'package:firka/main.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../../../../helpers/api/token_grant.dart';
import '../../../../helpers/cache_memory_image_provider.dart';
import '../../../model/style.dart';
import '../home/home_screen.dart';

class LoginScreen extends StatefulWidget {
  final AppInitialization data;

  const LoginScreen(this.data, {super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  late WebViewController _webViewController;

  bool _preloadDone = false;

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
            var isar = widget.data.isar;
            var resp = await getAccessToken(code);

            if (kDebugMode) {
              print("getAccessToken(): $resp");
            }

            var tokenModel = TokenModel.fromResp(resp);

            await isar.writeTxn(() async {
              await isar.tokenModels.put(tokenModel);
            });

            widget.data.client = KretaClient(tokenModel, isar);
            widget.data.tokenCount = await isar.tokenModels.count();

            if (!mounted) return NavigationDecision.prevent;

            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(builder: (context) => HomeScreen(widget.data)),
              (route) => false, // Remove all previous routes
            );
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
      systemNavigationBarColor: Color(0xFFFAFFF0),
    ));

    () async {
      final firkaBundle = FirkaBundle();

      await precacheAssets(firkaBundle, [
        "assets/images/carousel/slide1.png",
        "assets/images/carousel/slide1_background.gif",
        "assets/images/carousel/slide2.png",
        "assets/images/carousel/slide2_background.gif",
        "assets/images/carousel/slide3.png",
        "assets/images/carousel/slide3_foreground.gif",
        "assets/images/carousel/slide4.png",
        "assets/images/carousel/slide4_background.gif"
      ]);

      setState(() {
        _preloadDone = true;
      });
    }();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_preloadDone) {
      return MaterialApp(
      home: SizedBox(),
    );
    }

    final paddingWidthHorizontal = MediaQuery.of(context).size.width -
        MediaQuery.of(context).size.width * 0.95;
    List<Map<String, Object>> slides = [
      {
        'title': widget.data.l10n.title1,
        'subtitle': widget.data.l10n.subtitle1,
        'picture': 'assets/images/carousel/slide1.png',
        'background': 'assets/images/carousel/slide1_background.gif',
        'foreground': '',
        'rotation': 180.00,
        // „Mi nekünk két szám típusunk van, int (egy 32 bites szám) meg a double (egy 64 bites tört szám), KURVA ANYÁDAT”
        'scale': 1.5,
        'x': 0.00,
        'y': 150.00,
      },
      {
        'title': widget.data.l10n.title2,
        'subtitle': widget.data.l10n.subtitle2,
        'picture': 'assets/images/carousel/slide2.png',
        'background': 'assets/images/carousel/slide2_background.gif',
        'foreground': '',
        'rotation': 180.00,
        //Mivel radiáns, és nullával nem lehet osztani (remélem tudtad), ezért ha eggyel osztunk akkor egy marad
        'scale': 1.55,
        'x': 10.00,
        'y': 160.00,
      },
      {
        'title': widget.data.l10n.title3,
        'subtitle': widget.data.l10n.subtitle3,
        'picture': 'assets/images/carousel/slide3.png',
        'background': '',
        'foreground': 'assets/images/carousel/slide3_foreground.gif',
        'rotation': 180.0,
        'scale': 0.8,
        'x': 0.00,
        'y': 25.00,
      },
      {
        'title': widget.data.l10n.title4,
        'subtitle': widget.data.l10n.subtitle4,
        'picture': 'assets/images/carousel/slide4.png',
        'background': 'assets/images/carousel/slide4_background.gif',
        'foreground': '',
        'rotation': 180.00,
        'scale': 1.35,
        'x': -5.00,
        'y': 80.00,
      }
      //TODO: implement simulated physics so that the little boxes can move like the phone moves
    ];

    return MaterialApp(
      home: Scaffold(
        backgroundColor: appStyle.colors.background,
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
                          image: DecorationImage(
                            image: CacheMemoryImageProvider(
                                DefaultAssetBundle.of(context),
                                'assets/images/logos/colored_logo.png'),
                            fit: BoxFit.cover,
                          ),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Firka Napló',
                        style: appStyle.fonts.H_18px
                            .copyWith(color: appStyle.colors.textPrimary),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: CarouselSlider.builder(
                    itemCount: slides.length,
                    itemBuilder: (context, index, realIndex) => Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        Padding(
                          padding: EdgeInsetsGeometry.symmetric(
                              horizontal: paddingWidthHorizontal),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: [
                              Text(
                                slides[index]['title']! as String,
                                style: appStyle.fonts.H_18px.copyWith(
                                    color: appStyle.colors.textPrimary),
                                softWrap: true,
                                overflow: TextOverflow.visible,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                slides[index]['subtitle']! as String,
                                style: appStyle.fonts.B_14R.copyWith(
                                    color: appStyle.colors.textPrimary),
                                softWrap: true,
                                overflow: TextOverflow.visible,
                              ),
                            ],
                          ),
                        ),
                        Stack(
                          children: [
                            slides[index]['background']! == ''
                                ? SizedBox()
                                : ClipRect(
                                    clipper:
                                        ImageClipper(MediaQuery.of(context)),
                                    child: Transform.rotate(
                                      angle: -math.pi /
                                          (slides[index]['rotation']!
                                              as double),
                                      child: Transform.translate(
                                        offset: Offset(
                                            slides[index]['x'] as double,
                                            slides[index]['y'] as double),
                                        child: SizedBox(
                                          width:
                                              MediaQuery.of(context).size.width,
                                          child: Transform.scale(
                                              scale: slides[index]['scale']
                                                  as double,
                                              child: Image(
                                                image: CacheMemoryImageProvider(
                                                    DefaultAssetBundle.of(
                                                        context),
                                                    slides[index]['background']!
                                                        as String),
                                                fit: BoxFit.contain,
                                                width: double.infinity,
                                              )),
                                        ),
                                      ),
                                    )),
                            Column(
                              children: [
                                SizedBox(height: 73),
                                Padding(
                                  padding: EdgeInsetsGeometry.symmetric(
                                      horizontal: 18),
                                  child: SizedBox(
                                    width: MediaQuery.of(context).size.width,
                                    child: Image(
                                      image: CacheMemoryImageProvider(
                                          DefaultAssetBundle.of(context),
                                          slides[index]['picture']! as String),
                                      fit: BoxFit.cover,
                                      width: double.infinity,
                                      alignment: Alignment.center,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            slides[index]['foreground']! == ''
                                ? SizedBox()
                                : SizedBox(
                                    width: MediaQuery.of(context).size.width,
                                    child: ClipRect(
                                      clipBehavior: Clip.none,
                                      child: Transform.rotate(
                                          angle: -math.pi /
                                              (slides[index]['rotation']!
                                                  as double),
                                          child: Transform.translate(
                                            offset: Offset(
                                                slides[index]['x'] as double,
                                                slides[index]['y'] as double),
                                            child: Transform.scale(
                                              scale: slides[index]['scale']
                                                  as double,
                                              child: Image(
                                                image: CacheMemoryImageProvider(
                                                    DefaultAssetBundle.of(
                                                        context),
                                                    slides[index]['foreground']!
                                                        as String),
                                                fit: BoxFit.cover,
                                                width: MediaQuery.of(context)
                                                    .size
                                                    .width,
                                                alignment: Alignment.center,
                                              ),
                                            ),
                                          )),
                                    ),
                                  ),
                          ],
                        )
                      ],
                    ),
                    options: CarouselOptions(
                      height: double.infinity,
                      autoPlay: false,
                      autoPlayInterval: const Duration(milliseconds: 3000),
                      viewportFraction: 1.0,
                      enableInfiniteScroll: true,
                    ),
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
                        Color(0x00FAFFF0),
                        Color(0xFFFAFFF0)
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
                          child: Center(
                            child: Text(
                              widget.data.l10n.loginBtn,
                              textAlign: TextAlign.center,
                              style: appStyle.fonts.H_16px.copyWith(
                                  color: appStyle.colors.textPrimary,
                                  fontVariations: [FontVariation("wght", 800)]),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  GestureDetector(
                    child: Text(
                      widget.data.l10n.privacyLabel,
                      textAlign: TextAlign.center,
                      style: appStyle.fonts.H_12px
                          .copyWith(color: appStyle.colors.textTertiary),
                    ),
                    onTap: () {},
                  )
                ],
              ),
            ),
          ],
        )),
      ),
    );
  }
}

// this sucks :3
class ImageClipper extends CustomClipper<Rect> {
  final MediaQueryData _mediaQuery;

  ImageClipper(this._mediaQuery);

  @override
  Rect getClip(Size size) {
    return Rect.fromLTWH(
        0, -70, _mediaQuery.size.width, _mediaQuery.size.height);
  }

  @override
  bool shouldReclip(covariant CustomClipper<Rect> oldClipper) {
    return false;
  }
}
