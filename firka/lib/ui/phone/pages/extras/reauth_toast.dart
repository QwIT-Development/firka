import 'package:firka/main.dart';
import 'package:firka/ui/model/style.dart';
import 'package:firka/ui/phone/pages/extras/main_reauth.dart';
import 'package:firka/ui/widget/firka_icon.dart';
import 'package:flutter/material.dart';
import 'package:majesticons_flutter/majesticons_flutter.dart';

class ReauthToastWidget extends StatefulWidget {
  final AppInitialization data;
  final Function() onDismiss;

  const ReauthToastWidget({
    Key? key,
    required this.data,
    required this.onDismiss,
  }) : super(key: key);

  @override
  State<ReauthToastWidget> createState() => _ReauthToastWidgetState();
}

class _ReauthToastWidgetState extends State<ReauthToastWidget> {
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
          onTap: () {
            showReauthBottomSheet(context, widget.data, widget.data.l10n.reauth);
          },
          onVerticalDragUpdate: (details) {
            setState(() {
              _dragOffset += details.delta.dy;
              if (_dragOffset < 0) _dragOffset = 0;
            });
          },
          onVerticalDragEnd: (details) {
            if (_dragOffset > 50) {
              widget.onDismiss();
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
              borderRadius: BorderRadius.all(Radius.circular(200)),
            ),
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 15, vertical: 8),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    widget.data.l10n.reauth,
                    style: appStyle.fonts.B_16SB
                        .copyWith(color: appStyle.colors.errorText),
                  ),
                  SizedBox(width: 8),
                  FirkaIconWidget(
                    FirkaIconType.majesticons,
                    Majesticon.loginSolid,
                    color: appStyle.colors.errorAccent,
                    size: 24,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

Widget buildReauthToast(BuildContext context, AppInitialization data, Function() onDismiss) {
  return ReauthToastWidget(
    data: data,
    onDismiss: onDismiss,
  );
}
