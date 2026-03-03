import 'dart:async';
import 'dart:math' as math;

import 'package:carousel_slider/carousel_slider.dart';
import 'package:firka/core/firka_bundle.dart';
import 'package:firka/app/app_state.dart';
import 'package:firka/ui/phone/widgets/login_webview.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:vibration/vibration.dart';

import 'package:firka/core/bloc/theme_cubit.dart';
import 'package:firka/core/state/firka_state.dart';
import 'package:firka/core/image_preloader.dart';
import 'package:firka/ui/theme/style.dart';
import 'package:firka/ui/shared/delayed_spinner.dart';

const String _privacyUrlHungarian =
    'https://github.com/QwIT-Development/privacy-policy/blob/master/README.md';
const String _privacyUrlOther = 'https://firka.app/privacy';

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

  String _getPrivacyPolicyUrl() {
    final locale = Localizations.localeOf(context).languageCode;
    return locale == 'hu' ? _privacyUrlHungarian : _privacyUrlOther;
  }

  Future<void> _launchPrivacyPolicy() async {
    final url = _getPrivacyPolicyUrl();
    try {
      await launchUrl(Uri.parse(url));
    } catch (e) {
      logger.shout('LoginScreen: Error launching privacy policy URL: $e');
    }
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
      logger.shout('LoginScreen: Error preloading images: $e');
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

    final carousel = context.watch<ThemeCubit>().state.isLightMode
        ? "carousel"
        : "carousel_dark";

    final paddingWidthHorizontal =
        MediaQuery.of(context).size.width -
        MediaQuery.of(context).size.width * 0.95;

    List<Map<String, Object>> slides = [
      {
        'title': widget.data.l10n.title1,
        'subtitle': widget.data.l10n.subtitle1,
        'picture': 'assets/images/$carousel/slide1.webp',
        'background': 'assets/images/carousel/slide1_background.webp',
        'foreground': '',
        'rotation': 180.00,
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
        'picture': '',
        'background': 'assets/images/carousel/slide4_background.webp',
        'foreground': '',
        'rotation': 180.00,
        'scale': 1.35,
        'x': -5.00,
        'y': 80.00,
        'cards': true,
      },
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
                                'assets/images/logos/colored_logo.webp',
                              ),
                              fit: BoxFit.cover,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Firka Napló',
                          style: appStyle.fonts.H_18px.copyWith(
                            color: appStyle.colors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: CarouselSlider.builder(
                      itemCount: slides.length,
                      itemBuilder: (context, index, realIndex) {
                        final isCards = slides[index]['cards'] == true;

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            Padding(
                              padding: EdgeInsetsGeometry.symmetric(
                                horizontal: paddingWidthHorizontal,
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.start,
                                children: [
                                  Text(
                                    slides[index]['title']! as String,
                                    style: appStyle.fonts.H_18px.copyWith(
                                      color: appStyle.colors.textPrimary,
                                    ),
                                    softWrap: true,
                                    overflow: TextOverflow.visible,
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    slides[index]['subtitle']! as String,
                                    style: appStyle.fonts.B_16R.copyWith(
                                      color: appStyle.colors.textPrimary,
                                    ),
                                    softWrap: true,
                                    overflow: TextOverflow.visible,
                                  ),
                                ],
                              ),
                            ),
                            if (isCards)
                              Expanded(
                                child: Stack(
                                  children: [
                                    if ((slides[index]['background'] ?? '')
                                        .toString()
                                        .isNotEmpty)
                                      ClipRect(
                                        clipper: ImageClipper(
                                          MediaQuery.of(context),
                                        ),
                                        child: Transform.rotate(
                                          angle:
                                              -math.pi /
                                              (slides[index]['rotation']!
                                                  as double),
                                          child: Transform.translate(
                                            offset: Offset(
                                              slides[index]['x'] as double,
                                              slides[index]['y'] as double,
                                            ),
                                            child: SizedBox(
                                              width: MediaQuery.of(
                                                context,
                                              ).size.width,
                                              child: Transform.scale(
                                                scale:
                                                    slides[index]['scale']
                                                        as double,
                                                child: Image.asset(
                                                  slides[index]['background']!
                                                      as String,
                                                  bundle: DefaultAssetBundle.of(
                                                    context,
                                                  ),
                                                  fit: BoxFit.contain,
                                                  width: double.infinity,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    Padding(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 8),
                                      child: LayoutBuilder(
                                        builder: (ctx, constraints) =>
                                            _FloatingCardsSlide(
                                              width: constraints.maxWidth,
                                              height: constraints.maxHeight,
                                              topPadding: 30,
                                            ),
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            else
                              Stack(
                                children: [
                                  if ((slides[index]['background'] ?? '')
                                      .toString()
                                      .isNotEmpty)
                                    ClipRect(
                                      clipper: ImageClipper(
                                        MediaQuery.of(context),
                                      ),
                                      child: Transform.rotate(
                                        angle:
                                            -math.pi /
                                            (slides[index]['rotation']!
                                                as double),
                                        child: Transform.translate(
                                          offset: Offset(
                                            slides[index]['x'] as double,
                                            slides[index]['y'] as double,
                                          ),
                                          child: SizedBox(
                                            width: MediaQuery.of(
                                              context,
                                            ).size.width,
                                            child: Transform.scale(
                                              scale:
                                                  slides[index]['scale']
                                                      as double,
                                              child: Image.asset(
                                                slides[index]['background']!
                                                    as String,
                                                bundle: DefaultAssetBundle.of(
                                                  context,
                                                ),
                                                fit: BoxFit.contain,
                                                width: double.infinity,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  Column(
                                    children: [
                                      const SizedBox(height: 73),
                                      Padding(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 10,
                                          // 10 padding each side
                                          // LayoutBuilder receives the inset width so the physics walls match the edges
                                        ),
                                        child: SizedBox(
                                          width: MediaQuery.of(
                                            context,
                                          ).size.width,
                                          child:
                                              (slides[index]['picture'] ?? '')
                                                  .toString()
                                                  .isNotEmpty
                                              ? Image(
                                                  image: PreloadedImageProvider(
                                                    DefaultAssetBundle.of(
                                                      context,
                                                    ),
                                                    slides[index]['picture']!
                                                        as String,
                                                  ),
                                                  fit: BoxFit.cover,
                                                  width: double.infinity,
                                                  alignment: Alignment.center,
                                                )
                                              : const SizedBox.shrink(),
                                        ),
                                      ),
                                    ],
                                  ),
                                  if ((slides[index]['foreground'] ?? '')
                                      .toString()
                                      .isNotEmpty)
                                    SizedBox(
                                      width: MediaQuery.of(context).size.width,
                                      child: ClipRect(
                                        clipBehavior: Clip.none,
                                        child: Transform.rotate(
                                          angle:
                                              -math.pi /
                                              (slides[index]['rotation']!
                                                  as double),
                                          child: Transform.translate(
                                            offset: Offset(
                                              slides[index]['x'] as double,
                                              slides[index]['y'] as double,
                                            ),
                                            child: Transform.scale(
                                              scale:
                                                  slides[index]['scale']
                                                      as double,
                                              child: Image.asset(
                                                slides[index]['foreground']!
                                                    as String,
                                                bundle: DefaultAssetBundle.of(
                                                  context,
                                                ),
                                                fit: BoxFit.cover,
                                                width: MediaQuery.of(
                                                  context,
                                                ).size.width,
                                                alignment: Alignment.center,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                          ],
                        );
                      },
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
                        ],
                        stops: const [0.0, 0.5],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
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
                          horizontal: paddingWidthHorizontal,
                        ),
                        child: InkWell(
                          onTap: () {
                            showModalBottomSheet<void>(
                              context: context,
                              isScrollControlled: true,
                              showDragHandle: false,
                              builder: (BuildContext context) {
                                return SizedBox(
                                  height: MediaQuery.sizeOf(context).height,
                                  child: _loginWebView,
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
                              color: appStyle.colors.accent,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              shadows: [
                                BoxShadow(
                                  color: appStyle.colors.textPrimary.withAlpha(
                                    13,
                                  ),
                                  blurRadius: 2,
                                  offset: const Offset(0, 1),
                                  spreadRadius: 0,
                                ),
                              ],
                            ),
                            child: Center(
                              child: Text(
                                widget.data.l10n.loginBtn,
                                textAlign: TextAlign.center,
                                style: appStyle.fonts.H_16px.copyWith(
                                  color: appStyle.colors.textPrimaryLight,
                                  fontVariations: const [
                                    FontVariation("wght", 800),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    GestureDetector(
                      onTap: _launchPrivacyPolicy,
                      child: Text(
                        widget.data.l10n.privacyLabel,
                        textAlign: TextAlign.center,
                        style: appStyle.fonts.H_12px.copyWith(
                          color: appStyle.colors.textTertiary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

//card config
class _CardConfig {
  final String asset;
  final Offset baseOffset;
  final double size;
  final double parallax;
  final double glide;
  final double aspect;

  const _CardConfig({
    required this.asset,
    required this.baseOffset,
    required this.size,
    required this.parallax,
    required this.glide,
    this.aspect = 0.72,
  });
}

//floating card part
class _FloatingCardsSlide extends StatefulWidget {
  final double width;
  final double height;
  final double topPadding;
  const _FloatingCardsSlide({
    required this.width,
    required this.height,
    this.topPadding = 0,
  });
  @override
  State<_FloatingCardsSlide> createState() => _FloatingCardsSlideState();
}

class _FloatingCardsSlideState extends State<_FloatingCardsSlide>
    with SingleTickerProviderStateMixin {
  static const double _friction = 0.878;
  static const double _cardHeight =
      45; //not in pixels, idk what unit but it works :p
  static const double _maxSpeed = _cardHeight * 1.2;
  static const double _tiltForce = 0.05;
  static const double _bounceDamping = 0.45;
  static const double _collisionRestitution = 1.0;

  //minimum speed it has to go to trigger a vibration, so the phone doesn't turn into a bomb if the cards are touching
  static const double _vibrateSpeedThreshold = _maxSpeed * 0.2;

  static const List<_CardConfig> _cards = [
    _CardConfig(
      asset: 'assets/images/carousel/card1.svg',
      baseOffset: Offset(-100, -15),
      size: _cardHeight,
      parallax: 7.5,
      glide: 1.05,
      aspect: 4.48,
    ), // viewBox 215x48
    _CardConfig(
      asset: 'assets/images/carousel/card2.svg',
      baseOffset: Offset(-8, -35),
      size: _cardHeight,
      parallax: 9.0,
      glide: 1.12,
      aspect: 2.25,
    ), // viewBox 108x48
    _CardConfig(
      asset: 'assets/images/carousel/card3.svg',
      baseOffset: Offset(88, -5),
      size: _cardHeight,
      parallax: 7.0,
      glide: 1.0,
      aspect: 4.13,
    ), // viewBox 198x48
    _CardConfig(
      asset: 'assets/images/carousel/card4.svg',
      baseOffset: Offset(-60, 55),
      size: _cardHeight,
      parallax: 9.5,
      glide: 1.15,
      aspect: 2.25,
    ), // viewBox 108x48
    _CardConfig(
      asset: 'assets/images/carousel/card5.svg',
      baseOffset: Offset(52, 80),
      size: _cardHeight,
      parallax: 10.5,
      glide: 1.18,
      aspect: 3.02,
    ), // viewBox 145x48
    _CardConfig(
      asset: 'assets/images/carousel/card6.svg',
      baseOffset: Offset(128, 18),
      size: _cardHeight,
      parallax: 7.5,
      glide: 0.95,
      aspect: 5.63,
    ), // viewBox 270x48
    _CardConfig(
      asset: 'assets/images/carousel/card7.svg',
      baseOffset: Offset(-138, 22),
      size: _cardHeight,
      parallax: 8.5,
      glide: 1.05,
      aspect: 3.94,
    ), // viewBox 189x48
  ];

  late Ticker _ticker;
  List<Offset> _positions = [];
  List<Offset> _velocities = [];

  Offset _tilt = Offset.zero;
  Offset? _baseline;
  StreamSubscription<AccelerometerEvent>? _accelerometerSub;
  Duration? _lastTick;

  double _sceneWidth = 0;
  double _sceneHeight = 0;

 //we needed a cooldown, so that again, the phone doesn't turn into a bomb  | EDIT: actually this was fixed by the minimum speed, so we don't need it anymore
  // DateTime? _lastVibration;

  Offset _clampVel(Offset v) => Offset(
    v.dx.clamp(-_maxSpeed, _maxSpeed),
    v.dy.clamp(-_maxSpeed, _maxSpeed),
  );

  void _maybeVibrate() {
    // final now = DateTime.now();
    // if (_lastVibration != null &&
    //     now.difference(_lastVibration!).inMilliseconds < 2) //first used 50 but it wasn't good enough, so now it's 2
    //   return; 
    // _lastVibration = now;
    Vibration.vibrate(duration: 20);
  }

  @override
  void initState() {
    super.initState();

    _positions = _cards
        .map((c) => c.baseOffset + const Offset(0, 300))
        .toList();

    final rng = math.Random();
    _velocities = List.generate(_cards.length, (i) {
      final jitter = (rng.nextDouble() - 0.5) * 3.0;
      return Offset(jitter, -9.0 * _cards[i].glide);
    });

    _ticker = createTicker(_tick)..start();

    _accelerometerSub = accelerometerEventStream(
      samplingPeriod: SensorInterval.gameInterval,
    ).listen(_handleTilt);
  }

  void _handleTilt(AccelerometerEvent event) {
    final raw = Offset(event.x, event.y);
    _baseline ??= raw;
    final rel = raw - _baseline!;
    _tilt = Offset(
      (_tilt.dx * 0.88 + rel.dx * 0.12).clamp(-6.5, 6.5),
      (_tilt.dy * 0.88 + rel.dy * 0.12).clamp(-6.5, 6.5),
    );
  }

  void _tick(Duration elapsed) {
    if (_positions.isEmpty || _velocities.isEmpty) return;
    if (_lastTick == null) {
      _lastTick = elapsed;
      return;
    }

    final dt = ((elapsed - _lastTick!).inMicroseconds / 16667.0).clamp(
      0.0,
      4.0,
    );
    _lastTick = elapsed;

    if (_sceneWidth == 0 || _sceneHeight == 0) return;

    bool collidedThisTick = false;

    setState(() {
      final slope = Offset(-_tilt.dx, _tilt.dy);
      final n = _cards.length;

      //friction
      for (int i = 0; i < n; i++) {
        final card = _cards[i];
        _velocities[i] += slope * card.parallax * _tiltForce * dt;
        _velocities[i] *= math.pow(_friction, dt).toDouble();
        _velocities[i] = _clampVel(_velocities[i]);
        _positions[i] += _velocities[i] * dt;
      }

      // card to card collison and wall stuff
      //
      // running both together in a loop means that when card a is against a
      // wall and card b pushes into it, the wall clamp on the a card.
      // it goes back through the collision math wizard on the next loop,
      // so car b receives the correct reaction instead of having a mating session with card a.
      // five times is enough i think, more on slower end devices might cause issues idk tho
      final double halfW = _sceneWidth / 2;
      final double halfH = _sceneHeight / 2;

      for (int iter = 0; iter < 5; iter++) {
        //here's the card to card magic, meow i'm going crazy :3
        for (int i = 0; i < n - 1; i++) {
          for (int j = i + 1; j < n; j++) {
            final wi = _cards[i].size * _cards[i].aspect;
            final wj = _cards[j].size * _cards[j].aspect;
            final hi = _cards[i].size;
            final hj = _cards[j].size;

            final pi = _positions[i];
            final pj = _positions[j];

            final overlapX = (wi + wj) / 2 - (pj.dx - pi.dx).abs();
            final overlapY = (hi + hj) / 2 - (pj.dy - pi.dy).abs();

            if (overlapX > 0 && overlapY > 0) {
              if (overlapX < overlapY) {
                final sign = pj.dx > pi.dx ? 1.0 : -1.0;
                _positions[i] = Offset(pi.dx - sign * overlapX / 2, pi.dy);
                _positions[j] = Offset(pj.dx + sign * overlapX / 2, pj.dy);

                final viX = _velocities[i].dx;
                final vjX = _velocities[j].dx;
                if ((viX - vjX) * sign > 0) {
                  final impulse = (viX - vjX) * _collisionRestitution;
                  _velocities[i] = _clampVel(
                    Offset(_velocities[i].dx - impulse, _velocities[i].dy),
                  );
                  _velocities[j] = _clampVel(
                    Offset(_velocities[j].dx + impulse, _velocities[j].dy),
                  );
                  if ((viX - vjX).abs() > _vibrateSpeedThreshold) {
                    collidedThisTick = true;
                  }
                }
              } else {
                final sign = pj.dy > pi.dy ? 1.0 : -1.0;
                _positions[i] = Offset(pi.dx, pi.dy - sign * overlapY / 2);
                _positions[j] = Offset(pj.dx, pj.dy + sign * overlapY / 2);

                final viY = _velocities[i].dy;
                final vjY = _velocities[j].dy;
                if ((viY - vjY) * sign > 0) {
                  final impulse = (viY - vjY) * _collisionRestitution;
                  _velocities[i] = _clampVel(
                    Offset(_velocities[i].dx, _velocities[i].dy - impulse),
                  );
                  _velocities[j] = _clampVel(
                    Offset(_velocities[j].dx, _velocities[j].dy + impulse),
                  );
                  if ((viY - vjY).abs() > _vibrateSpeedThreshold) {
                    collidedThisTick = true;
                  }
                }
              }
            }
          }
        }

        // wall collision, runs every loop, explained before
        // feeds back into the next collision loop.
        for (int i = 0; i < n; i++) {
          final card = _cards[i];
          final double cardW = card.size * card.aspect;
          final double cardH = card.size;

          final double minX = -halfW + cardW / 2;
          final double maxX = halfW - cardW / 2;
          final double minY = -halfH + cardH / 2;
          final double maxY = halfH - cardH / 2;

          Offset pos = _positions[i];
          double vx = _velocities[i].dx;
          double vy = _velocities[i].dy;

          if (pos.dx < minX) {
            pos = Offset(minX, pos.dy);
            vx = vx.abs() * _bounceDamping;
          } else if (pos.dx > maxX) {
            pos = Offset(maxX, pos.dy);
            vx = -vx.abs() * _bounceDamping;
          }

          if (pos.dy < minY) {
            pos = Offset(pos.dx, minY);
            vy = vy.abs() * _bounceDamping;
          } else if (pos.dy > maxY) {
            pos = Offset(pos.dx, maxY);
            vy = -vy.abs() * _bounceDamping;
          }

          _velocities[i] = _clampVel(Offset(vx, vy));
          _positions[i] = pos;
        }
      }
    });

    // phone mating session
    if (collidedThisTick) _maybeVibrate();
  }

  @override
  void dispose() {
    _ticker.dispose();
    _accelerometerSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final double totalHeight = widget.height;
    _sceneWidth = widget.width;
    _sceneHeight = math.max(0, totalHeight - widget.topPadding);

    final Offset center = Offset(
      _sceneWidth / 2,
      widget.topPadding + _sceneHeight / 2,
    );

    return SizedBox(
      width: _sceneWidth,
      height: totalHeight,
      child: Stack(
        clipBehavior: Clip.hardEdge,
        children: [
          //background rectangle 
          Positioned(
            left: 0,
            right: 0,
            top: widget.topPadding,
            bottom: 0,
            child: Container(
              decoration: BoxDecoration(
                color: appStyle.colors.buttonSecondaryFill,  //button color xdddd
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(32),
                  topRight: Radius.circular(32),
                ),
              ),
            ),
          ),
          ...List.generate(_cards.length, (i) {
            final card = _cards[i];
            final double cardWidth = card.size * card.aspect;
            final double cardHeight = card.size;
            final Offset pos =
                center + _positions[i] - Offset(cardWidth / 2, cardHeight / 2);
            return Positioned(
              left: pos.dx,
              top: pos.dy,
              width: cardWidth,
              height: cardHeight,
              child: SvgPicture.asset(
                card.asset,
                width: cardWidth,
                height: cardHeight,
                fit: BoxFit.contain,
              ),
            );
          }),
        ],
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
      0,
      -70,
      _mediaQuery.size.width,
      _mediaQuery.size.height,
    );
  }

  @override
  bool shouldReclip(covariant CustomClipper<Rect> oldClipper) => false;
}
