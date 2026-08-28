import "dart:async";
import "dart:math";

import "package:firka/core/extensions.dart";
import "package:firka/l10n/app_localizations.dart";
import "package:firka/ui/theme/style.dart";
import "package:firka_common/data/models/grade_cache_model.dart";
import "package:firka_common/data/models/subject_cache_model.dart";
import "package:firka_common/data/util.dart";
import "package:firka_common/ui/components/grade.dart";
import "package:firka_common/ui/shared/class_icon.dart";
import "package:flutter/material.dart";
import "package:flutter_svg/flutter_svg.dart";
import "package:majesticons_flutter/majesticons_flutter.dart";
import "package:vibration/vibration.dart";

const _starLarge = "assets/images/surprise_grades/star_large.svg";
const _starMedium = "assets/images/surprise_grades/star_medium.svg";
const _starSmall = "assets/images/surprise_grades/star_small.svg";
const _gradeEmojis = {5: "🏆", 4: "😃", 3: "😐", 2: "😬", 1: "💩"};
const _flipDuration = Duration(milliseconds: 400);

String _gradeEmoji(int? value) => _gradeEmojis[value] ?? "✨";

String _rankLabel(AppLocalizations l10n, int value) {
  return switch (value) {
    5 => l10n.surprise_grade_rank_5,
    4 => l10n.surprise_grade_rank_4,
    3 => l10n.surprise_grade_rank_3,
    2 => l10n.surprise_grade_rank_2,
    _ => l10n.surprise_grade_rank_1,
  };
}

(Alignment, double) _pickCardEdge(Random rand) {
  final edge = rand.nextInt(4);
  final jitter = rand.nextDouble() * 2 - 1;
  switch (edge) {
    case 0:
      return (Alignment(jitter, -1), -pi / 2);
    case 1:
      return (Alignment(1, jitter), 0);
    case 2:
      return (Alignment(jitter, 1), pi / 2);
    default:
      return (Alignment(-1, jitter), pi);
  }
}

String _describeGradeWeight(AppLocalizations l10n, GradeCacheModel grade) {
  final weight = grade.weightPercentage;
  if (weight == null) return grade.type;

  final weightText = switch (weight) {
    100 => l10n.grade_weight_x1,
    200 => l10n.grade_weight_x2,
    300 => l10n.grade_weight_x3,
    400 => l10n.grade_weight_x4,
    500 => l10n.grade_weight_x5,
    _ => l10n.grade_weight_percent(weight),
  };

  return grade.type.isEmpty ? weightText : "${grade.type}, $weightText";
}

class SurpriseGradesScreen extends StatefulWidget {
  final List<GradeCacheModel> grades;
  final AppLocalizations l10n;
  final ValueChanged<GradeCacheModel>? onRevealed;

  const SurpriseGradesScreen(
    this.grades,
    this.l10n, {
    this.onRevealed,
    super.key,
  });

  @override
  State<SurpriseGradesScreen> createState() => _SurpriseGradesScreenState();
}

class _SurpriseGradesScreenState extends State<SurpriseGradesScreen> {
  int _page = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: appStyle.colors.background,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
              child: GestureDetector(
                onTap: () => Navigator.of(context).pop(),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Majesticon(
                      Majesticon.chevronLeftLine,
                      color: appStyle.colors.textPrimary,
                      size: 20,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      "Főoldal",
                      style: appStyle.fonts.B_16R.apply(
                        color: appStyle.colors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                "Új jegyek!",
                style: appStyle.fonts.H_H2.apply(
                  color: appStyle.colors.textPrimary,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 20),
                decoration: BoxDecoration(
                  color: appStyle.colors.a15p,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: _CardDeck(
                  grades: widget.grades,
                  l10n: widget.l10n,
                  onIndexChanged: (i) => setState(() => _page = i),
                  onRevealed: widget.onRevealed,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(widget.grades.length, (i) {
                final active = i == _page;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: active ? 10 : 8,
                  height: active ? 10 : 8,
                  decoration: BoxDecoration(
                    color: active
                        ? appStyle.colors.accent
                        : appStyle.colors.accent.withAlpha(90),
                    shape: BoxShape.circle,
                  ),
                );
              }),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                "Tartsd lenyomva a kártyát, hogy megfordítsd.",
                textAlign: TextAlign.center,
                style: appStyle.fonts.B_16R.apply(
                  color: appStyle.colors.textPrimary,
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}

class _CardDeck extends StatefulWidget {
  final List<GradeCacheModel> grades;
  final AppLocalizations l10n;
  final ValueChanged<int> onIndexChanged;
  final ValueChanged<GradeCacheModel>? onRevealed;

  const _CardDeck({
    required this.grades,
    required this.l10n,
    required this.onIndexChanged,
    this.onRevealed,
  });

  @override
  State<_CardDeck> createState() => _CardDeckState();
}

class _CardDeckState extends State<_CardDeck> with TickerProviderStateMixin {
  static const _cardWidth = 240.0;
  static const _cardHeight = 300.0;
  static const _swipeThreshold = 90.0;
  static const _peekVisibleSliver = 40.0;
  static const _peekCornerAngle = 8 * pi / 180;
  static const _dragSlop = 20.0;
  static const _holdDuration = Duration(milliseconds: 2000);
  static const _chargeVibrateMs = 20;
  static const _chargeWaitStartMs = 100.0;
  static const _chargeWaitEndMs = 2.0;
  static const _chargePatternMarginMs = 400;
  static const _sprayCount = 30;
  static const _sprayLifespanFraction = 0.12;
  static const _shakeMaxAmplitude = 8.0;
  static const _burstPattern = [0, 45, 55, 30, 70, 18];
  static const _burstIntensities = [0, 255, 0, 180, 0, 110];

  double get _restOffset =>
      (MediaQuery.sizeOf(context).width + _cardWidth) / 2 - _peekVisibleSliver;
  static const _shakeTuningSpanMs = 2400.0;
  static const _shakeRateDx = 113 / _shakeTuningSpanMs;
  static const _shakeRateDy = 97 / _shakeTuningSpanMs;
  static const _shakeRateAngle = 131 / _shakeTuningSpanMs;

  static final (List<int>, List<int>) _chargePattern = _buildChargePattern();

  static (List<int>, List<int>) _buildChargePattern() {
    final pattern = <int>[0];
    final intensities = <int>[0];
    final totalMs = _holdDuration.inMilliseconds + _chargePatternMarginMs;
    var elapsedMs = 0;
    while (elapsedMs < totalMs) {
      final t = (elapsedMs / _holdDuration.inMilliseconds).clamp(0.0, 1.0);
      final eased = 1 - pow(1 - t, 6).toDouble();
      final wait =
          (_chargeWaitStartMs + (_chargeWaitEndMs - _chargeWaitStartMs) * eased)
              .round();
      final strength = (70 + 185 * eased).round().clamp(1, 255);
      pattern.add(_chargeVibrateMs);
      intensities.add(strength);
      pattern.add(wait);
      intensities.add(0);
      elapsedMs += _chargeVibrateMs + wait;
    }
    return (pattern, intensities);
  }

  late final _settleController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 320),
  );
  late final _shakeController = AnimationController(
    vsync: this,
    duration: _holdDuration,
  );
  late final _flipShakeController = AnimationController(
    vsync: this,
    duration: _flipDuration,
  );
  final _flipKey = GlobalKey<_SurpriseFlipCardState>();
  final _rand = Random();

  int _index = 0;
  double _dragDx = 0;
  double _settleFrom = 0;
  double _settleTo = 0;

  Timer? _holdTimer;
  double _pressStartX = 0;
  bool _holdCancelled = false;
  int _burstTrigger = 0;
  int _revealBurstTrigger = 0;
  String _revealEmoji = "";
  List<_SprayParticle> _sprayParticles = [];
  final Set<int> _revealedIndices = {};

  @override
  void initState() {
    super.initState();
    _settleController.addListener(() {
      final t = Curves.easeOut.transform(_settleController.value);
      setState(() {
        _dragDx = _settleFrom + (_settleTo - _settleFrom) * t;
      });
    });
  }

  @override
  void dispose() {
    _holdTimer?.cancel();
    _settleController.dispose();
    _shakeController.dispose();
    _flipShakeController.dispose();
    super.dispose();
  }

  List<_SprayParticle> _generateSprayParticles() {
    return List.generate(_sprayCount, (i) {
      final (origin, normalAngle) = _pickCardEdge(_rand);
      final spread = (_rand.nextDouble() - 0.5) * (pi / 2.5);
      final distance = 40.0 + _rand.nextDouble() * 60;
      final value = 1 + _rand.nextInt(5);
      final spawnFraction =
          (i / _sprayCount + (_rand.nextDouble() - 0.5) * 0.02).clamp(
            0.0,
            1 - _sprayLifespanFraction,
          );
      return _SprayParticle(
        origin: origin,
        angle: normalAngle + spread,
        distance: distance,
        value: value,
        spawnFraction: spawnFraction,
        lifespanFraction: _sprayLifespanFraction,
      );
    });
  }

  void _onPointerDown(PointerDownEvent event) {
    _pressStartX = event.position.dx;
    _holdCancelled = false;
    if (_flipKey.currentState?.isRevealed ?? false) {
      return;
    }
    setState(() {
      _burstTrigger++;
      _sprayParticles = _generateSprayParticles();
    });
    final (pattern, intensities) = _chargePattern;
    Vibration.vibrate(pattern: pattern, intensities: intensities);
    _shakeController.forward(from: 0);
    _holdTimer = Timer(_holdDuration, () {
      _holdTimer = null;
      Vibration.cancel();
      Vibration.vibrate(duration: 28, amplitude: 200);
      _shakeController.value = 0;
      _flipShakeController.forward(from: 0);
      _flipKey.currentState?.flip();
    });
  }

  void _cancelHold() {
    _holdTimer?.cancel();
    _holdTimer = null;
    Vibration.cancel();
    _shakeController.stop();
    _shakeController.value = 0;
  }

  void _onPointerMove(PointerMoveEvent event) {
    if (!_holdCancelled &&
        (event.position.dx - _pressStartX).abs() > _dragSlop) {
      _holdCancelled = true;
      _cancelHold();
    }
    if (_holdCancelled) {
      final revealed = _flipKey.currentState?.isRevealed ?? false;
      setState(() {
        final updated = _dragDx + event.delta.dx;
        _dragDx = revealed
            ? updated.clamp(-_restOffset, _restOffset)
            : updated.clamp(0.0, _restOffset);
      });
    }
  }

  void _onPointerUp(PointerUpEvent event) {
    if (!_holdCancelled) {
      _cancelHold();
      return;
    }
    _holdTimer?.cancel();
    _holdTimer = null;
    _finishDrag();
  }

  void _onPointerCancel(PointerCancelEvent event) {
    final wasDragging = _holdCancelled;
    _cancelHold();
    if (wasDragging) _finishDrag();
  }

  void _finishDrag() {
    final canAdvance =
        _dragDx < -_swipeThreshold && _index < widget.grades.length - 1;
    final canRecede = _dragDx > _swipeThreshold && _index > 0;

    if (canAdvance) {
      _animateSettle(target: -_restOffset, onDone: () => _advance(1));
    } else if (canRecede) {
      _animateSettle(target: _restOffset, onDone: () => _advance(-1));
    } else {
      _animateSettle(target: 0, onDone: () {});
    }
  }

  void _advance(int direction) {
    setState(() {
      _index += direction;
      _dragDx = 0;
    });
    widget.onIndexChanged(_index);
    Vibration.vibrate(duration: 25, amplitude: 110);
  }

  void _animateSettle({required double target, required VoidCallback onDone}) {
    _settleFrom = _dragDx;
    _settleTo = target;
    _settleController.forward(from: 0).whenComplete(onDone);
  }

  @override
  Widget build(BuildContext context) {
    final progress = (-_dragDx / _cardWidth).clamp(-1.0, 1.0);
    final next = _index + 1 < widget.grades.length
        ? widget.grades[_index + 1]
        : null;
    final prev = _index > 0 ? widget.grades[_index - 1] : null;

    final restOffset = _restOffset;

    return SizedBox.expand(
      child: Listener(
        onPointerDown: _onPointerDown,
        onPointerMove: _onPointerMove,
        onPointerUp: _onPointerUp,
        onPointerCancel: _onPointerCancel,
        child: Stack(
          alignment: Alignment.center,
          clipBehavior: Clip.none,
          children: [
            AnimatedBuilder(
              animation: Listenable.merge([
                _shakeController,
                _flipShakeController,
              ]),
              builder: (context, child) {
                final shakeT = _shakeController.value;
                final elapsedMs = shakeT * _holdDuration.inMilliseconds;
                var amplitude =
                    _shakeMaxAmplitude * (1 / 3 + 2 / 3 * shakeT * shakeT);
                var shakeDx = sin(elapsedMs * _shakeRateDx) * amplitude;
                var shakeDy = cos(elapsedMs * _shakeRateDy) * amplitude * 0.5;
                var shakeAngle =
                    sin(elapsedMs * _shakeRateAngle) * 0.03 * shakeT * shakeT;

                final flipT = _flipShakeController.value;
                if (flipT > 0 && flipT < 1) {
                  final flipMs = flipT * _flipDuration.inMilliseconds;
                  final flipAmp = _shakeMaxAmplitude * (1 - flipT);
                  shakeDx += sin(flipMs * _shakeRateDx) * flipAmp;
                  shakeDy += cos(flipMs * _shakeRateDy) * flipAmp * 0.5;
                  shakeAngle +=
                      sin(flipMs * _shakeRateAngle) * 0.03 * (1 - flipT);
                }
                return Transform.translate(
                  offset: Offset(_dragDx + shakeDx, shakeDy),
                  child: Transform.rotate(
                    angle:
                        (_dragDx / _restOffset) * _peekCornerAngle + shakeAngle,
                    child: child,
                  ),
                );
              },
              child: SizedBox(
                width: _cardWidth,
                height: _cardHeight,
                child: _SurpriseFlipCard(
                  key: _flipKey,
                  grade: widget.grades[_index],
                  l10n: widget.l10n,
                  initiallyRevealed: _revealedIndices.contains(_index),
                  onRevealed: () {
                    final revealedGrade = widget.grades[_index];
                    setState(() => _revealedIndices.add(_index));
                    widget.onRevealed?.call(revealedGrade);
                    Future.delayed(_flipDuration, () {
                      if (!mounted) return;
                      Vibration.vibrate(
                        pattern: _burstPattern,
                        intensities: _burstIntensities,
                      );
                      setState(() {
                        _revealEmoji = _gradeEmoji(revealedGrade.numericValue);
                        _revealBurstTrigger++;
                      });
                    });
                  },
                ),
              ),
            ),
            if (next != null)
              _buildPeek(
                next,
                progress: progress,
                fromRight: true,
                restOffset: restOffset,
                isRevealed: _revealedIndices.contains(_index + 1),
              ),
            if (prev != null)
              _buildPeek(
                prev,
                progress: progress,
                fromRight: false,
                restOffset: restOffset,
                isRevealed: _revealedIndices.contains(_index - 1),
              ),
            if (_burstTrigger > 0)
              AnimatedBuilder(
                animation: _shakeController,
                builder: (context, child) => _HoldSpray(
                  progress: _shakeController.value,
                  particles: _sprayParticles,
                ),
              ),
            if (_revealBurstTrigger > 0)
              IgnorePointer(
                child: SizedBox(
                  width: _cardWidth,
                  height: _cardHeight,
                  child: _RevealEmojiBurst(
                    key: ValueKey(_revealBurstTrigger),
                    emoji: _revealEmoji,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildPeek(
    GradeCacheModel grade, {
    required double progress,
    required bool fromRight,
    required double restOffset,
    required bool isRevealed,
  }) {
    final side = fromRight ? 1.0 : -1.0;
    final tt = (fromRight ? progress : -progress).clamp(0.0, 1.0);
    final dx = restOffset * (side - progress);
    final angle = _peekCornerAngle * (1 - tt) * side;

    return Transform.translate(
      offset: Offset(dx, 0),
      child: Transform.rotate(
        angle: angle,
        child: SizedBox(
          width: _cardWidth,
          height: _cardHeight,
          child: IgnorePointer(
            child: isRevealed
                ? _SurpriseCardFace.back(grade, widget.l10n)
                : _SurpriseCardFace.front(grade, widget.l10n),
          ),
        ),
      ),
    );
  }
}

class _SurpriseFlipCard extends StatefulWidget {
  final GradeCacheModel grade;
  final AppLocalizations l10n;
  final bool initiallyRevealed;
  final VoidCallback onRevealed;

  const _SurpriseFlipCard({
    required this.grade,
    required this.l10n,
    required this.initiallyRevealed,
    required this.onRevealed,
    super.key,
  });

  @override
  State<_SurpriseFlipCard> createState() => _SurpriseFlipCardState();
}

class _SurpriseFlipCardState extends State<_SurpriseFlipCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  bool _showFront = true;

  bool get isRevealed => !_showFront;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: _flipDuration);
    if (widget.initiallyRevealed) {
      _showFront = false;
      _controller.value = 1;
    }
  }

  @override
  void didUpdateWidget(covariant _SurpriseFlipCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.grade != oldWidget.grade) {
      _showFront = !widget.initiallyRevealed;
      _controller.value = widget.initiallyRevealed ? 1 : 0;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void flip() {
    if (!_showFront) return;
    setState(() => _showFront = false);
    _controller.forward();
    widget.onRevealed();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final angle = _controller.value * pi;
        final isBack = angle > pi / 2;
        final displayAngle = isBack ? angle - pi : angle;
        return Transform(
          alignment: Alignment.center,
          transform: Matrix4.identity()
            ..setEntry(3, 2, 0.001)
            ..rotateY(displayAngle),
          child: isBack
              ? _SurpriseCardFace.back(widget.grade, widget.l10n)
              : _SurpriseCardFace.front(widget.grade, widget.l10n),
        );
      },
    );
  }
}

class _TexturedGridBox extends StatelessWidget {
  final Widget? child;

  const _TexturedGridBox({this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: appStyle.colors.accent),
        borderRadius: BorderRadius.circular(24),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(23),
        child: CustomPaint(
          painter: _GridPainter(appStyle.colors.accent.withAlpha(46)),
          child: SizedBox.expand(child: child),
        ),
      ),
    );
  }
}

class _GridPainter extends CustomPainter {
  final Color color;

  const _GridPainter(this.color);

  static const _cellSize = 24.0;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1;

    for (double x = 0; x <= size.width; x += _cellSize) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y <= size.height; y += _cellSize) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _GridPainter oldDelegate) =>
      oldDelegate.color != color;
}

class _SurpriseCardFace extends StatelessWidget {
  final GradeCacheModel grade;
  final AppLocalizations l10n;
  final bool isBack;

  const _SurpriseCardFace.front(this.grade, this.l10n) : isBack = false;
  const _SurpriseCardFace.back(this.grade, this.l10n) : isBack = true;

  @override
  Widget build(BuildContext context) {
    final subject = grade.subject.loadAndGet();
    final headline = (grade.topic ?? grade.type).firstUpper();

    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        color: appStyle.colors.card,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: appStyle.colors.textPrimary.withAlpha(20),
            blurRadius: 15,
            offset: const Offset(0, 11),
          ),
        ],
      ),
      child: isBack
          ? _buildBack(subject, headline)
          : _buildFront(subject, headline),
    );
  }

  Widget _buildFront(SubjectCacheModel? subject, String headline) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Stack(
        alignment: Alignment.center,
        children: [
          const Positioned.fill(child: _TexturedGridBox()),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: appStyle.colors.a15p,
                  borderRadius: BorderRadius.circular(20),
                ),
                alignment: Alignment.center,
                child: subject == null
                    ? null
                    : ClassIconWidget(
                        subject: subject,
                        color: appStyle.colors.accent,
                        size: 24,
                      ),
              ),
              const SizedBox(height: 20),
              Text(
                headline,
                textAlign: TextAlign.center,
                style: appStyle.fonts.H_H2.apply(
                  color: appStyle.colors.textPrimary,
                ),
              ),
              if (subject != null) ...[
                const SizedBox(height: 4),
                Text(
                  subject.name,
                  textAlign: TextAlign.center,
                  style: appStyle.fonts.B_14R.apply(
                    color: appStyle.colors.textSecondary,
                  ),
                ),
              ],
              const SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Text(
                  _describeGradeWeight(l10n, grade),
                  textAlign: TextAlign.center,
                  style: appStyle.fonts.B_14R.apply(
                    color: appStyle.colors.textSecondary,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBack(SubjectCacheModel? subject, String headline) {
    return Stack(
      children: [
        Positioned(
          left: 12,
          top: 73,
          width: 216,
          height: 159,
          child: _TexturedGridBox(
            child: Center(child: _SurpriseBadge(grade, l10n)),
          ),
        ),
        Positioned(
          left: 16,
          top: 16,
          right: 16,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                headline,
                style: appStyle.fonts.B_16SB.apply(
                  color: appStyle.colors.textPrimary,
                ),
              ),
              if (subject != null)
                Text(
                  subject.name,
                  style: appStyle.fonts.B_14R.apply(
                    color: appStyle.colors.textSecondary,
                  ),
                ),
            ],
          ),
        ),
        Positioned(
          left: 16,
          right: 16,
          bottom: 16,
          child: Text(
            _describeGradeWeight(l10n, grade),
            style: appStyle.fonts.B_14R.apply(
              color: appStyle.colors.textTertiary,
            ),
          ),
        ),
      ],
    );
  }
}

class SurpriseGradeMiniCard extends StatelessWidget {
  final GradeCacheModel grade;
  final AppLocalizations l10n;
  final double width;

  const SurpriseGradeMiniCard(
    this.grade,
    this.l10n, {
    required this.width,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: width * _CardDeckState._cardHeight / _CardDeckState._cardWidth,
      child: FittedBox(
        fit: BoxFit.fill,
        child: SizedBox(
          width: _CardDeckState._cardWidth,
          height: _CardDeckState._cardHeight,
          child: _SurpriseCardFace.front(grade, l10n),
        ),
      ),
    );
  }
}

class _SurpriseBadge extends StatelessWidget {
  final GradeCacheModel grade;
  final AppLocalizations l10n;

  const _SurpriseBadge(this.grade, this.l10n);

  @override
  Widget build(BuildContext context) {
    final rank = grade.numericValue != null
        ? _rankLabel(l10n, grade.numericValue!)
        : null;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.center,
          children: [
            GradeWidget(grade, size: 90),
            Positioned(
              right: -6,
              top: -4,
              child: SvgPicture.asset(_starMedium, width: 25, height: 25),
            ),
            Positioned(
              left: 2,
              bottom: -2,
              child: SvgPicture.asset(_starLarge, width: 21, height: 21),
            ),
            Positioned(
              left: -6,
              bottom: 6,
              child: SvgPicture.asset(_starSmall, width: 10, height: 10),
            ),
          ],
        ),
        if (rank != null) ...[
          const SizedBox(height: 12),
          Text(
            rank,
            style: appStyle.fonts.H_H2.apply(
              color: appStyle.colors.textPrimary,
            ),
          ),
        ],
      ],
    );
  }
}

class _HoldSpray extends StatelessWidget {
  static const _width = 240.0;
  static const _height = 300.0;

  final double progress;
  final List<_SprayParticle> particles;

  const _HoldSpray({required this.progress, required this.particles});

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: SizedBox(
        width: _width,
        height: _height,
        child: Stack(
          clipBehavior: Clip.none,
          children: particles.map((p) {
            final localT = ((progress - p.spawnFraction) / p.lifespanFraction)
                .clamp(0.0, 1.0);
            final alive =
                progress > 0 && progress >= p.spawnFraction && localT < 1.0;
            if (!alive) return const SizedBox.shrink();

            final fade = (1 - localT).clamp(0.0, 1.0);
            final dx = cos(p.angle) * p.distance * localT;
            final dy = sin(p.angle) * p.distance * localT;
            final scale = 0.6 + 0.4 * (1 - localT);
            return Align(
              alignment: p.origin,
              child: Transform.translate(
                offset: Offset(dx, dy),
                child: Transform.scale(
                  scale: scale,
                  child: Opacity(
                    opacity: fade,
                    child: GradeWidget.gradeValue(p.value, size: 28),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}

class _SprayParticle {
  final Alignment origin;
  final double angle;
  final double distance;
  final int value;
  final double spawnFraction;
  final double lifespanFraction;

  const _SprayParticle({
    required this.origin,
    required this.angle,
    required this.distance,
    required this.value,
    required this.spawnFraction,
    required this.lifespanFraction,
  });
}

class _RevealEmojiBurst extends StatefulWidget {
  final String emoji;

  const _RevealEmojiBurst({required this.emoji, super.key});

  @override
  State<_RevealEmojiBurst> createState() => _RevealEmojiBurstState();
}

class _RevealEmojiBurstState extends State<_RevealEmojiBurst>
    with SingleTickerProviderStateMixin {
  static const _width = 240.0;
  static const _height = 300.0;

  late final _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  );
  final _rand = Random();
  late final List<_EdgeParticle> _particles = _spawn();

  List<_EdgeParticle> _spawn() {
    return List.generate(14, (i) {
      final (origin, normalAngle) = _pickCardEdge(_rand);
      final spread = (_rand.nextDouble() - 0.5) * (pi / 2.5);
      final distance = 40.0 + _rand.nextDouble() * 60;
      return _EdgeParticle(
        origin: origin,
        angle: normalAngle + spread,
        distance: distance,
      );
    });
  }

  @override
  void initState() {
    super.initState();
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          final t = _controller.value;
          final fadeOut = (1 - t).clamp(0.0, 1.0);
          final fadeIn = (t / 0.12).clamp(0.0, 1.0);
          final fade = fadeIn * fadeOut;
          final active = t > 0 && !_controller.isDismissed;

          return SizedBox(
            width: _width,
            height: _height,
            child: !active
                ? null
                : Stack(
                    clipBehavior: Clip.none,
                    children: _particles.map((p) {
                      final dx = cos(p.angle) * p.distance * t;
                      final dy = sin(p.angle) * p.distance * t;
                      final scale = (0.6 + 0.4 * (1 - t)) * fadeIn;
                      return Align(
                        alignment: p.origin,
                        child: Transform.translate(
                          offset: Offset(dx, dy),
                          child: Transform.scale(
                            scale: scale,
                            child: Opacity(
                              opacity: fade,
                              child: Text(
                                widget.emoji,
                                style: const TextStyle(fontSize: 30),
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
          );
        },
      ),
    );
  }
}

class _EdgeParticle {
  final Alignment origin;
  final double angle;
  final double distance;

  const _EdgeParticle({
    required this.origin,
    required this.angle,
    required this.distance,
  });
}

class SurpriseCardFaceDebugScreen extends StatefulWidget {
  final GradeCacheModel grade;
  final AppLocalizations l10n;

  const SurpriseCardFaceDebugScreen(this.grade, this.l10n, {super.key});

  @override
  State<SurpriseCardFaceDebugScreen> createState() =>
      _SurpriseCardFaceDebugScreenState();
}

class _SurpriseCardFaceDebugScreenState
    extends State<SurpriseCardFaceDebugScreen> {
  bool _isBack = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: appStyle.colors.background,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: Majesticon(
                      Majesticon.chevronLeftLine,
                      color: appStyle.colors.textPrimary,
                      size: 24,
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () => setState(() => _isBack = !_isBack),
                    child: Text(_isBack ? "Show front" : "Show back"),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Center(
                child: SizedBox(
                  width: 240,
                  height: 300,
                  child: _isBack
                      ? _SurpriseCardFace.back(widget.grade, widget.l10n)
                      : _SurpriseCardFace.front(widget.grade, widget.l10n),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class SurpriseParticleDebugScreen extends StatefulWidget {
  const SurpriseParticleDebugScreen({super.key});

  @override
  State<SurpriseParticleDebugScreen> createState() =>
      _SurpriseParticleDebugScreenState();
}

class _SurpriseParticleDebugScreenState
    extends State<SurpriseParticleDebugScreen> {
  int _burstId = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: appStyle.colors.background,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: Majesticon(
                      Majesticon.chevronLeftLine,
                      color: appStyle.colors.textPrimary,
                      size: 24,
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () => setState(() => _burstId++),
                    child: const Text("Burst"),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Center(
                child: Stack(
                  alignment: Alignment.center,
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      width: 240,
                      height: 300,
                      decoration: BoxDecoration(
                        border: Border.all(color: appStyle.colors.accent),
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    _RevealEmojiBurst(
                      key: ValueKey(_burstId),
                      emoji: _gradeEmoji(1 + _burstId % 5),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
