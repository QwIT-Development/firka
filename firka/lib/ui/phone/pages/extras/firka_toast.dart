import 'package:firka/app/app_state.dart';
import 'package:firka/ui/phone/pages/extras/main_error.dart';
import 'package:firka/ui/theme/style.dart';
import 'package:firka/ui/phone/pages/extras/main_reauth.dart';
import 'package:firka/ui/shared/firka_icon.dart';
import 'package:flutter/material.dart';
import 'package:majesticons_flutter/majesticons_flutter.dart';

class FirkaToastWidget extends StatefulWidget {
  final Function()? onTap;
  final Function()? onDismiss;
  final List<Widget> children;
  final Color backgroundColor;

  const FirkaToastWidget({
    super.key,
    required this.backgroundColor,
    this.onTap,
    this.onDismiss,
    required this.children,
  });

  factory FirkaToastWidget.fetching(BuildContext context) {
    return FirkaToastWidget(
      backgroundColor: appStyle.colors.card,
      children: [
        SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(color: appStyle.colors.accent),
        ),
        SizedBox(width: 8),
        Text(
          initData.l10n.refreshing,
          style: appStyle.fonts.B_16SB.copyWith(
            color: appStyle.colors.textPrimary,
          ),
        ),
      ],
    );
  }

  factory FirkaToastWidget.error(BuildContext context, Object e) {
    return FirkaToastWidget(
      backgroundColor: appStyle.colors.errorCard,
      children: [
        Text(
          initData.l10n.api_error,
          style: appStyle.fonts.B_16SB.copyWith(
            color: appStyle.colors.errorText,
          ),
        ),
        SizedBox(width: 8),
        GestureDetector(
          child: FirkaIconWidget(
            FirkaIconType.majesticons,
            Majesticon.questionCircleSolid,
            color: appStyle.colors.errorAccent,
            size: 24,
          ),
          onTap: () {
            showErrorBottomSheet(
              context,
              "$e\n${e is Error ? e.stackTrace ?? '' : ''}",
            );
          },
        ),
      ],
    );
  }

  factory FirkaToastWidget.reauth(BuildContext context) {
    return FirkaToastWidget(
      backgroundColor: appStyle.colors.errorCard,
      onTap: () {
        showReauthBottomSheet(context, initData, initData.l10n.reauth);
      },
      onDismiss: () {
        initData.toastCubit.clear();
      },
      children: [
        Text(
          initData.l10n.reauth,
          style: appStyle.fonts.B_16SB.copyWith(
            color: appStyle.colors.errorText,
          ),
        ),
        SizedBox(width: 8),
        FirkaIconWidget(
          FirkaIconType.majesticons,
          Majesticon.loginSolid,
          color: appStyle.colors.errorAccent,
          size: 24,
        ),
      ],
    );
  }

  @override
  State<FirkaToastWidget> createState() => _FirkaToastWidgetState();
}

class _FirkaToastWidgetState extends State<FirkaToastWidget> {
  double _dragOffset = 0;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: MediaQuery.of(context).size.height / 1.6 + _dragOffset,
      left: 0.0,
      right: 0.0,
      bottom: 0,
      child: Center(
        child: GestureDetector(
          onTap: widget.onTap,
          onVerticalDragUpdate: (details) {
            setState(() {
              if (widget.onDismiss != null) _dragOffset += details.delta.dy;
              if (_dragOffset < 0) _dragOffset = 0;
            });
          },
          onVerticalDragEnd: (details) {
            if (_dragOffset > 50) {
              widget.onDismiss!();
            } else {
              setState(() {
                _dragOffset = 0;
              });
            }
          },
          child: Card(
            color: appStyle.colors.errorCard,
            shadowColor: Colors.transparent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(20)),
            ),
            child: Padding(
              padding: EdgeInsets.all(10),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: widget.children,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
