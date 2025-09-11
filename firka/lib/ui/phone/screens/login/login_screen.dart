import 'dart:math' as math;

import 'package:carousel_slider/carousel_slider.dart';
import 'package:firka/helpers/firka_bundle.dart';
import 'package:firka/main.dart';
import 'package:firka/ui/phone/widgets/login_webview.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../helpers/firka_state.dart';
import '../../../../helpers/image_preloader.dart';
import '../../../model/style.dart';
import '../../../widget/delayed_spinner.dart';

class LoginScreen extends StatefulWidget {
  final AppInitialization data;

  const LoginScreen(this.data, {super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends FirkaState<LoginScreen> {
  late LoginWebviewWidget _loginWebView;
  bool _preloadDone = false;

  @override
  void initState() {
    super.initState();

    _loginWebView = LoginWebviewWidget(widget.data);

    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

    _preloadImages();
  }

  Future<void> _preloadImages() async {
    final imagePaths = [
      "assets/images/carousel/slide1.webp",
      "assets/images/carousel/slide2.webp",
      "assets/images/carousel/slide3.webp",
      "assets/images/carousel/slide4.webp",
      "assets/images/carousel_dark/slide1.webp",
      "assets/images/carousel_dark/slide2.webp",
      "assets/images/carousel_dark/slide3.webp",
      "assets/images/carousel_dark/slide4.webp",
      "assets/images/logos/colored_logo.webp",
    ];

    try {
      await ImagePreloader.preloadMultipleAssets(FirkaBundle(), imagePaths);

      setState(() {
        _preloadDone = true;
      });
    } catch (e) {
      debugPrint('Error preloading images: $e');
      setState(() {
        _preloadDone = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_preloadDone) {
      return MaterialApp(
        home: Scaffold(
          backgroundColor: appStyle.colors.background,
          body: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              SizedBox(),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [SizedBox(), DelayedSpinnerWidget(), SizedBox()],
              ),
              SizedBox(),
            ],
          ),
        ),
      );
    }

    final carousel = isLightMode.value ? "carousel" : "carousel_dark";

    final paddingWidthHorizontal = MediaQuery.of(context).size.width -
        MediaQuery.of(context).size.width * 0.95;
    List<Map<String, Object>> slides = [
      {
        'title': widget.data.l10n.title1,
        'subtitle': widget.data.l10n.subtitle1,
        'picture': 'assets/images/$carousel/slide1.webp',
        'background': 'assets/images/carousel/slide1_background.webp',
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
        'picture': 'assets/images/$carousel/slide2.webp',
        'background': 'assets/images/carousel/slide2_background.webp',
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
        'picture': 'assets/images/$carousel/slide3.webp',
        'background': '',
        'foreground': 'assets/images/carousel/slide3_foreground.webp',
        'rotation': 180.0,
        'scale': 0.8,
        'x': 0.00,
        'y': 25.00,
      },
      {
        'title': widget.data.l10n.title4,
        'subtitle': widget.data.l10n.subtitle4,
        'picture': 'assets/images/$carousel/slide4.webp',
        'background': 'assets/images/carousel/slide4_background.webp',
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
                            image: PreloadedImageProvider(
                                DefaultAssetBundle.of(context),
                                'assets/images/logos/colored_logo.webp'),
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
                                              child: Image.asset(
                                                slides[index]['background']!
                                                    as String,
                                                bundle: DefaultAssetBundle.of(
                                                    context),
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
                                      image: PreloadedImageProvider(
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
                                              child: Image.asset(
                                                slides[index]['foreground']!
                                                    as String,
                                                bundle: DefaultAssetBundle.of(
                                                    context),
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
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        appStyle.colors.background.withAlpha(0),
                        appStyle.colors.background,
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
                              return _loginWebView;
                            },
                          );
                        },
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          width: double.infinity,
                          height: 48,
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          decoration: ShapeDecoration(
                            color: appStyle.colors.accent,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            shadows: [
                              BoxShadow(
                                color:
                                    appStyle.colors.textPrimary.withAlpha(13),
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
                                  color: appStyle.colors.textPrimaryLight,
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
